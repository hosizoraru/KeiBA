//
//  BaFavoriteCatalogResolver.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated struct BaFavoriteCatalogSelection: Equatable, Sendable {
    var contentIDs: Set<Int64>
    var catalogEntries: [BaGuideCatalogEntry]

    func normalized() -> BaFavoriteCatalogSelection {
        var entries: [BaGuideCatalogEntry] = []
        for entry in catalogEntries where entry.contentId > 0 {
            guard entries.contains(where: { BaFavoriteCatalogResolver.sharesIdentity($0, entry) }) == false else { continue }
            entries.append(entry)
        }
        var ids = contentIDs
        ids.formUnion(entries.map(\.contentId))
        return BaFavoriteCatalogSelection(contentIDs: ids, catalogEntries: entries)
    }
}

nonisolated enum BaFavoriteCatalogResolver {
    static func isFavorite(
        _ entry: BaGuideCatalogEntry,
        contentIDs: Set<Int64>,
        snapshots: [BaGuideCatalogEntry]
    ) -> Bool {
        if identityKeys(for: entry).isDisjoint(with: contentIDs) == false {
            return true
        }
        return snapshots.contains { sharesIdentity($0, entry) }
    }

    static func toggledSelection(
        for entry: BaGuideCatalogEntry,
        catalogEntries: [BaGuideCatalogEntry],
        storedContentIDs: Set<Int64>,
        storedSnapshots: [BaGuideCatalogEntry],
        detailInfo: BaStudentGuideInfo? = nil
    ) -> BaFavoriteCatalogSelection {
        let canonicalEntry = canonicalEntry(
            for: entry,
            catalogEntries: catalogEntries,
            snapshots: storedSnapshots,
            detailInfo: detailInfo
        )
        var selection = BaFavoriteCatalogSelection(
            contentIDs: storedContentIDs,
            catalogEntries: storedSnapshots
        )
        if isFavorite(entry, contentIDs: selection.contentIDs, snapshots: selection.catalogEntries) ||
            isFavorite(canonicalEntry, contentIDs: selection.contentIDs, snapshots: selection.catalogEntries)
        {
            let removeKeys = identityKeys(for: entry).union(identityKeys(for: canonicalEntry))
            selection.contentIDs.subtract(removeKeys)
            selection.catalogEntries.removeAll { snapshot in
                identityKeys(for: snapshot).isDisjoint(with: removeKeys) == false
            }
        } else {
            selection.contentIDs.insert(canonicalEntry.contentId)
            selection.catalogEntries.removeAll { sharesIdentity($0, canonicalEntry) }
            selection.catalogEntries.append(canonicalEntry)
        }
        return selection.normalized()
    }

    static func favoriteCatalogEntries(
        from bundle: BaGuideCatalogBundle?,
        contentIDs: Set<Int64>,
        snapshots: [BaGuideCatalogEntry]
    ) -> [BaGuideCatalogEntry] {
        guard contentIDs.isEmpty == false || snapshots.isEmpty == false else { return [] }
        var entries: [BaGuideCatalogEntry] = []

        if let bundle {
            for entry in bundle.entries where isFavorite(entry, contentIDs: contentIDs, snapshots: snapshots) {
                append(entry, to: &entries)
            }
        }
        for snapshot in snapshots {
            append(snapshot, to: &entries)
        }
        return entries
    }

    static func reconciledSettings(
        _ previous: BaGlobalSettings,
        with bundle: BaGuideCatalogBundle
    ) -> BaGlobalSettings {
        let favoriteIDs = previous.favoriteContentIDs
        var entries: [BaGuideCatalogEntry] = []
        var resolvedLegacyIDs = Set<Int64>()

        for entry in bundle.entries {
            let entryKeys = identityKeys(for: entry)
            if entryKeys.isDisjoint(with: favoriteIDs) == false {
                resolvedLegacyIDs.formUnion(entryKeys.intersection(favoriteIDs))
                append(entry, to: &entries)
            }
        }
        for snapshot in previous.favoriteCatalogEntries {
            if let current = bundle.entries.first(where: { sharesIdentity($0, snapshot) }) {
                append(current, to: &entries)
            } else {
                append(snapshot, to: &entries)
            }
        }

        let resolvedContentIDs = Set(entries.map(\.contentId))
        let unresolvedIDs = favoriteIDs.subtracting(resolvedLegacyIDs).subtracting(resolvedContentIDs)
        var next = previous
        next.favoriteCatalogEntries = entries
        next.favoriteContentIDs = resolvedContentIDs.union(unresolvedIDs)
        return next.normalized()
    }

    static func sharesIdentity(_ lhs: BaGuideCatalogEntry, _ rhs: BaGuideCatalogEntry) -> Bool {
        identityKeys(for: lhs).isDisjoint(with: identityKeys(for: rhs)) == false
    }

    static func identityKeys(for entry: BaGuideCatalogEntry) -> Set<Int64> {
        entry.identityKeys
    }

    private static func canonicalEntry(
        for entry: BaGuideCatalogEntry,
        catalogEntries: [BaGuideCatalogEntry],
        snapshots: [BaGuideCatalogEntry],
        detailInfo: BaStudentGuideInfo?
    ) -> BaGuideCatalogEntry {
        if let match = catalogEntries.first(where: { sharesIdentity($0, entry) }) {
            return match
        }
        if let match = snapshots.first(where: { sharesIdentity($0, entry) }) {
            return match
        }
        if let detailInfo, detailInfo.contentId != entry.contentId {
            return BaGuideCatalogEntry(
                entryId: entry.entryId,
                pid: entry.pid,
                contentId: detailInfo.contentId,
                name: detailInfo.title,
                alias: entry.alias,
                aliasDisplay: entry.aliasDisplay,
                iconURL: detailInfo.imageURL ?? entry.iconURL,
                type: entry.type,
                order: entry.order,
                createdAt: entry.createdAt,
                releaseDate: entry.releaseDate,
                detailURL: detailInfo.sourceURL ?? URL(string: "https://www.gamekee.com/ba/tj/\(detailInfo.contentId).html"),
                category: entry.category,
                metadata: entry.metadata
            )
        }
        return entry
    }

    private static func append(_ entry: BaGuideCatalogEntry, to entries: inout [BaGuideCatalogEntry]) {
        guard entries.contains(where: { sharesIdentity($0, entry) }) == false else { return }
        entries.append(entry)
    }
}
