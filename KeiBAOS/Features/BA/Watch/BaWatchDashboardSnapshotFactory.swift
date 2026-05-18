//
//  BaWatchDashboardSnapshotFactory.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaWatchDashboardSnapshot {
    init(
        userData: BaUserDataEnvelope,
        now: Date = Date(),
        timeline: BaTimelineGlanceSnapshot? = nil
    ) {
        let envelope = userData.settingsEnvelope().normalized()
        let profile = envelope.profile(for: envelope.selectedServer)
        let globalSettings = envelope.globalSettings.normalized()
        let dutyStudent = globalSettings.dutyStudent

        self.init(
            sourceUpdatedAt: userData.updatedAt,
            generatedAt: now,
            serverName: envelope.selectedServer.title,
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
                server: envelope.selectedServer
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

        let featuredItem: BaTimelineGlanceItem?
        if let runningEntry = running.min(by: { lhs, rhs in
            lhs[keyPath: endKeyPath] < rhs[keyPath: endKeyPath]
        }) {
            featuredItem = BaTimelineGlanceItem(
                title: runningEntry[keyPath: titleKeyPath],
                status: .running,
                startAt: runningEntry[keyPath: startKeyPath],
                endAt: runningEntry[keyPath: endKeyPath],
                relatedItemCount: running.count - 1
            )
        } else if let upcomingEntry = upcoming.min(by: { lhs, rhs in
            lhs[keyPath: startKeyPath] < rhs[keyPath: startKeyPath]
        }) {
            featuredItem = BaTimelineGlanceItem(
                title: upcomingEntry[keyPath: titleKeyPath],
                status: .upcoming,
                startAt: upcomingEntry[keyPath: startKeyPath],
                endAt: upcomingEntry[keyPath: endKeyPath],
                relatedItemCount: upcoming.count - 1
            )
        } else {
            featuredItem = nil
        }

        return BaTimelineGlanceSection(
            runningCount: running.count,
            upcomingCount: upcoming.count,
            endedCount: endedCount,
            featuredItem: featuredItem,
            lastSyncAt: lastSyncAt,
            isShowingCache: isShowingCache
        )
    }
}

extension BaAppModel {
    var watchSyncState: BaWatchSyncState {
        watchSnapshotSyncer.state
    }

    var currentWatchDashboardSnapshot: BaWatchDashboardSnapshot {
        BaWatchDashboardSnapshot(
            userData: envelope.userData(updatedAt: settingsStore.userDataUpdatedAt(fallback: Date())),
            now: Date(),
            timeline: watchTimelineGlanceSnapshot()
        )
    }

    func syncWatchSnapshot(updatedAt: Date = Date(), now: Date = Date()) {
        let userData = envelope.userData(updatedAt: updatedAt)
        watchSnapshotSyncer.sync(
            BaWatchDashboardSnapshot(
                userData: userData,
                now: now,
                timeline: watchTimelineGlanceSnapshot(now: now)
            )
        )
    }

    func requestWatchSnapshotSync() {
        watchSnapshotSyncer.activate()
        syncWatchSnapshot(updatedAt: Date(), now: Date())
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
}
