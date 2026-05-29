//
//  BaDashboardWidgetProvider.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import Foundation
import WidgetKit

nonisolated struct BaDashboardWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: BaWatchDashboardSnapshot?
    let isPlaceholder: Bool

    static func placeholder(date: Date = Date()) -> BaDashboardWidgetEntry {
        BaDashboardWidgetEntry(
            date: date,
            snapshot: .widgetPreview(now: date),
            isPlaceholder: true
        )
    }

    static func current(date: Date = Date()) -> BaDashboardWidgetEntry {
        BaDashboardWidgetEntry(
            date: date,
            snapshot: BaDashboardSnapshotSharing.loadSnapshot(),
            isPlaceholder: false
        )
    }
}

nonisolated struct BaDashboardWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BaDashboardWidgetEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (BaDashboardWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder() : .current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BaDashboardWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = BaDashboardSnapshotSharing.loadSnapshot()
        let dates = BaDashboardWidgetSchedule.entryDates(for: snapshot, from: now)
        let entries = dates.map { date in
            BaDashboardWidgetEntry(date: date, snapshot: snapshot, isPlaceholder: false)
        }
        let refreshDate = dates.last?.addingTimeInterval(60) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

private enum BaDashboardWidgetSchedule {
    nonisolated static func entryDates(for snapshot: BaWatchDashboardSnapshot?, from now: Date) -> [Date] {
        guard let snapshot else {
            return [roundedMinute(now)]
        }

        var dates = Set<Date>()
        dates.insert(roundedMinute(now))

        for offset in 1...12 {
            dates.insert(roundedMinute(now.addingTimeInterval(TimeInterval(offset) * BaWatchTimeMath.apRegenInterval)))
        }

        for offset in 1...4 {
            dates.insert(roundedMinute(now.addingTimeInterval(TimeInterval(offset) * BaWatchTimeMath.cafeHourlyInterval)))
        }

        add(snapshot.apFullAt(from: now), to: &dates, now: now)
        add(snapshot.cafeAPFullAt(from: now), to: &dates, now: now)
        addTimelineDates(snapshot.timeline.activities, to: &dates, now: now)
        addTimelineDates(snapshot.timeline.pools, to: &dates, now: now)

        return Array(dates)
            .filter { $0 >= now.addingTimeInterval(-60) }
            .sorted()
            .prefix(24)
            .map { $0 }
    }

    nonisolated private static func add(_ date: Date?, to dates: inout Set<Date>, now: Date) {
        guard let date, date > now else { return }
        dates.insert(roundedMinute(date))
    }

    nonisolated private static func addTimelineDates(
        _ section: BaTimelineGlanceSection,
        to dates: inout Set<Date>,
        now: Date
    ) {
        for item in section.displayItems {
            add(item.startAt, to: &dates, now: now)
            add(item.endAt, to: &dates, now: now)
        }
    }

    nonisolated private static func roundedMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60)
    }
}

private extension BaWatchDashboardSnapshot {
    nonisolated static func widgetPreview(now: Date) -> BaWatchDashboardSnapshot {
        BaWatchDashboardSnapshot(
            sourceUpdatedAt: now,
            generatedAt: now,
            officeName: "沙勒办公室",
            officeShortName: "沙勒",
            serverName: "国服",
            teacherName: "Voyager",
            friendCode: "BA26TEST",
            dutyStudentName: "阿罗娜",
            dutyStudentAvatarURLString: nil,
            dutyStudentAvatarImageData: nil,
            apBaseValue: 126,
            apLimit: 240,
            apRegenBaseAt: now.addingTimeInterval(-18 * 60),
            apNotificationsEnabled: true,
            apNotifyThreshold: 220,
            cafeLevel: 10,
            cafeAPBaseValue: 420,
            cafeStorageBaseAt: now.addingTimeInterval(-2 * 60 * 60),
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 650,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: true,
            favoriteStudentCount: 12,
            timeline: BaTimelineGlanceSnapshot(
                generatedAt: now,
                activities: BaTimelineGlanceSection(
                    runningCount: 2,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "特别委托活动",
                        status: .running,
                        startAt: now.addingTimeInterval(-2 * 24 * 60 * 60),
                        endAt: now.addingTimeInterval(20 * 60 * 60),
                        relatedItemCount: 1
                    ),
                    items: [
                        BaTimelineGlanceItem(
                            title: "特别委托活动",
                            status: .running,
                            startAt: now.addingTimeInterval(-2 * 24 * 60 * 60),
                            endAt: now.addingTimeInterval(20 * 60 * 60),
                            relatedItemCount: 1
                        ),
                        BaTimelineGlanceItem(
                            title: "大决战「市街地战・黑影」",
                            status: .running,
                            startAt: now.addingTimeInterval(-8 * 60 * 60),
                            endAt: now.addingTimeInterval(5 * 60 * 60)
                        ),
                    ],
                    lastSyncAt: now,
                    isShowingCache: false
                ),
                pools: BaTimelineGlanceSection(
                    runningCount: 1,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "FES 招募",
                        status: .running,
                        startAt: now.addingTimeInterval(-6 * 60 * 60),
                        endAt: now.addingTimeInterval(3 * 24 * 60 * 60)
                    ),
                    items: [
                        BaTimelineGlanceItem(
                            title: "FES 招募",
                            status: .running,
                            startAt: now.addingTimeInterval(-6 * 60 * 60),
                            endAt: now.addingTimeInterval(3 * 24 * 60 * 60)
                        ),
                        BaTimelineGlanceItem(
                            title: "限定复刻招募",
                            status: .upcoming,
                            startAt: now.addingTimeInterval(5 * 24 * 60 * 60),
                            endAt: now.addingTimeInterval(12 * 24 * 60 * 60)
                        ),
                    ],
                    lastSyncAt: now,
                    isShowingCache: false
                )
            )
        )
    }
}
