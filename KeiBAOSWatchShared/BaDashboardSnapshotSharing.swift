//
//  BaDashboardSnapshotSharing.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import Foundation

nonisolated enum BaDashboardWidgetKind {
    static let resources = "BaDashboardResourcesWidget"
    static let timeline = "BaDashboardTimelineWidget"
}

nonisolated enum BaDashboardSnapshotSharing {
    static let appGroupIdentifier = "group.os.kei.KeiBAOS"

    private static let sharedSnapshotKey = "ba.shared.dashboardSnapshot.v1"
    private static let sharedSnapshotFileName = "ba.shared.dashboardSnapshot.v1.data"
    private static let legacyWatchSnapshotKey = "ba.watch.cachedDashboardSnapshot.v1"

    static func loadSnapshot() -> BaWatchDashboardSnapshot? {
        if let snapshot = loadSnapshotFromSharedFile() {
            return snapshot
        }
        if let snapshot = loadSnapshot(from: .standard, key: sharedSnapshotKey) {
            return snapshot
        }
        return loadSnapshot(from: .standard, key: legacyWatchSnapshotKey)
    }

    static func save(_ snapshot: BaWatchDashboardSnapshot) {
        guard let data = try? BaWatchDashboardSnapshotCoding.encode(snapshot) else { return }
        saveDataToSharedFile(data)
        save(data, to: .standard, key: sharedSnapshotKey)
    }

    static func save(_ data: Data) {
        guard (try? BaWatchDashboardSnapshotCoding.decode(data)) != nil else { return }
        saveDataToSharedFile(data)
        save(data, to: .standard, key: sharedSnapshotKey)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: sharedSnapshotKey)
        defaults.removeObject(forKey: legacyWatchSnapshotKey)
        if let sharedSnapshotFileURL {
            try? FileManager.default.removeItem(at: sharedSnapshotFileURL)
        }
    }

    private static var sharedSnapshotFileURL: URL? {
        #if os(iOS) || os(watchOS)
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(sharedSnapshotFileName, isDirectory: false)
        #else
        return nil
        #endif
    }

    private static func loadSnapshotFromSharedFile() -> BaWatchDashboardSnapshot? {
        guard let sharedSnapshotFileURL,
              let data = try? Data(contentsOf: sharedSnapshotFileURL)
        else {
            return nil
        }
        return try? BaWatchDashboardSnapshotCoding.decode(data)
    }

    private static func loadSnapshot(from defaults: UserDefaults?, key: String) -> BaWatchDashboardSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? BaWatchDashboardSnapshotCoding.decode(data)
    }

    private static func saveDataToSharedFile(_ data: Data) {
        guard let sharedSnapshotFileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: sharedSnapshotFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if (try? Data(contentsOf: sharedSnapshotFileURL)) == data {
                return
            }
            try data.write(to: sharedSnapshotFileURL, options: [.atomic])
        } catch {
            return
        }
    }

    private static func save(_ data: Data, to defaults: UserDefaults?, key: String) {
        guard let defaults, defaults.data(forKey: key) != data else { return }
        defaults.set(data, forKey: key)
    }
}
