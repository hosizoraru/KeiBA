//
//  BaWatchSnapshotStore.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import Foundation
import Observation

@Observable
@MainActor
final class BaWatchSnapshotStore {
    static let shared = BaWatchSnapshotStore()

    private let defaults: UserDefaults
    private let snapshotKey = "ba.watch.cachedDashboardSnapshot.v1"
    @ObservationIgnored private var connectivityController: BaWatchConnectivityController?

    var snapshot: BaWatchDashboardSnapshot?
    var lastSyncError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        snapshot = Self.loadSnapshot(from: defaults, key: snapshotKey)
    }

    func activateConnectivity() {
        if connectivityController == nil {
            connectivityController = BaWatchConnectivityController()
        }
        connectivityController?.activate()
    }

    func applyApplicationContext(_ context: [String: Any]) {
        guard let data = context[BaWatchDashboardSnapshot.applicationContextKey] as? Data else { return }
        applySnapshotData(data)
    }

    func applySnapshotData(_ data: Data) {
        Task.detached(priority: .utility) {
            do {
                let decoded = try BaWatchDashboardSnapshotCoding.decode(data)
                await self.commit(snapshot: decoded, data: data)
            } catch {
                await self.recordSyncError(error)
            }
        }
    }

    private static func loadSnapshot(from defaults: UserDefaults, key: String) -> BaWatchDashboardSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? BaWatchDashboardSnapshotCoding.decode(data)
    }

    private func commit(snapshot decoded: BaWatchDashboardSnapshot, data: Data) {
        lastSyncError = nil
        if defaults.data(forKey: snapshotKey) != data {
            defaults.set(data, forKey: snapshotKey)
        }
        guard snapshot != decoded else { return }
        snapshot = decoded
    }

    private func recordSyncError(_ error: Error) {
        lastSyncError = error.localizedDescription
    }
}
