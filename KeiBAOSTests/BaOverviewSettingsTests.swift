//
//  BaOverviewSettingsTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/15.
//

@testable import KeiBAOS
import XCTest

final class BaOverviewSettingsTests: XCTestCase {
    func testSettingsStoreMigratesV1IntoSelectedServerProfile() throws {
        let defaults = try makeIsolatedDefaults()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var legacy = BaAppSettings.defaults(now: base)
        legacy.server = .global
        legacy.nickname = "Global Sensei"
        legacy.friendCode = "global-001"
        legacy.apCurrent = 177
        legacy.apLimit = 231
        legacy.cafeLevel = 8
        legacy.cafeApCurrent = 233
        legacy.lastInviteTicketAt = base.addingTimeInterval(-7200)
        legacy.lastInviteTicket1At = nil
        legacy.lastInviteTicket2At = nil
        legacy.showEndedActivities = false
        legacy.showPreviewImages = false
        legacy.refreshInterval = .sixHours
        legacy.apNotifyThreshold = 180
        legacy.cafeApNotifyThreshold = 220
        let legacyData = try JSONEncoder.ba.encode(legacy)
        defaults.set(legacyData, forKey: "ba.app.settings.v1")

        let store = BaSettingsStore(defaults: defaults)
        let envelope = store.loadEnvelope()
        let profile = envelope.profile(for: .global)

        XCTAssertEqual(envelope.schemaVersion, BaSettingsEnvelope.currentSchemaVersion)
        XCTAssertEqual(envelope.selectedServer, .global)
        XCTAssertEqual(profile.nickname, "Global Sensei")
        XCTAssertEqual(profile.friendCode, "GLOBAL-001")
        XCTAssertEqual(profile.apCurrent, 177)
        XCTAssertEqual(profile.apLimit, 231)
        XCTAssertEqual(profile.cafeLevel, 8)
        XCTAssertEqual(profile.cafeApCurrent, 233)
        XCTAssertEqual(profile.lastInviteTicket1At, legacy.lastInviteTicketAt)
        XCTAssertNil(profile.lastInviteTicket2At)
        XCTAssertFalse(envelope.globalSettings.showEndedActivities)
        XCTAssertFalse(envelope.globalSettings.showPreviewImages)
        XCTAssertEqual(envelope.globalSettings.refreshInterval, .sixHours)
        XCTAssertEqual(profile.apNotifyThreshold, 180)
        XCTAssertEqual(profile.cafeApNotifyThreshold, 220)
        XCTAssertNotNil(defaults.data(forKey: "ba.app.settings.v2"))
    }

    func testServerProfilesPersistIndependentlyWhenIdentityIsPerServer() throws {
        let defaults = try makeIsolatedDefaults()
        var envelope = BaSettingsEnvelope.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        envelope.globalSettings.identityIndependentByServer = true
        envelope.selectedServer = .jp

        var cnProfile = envelope.profile(for: .cn)
        cnProfile.nickname = "CN Sensei"
        cnProfile.friendCode = "CN-001"
        cnProfile.apCurrent = 90
        envelope.setProfile(cnProfile, for: .cn)

        var globalProfile = envelope.profile(for: .global)
        globalProfile.nickname = "Global Sensei"
        globalProfile.friendCode = "GL-001"
        globalProfile.apCurrent = 120
        envelope.setProfile(globalProfile, for: .global)

        var jpProfile = envelope.profile(for: .jp)
        jpProfile.nickname = "JP Sensei"
        jpProfile.friendCode = "JP-001"
        jpProfile.apCurrent = 150
        envelope.setProfile(jpProfile, for: .jp)

        let store = BaSettingsStore(defaults: defaults)
        store.saveEnvelope(envelope)
        let loaded = store.loadEnvelope()

        XCTAssertEqual(loaded.selectedServer, .jp)
        XCTAssertEqual(loaded.profile(for: .cn).nickname, "CN Sensei")
        XCTAssertEqual(loaded.profile(for: .global).nickname, "Global Sensei")
        XCTAssertEqual(loaded.profile(for: .jp).nickname, "JP Sensei")
        XCTAssertEqual(loaded.profile(for: .cn).apCurrent, 90)
        XCTAssertEqual(loaded.profile(for: .global).apCurrent, 120)
        XCTAssertEqual(loaded.profile(for: .jp).apCurrent, 150)
    }

    func testCafeAPStorageUsesSingleSharedCafeBucket() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var profile = BaServerProfile.defaults(now: base)
        profile.cafeLevel = 10
        profile.cafeApCurrent = 100
        profile.cafeStorageBaseAt = base

        let now = base.addingTimeInterval(2.5 * 60 * 60)
        let expected = 100 + 2 * BaTimeMath.cafeHourlyGain(level: 10)

        XCTAssertEqual(BaTimeMath.currentCafeAP(profile: profile, now: now), expected, accuracy: 0.001)
    }

    func testOverviewAPSnapshotRecoversWithTime() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var settings = BaAppSettings.defaults(now: base)
        settings.apCurrent = 10
        settings.apLimit = 240
        settings.apRegenBaseAt = base

        let snapshot = BaOfficeRepository().snapshot(
            settings: settings,
            now: base.addingTimeInterval(BaTimeMath.apRegenInterval * 2)
        )

        XCTAssertEqual(snapshot.apCurrent, "12")
        XCTAssertEqual(
            snapshot.apCurrentLimit,
            String(format: String(localized: "ba.office.ap.currentLimit.format"), "12", "240")
        )
        XCTAssertEqual(
            snapshot.apRemaining,
            String(format: String(localized: "ba.office.ap.remaining.format"), "228")
        )
    }

    func testAPAboveLimitStaysVisibleAndPausesNaturalRecovery() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var settings = BaAppSettings.defaults(now: base)
        settings.apCurrent = 300
        settings.apLimit = 240
        settings.apRegenBaseAt = base

        let snapshot = BaOfficeRepository().snapshot(
            settings: settings,
            now: base.addingTimeInterval(BaTimeMath.apRegenInterval * 2)
        )

        XCTAssertEqual(snapshot.apCurrent, "300")
        XCTAssertEqual(snapshot.apNext, String(localized: "ba.office.ap.paused.value"))
        XCTAssertEqual(snapshot.apFullRemain, String(localized: "ba.office.ap.full.ready"))
    }

    func testOverviewMinuteDurationsDropSecondsOutsideAPNext() {
        XCTAssertEqual(BaDisplayFormatters.compactDuration(90, includingSeconds: true), "1m 30s")
        XCTAssertEqual(BaDisplayFormatters.compactDuration(90, includingSeconds: false), "2m")
        XCTAssertEqual(BaDisplayFormatters.compactDuration(3661, includingSeconds: false), "1h 2m")
    }

    func testServerRefreshTimesRenderInLocalTimeZone() throws {
        let localTimeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let reference = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertEqual(
            BaTimeMath.localCafeStudentRefreshTimes(
                server: .jp,
                reference: reference,
                localTimeZone: localTimeZone
            ),
            "03:00 / 15:00"
        )
        XCTAssertEqual(
            BaTimeMath.localArenaRefreshTime(
                server: .global,
                reference: reference,
                localTimeZone: localTimeZone
            ),
            "13:00"
        )
        XCTAssertEqual(
            BaTimeMath.localCafeStudentRefreshTimes(
                server: .cn,
                reference: reference,
                localTimeZone: localTimeZone
            ),
            "04:00 / 16:00"
        )

        let slots = BaTimeMath.localCafeStudentRefreshSlots(
            server: .jp,
            reference: reference,
            localTimeZone: localTimeZone
        )
        XCTAssertEqual(slots.map(\.localClockTime), ["03:00", "15:00"])
        XCTAssertEqual(slots.map(\.id), [1, 2])
    }

    func testOverviewCafeSnapshotSplitsBothStudentVisitSlots() throws {
        let localTimeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = localTimeZone
        let now = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 2, minute: 57))
        )
        var settings = BaAppSettings.defaults(now: now)
        settings.server = .jp

        let snapshot = BaOfficeRepository().snapshot(settings: settings, now: now)

        XCTAssertEqual(snapshot.cafeVisitSlots.count, 2)
        XCTAssertEqual(
            snapshot.cafeVisitSlots[0].title,
            String(format: String(localized: "ba.cafe.metric.visit.index.format"), "1")
        )
        XCTAssertEqual(
            snapshot.cafeVisitSlots[0].detail,
            String(format: String(localized: "ba.cafe.metric.visit.detail.format"), "03:00")
        )
        XCTAssertEqual(
            snapshot.cafeVisitSlots[1].detail,
            String(format: String(localized: "ba.cafe.metric.visit.detail.format"), "15:00")
        )
        XCTAssertEqual(snapshot.cafeVisitSlots[0].value, "3m")
    }

    func testOverviewSyncTimeDropsSeconds() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(BaDisplayFormatters.syncTime(date, includingSeconds: false).split(separator: ":").count, 2)
        XCTAssertEqual(BaDisplayFormatters.syncTime(date, includingSeconds: true).split(separator: ":").count, 3)
    }

    func testOverviewTimelineSummaryDropsSeconds() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let activity = BaActivityEntry(
            id: 1,
            title: "Event",
            kindId: 1,
            kindName: "Event",
            beginAt: base.addingTimeInterval(-60),
            endAt: base.addingTimeInterval(90),
            linkURL: nil,
            imageURL: nil
        )
        let summary = BaOverviewTimelineSummary(
            activities: [activity],
            pools: [],
            now: base
        )

        XCTAssertEqual(
            summary.activityTime,
            String(format: String(localized: "ba.timeline.remaining.endsIn.format"), "2m")
        )
    }

    func testInviteTicketsHaveIndependentTwentyHourCooldowns() throws {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var settings = BaAppSettings.defaults(now: base)
        settings.lastInviteTicket1At = base.addingTimeInterval(-10 * 60 * 60)
        settings.lastInviteTicket2At = base.addingTimeInterval(-21 * 60 * 60)

        let snapshot = BaOfficeRepository().snapshot(settings: settings, now: base)
        let ticket1 = try XCTUnwrap(snapshot.cafeActions.first { $0.kind == .inviteTicket1 })
        let ticket2 = try XCTUnwrap(snapshot.cafeActions.first { $0.kind == .inviteTicket2 })

        XCTAssertFalse(ticket1.isReady)
        XCTAssertTrue(ticket2.isReady)
        XCTAssertEqual(
            BaTimeMath.nextInviteAvailable(lastInviteAt: settings.lastInviteTicket1At),
            settings.lastInviteTicket1At?.addingTimeInterval(BaTimeMath.inviteCooldown)
        )
    }

    func testHeadpatCooldownRespectsCafeStudentRefreshBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BaServer.cn.timeZone
        let lastHeadpat = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 3, minute: 30))
        )
        let expectedRefresh = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 4))
        )

        XCTAssertEqual(
            BaTimeMath.nextHeadpatAvailable(lastHeadpatAt: lastHeadpat, server: .cn),
            expectedRefresh
        )
    }

    func testHeadpatCooldownUsesSelectedServerStudentRefreshBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let lastHeadpat = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 2, minute: 30))
        )
        let expectedRefresh = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 15, hour: 3))
        )

        XCTAssertEqual(
            BaTimeMath.nextHeadpatAvailable(lastHeadpatAt: lastHeadpat, server: .jp),
            expectedRefresh
        )
    }

    func testOverviewPreferencesSurviveSettingsStoreRoundTrip() throws {
        let defaults = try makeIsolatedDefaults()
        var envelope = BaSettingsEnvelope.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        envelope.globalSettings.showEndedActivities = false
        envelope.globalSettings.showEndedPools = false
        envelope.globalSettings.showPreviewImages = false
        envelope.globalSettings.refreshInterval = .twelveHours
        envelope.globalSettings.calendarUpcomingNotificationsEnabled = false
        envelope.globalSettings.poolEndingNotificationsEnabled = true
        var profile = envelope.profile(for: .cn)
        profile.apNotifyThreshold = 210
        profile.cafeApNotifyThreshold = 330
        envelope.setProfile(profile, for: .cn)

        let store = BaSettingsStore(defaults: defaults)
        store.saveEnvelope(envelope)
        let loaded = store.loadEnvelope()

        XCTAssertFalse(loaded.globalSettings.showEndedActivities)
        XCTAssertFalse(loaded.globalSettings.showEndedPools)
        XCTAssertFalse(loaded.globalSettings.showPreviewImages)
        XCTAssertEqual(loaded.globalSettings.refreshInterval, .twelveHours)
        XCTAssertFalse(loaded.globalSettings.calendarUpcomingNotificationsEnabled)
        XCTAssertTrue(loaded.globalSettings.poolEndingNotificationsEnabled)
        XCTAssertEqual(loaded.profile(for: .cn).apNotifyThreshold, 210)
        XCTAssertEqual(loaded.profile(for: .cn).cafeApNotifyThreshold, 330)
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "KeiBAOSTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
