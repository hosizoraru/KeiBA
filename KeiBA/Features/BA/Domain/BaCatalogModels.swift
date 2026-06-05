//
//  BaCatalogModels.swift
//  KeiBA
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
            BaL10n.string("ba.catalog.category.students")
        case .npcSatellite:
            BaL10n.string("ba.catalog.category.npcSatellite")
        case .studentBgm:
            BaL10n.string("ba.catalog.category.studentBgm")
        case .favorites:
            BaL10n.string("ba.catalog.category.favorites")
        }
    }

    var searchPrompt: String {
        switch self {
        case .students:
            BaL10n.string("ba.catalog.search.students.prompt")
        case .npcSatellite:
            BaL10n.string("ba.catalog.search.npc.prompt")
        case .studentBgm:
            BaL10n.string("ba.catalog.search.bgm.prompt")
        case .favorites:
            BaL10n.string("ba.catalog.search.favorites.prompt")
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
    var metadata: BaGuideCatalogMetadata? = nil

    var id: Int64 {
        contentId
    }

    var identityKeys: Set<Int64> {
        var keys: Set<Int64> = []
        if contentId > 0 {
            keys.insert(contentId)
        }
        if entryId > 0 {
            keys.insert(Int64(entryId))
        }
        return keys
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
            category: category,
            metadata: metadata
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
            category: category,
            metadata: metadata
        )
    }

    func withMetadata(_ metadata: BaGuideCatalogMetadata?) -> BaGuideCatalogEntry {
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
            category: category,
            metadata: metadata
        )
    }
}

nonisolated struct BaGuideCatalogBundle: Codable, Hashable, Sendable {
    let entries: [BaGuideCatalogEntry]
    let syncedAt: Date
    let studentFilterGroups: [BaCatalogFilterGroup]
    let npcSatelliteFilterGroups: [BaCatalogFilterGroup]

    // Pre-bucketed by category. The catalog view, the pool resolver, and the
    // student-detail same-name resolver all call entries(in:) on hot paths;
    // bucketing once at init turns each repeat call into an O(1) dictionary
    // lookup instead of a fresh O(catalog) filter walk.
    private let entriesByCategory: [BaCatalogCategory: [BaGuideCatalogEntry]]

    init(
        entries: [BaGuideCatalogEntry],
        syncedAt: Date,
        studentFilterGroups: [BaCatalogFilterGroup] = [],
        npcSatelliteFilterGroups: [BaCatalogFilterGroup] = []
    ) {
        self.entries = entries
        self.syncedAt = syncedAt
        self.studentFilterGroups = studentFilterGroups
        self.npcSatelliteFilterGroups = npcSatelliteFilterGroups
        entriesByCategory = Self.bucketed(entries)
    }

    private enum CodingKeys: String, CodingKey {
        case entries
        case syncedAt
        case studentFilterGroups
        case npcSatelliteFilterGroups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedEntries = try container.decode([BaGuideCatalogEntry].self, forKey: .entries)
        entries = decodedEntries
        syncedAt = try container.decode(Date.self, forKey: .syncedAt)
        studentFilterGroups = try container.decodeIfPresent([BaCatalogFilterGroup].self, forKey: .studentFilterGroups) ?? []
        npcSatelliteFilterGroups = try container.decodeIfPresent([BaCatalogFilterGroup].self, forKey: .npcSatelliteFilterGroups) ?? []
        entriesByCategory = Self.bucketed(decodedEntries)
    }

    func entries(in category: BaCatalogCategory) -> [BaGuideCatalogEntry] {
        entriesByCategory[category] ?? []
    }

    func filterGroups(for category: BaCatalogCategory) -> [BaCatalogFilterGroup] {
        switch category {
        case .students:
            studentFilterGroups
        case .npcSatellite:
            npcSatelliteFilterGroups
        case .studentBgm, .favorites:
            []
        }
    }

    // Hashable: the bucketed dictionary is derived state, so omit it from
    // hashing/equality. Two bundles are equal iff their stored fields match.
    func hash(into hasher: inout Hasher) {
        hasher.combine(entries)
        hasher.combine(syncedAt)
        hasher.combine(studentFilterGroups)
        hasher.combine(npcSatelliteFilterGroups)
    }

    static func == (lhs: BaGuideCatalogBundle, rhs: BaGuideCatalogBundle) -> Bool {
        lhs.entries == rhs.entries &&
            lhs.syncedAt == rhs.syncedAt &&
            lhs.studentFilterGroups == rhs.studentFilterGroups &&
            lhs.npcSatelliteFilterGroups == rhs.npcSatelliteFilterGroups
    }

    private static func bucketed(_ entries: [BaGuideCatalogEntry]) -> [BaCatalogCategory: [BaGuideCatalogEntry]] {
        Dictionary(grouping: entries, by: \.category)
    }
}
