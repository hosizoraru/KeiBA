//
//  BaAppModel+Favorites.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func isFavorite(_ entry: BaGuideCatalogEntry) -> Bool {
        isFavoriteEntry(entry, ids: settings.favoriteContentIDs, snapshots: settings.favoriteCatalogEntries)
    }

    func toggleFavorite(_ entry: BaGuideCatalogEntry) {
        let canonicalEntry = canonicalFavoriteEntry(for: entry)
        updateGlobalSettings { global in
            if isFavoriteEntry(entry, ids: global.favoriteContentIDs, snapshots: global.favoriteCatalogEntries) ||
                isFavoriteEntry(canonicalEntry, ids: global.favoriteContentIDs, snapshots: global.favoriteCatalogEntries)
            {
                let removeKeys = favoriteIdentityKeys(for: entry).union(favoriteIdentityKeys(for: canonicalEntry))
                global.favoriteContentIDs.subtract(removeKeys)
                global.favoriteCatalogEntries.removeAll { snapshot in
                    favoriteIdentityKeys(for: snapshot).isDisjoint(with: removeKeys) == false
                }
            } else {
                global.favoriteContentIDs.insert(canonicalEntry.contentId)
                global.favoriteCatalogEntries.removeAll { snapshot in
                    sharesFavoriteIdentity(snapshot, canonicalEntry)
                }
                global.favoriteCatalogEntries.append(canonicalEntry)
            }
        }
    }

    func favoriteCatalogEntries(from bundle: BaGuideCatalogBundle?) -> [BaGuideCatalogEntry] {
        let ids = settings.favoriteContentIDs
        let snapshots = settings.favoriteCatalogEntries
        guard ids.isEmpty == false || snapshots.isEmpty == false else { return [] }
        var entries: [BaGuideCatalogEntry] = []

        if let bundle {
            for entry in bundle.entries where isFavoriteEntry(entry, ids: ids, snapshots: snapshots) {
                appendFavoriteEntry(entry, to: &entries)
            }
        }
        for snapshot in snapshots {
            appendFavoriteEntry(snapshot, to: &entries)
        }
        return entries
    }

    func reconcileFavoriteCatalogEntries(with bundle: BaGuideCatalogBundle) {
        let previous = envelope.globalSettings
        let favoriteIDs = previous.favoriteContentIDs
        var entries: [BaGuideCatalogEntry] = []
        var resolvedLegacyIDs = Set<Int64>()

        for entry in bundle.entries {
            let entryKeys = favoriteIdentityKeys(for: entry)
            if entryKeys.isDisjoint(with: favoriteIDs) == false {
                resolvedLegacyIDs.formUnion(entryKeys.intersection(favoriteIDs))
                appendFavoriteEntry(entry, to: &entries)
            }
        }
        for snapshot in previous.favoriteCatalogEntries {
            if let current = bundle.entries.first(where: { sharesFavoriteIdentity($0, snapshot) }) {
                appendFavoriteEntry(current, to: &entries)
            } else {
                appendFavoriteEntry(snapshot, to: &entries)
            }
        }

        let resolvedContentIDs = Set(entries.map(\.contentId))
        let unresolvedIDs = favoriteIDs.subtracting(resolvedLegacyIDs).subtracting(resolvedContentIDs)
        var next = previous
        next.favoriteCatalogEntries = entries
        next.favoriteContentIDs = resolvedContentIDs.union(unresolvedIDs)
        next = next.normalized()
        guard next != previous else { return }
        envelope.globalSettings = next
        settings = envelope.flattenedSettings()
        settingsStore.saveEnvelope(envelope)
    }

    nonisolated func sharesFavoriteIdentity(_ lhs: BaGuideCatalogEntry, _ rhs: BaGuideCatalogEntry) -> Bool {
        favoriteIdentityKeys(for: lhs).isDisjoint(with: favoriteIdentityKeys(for: rhs)) == false
    }

    nonisolated func favoriteIdentityKeys(for entry: BaGuideCatalogEntry) -> Set<Int64> {
        var keys: Set<Int64> = []
        if entry.contentId > 0 {
            keys.insert(entry.contentId)
        }
        if entry.entryId > 0 {
            keys.insert(Int64(entry.entryId))
        }
        return keys
    }

    private func canonicalFavoriteEntry(for entry: BaGuideCatalogEntry) -> BaGuideCatalogEntry {
        if let match = catalogState.value?.entries.first(where: { sharesFavoriteIdentity($0, entry) }) {
            return match
        }
        if let match = settings.favoriteCatalogEntries.first(where: { sharesFavoriteIdentity($0, entry) }) {
            return match
        }
        if let info = studentDetailStates[entry.contentId]?.value, info.contentId != entry.contentId {
            return BaGuideCatalogEntry(
                entryId: entry.entryId,
                pid: entry.pid,
                contentId: info.contentId,
                name: info.title,
                alias: entry.alias,
                aliasDisplay: entry.aliasDisplay,
                iconURL: info.imageURL ?? entry.iconURL,
                type: entry.type,
                order: entry.order,
                createdAt: entry.createdAt,
                releaseDate: entry.releaseDate,
                detailURL: info.sourceURL ?? URL(string: "https://www.gamekee.com/ba/tj/\(info.contentId).html"),
                category: entry.category
            )
        }
        return entry
    }

    private nonisolated func appendFavoriteEntry(_ entry: BaGuideCatalogEntry, to entries: inout [BaGuideCatalogEntry]) {
        guard entries.contains(where: { sharesFavoriteIdentity($0, entry) }) == false else { return }
        entries.append(entry)
    }

    private nonisolated func isFavoriteEntry(
        _ entry: BaGuideCatalogEntry,
        ids: Set<Int64>,
        snapshots: [BaGuideCatalogEntry]
    ) -> Bool {
        if favoriteIdentityKeys(for: entry).isDisjoint(with: ids) == false {
            return true
        }
        return snapshots.contains { sharesFavoriteIdentity($0, entry) }
    }
}
