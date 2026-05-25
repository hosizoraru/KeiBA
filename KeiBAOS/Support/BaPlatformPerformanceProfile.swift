//
//  BaPlatformPerformanceProfile.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation
#if os(iOS)
    import Darwin
#endif

nonisolated enum BaPlatformPerformanceClass: Equatable, Sendable {
    case phone
    case pad
    case desktop
    case watch
}

enum BaPlatformPerformanceProfile {
    nonisolated static var currentClass: BaPlatformPerformanceClass {
        #if os(macOS)
            .desktop
        #elseif os(iOS)
            isPad ? .pad : .phone
        #elseif os(watchOS)
            .watch
        #else
            .phone
        #endif
    }

    nonisolated static var catalogReleaseDateFetchLimit: Int {
        catalogReleaseDateFetchLimit(for: currentClass)
    }

    nonisolated static var catalogReleaseDateBatchSize: Int {
        catalogReleaseDateBatchSize(for: currentClass)
    }

    nonisolated static var catalogCachedReleaseDateBatchSize: Int {
        catalogCachedReleaseDateBatchSize(for: currentClass)
    }

    nonisolated static var musicInitialDetailFetchLimit: Int {
        musicInitialDetailFetchLimit(for: currentClass)
    }

    nonisolated static var musicDetailPrefetchConcurrency: Int {
        musicDetailPrefetchConcurrency(for: currentClass)
    }

    nonisolated static var musicCacheConcurrency: Int {
        musicCacheConcurrency(for: currentClass)
    }

    nonisolated static var musicProgressUpdateInterval: TimeInterval {
        musicProgressUpdateInterval(for: currentClass)
    }

    nonisolated static var overviewStartupNetworkDelay: Duration {
        overviewStartupNetworkDelay(for: currentClass)
    }

    nonisolated static var notificationStartupRefreshDelay: Duration {
        notificationStartupRefreshDelay(for: currentClass)
    }

    nonisolated static var notificationTimelineRefreshDelay: Duration {
        notificationTimelineRefreshDelay(for: currentClass)
    }

    nonisolated static var musicSamplesRowAvatarAccent: Bool {
        musicSamplesRowAvatarAccent(for: currentClass)
    }

    nonisolated static var imageMemoryCacheCountLimit: Int {
        imageMemoryCacheCountLimit(for: currentClass)
    }

    nonisolated static var imageMemoryCacheCostLimit: Int {
        imageMemoryCacheCostLimit(for: currentClass)
    }

    nonisolated static func catalogReleaseDateFetchLimit(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            12
        case .pad:
            8
        case .phone:
            4
        case .watch:
            2
        }
    }

    nonisolated static func catalogReleaseDateBatchSize(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            3
        case .pad:
            2
        case .phone, .watch:
            1
        }
    }

    nonisolated static func catalogCachedReleaseDateBatchSize(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            48
        case .pad:
            32
        case .phone:
            16
        case .watch:
            8
        }
    }

    nonisolated static func musicInitialDetailFetchLimit(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            18
        case .pad:
            12
        case .phone:
            7
        case .watch:
            3
        }
    }

    nonisolated static func musicDetailPrefetchConcurrency(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            6
        case .pad:
            4
        case .phone:
            2
        case .watch:
            1
        }
    }

    nonisolated static func musicCacheConcurrency(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            5
        case .pad:
            3
        case .phone:
            2
        case .watch:
            1
        }
    }

    nonisolated static func musicProgressUpdateInterval(for platformClass: BaPlatformPerformanceClass) -> TimeInterval {
        switch platformClass {
        case .desktop:
            0.25
        case .pad:
            0.33
        case .phone:
            0.5
        case .watch:
            1
        }
    }

    nonisolated static func overviewStartupNetworkDelay(for platformClass: BaPlatformPerformanceClass) -> Duration {
        switch platformClass {
        case .desktop:
            .milliseconds(350)
        case .pad:
            .milliseconds(550)
        case .phone:
            .milliseconds(850)
        case .watch:
            .seconds(1)
        }
    }

    nonisolated static func notificationStartupRefreshDelay(for platformClass: BaPlatformPerformanceClass) -> Duration {
        switch platformClass {
        case .desktop:
            .milliseconds(1_200)
        case .pad:
            .milliseconds(3_000)
        case .phone:
            .seconds(5)
        case .watch:
            .seconds(6)
        }
    }

    nonisolated static func notificationTimelineRefreshDelay(for platformClass: BaPlatformPerformanceClass) -> Duration {
        switch platformClass {
        case .desktop:
            .milliseconds(1_200)
        case .pad:
            .milliseconds(3_000)
        case .phone:
            .seconds(5)
        case .watch:
            .seconds(6)
        }
    }

    nonisolated static func musicSamplesRowAvatarAccent(for platformClass: BaPlatformPerformanceClass) -> Bool {
        switch platformClass {
        case .desktop, .pad:
            true
        case .phone, .watch:
            false
        }
    }

    // Cap the in-memory image cache to a value that scales with the device's
    // available memory. The previous flat 32 MB / 256 entries was generous on
    // a desktop and aggressive on a watch (a single page of thumbnails would
    // exceed it). NSCache uses these as soft hints, so the OS can still evict
    // earlier under pressure.
    nonisolated static func imageMemoryCacheCountLimit(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            512
        case .pad:
            384
        case .phone:
            256
        case .watch:
            96
        }
    }

    nonisolated static func imageMemoryCacheCostLimit(for platformClass: BaPlatformPerformanceClass) -> Int {
        switch platformClass {
        case .desktop:
            96 * 1024 * 1024
        case .pad:
            64 * 1024 * 1024
        case .phone:
            32 * 1024 * 1024
        case .watch:
            8 * 1024 * 1024
        }
    }

    #if os(iOS)
        nonisolated private static var isPad: Bool {
            let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
            if simulatorModelIdentifier.hasPrefix("iPad") {
                return true
            }

            return deviceModelIdentifier.hasPrefix("iPad")
        }

        nonisolated private static var deviceModelIdentifier: String {
            var systemInfo = utsname()
            _ = uname(&systemInfo)

            return withUnsafePointer(to: &systemInfo.machine) { pointer in
                pointer.withMemoryRebound(to: CChar.self, capacity: 1) { reboundPointer in
                    String(validatingUTF8: reboundPointer) ?? ""
                }
            }
        }
    #endif
}
