//
//  BaLocalization.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation
import SwiftUI

nonisolated enum BaAppLanguage: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case system
    case english
    case simplifiedChinese
    case japanese

    var id: Self {
        self
    }

    var titleResource: LocalizedStringResource {
        switch self {
        case .system:
            "ba.settings.language.system"
        case .english:
            "ba.settings.language.english"
        case .simplifiedChinese:
            "ba.settings.language.simplifiedChinese"
        case .japanese:
            "ba.settings.language.japanese"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        case .japanese:
            "ja"
        }
    }

    var locale: Locale {
        localeIdentifier.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
    }

    var localizationLanguage: Locale.Language? {
        localeIdentifier.map(Locale.Language.init(identifier:))
    }
}

nonisolated enum BaAppAppearance: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case system
    case light
    case dark

    var id: Self {
        self
    }

    var titleResource: LocalizedStringResource {
        switch self {
        case .system:
            "ba.settings.appearance.system"
        case .light:
            "ba.settings.appearance.light"
        case .dark:
            "ba.settings.appearance.dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

nonisolated enum BaL10n {
    private static let appLanguageOverrideKey = "ba.app.localization.language.v1"
    private static let appLanguageLock = NSLock()
    nonisolated(unsafe) private static var cachedAppLanguage: BaAppLanguage?

    static func configure(appLanguage: BaAppLanguage) {
        switch appLanguage {
        case .system:
            UserDefaults.standard.removeObject(forKey: appLanguageOverrideKey)
        default:
            UserDefaults.standard.set(appLanguage.rawValue, forKey: appLanguageOverrideKey)
        }
        setCachedAppLanguage(appLanguage)
    }

    static func string(_ key: String, table: String? = nil, bundle: Bundle = .main) -> String {
        string(key, language: configuredAppLanguage, table: table, bundle: bundle)
    }

    static func string(
        _ key: String,
        language: BaAppLanguage,
        table: String? = nil,
        bundle: Bundle = .main
    ) -> String {
        if let localizationLanguage = language.localizationLanguage {
            return bundle.localizedString(
                forKey: key,
                value: key,
                table: table,
                localizations: [localizationLanguage]
            )
        }
        return bundle.localizedString(forKey: key, value: key, table: table)
    }

    private static var configuredAppLanguage: BaAppLanguage {
        if let cached = cachedAppLanguageValue() {
            return cached
        }
        guard let rawValue = UserDefaults.standard.string(forKey: appLanguageOverrideKey),
              let language = BaAppLanguage(rawValue: rawValue)
        else {
            setCachedAppLanguage(.system)
            return .system
        }
        setCachedAppLanguage(language)
        return language
    }

    private static func cachedAppLanguageValue() -> BaAppLanguage? {
        appLanguageLock.lock()
        defer { appLanguageLock.unlock() }
        return cachedAppLanguage
    }

    private static func setCachedAppLanguage(_ language: BaAppLanguage) {
        appLanguageLock.lock()
        cachedAppLanguage = language
        appLanguageLock.unlock()
    }
}
