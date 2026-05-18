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
    var state: BaWatchSyncState { get }
    var onStateChanged: (@MainActor (BaWatchSyncState) -> Void)? { get set }

    func activate()
    func sync(_ snapshot: BaWatchDashboardSnapshot)
    func refreshState()
}

nonisolated enum BaWatchSyncAvailability: String, Equatable, Sendable {
    case unavailable
    case activating
    case confirmingInstall
    case notPaired
    case appNotInstalled
    case reachable
    case background
    case error
}

nonisolated struct BaWatchSyncState: Equatable, Sendable {
    var availability: BaWatchSyncAvailability
    var lastApplicationContextSentAt: Date?
    var lastGuaranteedTransferQueuedAt: Date?
    var lastSnapshotSourceUpdatedAt: Date?
    var lastErrorDescription: String?

    static let unavailable = BaWatchSyncState(availability: .unavailable)
}

@MainActor
final class BaNoopWatchSnapshotSyncer: BaWatchSnapshotSyncing {
    let state = BaWatchSyncState.unavailable
    var onStateChanged: (@MainActor (BaWatchSyncState) -> Void)?

    func activate() {}
    func sync(_ snapshot: BaWatchDashboardSnapshot) {}
    func refreshState() {}
}

#if os(iOS) && canImport(WatchConnectivity)
@MainActor
final class BaWatchConnectivityBridge: NSObject, BaWatchSnapshotSyncing {
    private(set) var state = BaWatchSyncState.unavailable {
        didSet {
            guard state != oldValue else { return }
            onStateChanged?(state)
        }
    }

    var onStateChanged: (@MainActor (BaWatchSyncState) -> Void)?

    private var pendingSnapshot: BaWatchDashboardSnapshot?
    private var pendingRequiresGuaranteedDelivery = false
    private var didAssignDelegate = false
    private var lastApplicationContextData: Data?
    private var lastQueuedGuaranteedSourceUpdatedAt: Date?
    private var watchAppMissingSince: Date?
    private let watchAppInstallGraceInterval: TimeInterval = 45

    func activate() {
        guard WCSession.isSupported() else {
            state.availability = .unavailable
            return
        }
        let session = WCSession.default
        if didAssignDelegate == false {
            session.delegate = self
            didAssignDelegate = true
        }
        updateState(from: session)
        guard session.activationState == .notActivated else { return }
        state.availability = .activating
        session.activate()
    }

    func sync(_ snapshot: BaWatchDashboardSnapshot) {
        pendingSnapshot = snapshot
        pendingRequiresGuaranteedDelivery = true
        flushPendingSnapshot()
    }

    func refreshState() {
        activate()
        guard WCSession.isSupported() else { return }
        updateState(from: WCSession.default)
    }

    private func flushPendingSnapshot() {
        guard WCSession.isSupported() else {
            state.availability = .unavailable
            return
        }
        activate()

        let session = WCSession.default
        updateState(from: session)

        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              let snapshot = pendingSnapshot
        else {
            return
        }

        let data: Data
        do {
            data = try BaWatchDashboardSnapshotCoding.encode(snapshot)
        } catch {
            state.availability = .error
            state.lastErrorDescription = error.localizedDescription
            return
        }

        let payload = payload(for: snapshot, data: data)
        do {
            if data != lastApplicationContextData {
                try session.updateApplicationContext(payload)
                lastApplicationContextData = data
                state.lastApplicationContextSentAt = Date()
            }
            queueGuaranteedTransferIfNeeded(payload: payload, snapshot: snapshot, session: session)
            state.lastSnapshotSourceUpdatedAt = snapshot.sourceUpdatedAt
            state.lastErrorDescription = nil
            updateState(from: session)
            pendingSnapshot = nil
            pendingRequiresGuaranteedDelivery = false
        } catch {
            state.availability = .error
            state.lastErrorDescription = error.localizedDescription
            queueGuaranteedTransfer(payload: payload, snapshot: snapshot, session: session)
        }
    }

    private func updateState(from session: WCSession, now: Date = Date()) {
        guard session.activationState == .activated else {
            state.availability = .activating
            return
        }
        guard session.isPaired else {
            state.availability = .notPaired
            return
        }
        guard session.isWatchAppInstalled else {
            if watchAppMissingSince == nil {
                watchAppMissingSince = now
            }
            let missingDuration = now.timeIntervalSince(watchAppMissingSince ?? now)
            if missingDuration < watchAppInstallGraceInterval {
                state.availability = .confirmingInstall
            } else {
                state.availability = .appNotInstalled
            }
            return
        }
        watchAppMissingSince = nil
        state.availability = session.isReachable ? .reachable : .background
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
        state.lastGuaranteedTransferQueuedAt = Date()
        #endif
    }
}

extension BaWatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.updateState(from: session)
            if let error {
                self?.state.availability = .error
                self?.state.lastErrorDescription = error.localizedDescription
            }
            guard activationState == .activated else { return }
            self?.flushPendingSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.updateState(from: session)
            self?.flushPendingSnapshot()
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.updateState(from: session)
            self?.flushPendingSnapshot()
        }
    }
}
#endif
