//
//  BaAppModel.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation
import Observation

@Observable
@MainActor
final class BaAppModel {
    var settings: BaAppSettings
    var officeSnapshot: BaOfficeSnapshot
    var activityState = BaLoadableState<[BaActivityEntry]>()
    var poolState = BaLoadableState<[BaPoolEntry]>()
    var catalogState = BaLoadableState<BaGuideCatalogBundle>()
    var studentDetailStates: [Int64: BaLoadableState<BaStudentGuideInfo>] = [:]

    private let settingsStore: BaSettingsStore
    private let cacheStore: BaCacheStore
    private let imageCache: BaImageCache
    private let activityPoolRepository: BaActivityPoolRepository
    private let catalogRepository: BaGuideCatalogRepository
    private let catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator
    private let studentRepository: BaStudentGuideRepository
    private let officeRepository: BaOfficeRepository

    init(
        settingsStore: BaSettingsStore,
        cacheStore: BaCacheStore,
        imageCache: BaImageCache,
        activityPoolRepository: BaActivityPoolRepository,
        catalogRepository: BaGuideCatalogRepository,
        catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator,
        studentRepository: BaStudentGuideRepository,
        officeRepository: BaOfficeRepository
    ) {
        self.settingsStore = settingsStore
        self.cacheStore = cacheStore
        self.imageCache = imageCache
        self.activityPoolRepository = activityPoolRepository
        self.catalogRepository = catalogRepository
        self.catalogReleaseDateHydrator = catalogReleaseDateHydrator
        self.studentRepository = studentRepository
        self.officeRepository = officeRepository
        let loadedSettings = settingsStore.load()
        settings = loadedSettings
        officeSnapshot = officeRepository.snapshot(settings: loadedSettings)
    }

    static func live() -> BaAppModel {
        let client = GameKeeClient()
        let cacheStore = BaCacheStore()
        let imageCache = BaImageCache(client: client)
        return BaAppModel(
            settingsStore: BaSettingsStore(),
            cacheStore: cacheStore,
            imageCache: imageCache,
            activityPoolRepository: BaActivityPoolRepository(client: client),
            catalogRepository: BaGuideCatalogRepository(client: client),
            catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator(
                cacheStore: cacheStore,
                studentRepository: BaStudentGuideRepository(client: client)
            ),
            studentRepository: BaStudentGuideRepository(client: client),
            officeRepository: BaOfficeRepository()
        )
    }

    func updateSettings(_ transform: (inout BaAppSettings) -> Void) {
        let previousServer = settings.server
        var next = settings
        transform(&next)
        settings = next
        settingsStore.save(next)
        if previousServer != next.server {
            activityState = BaLoadableState()
            poolState = BaLoadableState()
        }
        refreshOfficeSnapshot()
    }

    func refreshOfficeSnapshot(now: Date = Date()) {
        officeSnapshot = officeRepository.snapshot(settings: settings, now: now)
    }

    func loadActivitiesIfNeeded() async {
        if activityState.value == nil {
            await loadCachedActivities()
            await refreshActivities(force: false)
        }
    }

    func refreshActivities(force _: Bool) async {
        if activityState.isLoading { return }
        activityState.isLoading = true
        activityState.errorMessage = nil
        do {
            let snapshot = try await activityPoolRepository.fetchActivities(server: settings.server)
            activityState = BaLoadableState(
                value: snapshot.value,
                isLoading: false,
                errorMessage: snapshot.sourceErrors.first,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(snapshot.value, for: .activities(settings.server), schemaVersion: 3, syncedAt: snapshot.syncedAt)
        } catch {
            await applyActivityFailure(error)
        }
    }

    func loadPoolsIfNeeded() async {
        if poolState.value == nil {
            await loadCachedPools()
            await refreshPools(force: false)
        }
    }

    func refreshPools(force _: Bool) async {
        if poolState.isLoading { return }
        let server = settings.server
        poolState.isLoading = true
        poolState.errorMessage = nil
        do {
            let snapshot = try await activityPoolRepository.fetchPools(server: server)
            let entries = await resolvePoolStudentGuideURLs(
                entries: snapshot.value,
                server: server,
                allowCatalogNetwork: true
            )
            guard settings.server == server else { return }
            poolState = BaLoadableState(
                value: entries,
                isLoading: false,
                errorMessage: snapshot.sourceErrors.first,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(entries, for: .pools(server), schemaVersion: Self.poolCacheSchemaVersion, syncedAt: snapshot.syncedAt)
        } catch {
            await applyPoolFailure(error)
        }
    }

    func loadCatalogIfNeeded() async {
        if catalogState.value == nil {
            await loadCachedCatalog()
            await refreshCatalog(force: false)
        }
    }

    func refreshCatalog(force _: Bool) async {
        if catalogState.isLoading { return }
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
            await cacheStore.save(snapshot.value, for: .catalog, schemaVersion: 2, syncedAt: snapshot.syncedAt)
            let hydrated = await catalogReleaseDateHydrator.hydrate(bundle: snapshot.value)
            if hydrated != snapshot.value {
                catalogState = BaLoadableState(
                    value: hydrated,
                    isLoading: false,
                    errorMessage: nil,
                    lastSyncAt: snapshot.syncedAt,
                    isShowingCache: false
                )
                await cacheStore.save(hydrated, for: .catalog, schemaVersion: 2, syncedAt: snapshot.syncedAt)
            }
        } catch {
            await applyCatalogFailure(error)
        }
    }

    func loadStudentDetail(entry: BaGuideCatalogEntry, force: Bool = false) async {
        if force == false, studentDetailStates[entry.contentId]?.value != nil {
            return
        }
        if force == false, let cached = await cacheStore.load(BaStudentGuideInfo.self, for: .studentDetail(entry.contentId)) {
            studentDetailStates[entry.contentId] = BaLoadableState(
                value: cached.value,
                isLoading: false,
                errorMessage: nil,
                lastSyncAt: cached.syncedAt,
                isShowingCache: true
            )
        }
        var state = studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
        state.isLoading = true
        state.errorMessage = nil
        studentDetailStates[entry.contentId] = state
        do {
            let snapshot = try await studentRepository.fetchStudentDetail(entry: entry)
            studentDetailStates[entry.contentId] = BaLoadableState(
                value: snapshot.value,
                isLoading: false,
                errorMessage: BaDataErrorPresenter.studentDetailMessage(for: snapshot.sourceErrors.first),
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(
                snapshot.value,
                for: .studentDetail(entry.contentId),
                schemaVersion: 2,
                syncedAt: snapshot.syncedAt
            )
        } catch {
            var failed = studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
            failed.isLoading = false
            failed.errorMessage = error.localizedDescription
            studentDetailStates[entry.contentId] = failed
        }
    }

    func imageData(for url: URL, refererPath: String = "/ba") async throws -> Data {
        try await imageCache.data(for: url, refererPath: refererPath)
    }

    func imageCacheSummary() async -> String {
        await imageCache.summary()
    }

    func entries(for category: BaCatalogCategory, query: String = "") -> [BaGuideCatalogEntry] {
        guard let bundle = catalogState.value else { return [] }
        let source: [BaGuideCatalogEntry]
        switch category {
        case .students:
            source = bundle.entries(in: .students)
        case .npcSatellite:
            source = bundle.entries(in: .npcSatellite)
        case .studentBgm:
            source = bundle.entries(in: .students)
                .prefix(80)
                .map { $0.withCategory(.studentBgm) }
        case .favorites:
            source = bundle.entries.filter { settings.favoriteContentIDs.contains($0.contentId) }
        }
        return source
            .filter { $0.matches(query: query) }
            .sorted { lhs, rhs in
                let lhsFavorite = settings.favoriteContentIDs.contains(lhs.contentId)
                let rhsFavorite = settings.favoriteContentIDs.contains(rhs.contentId)
                if lhsFavorite != rhsFavorite {
                    return lhsFavorite
                }
                if lhs.releaseDate != rhs.releaseDate {
                    return (lhs.releaseDate ?? .distantPast) > (rhs.releaseDate ?? .distantPast)
                }
                return lhs.order < rhs.order
            }
    }

    func isFavorite(_ entry: BaGuideCatalogEntry) -> Bool {
        settings.favoriteContentIDs.contains(entry.contentId)
    }

    func toggleFavorite(_ entry: BaGuideCatalogEntry) {
        updateSettings { settings in
            if settings.favoriteContentIDs.contains(entry.contentId) {
                settings.favoriteContentIDs.remove(entry.contentId)
            } else {
                settings.favoriteContentIDs.insert(entry.contentId)
            }
        }
    }

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

    private func loadCachedActivities() async {
        guard let cached = await cacheStore.load([BaActivityEntry].self, for: .activities(settings.server)) else { return }
        activityState = BaLoadableState(
            value: cached.value,
            isLoading: false,
            errorMessage: nil,
            lastSyncAt: cached.syncedAt,
            isShowingCache: true
        )
    }

    private func loadCachedPools() async {
        let server = settings.server
        guard let cached = await cacheStore.load([BaPoolEntry].self, for: .pools(server)) else { return }
        let entries = await resolvePoolStudentGuideURLs(
            entries: cached.value,
            server: server,
            allowCatalogNetwork: false
        )
        poolState = BaLoadableState(
            value: entries,
            isLoading: false,
            errorMessage: nil,
            lastSyncAt: cached.syncedAt,
            isShowingCache: true
        )
        if entries != cached.value {
            await cacheStore.save(entries, for: .pools(server), schemaVersion: Self.poolCacheSchemaVersion, syncedAt: cached.syncedAt)
        }
    }

    private func loadCachedCatalog() async {
        guard let cached = await cacheStore.load(BaGuideCatalogBundle.self, for: .catalog) else { return }
        catalogState = BaLoadableState(
            value: cached.value,
            isLoading: false,
            errorMessage: nil,
            lastSyncAt: cached.syncedAt,
            isShowingCache: true
        )
    }

    private func applyActivityFailure(_ error: Error) async {
        if activityState.value == nil {
            await loadCachedActivities()
        }
        activityState.isLoading = false
        activityState.errorMessage = error.localizedDescription
        activityState.isShowingCache = activityState.value != nil
    }

    private func applyPoolFailure(_ error: Error) async {
        if poolState.value == nil {
            await loadCachedPools()
        }
        poolState.isLoading = false
        poolState.errorMessage = error.localizedDescription
        poolState.isShowingCache = poolState.value != nil
    }

    private func applyCatalogFailure(_ error: Error) async {
        if catalogState.value == nil {
            await loadCachedCatalog()
        }
        catalogState.isLoading = false
        catalogState.errorMessage = error.localizedDescription
        catalogState.isShowingCache = catalogState.value != nil
    }

    private func resolvePoolStudentGuideURLs(
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

    private static let poolCacheSchemaVersion = 6
    private static let studentCatalogPID = 49_443
}
