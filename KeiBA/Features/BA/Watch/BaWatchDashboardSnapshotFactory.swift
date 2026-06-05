//
//  BaWatchDashboardSnapshotFactory.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation
#if os(iOS) && canImport(WidgetKit)
import WidgetKit
#endif

extension BaWatchDashboardSnapshot {
    init(
        userData: BaUserDataEnvelope,
        now: Date = Date(),
        timeline: BaTimelineGlanceSnapshot? = nil
    ) {
        let envelope = userData.settingsEnvelope().normalized()
        let account = envelope.watchDashboardAccount
        let server = account.server
        let profile = account.profile
        let globalSettings = envelope.globalSettings.normalized()
        let dutyStudent = globalSettings.dutyStudent

        self.init(
            sourceUpdatedAt: userData.updatedAt,
            generatedAt: now,
            accountID: account.id,
            accountDisplayName: BaAccountDisplayText.title(for: account),
            officeName: BaOfficeTerminology.officeName(
                for: server,
                appLanguage: globalSettings.appLanguage
            ),
            officeShortName: BaOfficeTerminology.shortOfficeName(
                for: server,
                appLanguage: globalSettings.appLanguage
            ),
            serverName: server.title,
            teacherName: profile.nickname,
            friendCode: profile.friendCode,
            dutyStudentName: dutyStudent?.name,
            dutyStudentAvatarURLString: dutyStudent?.avatarURL?.absoluteString,
            apBaseValue: profile.apCurrent,
            apLimit: profile.apLimit,
            apRegenBaseAt: profile.apRegenBaseAt,
            apNotificationsEnabled: profile.apNotificationsEnabled,
            apNotifyThreshold: profile.apNotifyThreshold,
            cafeLevel: profile.cafeLevel,
            cafeAPBaseValue: profile.cafeApCurrent,
            cafeStorageBaseAt: profile.cafeStorageBaseAt,
            cafeAPNotificationsEnabled: profile.cafeApNotificationsEnabled,
            cafeAPNotifyThreshold: profile.cafeApNotifyThreshold,
            nextHeadpatAvailableAt: BaTimeMath.nextHeadpatAvailable(
                lastHeadpatAt: profile.lastHeadpatAt,
                server: server
            ),
            nextInviteTicket1AvailableAt: BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket1At),
            nextInviteTicket2AvailableAt: BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket2At),
            activityNotificationsEnabled: globalSettings.activityNotificationsEnabled ||
                globalSettings.calendarUpcomingNotificationsEnabled ||
                globalSettings.calendarEndingNotificationsEnabled,
            poolNotificationsEnabled: globalSettings.poolNotificationsEnabled ||
                globalSettings.poolUpcomingNotificationsEnabled ||
                globalSettings.poolEndingNotificationsEnabled ||
                globalSettings.calendarPoolChangeNotificationsEnabled,
            favoriteStudentCount: globalSettings.favoriteContentIDs.count,
            timeline: timeline
        )
    }
}

extension BaTimelineGlanceSnapshot {
    init(
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        activitySyncAt: Date?,
        poolSyncAt: Date?,
        activityIsShowingCache: Bool,
        poolIsShowingCache: Bool,
        now: Date = Date()
    ) {
        self.init(
            generatedAt: now,
            activities: Self.section(
                entries: activities,
                now: now,
                title: \.title,
                start: \.beginAt,
                end: \.endAt,
                lastSyncAt: activitySyncAt,
                isShowingCache: activityIsShowingCache
            ),
            pools: Self.section(
                entries: pools,
                now: now,
                title: \.name,
                start: \.startAt,
                end: \.endAt,
                lastSyncAt: poolSyncAt,
                isShowingCache: poolIsShowingCache
            )
        )
    }

    private static func section<Entry>(
        entries: [Entry],
        now: Date,
        title titleKeyPath: KeyPath<Entry, String>,
        start startKeyPath: KeyPath<Entry, Date>,
        end endKeyPath: KeyPath<Entry, Date>,
        lastSyncAt: Date?,
        isShowingCache: Bool
    ) -> BaTimelineGlanceSection {
        var running: [Entry] = []
        var upcoming: [Entry] = []
        var endedCount = 0

        for entry in entries {
            let start = entry[keyPath: startKeyPath]
            let end = entry[keyPath: endKeyPath]
            if now >= start && now < end {
                running.append(entry)
            } else if now < start {
                upcoming.append(entry)
            } else {
                endedCount += 1
            }
        }

        let runningItems = running
            .sorted { lhs, rhs in
                lhs[keyPath: endKeyPath] < rhs[keyPath: endKeyPath]
            }
            .map { entry in
                BaTimelineGlanceItem(
                    title: entry[keyPath: titleKeyPath],
                    status: .running,
                    startAt: entry[keyPath: startKeyPath],
                    endAt: entry[keyPath: endKeyPath]
                )
            }

        let upcomingItems = upcoming
            .sorted { lhs, rhs in
                lhs[keyPath: startKeyPath] < rhs[keyPath: startKeyPath]
            }
            .map { entry in
                BaTimelineGlanceItem(
                    title: entry[keyPath: titleKeyPath],
                    status: .upcoming,
                    startAt: entry[keyPath: startKeyPath],
                    endAt: entry[keyPath: endKeyPath]
                )
            }

        var displayItems = Array((runningItems + upcomingItems).prefix(4))
        if displayItems.indices.contains(0) {
            let firstStatus = displayItems[0].status
            let sameStatusCount = firstStatus == .running ? runningItems.count : upcomingItems.count
            displayItems[0].relatedItemCount = max(sameStatusCount - 1, 0)
        }

        return BaTimelineGlanceSection(
            runningCount: running.count,
            upcomingCount: upcoming.count,
            endedCount: endedCount,
            featuredItem: displayItems.first,
            items: displayItems,
            lastSyncAt: lastSyncAt,
            isShowingCache: isShowingCache
        )
    }
}

extension BaAppModel {
    var currentWatchDashboardSnapshot: BaWatchDashboardSnapshot {
        BaWatchDashboardSnapshot(
            userData: envelope.userData(updatedAt: settingsStore.userDataUpdatedAt(fallback: Date())),
            now: Date(),
            timeline: watchTimelineGlanceSnapshot()
        )
    }

    func syncWatchSnapshot(updatedAt: Date = Date(), now: Date = Date()) {
        let userData = envelope.userData(updatedAt: updatedAt)
        let snapshot = BaWatchDashboardSnapshot(
            userData: userData,
            now: now,
            timeline: watchTimelineGlanceSnapshot(now: now)
        )
        persistDashboardSnapshotForWidgets(snapshot)
        watchSnapshotSyncer.sync(snapshot)
        watchSyncState = watchSnapshotSyncer.state
        scheduleWatchAvatarSnapshotSyncIfNeeded(snapshot)
    }

    func requestWatchSnapshotSync() {
        watchSnapshotSyncer.activate()
        syncWatchSnapshot(updatedAt: Date(), now: Date())
        watchSyncState = watchSnapshotSyncer.state
    }

    func refreshWatchSyncState() {
        watchSnapshotSyncer.refreshState()
        watchSyncState = watchSnapshotSyncer.state
    }

    private func watchTimelineGlanceSnapshot(now: Date = Date()) -> BaTimelineGlanceSnapshot {
        BaTimelineGlanceSnapshot(
            activities: activityState.value ?? [],
            pools: poolState.value ?? [],
            activitySyncAt: activityState.lastSyncAt,
            poolSyncAt: poolState.lastSyncAt,
            activityIsShowingCache: activityState.isShowingCache,
            poolIsShowingCache: poolState.isShowingCache,
            now: now
        )
    }

    private func scheduleWatchAvatarSnapshotSyncIfNeeded(_ snapshot: BaWatchDashboardSnapshot) {
        watchAvatarSnapshotTask?.cancel()
        guard shouldPrepareWatchAvatarSnapshot,
              snapshot.dutyStudentAvatarImageData == nil,
              let urlString = snapshot.dutyStudentAvatarURLString,
              let url = URL(string: urlString)
        else {
            watchAvatarSnapshotTask = nil
            return
        }

        watchAvatarSnapshotTask = Task { [weak self, snapshot, url] in
            guard let self else { return }
            do {
                let data = try await imageData(for: url)
                guard Task.isCancelled == false else { return }
                guard let avatarData = await BaWatchAvatarThumbnailEncoder.encodedThumbnailData(from: data) else {
                    return
                }
                guard Task.isCancelled == false else { return }
                guard settings.dutyStudent?.avatarURL?.absoluteString == url.absoluteString else { return }

                var enrichedSnapshot = snapshot
                enrichedSnapshot.generatedAt = Date()
                enrichedSnapshot.dutyStudentAvatarImageData = avatarData
                self.persistDashboardSnapshotForWidgets(enrichedSnapshot)
                watchSnapshotSyncer.sync(enrichedSnapshot)
                watchSyncState = watchSnapshotSyncer.state
            } catch {
                guard Task.isCancelled == false else { return }
            }
        }
    }

    private var shouldPrepareWatchAvatarSnapshot: Bool {
        switch watchSyncState.availability {
        case .activating, .confirmingInstall, .reachable, .background:
            true
        case .unavailable, .notPaired, .appNotInstalled, .error:
            false
        }
    }

    private func persistDashboardSnapshotForWidgets(_ snapshot: BaWatchDashboardSnapshot) {
        BaDashboardSnapshotSharing.save(snapshot)
        #if os(iOS) && canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: BaDashboardWidgetKind.resources)
        WidgetCenter.shared.reloadTimelines(ofKind: BaDashboardWidgetKind.timeline)
        #endif
    }
}
