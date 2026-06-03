//
//  BaAppModel+Notifications.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func scheduleNotificationRefresh(
        requestAuthorizationIfNeeded: Bool = false,
        now: Date = Date(),
        delay: Duration? = nil
    ) {
        let envelope = envelope
        let settings = settings
        let activities = activityState.value ?? []
        let pools = poolState.value ?? []
        notificationSyncTask?.cancel()
        notificationSyncTask = Task { [notificationCoordinator] in
            if let delay {
                try? await Task.sleep(for: delay)
            }
            guard Task.isCancelled == false else { return }
            await notificationCoordinator.synchronize(
                envelope: envelope,
                settings: settings,
                activities: activities,
                pools: pools,
                requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
                now: now
            )
        }
    }

    func requestNotificationAuthorizationAndRefreshSchedule(
        forceRequest: Bool = false,
        now: Date = Date()
    ) async {
        let hasEnabledReminder = BaNotificationPreferenceSnapshot(envelope: envelope).hasEnabledReminder
        let envelope = envelope
        let settings = settings
        let activities = activityState.value ?? []
        let pools = poolState.value ?? []
        notificationSyncTask?.cancel()
        await notificationCoordinator.synchronize(
            envelope: envelope,
            settings: settings,
            activities: activities,
            pools: pools,
            requestAuthorizationIfNeeded: forceRequest || hasEnabledReminder,
            now: now
        )
    }

    func sendTestNotification(now: Date = Date()) async {
        await notificationCoordinator.sendTestNotification(now: now)
    }

    func startTestLiveActivity(kind: BaDebugLiveActivityKind = .resource, now: Date = Date()) async -> Bool {
        await notificationCoordinator.startTestLiveActivity(kind: kind, now: now)
    }

    func endTestLiveActivities() async {
        await notificationCoordinator.endTestLiveActivities()
    }
}
