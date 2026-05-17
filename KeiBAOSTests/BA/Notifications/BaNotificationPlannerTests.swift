//
//  BaNotificationPlannerTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

import Foundation
@testable import KeiBAOS
import XCTest

final class BaNotificationPlannerTests: XCTestCase {
    func testAPReminderUsesConfiguredThresholdDate() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.apNotificationsEnabled = true
        settings.apCurrent = 100
        settings.apLimit = 240
        settings.apNotifyThreshold = 120
        settings.apRegenBaseAt = now

        let plan = BaNotificationPlanner.makePlan(
            settings: settings,
            activities: [],
            pools: [],
            now: now
        )

        XCTAssertEqual(plan.reminders.map(\.kind), [.ap])
        XCTAssertEqual(plan.reminders.first?.fireDate, now.addingTimeInterval(120 * 60))
        XCTAssertEqual(plan.reminders.first?.bodyArguments.first, "120")
    }

    func testCafeAPReminderFallsBackToCapacityAfterThresholdHasPassed() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.cafeApNotificationsEnabled = true
        settings.cafeLevel = 10
        settings.cafeApCurrent = 462
        settings.cafeApNotifyThreshold = 120
        settings.cafeStorageBaseAt = now

        let plan = BaNotificationPlanner.makePlan(
            settings: settings,
            activities: [],
            pools: [],
            now: now
        )

        XCTAssertEqual(plan.reminders.map(\.kind), [.cafeAP])
        XCTAssertEqual(plan.reminders.first?.bodyArguments.first, "740")
        XCTAssertEqual(plan.reminders.first?.fireDate, now.addingTimeInterval(10 * 60 * 60))
    }

    func testTimelineRemindersHonorLeadTimeAndSpecificSwitches() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.calendarUpcomingNotificationsEnabled = true
        settings.calendarEndingNotificationsEnabled = true
        settings.calendarPoolNotifyLead = .twentyFourHours
        let activity = BaActivityEntry(
            id: 10,
            title: "夏日活动",
            kindId: 1,
            kindName: "活动",
            beginAt: now.addingTimeInterval(2 * 24 * 60 * 60),
            endAt: now.addingTimeInterval(3 * 24 * 60 * 60),
            linkURL: nil,
            imageURL: nil
        )

        let plan = BaNotificationPlanner.makePlan(
            settings: settings,
            activities: [activity],
            pools: [],
            now: now
        )

        XCTAssertEqual(plan.reminders.map(\.kind), [.activityStart, .activityEnd])
        XCTAssertEqual(plan.reminders[0].fireDate, now.addingTimeInterval(24 * 60 * 60))
        XCTAssertEqual(plan.reminders[1].fireDate, now.addingTimeInterval(2 * 24 * 60 * 60))
    }

    func testDisabledSwitchesProduceNoManagedReminders() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let settings = quietSettings(now: now)

        let plan = BaNotificationPlanner.makePlan(
            settings: settings,
            activities: [],
            pools: [],
            now: now
        )

        XCTAssertTrue(plan.reminders.isEmpty)
    }

    func testPreferenceSnapshotDetectsNewlyEnabledReminder() {
        var previous = BaSettingsEnvelope.defaults()
        previous.serverProfiles[.cn]?.apNotificationsEnabled = false
        var next = previous
        next.serverProfiles[.cn]?.apNotificationsEnabled = true

        XCTAssertTrue(
            BaNotificationPreferenceSnapshot(envelope: next)
                .becameEnabled(from: BaNotificationPreferenceSnapshot(envelope: previous))
        )
    }

    func testLiveActivityCandidatesPreferUrgentResourceAndRunningTimeline() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.apNotificationsEnabled = true
        settings.calendarEndingNotificationsEnabled = true
        settings.apCurrent = 236
        settings.apLimit = 240
        settings.apRegenBaseAt = now
        let activity = BaActivityEntry(
            id: 11,
            title: "综合战术考试",
            kindId: 1,
            kindName: "活动",
            beginAt: now.addingTimeInterval(-60 * 60),
            endAt: now.addingTimeInterval(2 * 60 * 60),
            linkURL: nil,
            imageURL: nil
        )

        let candidates = BaNotificationPlanner.liveActivityCandidates(
            settings: settings,
            activities: [activity],
            pools: [],
            now: now
        )

        XCTAssertEqual(candidates.map(\.kind), [.ap, .activity])
        XCTAssertEqual(candidates.first?.endDate, now.addingTimeInterval(24 * 60))
    }

    func testLiveActivityCandidatesIgnoreDistantTimelines() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.calendarEndingNotificationsEnabled = true
        let activity = BaActivityEntry(
            id: 12,
            title: "长线活动",
            kindId: 1,
            kindName: "活动",
            beginAt: now.addingTimeInterval(-60 * 60),
            endAt: now.addingTimeInterval(13 * 60 * 60),
            linkURL: nil,
            imageURL: nil
        )

        let candidates = BaNotificationPlanner.liveActivityCandidates(
            settings: settings,
            activities: [activity],
            pools: [],
            now: now
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    private func quietSettings(now: Date) -> BaAppSettings {
        var settings = BaAppSettings.defaults(now: now)
        settings.apNotificationsEnabled = false
        settings.cafeApNotificationsEnabled = false
        settings.visitNotificationsEnabled = false
        settings.arenaRefreshNotificationsEnabled = false
        settings.calendarUpcomingNotificationsEnabled = false
        settings.calendarEndingNotificationsEnabled = false
        settings.poolUpcomingNotificationsEnabled = false
        settings.poolEndingNotificationsEnabled = false
        settings.calendarPoolChangeNotificationsEnabled = false
        return settings
    }
}
