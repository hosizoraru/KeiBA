//
//  BaAppModel+Favorites.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func isFavorite(_ entry: BaGuideCatalogEntry) -> Bool {
        BaFavoriteCatalogResolver.isFavorite(
            entry,
            contentIDs: settings.favoriteContentIDs,
            snapshots: settings.favoriteCatalogEntries
        )
    }

    func toggleFavorite(_ entry: BaGuideCatalogEntry) {
        let catalogEntries = catalogState.value?.entries ?? []
        let detailInfo = studentDetailStates[entry.contentId]?.value
        updateGlobalSettings { global in
            let selection = BaFavoriteCatalogResolver.toggledSelection(
                for: entry,
                catalogEntries: catalogEntries,
                storedContentIDs: global.favoriteContentIDs,
                storedSnapshots: global.favoriteCatalogEntries,
                detailInfo: detailInfo
            )
            global.favoriteContentIDs = selection.contentIDs
            global.favoriteCatalogEntries = selection.catalogEntries
        }
    }

    func favoriteCatalogEntries(from bundle: BaGuideCatalogBundle?) -> [BaGuideCatalogEntry] {
        BaFavoriteCatalogResolver.favoriteCatalogEntries(
            from: bundle,
            contentIDs: settings.favoriteContentIDs,
            snapshots: settings.favoriteCatalogEntries
        )
    }

    func reconcileFavoriteCatalogEntries(with bundle: BaGuideCatalogBundle) {
        let previous = envelope.globalSettings
        let next = BaFavoriteCatalogResolver.reconciledSettings(previous, with: bundle)
        guard next != previous else { return }
        envelope.globalSettings = next
        settings = envelope.flattenedSettings()
        settingsStore.saveEnvelope(envelope)
    }

    nonisolated func sharesFavoriteIdentity(_ lhs: BaGuideCatalogEntry, _ rhs: BaGuideCatalogEntry) -> Bool {
        BaFavoriteCatalogResolver.sharesIdentity(lhs, rhs)
    }

    nonisolated func favoriteIdentityKeys(for entry: BaGuideCatalogEntry) -> Set<Int64> {
        BaFavoriteCatalogResolver.identityKeys(for: entry)
    }
}
