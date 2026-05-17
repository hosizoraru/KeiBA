//
//  BaAppModel+Timeline.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func loadTimelineCachesIfNeeded() async {
        if activityState.value == nil {
            await loadCachedActivities()
        }
        if poolState.value == nil {
            await loadCachedPools()
        }
    }

    func refreshTimelineIfNeeded(now: Date = Date()) async {
        async let activities: Void = loadActivitiesIfNeeded(now: now)
        async let pools: Void = loadPoolsIfNeeded(now: now)
        _ = await (activities, pools)
    }

    func loadActivitiesIfNeeded(now: Date = Date()) async {
        if activityState.value == nil {
            await loadCachedActivities()
        }
        guard settings.refreshInterval.shouldRefresh(lastSyncAt: activityState.lastSyncAt, now: now) else { return }
        await refreshActivities(force: false)
    }

    func refreshActivities(force: Bool) async {
        if activityState.isLoading { return }
        if force == false,
           activityState.value != nil,
           settings.refreshInterval.shouldRefresh(lastSyncAt: activityState.lastSyncAt) == false
        {
            return
        }
        let server = settings.server
        activityState.isLoading = true
        activityState.errorMessage = nil
        do {
            let snapshot = try await activityPoolRepository.fetchActivities(server: server)
            guard settings.server == server else { return }
            activityState = BaLoadableState(
                value: snapshot.value,
                isLoading: false,
                errorMessage: snapshot.sourceErrors.first,
                lastSyncAt: snapshot.syncedAt,
                isShowingCache: false
            )
            await cacheStore.save(snapshot.value, for: .activities(server), schemaVersion: 3, syncedAt: snapshot.syncedAt)
            scheduleNotificationRefresh(delay: BaPlatformPerformanceProfile.notificationTimelineRefreshDelay)
        } catch {
            guard settings.server == server else { return }
            guard Self.isCancellation(error) == false else {
                activityState.isLoading = false
                return
            }
            await applyActivityFailure(error)
        }
    }

    func loadPoolsIfNeeded(now: Date = Date()) async {
        if poolState.value == nil {
            await loadCachedPools()
        }
        guard settings.refreshInterval.shouldRefresh(lastSyncAt: poolState.lastSyncAt, now: now) else { return }
        await refreshPools(force: false)
    }

    func refreshPools(force: Bool) async {
        if poolState.isLoading { return }
        if force == false,
           poolState.value != nil,
           settings.refreshInterval.shouldRefresh(lastSyncAt: poolState.lastSyncAt) == false
        {
            return
        }
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
            scheduleNotificationRefresh(delay: BaPlatformPerformanceProfile.notificationTimelineRefreshDelay)
        } catch {
            guard settings.server == server else { return }
            guard Self.isCancellation(error) == false else {
                poolState.isLoading = false
                return
            }
            await applyPoolFailure(error)
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
        scheduleNotificationRefresh(delay: BaPlatformPerformanceProfile.notificationTimelineRefreshDelay)
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
        scheduleNotificationRefresh(delay: BaPlatformPerformanceProfile.notificationTimelineRefreshDelay)
        if entries != cached.value {
            await cacheStore.save(entries, for: .pools(server), schemaVersion: Self.poolCacheSchemaVersion, syncedAt: cached.syncedAt)
        }
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

    nonisolated static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
