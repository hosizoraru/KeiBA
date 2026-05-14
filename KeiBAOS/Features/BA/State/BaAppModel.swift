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
    private let studentRepository: BaStudentGuideRepository
    private let officeRepository: BaOfficeRepository

    init(
        settingsStore: BaSettingsStore,
        cacheStore: BaCacheStore,
        imageCache: BaImageCache,
        activityPoolRepository: BaActivityPoolRepository,
        catalogRepository: BaGuideCatalogRepository,
        studentRepository: BaStudentGuideRepository,
        officeRepository: BaOfficeRepository
    ) {
        self.settingsStore = settingsStore
        self.cacheStore = cacheStore
        self.imageCache = imageCache
        self.activityPoolRepository = activityPoolRepository
        self.catalogRepository = catalogRepository
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

    func refreshActivities(force: Bool) async {
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

    func refreshPools(force: Bool) async {
        if poolState.isLoading { return }
        poolState.isLoading = true
        poolState.errorMessage = nil
        do {
            let snapshot = try await activityPoolRepository.fetchPools(server: settings.server)
            poolState = BaLoadableState(
                value: snapshot.value,
                isLoading: false,
                errorMessage: snapshot.sourceErrors.first,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(snapshot.value, for: .pools(settings.server), schemaVersion: 5, syncedAt: snapshot.syncedAt)
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

    func refreshCatalog(force: Bool) async {
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
            await cacheStore.save(snapshot.value, for: .catalog, schemaVersion: 1, syncedAt: snapshot.syncedAt)
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
                errorMessage: snapshot.sourceErrors.first,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(snapshot.value, for: .studentDetail(entry.contentId), schemaVersion: 1, syncedAt: snapshot.syncedAt)
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
        return source.filter { $0.matches(query: query) }
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

    func linkedCatalogEntry(for pool: BaPoolEntry) -> BaGuideCatalogEntry? {
        guard let bundle = catalogState.value else { return nil }
        if let contentId = pool.contentId {
            return bundle.entries.first { $0.contentId == contentId }
        }
        let poolName = pool.name
            .replacingOccurrences(of: #"\(.+?\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return bundle.entries.first { entry in
            entry.name == pool.name ||
                entry.name == poolName ||
                pool.name.localizedCaseInsensitiveContains(entry.name) ||
                entry.alias.localizedCaseInsensitiveContains(poolName)
        }
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
        guard let cached = await cacheStore.load([BaPoolEntry].self, for: .pools(settings.server)) else { return }
        poolState = BaLoadableState(
            value: cached.value,
            isLoading: false,
            errorMessage: nil,
            lastSyncAt: cached.syncedAt,
            isShowingCache: true
        )
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
}
