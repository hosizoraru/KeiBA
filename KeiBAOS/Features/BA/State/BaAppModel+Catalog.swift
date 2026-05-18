//
//  BaAppModel+Catalog.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func loadCatalogIfNeeded(now: Date = Date()) async {
        if catalogState.value == nil {
            await loadCachedCatalog()
        }
        guard settings.refreshInterval.shouldRefresh(lastSyncAt: catalogState.lastSyncAt, now: now) else { return }
        await refreshCatalog(force: false)
    }

    func refreshCatalog(force: Bool) async {
        if catalogState.isLoading { return }
        if force == false,
           catalogState.value != nil,
           settings.refreshInterval.shouldRefresh(lastSyncAt: catalogState.lastSyncAt) == false
        {
            return
        }
        catalogState.isLoading = true
        catalogState.errorMessage = nil
        do {
            let snapshot = try await catalogRepository.fetchCatalog()
            catalogState = BaLoadableState(
                value: snapshot.value,
                isLoading: false,
                errorMessage: nil,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(snapshot.value, for: .catalog, schemaVersion: Self.catalogCacheSchemaVersion, syncedAt: snapshot.syncedAt)
            reconcileFavoriteCatalogEntries(with: snapshot.value)
            let hydrated = await catalogReleaseDateHydrator.hydrate(
                bundle: snapshot.value,
                maxNetworkFetchPerPass: BaPlatformPerformanceProfile.catalogReleaseDateFetchLimit,
                batchSize: BaPlatformPerformanceProfile.catalogReleaseDateBatchSize
            )
            if hydrated != snapshot.value {
                catalogState = BaLoadableState(
                    value: hydrated,
                    isLoading: false,
                    errorMessage: nil,
                    lastSyncAt: snapshot.syncedAt,
                    isShowingCache: false
                )
                await cacheStore.save(hydrated, for: .catalog, schemaVersion: Self.catalogCacheSchemaVersion, syncedAt: snapshot.syncedAt)
                reconcileFavoriteCatalogEntries(with: hydrated)
            }
        } catch {
            guard Self.isCancellation(error) == false else {
                catalogState.isLoading = false
                return
            }
            await applyCatalogFailure(error)
        }
    }

    func entries(
        for category: BaCatalogCategory,
        query: String = "",
        sortMode: BaCatalogSortMode = .releaseDateDescending,
        filterSelection: BaCatalogFilterSelection = .empty,
        filterGroups: [BaCatalogFilterGroup] = []
    ) -> [BaGuideCatalogEntry] {
        let bundle = catalogState.value
        guard bundle != nil || category == .favorites else { return [] }
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: [BaGuideCatalogEntry]
        switch category {
        case .students:
            source = bundle?.entries(in: .students) ?? []
        case .npcSatellite:
            source = bundle?.entries(in: .npcSatellite) ?? []
        case .studentBgm:
            source = (bundle?.entries(in: .students) ?? [])
                .prefix(80)
                .map { $0.withCategory(.studentBgm) }
        case .favorites:
            source = favoriteCatalogEntries(from: bundle)
        }
        let queriedEntries = keyword.isEmpty
            ? source
            : source.filter { $0.matches(trimmedQuery: keyword) }
        let filterPlan = BaCatalogFilterPlan(selection: filterSelection, groups: filterGroups)
        let filteredEntries = filterPlan.isEmpty
            ? queriedEntries
            : queriedEntries.filter { filterPlan.matches($0) }
        return filteredEntries.sorted(using: sortMode, favoriteContentIDs: settings.favoriteContentIDs)
    }

    private func loadCachedCatalog() async {
        guard let cached = await cacheStore.load(BaGuideCatalogBundle.self, for: .catalog) else { return }
        guard cached.schemaVersion >= Self.catalogCacheSchemaVersion else { return }
        catalogState = BaLoadableState(
            value: cached.value,
            isLoading: false,
            errorMessage: nil,
            lastSyncAt: cached.syncedAt,
            isShowingCache: true
        )
        reconcileFavoriteCatalogEntries(with: cached.value)
    }

    private func applyCatalogFailure(_ error: Error) async {
        if catalogState.value == nil {
            await loadCachedCatalog()
        }
        catalogState.isLoading = false
        catalogState.errorMessage = error.localizedDescription
        catalogState.isShowingCache = catalogState.value != nil
    }
}
