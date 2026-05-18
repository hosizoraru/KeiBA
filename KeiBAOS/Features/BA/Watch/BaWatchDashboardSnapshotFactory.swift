//
//  BaWatchDashboardSnapshotFactory.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaWatchDashboardSnapshot {
    init(userData: BaUserDataEnvelope, now: Date = Date()) {
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
            favoriteStudentCount: globalSettings.favoriteContentIDs.count
        )
    }
}

extension BaAppModel {
    func syncWatchSnapshot(updatedAt: Date = Date(), now: Date = Date()) {
        let userData = envelope.userData(updatedAt: updatedAt)
        watchSnapshotSyncer.sync(BaWatchDashboardSnapshot(userData: userData, now: now))
    }
}
