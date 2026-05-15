//
//  BaGuideVoiceParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated struct BaGuideVoiceParseResult: Hashable {
    let languageHeaders: [String]
    let entries: [BaGuideVoiceEntry]
}

struct BaGuideVoiceParser {
    func parse(baseData: [[BaJSONObject]], content: Any?, sourceURL: URL?) -> BaGuideVoiceParseResult {
        let structured = parseBaseData(baseData, sourceURL: sourceURL)
        if structured.entries.isEmpty == false {
            return structured
        }
        let audioURLs = BaGuideTextNormalizer.audioURLs(in: content, sourceURL: sourceURL)
        let headers = languageHeaders(rawHeaders: [], entriesAudioCounts: audioURLs.isEmpty ? [] : [audioURLs.count])
        let entries = audioURLs.enumerated().map { index, url in
            BaGuideVoiceEntry(
                id: "voice-url-\(index)",
                title: String(format: String(localized: "ba.student.detail.voice.item.format"), index + 1),
                subtitle: url.lastPathComponent,
                transcript: "",
                audioURL: url,
                section: nil,
                lineHeaders: nil,
                lines: nil,
                audioURLs: [url],
                audioHeaders: [defaultLanguageLabel(index)]
            )
        }
        return BaGuideVoiceParseResult(languageHeaders: headers, entries: entries)
    }

    private func parseBaseData(_ baseData: [[BaJSONObject]], sourceURL: URL?) -> BaGuideVoiceParseResult {
        var rawLanguageHeaders: [String] = []
        var entries: [BaGuideVoiceEntry] = []
        var inVoiceBlock = false
        var currentSection = ""

        for (rowIndex, row) in baseData.enumerated() {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            if key == "配音语言" {
                inVoiceBlock = true
                currentSection = ""
                rawLanguageHeaders = row.dropFirst()
                    .compactMap { $0.string("value") }
                    .map(canonicalLanguageLabel)
                    .filter { $0.isEmpty == false && $0 != "官翻" }
                rawLanguageHeaders = unique(rawLanguageHeaders)
                continue
            }
            guard inVoiceBlock else { continue }
            if key.isEmpty || key == "配音" || key == "配音大类" {
                continue
            }

            let isVoiceCategory = isVoiceCategoryKey(key)
            if isVoiceCategory {
                currentSection = key
            } else {
                if entries.isEmpty == false, isVoiceBlockTailKey(key) {
                    break
                }
                guard currentSection.isEmpty == false else { continue }
            }
            let section = isVoiceCategory ? key : currentSection
            guard section.isEmpty == false else { continue }

            let rowContent = parseVoiceRowCells(
                row.dropFirst(),
                defaultTitle: key,
                assignFirstTextAsTitle: isVoiceCategory,
                sourceURL: sourceURL
            )
            let audioURLs = BaGuideTextNormalizer.dedupe(rowContent.audioURLs)
            let records = voiceLineRecords(
                textByAudioSegment: rowContent.textByAudioSegment,
                headers: rawLanguageHeaders,
                audioURLs: audioURLs
            )
            let alignedAudio = alignedAudio(
                records: records,
                audioURLs: audioURLs,
                headers: rawLanguageHeaders
            )
            guard records.isEmpty == false || audioURLs.isEmpty == false else { continue }
            entries.append(
                BaGuideVoiceEntry(
                    id: "voice-\(rowIndex)-\(abs("\(section)|\(rowContent.title)".hashValue))",
                    title: rowContent.title,
                    subtitle: section,
                    transcript: records.map(\.text).joined(separator: "\n"),
                    audioURL: alignedAudio.urls.first,
                    section: section,
                    lineHeaders: records.map(\.label),
                    lines: records.map(\.text),
                    audioURLs: alignedAudio.urls.isEmpty ? nil : alignedAudio.urls,
                    audioHeaders: alignedAudio.headers.isEmpty ? nil : alignedAudio.headers
                )
            )
        }

        let headers = languageHeaders(
            rawHeaders: rawLanguageHeaders,
            entriesAudioCounts: entries.map { $0.audioURLs?.count ?? ($0.audioURL == nil ? 0 : 1) }
        )
        return BaGuideVoiceParseResult(languageHeaders: headers, entries: entries)
    }

    private func parseVoiceRowCells(
        _ cells: ArraySlice<BaJSONObject>,
        defaultTitle: String,
        assignFirstTextAsTitle: Bool,
        sourceURL: URL?
    ) -> ParsedVoiceRowContent {
        var title = defaultTitle
        var titleAssigned = assignFirstTextAsTitle == false
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
            guard cleaned.isEmpty == false else { continue }
            if shouldDisplayVoiceText(cleaned) == false {
                appendAudio(from: cell, rawValue: rawValue)
                continue
            }
            if titleAssigned == false {
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
        let dubbingCount = max(headers.count, audioURLs.count)
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

    private func alignedAudio(
        records: [VoiceLineRecord],
        audioURLs: [URL],
        headers: [String]
    ) -> (urls: [URL], headers: [String]) {
        guard audioURLs.isEmpty == false else { return ([], []) }
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
        let labels = normalizedHeaders(headers: headers, count: audioURLs.count)
        return (
            indexes.map { audioURLs[$0] },
            indexes.map { labels.indices.contains($0) ? labels[$0] : defaultLanguageLabel($0) }
        )
    }

    private func languageHeaders(rawHeaders: [String], entriesAudioCounts: [Int]) -> [String] {
        var out = rawHeaders
        let headerCount = max(out.count, entriesAudioCounts.max() ?? 0)
        while out.count < headerCount {
            let fallback = defaultLanguageLabel(out.count)
            out.append(out.contains(fallback) ? localizedLanguageLabel(out.count) : fallback)
        }
        return out
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
            localizedLanguageLabel(index)
        }
    }

    private func localizedLanguageLabel(_ index: Int) -> String {
        String(format: String(localized: "ba.student.detail.voice.language.format"), index + 1)
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
