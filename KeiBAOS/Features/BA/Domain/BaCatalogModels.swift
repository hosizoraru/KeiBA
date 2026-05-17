//
//  BaCatalogModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaCatalogCategory: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case students
    case npcSatellite
    case studentBgm
    case favorites

    static let catalogCases: [BaCatalogCategory] = [.students, .npcSatellite]
    static let libraryCases: [BaCatalogCategory] = [.studentBgm, .favorites]

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.category.students")
        case .npcSatellite:
            String(localized: "ba.catalog.category.npcSatellite")
        case .studentBgm:
            String(localized: "ba.catalog.category.studentBgm")
        case .favorites:
            String(localized: "ba.catalog.category.favorites")
        }
    }

    var searchPrompt: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.search.students.prompt")
        case .npcSatellite:
            String(localized: "ba.catalog.search.npc.prompt")
        case .studentBgm:
            String(localized: "ba.catalog.search.bgm.prompt")
        case .favorites:
            String(localized: "ba.catalog.search.favorites.prompt")
        }
    }

    var gameKeePID: Int {
        switch self {
        case .students:
            49_443
        case .npcSatellite:
            107_619
        case .studentBgm, .favorites:
            0
        }
    }

    static let gameKeeSecondPageID = 23_941
}

nonisolated struct BaGuideCatalogEntry: Identifiable, Codable, Hashable, Sendable {
    let entryId: Int
    let pid: Int
    let contentId: Int64
    let name: String
    let alias: String
    let aliasDisplay: String
    let iconURL: URL?
    let type: Int
    let order: Int
    let createdAt: Date?
    let releaseDate: Date?
    let detailURL: URL?
    let category: BaCatalogCategory

    var id: Int64 {
        contentId
    }

    func matches(query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return matches(trimmedQuery: keyword)
    }

    func matches(trimmedQuery keyword: String) -> Bool {
        guard keyword.isEmpty == false else { return true }
        return name.localizedCaseInsensitiveContains(keyword) ||
            alias.localizedCaseInsensitiveContains(keyword) ||
            "\(contentId)".contains(keyword)
    }

    func withCategory(_ category: BaCatalogCategory) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: entryId,
            pid: pid,
            contentId: contentId,
            name: name,
            alias: alias,
            aliasDisplay: aliasDisplay,
            iconURL: iconURL,
            type: type,
            order: order,
            createdAt: createdAt,
            releaseDate: releaseDate,
            detailURL: detailURL,
            category: category
        )
    }

    func withReleaseDate(_ releaseDate: Date?) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: entryId,
            pid: pid,
            contentId: contentId,
            name: name,
            alias: alias,
            aliasDisplay: aliasDisplay,
            iconURL: iconURL,
            type: type,
            order: order,
            createdAt: createdAt,
            releaseDate: releaseDate ?? self.releaseDate,
            detailURL: detailURL,
            category: category
        )
    }
}

nonisolated struct BaGuideCatalogBundle: Codable, Hashable, Sendable {
    let entries: [BaGuideCatalogEntry]
    let syncedAt: Date

    func entries(in category: BaCatalogCategory) -> [BaGuideCatalogEntry] {
        entries.filter { $0.category == category }
    }
}
