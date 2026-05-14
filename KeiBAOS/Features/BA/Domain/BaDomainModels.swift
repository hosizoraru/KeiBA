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

nonisolated struct BaAppSettings: Codable, Equatable {
    var server: BaServer
    var nickname: String
    var friendCode: String
    var apCurrent: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var cafeLevel: Int
    var cafeApCurrent: Double
    var cafeStorageBaseAt: Date
    var lastHeadpatAt: Date?
    var lastInviteTicketAt: Date?
    var showEndedActivities: Bool
    var showEndedPools: Bool
    var showPreviewImages: Bool
    var activityNotificationsEnabled: Bool
    var poolNotificationsEnabled: Bool
    var apNotificationsEnabled: Bool
    var cafeApNotificationsEnabled: Bool
    var visitNotificationsEnabled: Bool
    var mediaAutoplayEnabled: Bool
    var mediaDownloadEnabled: Bool
    var refreshInterval: BaRefreshInterval
    var favoriteContentIDs: Set<Int64>

    static func defaults(now: Date = Date()) -> BaAppSettings {
        BaAppSettings(
            server: .cn,
            nickname: "Kei",
            friendCode: "ARISUKEI",
            apCurrent: 1,
            apLimit: 240,
            apRegenBaseAt: now,
            cafeLevel: 10,
            cafeApCurrent: 462,
            cafeStorageBaseAt: now,
            lastHeadpatAt: nil,
            lastInviteTicketAt: nil,
            showEndedActivities: true,
            showEndedPools: true,
            showPreviewImages: true,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: false,
            apNotificationsEnabled: true,
            cafeApNotificationsEnabled: true,
            visitNotificationsEnabled: false,
            mediaAutoplayEnabled: false,
            mediaDownloadEnabled: false,
            refreshInterval: .threeHours,
            favoriteContentIDs: []
        )
    }
}

nonisolated struct BaOfficeSnapshot: Equatable {
    let nickname: String
    let teacherSuffix: String
    let friendCode: String
    let server: String
    let apCurrent: String
    let apLimit: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
    let cafeApCurrent: String
    let cafeApLimit: String
    let cafeLevel: String
    let cafeVisitRefresh: String
    let tacticalRefresh: String
    let headpatRemain: String
    let headpatDetail: String
    let inviteRemain: String
    let inviteDetail: String
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
}

nonisolated enum BaCatalogCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case students
    case npcSatellite
    case studentBgm
    case favorites

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
        case .voice:
            String(localized: "ba.student.detail.page.voice")
        case .gallery:
            String(localized: "ba.student.detail.page.gallery")
        case .simulate:
            String(localized: "ba.student.detail.page.simulate")
        }
    }

    var systemImage: String {
        switch self {
        case .overviewProfile:
            "person.text.rectangle"
        case .skills:
            "sparkles"
        case .voice:
            "waveform"
        case .gallery:
            "photo.on.rectangle.angled"
        case .simulate:
            "chart.xyaxis.line"
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
    let voiceRows: [BaGuideVoiceEntry]
    let galleryItems: [BaGuideGalleryItem]
    let growthRows: [BaGuideRow]
    let simulateRows: [BaGuideRow]
    let contentSource: String
    let syncedAt: Date

    var id: Int64 {
        contentId
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
