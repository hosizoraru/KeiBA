//
//  BaCatalogReleaseDateHydrator.swift
//  KeiBAOS
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
        let cached = await applyCachedReleaseDates(bundle)
        let missing = cached.entries
            .filter { $0.category == .students && $0.releaseDate == nil }
            .prefix(maxNetworkFetchPerPass)
            .map { $0 }
        guard missing.isEmpty == false else { return cached }

        var patches: [Int64: Date] = [:]
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
                    if let date = releaseDate(from: info) {
                        patches[entry.contentId] = date
                    }
                }
            }
            start = end
        }
        guard patches.isEmpty == false else { return cached }
        return apply(patches: patches, to: cached)
    }

    private func applyCachedReleaseDates(_ bundle: BaGuideCatalogBundle) async -> BaGuideCatalogBundle {
        var patches: [Int64: Date] = [:]
        for entry in bundle.entries where entry.releaseDate == nil {
            guard let cached = await cacheStore.load(BaStudentGuideInfo.self, for: .studentDetail(entry.contentId)),
                  let date = releaseDate(from: cached.value)
            else {
                continue
            }
            patches[entry.contentId] = date
        }
        return patches.isEmpty ? bundle : apply(patches: patches, to: bundle)
    }

    private func apply(patches: [Int64: Date], to bundle: BaGuideCatalogBundle) -> BaGuideCatalogBundle {
        BaGuideCatalogBundle(
            entries: bundle.entries.map { entry in
                entry.withReleaseDate(patches[entry.contentId])
            },
            syncedAt: bundle.syncedAt
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
