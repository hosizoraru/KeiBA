//
//  BaUserNotificationSchedulerTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

import Foundation
@testable import KeiBAOS
import UserNotifications
import XCTest

@MainActor
final class BaUserNotificationSchedulerTests: XCTestCase {
    func testSchedulerReplacesOnlyManagedNotificationRequests() async {
        let center = RecordingNotificationCenter()
        center.status = .authorized
        center.pendingIdentifiers = [
            BaNotificationPlan.managedIdentifierPrefix + "cn.ap.threshold",
            "external.request",
        ]
        let scheduler = BaUserNotificationScheduler(center: center)
        let reminder = BaNotificationReminder(
            id: BaNotificationPlan.managedIdentifierPrefix + "cn.cafeAP.threshold",
            kind: .cafeAP,
            fireDate: Date(timeIntervalSince1970: 1_800_000_120),
            titleKey: "ba.notification.cafeAp.title",
            bodyKey: "ba.notification.cafeAp.body",
            bodyArguments: ["740", "12:00"],
            threadIdentifier: "test"
        )

        await scheduler.apply(
            plan: BaNotificationPlan(reminders: [reminder]),
            requestAuthorizationIfNeeded: false,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(center.removedIdentifiers, [BaNotificationPlan.managedIdentifierPrefix + "cn.ap.threshold"])
        XCTAssertEqual(center.addedRequests.map(\.identifier), [reminder.id])
    }

    func testSchedulerRequestsAuthorizationBeforeSchedulingWhenNeeded() async {
        let center = RecordingNotificationCenter()
        center.status = .notDetermined
        center.statusAfterAuthorization = .authorized
        let scheduler = BaUserNotificationScheduler(center: center)
        let reminder = BaNotificationReminder(
            id: BaNotificationPlan.managedIdentifierPrefix + "cn.ap.threshold",
            kind: .ap,
            fireDate: Date(timeIntervalSince1970: 1_800_000_060),
            titleKey: "ba.notification.ap.title",
            bodyKey: "ba.notification.ap.body",
            bodyArguments: ["120", "12:00"],
            threadIdentifier: "test"
        )

        await scheduler.apply(
            plan: BaNotificationPlan(reminders: [reminder]),
            requestAuthorizationIfNeeded: true,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertEqual(center.addedRequests.map(\.identifier), [reminder.id])
    }

    func testSchedulerClearsManagedRequestsWhenAuthorizationIsDenied() async {
        let center = RecordingNotificationCenter()
        center.status = .denied
        center.pendingIdentifiers = [
            BaNotificationPlan.managedIdentifierPrefix + "cn.ap.threshold",
            "external.request",
        ]
        let scheduler = BaUserNotificationScheduler(center: center)
        let reminder = BaNotificationReminder(
            id: BaNotificationPlan.managedIdentifierPrefix + "cn.cafeAP.threshold",
            kind: .cafeAP,
            fireDate: Date(timeIntervalSince1970: 1_800_000_120),
            titleKey: "ba.notification.cafeAp.title",
            bodyKey: "ba.notification.cafeAp.body",
            bodyArguments: ["740", "12:00"],
            threadIdentifier: "test"
        )

        await scheduler.apply(
            plan: BaNotificationPlan(reminders: [reminder]),
            requestAuthorizationIfNeeded: false,
            now: Date(timeIntervalSince1970: 1_800_000_000)
        )

        XCTAssertEqual(center.removedIdentifiers, [BaNotificationPlan.managedIdentifierPrefix + "cn.ap.threshold"])
        XCTAssertTrue(center.addedRequests.isEmpty)
    }
}

private final class RecordingNotificationCenter: BaUserNotificationCenterClient {
    var status: UNAuthorizationStatus = .denied
    var statusAfterAuthorization: UNAuthorizationStatus?
    var pendingIdentifiers: [String] = []
    var removedIdentifiers: [String] = []
    var addedRequests: [UNNotificationRequest] = []
    var authorizationRequestCount = 0

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationRequestCount += 1
        if let statusAfterAuthorization {
            status = statusAfterAuthorization
        }
        return status.allowsSchedulingInTests
    }

    func pendingNotificationIdentifiers(matchingPrefix prefix: String) async -> [String] {
        pendingIdentifiers.filter { $0.hasPrefix(prefix) }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers += identifiers
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
}

private extension UNAuthorizationStatus {
    var allowsSchedulingInTests: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }
}
