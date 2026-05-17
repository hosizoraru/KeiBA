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
        await model.endTestLiveActivities()

        XCTAssertEqual(coordinator.testNotificationDates, [now])
        XCTAssertEqual(coordinator.testLiveActivityDates, [now])
        XCTAssertTrue(liveActivityStarted)
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
}

@MainActor
private final class RecordingNotificationCoordinator: BaNotificationCoordinating {
    struct Call {
        var settings: BaAppSettings
        var activities: [BaActivityEntry]
        var pools: [BaPoolEntry]
        var requestAuthorizationIfNeeded: Bool
        var now: Date
    }

    var calls: [Call] = []
    var testNotificationDates: [Date] = []
    var testLiveActivityDates: [Date] = []
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

    func startTestLiveActivity(now: Date) async -> Bool {
        testLiveActivityDates.append(now)
        return true
    }

    func endTestLiveActivities() async {
        endTestLiveActivityCount += 1
    }
}
