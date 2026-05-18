//
//  BaCatalogSortMode.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaCatalogSortMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case defaultOrder
    case releaseDateDescending
    case releaseDateAscending

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .defaultOrder:
            BaL10n.string("ba.catalog.sort.default")
        case .releaseDateDescending:
            BaL10n.string("ba.catalog.sort.releaseDate.desc")
        case .releaseDateAscending:
            BaL10n.string("ba.catalog.sort.releaseDate.asc")
        }
    }
}

nonisolated extension Array where Element == BaGuideCatalogEntry {
    func sorted(using mode: BaCatalogSortMode, favoriteContentIDs: Set<Int64>) -> [BaGuideCatalogEntry] {
        let sortedBase: [BaGuideCatalogEntry]
        switch mode {
        case .defaultOrder, .releaseDateDescending, .releaseDateAscending:
            sortedBase = enumerated()
                .map { IndexedCatalogEntry(index: $0.offset, entry: $0.element) }
                .sorted { mode.isInIncreasingOrder($0, $1) }
                .map(\.entry)
        }

        guard favoriteContentIDs.isEmpty == false else { return sortedBase }

        var favoriteEntries: [BaGuideCatalogEntry] = []
        var regularEntries: [BaGuideCatalogEntry] = []
        favoriteEntries.reserveCapacity(favoriteContentIDs.count)
        regularEntries.reserveCapacity(Swift.max(sortedBase.count - favoriteContentIDs.count, 0))
        for entry in sortedBase {
            if favoriteContentIDs.contains(entry.contentId) {
                favoriteEntries.append(entry)
            } else {
                regularEntries.append(entry)
            }
        }
        return favoriteEntries + regularEntries
    }
}

private struct IndexedCatalogEntry {
    let index: Int
    let entry: BaGuideCatalogEntry
}

nonisolated private extension BaCatalogSortMode {
    func isInIncreasingOrder(_ lhs: IndexedCatalogEntry, _ rhs: IndexedCatalogEntry) -> Bool {
        switch self {
        case .defaultOrder:
            compareOrder(lhs, rhs)
        case .releaseDateDescending:
            compareDate(lhs, rhs, unknownDate: .distantPast, descending: true)
        case .releaseDateAscending:
            compareDate(lhs, rhs, unknownDate: .distantFuture, descending: false)
        }
    }

    func compareDate(
        _ lhs: IndexedCatalogEntry,
        _ rhs: IndexedCatalogEntry,
        unknownDate: Date,
        descending: Bool
    ) -> Bool {
        let lhsDate = lhs.entry.releaseDate ?? lhs.entry.createdAt ?? unknownDate
        let rhsDate = rhs.entry.releaseDate ?? rhs.entry.createdAt ?? unknownDate
        if lhsDate != rhsDate {
            return descending ? lhsDate > rhsDate : lhsDate < rhsDate
        }
        return compareOrder(lhs, rhs)
    }

    func compareOrder(_ lhs: IndexedCatalogEntry, _ rhs: IndexedCatalogEntry) -> Bool {
        if lhs.entry.order != rhs.entry.order {
            return lhs.entry.order < rhs.entry.order
        }
        return lhs.index < rhs.index
    }
}
