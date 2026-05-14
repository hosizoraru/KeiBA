//
//  BaGuideVoiceParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideVoiceParser {
    func parse(baseData: [[BaJSONObject]], content: Any?, sourceURL: URL?) -> [BaGuideVoiceEntry] {
        let structured = parseBaseData(baseData, sourceURL: sourceURL)
        if structured.isEmpty == false {
            return structured
        }
        return BaGuideTextNormalizer.audioURLs(in: content, sourceURL: sourceURL)
            .enumerated()
            .map { index, url in
                BaGuideVoiceEntry(
                    id: "voice-url-\(index)",
                    title: String(format: String(localized: "ba.student.detail.voice.item.format"), index + 1),
                    subtitle: url.lastPathComponent,
                    transcript: "",
                    audioURL: url,
                    section: nil,
                    lineHeaders: nil,
                    lines: nil,
                    audioURLs: [url]
                )
            }
    }

    private func parseBaseData(_ baseData: [[BaJSONObject]], sourceURL: URL?) -> [BaGuideVoiceEntry] {
        var languageHeaders: [String] = []
        var entries: [BaGuideVoiceEntry] = []
        var inVoiceBlock = false
        var currentSection = ""

        for (rowIndex, row) in baseData.enumerated() {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            if key == "配音语言" {
                inVoiceBlock = true
                currentSection = ""
                languageHeaders = row.dropFirst()
                    .compactMap { $0.string("value") }
                    .map(canonicalLanguageLabel)
                    .filter { $0.isEmpty == false && $0 != "官翻" }
                languageHeaders = unique(languageHeaders)
                continue
            }
            guard inVoiceBlock else { continue }
            if key.isEmpty || key == "配音" || key == "配音大类" {
                continue
            }
            if entries.isEmpty == false, isVoiceBlockTailKey(key) {
                break
            }

            let section: String
            if isVoiceCategoryKey(key) {
                currentSection = key
                section = key
            } else {
                guard currentSection.isEmpty == false else { continue }
                section = currentSection
            }

            var title = key
            var titleAssigned = false
            var lines: [String] = []
            var audioURLs: [URL] = []
            for cell in row.dropFirst() {
                let rawValue = cell.string("value") ?? ""
                let type = (cell.string("type") ?? "").lowercased()
                let cleaned = BaGuideTextNormalizer.clean(rawValue)
                let directAudios = BaGuideTextNormalizer.audioURLs(in: cell["value"], sourceURL: sourceURL)
                audioURLs.append(contentsOf: directAudios)
                if type == "audio", let direct = BaGuideTextNormalizer.normalizeMediaURL(rawValue, sourceURL: sourceURL), BaGuideTextNormalizer.looksLikeAudioURL(direct) {
                    audioURLs.append(direct)
                }
                guard cleaned.isEmpty == false else { continue }
                if titleAssigned == false, isVoiceCategoryKey(key) == false {
                    title = cleaned
                    titleAssigned = true
                } else {
                    lines.append(cleaned)
                }
            }
            audioURLs = BaGuideTextNormalizer.dedupe(audioURLs)
            let linePairs = linePairs(lines: lines, headers: languageHeaders, audioCount: audioURLs.count)
            guard linePairs.isEmpty == false || audioURLs.isEmpty == false else { continue }
            entries.append(
                BaGuideVoiceEntry(
                    id: "voice-\(rowIndex)-\(abs("\(section)|\(title)".hashValue))",
                    title: title,
                    subtitle: section,
                    transcript: linePairs.map(\.1).joined(separator: "\n"),
                    audioURL: audioURLs.first,
                    section: section,
                    lineHeaders: linePairs.map(\.0),
                    lines: linePairs.map(\.1),
                    audioURLs: audioURLs.isEmpty ? nil : audioURLs
                )
            )
        }
        return entries
    }

    private func linePairs(lines: [String], headers: [String], audioCount: Int) -> [(String, String)] {
        let labels = normalizedHeaders(headers: headers, count: max(lines.count, audioCount))
        return lines.enumerated()
            .map { index, line in
                (labels.indices.contains(index) ? labels[index] : defaultLanguageLabel(index), line)
            }
            .map { pair in
                (canonicalLanguageLabel(pair.0).ifBlank(pair.0), pair.1)
            }
            .sorted { lhs, rhs in
                voicePriority(lhs.0) < voicePriority(rhs.0)
            }
    }

    private func normalizedHeaders(headers: [String], count: Int) -> [String] {
        var out = headers
        while out.count < count {
            out.append(defaultLanguageLabel(out.count))
        }
        return out
    }

    private func canonicalLanguageLabel(_ raw: String) -> String {
        let normalized = BaGuideTextNormalizer.normalizedKey(raw)
        if normalized.isEmpty { return "" }
        if normalized.contains("官翻") || normalized.contains("官方翻译") || normalized.contains("官方中文") || normalized.contains("官中") {
            return "官翻"
        }
        if normalized.contains("韩") || normalized.contains("kr") || normalized.contains("kor") || normalized.contains("korean") {
            return "韩配"
        }
        if normalized.contains("中") || normalized.contains("cn") || normalized.contains("国语") || normalized.contains("国配") || normalized.contains("中文") {
            return "中配"
        }
        if normalized.contains("日") || normalized.contains("jp") || normalized.contains("jpn") || normalized.contains("日本") {
            return "日配"
        }
        return BaGuideTextNormalizer.clean(raw)
    }

    private func defaultLanguageLabel(_ index: Int) -> String {
        switch index {
        case 0:
            "日配"
        case 1:
            "中配"
        case 2:
            "韩配"
        default:
            String(format: String(localized: "ba.student.detail.voice.language.format"), index + 1)
        }
    }

    private func voicePriority(_ label: String) -> Int {
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

    private func isVoiceCategoryKey(_ raw: String) -> Bool {
        BaGuideTextNormalizer.containsAny(raw, tokens: ["通常", "战斗", "活动", "大厅", "咖啡馆", "事件", "好感度", "成长", "MomoTalk"])
    }

    private func isVoiceBlockTailKey(_ raw: String) -> Bool {
        BaGuideTextNormalizer.containsAny(raw, tokens: ["技能", "专武", "爱用品", "能力解放", "装备", "礼物偏好", "角色表情", "回忆大厅", "立绘"])
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
