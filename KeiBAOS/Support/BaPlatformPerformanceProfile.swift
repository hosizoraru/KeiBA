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

enum BaPlatformPerformanceProfile {
    static var catalogReleaseDateFetchLimit: Int {
        #if os(macOS)
            12
        #elseif os(iOS)
            isPad ? 8 : 4
        #elseif os(watchOS)
            2
        #else
            4
        #endif
    }

    static var catalogReleaseDateBatchSize: Int {
        #if os(macOS)
            3
        #elseif os(iOS)
            isPad ? 2 : 1
        #elseif os(watchOS)
            1
        #else
            1
        #endif
    }

    static var musicInitialDetailFetchLimit: Int {
        #if os(macOS)
            18
        #elseif os(iOS)
            isPad ? 12 : 7
        #elseif os(watchOS)
            3
        #else
            7
        #endif
    }

    static var musicSamplesRowAvatarAccent: Bool {
        #if os(macOS)
            true
        #elseif os(iOS)
            isPad
        #elseif os(watchOS)
            false
        #else
            false
        #endif
    }

    #if os(iOS)
        private static var isPad: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }
    #endif
}
