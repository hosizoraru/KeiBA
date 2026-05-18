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
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        Task { @MainActor in
            BaWatchSnapshotStore.shared.applyApplicationContext(session.receivedApplicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
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

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {}
}
