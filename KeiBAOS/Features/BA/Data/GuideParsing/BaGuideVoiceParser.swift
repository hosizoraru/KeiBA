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

            let isVoiceCategory = isVoiceCategoryKey(key)
            let section: String
            if isVoiceCategory {
                currentSection = key
                section = key
            } else {
                guard currentSection.isEmpty == false else { continue }
                section = currentSection
            }

            let rowContent = parseVoiceRowCells(
                row.dropFirst(),
                defaultTitle: key,
                canAssignTitle: isVoiceCategory,
                sourceURL: sourceURL
            )
            let audioURLs = BaGuideTextNormalizer.dedupe(rowContent.audioURLs)
            let records = voiceLineRecords(
                textByAudioSegment: rowContent.textByAudioSegment,
                headers: languageHeaders,
                audioURLs: audioURLs
            )
            let alignedAudioURLs = alignedAudioURLs(records: records, audioURLs: audioURLs)
            guard records.isEmpty == false || audioURLs.isEmpty == false else { continue }
            entries.append(
                BaGuideVoiceEntry(
                    id: "voice-\(rowIndex)-\(abs("\(section)|\(rowContent.title)".hashValue))",
                    title: rowContent.title,
                    subtitle: section,
                    transcript: records.map(\.text).joined(separator: "\n"),
                    audioURL: alignedAudioURLs.first ?? audioURLs.first,
                    section: section,
                    lineHeaders: records.map(\.label),
                    lines: records.map(\.text),
                    audioURLs: alignedAudioURLs.isEmpty ? nil : alignedAudioURLs
                )
            )
        }
        return entries
    }

    private func parseVoiceRowCells(
        _ cells: ArraySlice<BaJSONObject>,
        defaultTitle: String,
        canAssignTitle: Bool,
        sourceURL: URL?
    ) -> ParsedVoiceRowContent {
        var title = defaultTitle
        var titleAssigned = false
        var textByAudioSegment: [Int: [String]] = [:]
        var audioURLs: [URL] = []

        func appendAudio(from cell: BaJSONObject, rawValue: String) {
            for url in extractAudioURLs(in: cell, rawValue: rawValue, sourceURL: sourceURL)
                where audioURLs.contains(url) == false
            {
                audioURLs.append(url)
            }
        }

        for cell in cells {
            let rawValue = cell.string("value") ?? ""
            let cleaned = BaGuideTextNormalizer.clean(rawValue)
            let type = (cell.string("type") ?? "").lowercased()
            if type == "audio" {
                appendAudio(from: cell, rawValue: rawValue)
                continue
            }
            guard cleaned.isEmpty == false, shouldDisplayVoiceText(cleaned) else { continue }
            if canAssignTitle, titleAssigned == false {
                title = cleaned
                titleAssigned = true
            } else {
                textByAudioSegment[audioURLs.count, default: []].append(cleaned)
                appendAudio(from: cell, rawValue: rawValue)
            }
        }

        return ParsedVoiceRowContent(title: title, textByAudioSegment: textByAudioSegment, audioURLs: audioURLs)
    }

    private func extractAudioURLs(in cell: BaJSONObject, rawValue: String, sourceURL: URL?) -> [URL] {
        var urls = BaGuideTextNormalizer.audioURLs(in: cell["value"], sourceURL: sourceURL)
        let type = (cell.string("type") ?? "").lowercased()
        if type == "audio",
           let direct = BaGuideTextNormalizer.normalizeMediaURL(rawValue, sourceURL: sourceURL),
           BaGuideTextNormalizer.looksLikeAudioURL(direct)
        {
            urls.append(direct)
        }
        return urls
    }

    private func shouldDisplayVoiceText(_ raw: String) -> Bool {
        guard let url = BaGuideTextNormalizer.normalizeMediaURL(raw, sourceURL: nil) else {
            return true
        }
        return BaGuideTextNormalizer.looksLikeAudioURL(url) == false
    }

    private func voiceLineRecords(
        textByAudioSegment: [Int: [String]],
        headers: [String],
        audioURLs: [URL]
    ) -> [VoiceLineRecord] {
        let maxTextCount = textByAudioSegment.values.map(\.count).max() ?? 0
        let dubbingCount = max(headers.count, audioURLs.count, maxTextCount)
        guard dubbingCount > 0 else {
            return []
        }

        var remainingText = textByAudioSegment
        var dubbingTexts = Array(repeating: "", count: dubbingCount)
        var segmentZero = remainingText[0] ?? []
        for index in dubbingTexts.indices where segmentZero.isEmpty == false {
            dubbingTexts[index] = segmentZero.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        remainingText[0] = segmentZero

        for index in dubbingTexts.indices where dubbingTexts[index].isEmpty {
            var bucket = remainingText[index] ?? []
            if bucket.isEmpty == false {
                dubbingTexts[index] = bucket.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                remainingText[index] = bucket
            }
        }

        let officialTranslation = remainingText
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.isEmpty == false } ?? ""

        var records: [VoiceLineRecord] = []
        let labels = normalizedHeaders(headers: headers, count: dubbingCount)
        for index in dubbingTexts.indices {
            let text = dubbingTexts[index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.isEmpty == false else { continue }
            let label = labels.indices.contains(index) ? labels[index] : defaultLanguageLabel(index)
            records.append(
                VoiceLineRecord(
                    label: canonicalLanguageLabel(label).ifBlank(label),
                    text: text,
                    audioIndex: index
                )
            )
        }
        if officialTranslation.isEmpty == false {
            records.append(
                VoiceLineRecord(
                    label: "官翻",
                    text: officialTranslation,
                    audioIndex: nil
                )
            )
        }

        return records
            .enumerated()
            .sorted { lhs, rhs in
                let lhsPriority = voicePriority(lhs.element.label)
                let rhsPriority = voicePriority(rhs.element.label)
                return lhsPriority < rhsPriority || (lhsPriority == rhsPriority && lhs.offset < rhs.offset)
            }
            .map(\.element)
    }

    private func alignedAudioURLs(records: [VoiceLineRecord], audioURLs: [URL]) -> [URL] {
        guard audioURLs.isEmpty == false else { return [] }
        var used = Set<Int>()
        var indexes: [Int] = records.compactMap { record in
            guard let index = record.audioIndex,
                  audioURLs.indices.contains(index),
                  used.insert(index).inserted
            else {
                return nil
            }
            return index
        }
        indexes.append(contentsOf: audioURLs.indices.filter { used.contains($0) == false })
        return indexes.map { audioURLs[$0] }
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

    private struct ParsedVoiceRowContent {
        let title: String
        let textByAudioSegment: [Int: [String]]
        let audioURLs: [URL]
    }

    private struct VoiceLineRecord {
        let label: String
        let text: String
        let audioIndex: Int?
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
