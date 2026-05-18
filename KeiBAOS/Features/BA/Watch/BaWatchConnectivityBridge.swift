//
//  BaWatchConnectivityBridge.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

#if os(iOS) && canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
protocol BaWatchSnapshotSyncing: AnyObject {
    func activate()
    func sync(_ snapshot: BaWatchDashboardSnapshot)
}

@MainActor
final class BaNoopWatchSnapshotSyncer: BaWatchSnapshotSyncing {
    func activate() {}
    func sync(_ snapshot: BaWatchDashboardSnapshot) {}
}

#if os(iOS) && canImport(WatchConnectivity)
@MainActor
final class BaWatchConnectivityBridge: NSObject, BaWatchSnapshotSyncing {
    private var pendingSnapshot: BaWatchDashboardSnapshot?
    private var didAssignDelegate = false

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if didAssignDelegate == false {
            session.delegate = self
            didAssignDelegate = true
        }
        guard session.activationState == .notActivated else { return }
        session.activate()
    }

    func sync(_ snapshot: BaWatchDashboardSnapshot) {
        pendingSnapshot = snapshot
        flushPendingSnapshot()
    }

    private func flushPendingSnapshot() {
        guard WCSession.isSupported() else { return }
        activate()

        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              let snapshot = pendingSnapshot,
              let data = try? BaWatchDashboardSnapshotCoding.encode(snapshot)
        else {
            return
        }

        let payload: [String: Any] = [BaWatchDashboardSnapshot.applicationContextKey: data]
        do {
            try session.updateApplicationContext(payload)
            pendingSnapshot = nil
        } catch {
            session.transferUserInfo(payload)
        }
    }
}

extension BaWatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        Task { @MainActor [weak self] in
            self?.flushPendingSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
