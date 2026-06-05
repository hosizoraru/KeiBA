//
//  BaTimelineGlanceSnapshot.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import Foundation

nonisolated enum BaTimelineGlanceStatus: String, Codable, Equatable, Sendable {
    case running
    case upcoming
    case ended
}

nonisolated struct BaTimelineGlanceItem: Codable, Equatable, Sendable {
    var title: String
    var status: BaTimelineGlanceStatus
    var startAt: Date
    var endAt: Date
    var relatedItemCount: Int

    init(
        title: String,
        status: BaTimelineGlanceStatus,
        startAt: Date,
        endAt: Date,
        relatedItemCount: Int = 0
    ) {
        self.title = title
        self.status = status
        self.startAt = startAt
        self.endAt = endAt
        self.relatedItemCount = max(relatedItemCount, 0)
    }

    func progress(at date: Date = Date()) -> Double {
        guard endAt > startAt else { return 0 }
        return min(max(date.timeIntervalSince(startAt) / endAt.timeIntervalSince(startAt), 0), 1)
    }
}

nonisolated struct BaTimelineGlanceSection: Codable, Equatable, Sendable {
    var runningCount: Int
    var upcomingCount: Int
    var endedCount: Int
    var featuredItem: BaTimelineGlanceItem?
    var items: [BaTimelineGlanceItem]
    var lastSyncAt: Date?
    var isShowingCache: Bool

    enum CodingKeys: String, CodingKey {
        case runningCount
        case upcomingCount
        case endedCount
        case featuredItem
        case items
        case lastSyncAt
        case isShowingCache
    }

    init(
        runningCount: Int = 0,
        upcomingCount: Int = 0,
        endedCount: Int = 0,
        featuredItem: BaTimelineGlanceItem? = nil,
        items: [BaTimelineGlanceItem] = [],
        lastSyncAt: Date? = nil,
        isShowingCache: Bool = false
    ) {
        self.runningCount = max(runningCount, 0)
        self.upcomingCount = max(upcomingCount, 0)
        self.endedCount = max(endedCount, 0)
        self.featuredItem = featuredItem
        self.items = Self.normalizedItems(items, featuredItem: featuredItem)
        self.lastSyncAt = lastSyncAt
        self.isShowingCache = isShowingCache
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        runningCount = max(try container.decode(Int.self, forKey: .runningCount), 0)
        upcomingCount = max(try container.decode(Int.self, forKey: .upcomingCount), 0)
        endedCount = max(try container.decode(Int.self, forKey: .endedCount), 0)
        featuredItem = try container.decodeIfPresent(BaTimelineGlanceItem.self, forKey: .featuredItem)
        items = Self.normalizedItems(
            try container.decodeIfPresent([BaTimelineGlanceItem].self, forKey: .items) ?? [],
            featuredItem: featuredItem
        )
        lastSyncAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncAt)
        isShowingCache = try container.decode(Bool.self, forKey: .isShowingCache)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(runningCount, forKey: .runningCount)
        try container.encode(upcomingCount, forKey: .upcomingCount)
        try container.encode(endedCount, forKey: .endedCount)
        try container.encodeIfPresent(featuredItem, forKey: .featuredItem)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(lastSyncAt, forKey: .lastSyncAt)
        try container.encode(isShowingCache, forKey: .isShowingCache)
    }

    var hasContent: Bool {
        runningCount > 0 || upcomingCount > 0 || endedCount > 0 || featuredItem != nil || items.isEmpty == false
    }

    var displayItems: [BaTimelineGlanceItem] {
        items.isEmpty ? featuredItem.map { [$0] } ?? [] : items
    }

    private static func normalizedItems(
        _ items: [BaTimelineGlanceItem],
        featuredItem: BaTimelineGlanceItem?
    ) -> [BaTimelineGlanceItem] {
        if items.isEmpty, let featuredItem {
            return [featuredItem]
        }
        return Array(items.prefix(4))
    }
}

nonisolated struct BaTimelineGlanceSnapshot: Codable, Equatable, Sendable {
    var generatedAt: Date
    var activities: BaTimelineGlanceSection
    var pools: BaTimelineGlanceSection

    init(
        generatedAt: Date,
        activities: BaTimelineGlanceSection = BaTimelineGlanceSection(),
        pools: BaTimelineGlanceSection = BaTimelineGlanceSection()
    ) {
        self.generatedAt = generatedAt
        self.activities = activities
        self.pools = pools
    }

    static func empty(generatedAt: Date = Date()) -> BaTimelineGlanceSnapshot {
        BaTimelineGlanceSnapshot(generatedAt: generatedAt)
    }
}
