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
        let audioInfo = parseAudioInfo(content, sourceURL: sourceURL)
        if audioInfo.entries.isEmpty == false {
            return audioInfo
        }
        let audioURLs = BaGuideTextNormalizer.audioURLs(in: content, sourceURL: sourceURL)
        let headers = languageHeaders(rawHeaders: [], entriesAudioCounts: audioURLs.isEmpty ? [] : [audioURLs.count])
        let entries = audioURLs.enumerated().map { index, url in
            BaGuideVoiceEntry(
                id: "voice-url-\(index)",
                title: String(format: BaL10n.string("ba.student.detail.voice.item.format"), index + 1),
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

    private func parseAudioInfo(_ content: Any?, sourceURL: URL?) -> BaGuideVoiceParseResult {
        var rawLanguageHeaders: [String] = []
        var accumulators: [String: ArrayVoiceEntryAccumulator] = [:]
        var nextOrder = 0
        walkAudioInfo(
            content,
            sourceURL: sourceURL,
            rawLanguageHeaders: &rawLanguageHeaders,
            accumulators: &accumulators,
            nextOrder: &nextOrder
        )

        let entries = accumulators.values
            .sorted { $0.order < $1.order }
            .compactMap { accumulator -> BaGuideVoiceEntry? in
                let lineHeaders = orderedVoiceLabels(
                    availableLabels: Array(accumulator.linesByLanguage.keys),
                    preferredHeaders: rawLanguageHeaders
                )
                let lines = lineHeaders.compactMap { accumulator.linesByLanguage[$0]?.trimmingCharacters(in: .whitespacesAndNewlines) }
                let audioHeaders = orderedVoiceLabels(
                    availableLabels: Array(accumulator.audioByLanguage.keys),
                    preferredHeaders: rawLanguageHeaders
                )
                let audioURLs = audioHeaders.compactMap { accumulator.audioByLanguage[$0] }
                guard lines.contains(where: { $0.isEmpty == false }) || audioURLs.isEmpty == false else {
                    return nil
                }
                return BaGuideVoiceEntry(
                    id: "voice-audio-info-\(accumulator.order)-\(abs("\(accumulator.section)|\(accumulator.title)".hashValue))",
                    title: accumulator.title,
                    subtitle: accumulator.section,
                    transcript: lines.joined(separator: "\n"),
                    audioURL: audioURLs.first,
                    section: accumulator.section,
                    lineHeaders: lineHeaders.isEmpty ? nil : lineHeaders,
                    lines: lines.isEmpty ? nil : lines,
                    audioURLs: audioURLs.isEmpty ? nil : audioURLs,
                    audioHeaders: audioHeaders.isEmpty ? nil : audioHeaders
                )
            }

        let headers = languageHeaders(
            rawHeaders: rawLanguageHeaders,
            entriesAudioCounts: entries.map { $0.audioURLs?.count ?? ($0.audioURL == nil ? 0 : 1) }
        )
        return BaGuideVoiceParseResult(languageHeaders: headers, entries: entries)
    }

    private func walkAudioInfo(
        _ any: Any?,
        sourceURL: URL?,
        rawLanguageHeaders: inout [String],
        accumulators: inout [String: ArrayVoiceEntryAccumulator],
        nextOrder: inout Int,
        depth: Int = 0
    ) {
        guard depth <= 10, let any else { return }
        if let object = any as? BaJSONObject {
            if object.string("type")?.trimmingCharacters(in: .whitespacesAndNewlines) == "audio-info" {
                processAudioInfoNode(
                    object,
                    sourceURL: sourceURL,
                    rawLanguageHeaders: &rawLanguageHeaders,
                    accumulators: &accumulators,
                    nextOrder: &nextOrder
                )
            }
            for value in object.values {
                walkAudioInfo(
                    value,
                    sourceURL: sourceURL,
                    rawLanguageHeaders: &rawLanguageHeaders,
                    accumulators: &accumulators,
                    nextOrder: &nextOrder,
                    depth: depth + 1
                )
            }
            return
        }
        if let array = any as? [Any] {
            for value in array {
                walkAudioInfo(
                    value,
                    sourceURL: sourceURL,
                    rawLanguageHeaders: &rawLanguageHeaders,
                    accumulators: &accumulators,
                    nextOrder: &nextOrder,
                    depth: depth + 1
                )
            }
        }
    }

    private func processAudioInfoNode(
        _ object: BaJSONObject,
        sourceURL: URL?,
        rawLanguageHeaders: inout [String],
        accumulators: inout [String: ArrayVoiceEntryAccumulator],
        nextOrder: inout Int
    ) {
        guard let data = object.object("data") else { return }
        let rootTitle = BaGuideRichTextExtractor.text(from: data["title"]).ifBlank("语音台词")
        var tabKeyToLabel: [String: String] = [:]

        for (index, tab) in objectArray(data["tabs"]).enumerated() {
            let key = tab.string("key") ?? ""
            guard key.isEmpty == false else { continue }
            let rawLabel = BaGuideRichTextExtractor.text(from: tab["label"])
                .ifBlank(localizedLanguageLabel(index))
            let label = canonicalLanguageLabel(rawLabel).ifBlank(rawLabel)
            if appendVoiceHeader(label, rawLanguageHeaders: &rawLanguageHeaders) {
                tabKeyToLabel[key] = label
            }
        }

        for (groupIndex, group) in objectArray(data["list"]).enumerated() {
            let filterTabKey = group.string("filterTabKey") ?? ""
            let rawLanguage = tabKeyToLabel[filterTabKey]
                ?? BaGuideRichTextExtractor.text(from: group["label"])
                .ifBlank(defaultLanguageLabel(groupIndex))
            let language = canonicalLanguageLabel(rawLanguage).ifBlank(rawLanguage)
            _ = appendVoiceHeader(language, rawLanguageHeaders: &rawLanguageHeaders)

            let section = sanitizedAudioInfoSection(
                BaGuideRichTextExtractor.text(from: group["title"]),
                fallback: rootTitle
            )

            for (contentIndex, item) in objectArray(group["content"]).enumerated() {
                let title = BaGuideRichTextExtractor.text(from: item["name"])
                    .ifBlank(BaGuideRichTextExtractor.text(from: item["title"]))
                    .ifBlank(String(format: BaL10n.string("ba.student.detail.voice.item.format"), contentIndex + 1))
                let descLines = BaGuideRichTextExtractor.lines(from: item["desc"], sourceURL: sourceURL)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
                let primaryLine = descLines.first ?? ""
                let officialLine = descLines.dropFirst().first(where: { $0 != primaryLine }) ?? ""
                let audioURL = audioInfoURLs(in: item, sourceURL: sourceURL).first

                let key = "\(section)|\(title)"
                var accumulator = accumulators[key] ?? ArrayVoiceEntryAccumulator(
                    section: section,
                    title: title,
                    order: nextOrder
                )
                if accumulators[key] == nil {
                    nextOrder += 1
                }
                let resolvedLanguage = resolvedAudioInfoLanguage(
                    language,
                    primaryLine: primaryLine,
                    audioURL: audioURL,
                    accumulator: accumulator,
                    rawLanguageHeaders: &rawLanguageHeaders
                )
                if resolvedLanguage.isEmpty == false,
                   primaryLine.isEmpty == false,
                   accumulator.linesByLanguage[resolvedLanguage]?.isEmpty ?? true
                {
                    accumulator.linesByLanguage[resolvedLanguage] = primaryLine
                }
                if resolvedLanguage.isEmpty == false,
                   let audioURL,
                   accumulator.audioByLanguage[resolvedLanguage] == nil
                {
                    accumulator.audioByLanguage[resolvedLanguage] = audioURL
                }
                if officialLine.isEmpty == false,
                   accumulator.linesByLanguage["官翻"]?.isEmpty ?? true
                {
                    accumulator.linesByLanguage["官翻"] = officialLine
                }
                accumulators[key] = accumulator
            }
        }
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

    private func audioInfoURLs(in item: BaJSONObject, sourceURL: URL?) -> [URL] {
        var urls: [URL] = []
        if let rawAudio = item.string("audio"),
           let url = BaGuideTextNormalizer.normalizeMediaURL(rawAudio, sourceURL: sourceURL),
           BaGuideTextNormalizer.looksLikeAudioURL(url)
        {
            urls.append(url)
        }
        urls.append(contentsOf: BaGuideTextNormalizer.audioURLs(in: item, sourceURL: sourceURL))
        return BaGuideTextNormalizer.dedupe(urls)
    }

    private func resolvedAudioInfoLanguage(
        _ language: String,
        primaryLine: String,
        audioURL: URL?,
        accumulator: ArrayVoiceEntryAccumulator,
        rawLanguageHeaders: inout [String]
    ) -> String {
        let label = canonicalLanguageLabel(language).ifBlank(language)
        guard label.isEmpty == false else { return "" }
        guard audioInfoLanguageNeedsAlternate(
            label,
            primaryLine: primaryLine,
            audioURL: audioURL,
            accumulator: accumulator
        ) else {
            return label
        }
        let alternate = availableAlternateLanguageLabel(
            for: label,
            primaryLine: primaryLine,
            audioURL: audioURL,
            accumulator: accumulator
        )
        _ = appendVoiceHeader(alternate, rawLanguageHeaders: &rawLanguageHeaders)
        return alternate
    }

    private func audioInfoLanguageNeedsAlternate(
        _ label: String,
        primaryLine: String,
        audioURL: URL?,
        accumulator: ArrayVoiceEntryAccumulator
    ) -> Bool {
        let existingLine = accumulator.linesByLanguage[label]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let existingAudio = accumulator.audioByLanguage[label]
        if primaryLine.isEmpty == false,
           existingLine.isEmpty == false,
           existingLine != primaryLine
        {
            return true
        }
        if let audioURL,
           let existingAudio,
           existingAudio != audioURL
        {
            return true
        }
        return false
    }

    private func availableAlternateLanguageLabel(
        for label: String,
        primaryLine: String,
        audioURL: URL?,
        accumulator: ArrayVoiceEntryAccumulator
    ) -> String {
        let base = oldVersionLanguageLabel(for: label)
        if audioInfoCanUseLanguageLabel(base, primaryLine: primaryLine, audioURL: audioURL, accumulator: accumulator) {
            return base
        }
        for index in 2...8 {
            let candidate = "\(base) \(index)"
            if audioInfoCanUseLanguageLabel(candidate, primaryLine: primaryLine, audioURL: audioURL, accumulator: accumulator) {
                return candidate
            }
        }
        return "\(base) \(abs("\(label)|\(primaryLine)|\(audioURL?.absoluteString ?? "")".hashValue))"
    }

    private func audioInfoCanUseLanguageLabel(
        _ label: String,
        primaryLine: String,
        audioURL: URL?,
        accumulator: ArrayVoiceEntryAccumulator
    ) -> Bool {
        let existingLine = accumulator.linesByLanguage[label]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let existingAudio = accumulator.audioByLanguage[label]
        let lineAvailable = primaryLine.isEmpty || existingLine.isEmpty || existingLine == primaryLine
        let audioAvailable = audioURL == nil || existingAudio == nil || existingAudio == audioURL
        return lineAvailable && audioAvailable
    }

    private func oldVersionLanguageLabel(for label: String) -> String {
        switch canonicalLanguageLabel(label) {
        case "日配":
            "旧版日配"
        case "中配":
            "旧版中配"
        case "韩配":
            "旧版韩配"
        case let value where value.hasPrefix("旧版"):
            value
        default:
            "\(label) 旧版"
        }
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
        let isOld = normalized.contains("旧") || normalized.contains("old")
        if isOld {
            if isJapaneseLanguageLabel(normalized) {
                return "旧版日配"
            }
            if isChineseLanguageLabel(normalized) {
                return "旧版中配"
            }
            if isKoreanLanguageLabel(normalized) {
                return "旧版韩配"
            }
        }
        if normalized.contains("官翻") ||
            normalized.contains("官方翻译") ||
            normalized.contains("官方中文") ||
            normalized.contains("官中")
        {
            return "官翻"
        }
        if isKoreanLanguageLabel(normalized) {
            return "韩配"
        }
        if isChineseLanguageLabel(normalized) {
            return "中配"
        }
        if isJapaneseLanguageLabel(normalized) {
            return "日配"
        }
        return BaGuideTextNormalizer.clean(raw)
    }

    private func isJapaneseLanguageLabel(_ normalized: String) -> Bool {
        normalized.contains("日") ||
            normalized.contains("jp") ||
            normalized.contains("jpn") ||
            normalized.contains("日本")
    }

    private func isChineseLanguageLabel(_ normalized: String) -> Bool {
        normalized.contains("中") ||
            normalized.contains("cn") ||
            normalized.contains("国语") ||
            normalized.contains("国配") ||
            normalized.contains("中文")
    }

    private func isKoreanLanguageLabel(_ normalized: String) -> Bool {
        normalized.contains("韩") ||
            normalized.contains("kr") ||
            normalized.contains("kor") ||
            normalized.contains("korean")
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
        String(format: BaL10n.string("ba.student.detail.voice.language.format"), index + 1)
    }

    private func voicePriority(_ label: String) -> Int {
        switch canonicalLanguageLabel(label) {
        case "日配":
            0
        case "中配":
            1
        case "旧版日配":
            2
        case "旧版中配":
            3
        case "官翻":
            4
        case "韩配":
            5
        case "旧版韩配":
            6
        default:
            7
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

    private func appendVoiceHeader(_ label: String, rawLanguageHeaders: inout [String]) -> Bool {
        let value = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false, canonicalLanguageLabel(value) != "官翻" else {
            return false
        }
        if rawLanguageHeaders.contains(value) == false {
            rawLanguageHeaders.append(value)
        }
        return true
    }

    private func orderedVoiceLabels(availableLabels: [String], preferredHeaders: [String]) -> [String] {
        let available = Set(availableLabels)
        var ordered: [String] = []
        for header in preferredHeaders where available.contains(header) {
            ordered.append(header)
        }
        let remaining = availableLabels
            .filter { ordered.contains($0) == false }
            .sorted { lhs, rhs in
                let lhsPriority = voicePriority(lhs)
                let rhsPriority = voicePriority(rhs)
                return lhsPriority < rhsPriority || (lhsPriority == rhsPriority && lhs < rhs)
            }
        ordered.append(contentsOf: remaining)
        return unique(ordered)
    }

    private func sanitizedAudioInfoSection(_ rawTitle: String, fallback: String) -> String {
        let title = BaGuideTextNormalizer.clean(rawTitle)
        guard title.isEmpty == false, title.localizedCaseInsensitiveContains("分组标题") == false else {
            return fallback
        }
        return title
    }

    private func objectArray(_ any: Any?) -> [BaJSONObject] {
        if let objects = any as? [BaJSONObject] {
            return objects
        }
        return (any as? [Any])?.compactMap { $0 as? BaJSONObject } ?? []
    }

    private struct ParsedVoiceRowContent {
        let title: String
        let textByAudioSegment: [Int: [String]]
        let audioURLs: [URL]
    }

    private struct ArrayVoiceEntryAccumulator {
        let section: String
        let title: String
        let order: Int
        var linesByLanguage: [String: String] = [:]
        var audioByLanguage: [String: URL] = [:]
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
