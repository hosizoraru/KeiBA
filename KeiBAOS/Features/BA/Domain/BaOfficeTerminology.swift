//
//  BaOfficeTerminology.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import Foundation

nonisolated enum BaOfficeTerminology {
    static func overviewTitle(for settings: BaAppSettings) -> String {
        guard settings.appLanguage.usesSimplifiedChineseTerminology else {
            return BaL10n.string("ba.office.overview.title", language: settings.appLanguage)
        }
        return String(
            format: BaL10n.string("ba.office.overview.title.format", language: settings.appLanguage),
            officeName(for: settings.server, appLanguage: settings.appLanguage)
        )
    }

    static func officeName(for server: BaServer, appLanguage: BaAppLanguage) -> String {
        guard appLanguage.usesSimplifiedChineseTerminology else {
            return BaL10n.string("ba.office.name.default", language: appLanguage)
        }
        return BaL10n.string(server.simplifiedChineseOfficeNameKey, language: appLanguage)
    }
}

private extension BaServer {
    nonisolated var simplifiedChineseOfficeNameKey: String {
        switch self {
        case .cn:
            "ba.office.name.cn"
        case .global:
            "ba.office.name.global"
        case .jp:
            "ba.office.name.jp"
        }
    }
}

private extension BaAppLanguage {
    nonisolated var usesSimplifiedChineseTerminology: Bool {
        switch self {
        case .simplifiedChinese:
            true
        case .system:
            Locale.autoupdatingCurrent.baUsesSimplifiedChinese
        case .english, .japanese:
            false
        }
    }
}

private extension Locale {
    nonisolated var baUsesSimplifiedChinese: Bool {
        guard language.languageCode?.identifier == "zh" else { return false }
        if language.script?.identifier == "Hans" {
            return true
        }
        let regionIdentifier = region?.identifier
        return regionIdentifier == "CN" || regionIdentifier == "SG"
    }
}
