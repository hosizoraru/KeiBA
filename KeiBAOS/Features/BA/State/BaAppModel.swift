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
    var envelope: BaSettingsEnvelope
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
        let loadedEnvelope = settingsStore.loadEnvelope()
        let loadedSettings = loadedEnvelope.flattenedSettings()
        envelope = loadedEnvelope
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

    var currentProfile: BaServerProfile {
        envelope.profile(for: envelope.selectedServer)
    }

    func selectServer(_ server: BaServer) {
        let previousServer = settings.server
        envelope.selectedServer = server
        persistEnvelope(previousServer: previousServer)
    }

    func updateSettings(_ transform: (inout BaAppSettings) -> Void) {
        let previous = settings
        let previousServer = settings.server
        var next = settings
        transform(&next)
        applyFlattenedSettings(next, previous: previous)
        persistEnvelope(previousServer: previousServer)
    }

    func updateCurrentProfile(_ transform: (inout BaServerProfile) -> Void) {
        let previousServer = settings.server
        var profile = currentProfile
        transform(&profile)
        envelope.setProfile(profile, for: envelope.selectedServer)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
        persistEnvelope(previousServer: previousServer)
    }

    func updateGlobalSettings(_ transform: (inout BaGlobalSettings) -> Void) {
        let previousServer = settings.server
        transform(&envelope.globalSettings)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
        persistEnvelope(previousServer: previousServer)
    }

    func setCurrentAP(_ value: Int) {
        updateCurrentProfile { profile in
            let currentFraction = BaTimeMath.normalizedAP(profile.apCurrent) - Double(BaTimeMath.displayAP(profile.apCurrent))
            profile.apCurrent = BaTimeMath.normalizedAP(Double(min(max(value, 0), BaTimeMath.apMax)) + currentFraction)
            profile.apRegenBaseAt = Date()
            profile.apSyncAt = Date()
        }
    }

    func setAPLimit(_ value: Int) {
        updateCurrentProfile { profile in
            profile.apLimit = min(max(value, 0), BaTimeMath.apLimitMax)
        }
    }

    func claimCafeAP() {
        updateCurrentProfile { profile in
            let now = Date()
            let currentCafeAP = BaTimeMath.currentCafeAP(profile: profile, now: now)
            guard currentCafeAP > 0 else { return }
            profile.apCurrent = BaTimeMath.normalizedAP(profile.apCurrent + currentCafeAP)
            profile.apRegenBaseAt = now
            profile.apSyncAt = now
            profile.cafeApCurrent = 0
            profile.cafeStorageBaseAt = now
        }
    }

    func performCafeAction(_ kind: BaCafeActionKind) {
        updateCurrentProfile { profile in
            let now = Date()
            switch kind {
            case .headpat:
                let availableAt = BaTimeMath.nextHeadpatAvailable(lastHeadpatAt: profile.lastHeadpatAt, server: settings.server)
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastHeadpatAt = now
            case .inviteTicket1:
                let availableAt = BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket1At)
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastInviteTicket1At = now
            case .inviteTicket2:
                let availableAt = BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket2At)
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastInviteTicket2At = now
            }
        }
    }

    func resetCafeAction(_ kind: BaCafeActionKind) {
        updateCurrentProfile { profile in
            switch kind {
            case .headpat:
                profile.lastHeadpatAt = nil
            case .inviteTicket1:
                profile.lastInviteTicket1At = nil
            case .inviteTicket2:
                profile.lastInviteTicket2At = nil
            }
        }
    }

    private func persistEnvelope(previousServer: BaServer) {
        envelope = envelope.normalized()
        settings = envelope.flattenedSettings()
        settingsStore.saveEnvelope(envelope)
        if previousServer != settings.server {
            activityState = BaLoadableState()
            poolState = BaLoadableState()
        }
        refreshOfficeSnapshot()
    }

    private func applyFlattenedSettings(_ next: BaAppSettings, previous: BaAppSettings) {
        envelope.globalSettings.identityIndependentByServer = next.identityIndependentByServer
        envelope.globalSettings.showEndedActivities = next.showEndedActivities
        envelope.globalSettings.showEndedPools = next.showEndedPools
        envelope.globalSettings.showPreviewImages = next.showPreviewImages
        envelope.globalSettings.activityNotificationsEnabled = next.activityNotificationsEnabled
        envelope.globalSettings.poolNotificationsEnabled = next.poolNotificationsEnabled
        envelope.globalSettings.calendarUpcomingNotificationsEnabled = next.calendarUpcomingNotificationsEnabled
        envelope.globalSettings.calendarEndingNotificationsEnabled = next.calendarEndingNotificationsEnabled
        envelope.globalSettings.poolUpcomingNotificationsEnabled = next.poolUpcomingNotificationsEnabled
        envelope.globalSettings.poolEndingNotificationsEnabled = next.poolEndingNotificationsEnabled
        envelope.globalSettings.calendarPoolChangeNotificationsEnabled = next.calendarPoolChangeNotificationsEnabled
        envelope.globalSettings.calendarPoolNotifyLead = next.calendarPoolNotifyLead
        envelope.globalSettings.mediaAutoplayEnabled = next.mediaAutoplayEnabled
        envelope.globalSettings.mediaDownloadEnabled = next.mediaDownloadEnabled
        envelope.globalSettings.refreshInterval = next.refreshInterval
        envelope.globalSettings.favoriteContentIDs = next.favoriteContentIDs
        if next.server != previous.server {
            envelope.selectedServer = next.server
            return
        }
        var profile = currentProfile
        profile.nickname = next.nickname
        profile.friendCode = next.friendCode
        profile.apCurrent = next.apCurrent
        profile.apLimit = next.apLimit
        profile.apRegenBaseAt = next.apRegenBaseAt
        profile.apSyncAt = next.apSyncAt
        profile.cafeLevel = next.cafeLevel
        profile.cafeApCurrent = next.cafeApCurrent
        profile.cafeStorageBaseAt = next.cafeStorageBaseAt
        profile.lastHeadpatAt = next.lastHeadpatAt
        profile.lastInviteTicket1At = next.lastInviteTicket1At ?? next.lastInviteTicketAt
        profile.lastInviteTicket2At = next.lastInviteTicket2At
        profile.apNotificationsEnabled = next.apNotificationsEnabled
        profile.cafeApNotificationsEnabled = next.cafeApNotificationsEnabled
        profile.visitNotificationsEnabled = next.visitNotificationsEnabled
        profile.arenaRefreshNotificationsEnabled = next.arenaRefreshNotificationsEnabled
        profile.apNotifyThreshold = next.apNotifyThreshold
        profile.cafeApNotifyThreshold = next.cafeApNotifyThreshold
        profile.cafeVisitLastNotifiedAt = next.cafeVisitLastNotifiedAt
        profile.arenaRefreshLastNotifiedAt = next.arenaRefreshLastNotifiedAt
        envelope.setProfile(profile, for: envelope.selectedServer)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
    }

    private func synchronizeSharedIdentityIfNeeded(from server: BaServer) {
        guard envelope.globalSettings.identityIndependentByServer == false else { return }
        let source = envelope.profile(for: server)
        for target in BaServer.allCases {
            envelope.serverProfiles[target]?.nickname = source.nickname
            envelope.serverProfiles[target]?.friendCode = source.friendCode
        }
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
    private static let studentCatalogPID = 49443
}
