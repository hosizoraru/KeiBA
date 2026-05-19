//
//  BaWatchConnectivityController.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import Foundation
import WatchConnectivity

@MainActor
final class BaWatchConnectivityController: NSObject, WCSessionDelegate {
    private var didAssignDelegate = false
    private var didRequestActivation = false

    func activate() {
        guard WCSession.isSupported() else {
            BaWatchSnapshotStore.shared.updatePhoneConnectionStatus(.unavailable)
            return
        }
        let session = WCSession.default
        if didAssignDelegate == false {
            session.delegate = self
            didAssignDelegate = true
        }
        publishPhoneConnectionStatus(for: session)
        guard session.activationState == .notActivated, didRequestActivation == false else { return }
        didRequestActivation = true
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        publishPhoneConnectionStatus(for: session, activationState: activationState)
        guard activationState == .activated else {
            Task { @MainActor in
                self.didRequestActivation = false
            }
            return
        }
        Task { @MainActor in
            self.didRequestActivation = false
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard applicationContext[BaWatchDashboardSnapshot.applicationContextKey] is Data else { return }
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        guard userInfo[BaWatchDashboardSnapshot.applicationContextKey] is Data else { return }
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(userInfo)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        publishPhoneConnectionStatus(for: session)
    }

    private nonisolated func publishPhoneConnectionStatus(
        for session: WCSession,
        activationState: WCSessionActivationState? = nil
    ) {
        let resolvedActivationState = activationState ?? session.activationState
        let status: BaWatchPhoneConnectionStatus
        if resolvedActivationState != .activated {
            status = .waiting
        } else if session.isReachable {
            status = .connected
        } else {
            status = .background
        }

        Task { @MainActor in
            BaWatchSnapshotStore.shared.updatePhoneConnectionStatus(status)
        }
    }
}
