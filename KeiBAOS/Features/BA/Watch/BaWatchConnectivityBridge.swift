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
    private var pendingRequiresGuaranteedDelivery = false
    private var didAssignDelegate = false
    private var lastApplicationContextData: Data?
    private var lastQueuedGuaranteedSourceUpdatedAt: Date?

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
        pendingRequiresGuaranteedDelivery = true
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

        let payload = payload(for: snapshot, data: data)
        do {
            if data != lastApplicationContextData {
                try session.updateApplicationContext(payload)
                lastApplicationContextData = data
            }
            queueGuaranteedTransferIfNeeded(payload: payload, snapshot: snapshot, session: session)
            pendingSnapshot = nil
            pendingRequiresGuaranteedDelivery = false
        } catch {
            queueGuaranteedTransfer(payload: payload, snapshot: snapshot, session: session)
        }
    }

    private func payload(for snapshot: BaWatchDashboardSnapshot, data: Data) -> [String: Any] {
        [
            BaWatchDashboardSnapshot.applicationContextKey: data,
            "ba.watch.sourceUpdatedAt": snapshot.sourceUpdatedAt.timeIntervalSince1970
        ]
    }

    private func queueGuaranteedTransferIfNeeded(
        payload: [String: Any],
        snapshot: BaWatchDashboardSnapshot,
        session: WCSession
    ) {
        guard pendingRequiresGuaranteedDelivery, session.isReachable == false else { return }
        queueGuaranteedTransfer(payload: payload, snapshot: snapshot, session: session)
    }

    private func queueGuaranteedTransfer(
        payload: [String: Any],
        snapshot: BaWatchDashboardSnapshot,
        session: WCSession
    ) {
        #if targetEnvironment(simulator)
        _ = payload
        _ = snapshot
        _ = session
        #else
        guard lastQueuedGuaranteedSourceUpdatedAt != snapshot.sourceUpdatedAt else { return }
        session.transferUserInfo(payload)
        lastQueuedGuaranteedSourceUpdatedAt = snapshot.sourceUpdatedAt
        #endif
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

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.flushPendingSnapshot()
        }
    }
}
#endif
