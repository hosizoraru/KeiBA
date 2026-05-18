//
//  BaTimelineGlanceSnapshot.swift
//  KeiBAOS
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
    var lastSyncAt: Date?
    var isShowingCache: Bool

    init(
        runningCount: Int = 0,
        upcomingCount: Int = 0,
        endedCount: Int = 0,
        featuredItem: BaTimelineGlanceItem? = nil,
        lastSyncAt: Date? = nil,
        isShowingCache: Bool = false
    ) {
        self.runningCount = max(runningCount, 0)
        self.upcomingCount = max(upcomingCount, 0)
        self.endedCount = max(endedCount, 0)
        self.featuredItem = featuredItem
        self.lastSyncAt = lastSyncAt
        self.isShowingCache = isShowingCache
    }

    var hasContent: Bool {
        runningCount > 0 || upcomingCount > 0 || endedCount > 0 || featuredItem != nil
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
