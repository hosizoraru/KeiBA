//
//  BaPoolCatalogEntryResolver.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated struct BaPoolCatalogEntryResolver {
    private let studentEntries: [BaGuideCatalogEntry]
    private let guideResolver: BaPoolStudentGuideResolver

    init(studentEntries: [BaGuideCatalogEntry]) {
        self.studentEntries = studentEntries
        guideResolver = BaPoolStudentGuideResolver(catalogEntries: studentEntries)
    }

    func catalogEntry(for pool: BaPoolEntry) -> BaGuideCatalogEntry? {
        if let contentId = pool.contentId {
            if let entry = studentEntries.first(where: { $0.contentId == contentId }) {
                return entry
            }
            return fallbackCatalogEntry(pool: pool, contentId: contentId, detailURL: pool.studentGuideOpenURL)
        }

        let resolvedPool = guideResolver.resolve(pool)
        guard let guideURL = resolvedPool.studentGuideOpenURL,
              let contentId = BaPoolStudentGuideResolver.contentID(from: guideURL)
        else {
            return nil
        }

        if let entry = studentEntries.first(where: { $0.contentId == contentId }) {
            return entry
        }
        return fallbackCatalogEntry(pool: resolvedPool, contentId: contentId, detailURL: guideURL)
    }

    private func fallbackCatalogEntry(
        pool: BaPoolEntry,
        contentId: Int64,
        detailURL: URL?
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: BaCatalogCategory.students.gameKeePID,
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
