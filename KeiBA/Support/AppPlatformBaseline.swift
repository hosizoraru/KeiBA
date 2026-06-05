//
//  AppPlatformBaseline.swift
//  KeiBA
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
        "\(Self.minimumVersion)+"
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

enum AppBuildBaseline: CaseIterable, Identifiable {
    case xcode
    case projectFormat
    case sdk
    case runtimeMinimum

    static let projectFormatVersion = "Xcode 26.3"

    var id: Self {
        self
    }

    var titleKey: String {
        switch self {
        case .xcode:
            "ba.about.platform.build.xcode"
        case .projectFormat:
            "ba.about.platform.build.projectFormat"
        case .sdk:
            "ba.about.platform.build.sdk"
        case .runtimeMinimum:
            "ba.about.platform.build.runtimeMinimum"
        }
    }

    var value: String {
        switch self {
        case .xcode:
            Self.xcodeVersion
        case .projectFormat:
            Self.projectFormatVersion
        case .sdk:
            Self.infoString("DTSDKName")
        case .runtimeMinimum:
            Self.infoString("MinimumOSVersion", fallbackKey: "LSMinimumSystemVersion")
        }
    }

    var systemImage: String {
        switch self {
        case .xcode:
            "hammer"
        case .projectFormat:
            "doc.badge.gearshape"
        case .sdk:
            "shippingbox"
        case .runtimeMinimum:
            "target"
        }
    }

    private static var xcodeVersion: String {
        let rawVersion = infoString("DTXcode")
        let build = infoString("DTXcodeBuild")
        let formattedVersion = formattedXcodeVersion(rawVersion)
        guard build != unknown else { return formattedVersion }
        return "\(formattedVersion) (\(build))"
    }

    private static func formattedXcodeVersion(_ rawVersion: String) -> String {
        guard rawVersion != unknown, rawVersion.count >= 3, let value = Int(rawVersion) else {
            return rawVersion
        }
        let major = value / 100
        let minor = (value % 100) / 10
        return minor == 0 ? "Xcode \(major)" : "Xcode \(major).\(minor)"
    }

    private static func infoString(_ key: String, fallbackKey: String? = nil) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, value.isEmpty == false {
            return value
        }
        if let fallbackKey,
           let value = Bundle.main.object(forInfoDictionaryKey: fallbackKey) as? String,
           value.isEmpty == false
        {
            return value
        }
        return unknown
    }

    private static var unknown: String {
        BaL10n.string("ba.about.version.unknown")
    }
}
