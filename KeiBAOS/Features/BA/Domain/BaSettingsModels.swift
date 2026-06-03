//
//  BaSettingsModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation
import SwiftUI

nonisolated enum BaServer: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case cn
    case global
    case jp

    var id: Self {
        self
    }

    var title: String {
        BaL10n.string(titleKey)
    }

    var titleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: titleKey)
    }

    var titleKey: String {
        switch self {
        case .cn:
            "ba.server.cn"
        case .global:
            "ba.server.global"
        case .jp:
            "ba.server.jp"
        }
    }

    var gameKeeServerId: Int {
        switch self {
        case .cn:
            16
        case .global:
            17
        case .jp:
            15
        }
    }

    var timeZoneIdentifier: String {
        switch self {
        case .cn:
            "Asia/Shanghai"
        case .global, .jp:
            "Asia/Tokyo"
        }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

nonisolated enum BaRefreshInterval: Int, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case oneHour = 1
    case threeHours = 3
    case sixHours = 6
    case twelveHours = 12
    case twentyFourHours = 24

    var id: Self {
        self
    }

    var title: String {
        BaL10n.string(titleKey)
    }

    var titleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: titleKey)
    }

    var titleKey: String {
        switch self {
        case .oneHour:
            "ba.settings.refresh.interval.1h"
        case .threeHours:
            "ba.settings.refresh.interval.3h"
        case .sixHours:
            "ba.settings.refresh.interval.6h"
        case .twelveHours:
            "ba.settings.refresh.interval.12h"
        case .twentyFourHours:
            "ba.settings.refresh.interval.24h"
        }
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue) * 60 * 60
    }

    func shouldRefresh(lastSyncAt: Date?, now: Date = Date()) -> Bool {
        guard let lastSyncAt else { return true }
        return now.timeIntervalSince(lastSyncAt) >= timeInterval
    }
}

nonisolated enum BaCalendarPoolNotifyLead: Int, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case oneHour = 1
    case threeHours = 3
    case sixHours = 6
    case twelveHours = 12
    case twentyFourHours = 24

    var id: Self {
        self
    }

    var title: String {
        BaL10n.string(titleKey)
    }

    var titleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: titleKey)
    }

    var titleKey: String {
        switch self {
        case .oneHour:
            "ba.settings.refresh.interval.1h"
        case .threeHours:
            "ba.settings.refresh.interval.3h"
        case .sixHours:
            "ba.settings.refresh.interval.6h"
        case .twelveHours:
            "ba.settings.refresh.interval.12h"
        case .twentyFourHours:
            "ba.settings.refresh.interval.24h"
        }
    }
}

nonisolated struct BaDutyStudent: Codable, Equatable, Hashable, Sendable {
    var contentId: Int64
    var name: String
    var avatarURL: URL?
}

nonisolated struct BaGlobalSettings: Codable, Equatable, Sendable {
    var identityIndependentByServer: Bool
    var showEndedActivities: Bool
    var showEndedPools: Bool
    var showPreviewImages: Bool
    var activityNotificationsEnabled: Bool
    var poolNotificationsEnabled: Bool
    var calendarUpcomingNotificationsEnabled: Bool
    var calendarEndingNotificationsEnabled: Bool
    var poolUpcomingNotificationsEnabled: Bool
    var poolEndingNotificationsEnabled: Bool
    var calendarPoolChangeNotificationsEnabled: Bool
    var calendarPoolNotifyLead: BaCalendarPoolNotifyLead
    var mediaAutoplayEnabled: Bool
    var mediaDownloadEnabled: Bool
    var refreshInterval: BaRefreshInterval
    var appLanguage: BaAppLanguage
    var appAppearance: BaAppAppearance
    var appIcon: BaAppIconChoice
    var favoriteContentIDs: Set<Int64>
    var favoriteCatalogEntries: [BaGuideCatalogEntry]
    var dutyStudent: BaDutyStudent?

    static func defaults() -> BaGlobalSettings {
        BaGlobalSettings(
            identityIndependentByServer: false,
            showEndedActivities: true,
            showEndedPools: true,
            showPreviewImages: true,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: false,
            calendarUpcomingNotificationsEnabled: true,
            calendarEndingNotificationsEnabled: false,
            poolUpcomingNotificationsEnabled: false,
            poolEndingNotificationsEnabled: false,
            calendarPoolChangeNotificationsEnabled: false,
            calendarPoolNotifyLead: .twentyFourHours,
            mediaAutoplayEnabled: false,
            mediaDownloadEnabled: false,
            refreshInterval: .threeHours,
            appLanguage: .system,
            appAppearance: .system,
            appIcon: .modern,
            favoriteContentIDs: [],
            favoriteCatalogEntries: [],
            dutyStudent: nil
        )
    }
}

nonisolated extension BaGlobalSettings {
    enum CodingKeys: String, CodingKey {
        case identityIndependentByServer
        case showEndedActivities
        case showEndedPools
        case showPreviewImages
        case activityNotificationsEnabled
        case poolNotificationsEnabled
        case calendarUpcomingNotificationsEnabled
        case calendarEndingNotificationsEnabled
        case poolUpcomingNotificationsEnabled
        case poolEndingNotificationsEnabled
        case calendarPoolChangeNotificationsEnabled
        case calendarPoolNotifyLead
        case mediaAutoplayEnabled
        case mediaDownloadEnabled
        case refreshInterval
        case appLanguage
        case appAppearance
        case appIcon
        case favoriteContentIDs
        case favoriteCatalogEntries
        case dutyStudent
    }

    init(from decoder: Decoder) throws {
        let defaults = BaGlobalSettings.defaults()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identityIndependentByServer = try container.decodeIfPresent(Bool.self, forKey: .identityIndependentByServer) ?? defaults.identityIndependentByServer
        showEndedActivities = try container.decodeIfPresent(Bool.self, forKey: .showEndedActivities) ?? defaults.showEndedActivities
        showEndedPools = try container.decodeIfPresent(Bool.self, forKey: .showEndedPools) ?? defaults.showEndedPools
        showPreviewImages = try container.decodeIfPresent(Bool.self, forKey: .showPreviewImages) ?? defaults.showPreviewImages
        activityNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .activityNotificationsEnabled) ?? defaults.activityNotificationsEnabled
        poolNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolNotificationsEnabled) ?? defaults.poolNotificationsEnabled
        calendarUpcomingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarUpcomingNotificationsEnabled) ?? defaults.calendarUpcomingNotificationsEnabled
        calendarEndingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarEndingNotificationsEnabled) ?? defaults.calendarEndingNotificationsEnabled
        poolUpcomingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolUpcomingNotificationsEnabled) ?? defaults.poolUpcomingNotificationsEnabled
        poolEndingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolEndingNotificationsEnabled) ?? defaults.poolEndingNotificationsEnabled
        calendarPoolChangeNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarPoolChangeNotificationsEnabled) ?? defaults.calendarPoolChangeNotificationsEnabled
        calendarPoolNotifyLead = try container.decodeIfPresent(BaCalendarPoolNotifyLead.self, forKey: .calendarPoolNotifyLead) ?? defaults.calendarPoolNotifyLead
        mediaAutoplayEnabled = try container.decodeIfPresent(Bool.self, forKey: .mediaAutoplayEnabled) ?? defaults.mediaAutoplayEnabled
        mediaDownloadEnabled = try container.decodeIfPresent(Bool.self, forKey: .mediaDownloadEnabled) ?? defaults.mediaDownloadEnabled
        refreshInterval = try container.decodeIfPresent(BaRefreshInterval.self, forKey: .refreshInterval) ?? defaults.refreshInterval
        appLanguage = try container.decodeIfPresent(BaAppLanguage.self, forKey: .appLanguage) ?? defaults.appLanguage
        appAppearance = try container.decodeIfPresent(BaAppAppearance.self, forKey: .appAppearance) ?? defaults.appAppearance
        appIcon = try container.decodeIfPresent(BaAppIconChoice.self, forKey: .appIcon) ?? defaults.appIcon
        favoriteContentIDs = try container.decodeIfPresent(Set<Int64>.self, forKey: .favoriteContentIDs) ?? defaults.favoriteContentIDs
        favoriteCatalogEntries = try container.decodeIfPresent([BaGuideCatalogEntry].self, forKey: .favoriteCatalogEntries) ?? defaults.favoriteCatalogEntries
        dutyStudent = try container.decodeIfPresent(BaDutyStudent.self, forKey: .dutyStudent)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identityIndependentByServer, forKey: .identityIndependentByServer)
        try container.encode(showEndedActivities, forKey: .showEndedActivities)
        try container.encode(showEndedPools, forKey: .showEndedPools)
        try container.encode(showPreviewImages, forKey: .showPreviewImages)
        try container.encode(activityNotificationsEnabled, forKey: .activityNotificationsEnabled)
        try container.encode(poolNotificationsEnabled, forKey: .poolNotificationsEnabled)
        try container.encode(calendarUpcomingNotificationsEnabled, forKey: .calendarUpcomingNotificationsEnabled)
        try container.encode(calendarEndingNotificationsEnabled, forKey: .calendarEndingNotificationsEnabled)
        try container.encode(poolUpcomingNotificationsEnabled, forKey: .poolUpcomingNotificationsEnabled)
        try container.encode(poolEndingNotificationsEnabled, forKey: .poolEndingNotificationsEnabled)
        try container.encode(calendarPoolChangeNotificationsEnabled, forKey: .calendarPoolChangeNotificationsEnabled)
        try container.encode(calendarPoolNotifyLead, forKey: .calendarPoolNotifyLead)
        try container.encode(mediaAutoplayEnabled, forKey: .mediaAutoplayEnabled)
        try container.encode(mediaDownloadEnabled, forKey: .mediaDownloadEnabled)
        try container.encode(refreshInterval, forKey: .refreshInterval)
        try container.encode(appLanguage, forKey: .appLanguage)
        try container.encode(appAppearance, forKey: .appAppearance)
        try container.encode(appIcon, forKey: .appIcon)
        try container.encode(favoriteContentIDs, forKey: .favoriteContentIDs)
        try container.encode(favoriteCatalogEntries, forKey: .favoriteCatalogEntries)
        try container.encodeIfPresent(dutyStudent, forKey: .dutyStudent)
    }

    func normalized() -> BaGlobalSettings {
        var copy = self
        var seen = Set<Int64>()
        copy.favoriteCatalogEntries = copy.favoriteCatalogEntries.filter { entry in
            guard entry.contentId > 0 else { return false }
            return seen.insert(entry.contentId).inserted
        }
        copy.favoriteContentIDs.formUnion(copy.favoriteCatalogEntries.map(\.contentId))
        return copy
    }
}

nonisolated struct BaServerProfile: Codable, Equatable, Sendable {
    var nickname: String
    var friendCode: String
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
    var cafeVisitLastNotifiedAt: Date?
    var arenaRefreshLastNotifiedAt: Date?

    static func defaults(now: Date = Date()) -> BaServerProfile {
        BaServerProfile(
            nickname: "Kei",
            friendCode: "ARISUKEI",
            apCurrent: 1,
            apLimit: 240,
            apRegenBaseAt: now,
            apSyncAt: now,
            cafeLevel: 10,
            cafeApCurrent: 462,
            cafeStorageBaseAt: now,
            lastHeadpatAt: nil,
            lastInviteTicket1At: nil,
            lastInviteTicket2At: nil,
            apNotificationsEnabled: true,
            cafeApNotificationsEnabled: true,
            visitNotificationsEnabled: false,
            arenaRefreshNotificationsEnabled: false,
            apNotifyThreshold: 120,
            cafeApNotifyThreshold: 120,
            cafeVisitLastNotifiedAt: nil,
            arenaRefreshLastNotifiedAt: nil
        )
    }
}

typealias BaAccountID = String

nonisolated struct BaAccountProfile: Identifiable, Codable, Equatable, Sendable {
    var id: BaAccountID
    var server: BaServer
    var displayName: String
    var profile: BaServerProfile
    var isEnabled: Bool
    var sortOrder: Int

    init(
        id: BaAccountID = UUID().uuidString,
        server: BaServer,
        displayName: String? = nil,
        profile: BaServerProfile = .defaults(),
        isEnabled: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.server = server
        self.displayName = displayName ?? profile.nickname
        self.profile = profile
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
    }

    var title: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.nickname : displayName
    }

    var detail: String {
        String(
            format: BaL10n.string("ba.account.summary.format"),
            server.title,
            profile.nickname,
            profile.friendCode
        )
    }

    static func legacyID(for server: BaServer) -> BaAccountID {
        "legacy-\(server.rawValue)"
    }

    static func defaultID(for server: BaServer) -> BaAccountID {
        "default-\(server.rawValue)"
    }

    func normalized(defaultSortOrder: Int) -> BaAccountProfile? {
        let normalizedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedID.isEmpty == false else { return nil }
        let normalizedProfile = profile.normalized()
        let normalizedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return BaAccountProfile(
            id: normalizedID,
            server: server,
            displayName: normalizedDisplayName.isEmpty ? normalizedProfile.nickname : String(normalizedDisplayName.prefix(32)),
            profile: normalizedProfile,
            isEnabled: isEnabled,
            sortOrder: sortOrder >= 0 ? sortOrder : defaultSortOrder
        )
    }
}

nonisolated struct BaSettingsEnvelope: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var selectedServer: BaServer
    var globalSettings: BaGlobalSettings
    var serverProfiles: [BaServer: BaServerProfile]
    var selectedAccountID: BaAccountID?
    var accounts: [BaAccountProfile]

    static let currentSchemaVersion = 7

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case selectedServer
        case globalSettings
        case serverProfiles
        case selectedAccountID
        case accounts
    }

    init(
        schemaVersion: Int,
        selectedServer: BaServer,
        globalSettings: BaGlobalSettings,
        serverProfiles: [BaServer: BaServerProfile],
        selectedAccountID: BaAccountID? = nil,
        accounts: [BaAccountProfile] = []
    ) {
        self.schemaVersion = schemaVersion
        self.selectedServer = selectedServer
        self.globalSettings = globalSettings
        self.serverProfiles = serverProfiles
        self.selectedAccountID = selectedAccountID
        self.accounts = accounts
    }

    init(from decoder: Decoder) throws {
        let defaults = BaSettingsEnvelope.defaults()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? defaults.schemaVersion
        selectedServer = try container.decodeIfPresent(BaServer.self, forKey: .selectedServer) ?? defaults.selectedServer
        globalSettings = try container.decodeIfPresent(BaGlobalSettings.self, forKey: .globalSettings) ?? defaults.globalSettings
        serverProfiles = try container.decodeIfPresent([BaServer: BaServerProfile].self, forKey: .serverProfiles) ?? defaults.serverProfiles
        selectedAccountID = try container.decodeIfPresent(BaAccountID.self, forKey: .selectedAccountID)
        accounts = try container.decodeIfPresent([BaAccountProfile].self, forKey: .accounts) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(selectedServer, forKey: .selectedServer)
        try container.encode(globalSettings, forKey: .globalSettings)
        try container.encode(serverProfiles, forKey: .serverProfiles)
        try container.encodeIfPresent(selectedAccountID, forKey: .selectedAccountID)
        try container.encode(accounts, forKey: .accounts)
    }

    static func defaults(now: Date = Date()) -> BaSettingsEnvelope {
        let profile = BaServerProfile.defaults(now: now)
        let account = BaAccountProfile(
            id: BaAccountProfile.defaultID(for: .cn),
            server: .cn,
            displayName: profile.nickname,
            profile: profile,
            sortOrder: 0
        )
        return BaSettingsEnvelope(
            schemaVersion: currentSchemaVersion,
            selectedServer: .cn,
            globalSettings: .defaults(),
            serverProfiles: Dictionary(uniqueKeysWithValues: BaServer.allCases.map { ($0, profile) }),
            selectedAccountID: account.id,
            accounts: [account]
        )
    }

    static func migrated(from settings: BaAppSettings) -> BaSettingsEnvelope {
        var envelope = BaSettingsEnvelope.defaults(now: settings.apRegenBaseAt)
        envelope.selectedServer = settings.server
        envelope.globalSettings = BaGlobalSettings(
            identityIndependentByServer: settings.identityIndependentByServer,
            showEndedActivities: settings.showEndedActivities,
            showEndedPools: settings.showEndedPools,
            showPreviewImages: settings.showPreviewImages,
            activityNotificationsEnabled: settings.activityNotificationsEnabled,
            poolNotificationsEnabled: settings.poolNotificationsEnabled,
            calendarUpcomingNotificationsEnabled: settings.calendarUpcomingNotificationsEnabled,
            calendarEndingNotificationsEnabled: settings.calendarEndingNotificationsEnabled,
            poolUpcomingNotificationsEnabled: settings.poolUpcomingNotificationsEnabled,
            poolEndingNotificationsEnabled: settings.poolEndingNotificationsEnabled,
            calendarPoolChangeNotificationsEnabled: settings.calendarPoolChangeNotificationsEnabled,
            calendarPoolNotifyLead: settings.calendarPoolNotifyLead,
            mediaAutoplayEnabled: settings.mediaAutoplayEnabled,
            mediaDownloadEnabled: settings.mediaDownloadEnabled,
            refreshInterval: settings.refreshInterval,
            appLanguage: settings.appLanguage,
            appAppearance: settings.appAppearance,
            appIcon: .modern,
            favoriteContentIDs: settings.favoriteContentIDs,
            favoriteCatalogEntries: settings.favoriteCatalogEntries,
            dutyStudent: settings.dutyStudent
        )
        let profile = BaServerProfile(
            nickname: settings.nickname,
            friendCode: settings.friendCode,
            apCurrent: settings.apCurrent,
            apLimit: settings.apLimit,
            apRegenBaseAt: settings.apRegenBaseAt,
            apSyncAt: settings.apSyncAt,
            cafeLevel: settings.cafeLevel,
            cafeApCurrent: settings.cafeApCurrent,
            cafeStorageBaseAt: settings.cafeStorageBaseAt,
            lastHeadpatAt: settings.lastHeadpatAt,
            lastInviteTicket1At: settings.lastInviteTicket1At ?? settings.lastInviteTicketAt,
            lastInviteTicket2At: settings.lastInviteTicket2At,
            apNotificationsEnabled: settings.apNotificationsEnabled,
            cafeApNotificationsEnabled: settings.cafeApNotificationsEnabled,
            visitNotificationsEnabled: settings.visitNotificationsEnabled,
            arenaRefreshNotificationsEnabled: settings.arenaRefreshNotificationsEnabled,
            apNotifyThreshold: settings.apNotifyThreshold,
            cafeApNotifyThreshold: settings.cafeApNotifyThreshold,
            cafeVisitLastNotifiedAt: settings.cafeVisitLastNotifiedAt,
            arenaRefreshLastNotifiedAt: settings.arenaRefreshLastNotifiedAt
        )
        envelope.serverProfiles[settings.server] = profile
        if settings.identityIndependentByServer {
            envelope.accounts = BaServer.allCases.enumerated().map { index, server in
                var serverProfile = envelope.serverProfiles[server] ?? .defaults(now: settings.apRegenBaseAt)
                if server == settings.server {
                    serverProfile = profile
                }
                return BaAccountProfile(
                    id: BaAccountProfile.legacyID(for: server),
                    server: server,
                    displayName: serverProfile.nickname,
                    profile: serverProfile,
                    sortOrder: index
                )
            }
            envelope.selectedAccountID = BaAccountProfile.legacyID(for: settings.server)
        } else {
            let account = BaAccountProfile(
                id: BaAccountProfile.defaultID(for: settings.server),
                server: settings.server,
                displayName: profile.nickname,
                profile: profile,
                sortOrder: 0
            )
            envelope.accounts = [account]
            envelope.selectedAccountID = account.id
        }
        return envelope
    }

    var selectedAccount: BaAccountProfile {
        if let selectedAccountID,
           let account = accounts.first(where: { $0.id == selectedAccountID })
        {
            return account
        }
        if let account = accounts.first(where: { $0.isEnabled && $0.server == selectedServer }) ??
            accounts.first(where: { $0.server == selectedServer }) ??
            accounts.first(where: \.isEnabled) ??
            accounts.first
        {
            return account
        }
        let fallbackProfile = serverProfiles[selectedServer] ?? .defaults()
        return BaAccountProfile(
            id: BaAccountProfile.defaultID(for: selectedServer),
            server: selectedServer,
            displayName: fallbackProfile.nickname,
            profile: fallbackProfile,
            sortOrder: 0
        )
    }

    var enabledAccounts: [BaAccountProfile] {
        accounts.filter(\.isEnabled)
    }

    func profile(for server: BaServer) -> BaServerProfile {
        let selected = selectedAccount
        if selected.server == server {
            return selected.profile
        }
        return accounts.first(where: { $0.server == server && $0.isEnabled })?.profile ??
            accounts.first(where: { $0.server == server })?.profile ??
            serverProfiles[server] ??
            .defaults()
    }

    mutating func setProfile(_ profile: BaServerProfile, for server: BaServer) {
        let normalizedProfile = profile.normalized()
        if let selectedAccountID,
           let selectedIndex = accounts.firstIndex(where: { $0.id == selectedAccountID && $0.server == server })
        {
            accounts[selectedIndex].profile = normalizedProfile
            accounts[selectedIndex].displayName = normalizedAccountDisplayName(
                currentDisplayName: accounts[selectedIndex].displayName,
                profile: normalizedProfile
            )
        } else if let index = accounts.firstIndex(where: { $0.server == server }) {
            accounts[index].profile = normalizedProfile
            accounts[index].displayName = normalizedAccountDisplayName(
                currentDisplayName: accounts[index].displayName,
                profile: normalizedProfile
            )
        } else {
            let account = BaAccountProfile(
                id: BaAccountProfile.defaultID(for: server),
                server: server,
                displayName: normalizedProfile.nickname,
                profile: normalizedProfile,
                sortOrder: accounts.count
            )
            accounts.append(account)
            if server == selectedServer {
                selectedAccountID = account.id
            }
        }
        serverProfiles[server] = normalizedProfile
    }

    mutating func setSelectedAccountID(_ accountID: BaAccountID) {
        guard let account = accounts.first(where: { $0.id == accountID }) else { return }
        selectedAccountID = account.id
        selectedServer = account.server
        serverProfiles[account.server] = account.profile
    }

    mutating func addAccount(_ account: BaAccountProfile, select: Bool = true) {
        let normalized = account.normalized(defaultSortOrder: accounts.count) ?? account
        accounts.removeAll { $0.id == normalized.id }
        accounts.append(normalized)
        if select {
            selectedAccountID = normalized.id
            selectedServer = normalized.server
        }
        serverProfiles[normalized.server] = normalized.profile
    }

    mutating func updateAccount(id: BaAccountID, transform: (inout BaAccountProfile) -> Void) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        var account = accounts[index]
        transform(&account)
        guard let normalized = account.normalized(defaultSortOrder: index) else { return }
        accounts[index] = normalized
        if selectedAccountID == id {
            selectedServer = normalized.server
        }
        serverProfiles[normalized.server] = normalized.profile
    }

    mutating func deleteAccount(id: BaAccountID) {
        guard accounts.count > 1 else { return }
        accounts.removeAll { $0.id == id }
        if selectedAccountID == id || accounts.contains(where: { $0.id == selectedAccountID }) == false {
            selectedAccountID = accounts.first(where: \.isEnabled)?.id ?? accounts.first?.id
        }
        selectedServer = selectedAccount.server
    }

    mutating func moveAccount(id: BaAccountID, offset: Int) {
        guard offset != 0,
              let fromIndex = accounts.firstIndex(where: { $0.id == id })
        else {
            return
        }
        let toIndex = min(max(fromIndex + offset, 0), accounts.count - 1)
        guard fromIndex != toIndex else { return }
        var mutable = accounts
        let account = mutable.remove(at: fromIndex)
        mutable.insert(account, at: toIndex)
        accounts = mutable.enumerated().map { index, account in
            var copy = account
            copy.sortOrder = index
            return copy
        }
    }

    func flattenedSettings() -> BaAppSettings {
        flattenedSettings(for: selectedAccount)
    }

    func flattenedSettings(for account: BaAccountProfile) -> BaAppSettings {
        let profile = account.profile
        return BaAppSettings(
            server: account.server,
            nickname: profile.nickname,
            friendCode: profile.friendCode,
            apCurrent: profile.apCurrent,
            apLimit: profile.apLimit,
            apRegenBaseAt: profile.apRegenBaseAt,
            apSyncAt: profile.apSyncAt,
            cafeLevel: profile.cafeLevel,
            cafeApCurrent: profile.cafeApCurrent,
            cafeStorageBaseAt: profile.cafeStorageBaseAt,
            lastHeadpatAt: profile.lastHeadpatAt,
            lastInviteTicketAt: profile.lastInviteTicket1At,
            lastInviteTicket1At: profile.lastInviteTicket1At,
            lastInviteTicket2At: profile.lastInviteTicket2At,
            showEndedActivities: globalSettings.showEndedActivities,
            showEndedPools: globalSettings.showEndedPools,
            showPreviewImages: globalSettings.showPreviewImages,
            activityNotificationsEnabled: globalSettings.activityNotificationsEnabled,
            poolNotificationsEnabled: globalSettings.poolNotificationsEnabled,
            apNotificationsEnabled: profile.apNotificationsEnabled,
            cafeApNotificationsEnabled: profile.cafeApNotificationsEnabled,
            visitNotificationsEnabled: profile.visitNotificationsEnabled,
            arenaRefreshNotificationsEnabled: profile.arenaRefreshNotificationsEnabled,
            calendarUpcomingNotificationsEnabled: globalSettings.calendarUpcomingNotificationsEnabled,
            calendarEndingNotificationsEnabled: globalSettings.calendarEndingNotificationsEnabled,
            poolUpcomingNotificationsEnabled: globalSettings.poolUpcomingNotificationsEnabled,
            poolEndingNotificationsEnabled: globalSettings.poolEndingNotificationsEnabled,
            calendarPoolChangeNotificationsEnabled: globalSettings.calendarPoolChangeNotificationsEnabled,
            calendarPoolNotifyLead: globalSettings.calendarPoolNotifyLead,
            mediaAutoplayEnabled: globalSettings.mediaAutoplayEnabled,
            mediaDownloadEnabled: globalSettings.mediaDownloadEnabled,
            refreshInterval: globalSettings.refreshInterval,
            appLanguage: globalSettings.appLanguage,
            appAppearance: globalSettings.appAppearance,
            favoriteContentIDs: globalSettings.favoriteContentIDs,
            favoriteCatalogEntries: globalSettings.favoriteCatalogEntries,
            dutyStudent: globalSettings.dutyStudent,
            identityIndependentByServer: globalSettings.identityIndependentByServer,
            apNotifyThreshold: profile.apNotifyThreshold,
            cafeApNotifyThreshold: profile.cafeApNotifyThreshold,
            cafeVisitLastNotifiedAt: profile.cafeVisitLastNotifiedAt,
            arenaRefreshLastNotifiedAt: profile.arenaRefreshLastNotifiedAt
        )
    }

    private func normalizedAccountDisplayName(currentDisplayName: String, profile: BaServerProfile) -> String {
        currentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.nickname : currentDisplayName
    }
}

nonisolated extension BaServerProfile {
    func normalized() -> BaServerProfile {
        var copy = self
        let nickname = copy.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.nickname = nickname.isEmpty ? "Kei" : nickname
        copy.friendCode = BaFriendCodeFormat.normalized(copy.friendCode)
        copy.apCurrent = BaTimeMath.normalizedAP(copy.apCurrent)
        copy.apLimit = min(max(copy.apLimit, 0), BaTimeMath.apLimitMax)
        copy.cafeLevel = min(max(copy.cafeLevel, 1), 10)
        copy.cafeApCurrent = BaTimeMath.normalizedAP(copy.cafeApCurrent)
        copy.apNotifyThreshold = min(max(copy.apNotifyThreshold, 0), BaTimeMath.apMax)
        copy.cafeApNotifyThreshold = min(max(copy.cafeApNotifyThreshold, 0), BaTimeMath.apMax)
        return copy
    }
}

nonisolated struct BaAppSettings: Codable, Equatable, Sendable {
    var server: BaServer
    var nickname: String
    var friendCode: String
    var apCurrent: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var apSyncAt: Date?
    var cafeLevel: Int
    var cafeApCurrent: Double
    var cafeStorageBaseAt: Date
    var lastHeadpatAt: Date?
    var lastInviteTicketAt: Date?
    var lastInviteTicket1At: Date?
    var lastInviteTicket2At: Date?
    var showEndedActivities: Bool
    var showEndedPools: Bool
    var showPreviewImages: Bool
    var activityNotificationsEnabled: Bool
    var poolNotificationsEnabled: Bool
    var apNotificationsEnabled: Bool
    var cafeApNotificationsEnabled: Bool
    var visitNotificationsEnabled: Bool
    var arenaRefreshNotificationsEnabled: Bool
    var calendarUpcomingNotificationsEnabled: Bool
    var calendarEndingNotificationsEnabled: Bool
    var poolUpcomingNotificationsEnabled: Bool
    var poolEndingNotificationsEnabled: Bool
    var calendarPoolChangeNotificationsEnabled: Bool
    var calendarPoolNotifyLead: BaCalendarPoolNotifyLead
    var mediaAutoplayEnabled: Bool
    var mediaDownloadEnabled: Bool
    var refreshInterval: BaRefreshInterval
    var appLanguage: BaAppLanguage
    var appAppearance: BaAppAppearance
    var favoriteContentIDs: Set<Int64>
    var favoriteCatalogEntries: [BaGuideCatalogEntry]
    var dutyStudent: BaDutyStudent?
    var identityIndependentByServer: Bool
    var apNotifyThreshold: Int
    var cafeApNotifyThreshold: Int
    var cafeVisitLastNotifiedAt: Date?
    var arenaRefreshLastNotifiedAt: Date?

    static func defaults(now: Date = Date()) -> BaAppSettings {
        BaAppSettings(
            server: .cn,
            nickname: "Kei",
            friendCode: "ARISUKEI",
            apCurrent: 1,
            apLimit: 240,
            apRegenBaseAt: now,
            apSyncAt: now,
            cafeLevel: 10,
            cafeApCurrent: 462,
            cafeStorageBaseAt: now,
            lastHeadpatAt: nil,
            lastInviteTicketAt: nil,
            lastInviteTicket1At: nil,
            lastInviteTicket2At: nil,
            showEndedActivities: true,
            showEndedPools: true,
            showPreviewImages: true,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: false,
            apNotificationsEnabled: true,
            cafeApNotificationsEnabled: true,
            visitNotificationsEnabled: false,
            arenaRefreshNotificationsEnabled: false,
            calendarUpcomingNotificationsEnabled: true,
            calendarEndingNotificationsEnabled: false,
            poolUpcomingNotificationsEnabled: false,
            poolEndingNotificationsEnabled: false,
            calendarPoolChangeNotificationsEnabled: false,
            calendarPoolNotifyLead: .twentyFourHours,
            mediaAutoplayEnabled: false,
            mediaDownloadEnabled: false,
            refreshInterval: .threeHours,
            appLanguage: .system,
            appAppearance: .system,
            favoriteContentIDs: [],
            favoriteCatalogEntries: [],
            dutyStudent: nil,
            identityIndependentByServer: false,
            apNotifyThreshold: 120,
            cafeApNotifyThreshold: 120,
            cafeVisitLastNotifiedAt: nil,
            arenaRefreshLastNotifiedAt: nil
        )
    }
}

nonisolated extension BaAppSettings {
    enum CodingKeys: String, CodingKey {
        case server
        case nickname
        case friendCode
        case apCurrent
        case apLimit
        case apRegenBaseAt
        case apSyncAt
        case cafeLevel
        case cafeApCurrent
        case cafeStorageBaseAt
        case lastHeadpatAt
        case lastInviteTicketAt
        case lastInviteTicket1At
        case lastInviteTicket2At
        case showEndedActivities
        case showEndedPools
        case showPreviewImages
        case activityNotificationsEnabled
        case poolNotificationsEnabled
        case apNotificationsEnabled
        case cafeApNotificationsEnabled
        case visitNotificationsEnabled
        case arenaRefreshNotificationsEnabled
        case calendarUpcomingNotificationsEnabled
        case calendarEndingNotificationsEnabled
        case poolUpcomingNotificationsEnabled
        case poolEndingNotificationsEnabled
        case calendarPoolChangeNotificationsEnabled
        case calendarPoolNotifyLead
        case mediaAutoplayEnabled
        case mediaDownloadEnabled
        case refreshInterval
        case appLanguage
        case appAppearance
        case favoriteContentIDs
        case favoriteCatalogEntries
        case dutyStudent
        case identityIndependentByServer
        case apNotifyThreshold
        case cafeApNotifyThreshold
        case cafeVisitLastNotifiedAt
        case arenaRefreshLastNotifiedAt
    }

    init(from decoder: Decoder) throws {
        let defaults = BaAppSettings.defaults()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        server = try container.decodeIfPresent(BaServer.self, forKey: .server) ?? defaults.server
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? defaults.nickname
        friendCode = try container.decodeIfPresent(String.self, forKey: .friendCode) ?? defaults.friendCode
        apCurrent = try container.decodeIfPresent(Double.self, forKey: .apCurrent) ?? defaults.apCurrent
        apLimit = try container.decodeIfPresent(Int.self, forKey: .apLimit) ?? defaults.apLimit
        apRegenBaseAt = try container.decodeIfPresent(Date.self, forKey: .apRegenBaseAt) ?? defaults.apRegenBaseAt
        apSyncAt = try container.decodeIfPresent(Date.self, forKey: .apSyncAt)
        cafeLevel = try container.decodeIfPresent(Int.self, forKey: .cafeLevel) ?? defaults.cafeLevel
        cafeApCurrent = try container.decodeIfPresent(Double.self, forKey: .cafeApCurrent) ?? defaults.cafeApCurrent
        cafeStorageBaseAt = try container.decodeIfPresent(Date.self, forKey: .cafeStorageBaseAt) ?? defaults.cafeStorageBaseAt
        lastHeadpatAt = try container.decodeIfPresent(Date.self, forKey: .lastHeadpatAt)
        lastInviteTicketAt = try container.decodeIfPresent(Date.self, forKey: .lastInviteTicketAt)
        lastInviteTicket1At = try container.decodeIfPresent(Date.self, forKey: .lastInviteTicket1At) ?? lastInviteTicketAt
        lastInviteTicket2At = try container.decodeIfPresent(Date.self, forKey: .lastInviteTicket2At)
        showEndedActivities = try container.decodeIfPresent(Bool.self, forKey: .showEndedActivities) ?? defaults.showEndedActivities
        showEndedPools = try container.decodeIfPresent(Bool.self, forKey: .showEndedPools) ?? defaults.showEndedPools
        showPreviewImages = try container.decodeIfPresent(Bool.self, forKey: .showPreviewImages) ?? defaults.showPreviewImages
        activityNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .activityNotificationsEnabled) ?? defaults.activityNotificationsEnabled
        poolNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolNotificationsEnabled) ?? defaults.poolNotificationsEnabled
        apNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .apNotificationsEnabled) ?? defaults.apNotificationsEnabled
        cafeApNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .cafeApNotificationsEnabled) ?? defaults.cafeApNotificationsEnabled
        visitNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .visitNotificationsEnabled) ?? defaults.visitNotificationsEnabled
        arenaRefreshNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .arenaRefreshNotificationsEnabled) ?? defaults.arenaRefreshNotificationsEnabled
        calendarUpcomingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarUpcomingNotificationsEnabled) ?? activityNotificationsEnabled
        calendarEndingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarEndingNotificationsEnabled) ?? false
        poolUpcomingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolUpcomingNotificationsEnabled) ?? poolNotificationsEnabled
        poolEndingNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .poolEndingNotificationsEnabled) ?? false
        calendarPoolChangeNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .calendarPoolChangeNotificationsEnabled) ?? false
        calendarPoolNotifyLead = try container.decodeIfPresent(BaCalendarPoolNotifyLead.self, forKey: .calendarPoolNotifyLead) ?? defaults.calendarPoolNotifyLead
        mediaAutoplayEnabled = try container.decodeIfPresent(Bool.self, forKey: .mediaAutoplayEnabled) ?? defaults.mediaAutoplayEnabled
        mediaDownloadEnabled = try container.decodeIfPresent(Bool.self, forKey: .mediaDownloadEnabled) ?? defaults.mediaDownloadEnabled
        refreshInterval = try container.decodeIfPresent(BaRefreshInterval.self, forKey: .refreshInterval) ?? defaults.refreshInterval
        appLanguage = try container.decodeIfPresent(BaAppLanguage.self, forKey: .appLanguage) ?? defaults.appLanguage
        appAppearance = try container.decodeIfPresent(BaAppAppearance.self, forKey: .appAppearance) ?? defaults.appAppearance
        favoriteContentIDs = try container.decodeIfPresent(Set<Int64>.self, forKey: .favoriteContentIDs) ?? defaults.favoriteContentIDs
        favoriteCatalogEntries = try container.decodeIfPresent([BaGuideCatalogEntry].self, forKey: .favoriteCatalogEntries) ?? defaults.favoriteCatalogEntries
        dutyStudent = try container.decodeIfPresent(BaDutyStudent.self, forKey: .dutyStudent)
        identityIndependentByServer = try container.decodeIfPresent(Bool.self, forKey: .identityIndependentByServer) ?? false
        apNotifyThreshold = try container.decodeIfPresent(Int.self, forKey: .apNotifyThreshold) ?? defaults.apNotifyThreshold
        cafeApNotifyThreshold = try container.decodeIfPresent(Int.self, forKey: .cafeApNotifyThreshold) ?? defaults.cafeApNotifyThreshold
        cafeVisitLastNotifiedAt = try container.decodeIfPresent(Date.self, forKey: .cafeVisitLastNotifiedAt)
        arenaRefreshLastNotifiedAt = try container.decodeIfPresent(Date.self, forKey: .arenaRefreshLastNotifiedAt)
    }
}
