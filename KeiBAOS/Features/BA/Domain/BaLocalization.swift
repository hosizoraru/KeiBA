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
    private nonisolated static let appLanguageCache = BaLockedAppLanguageCache()
    private static let appBundle = Bundle(for: BaLocalizationBundleToken.self)

    static func configure(appLanguage: BaAppLanguage) {
        setCachedAppLanguage(appLanguage)
    }

    static func string(_ key: String, table: String? = nil, bundle: Bundle? = nil) -> String {
        string(key, language: configuredAppLanguage, table: table, bundle: bundle)
    }

    static func string(
        _ key: String,
        language: BaAppLanguage,
        table: String? = nil,
        bundle: Bundle? = nil
    ) -> String {
        let bundle = bundle ?? (language == .system ? .main : appBundle)
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
        setCachedAppLanguage(.system)
        return .system
    }

    private static func cachedAppLanguageValue() -> BaAppLanguage? {
        appLanguageCache.value
    }

    private static func setCachedAppLanguage(_ language: BaAppLanguage) {
        appLanguageCache.store(language)
    }
}

private nonisolated final class BaLockedAppLanguageCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cachedLanguage: BaAppLanguage?

    var value: BaAppLanguage? {
        lock.lock()
        defer { lock.unlock() }
        return cachedLanguage
    }

    func store(_ language: BaAppLanguage) {
        lock.lock()
        cachedLanguage = language
        lock.unlock()
    }
}

private final class BaLocalizationBundleToken: NSObject {}
