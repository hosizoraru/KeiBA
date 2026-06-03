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
        legacy.friendCode = "glob0001"
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
        XCTAssertEqual(profile.friendCode, "GLOB0001")
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
        cnProfile.friendCode = "CN000001"
        cnProfile.apCurrent = 90
        envelope.setProfile(cnProfile, for: .cn)

        var globalProfile = envelope.profile(for: .global)
        globalProfile.nickname = "Global Sensei"
        globalProfile.friendCode = "GL000001"
        globalProfile.apCurrent = 120
        envelope.setProfile(globalProfile, for: .global)

        var jpProfile = envelope.profile(for: .jp)
        jpProfile.nickname = "JP Sensei"
        jpProfile.friendCode = "JP000001"
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
        XCTAssertEqual(loaded.accounts.map(\.server), [.cn, .global, .jp])
        XCTAssertEqual(loaded.selectedAccount.server, .jp)
    }

    func testMultipleAccountsOnSameServerSwitchOfficeProfile() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var primaryProfile = BaServerProfile.defaults(now: base)
        primaryProfile.nickname = "CN Main"
        primaryProfile.friendCode = "main0001"
        primaryProfile.apCurrent = 42
        primaryProfile.cafeApCurrent = 120

        var secondaryProfile = BaServerProfile.defaults(now: base.addingTimeInterval(60))
        secondaryProfile.nickname = "CN Alt"
        secondaryProfile.friendCode = "alt00002"
        secondaryProfile.apCurrent = 88
        secondaryProfile.cafeApCurrent = 240

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(
                id: "cn-main",
                server: .cn,
                displayName: "国服主号",
                profile: primaryProfile,
                sortOrder: 0
            ),
            BaAccountProfile(
                id: "cn-alt",
                server: .cn,
                displayName: "国服小号",
                profile: secondaryProfile,
                sortOrder: 1
            ),
        ]
        envelope.selectedAccountID = "cn-main"
        envelope.selectedServer = .cn

        let primarySettings = envelope.normalized().flattenedSettings()
        XCTAssertEqual(primarySettings.server, .cn)
        XCTAssertEqual(primarySettings.nickname, "CN Main")
        XCTAssertEqual(primarySettings.friendCode, "MAIN0001")
        XCTAssertEqual(primarySettings.apCurrent, 42)
        XCTAssertEqual(primarySettings.cafeApCurrent, 120)

        envelope.setSelectedAccountID("cn-alt")
        let secondarySettings = envelope.normalized().flattenedSettings()
        XCTAssertEqual(secondarySettings.server, .cn)
        XCTAssertEqual(secondarySettings.nickname, "CN Alt")
        XCTAssertEqual(secondarySettings.friendCode, "ALT00002")
        XCTAssertEqual(secondarySettings.apCurrent, 88)
        XCTAssertEqual(secondarySettings.cafeApCurrent, 240)
    }

    func testCurrentProfileWritesOnlySelectedAccount() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var first = BaServerProfile.defaults(now: base)
        first.nickname = "First"
        first.friendCode = "first001"
        first.apCurrent = 12
        var second = BaServerProfile.defaults(now: base)
        second.nickname = "Second"
        second.friendCode = "second02"
        second.apCurrent = 34

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(id: "cn-first", server: .cn, displayName: "First", profile: first, sortOrder: 0),
            BaAccountProfile(id: "cn-second", server: .cn, displayName: "Second", profile: second, sortOrder: 1),
        ]
        envelope.selectedAccountID = "cn-second"
        envelope.selectedServer = .cn

        var updated = envelope.selectedAccount.profile
        updated.nickname = "Second Updated"
        updated.friendCode = "upd00002"
        updated.apCurrent = 99
        envelope.setProfile(updated, for: .cn)
        let normalized = envelope.normalized()

        XCTAssertEqual(normalized.accounts.first { $0.id == "cn-first" }?.profile.nickname, "First")
        XCTAssertEqual(normalized.accounts.first { $0.id == "cn-first" }?.profile.apCurrent, 12)
        XCTAssertEqual(normalized.accounts.first { $0.id == "cn-second" }?.profile.nickname, "Second Updated")
        XCTAssertEqual(normalized.accounts.first { $0.id == "cn-second" }?.profile.friendCode, "UPD00002")
        XCTAssertEqual(normalized.accounts.first { $0.id == "cn-second" }?.profile.apCurrent, 99)
        XCTAssertEqual(normalized.flattenedSettings().nickname, "Second Updated")
    }

    func testDeletingSelectedAccountFallsBackToNextEnabledAccount() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var cnProfile = BaServerProfile.defaults(now: base)
        cnProfile.nickname = "CN Main"
        var jpProfile = BaServerProfile.defaults(now: base)
        jpProfile.nickname = "JP Main"

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(id: "cn-main", server: .cn, displayName: "CN", profile: cnProfile, isEnabled: false, sortOrder: 0),
            BaAccountProfile(id: "jp-main", server: .jp, displayName: "JP", profile: jpProfile, sortOrder: 1),
        ]
        envelope.selectedAccountID = "cn-main"
        envelope.selectedServer = .cn

        envelope.deleteAccount(id: "cn-main")
        let normalized = envelope.normalized()

        XCTAssertEqual(normalized.accounts.map(\.id), ["jp-main"])
        XCTAssertEqual(normalized.selectedAccountID, "jp-main")
        XCTAssertEqual(normalized.selectedServer, .jp)
        XCTAssertEqual(normalized.flattenedSettings().nickname, "JP Main")
    }

    func testDisablingSelectedAccountFallsBackToNextEnabledAccount() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var firstProfile = BaServerProfile.defaults(now: base)
        firstProfile.nickname = "First"
        var secondProfile = BaServerProfile.defaults(now: base)
        secondProfile.nickname = "Second"
        var thirdProfile = BaServerProfile.defaults(now: base)
        thirdProfile.nickname = "Third"

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(id: "first", server: .cn, displayName: "First", profile: firstProfile, sortOrder: 0),
            BaAccountProfile(id: "second", server: .cn, displayName: "Second", profile: secondProfile, sortOrder: 1),
            BaAccountProfile(id: "third", server: .jp, displayName: "Third", profile: thirdProfile, sortOrder: 2),
        ]
        envelope.selectedAccountID = "second"
        envelope.selectedServer = .cn

        envelope.updateAccount(id: "second") { account in
            account.isEnabled = false
        }
        let normalized = envelope.normalized()

        XCTAssertEqual(normalized.accounts.first { $0.id == "second" }?.isEnabled, false)
        XCTAssertEqual(normalized.selectedAccountID, "first")
        XCTAssertEqual(normalized.selectedServer, .cn)
        XCTAssertEqual(normalized.flattenedSettings().nickname, "First")
    }

    func testDisablingOnlyEnabledAccountKeepsSelectionAvailableForEditing() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var firstProfile = BaServerProfile.defaults(now: base)
        firstProfile.nickname = "First"
        var secondProfile = BaServerProfile.defaults(now: base)
        secondProfile.nickname = "Second"

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(id: "first", server: .cn, displayName: "First", profile: firstProfile, isEnabled: false, sortOrder: 0),
            BaAccountProfile(id: "second", server: .jp, displayName: "Second", profile: secondProfile, sortOrder: 1),
        ]
        envelope.selectedAccountID = "second"
        envelope.selectedServer = .jp

        envelope.updateAccount(id: "second") { account in
            account.isEnabled = false
        }
        let normalized = envelope.normalized()

        XCTAssertEqual(normalized.accounts.filter(\.isEnabled).count, 0)
        XCTAssertEqual(normalized.selectedAccountID, "second")
        XCTAssertEqual(normalized.selectedServer, .jp)
        XCTAssertEqual(normalized.flattenedSettings().nickname, "Second")
    }

    func testNormalizationRepairsDisabledSelectedAccountWhenEnabledFallbackExists() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var firstProfile = BaServerProfile.defaults(now: base)
        firstProfile.nickname = "First"
        var disabledProfile = BaServerProfile.defaults(now: base)
        disabledProfile.nickname = "Disabled"
        var thirdProfile = BaServerProfile.defaults(now: base)
        thirdProfile.nickname = "Third"

        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.accounts = [
            BaAccountProfile(id: "first", server: .cn, displayName: "First", profile: firstProfile, sortOrder: 0),
            BaAccountProfile(id: "disabled", server: .cn, displayName: "Disabled", profile: disabledProfile, isEnabled: false, sortOrder: 1),
            BaAccountProfile(id: "third", server: .jp, displayName: "Third", profile: thirdProfile, sortOrder: 2),
        ]
        envelope.selectedAccountID = "disabled"
        envelope.selectedServer = .cn

        let normalized = envelope.normalized()

        XCTAssertEqual(normalized.selectedAccountID, "first")
        XCTAssertEqual(normalized.selectedServer, .cn)
        XCTAssertEqual(normalized.flattenedSettings().nickname, "First")
    }

    func testFriendCodeKeepsEightUppercaseLettersOrDigits() {
        XCTAssertEqual(BaFriendCodeFormat.sanitizedDraft("ab-12 cd34xyz"), "AB12CD34")
        XCTAssertEqual(BaFriendCodeFormat.normalized("ke1os26x"), "KE1OS26X")
        XCTAssertEqual(BaFriendCodeFormat.normalized("short7"), BaFriendCodeFormat.fallback)
    }

    func testAppLanguageDefaultsPersistAndLookupLocalizedStrings() throws {
        let defaults = try makeIsolatedDefaults()
        var envelope = BaSettingsEnvelope.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(envelope.globalSettings.appLanguage, .system)
        XCTAssertEqual(envelope.globalSettings.appAppearance, .system)
        XCTAssertEqual(envelope.globalSettings.appIcon, .modern)
        XCTAssertEqual(BaL10n.string("ba.settings.language.title", language: .japanese), "アプリの言語")
        XCTAssertEqual(BaL10n.string("ba.settings.language.title", language: .simplifiedChinese), "应用语言")
        XCTAssertEqual(BaL10n.string("ba.settings.appearance.title", language: .japanese), "外観")
        XCTAssertEqual(BaL10n.string("ba.settings.appearance.title", language: .simplifiedChinese), "外观")
        XCTAssertEqual(BaL10n.string("ba.settings.appIcon.title", language: .japanese), "アプリアイコン")
        XCTAssertEqual(BaL10n.string("ba.settings.appIcon.classic", language: .simplifiedChinese), "经典")

        envelope.globalSettings.appLanguage = .japanese
        envelope.globalSettings.appAppearance = .dark
        envelope.globalSettings.appIcon = .classic
        let store = BaSettingsStore(defaults: defaults)
        store.saveEnvelope(envelope)

        XCTAssertEqual(store.loadEnvelope().globalSettings.appLanguage, .japanese)
        XCTAssertEqual(store.loadEnvelope().globalSettings.appAppearance, .dark)
        XCTAssertEqual(store.loadEnvelope().globalSettings.appIcon, .classic)
    }

    func testOfficeTerminologyUsesServerSpecificSimplifiedChineseNames() {
        var settings = BaAppSettings.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        settings.appLanguage = .simplifiedChinese

        settings.server = .cn
        XCTAssertEqual(BaOfficeTerminology.overviewTitle(for: settings), "沙勒办公室总览")

        settings.server = .global
        XCTAssertEqual(BaOfficeTerminology.overviewTitle(for: settings), "夏萊行政室总览")

        settings.server = .jp
        XCTAssertEqual(BaOfficeTerminology.overviewTitle(for: settings), "夏莱办公室总览")
    }

    func testOfficeTerminologyKeepsGenericTitleOutsideSimplifiedChinese() {
        var settings = BaAppSettings.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        settings.server = .global

        settings.appLanguage = .english
        XCTAssertEqual(BaOfficeTerminology.overviewTitle(for: settings), "Schale Office Overview")

        settings.appLanguage = .japanese
        XCTAssertEqual(BaOfficeTerminology.overviewTitle(for: settings), "シャーレオフィス概要")
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

        let snapshot = BaOfficeRepository().snapshot(
            settings: settings,
            now: now,
            localTimeZone: localTimeZone
        )

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
            summary.activity.remainingText,
            String(format: String(localized: "ba.timeline.remaining.endsIn.format"), "2m")
        )
        XCTAssertEqual(summary.activity.endText, BaDisplayFormatters.dateTime(base.addingTimeInterval(90)))
    }

    func testOverviewTimelineSummaryShowsAllEntriesWithEarliestEndTime() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let earliestEnd = base.addingTimeInterval(3_600)
        let laterEnd = base.addingTimeInterval(7_200)
        let activities = [
            BaActivityEntry(
                id: 1,
                title: "Later",
                kindId: 1,
                kindName: "Event",
                beginAt: base.addingTimeInterval(-60),
                endAt: laterEnd,
                linkURL: nil,
                imageURL: nil
            ),
            BaActivityEntry(
                id: 2,
                title: "Raid",
                kindId: 1,
                kindName: "Event",
                beginAt: base.addingTimeInterval(-60),
                endAt: earliestEnd,
                linkURL: nil,
                imageURL: nil
            ),
            BaActivityEntry(
                id: 3,
                title: "Login",
                kindId: 1,
                kindName: "Event",
                beginAt: base.addingTimeInterval(-120),
                endAt: earliestEnd,
                linkURL: nil,
                imageURL: nil
            )
        ]
        let pools = [
            BaPoolEntry(
                id: 1,
                name: "Pickup A",
                tagId: 1,
                tagName: "Pool",
                alias: "",
                startAt: base.addingTimeInterval(-60),
                endAt: laterEnd,
                linkURL: nil,
                imageURL: nil,
                contentId: nil,
                studentGuideURL: nil
            ),
            BaPoolEntry(
                id: 2,
                name: "Pickup B",
                tagId: 1,
                tagName: "Pool",
                alias: "",
                startAt: base.addingTimeInterval(-60),
                endAt: earliestEnd,
                linkURL: nil,
                imageURL: nil,
                contentId: nil,
                studentGuideURL: nil
            )
        ]

        let summary = BaOverviewTimelineSummary(activities: activities, pools: pools, now: base)

        XCTAssertEqual(summary.activity.titles, ["Raid", "Login"])
        XCTAssertEqual(summary.activity.endAt, earliestEnd)
        XCTAssertEqual(summary.activity.primaryTitle, "Raid")
        XCTAssertEqual(
            summary.activity.extraTitleText,
            String.localizedStringWithFormat(
                String(localized: "ba.overview.timeline.moreItems.format"),
                1
            )
        )
        XCTAssertEqual(summary.pool.titles, ["Pickup B"])
        XCTAssertEqual(summary.pool.endAt, earliestEnd)
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
        envelope.globalSettings.dutyStudent = BaDutyStudent(
            contentId: 10_001,
            name: "Shiroko",
            avatarURL: URL(string: "https://cdnimg.gamekee.com/student/shiroko.png")
        )
        envelope.globalSettings.favoriteContentIDs = [647_097]
        envelope.globalSettings.favoriteCatalogEntries = [
            makeOverviewCatalogEntry(
                entryId: 174_603,
                pid: BaCatalogCategory.npcSatellite.gameKeePID,
                contentId: 647_097,
                name: "爱丽丝(冬装)",
                category: .npcSatellite
            ),
        ]
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
        XCTAssertEqual(loaded.globalSettings.dutyStudent?.contentId, 10_001)
        XCTAssertEqual(loaded.globalSettings.dutyStudent?.name, "Shiroko")
        XCTAssertEqual(loaded.globalSettings.dutyStudent?.avatarURL?.absoluteString, "https://cdnimg.gamekee.com/student/shiroko.png")
        XCTAssertEqual(loaded.globalSettings.favoriteContentIDs, [647_097])
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.first?.contentId, 647_097)
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.first?.category, .npcSatellite)
        XCTAssertEqual(loaded.profile(for: .cn).apNotifyThreshold, 210)
        XCTAssertEqual(loaded.profile(for: .cn).cafeApNotifyThreshold, 330)
    }

    func testFavoriteNPCEntryPersistsAsCatalogSnapshotAndMigratesLegacyEntryID() throws {
        let defaults = try makeIsolatedDefaults()
        let canonical = makeOverviewCatalogEntry(
            entryId: 174_603,
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            contentId: 647_097,
            name: "爱丽丝(冬装)",
            category: .npcSatellite
        )
        let staleEntry = makeOverviewCatalogEntry(
            entryId: 174_603,
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            contentId: 174_603,
            name: "爱丽丝(冬装)",
            category: .npcSatellite
        )
        let catalogBundle = BaGuideCatalogBundle(
            entries: [canonical],
            syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let selection = BaFavoriteCatalogResolver.toggledSelection(
            for: staleEntry,
            catalogEntries: catalogBundle.entries,
            storedContentIDs: [],
            storedSnapshots: []
        )
        var envelope = BaSettingsEnvelope.defaults(now: Date(timeIntervalSince1970: 1_700_000_000))
        envelope.globalSettings.favoriteContentIDs = selection.contentIDs
        envelope.globalSettings.favoriteCatalogEntries = selection.catalogEntries
        BaSettingsStore(defaults: defaults).saveEnvelope(envelope)

        let loaded = BaSettingsStore(defaults: defaults).loadEnvelope()
        let favoriteEntries = BaFavoriteCatalogResolver.favoriteCatalogEntries(
            from: catalogBundle,
            contentIDs: loaded.globalSettings.favoriteContentIDs,
            snapshots: loaded.globalSettings.favoriteCatalogEntries
        )

        XCTAssertEqual(loaded.globalSettings.favoriteContentIDs, [647_097])
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.first?.contentId, 647_097)
        XCTAssertEqual(favoriteEntries.map(\.contentId), [647_097])
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.first?.entryId, 174_603)
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.first?.category, .npcSatellite)

        var legacySettings = BaGlobalSettings.defaults()
        legacySettings.favoriteContentIDs = [Int64(staleEntry.entryId)]
        legacySettings.favoriteCatalogEntries = [staleEntry]
        let reconciledSettings = BaFavoriteCatalogResolver.reconciledSettings(legacySettings, with: catalogBundle)
        XCTAssertEqual(reconciledSettings.favoriteContentIDs, [647_097])
        XCTAssertEqual(reconciledSettings.favoriteCatalogEntries.first?.contentId, 647_097)
    }

    @MainActor
    func testNPCSatelliteEntryCanBecomeDutyStudentWithResolvedPortrait() async throws {
        let defaults = try makeIsolatedDefaults()
        let model = makeOverviewAppModel(defaults: defaults)
        let fallbackURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/student/alice-icon.png"))
        let portraitURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/student/alice-winter-portrait.png"))
        let entry = makeOverviewCatalogEntry(
            entryId: 174_603,
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            contentId: 647_097,
            name: "爱丽丝（冬装）",
            category: .npcSatellite,
            iconURL: fallbackURL
        )
        model.studentDetailStates[entry.contentId] = BaLoadableState(
            value: BaStudentGuideInfo(
                contentId: entry.contentId,
                sourceURL: entry.detailURL,
                title: "爱丽丝（冬装）",
                subtitle: "GameKee",
                summary: "",
                imageURL: portraitURL,
                stats: [],
                profileRows: [],
                skillRows: [],
                voiceRows: [],
                galleryItems: [],
                growthRows: [],
                simulateRows: [],
                contentSource: "fixture",
                syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        )

        XCTAssertTrue(model.canSetDutyStudent(entry))

        await model.toggleDutyStudent(entry)

        XCTAssertEqual(model.settings.dutyStudent?.contentId, entry.contentId)
        XCTAssertEqual(model.settings.dutyStudent?.name, "爱丽丝（冬装）")
        XCTAssertEqual(model.settings.dutyStudent?.avatarURL, portraitURL)
        XCTAssertTrue(model.isDutyStudent(entry))

        await model.toggleDutyStudent(entry)

        XCTAssertNil(model.settings.dutyStudent)
    }

    func testRefreshIntervalControlsCacheStaleness() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(BaRefreshInterval.threeHours.timeInterval, 10_800)
        XCTAssertFalse(BaRefreshInterval.threeHours.shouldRefresh(lastSyncAt: now.addingTimeInterval(-10_799), now: now))
        XCTAssertTrue(BaRefreshInterval.threeHours.shouldRefresh(lastSyncAt: now.addingTimeInterval(-10_800), now: now))
        XCTAssertTrue(BaRefreshInterval.threeHours.shouldRefresh(lastSyncAt: nil, now: now))
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "KeiBAOSTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @MainActor
    private func makeOverviewAppModel(defaults: UserDefaults) -> BaAppModel {
        let client = GameKeeClient()
        let cacheStore = BaCacheStore()
        return BaAppModel(
            settingsStore: BaSettingsStore(defaults: defaults),
            cacheStore: cacheStore,
            imageCache: BaImageCache(client: client),
            activityPoolRepository: BaActivityPoolRepository(client: client),
            catalogRepository: BaGuideCatalogRepository(client: client),
            catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator(
                cacheStore: cacheStore,
                studentRepository: BaStudentGuideRepository(client: client)
            ),
            studentRepository: BaStudentGuideRepository(client: client),
            officeRepository: BaOfficeRepository()
        )
    }

    private func makeOverviewCatalogEntry(
        entryId: Int,
        pid: Int,
        contentId: Int64,
        name: String,
        category: BaCatalogCategory,
        iconURL: URL? = nil
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: entryId,
            pid: pid,
            contentId: contentId,
            name: name,
            alias: "",
            aliasDisplay: "",
            iconURL: iconURL,
            type: 1,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
            category: category
        )
    }
}
