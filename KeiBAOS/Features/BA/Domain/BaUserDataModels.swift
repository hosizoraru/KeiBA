//
//  BaUserDataModels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated struct BaUserDataEnvelope: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    static let keyValueSyncStoreKey = "ba.userData.v1"

    var schemaVersion: Int
    var updatedAt: Date
    var selectedServer: BaServer
    var selectedAccountID: BaAccountID?
    var globalSettings: BaGlobalSettings
    var serverProfiles: [BaServer: BaServerProfile]
    var accounts: [BaAccountProfile]

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case updatedAt
        case selectedServer
        case selectedAccountID
        case globalSettings
        case serverProfiles
        case accounts
    }

    init(
        schemaVersion: Int = currentSchemaVersion,
        updatedAt: Date = Date(),
        selectedServer: BaServer,
        selectedAccountID: BaAccountID? = nil,
        globalSettings: BaGlobalSettings,
        serverProfiles: [BaServer: BaServerProfile],
        accounts: [BaAccountProfile] = []
    ) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.selectedServer = selectedServer
        self.selectedAccountID = selectedAccountID
        self.globalSettings = globalSettings
        self.serverProfiles = serverProfiles
        self.accounts = accounts
    }

    init(from decoder: Decoder) throws {
        let defaults = BaSettingsEnvelope.defaults()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        selectedServer = try container.decodeIfPresent(BaServer.self, forKey: .selectedServer) ?? defaults.selectedServer
        selectedAccountID = try container.decodeIfPresent(BaAccountID.self, forKey: .selectedAccountID)
        globalSettings = try container.decodeIfPresent(BaGlobalSettings.self, forKey: .globalSettings) ?? defaults.globalSettings
        serverProfiles = try container.decodeIfPresent([BaServer: BaServerProfile].self, forKey: .serverProfiles) ?? defaults.serverProfiles
        accounts = try container.decodeIfPresent([BaAccountProfile].self, forKey: .accounts) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(selectedServer, forKey: .selectedServer)
        try container.encodeIfPresent(selectedAccountID, forKey: .selectedAccountID)
        try container.encode(globalSettings, forKey: .globalSettings)
        try container.encode(serverProfiles, forKey: .serverProfiles)
        try container.encode(accounts, forKey: .accounts)
    }

    init(settingsEnvelope: BaSettingsEnvelope, updatedAt: Date = Date()) {
        let normalized = settingsEnvelope.normalized()
        self.init(
            updatedAt: updatedAt,
            selectedServer: normalized.selectedServer,
            selectedAccountID: normalized.selectedAccountID,
            globalSettings: normalized.globalSettings,
            serverProfiles: normalized.serverProfiles,
            accounts: normalized.accounts
        )
    }

    func settingsEnvelope() -> BaSettingsEnvelope {
        BaSettingsEnvelope(
            schemaVersion: BaSettingsEnvelope.currentSchemaVersion,
            selectedServer: selectedServer,
            globalSettings: globalSettings,
            serverProfiles: serverProfiles,
            selectedAccountID: selectedAccountID,
            accounts: accounts
        )
        .normalized()
    }

    func normalized(updatedAt: Date? = nil) -> BaUserDataEnvelope {
        let settingsEnvelope = settingsEnvelope()
        return BaUserDataEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            updatedAt: updatedAt ?? self.updatedAt,
            selectedServer: settingsEnvelope.selectedServer,
            selectedAccountID: settingsEnvelope.selectedAccountID,
            globalSettings: settingsEnvelope.globalSettings,
            serverProfiles: settingsEnvelope.serverProfiles,
            accounts: settingsEnvelope.accounts
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
        let currentAccount = normalized.selectedAccount
        let currentProfile = currentAccount.profile
        schemaVersion = Self.currentSchemaVersion
        self.generatedAt = generatedAt
        selectedServer = currentAccount.server
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
        copy.globalSettings = copy.globalSettings.normalized()
        for server in BaServer.allCases where copy.serverProfiles[server] == nil {
            copy.serverProfiles[server] = .defaults()
        }
        for server in BaServer.allCases {
            copy.serverProfiles[server] = copy.serverProfiles[server]?.normalized()
        }

        if copy.accounts.isEmpty {
            copy.accounts = copy.legacyAccounts()
        }

        copy.accounts = Self.normalizedAccounts(copy.accounts)
        if copy.accounts.isEmpty {
            let fallbackProfile = copy.serverProfiles[copy.selectedServer] ?? .defaults()
            copy.accounts = [
                BaAccountProfile(
                    id: BaAccountProfile.defaultID(for: copy.selectedServer),
                    server: copy.selectedServer,
                    displayName: fallbackProfile.nickname,
                    profile: fallbackProfile,
                    sortOrder: 0
                ),
            ]
        }

        if copy.accounts.contains(where: { $0.server == copy.selectedServer }) == false {
            let fallbackProfile = (copy.serverProfiles[copy.selectedServer] ?? .defaults()).normalized()
            copy.accounts.append(
                BaAccountProfile(
                    id: BaAccountProfile.defaultID(for: copy.selectedServer),
                    server: copy.selectedServer,
                    displayName: fallbackProfile.nickname,
                    profile: fallbackProfile,
                    sortOrder: copy.accounts.count
                )
            )
            copy.accounts = Self.normalizedAccounts(copy.accounts)
        }

        let selectedByID = copy.selectedAccountID.flatMap { id in
            copy.accounts.first { $0.id == id }
        }
        let selectedEnabledByID = selectedByID.flatMap { account in
            account.isEnabled ? account : nil
        }
        let hasEnabledAccount = copy.accounts.contains(where: \.isEnabled)
        let resolvedAccount =
            selectedEnabledByID.flatMap { $0.server == copy.selectedServer ? $0 : nil } ??
            copy.accounts.first { $0.server == copy.selectedServer && $0.isEnabled } ??
            (hasEnabledAccount ? nil : selectedByID.flatMap { $0.server == copy.selectedServer ? $0 : nil }) ??
            selectedEnabledByID ??
            copy.accounts.first(where: \.isEnabled) ??
            selectedByID ??
            copy.accounts.first { $0.server == copy.selectedServer } ??
            copy.accounts[0]

        copy.selectedAccountID = resolvedAccount.id
        copy.selectedServer = resolvedAccount.server
        copy.serverProfiles = copy.legacyServerProfiles(activeAccount: resolvedAccount)
        return copy
    }

    func userData(updatedAt: Date = Date()) -> BaUserDataEnvelope {
        BaUserDataEnvelope(settingsEnvelope: self, updatedAt: updatedAt)
    }

    func watchUserSnapshot(generatedAt: Date = Date()) -> BaWatchUserSnapshot {
        userData().watchSnapshot(generatedAt: generatedAt)
    }

    private func legacyAccounts() -> [BaAccountProfile] {
        if globalSettings.identityIndependentByServer {
            return BaServer.allCases.enumerated().map { index, server in
                let profile = (serverProfiles[server] ?? .defaults()).normalized()
                return BaAccountProfile(
                    id: BaAccountProfile.legacyID(for: server),
                    server: server,
                    displayName: profile.nickname,
                    profile: profile,
                    sortOrder: index
                )
            }
        }

        let profile = (serverProfiles[selectedServer] ?? .defaults()).normalized()
        return [
            BaAccountProfile(
                id: BaAccountProfile.defaultID(for: selectedServer),
                server: selectedServer,
                displayName: profile.nickname,
                profile: profile,
                sortOrder: 0
            ),
        ]
    }

    private func legacyServerProfiles(activeAccount: BaAccountProfile) -> [BaServer: BaServerProfile] {
        var profiles = Dictionary(
            uniqueKeysWithValues: BaServer.allCases.map { server in
                (server, (serverProfiles[server] ?? .defaults()).normalized())
            }
        )

        var assignedServers = Set<BaServer>()
        for account in accounts.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            guard assignedServers.insert(account.server).inserted else { continue }
            profiles[account.server] = account.profile.normalized()
        }
        profiles[activeAccount.server] = activeAccount.profile.normalized()
        return profiles
    }

    private static func normalizedAccounts(_ accounts: [BaAccountProfile]) -> [BaAccountProfile] {
        var seen = Set<BaAccountID>()
        return accounts.enumerated().compactMap { index, account in
            guard let normalized = account.normalized(defaultSortOrder: index),
                  seen.insert(normalized.id).inserted
            else {
                return nil
            }
            return normalized
        }
        .sorted {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.id < $1.id
        }
    }
}
