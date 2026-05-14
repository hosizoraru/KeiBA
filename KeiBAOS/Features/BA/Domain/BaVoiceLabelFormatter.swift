//
//  BaVoiceLabelFormatter.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated enum BaVoiceLabelFormatter {
    static func languageTitle(_ header: String) -> String {
        let canonical = BaVoiceLanguageResolver.canonicalLanguageLabel(header)
        switch canonical {
        case "日配":
            return String(localized: "ba.student.detail.voice.language.jp")
        case "中配":
            return String(localized: "ba.student.detail.voice.language.cn")
        case "韩配":
            return String(localized: "ba.student.detail.voice.language.kr")
        case "官翻":
            return String(localized: "ba.student.detail.voice.language.official")
        default:
            if let index = languageIndex(from: canonical.isEmpty ? header : canonical) {
                return String(format: String(localized: "ba.student.detail.voice.language.format"), index)
            }
            return header.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func entryTitle(_ raw: String) -> String {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = lookupKey(clean)
        if let index = suffixNumber(in: normalized, prefix: "成长台词") {
            return String(format: String(localized: "ba.student.detail.voice.growthTitle.format"), index)
        }
        if normalized.isEmpty {
            return String(localized: "ba.student.detail.voice.entry")
        }
        if normalized == "语音条目" {
            return String(localized: "ba.student.detail.voice.entry")
        }
        return clean
    }

    private static func lookupKey(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
    }

    private static func languageIndex(from raw: String) -> Int? {
        let normalized = lookupKey(raw).lowercased()
        return suffixNumber(in: normalized, prefix: "语言")
    }

    private static func suffixNumber(in raw: String, prefix: String) -> Int? {
        guard raw.hasPrefix(prefix) else { return nil }
        let suffix = raw.dropFirst(prefix.count)
        guard suffix.isEmpty == false,
              suffix.allSatisfy(\.isNumber)
        else {
            return nil
        }
        return Int(suffix)
    }
}
