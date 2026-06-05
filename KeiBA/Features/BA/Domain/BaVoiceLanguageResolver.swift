//
//  BaVoiceLanguageResolver.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated struct BaVoiceLinePair: Identifiable, Hashable {
    let language: String
    let text: String

    var id: String {
        "\(language)|\(text)"
    }
}

nonisolated enum BaVoiceLanguageResolver {
    static func displayHeaders(
        for entries: [BaGuideVoiceEntry],
        preferredHeaders: [String] = []
    ) -> [String] {
        var headers: [String] = []
        for header in preferredHeaders {
            appendHeader(header, to: &headers, includeOfficialTranslation: false)
        }
        for entry in entries {
            for header in entry.lineHeaders ?? [] {
                appendHeader(header, to: &headers, includeOfficialTranslation: false)
            }
            for header in entry.audioHeaders ?? [] {
                appendHeader(header, to: &headers, includeOfficialTranslation: false)
            }
        }
        let maxAudioCount = entries.map(audioCount).max() ?? 0
        while headers.count < maxAudioCount {
            let fallback = defaultLanguageLabel(headers.count)
            headers.append(headers.contains(fallback) ? localizedLanguageLabel(headers.count) : fallback)
        }
        return headers
    }

    static func playableHeaders(
        for entries: [BaGuideVoiceEntry],
        preferredHeaders: [String] = []
    ) -> [String] {
        let headers = displayHeaders(for: entries, preferredHeaders: preferredHeaders)
        return headers.filter { header in
            entries.contains {
                directPlaybackURL(for: $0, headers: headers, selectedHeader: header) != nil
            }
        }
    }

    static func playbackHeaders(for entries: [BaGuideVoiceEntry]) -> [String] {
        playableHeaders(for: entries)
    }

    static func directPlaybackURL(
        for entry: BaGuideVoiceEntry,
        headers: [String],
        selectedHeader: String
    ) -> URL? {
        let selected = canonicalLanguageLabel(selectedHeader)
        guard selected.isEmpty == false else { return nil }
        if let audioHeaders = entry.audioHeaders,
           let audioURLs = entry.audioURLs,
           let index = audioHeaders.firstIndex(where: { canonicalLanguageLabel($0) == selected }),
           audioURLs.indices.contains(index)
        {
            return audioURLs[index]
        }
        if entry.audioHeaders == nil,
           let index = headers.firstIndex(where: { canonicalLanguageLabel($0) == selected }),
           let url = entry.audioURLs?.indices.contains(index) == true ? entry.audioURLs?[index] : nil
        {
            return url
        }
        if entry.audioHeaders == nil,
           entry.audioURLs?.isEmpty != false,
           selected == canonicalLanguageLabel(headers.first ?? ""),
           let url = entry.audioURL
        {
            return url
        }
        return nil
    }

    static func fallbackPlaybackURL(for entry: BaGuideVoiceEntry) -> URL? {
        if let url = entry.audioURLs?.first(where: { $0.absoluteString.isEmpty == false }) {
            return url
        }
        return entry.audioURL
    }

    static func playbackURL(
        for entry: BaGuideVoiceEntry,
        headers: [String],
        selectedHeader: String
    ) -> URL? {
        directPlaybackURL(for: entry, headers: headers, selectedHeader: selectedHeader)
    }

    static func linePairs(
        for entry: BaGuideVoiceEntry,
        fallbackHeaders: [String]
    ) -> [BaVoiceLinePair] {
        let explicit = if let lineHeaders = entry.lineHeaders,
                          let lines = entry.lines,
                          lineHeaders.count == lines.count,
                          lineHeaders.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false })
        {
            Array(zip(lineHeaders, lines))
        } else {
            [(String, String)]()
        }
        let rawPairs = explicit.isEmpty ? fallbackPairs(entry: entry, headers: fallbackHeaders) : explicit
        return rawPairs.enumerated()
            .compactMap { index, pair -> (BaVoiceLinePair, Int)? in
                let label = pair.0.trimmingCharacters(in: .whitespacesAndNewlines)
                let text = pair.1.trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.isEmpty == false else { return nil }
                let normalized = canonicalLanguageLabel(label).ifBlank(label)
                return (BaVoiceLinePair(language: normalized, text: text), index)
            }
            .sorted { lhs, rhs in
                let priority = voicePriority(lhs.0.language) < voicePriority(rhs.0.language)
                return priority || (voicePriority(lhs.0.language) == voicePriority(rhs.0.language) && lhs.1 < rhs.1)
            }
            .map(\.0)
    }

    static func canonicalLanguageLabel(_ raw: String) -> String {
        let normalized = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else { return "" }
        if normalized.contains("官翻") ||
            normalized.contains("官方翻译") ||
            normalized.contains("官方中文") ||
            normalized.contains("官中")
        {
            return "官翻"
        }
        if normalized.contains("韩") ||
            normalized.contains("kr") ||
            normalized.contains("kor") ||
            normalized.contains("korean")
        {
            return "韩配"
        }
        if normalized.contains("中") ||
            normalized.contains("cn") ||
            normalized.contains("国语") ||
            normalized.contains("国配") ||
            normalized.contains("中文")
        {
            return "中配"
        }
        if normalized.contains("日") ||
            normalized.contains("jp") ||
            normalized.contains("jpn") ||
            normalized.contains("日本")
        {
            return "日配"
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func appendHeader(
        _ raw: String,
        to headers: inout [String],
        includeOfficialTranslation: Bool
    ) {
        let normalized = canonicalLanguageLabel(raw)
        guard normalized.isEmpty == false else { return }
        guard includeOfficialTranslation || normalized != "官翻" else { return }
        if headers.contains(normalized) == false {
            headers.append(normalized)
        }
    }

    private static func audioCount(_ entry: BaGuideVoiceEntry) -> Int {
        max(entry.audioURLs?.count ?? 0, entry.audioURL == nil ? 0 : 1)
    }

    private static func fallbackPairs(entry: BaGuideVoiceEntry, headers: [String]) -> [(String, String)] {
        if let lines = entry.lines {
            return lines.enumerated().map { index, line in
                (headers.indices.contains(index) ? headers[index] : defaultLanguageLabel(index), line)
            }
        }
        if entry.transcript.isEmpty == false {
            return [(headers.first ?? defaultLanguageLabel(0), entry.transcript)]
        }
        return []
    }

    private static func defaultLanguageLabel(_ index: Int) -> String {
        switch index {
        case 0:
            "日配"
        case 1:
            "中配"
        case 2:
            "韩配"
        default:
            localizedLanguageLabel(index)
        }
    }

    private static func localizedLanguageLabel(_ index: Int) -> String {
        String(format: BaL10n.string("ba.student.detail.voice.language.format"), index + 1)
    }

    private static func voicePriority(_ label: String) -> Int {
        switch canonicalLanguageLabel(label) {
        case "日配":
            0
        case "中配":
            1
        case "官翻":
            2
        case "韩配":
            3
        default:
            4
        }
    }
}

private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
