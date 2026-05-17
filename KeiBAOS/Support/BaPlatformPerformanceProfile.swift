//
//  BaPlatformPerformanceProfile.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation
#if os(iOS)
    import UIKit
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

    nonisolated static var musicSamplesRowAvatarAccent: Bool {
        musicSamplesRowAvatarAccent(for: currentClass)
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

    nonisolated static func musicSamplesRowAvatarAccent(for platformClass: BaPlatformPerformanceClass) -> Bool {
        switch platformClass {
        case .desktop, .pad:
            true
        case .phone, .watch:
            false
        }
    }

    #if os(iOS)
        private static var isPad: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }
    #endif
}
