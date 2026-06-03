//
//  BaUserNotificationScheduler.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if canImport(UserNotifications)
import UserNotifications

@MainActor
protocol BaNotificationCoordinating: AnyObject {
    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async

    func synchronize(
        envelope: BaSettingsEnvelope,
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async

    func sendTestNotification(now: Date) async
    func startTestLiveActivity(kind: BaDebugLiveActivityKind, now: Date) async -> Bool
    func endTestLiveActivities() async
}

@MainActor
final class BaNoopNotificationCoordinator: BaNotificationCoordinating {
    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async {}

    func synchronize(
        envelope: BaSettingsEnvelope,
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async {}

    func sendTestNotification(now: Date) async {}
    func startTestLiveActivity(kind: BaDebugLiveActivityKind, now: Date) async -> Bool { false }
    func endTestLiveActivities() async {}
}

@MainActor
final class BaNotificationCoordinator: BaNotificationCoordinating {
    private let scheduler: BaUserNotificationScheduler
    #if os(iOS) && canImport(ActivityKit)
    private let liveActivityController = BaLiveActivityController()
    #endif

    init(scheduler: BaUserNotificationScheduler? = nil) {
        self.scheduler = scheduler ?? BaUserNotificationScheduler(center: BaSystemUserNotificationCenterClient())
        BaUserNotificationForegroundPresenter.shared.install()
    }

    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date = Date()
    ) async {
        await synchronize(
            envelope: BaSettingsEnvelope.migrated(from: settings),
            settings: settings,
            activities: activities,
            pools: pools,
            requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
            now: now
        )
    }

    func synchronize(
        envelope: BaSettingsEnvelope,
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date = Date()
    ) async {
        let planning = await Task.detached(priority: .utility) {
            #if os(iOS) && canImport(ActivityKit)
            let liveActivityCandidates = BaNotificationPlanner.liveActivityCandidates(
                settings: settings,
                activities: activities,
                pools: pools,
                now: now
            )
            #else
            let liveActivityCandidates: [BaLiveActivityCandidate] = []
            #endif

            return BaNotificationPlanningResult(
                plan: BaNotificationPlanner.makePlan(
                    envelope: envelope,
                    activities: activities,
                    pools: pools,
                    now: now
                ),
                liveActivityCandidates: liveActivityCandidates
            )
        }.value

        await scheduler.apply(plan: planning.plan, requestAuthorizationIfNeeded: requestAuthorizationIfNeeded, now: now)

        #if os(iOS) && canImport(ActivityKit)
        await liveActivityController.synchronize(candidates: planning.liveActivityCandidates)
        #endif
    }

    func sendTestNotification(now: Date = Date()) async {
        await scheduler.sendTestNotification(requestAuthorizationIfNeeded: true, now: now)
    }

    func startTestLiveActivity(kind: BaDebugLiveActivityKind = .resource, now: Date = Date()) async -> Bool {
        #if os(iOS) && canImport(ActivityKit)
        await liveActivityController.startTestActivity(kind: kind, now: now)
        #else
        false
        #endif
    }

    func endTestLiveActivities() async {
        #if os(iOS) && canImport(ActivityKit)
        await liveActivityController.endTestActivities()
        #endif
    }
}

private struct BaNotificationPlanningResult: Sendable {
    let plan: BaNotificationPlan
    let liveActivityCandidates: [BaLiveActivityCandidate]
}

@MainActor
final class BaUserNotificationScheduler {
    private let center: BaUserNotificationCenterClient

    init(center: BaUserNotificationCenterClient) {
        self.center = center
    }

    func apply(
        plan: BaNotificationPlan,
        requestAuthorizationIfNeeded: Bool,
        now: Date = Date()
    ) async {
        if requestAuthorizationIfNeeded {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let status = await center.authorizationStatus()
        guard status.allowsScheduling else {
            await removeManagedRequests()
            return
        }

        await removeManagedRequests()

        for reminder in plan.reminders {
            guard reminder.fireDate > now else { continue }
            let request = makeRequest(reminder: reminder, now: now)
            try? await center.add(request)
        }
    }

    func sendTestNotification(
        requestAuthorizationIfNeeded: Bool,
        now: Date = Date()
    ) async {
        if requestAuthorizationIfNeeded {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let status = await center.authorizationStatus()
        guard status.allowsScheduling else { return }

        let identifier = BaNotificationPlan.debugIdentifierPrefix + "local"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = localized("ba.notification.debug.local.title")
        content.body = localized("ba.notification.debug.local.body")
        content.sound = .default
        content.threadIdentifier = "os.kei.KeiBAOS.ba.debug"
        content.categoryIdentifier = "ba.debug"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func removeManagedRequests() async {
        let identifiers = await center.pendingNotificationIdentifiers(
            matchingPrefix: BaNotificationPlan.managedIdentifierPrefix
        )
        guard identifiers.isEmpty == false else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func makeRequest(reminder: BaNotificationReminder, now: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = localized(reminder.titleKey)
        content.body = String(
            format: localized(reminder.bodyKey),
            arguments: reminder.bodyArguments
        )
        content.sound = .default
        content.threadIdentifier = reminder.threadIdentifier
        content.categoryIdentifier = "ba.\(reminder.kind.rawValue)"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(reminder.fireDate.timeIntervalSince(now), 1),
            repeats: false
        )
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }
}

protocol BaUserNotificationCenterClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func pendingNotificationIdentifiers(matchingPrefix prefix: String) async -> [String]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

struct BaSystemUserNotificationCenterClient: BaUserNotificationCenterClient {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func pendingNotificationIdentifiers(matchingPrefix prefix: String) async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.map(\.identifier).filter { $0.hasPrefix(prefix) })
            }
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

final class BaUserNotificationForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = BaUserNotificationForegroundPresenter()

    func install(center: UNUserNotificationCenter = .current()) {
        center.delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

private extension UNAuthorizationStatus {
    var allowsScheduling: Bool {
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
#else
@MainActor
protocol BaNotificationCoordinating: AnyObject {
    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async

    func sendTestNotification(now: Date) async
    func startTestLiveActivity(kind: BaDebugLiveActivityKind, now: Date) async -> Bool
    func endTestLiveActivities() async
}

@MainActor
final class BaNoopNotificationCoordinator: BaNotificationCoordinating {
    func synchronize(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        requestAuthorizationIfNeeded: Bool,
        now: Date
    ) async {}

    func sendTestNotification(now: Date) async {}
    func startTestLiveActivity(kind: BaDebugLiveActivityKind, now: Date) async -> Bool { false }
    func endTestLiveActivities() async {}
}
#endif
