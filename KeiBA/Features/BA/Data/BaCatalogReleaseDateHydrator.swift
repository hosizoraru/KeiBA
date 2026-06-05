//
//  BaCatalogReleaseDateHydrator.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaCatalogReleaseDateHydrator {
    private let cacheStore: BaCacheStore
    private let studentRepository: BaStudentGuideRepository

    init(cacheStore: BaCacheStore, studentRepository: BaStudentGuideRepository) {
        self.cacheStore = cacheStore
        self.studentRepository = studentRepository
    }

    func hydrate(
        bundle: BaGuideCatalogBundle,
        maxNetworkFetchPerPass: Int = 8,
        batchSize: Int = 2
    ) async -> BaGuideCatalogBundle {
        let cached = await applyCachedStudentDetailPatches(bundle)
        let missing = cached.entries
            .filter { $0.category == .students && ($0.releaseDate == nil || $0.metadata?.needsDetailHydration != false) }
            .prefix(maxNetworkFetchPerPass)
            .map { $0 }
        guard missing.isEmpty == false else { return cached }

        var patches: [Int64: CatalogHydrationPatch] = [:]
        var start = 0
        while start < missing.count {
            let end = min(start + max(batchSize, 1), missing.count)
            await withTaskGroup(of: (BaGuideCatalogEntry, BaStudentGuideInfo?).self) { group in
                for entry in missing[start ..< end] {
                    group.addTask {
                        let snapshot = try? await studentRepository.fetchStudentDetail(entry: entry)
                        return (entry, snapshot?.value)
                    }
                }
                for await (entry, info) in group {
                    guard let info else { continue }
                    await cacheStore.save(info, for: .studentDetail(entry.contentId), schemaVersion: 3, syncedAt: info.syncedAt)
                    patches[entry.contentId] = CatalogHydrationPatch(
                        releaseDate: releaseDate(from: info),
                        metadata: BaCatalogMetadataParser.metadata(from: info)
                    )
                }
            }
            start = end
        }
        guard patches.isEmpty == false else { return cached }
        return apply(patches: patches, to: cached)
    }

    private func applyCachedStudentDetailPatches(_ bundle: BaGuideCatalogBundle) async -> BaGuideCatalogBundle {
        var patches: [Int64: CatalogHydrationPatch] = [:]
        let candidates = bundle.entries.filter { entry in
            entry.category == .students && (entry.releaseDate == nil || entry.metadata?.needsDetailHydration != false)
        }
        for batch in candidates.baChunked(into: BaPlatformPerformanceProfile.catalogCachedReleaseDateBatchSize) {
            for entry in batch {
                guard let cached = await cacheStore.load(BaStudentGuideInfo.self, for: .studentDetail(entry.contentId)) else {
                    continue
                }
                patches[entry.contentId] = CatalogHydrationPatch(
                    releaseDate: releaseDate(from: cached.value),
                    metadata: BaCatalogMetadataParser.metadata(from: cached.value)
                )
            }
            await Task.yield()
        }
        return patches.isEmpty ? bundle : apply(patches: patches, to: bundle)
    }

    private func apply(patches: [Int64: CatalogHydrationPatch], to bundle: BaGuideCatalogBundle) -> BaGuideCatalogBundle {
        BaGuideCatalogBundle(
            entries: bundle.entries.map { entry in
                guard let patch = patches[entry.contentId] else { return entry }
                let patchedMetadata: BaGuideCatalogMetadata?
                if let metadata = entry.metadata, let patchMetadata = patch.metadata {
                    patchedMetadata = metadata.mergingMissingFields(with: patchMetadata)
                } else {
                    patchedMetadata = entry.metadata ?? patch.metadata
                }
                return entry
                    .withReleaseDate(patch.releaseDate)
                    .withMetadata(patchedMetadata)
            },
            syncedAt: bundle.syncedAt,
            studentFilterGroups: bundle.studentFilterGroups,
            npcSatelliteFilterGroups: bundle.npcSatelliteFilterGroups
        )
    }

    private func releaseDate(from info: BaStudentGuideInfo) -> Date? {
        let rows = info.profileRows + info.stats
        for row in rows where BaGuideTextNormalizer.containsAny(row.title, tokens: ["实装", "上线", "release"]) {
            if let date = BaGuideTextNormalizer.extractDate(from: row.value) {
                return date
            }
        }
        return nil
    }
}

private struct CatalogHydrationPatch {
    let releaseDate: Date?
    let metadata: BaGuideCatalogMetadata?
}
