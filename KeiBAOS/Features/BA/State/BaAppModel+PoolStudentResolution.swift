//
//  BaAppModel+PoolStudentResolution.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func studentCatalogEntry(for pool: BaPoolEntry) -> BaGuideCatalogEntry? {
        let studentEntries = catalogState.value?.entries(in: .students) ?? []
        if let contentId = pool.contentId {
            if let entry = studentEntries.first(where: { $0.contentId == contentId }) {
                return entry
            }
            return fallbackStudentCatalogEntry(pool: pool, contentId: contentId, detailURL: pool.studentGuideOpenURL)
        }

        let resolvedPool = BaPoolStudentGuideResolver(catalogEntries: studentEntries).resolve(pool)
        guard let guideURL = resolvedPool.studentGuideOpenURL,
              let contentId = BaPoolStudentGuideResolver.contentID(from: guideURL)
        else {
            return nil
        }

        if let entry = studentEntries.first(where: { $0.contentId == contentId }) {
            return entry
        }
        return fallbackStudentCatalogEntry(pool: resolvedPool, contentId: contentId, detailURL: guideURL)
    }

    func studentCatalogEntry(forSameNameRole item: BaStudentProfileSameNameRoleItem) -> BaGuideCatalogEntry? {
        let catalogEntries = catalogState.value?.entries.filter {
            $0.category == .students || $0.category == .npcSatellite
        } ?? []
        return BaSameNameStudentCatalogResolver.catalogEntry(for: item, catalogEntries: catalogEntries)
    }

    func resolvePoolStudentGuideURLs(
        entries: [BaPoolEntry],
        server: BaServer,
        allowCatalogNetwork: Bool
    ) async -> [BaPoolEntry] {
        guard entries.isEmpty == false else { return entries }

        var resolved = entries.map(BaPoolStudentGuideResolver.empty.resolve)
        if needsStudentCatalogResolution(resolved) == false {
            return resolved
        }

        let cachedEntries = await availableStudentCatalogEntries()
        if cachedEntries.isEmpty == false {
            let cachedResolver = BaPoolStudentGuideResolver(catalogEntries: cachedEntries)
            resolved = resolved.map(cachedResolver.resolve)
        }
        guard server == .cn, allowCatalogNetwork, needsStudentCatalogResolution(resolved) else {
            return resolved
        }

        guard let networkSnapshot = try? await catalogRepository.fetchStudentCatalog() else {
            return resolved
        }
        let networkResolver = BaPoolStudentGuideResolver(catalogEntries: networkSnapshot.value)
        return resolved.map(networkResolver.resolve)
    }

    private func availableStudentCatalogEntries() async -> [BaGuideCatalogEntry] {
        if let bundle = catalogState.value {
            return bundle.entries(in: .students)
        }
        if let cached = await cacheStore.load(BaGuideCatalogBundle.self, for: .catalog) {
            guard cached.schemaVersion >= Self.catalogCacheSchemaVersion else { return [] }
            return cached.value.entries(in: .students)
        }
        return []
    }

    private func needsStudentCatalogResolution(_ entries: [BaPoolEntry]) -> Bool {
        entries.contains { $0.studentGuideOpenURL == nil }
    }

    private func fallbackStudentCatalogEntry(
        pool: BaPoolEntry,
        contentId: Int64,
        detailURL: URL?
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: Self.studentCatalogPID,
            contentId: contentId,
            name: pool.name,
            alias: pool.alias,
            aliasDisplay: pool.alias,
            iconURL: pool.imageURL,
            type: 0,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: detailURL ?? URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
            category: .students
        )
    }
}
