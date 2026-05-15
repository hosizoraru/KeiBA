//
//  BaDomainModels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation
import SwiftUI

nonisolated enum BaServer: String, CaseIterable, Codable, Identifiable, Hashable {
    case cn
    case global
    case jp

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .cn:
            String(localized: "ba.server.cn")
        case .global:
            String(localized: "ba.server.global")
        case .jp:
            String(localized: "ba.server.jp")
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

nonisolated enum BaRefreshInterval: Int, CaseIterable, Codable, Identifiable, Hashable {
    case oneHour = 1
    case threeHours = 3
    case sixHours = 6
    case twelveHours = 12
    case twentyFourHours = 24

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .oneHour:
            String(localized: "ba.settings.refresh.interval.1h")
        case .threeHours:
            String(localized: "ba.settings.refresh.interval.3h")
        case .sixHours:
            String(localized: "ba.settings.refresh.interval.6h")
        case .twelveHours:
            String(localized: "ba.settings.refresh.interval.12h")
        case .twentyFourHours:
            String(localized: "ba.settings.refresh.interval.24h")
        }
    }
}

nonisolated enum BaCalendarPoolNotifyLead: Int, CaseIterable, Codable, Identifiable, Hashable {
    case oneHour = 1
    case threeHours = 3
    case sixHours = 6
    case twelveHours = 12
    case twentyFourHours = 24

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .oneHour:
            String(localized: "ba.settings.refresh.interval.1h")
        case .threeHours:
            String(localized: "ba.settings.refresh.interval.3h")
        case .sixHours:
            String(localized: "ba.settings.refresh.interval.6h")
        case .twelveHours:
            String(localized: "ba.settings.refresh.interval.12h")
        case .twentyFourHours:
            String(localized: "ba.settings.refresh.interval.24h")
        }
    }
}

nonisolated struct BaGlobalSettings: Codable, Equatable {
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
    var favoriteContentIDs: Set<Int64>

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
            favoriteContentIDs: []
        )
    }
}

nonisolated struct BaServerProfile: Codable, Equatable {
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

nonisolated struct BaSettingsEnvelope: Codable, Equatable {
    var schemaVersion: Int
    var selectedServer: BaServer
    var globalSettings: BaGlobalSettings
    var serverProfiles: [BaServer: BaServerProfile]

    static let currentSchemaVersion = 2

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
            favoriteContentIDs: settings.favoriteContentIDs
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
            favoriteContentIDs: globalSettings.favoriteContentIDs,
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
        let friendCode = copy.friendCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        copy.nickname = nickname.isEmpty ? "Kei" : nickname
        copy.friendCode = friendCode.isEmpty ? "ARISUKEI" : friendCode
        copy.apCurrent = BaTimeMath.normalizedAP(copy.apCurrent)
        copy.apLimit = min(max(copy.apLimit, 0), BaTimeMath.apLimitMax)
        copy.cafeLevel = min(max(copy.cafeLevel, 1), 10)
        copy.cafeApCurrent = BaTimeMath.normalizedAP(copy.cafeApCurrent)
        copy.apNotifyThreshold = min(max(copy.apNotifyThreshold, 0), BaTimeMath.apMax)
        copy.cafeApNotifyThreshold = min(max(copy.cafeApNotifyThreshold, 0), BaTimeMath.apMax)
        return copy
    }
}

nonisolated struct BaAppSettings: Codable, Equatable {
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
    var favoriteContentIDs: Set<Int64>
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
            favoriteContentIDs: [],
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
        case favoriteContentIDs
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
        favoriteContentIDs = try container.decodeIfPresent(Set<Int64>.self, forKey: .favoriteContentIDs) ?? defaults.favoriteContentIDs
        identityIndependentByServer = try container.decodeIfPresent(Bool.self, forKey: .identityIndependentByServer) ?? false
        apNotifyThreshold = try container.decodeIfPresent(Int.self, forKey: .apNotifyThreshold) ?? defaults.apNotifyThreshold
        cafeApNotifyThreshold = try container.decodeIfPresent(Int.self, forKey: .cafeApNotifyThreshold) ?? defaults.cafeApNotifyThreshold
        cafeVisitLastNotifiedAt = try container.decodeIfPresent(Date.self, forKey: .cafeVisitLastNotifiedAt)
        arenaRefreshLastNotifiedAt = try container.decodeIfPresent(Date.self, forKey: .arenaRefreshLastNotifiedAt)
    }
}

nonisolated struct BaOfficeSnapshot: Equatable {
    let nickname: String
    let teacherSuffix: String
    let friendCode: String
    let server: String
    let apCurrent: String
    let apLimit: String
    let apCurrentLimit: String
    let apRemaining: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
    let cafeApCurrent: String
    let cafeApLimit: String
    let cafeLevel: String
    let cafeVisitRefresh: String
    let cafeVisitDetail: String
    let cafeVisitSlots: [BaCafeVisitSnapshot]
    let tacticalRefresh: String
    let tacticalRefreshDetail: String
    let headpatRemain: String
    let headpatDetail: String
    let cafeActions: [BaCafeActionSnapshot]
}

nonisolated struct BaOfficeAPSnapshot: Equatable {
    let apCurrent: String
    let apLimit: String
    let apCurrentLimit: String
    let apRemaining: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
}

nonisolated struct BaCafeVisitSnapshot: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let value: String
    let detail: String
}

nonisolated enum BaCafeActionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case headpat
    case inviteTicket1
    case inviteTicket2

    var id: Self {
        self
    }
}

nonisolated struct BaCafeActionSnapshot: Identifiable, Codable, Equatable, Hashable {
    let kind: BaCafeActionKind
    let title: String
    let value: String
    let detail: String
    let asset: BaGameAsset
    let tintName: String
    let isReady: Bool

    var id: BaCafeActionKind {
        kind
    }
}

enum BaTimelineStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case running
    case upcoming
    case ended

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .running:
            String(localized: "ba.status.running")
        case .upcoming:
            String(localized: "ba.status.upcoming")
        case .ended:
            String(localized: "ba.status.ended")
        }
    }

    var tint: Color {
        switch self {
        case .running:
            BaDesign.green
        case .upcoming:
            BaDesign.blue
        case .ended:
            .secondary
        }
    }
}

nonisolated struct BaActivityEntry: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let kindId: Int
    let kindName: String
    let beginAt: Date
    let endAt: Date
    let linkURL: URL?
    let imageURL: URL?

    func status(at now: Date = Date()) -> BaTimelineStatus {
        if now >= beginAt && now < endAt {
            return .running
        }
        if now < beginAt {
            return .upcoming
        }
        return .ended
    }

    func progress(at now: Date = Date()) -> Double {
        guard endAt > beginAt else { return 0 }
        let elapsed = now.timeIntervalSince(beginAt)
        let total = endAt.timeIntervalSince(beginAt)
        return min(max(elapsed / total, 0), 1)
    }
}

nonisolated struct BaPoolEntry: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let tagId: Int
    let tagName: String
    let alias: String
    let startAt: Date
    let endAt: Date
    let linkURL: URL?
    let imageURL: URL?
    let contentId: Int64?
    let studentGuideURL: URL?

    func status(at now: Date = Date()) -> BaTimelineStatus {
        if now >= startAt && now < endAt {
            return .running
        }
        if now < startAt {
            return .upcoming
        }
        return .ended
    }

    func progress(at now: Date = Date()) -> Double {
        guard endAt > startAt else { return 0 }
        let elapsed = now.timeIntervalSince(startAt)
        let total = endAt.timeIntervalSince(startAt)
        return min(max(elapsed / total, 0), 1)
    }

    func withStudentGuideURL(_ studentGuideURL: URL?) -> BaPoolEntry {
        BaPoolEntry(
            id: id,
            name: name,
            tagId: tagId,
            tagName: tagName,
            alias: alias,
            startAt: startAt,
            endAt: endAt,
            linkURL: linkURL,
            imageURL: imageURL,
            contentId: contentId,
            studentGuideURL: studentGuideURL
        )
    }
}

nonisolated enum BaCatalogCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case students
    case npcSatellite
    case studentBgm
    case favorites

    static let catalogCases: [BaCatalogCategory] = [.students, .npcSatellite]
    static let libraryCases: [BaCatalogCategory] = [.studentBgm, .favorites]

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.category.students")
        case .npcSatellite:
            String(localized: "ba.catalog.category.npcSatellite")
        case .studentBgm:
            String(localized: "ba.catalog.category.studentBgm")
        case .favorites:
            String(localized: "ba.catalog.category.favorites")
        }
    }

    var searchPrompt: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.search.students.prompt")
        case .npcSatellite:
            String(localized: "ba.catalog.search.npc.prompt")
        case .studentBgm:
            String(localized: "ba.catalog.search.bgm.prompt")
        case .favorites:
            String(localized: "ba.catalog.search.favorites.prompt")
        }
    }
}

nonisolated struct BaGuideCatalogEntry: Identifiable, Codable, Hashable {
    let entryId: Int
    let pid: Int
    let contentId: Int64
    let name: String
    let alias: String
    let aliasDisplay: String
    let iconURL: URL?
    let type: Int
    let order: Int
    let createdAt: Date?
    let releaseDate: Date?
    let detailURL: URL?
    let category: BaCatalogCategory

    var id: Int64 {
        contentId
    }

    func matches(query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return true }
        return name.localizedCaseInsensitiveContains(keyword) ||
            alias.localizedCaseInsensitiveContains(keyword) ||
            "\(contentId)".contains(keyword)
    }

    func withCategory(_ category: BaCatalogCategory) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: entryId,
            pid: pid,
            contentId: contentId,
            name: name,
            alias: alias,
            aliasDisplay: aliasDisplay,
            iconURL: iconURL,
            type: type,
            order: order,
            createdAt: createdAt,
            releaseDate: releaseDate,
            detailURL: detailURL,
            category: category
        )
    }

    func withReleaseDate(_ releaseDate: Date?) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: entryId,
            pid: pid,
            contentId: contentId,
            name: name,
            alias: alias,
            aliasDisplay: aliasDisplay,
            iconURL: iconURL,
            type: type,
            order: order,
            createdAt: createdAt,
            releaseDate: releaseDate ?? self.releaseDate,
            detailURL: detailURL,
            category: category
        )
    }
}

nonisolated struct BaGuideCatalogBundle: Codable, Hashable {
    let entries: [BaGuideCatalogEntry]
    let syncedAt: Date

    func entries(in category: BaCatalogCategory) -> [BaGuideCatalogEntry] {
        entries.filter { $0.category == category }
    }
}

nonisolated enum BaStudentDetailSection: String, CaseIterable, Codable, Identifiable, Hashable {
    case profile
    case skills
    case growth
    case voice
    case gallery
    case simulate

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .profile:
            String(localized: "ba.student.detail.section.profile")
        case .skills:
            String(localized: "ba.student.detail.section.skills")
        case .growth:
            String(localized: "ba.student.detail.section.growth")
        case .voice:
            String(localized: "ba.student.detail.section.voice")
        case .gallery:
            String(localized: "ba.student.detail.section.gallery")
        case .simulate:
            String(localized: "ba.student.detail.section.simulate")
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "person.text.rectangle"
        case .skills:
            "sparkles"
        case .growth:
            "shield.lefthalf.filled"
        case .voice:
            "waveform"
        case .gallery:
            "photo.on.rectangle.angled"
        case .simulate:
            "chart.xyaxis.line"
        }
    }
}

nonisolated enum BaStudentDetailPage: String, CaseIterable, Codable, Identifiable, Hashable {
    case overviewProfile
    case skills
    case profile
    case voice
    case gallery
    case simulate

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .overviewProfile:
            String(localized: "ba.student.detail.page.overviewProfile")
        case .skills:
            String(localized: "ba.student.detail.page.skills")
        case .profile:
            String(localized: "ba.student.detail.page.profile")
        case .voice:
            String(localized: "ba.student.detail.page.voice")
        case .gallery:
            String(localized: "ba.student.detail.page.gallery")
        case .simulate:
            String(localized: "ba.student.detail.page.simulate")
        }
    }
}

nonisolated struct BaGuideRow: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let value: String
    let imageURL: URL?
    var imageURLs: [URL]? = nil
}

nonisolated enum BaGuideMediaKind: String, Codable, Hashable {
    case image
    case video
    case audio
    case live2d
    case unknown

    var systemImage: String {
        switch self {
        case .image:
            "photo"
        case .video:
            "play.rectangle"
        case .audio:
            "waveform"
        case .live2d:
            "person.crop.square"
        case .unknown:
            "paperclip"
        }
    }

    var title: String {
        switch self {
        case .image:
            String(localized: "ba.student.detail.media.image")
        case .video:
            String(localized: "ba.student.detail.media.video")
        case .audio:
            String(localized: "ba.student.detail.media.audio")
        case .live2d:
            String(localized: "ba.student.detail.media.live2d")
        case .unknown:
            String(localized: "ba.student.detail.media.unknown")
        }
    }
}

nonisolated struct BaGuideGalleryItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let imageURL: URL?
    let mediaURL: URL?
    var mediaKind: BaGuideMediaKind? = nil
    var memoryUnlockLevel: String? = nil
    var note: String? = nil
}

nonisolated struct BaGuideVoiceEntry: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let transcript: String
    let audioURL: URL?
    var section: String? = nil
    var lineHeaders: [String]? = nil
    var lines: [String]? = nil
    var audioURLs: [URL]? = nil
    var audioHeaders: [String]? = nil
}

nonisolated struct BaStudentGuideInfo: Identifiable, Codable, Hashable {
    let contentId: Int64
    let sourceURL: URL?
    let title: String
    let subtitle: String
    let summary: String
    let imageURL: URL?
    let stats: [BaGuideRow]
    let profileRows: [BaGuideRow]
    let skillRows: [BaGuideRow]
    let voiceLanguageHeaders: [String]
    let voiceRows: [BaGuideVoiceEntry]
    let galleryItems: [BaGuideGalleryItem]
    let growthRows: [BaGuideRow]
    let simulateRows: [BaGuideRow]
    let contentSource: String
    let syncedAt: Date

    var id: Int64 {
        contentId
    }

    init(
        contentId: Int64,
        sourceURL: URL?,
        title: String,
        subtitle: String,
        summary: String,
        imageURL: URL?,
        stats: [BaGuideRow],
        profileRows: [BaGuideRow],
        skillRows: [BaGuideRow],
        voiceLanguageHeaders: [String] = [],
        voiceRows: [BaGuideVoiceEntry],
        galleryItems: [BaGuideGalleryItem],
        growthRows: [BaGuideRow],
        simulateRows: [BaGuideRow],
        contentSource: String,
        syncedAt: Date
    ) {
        self.contentId = contentId
        self.sourceURL = sourceURL
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.imageURL = imageURL
        self.stats = stats
        self.profileRows = profileRows
        self.skillRows = skillRows
        self.voiceLanguageHeaders = voiceLanguageHeaders
        self.voiceRows = voiceRows
        self.galleryItems = galleryItems
        self.growthRows = growthRows
        self.simulateRows = simulateRows
        self.contentSource = contentSource
        self.syncedAt = syncedAt
    }

    private enum CodingKeys: String, CodingKey {
        case contentId
        case sourceURL
        case title
        case subtitle
        case summary
        case imageURL
        case stats
        case profileRows
        case skillRows
        case voiceLanguageHeaders
        case voiceRows
        case galleryItems
        case growthRows
        case simulateRows
        case contentSource
        case syncedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            contentId: try container.decode(Int64.self, forKey: .contentId),
            sourceURL: try container.decodeIfPresent(URL.self, forKey: .sourceURL),
            title: try container.decode(String.self, forKey: .title),
            subtitle: try container.decode(String.self, forKey: .subtitle),
            summary: try container.decode(String.self, forKey: .summary),
            imageURL: try container.decodeIfPresent(URL.self, forKey: .imageURL),
            stats: try container.decode([BaGuideRow].self, forKey: .stats),
            profileRows: try container.decode([BaGuideRow].self, forKey: .profileRows),
            skillRows: try container.decode([BaGuideRow].self, forKey: .skillRows),
            voiceLanguageHeaders: try container.decodeIfPresent([String].self, forKey: .voiceLanguageHeaders) ?? [],
            voiceRows: try container.decode([BaGuideVoiceEntry].self, forKey: .voiceRows),
            galleryItems: try container.decode([BaGuideGalleryItem].self, forKey: .galleryItems),
            growthRows: try container.decode([BaGuideRow].self, forKey: .growthRows),
            simulateRows: try container.decode([BaGuideRow].self, forKey: .simulateRows),
            contentSource: try container.decode(String.self, forKey: .contentSource),
            syncedAt: try container.decode(Date.self, forKey: .syncedAt)
        )
    }
}

struct BaLoadableState<Value> {
    var value: Value?
    var isLoading: Bool
    var errorMessage: String?
    var lastSyncAt: Date?
    var isShowingCache: Bool

    init(
        value: Value? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        lastSyncAt: Date? = nil,
        isShowingCache: Bool = false
    ) {
        self.value = value
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.lastSyncAt = lastSyncAt
        self.isShowingCache = isShowingCache
    }
}

nonisolated struct BaCacheEnvelope<Value: Codable>: Codable {
    let schemaVersion: Int
    let syncedAt: Date
    let value: Value
}
