//
//  BaWatchSnapshotStore.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import Foundation
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum BaWatchPhoneConnectionStatus: Equatable, Sendable {
    case waiting
    case connected
    case background
    case unavailable

    var localizedValue: String {
        switch self {
        case .waiting:
            String(localized: "ba.watch.connection.waiting")
        case .connected:
            String(localized: "ba.watch.connection.connected")
        case .background:
            String(localized: "ba.watch.connection.background")
        case .unavailable:
            String(localized: "ba.watch.connection.unavailable")
        }
    }

    var systemImage: String {
        switch self {
        case .waiting:
            "iphone.gen3.slash"
        case .connected:
            "iphone.gen3.radiowaves.left.and.right"
        case .background:
            "arrow.triangle.2.circlepath"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }
}

@Observable
@MainActor
final class BaWatchSnapshotStore {
    static let shared = BaWatchSnapshotStore()

    private let defaults: UserDefaults
    private let snapshotKey = "ba.watch.cachedDashboardSnapshot.v1"
    @ObservationIgnored private var connectivityController: BaWatchConnectivityController?

    var snapshot: BaWatchDashboardSnapshot?
    var lastSyncError: String?
    var phoneConnectionStatus: BaWatchPhoneConnectionStatus = .waiting

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
        BaDashboardSnapshotSharing.save(data)
        reloadWidgetTimelines()
        guard snapshot != decoded else { return }
        snapshot = decoded
    }

    private func recordSyncError(_ error: Error) {
        lastSyncError = error.localizedDescription
    }

    func updatePhoneConnectionStatus(_ status: BaWatchPhoneConnectionStatus) {
        guard phoneConnectionStatus != status else { return }
        phoneConnectionStatus = status
    }

    private func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: BaDashboardWidgetKind.resources)
        WidgetCenter.shared.reloadTimelines(ofKind: BaDashboardWidgetKind.timeline)
        #endif
    }
}
