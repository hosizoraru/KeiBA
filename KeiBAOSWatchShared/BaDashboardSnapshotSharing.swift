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

    // Process-local memo so the main-actor save path doesn't re-read the
    // existing app-group file on every dashboard push just to skip a no-op
    // write. The first write seeds it; subsequent identical pushes short-
    // circuit before any disk I/O. Synchronized via NSLock so it stays
    // safe across the host app and extensions that share this enum.
    private nonisolated static let lastWrittenSharedSnapshotData = BaLockedSnapshotData()

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
        lastWrittenSharedSnapshotData.clear()
    }

    private static var sharedSnapshotFileURL: URL? {
        sharedSnapshotFileURLCache
    }

    // Resolve the app-group container path once. The previous computed
    // property re-asked FileManager on every save and every widget timeline
    // build; the result is fixed for the process lifetime, so caching it
    // turns each subsequent access into a single load.
    private nonisolated static let sharedSnapshotFileURLCache: URL? = {
        #if os(iOS) || os(watchOS)
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(sharedSnapshotFileName, isDirectory: false)
        #else
        nil
        #endif
    }()

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
        // Memoized fast path: skip the disk read used to dedupe identical
        // payloads. The previous Data(contentsOf:) ran on every snapshot
        // sync (which fires on every settings/timeline change), turning a
        // no-op push into a full file read.
        if lastWrittenSharedSnapshotData.matches(data) {
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: sharedSnapshotFileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: sharedSnapshotFileURL, options: [.atomic])
            lastWrittenSharedSnapshotData.store(data)
        } catch {
            return
        }
    }

    private static func save(_ data: Data, to defaults: UserDefaults?, key: String) {
        guard let defaults, defaults.data(forKey: key) != data else { return }
        defaults.set(data, forKey: key)
    }
}

private nonisolated final class BaLockedSnapshotData: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Data?

    func matches(_ data: Data) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value == data
    }

    func store(_ data: Data) {
        lock.lock()
        value = data
        lock.unlock()
    }

    func clear() {
        lock.lock()
        value = nil
        lock.unlock()
    }
}
