//
//  BaVoiceDisplayModel.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated struct BaVoiceSectionFilter: Identifiable, Hashable {
    let section: String?

    var id: String {
        section ?? "__all"
    }

    var title: String {
        guard let section, section.isEmpty == false else {
            return String(localized: "ba.student.detail.voice.filter.all")
        }
        return section
    }

    static let all = BaVoiceSectionFilter(section: nil)

    static func filters(for entries: [BaGuideVoiceEntry]) -> [BaVoiceSectionFilter] {
        var seen = Set<String>()
        let sections = entries.compactMap { entry -> String? in
            let value = entry.section?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard value.isEmpty == false, seen.insert(value).inserted else { return nil }
            return value
        }
        return [.all] + sections.map { BaVoiceSectionFilter(section: $0) }
    }

    func includes(_ entry: BaGuideVoiceEntry) -> Bool {
        guard let section else { return true }
        return entry.section?.trimmingCharacters(in: .whitespacesAndNewlines) == section
    }
}

nonisolated enum BaVoiceDisplayModel {
    static func filteredEntries(
        _ entries: [BaGuideVoiceEntry],
        filter: BaVoiceSectionFilter,
        query: String,
        fallbackHeaders: [String]
    ) -> [BaGuideVoiceEntry] {
        let normalizedQuery = normalizedSearchText(query)
        return entries.filter { entry in
            filter.includes(entry) && (
                normalizedQuery.isEmpty ||
                    matches(entry: entry, query: normalizedQuery, fallbackHeaders: fallbackHeaders)
            )
        }
    }

    static func selectedLine(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String],
        selectedLanguage: String
    ) -> BaVoiceLinePair? {
        let selected = BaVoiceLanguageResolver.canonicalLanguageLabel(selectedLanguage)
        let pairs = BaVoiceLanguageResolver.linePairs(for: entry, fallbackHeaders: fallbackHeaders)
        let line = pairs.first {
            BaVoiceLanguageResolver.canonicalLanguageLabel($0.language) == selected
        }
        if selected.isEmpty == false, let line {
            return line
        }
        return pairs.first { isOfficialTranslation($0.language) == false } ?? pairs.first
    }

    static func officialLine(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String]
    ) -> BaVoiceLinePair? {
        BaVoiceLanguageResolver
            .linePairs(for: entry, fallbackHeaders: fallbackHeaders)
            .first { isOfficialTranslation($0.language) }
    }

    static func secondaryLines(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String],
        selectedLanguage: String
    ) -> [BaVoiceLinePair] {
        let selected = selectedLine(
            for: entry,
            fallbackHeaders: fallbackHeaders,
            selectedLanguage: selectedLanguage
        )
        return BaVoiceLanguageResolver
            .linePairs(for: entry, fallbackHeaders: fallbackHeaders)
            .filter { pair in
                pair != selected && isOfficialTranslation(pair.language) == false
            }
    }

    static func copySelectedText(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String],
        selectedLanguage: String
    ) -> String {
        if let selected = selectedLine(
            for: entry,
            fallbackHeaders: fallbackHeaders,
            selectedLanguage: selectedLanguage
        ) {
            let title = BaVoiceLabelFormatter.entryTitle(entry.title)
            let language = BaVoiceLabelFormatter.languageTitle(selected.language)
            return "\(title)\n\(language): \(selected.text)"
        }
        return copyAllText(for: entry, fallbackHeaders: fallbackHeaders)
    }

    static func copyAllText(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String]
    ) -> String {
        var lines = [BaVoiceLabelFormatter.entryTitle(entry.title)]
        if let section = entry.section?.trimmingCharacters(in: .whitespacesAndNewlines), section.isEmpty == false {
            lines.insert(section, at: 0)
        }
        lines += BaVoiceLanguageResolver
            .linePairs(for: entry, fallbackHeaders: fallbackHeaders)
            .map { "\(BaVoiceLabelFormatter.languageTitle($0.language)): \($0.text)" }
        return lines.joined(separator: "\n")
    }

    static func audioFormatTitle(for url: URL?) -> String? {
        guard let url else { return nil }
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if ext.isEmpty {
            return String(localized: "ba.student.detail.voice.audio.format")
        }
        return ext.uppercased()
    }

    static func audioCount(for entry: BaGuideVoiceEntry) -> Int {
        let urls = entry.audioURLs ?? []
        if urls.isEmpty == false { return urls.count }
        return entry.audioURL == nil ? 0 : 1
    }

    static func matches(
        entry: BaGuideVoiceEntry,
        query: String,
        fallbackHeaders: [String]
    ) -> Bool {
        var parts = [entry.title, entry.subtitle, entry.section ?? "", entry.transcript]
        let voiceText = BaVoiceLanguageResolver
            .linePairs(for: entry, fallbackHeaders: fallbackHeaders)
            .map { "\($0.language) \($0.text)" }
            .joined(separator: " ")
        parts.append(voiceText)
        let haystack = parts.joined(separator: " ")
        return normalizedSearchText(haystack).contains(query)
    }

    static func nowPlayingEntry(
        entries: [BaGuideVoiceEntry],
        currentURL: URL?
    ) -> BaGuideVoiceEntry? {
        guard let currentURL else { return nil }
        return entries.first { entry in
            if entry.audioURL == currentURL { return true }
            return entry.audioURLs?.contains(currentURL) == true
        }
    }

    static func isOfficialTranslation(_ label: String) -> Bool {
        BaVoiceLanguageResolver.canonicalLanguageLabel(label) == "官翻"
    }

    private static func normalizedSearchText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
