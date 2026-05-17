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

nonisolated struct BaSettingsEnvelope: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var selectedServer: BaServer
    var globalSettings: BaGlobalSettings
    var serverProfiles: [BaServer: BaServerProfile]

    static let currentSchemaVersion = 5

    static func defaults(now: Date = Date()) -> BaSettingsEnvelope {
        let profile = BaServerProfile.defaults(now: now)
        return BaSettingsEnvelope(
            schemaVersion: currentSchemaVersion,
            selectedServer: .cn,
            globalSettings: .defaults(),
            serverProfiles: Dictionary(uniqueKeysWithValues: BaServer.allCases.map { ($0, profile) })
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
        if envelope.globalSettings.identityIndependentByServer == false {
            for server in BaServer.allCases {
                envelope.serverProfiles[server]?.nickname = settings.nickname
                envelope.serverProfiles[server]?.friendCode = settings.friendCode
            }
        }
        return envelope
    }

    func profile(for server: BaServer) -> BaServerProfile {
        serverProfiles[server] ?? .defaults()
    }

    mutating func setProfile(_ profile: BaServerProfile, for server: BaServer) {
        serverProfiles[server] = profile.normalized()
    }

    func flattenedSettings() -> BaAppSettings {
        let profile = profile(for: selectedServer)
        return BaAppSettings(
            server: selectedServer,
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
