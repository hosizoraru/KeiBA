//
//  BaWatchConnectivityController.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import Foundation
import WatchConnectivity

final class BaWatchConnectivityController: NSObject, WCSessionDelegate {
    func activate() {
        guard WCSession.isSupported() else {
            Task { @MainActor in
                BaWatchSnapshotStore.shared.updatePhoneConnectionStatus(.unavailable)
            }
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        publishPhoneConnectionStatus(for: session)
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(session.receivedApplicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        publishPhoneConnectionStatus(for: session, activationState: activationState)
        guard activationState == .activated else { return }
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(session.receivedApplicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
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
