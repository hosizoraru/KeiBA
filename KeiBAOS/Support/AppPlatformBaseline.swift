//
//  AppPlatformBaseline.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import Foundation

enum AppPlatformBaseline: CaseIterable, Identifiable {
    case iOS
    case iPadOS
    case macOS
    case watchOS

    static let minimumVersion = "26.0"
    static let summary = "26.0+"

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .iOS:
            "iOS"
        case .iPadOS:
            "iPadOS"
        case .macOS:
            "macOS"
        case .watchOS:
            "watchOS"
        }
    }

    var minimumVersion: String {
        Self.minimumVersion
    }

    var systemImage: String {
        switch self {
        case .iOS:
            "iphone"
        case .iPadOS:
            "ipad"
        case .macOS:
            "macwindow"
        case .watchOS:
            "applewatch"
        }
    }
}
