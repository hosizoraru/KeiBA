//
//  BaNotificationAppModelTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

import Foundation
@testable import KeiBAOS
import XCTest

@MainActor
final class BaNotificationAppModelTests: XCTestCase {
    func testProfileNotificationToggleRequestsAuthorizationAndRefreshesSchedule() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            var profile = envelope.profile(for: .cn)
            profile.apNotificationsEnabled = false
            envelope.setProfile(profile, for: .cn)
        }

        model.updateCurrentProfile { profile in
            profile.apNotificationsEnabled = true
        }

        await assertCoordinatorCallCount(1, coordinator: coordinator)
        XCTAssertTrue(coordinator.calls[0].requestAuthorizationIfNeeded)
        XCTAssertTrue(coordinator.calls[0].settings.apNotificationsEnabled)
    }

    func testGlobalNotificationToggleRequestsAuthorizationAndRefreshesSchedule() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            envelope.globalSettings.poolEndingNotificationsEnabled = false
        }

        model.updateGlobalSettings { settings in
            settings.poolEndingNotificationsEnabled = true
        }

        await assertCoordinatorCallCount(1, coordinator: coordinator)
        XCTAssertTrue(coordinator.calls[0].requestAuthorizationIfNeeded)
        XCTAssertTrue(coordinator.calls[0].settings.poolEndingNotificationsEnabled)
    }

    func testNonActiveAccountNotificationToggleRefreshesScheduleWithFullEnvelope() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            let base = Date(timeIntervalSince1970: 1_800_000_000)
            var activeProfile = BaServerProfile.defaults(now: base)
            activeProfile.apNotificationsEnabled = false
            var inactiveProfile = BaServerProfile.defaults(now: base)
            inactiveProfile.nickname = "JP Sensei"
            inactiveProfile.friendCode = "jp000001"
            inactiveProfile.apNotificationsEnabled = false
            envelope.accounts = [
                BaAccountProfile(id: "active", server: .cn, displayName: "Active", profile: activeProfile, sortOrder: 0),
                BaAccountProfile(id: "inactive", server: .jp, displayName: "Inactive", profile: inactiveProfile, sortOrder: 1),
            ]
            envelope.selectedAccountID = "active"
            envelope.selectedServer = .cn
        }

        let previousEnvelope = model.envelope
        model.envelope.updateAccount(id: "inactive") { account in
            account.profile.apNotificationsEnabled = true
        }
        model.persistEnvelope(previousServer: model.settings.server, previousEnvelope: previousEnvelope)

        await assertCoordinatorCallCount(1, coordinator: coordinator)
        let envelope = try XCTUnwrap(coordinator.calls[0].envelope)
        XCTAssertTrue(coordinator.calls[0].requestAuthorizationIfNeeded)
        XCTAssertEqual(envelope.accounts.map(\.id), ["active", "inactive"])
        XCTAssertTrue(envelope.accounts.first { $0.id == "inactive" }?.profile.apNotificationsEnabled ?? false)
    }

    func testAccountReminderUpdatePersistsOnlyTargetAccountAndRefreshesSchedule() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            let base = Date(timeIntervalSince1970: 1_800_000_000)
            var activeProfile = BaServerProfile.defaults(now: base)
            activeProfile.nickname = "CN Sensei"
            activeProfile.friendCode = "cn000001"
            activeProfile.apNotificationsEnabled = false
            activeProfile.cafeApNotificationsEnabled = false
            activeProfile.visitNotificationsEnabled = false
            activeProfile.arenaRefreshNotificationsEnabled = false
            activeProfile.apNotifyThreshold = 90
            activeProfile.cafeApNotifyThreshold = 100
            var inactiveProfile = BaServerProfile.defaults(now: base)
            inactiveProfile.nickname = "JP Sensei"
            inactiveProfile.friendCode = "jp000001"
            inactiveProfile.apNotificationsEnabled = false
            inactiveProfile.cafeApNotificationsEnabled = false
            inactiveProfile.visitNotificationsEnabled = false
            inactiveProfile.arenaRefreshNotificationsEnabled = false
            inactiveProfile.apNotifyThreshold = 110
            inactiveProfile.cafeApNotifyThreshold = 120
            envelope.accounts = [
                BaAccountProfile(id: "active", server: .cn, displayName: "Active", profile: activeProfile, sortOrder: 0),
                BaAccountProfile(id: "inactive", server: .jp, displayName: "Inactive", profile: inactiveProfile, sortOrder: 1),
            ]
            envelope.selectedAccountID = "active"
            envelope.selectedServer = .cn
        }

        model.updateAccount(
            id: "inactive",
            displayName: "JP Alt",
            server: .jp,
            nickname: "JP Alt Sensei",
            friendCode: "JP000002",
            isEnabled: true,
            apNotificationsEnabled: true,
            cafeApNotificationsEnabled: true,
            visitNotificationsEnabled: true,
            arenaRefreshNotificationsEnabled: true,
            apNotifyThreshold: BaTimeMath.apMax + 50,
            cafeApNotifyThreshold: -10
        )

        await assertCoordinatorCallCount(1, coordinator: coordinator)
        let active = try XCTUnwrap(model.envelope.accounts.first { $0.id == "active" })
        let inactive = try XCTUnwrap(model.envelope.accounts.first { $0.id == "inactive" })
        XCTAssertEqual(active.profile.nickname, "CN Sensei")
        XCTAssertFalse(active.profile.apNotificationsEnabled)
        XCTAssertFalse(active.profile.cafeApNotificationsEnabled)
        XCTAssertFalse(active.profile.visitNotificationsEnabled)
        XCTAssertFalse(active.profile.arenaRefreshNotificationsEnabled)
        XCTAssertEqual(active.profile.apNotifyThreshold, 90)
        XCTAssertEqual(active.profile.cafeApNotifyThreshold, 100)
        XCTAssertEqual(inactive.displayName, "JP Alt")
        XCTAssertEqual(inactive.profile.nickname, "JP Alt Sensei")
        XCTAssertTrue(inactive.profile.apNotificationsEnabled)
        XCTAssertTrue(inactive.profile.cafeApNotificationsEnabled)
        XCTAssertTrue(inactive.profile.visitNotificationsEnabled)
        XCTAssertTrue(inactive.profile.arenaRefreshNotificationsEnabled)
        XCTAssertEqual(inactive.profile.apNotifyThreshold, BaTimeMath.apMax)
        XCTAssertEqual(inactive.profile.cafeApNotifyThreshold, 0)
        XCTAssertTrue(coordinator.calls[0].requestAuthorizationIfNeeded)
        let synchronizedEnvelope = try XCTUnwrap(coordinator.calls[0].envelope)
        XCTAssertEqual(synchronizedEnvelope.accounts.first { $0.id == "inactive" }?.profile.apNotifyThreshold, BaTimeMath.apMax)
    }

    func testAddedAccountStoresInitialReminderPreferences() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { _ in }

        model.addAccount(
            displayName: "CN Alt",
            server: .cn,
            nickname: "Alt Sensei",
            friendCode: "ALT00001",
            apNotificationsEnabled: false,
            cafeApNotificationsEnabled: true,
            visitNotificationsEnabled: true,
            arenaRefreshNotificationsEnabled: false,
            apNotifyThreshold: BaTimeMath.apMax + 1,
            cafeApNotifyThreshold: -1
        )

        let account = try XCTUnwrap(model.envelope.accounts.first { $0.displayName == "CN Alt" })
        XCTAssertEqual(model.currentAccount.id, account.id)
        XCTAssertFalse(account.profile.apNotificationsEnabled)
        XCTAssertTrue(account.profile.cafeApNotificationsEnabled)
        XCTAssertTrue(account.profile.visitNotificationsEnabled)
        XCTAssertFalse(account.profile.arenaRefreshNotificationsEnabled)
        XCTAssertEqual(account.profile.apNotifyThreshold, BaTimeMath.apMax)
        XCTAssertEqual(account.profile.cafeApNotifyThreshold, 0)
    }

    func testDisabledAccountCannotBeSelectedWhenEnabledAccountsExist() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            let base = Date(timeIntervalSince1970: 1_800_000_000)
            var activeProfile = BaServerProfile.defaults(now: base)
            activeProfile.nickname = "Active"
            var disabledProfile = BaServerProfile.defaults(now: base)
            disabledProfile.nickname = "Disabled"
            envelope.accounts = [
                BaAccountProfile(id: "active", server: .cn, displayName: "Active", profile: activeProfile, sortOrder: 0),
                BaAccountProfile(id: "disabled", server: .jp, displayName: "Disabled", profile: disabledProfile, isEnabled: false, sortOrder: 1),
            ]
            envelope.selectedAccountID = "active"
            envelope.selectedServer = .cn
        }

        XCTAssertEqual(model.switchableAccounts.map(\.id), ["active"])

        model.selectAccount("disabled")

        XCTAssertEqual(model.currentAccount.id, "active")
        XCTAssertEqual(model.settings.server, .cn)
        await assertNoCoordinatorCalls(coordinator: coordinator)
    }

    func testIdentityTextUpdateSkipsNotificationRefresh() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { _ in }

        model.updateCurrentProfile { profile in
            profile.nickname = "Atri"
        }

        await assertNoCoordinatorCalls(coordinator: coordinator)
        XCTAssertEqual(model.currentProfile.nickname, "Atri")
    }

    func testNoOpProfileUpdateSkipsPersistenceSideEffects() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { _ in }
        let profile = model.currentProfile

        model.updateCurrentProfile { next in
            next = profile
        }

        await assertNoCoordinatorCalls(coordinator: coordinator)
    }

    func testExplicitAuthorizationRefreshRequestsOnlyWhenAnyReminderIsEnabled() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            var profile = envelope.profile(for: .cn)
            profile.apNotificationsEnabled = false
            profile.cafeApNotificationsEnabled = false
            profile.visitNotificationsEnabled = false
            profile.arenaRefreshNotificationsEnabled = false
            envelope.setProfile(profile, for: .cn)
            envelope.globalSettings.calendarUpcomingNotificationsEnabled = false
            envelope.globalSettings.calendarEndingNotificationsEnabled = false
            envelope.globalSettings.poolUpcomingNotificationsEnabled = false
            envelope.globalSettings.poolEndingNotificationsEnabled = false
            envelope.globalSettings.calendarPoolChangeNotificationsEnabled = false
        }

        await model.requestNotificationAuthorizationAndRefreshSchedule()

        XCTAssertEqual(coordinator.calls.count, 1)
        XCTAssertFalse(coordinator.calls[0].requestAuthorizationIfNeeded)
    }

    func testForcedAuthorizationRefreshRequestsEvenWhenAllRemindersAreDisabled() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { envelope in
            var profile = envelope.profile(for: .cn)
            profile.apNotificationsEnabled = false
            profile.cafeApNotificationsEnabled = false
            profile.visitNotificationsEnabled = false
            profile.arenaRefreshNotificationsEnabled = false
            envelope.setProfile(profile, for: .cn)
            envelope.globalSettings.calendarUpcomingNotificationsEnabled = false
            envelope.globalSettings.calendarEndingNotificationsEnabled = false
            envelope.globalSettings.poolUpcomingNotificationsEnabled = false
            envelope.globalSettings.poolEndingNotificationsEnabled = false
            envelope.globalSettings.calendarPoolChangeNotificationsEnabled = false
        }

        await model.requestNotificationAuthorizationAndRefreshSchedule(forceRequest: true)

        XCTAssertEqual(coordinator.calls.count, 1)
        XCTAssertTrue(coordinator.calls[0].requestAuthorizationIfNeeded)
    }

    func testDebugNotificationActionsForwardToCoordinator() async throws {
        let defaults = try makeIsolatedDefaults()
        let coordinator = RecordingNotificationCoordinator()
        let model = makeAppModel(defaults: defaults, coordinator: coordinator) { _ in }
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        await model.sendTestNotification(now: now)
        let liveActivityStarted = await model.startTestLiveActivity(now: now)
        let activityLiveActivityStarted = await model.startTestLiveActivity(
            kind: .activity,
            now: now.addingTimeInterval(60)
        )
        let poolLiveActivityStarted = await model.startTestLiveActivity(
            kind: .pool,
            now: now.addingTimeInterval(120)
        )
        await model.endTestLiveActivities()

        XCTAssertEqual(coordinator.testNotificationDates, [now])
        XCTAssertEqual(coordinator.testLiveActivities.map(\.kind), [.resource, .activity, .pool])
        XCTAssertEqual(
            coordinator.testLiveActivities.map(\.now),
            [now, now.addingTimeInterval(60), now.addingTimeInterval(120)]
        )
        XCTAssertTrue(liveActivityStarted)
        XCTAssertTrue(activityLiveActivityStarted)
        XCTAssertTrue(poolLiveActivityStarted)
        XCTAssertEqual(coordinator.endTestLiveActivityCount, 1)
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "KeiBAOSTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeAppModel(
        defaults: UserDefaults,
        coordinator: RecordingNotificationCoordinator,
        configureEnvelope: (inout BaSettingsEnvelope) -> Void
    ) -> BaAppModel {
        var envelope = BaSettingsEnvelope.defaults()
        configureEnvelope(&envelope)
        BaSettingsStore(defaults: defaults).saveEnvelope(envelope)

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
            officeRepository: BaOfficeRepository(),
            notificationCoordinator: coordinator
        )
    }

    private func assertCoordinatorCallCount(
        _ expectedCount: Int,
        coordinator: RecordingNotificationCoordinator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<50 {
            if coordinator.calls.count >= expectedCount {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected \(expectedCount) notification sync call(s), got \(coordinator.calls.count).", file: file, line: line)
    }

    private func assertNoCoordinatorCalls(
        coordinator: RecordingNotificationCoordinator,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(coordinator.calls.isEmpty, file: file, line: line)
    }
}

@MainActor
private final class RecordingNotificationCoordinator: BaNotificationCoordinating {
    struct Call {
        var envelope: BaSettingsEnvelope?
        var settings: BaAppSettings
        var activities: [BaActivityEntry]
        var pools: [BaPoolEntry]
        var requestAuthorizationIfNeeded: Bool
        var now: Date
    }

    var calls: [Call] = []
    var testNotificationDates: [Date] = []
    var testLiveActivities: [(kind: BaDebugLiveActivityKind, now: Date)] = []
    var endTestLiveActivityCount = 0

    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async {
        calls.append(
            Call(
                envelope: nil,
                settings: settings,
                activities: activities,
                pools: pools,
                requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
                now: now
            )
        )
    }

    func synchronize(
        envelope: BaSettingsEnvelope,
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async {
        calls.append(
            Call(
                envelope: envelope,
                settings: settings,
                activities: activities,
                pools: pools,
                requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
                now: now
            )
        )
    }

    func sendTestNotification(now: Date) async {
        testNotificationDates.append(now)
    }

    func startTestLiveActivity(kind: BaDebugLiveActivityKind, now: Date) async -> Bool {
        testLiveActivities.append((kind, now))
        return true
    }

    func endTestLiveActivities() async {
        endTestLiveActivityCount += 1
    }
}
