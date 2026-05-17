//
//  BaUserDataModels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated struct BaUserDataEnvelope: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let iCloudKeyValueStoreKey = "ba.userData.v1"

    var schemaVersion: Int
    var updatedAt: Date
    var selectedServer: BaServer
    var globalSettings: BaGlobalSettings
    var serverProfiles: [BaServer: BaServerProfile]

    init(
        schemaVersion: Int = currentSchemaVersion,
        updatedAt: Date = Date(),
        selectedServer: BaServer,
        globalSettings: BaGlobalSettings,
        serverProfiles: [BaServer: BaServerProfile]
    ) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.selectedServer = selectedServer
        self.globalSettings = globalSettings
        self.serverProfiles = serverProfiles
    }

    init(settingsEnvelope: BaSettingsEnvelope, updatedAt: Date = Date()) {
        let normalized = settingsEnvelope.normalized()
        self.init(
            updatedAt: updatedAt,
            selectedServer: normalized.selectedServer,
            globalSettings: normalized.globalSettings,
            serverProfiles: normalized.serverProfiles
        )
    }

    func settingsEnvelope() -> BaSettingsEnvelope {
        BaSettingsEnvelope(
            schemaVersion: BaSettingsEnvelope.currentSchemaVersion,
            selectedServer: selectedServer,
            globalSettings: globalSettings,
            serverProfiles: serverProfiles
        )
        .normalized()
    }

    func normalized(updatedAt: Date? = nil) -> BaUserDataEnvelope {
        let settingsEnvelope = settingsEnvelope()
        return BaUserDataEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            updatedAt: updatedAt ?? self.updatedAt,
            selectedServer: settingsEnvelope.selectedServer,
            globalSettings: settingsEnvelope.globalSettings,
            serverProfiles: settingsEnvelope.serverProfiles
        )
    }

    func watchSnapshot(generatedAt: Date = Date()) -> BaWatchUserSnapshot {
        let settingsEnvelope = settingsEnvelope()
        return BaWatchUserSnapshot(settingsEnvelope: settingsEnvelope, generatedAt: generatedAt)
    }
}

nonisolated struct BaWatchUserSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let applicationContextKey = "ba.watch.userSnapshot.v1"

    var schemaVersion: Int
    var generatedAt: Date
    var selectedServer: BaServer
    var nickname: String
    var friendCode: String
    var dutyStudent: BaDutyStudent?
    var profile: BaWatchServerProfileSnapshot
    var preferences: BaWatchPreferencesSnapshot

    init(settingsEnvelope: BaSettingsEnvelope, generatedAt: Date = Date()) {
        let normalized = settingsEnvelope.normalized()
        let currentProfile = normalized.profile(for: normalized.selectedServer)
        schemaVersion = Self.currentSchemaVersion
        self.generatedAt = generatedAt
        selectedServer = normalized.selectedServer
        nickname = currentProfile.nickname
        friendCode = currentProfile.friendCode
        dutyStudent = normalized.globalSettings.dutyStudent
        profile = BaWatchServerProfileSnapshot(serverProfile: currentProfile)
        preferences = BaWatchPreferencesSnapshot(globalSettings: normalized.globalSettings)
    }
}

nonisolated struct BaWatchServerProfileSnapshot: Codable, Equatable, Sendable {
    var apCurrent: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var apSyncAt: Date?
    var cafeLevel: Int
    var cafeApCurrent: Double
    var cafeStorageBaseAt: Date
    var lastHeadpatAt: Date?
    var lastInviteTicket1At: Date?
    var lastInviteTicket2At: Date?
    var apNotificationsEnabled: Bool
    var cafeApNotificationsEnabled: Bool
    var visitNotificationsEnabled: Bool
    var arenaRefreshNotificationsEnabled: Bool
    var apNotifyThreshold: Int
    var cafeApNotifyThreshold: Int

    init(serverProfile: BaServerProfile) {
        let normalized = serverProfile.normalized()
        apCurrent = normalized.apCurrent
        apLimit = normalized.apLimit
        apRegenBaseAt = normalized.apRegenBaseAt
        apSyncAt = normalized.apSyncAt
        cafeLevel = normalized.cafeLevel
        cafeApCurrent = normalized.cafeApCurrent
        cafeStorageBaseAt = normalized.cafeStorageBaseAt
        lastHeadpatAt = normalized.lastHeadpatAt
        lastInviteTicket1At = normalized.lastInviteTicket1At
        lastInviteTicket2At = normalized.lastInviteTicket2At
        apNotificationsEnabled = normalized.apNotificationsEnabled
        cafeApNotificationsEnabled = normalized.cafeApNotificationsEnabled
        visitNotificationsEnabled = normalized.visitNotificationsEnabled
        arenaRefreshNotificationsEnabled = normalized.arenaRefreshNotificationsEnabled
        apNotifyThreshold = normalized.apNotifyThreshold
        cafeApNotifyThreshold = normalized.cafeApNotifyThreshold
    }
}

nonisolated struct BaWatchPreferencesSnapshot: Codable, Equatable, Sendable {
    var showEndedActivities: Bool
    var showEndedPools: Bool
    var activityNotificationsEnabled: Bool
    var poolNotificationsEnabled: Bool
    var calendarUpcomingNotificationsEnabled: Bool
    var calendarEndingNotificationsEnabled: Bool
    var poolUpcomingNotificationsEnabled: Bool
    var poolEndingNotificationsEnabled: Bool
    var calendarPoolChangeNotificationsEnabled: Bool
    var calendarPoolNotifyLead: BaCalendarPoolNotifyLead
    var refreshInterval: BaRefreshInterval
    var favoriteContentIDs: [Int64]
    var favoriteCount: Int

    init(globalSettings: BaGlobalSettings) {
        let normalized = globalSettings.normalized()
        showEndedActivities = normalized.showEndedActivities
        showEndedPools = normalized.showEndedPools
        activityNotificationsEnabled = normalized.activityNotificationsEnabled
        poolNotificationsEnabled = normalized.poolNotificationsEnabled
        calendarUpcomingNotificationsEnabled = normalized.calendarUpcomingNotificationsEnabled
        calendarEndingNotificationsEnabled = normalized.calendarEndingNotificationsEnabled
        poolUpcomingNotificationsEnabled = normalized.poolUpcomingNotificationsEnabled
        poolEndingNotificationsEnabled = normalized.poolEndingNotificationsEnabled
        calendarPoolChangeNotificationsEnabled = normalized.calendarPoolChangeNotificationsEnabled
        calendarPoolNotifyLead = normalized.calendarPoolNotifyLead
        refreshInterval = normalized.refreshInterval
        favoriteContentIDs = normalized.favoriteContentIDs.sorted()
        favoriteCount = normalized.favoriteContentIDs.count
    }
}

nonisolated extension BaSettingsEnvelope {
    func normalized() -> BaSettingsEnvelope {
        var copy = self
        copy.schemaVersion = Self.currentSchemaVersion
        if BaServer.allCases.contains(copy.selectedServer) == false {
            copy.selectedServer = .cn
        }
        copy.globalSettings = copy.globalSettings.normalized()
        for server in BaServer.allCases where copy.serverProfiles[server] == nil {
            copy.serverProfiles[server] = .defaults()
        }
        for server in BaServer.allCases {
            copy.serverProfiles[server] = copy.serverProfiles[server]?.normalized()
        }
        if copy.globalSettings.identityIndependentByServer == false {
            let shared = copy.profile(for: copy.selectedServer)
            for server in BaServer.allCases {
                copy.serverProfiles[server]?.nickname = shared.nickname
                copy.serverProfiles[server]?.friendCode = shared.friendCode
            }
        }
        return copy
    }

    func userData(updatedAt: Date = Date()) -> BaUserDataEnvelope {
        BaUserDataEnvelope(settingsEnvelope: self, updatedAt: updatedAt)
    }

    func watchUserSnapshot(generatedAt: Date = Date()) -> BaWatchUserSnapshot {
        userData().watchSnapshot(generatedAt: generatedAt)
    }
}
