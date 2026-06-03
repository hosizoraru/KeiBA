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
        var previousProfile = previous.profile(for: .cn)
        previousProfile.apNotificationsEnabled = false
        previous.setProfile(previousProfile, for: .cn)
        var next = previous
        var nextProfile = next.profile(for: .cn)
        nextProfile.apNotificationsEnabled = true
        next.setProfile(nextProfile, for: .cn)

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

    func testLiveActivitySelectionKeepsSingleHighestPriorityCandidate() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let candidates = [
            BaLiveActivityCandidate(
                id: "activity",
                kind: .activity,
                title: "活动",
                subtitle: "结束倒计时",
                startDate: now,
                endDate: now.addingTimeInterval(30 * 60),
                relevance: 0.82
            ),
            BaLiveActivityCandidate(
                id: "ap",
                kind: .ap,
                title: "AP",
                subtitle: "恢复倒计时",
                startDate: now,
                endDate: now.addingTimeInterval(60 * 60),
                relevance: 0.92
            ),
        ]

        let selected = BaLiveActivitySelection.selectedCandidates(from: candidates)

        XCTAssertEqual(selected.map(\.id), ["ap"])
    }

    func testLiveActivityResourceCandidateCombinesAPAndCafeAP() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.apNotificationsEnabled = true
        settings.cafeApNotificationsEnabled = true
        settings.apCurrent = 236
        settings.apLimit = 240
        settings.apRegenBaseAt = now
        settings.cafeLevel = 10
        settings.cafeApCurrent = 690
        settings.cafeStorageBaseAt = now

        let candidates = BaNotificationPlanner.liveActivityCandidates(
            settings: settings,
            activities: [],
            pools: [],
            now: now
        )

        XCTAssertEqual(candidates.map(\.kind), [.ap])
        XCTAssertEqual(candidates.first?.resources.map(\.kind), [.ap, .cafeAP])
        XCTAssertEqual(candidates.first?.resources.first?.currentValue, 236)
        XCTAssertEqual(candidates.first?.resources.first?.limitValue, 240)
        XCTAssertEqual(candidates.first?.endDate, now.addingTimeInterval(2 * 60 * 60))
    }

    func testLiveActivityCandidatesExposeRunningActivityAndPoolDetails() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var settings = quietSettings(now: now)
        settings.calendarEndingNotificationsEnabled = true
        settings.poolEndingNotificationsEnabled = true
        let activity = BaActivityEntry(
            id: 21,
            title: "综合战术考试",
            kindId: 1,
            kindName: "活动",
            beginAt: now.addingTimeInterval(-60 * 60),
            endAt: now.addingTimeInterval(90 * 60),
            linkURL: nil,
            imageURL: nil
        )
        let pool = BaPoolEntry(
            id: 31,
            name: "限定招募",
            tagId: 6,
            tagName: "招募",
            alias: "",
            startAt: now.addingTimeInterval(-2 * 60 * 60),
            endAt: now.addingTimeInterval(45 * 60),
            linkURL: nil,
            imageURL: nil,
            contentId: nil,
            studentGuideURL: nil
        )

        let candidates = BaNotificationPlanner.liveActivityCandidates(
            settings: settings,
            activities: [activity],
            pools: [pool],
            now: now
        )

        XCTAssertEqual(candidates.map(\.kind), [.pool, .activity])
        XCTAssertEqual(candidates.map(\.title), ["限定招募", "综合战术考试"])
        XCTAssertEqual(candidates.map(\.startDate), [now, now])
        XCTAssertEqual(candidates.map(\.endDate), [pool.endAt, activity.endAt])
        XCTAssertTrue(candidates.allSatisfy(\.resources.isEmpty))
    }

    func testLiveActivitySelectionUsesEarlierEndDateWhenRelevanceMatches() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let candidates = [
            BaLiveActivityCandidate(
                id: "later",
                kind: .pool,
                title: "卡池",
                subtitle: "结束倒计时",
                startDate: now,
                endDate: now.addingTimeInterval(90 * 60),
                relevance: 0.8
            ),
            BaLiveActivityCandidate(
                id: "earlier",
                kind: .activity,
                title: "活动",
                subtitle: "结束倒计时",
                startDate: now,
                endDate: now.addingTimeInterval(20 * 60),
                relevance: 0.8
            ),
        ]

        let selected = BaLiveActivitySelection.selectedCandidates(from: candidates)

        XCTAssertEqual(selected.map(\.id), ["earlier"])
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
