//
//  BaStudentSkillDisplayModel.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

nonisolated struct BaStudentSkillDisplayModel: Identifiable, Hashable {
    // Compiled-once regex cache. parseLevelNumber alone is called from
    // levelOptions/defaultLevel computed properties — those run on every body
    // recompose for every visible skill card.
    fileprivate nonisolated(unsafe) static let levelDigitRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d{1,2}"#)
    }()
    fileprivate nonisolated(unsafe) static let glossaryNameRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"名词\d+"#)
    }()
    fileprivate nonisolated(unsafe) static let dimensionRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"/w_(\d{1,4})/h_(\d{1,4})/"#)
    }()
    fileprivate nonisolated(unsafe) static let levelKeyRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"(?i)^LV\.?\d{1,2}$"#)
    }()
    fileprivate nonisolated(unsafe) static let costPrefixRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"(?i)^COST:\s*"#)
    }()
    fileprivate nonisolated(unsafe) static let collapsedSpaceRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\s{2,}"#)
    }()
    fileprivate nonisolated(unsafe) static let multiSpaceRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\s+"#)
    }()
    fileprivate nonisolated(unsafe) static let ownedSkillRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"^(「[^」]{1,40}」|『[^』]{1,40}』|【[^】]{1,40}】|[A-Za-z0-9\u{4E00}-\u{9FFF}·・\-\s]{1,40})\s*的\s*(.+)$"#
        )
    }()
    fileprivate nonisolated(unsafe) static let trailingNumberRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^(.*?)[\s\-_]*(\d{1,2})$"#)
    }()
    fileprivate nonisolated(unsafe) static let trailingDigitsRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d{1,2}$"#)
    }()
    fileprivate nonisolated(unsafe) static let bracketCaptureRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"[（(【\[]([^()（）【】\[\]]+)[)）】\]]"#)
    }()

    let id: String
    let type: String
    let name: String
    let iconURL: URL?
    let descriptionByLevel: [String: String]
    let descriptionIconsByLevel: [String: [URL]]
    let costByLevel: [String: String]
    let glossaryIcons: [String: URL]
    let fallbackDescription: String
    let fallbackDescriptionIcons: [URL]

    var displayName: String {
        name.ifBlank(BaL10n.string("ba.student.detail.skill.unnamed"))
    }

    var levelOptions: [String] {
        descriptionByLevel.keys.sorted {
            (Self.parseLevelNumber($0) ?? Int.max, $0) < (Self.parseLevelNumber($1) ?? Int.max, $1)
        }
    }

    var defaultLevel: String {
        levelOptions.max {
            (Self.parseLevelNumber($0) ?? Int.min, $0) < (Self.parseLevelNumber($1) ?? Int.min, $1)
        } ?? levelOptions.first ?? "Lv.1"
    }

    var localizedType: String {
        let base = typeMeta.baseType
        if base.localizedCaseInsensitiveContains("EX") {
            return "EX技能"
        }
        if base.localizedCaseInsensitiveContains("普通") {
            return BaL10n.string("ba.student.detail.skill.normal")
        }
        if base.localizedCaseInsensitiveContains("被动") {
            return BaL10n.string("ba.student.detail.skill.passive")
        }
        if base.localizedCaseInsensitiveContains("辅助") {
            return BaL10n.string("ba.student.detail.skill.sub")
        }
        return base.ifBlank(BaStudentDetailSection.skills.title)
    }

    var typeStateTags: [String] {
        typeMeta.stateTags
    }

    var typeVariantBadge: String? {
        typeMeta.variantIndex.flatMap(Self.circledNumber)
    }

    private var typeMeta: BaStudentSkillTypeMeta {
        BaStudentSkillTypeMeta.parse(type)
    }

    func description(for level: String) -> String {
        descriptionByLevel[level]
            ?? descriptionByLevel[defaultLevel]
            ?? fallbackDescription
    }

    func descriptionIcons(for level: String) -> [URL] {
        let levelIcons = descriptionIconsByLevel[level] ?? []
        if levelIcons.isEmpty == false {
            return levelIcons
        }
        let defaultIcons = descriptionIconsByLevel[defaultLevel] ?? []
        return defaultIcons.isEmpty ? fallbackDescriptionIcons : defaultIcons
    }

    func cost(for level: String) -> String {
        costByLevel[level]
            ?? costByLevel[defaultLevel]
            ?? costByLevel.values.first
            ?? ""
    }

    static func cards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        let glossaryIcons = extractSkillGlossaryIcons(from: rows)
        let drafts = parseBaseSkillDrafts(from: rows)
        let cards = drafts.enumerated().compactMap { index, draft -> BaStudentSkillDisplayModel? in
            let hasHead = draft.name.isEmpty == false || draft.iconURL != nil
            let hasDescription = draft.descriptionByLevel.isEmpty == false || draft.fallbackDescription.isEmpty == false
            guard hasHead, hasDescription else { return nil }
            return BaStudentSkillDisplayModel(
                id: "skill-\(index)-\(draft.type)-\(draft.name)",
                type: draft.type,
                name: draft.name,
                iconURL: draft.iconURL,
                descriptionByLevel: draft.descriptionByLevel,
                descriptionIconsByLevel: draft.descriptionIconsByLevel,
                costByLevel: draft.costByLevel,
                glossaryIcons: glossaryIcons,
                fallbackDescription: draft.fallbackDescription,
                fallbackDescriptionIcons: draft.fallbackDescriptionIcons
            )
        }
        return cards.isEmpty ? fallbackCards(from: rows) : cards
    }

    static func parseLevelNumber(_ label: String) -> Int? {
        let foundRange: Range<String.Index>?
        if let regex = levelDigitRegex {
            let range = NSRange(label.startIndex ..< label.endIndex, in: label)
            foundRange = regex.firstMatch(in: label, range: range).flatMap { Range($0.range, in: label) }
        } else {
            foundRange = label.range(of: #"\d{1,2}"#, options: .regularExpression)
        }
        guard let range = foundRange else { return nil }
        return Int(label[range])
    }

    static func matchesGlossaryName(_ value: String) -> Bool {
        if let regex = glossaryNameRegex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            return regex.firstMatch(in: value, range: range) != nil
        }
        return value.range(of: #"名词\d+"#, options: .regularExpression) != nil
    }

    private static func fallbackCards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        rows.prefix(16).enumerated().map { index, row in
            BaStudentSkillDisplayModel(
                id: row.id,
                type: "",
                name: skillTitle(row: row, index: index),
                iconURL: row.imageURL,
                descriptionByLevel: [:],
                descriptionIconsByLevel: [:],
                costByLevel: [:],
                glossaryIcons: [:],
                fallbackDescription: row.value,
                fallbackDescriptionIcons: rowDescriptionIcons(row)
            )
        }
    }

    private static func skillTitle(row: BaGuideRow, index: Int) -> String {
        let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty == false {
            return title
        }
        return String(format: BaL10n.string("ba.student.detail.row.format"), index + 1)
    }

    private static func parseBaseSkillDrafts(from rows: [BaGuideRow]) -> [SkillDraft] {
        var result: [SkillDraft] = []
        var draft: SkillDraft?
        var currentLevelKey: String?
        var enteredSkillBlocks = false
        var pendingName = ""
        var pendingIconURL: URL?
        var currentType = ""
        var lastDescribedDraft: SkillDraft?

        func commitDraft() {
            guard var item = draft else { return }
            if let inherited = lastDescribedDraft, inherited.type == item.type {
                if item.hasDescription == false {
                    item.descriptionByLevel = inherited.descriptionByLevel
                    item.descriptionIconsByLevel = inherited.descriptionIconsByLevel
                    item.fallbackDescription = inherited.fallbackDescription
                    item.fallbackDescriptionIcons = inherited.fallbackDescriptionIcons
                }
                if item.costByLevel.isEmpty {
                    item.costByLevel = inherited.costByLevel
                }
            }
            result.append(item)
            if item.hasDescription {
                lastDescribedDraft = item
            }
            draft = nil
            currentLevelKey = nil
        }

        for row in rows.flatMap(expandedSkillRows) {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
            let image = row.imageURL
            let iconCandidates = rowDescriptionIcons(row)

            if key == "专武" || key.contains("技能名词") || key.contains("升级材料") || key == "所需个数" {
                commitDraft()
                if key.contains("技能名词") {
                    enteredSkillBlocks = false
                }
                continue
            }

            if key == "技能类型" {
                guard value.isEmpty == false else { continue }
                enteredSkillBlocks = true
                commitDraft()
                currentType = sanitizeSkillLabel(value)
                draft = SkillDraft(type: currentType)
                if pendingName.isEmpty == false {
                    draft?.name = pendingName
                }
                if let pendingIconURL {
                    draft?.iconURL = pendingIconURL
                }
                pendingName = ""
                pendingIconURL = nil
                currentLevelKey = nil
                continue
            }

            if enteredSkillBlocks == false {
                if key.contains("技能名称"), value.isEmpty == false {
                    pendingName = sanitizeSkillLabel(value)
                } else if key == "技能图标", let image {
                    pendingIconURL = image
                }
                continue
            }

            if key.isEmpty, value.isEmpty, image == nil {
                commitDraft()
                continue
            }

            guard draft != nil else { continue }
            switch true {
            case key.contains("技能名称") && key.contains("★") == false:
                if value.isEmpty == false {
                    if let active = draft, active.name.isEmpty == false {
                        commitDraft()
                        draft = SkillDraft(type: currentType.ifBlank(active.type))
                    } else if draft == nil {
                        draft = SkillDraft(type: currentType)
                    }
                    draft?.name = sanitizeSkillLabel(value)
                }
            case key == "技能图标":
                if let image {
                    draft?.iconURL = image
                }
            case key == "技能等级":
                if let levelLabel = toDisplayLevelLabel(value) {
                    currentLevelKey = levelLabel
                }
            case key == "技能描述":
                if let currentLevelKey {
                    if value.isEmpty == false {
                        draft?.descriptionByLevel[currentLevelKey] = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.descriptionIconsByLevel[currentLevelKey] = iconCandidates
                    }
                } else {
                    if value.isEmpty == false {
                        draft?.fallbackDescription = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.fallbackDescriptionIcons = iconCandidates
                    }
                }
            case key == "技能COST":
                if value.isEmpty == false {
                    if let currentLevelKey {
                        draft?.costByLevel[currentLevelKey] = normalizeCost(value)
                    } else {
                        draft?.costByLevel["base"] = normalizeCost(value)
                    }
                }
            default:
                if let levelLabel = toDisplayLevelLabel(key) {
                    if value.isEmpty == false {
                        draft?.descriptionByLevel[levelLabel] = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.descriptionIconsByLevel[levelLabel] = iconCandidates
                    }
                    currentLevelKey = levelLabel
                }
            }
        }
        commitDraft()
        return result
    }

    private static func expandedSkillRows(from row: BaGuideRow) -> [BaGuideRow] {
        let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key == "角色技能", value.contains("技能类型") || value.contains("技能名称") else {
            return [row]
        }
        let parts = value
            .components(separatedBy: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        guard parts.count >= 2 else { return [row] }
        var expanded: [BaGuideRow] = []
        var index = 0
        while index < parts.count {
            let title = parts[index]
            let next = parts.indices.contains(index + 1) ? parts[index + 1] : ""
            if isKnownSkillKey(title) || toDisplayLevelLabel(title) != nil {
                expanded.append(
                    BaGuideRow(
                        id: "\(row.id)-expanded-\(expanded.count)",
                        title: title,
                        value: next,
                        imageURL: nil
                    )
                )
                index += 2
            } else {
                index += 1
            }
        }
        return expanded.isEmpty ? [row] : expanded
    }

    static func extractSkillGlossaryIcons(from rows: [BaGuideRow]) -> [String: URL] {
        var glossary: [String: URL] = [:]
        var inGlossary = false

        for row in rows {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if key == "技能名词" {
                inGlossary = true
                continue
            }
            guard inGlossary else { continue }
            if key.contains("升级材料") || key == "专武" || key.contains("爱用品") {
                inGlossary = false
                continue
            }
            if key == "名词图标" || key == "名词解释" || Self.matchesGlossaryName(key) {
                continue
            }
            if key.isEmpty == false, let imageURL = row.imageURL {
                glossary[key] = imageURL
            }
        }
        return glossary
    }

    static func rowDescriptionIcons(_ row: BaGuideRow) -> [URL] {
        let candidates = row.imageURLs ?? row.imageURL.map { [$0] } ?? []
        return Array(
            candidates
                .filter(isLikelyDescriptionIcon)
                .reduce(into: [URL]()) { result, url in
                    if result.contains(url) == false {
                        result.append(url)
                    }
                }
                .prefix(6)
        )
    }

    static func isLikelyDescriptionIcon(_ url: URL) -> Bool {
        let value = url.absoluteString
        if value.localizedCaseInsensitiveContains("data:image") {
            return true
        }
        let matchedRange: Range<String.Index>?
        if let regex = dimensionRegex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            matchedRange = regex.firstMatch(in: value, range: range).flatMap { Range($0.range, in: value) }
        } else {
            matchedRange = value.range(of: #"/w_(\d{1,4})/h_(\d{1,4})/"#, options: .regularExpression)
        }
        guard let match = matchedRange else { return false }
        let matched = String(value[match])
        let numbers = matched
            .split { $0 == "/" || $0 == "_" }
            .compactMap { Int($0) }
        guard numbers.count >= 2 else { return false }
        return numbers[0] <= 96 && numbers[1] <= 96
    }

    static func toDisplayLevelLabel(_ rawKey: String) -> String? {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        let matchedRange: Range<String.Index>?
        if let regex = levelKeyRegex {
            let range = NSRange(key.startIndex ..< key.endIndex, in: key)
            matchedRange = regex.firstMatch(in: key, range: range).flatMap { Range($0.range, in: key) }
        } else {
            matchedRange = key.range(of: #"(?i)^LV\.?\d{1,2}$"#, options: .regularExpression)
        }
        guard let range = matchedRange,
              range.lowerBound == key.startIndex,
              range.upperBound == key.endIndex,
              let number = parseLevelNumber(key)
        else {
            return nil
        }
        return "Lv.\(number)"
    }

    private static func sanitizeSkillLabel(_ raw: String) -> String {
        let cleaned = stripInlineNotes(raw)
        guard cleaned.isEmpty == false else { return "" }
        let segments = splitSlashSegments(cleaned)
        guard segments.count > 1 else { return cleaned }
        let tailHasPlaceholder = segments.dropFirst().contains { segment in
            let compact = segment.replacingOccurrences(of: " ", with: "")
            return compact.isEmpty ||
                compact == "..." ||
                compact == "…" ||
                compact.count <= 2 ||
                ["占位", "暂无", "无", "待补", "图片"].contains { compact.contains($0) } ||
                isLikelyNoteSegment(segment)
        }
        return tailHasPlaceholder ? segments[0].trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    private static func stripInlineNotes(_ raw: String) -> String {
        raw.components(separatedBy: "<-").first?
            .components(separatedBy: "←").first?
            .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；\n\t"))
            ?? ""
    }

    private static func splitSlashSegments(_ raw: String) -> [String] {
        raw.components(separatedBy: CharacterSet(charactersIn: "/／|｜"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private static func isLikelyNoteSegment(_ raw: String) -> Bool {
        let compact = raw.replacingOccurrences(of: " ", with: "")
        return compact.hasPrefix("注") ||
            compact.localizedCaseInsensitiveContains("todo") ||
            compact.localizedCaseInsensitiveContains("note")
    }

    private static func isKnownSkillKey(_ value: String) -> Bool {
        ["技能名称", "技能类型", "技能图标", "技能等级", "技能描述", "技能COST"].contains(value)
    }

    private static func normalizeCost(_ raw: String) -> String {
        let normalized = raw.replacingOccurrences(of: "：", with: ":")
        let stripped: String
        if let regex = costPrefixRegex {
            let range = NSRange(normalized.startIndex ..< normalized.endIndex, in: normalized)
            stripped = regex.stringByReplacingMatches(in: normalized, range: range, withTemplate: "")
        } else {
            stripped = normalized.replacingOccurrences(of: #"(?i)^COST:\s*"#, with: "", options: .regularExpression)
        }
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func circledNumber(_ index: Int) -> String? {
        let numbers = [
            "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
            "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
        ]
        return numbers.indices.contains(index - 1) ? numbers[index - 1] : "\(index)"
    }

    private struct SkillDraft {
        var type = ""
        var name = ""
        var iconURL: URL?
        var fallbackDescription = ""
        var fallbackDescriptionIcons: [URL] = []
        var descriptionByLevel: [String: String] = [:]
        var descriptionIconsByLevel: [String: [URL]] = [:]
        var costByLevel: [String: String] = [:]

        var hasDescription: Bool {
            descriptionByLevel.isEmpty == false || fallbackDescription.isEmpty == false
        }
    }
}

private nonisolated struct BaStudentSkillTypeMeta: Hashable {
    var baseType: String
    var variantIndex: Int?
    var stateTags: [String] = []

    static func parse(_ raw: String) -> BaStudentSkillTypeMeta {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else {
            return BaStudentSkillTypeMeta(baseType: "")
        }

        var variantIndex: Int?
        var stateTags: [String] = []
        let bracketMatches = bracketCaptures(in: cleaned)
        for candidate in bracketMatches {
            let tokens = candidate
                .components(separatedBy: CharacterSet(charactersIn: "、,，/／|｜+＋"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            for token in tokens.isEmpty ? [candidate] : tokens {
                let tokenMeta = parseToken(token)
                variantIndex = variantIndex ?? tokenMeta.variantIndex
                let tag = normalizeStateTag(tokenMeta.base.ifBlank(token))
                if tag.isEmpty == false {
                    stateTags.append(tag)
                }
            }
        }

        let bracketStripped: String
        if let regex = BaStudentSkillDisplayModel.bracketCaptureRegex {
            let range = NSRange(cleaned.startIndex ..< cleaned.endIndex, in: cleaned)
            bracketStripped = regex.stringByReplacingMatches(in: cleaned, range: range, withTemplate: "")
        } else {
            bracketStripped = cleaned.replacingOccurrences(
                of: #"[（(【\[]([^()（）【】\[\]]+)[)）】\]]"#,
                with: "",
                options: .regularExpression
            )
        }
        let collapsed: String
        if let regex = BaStudentSkillDisplayModel.collapsedSpaceRegex {
            let range = NSRange(bracketStripped.startIndex ..< bracketStripped.endIndex, in: bracketStripped)
            collapsed = regex.stringByReplacingMatches(in: bracketStripped, range: range, withTemplate: " ")
        } else {
            collapsed = bracketStripped.replacingOccurrences(
                of: #"\s{2,}"#,
                with: " ",
                options: .regularExpression
            )
        }
        let baseCandidate = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: " -_/／|｜"))
        let owned = splitOwnedSkillType(baseCandidate.ifBlank(cleaned))
        let baseToken = owned?.skillType ?? baseCandidate.ifBlank(cleaned)
        let baseMeta = parseToken(baseToken)
        variantIndex = variantIndex ?? baseMeta.variantIndex
        if let ownerTag = owned?.ownerTag, ownerTag.isEmpty == false {
            stateTags.insert(normalizeStateTag(ownerTag), at: 0)
        }

        return BaStudentSkillTypeMeta(
            baseType: baseMeta.base.ifBlank(cleaned),
            variantIndex: variantIndex,
            stateTags: Array(NSOrderedSet(array: stateTags.filter { $0.isEmpty == false })) as? [String] ?? stateTags
        )
    }

    private static func bracketCaptures(in value: String) -> [String] {
        guard let regex = BaStudentSkillDisplayModel.bracketCaptureRegex else { return [] }
        let nsValue = value as NSString
        return regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return nsValue.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func splitOwnedSkillType(_ raw: String) -> (ownerTag: String, skillType: String)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized: String
        if let regex = BaStudentSkillDisplayModel.multiSpaceRegex {
            let range = NSRange(trimmed.startIndex ..< trimmed.endIndex, in: trimmed)
            normalized = regex.stringByReplacingMatches(in: trimmed, range: range, withTemplate: " ")
        } else {
            normalized = trimmed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }
        let foundRange: Range<String.Index>?
        if let regex = BaStudentSkillDisplayModel.ownedSkillRegex {
            let range = NSRange(normalized.startIndex ..< normalized.endIndex, in: normalized)
            foundRange = regex.firstMatch(in: normalized, range: range).flatMap { Range($0.range, in: normalized) }
        } else {
            foundRange = normalized.range(
                of: #"^(「[^」]{1,40}」|『[^』]{1,40}』|【[^】]{1,40}】|[A-Za-z0-9\u{4E00}-\u{9FFF}·・\-\s]{1,40})\s*的\s*(.+)$"#,
                options: .regularExpression
            )
        }
        guard let range = foundRange else {
            return nil
        }
        let matched = String(normalized[range])
        let parts = matched.components(separatedBy: "的")
        guard parts.count >= 2 else { return nil }
        let owner = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let skillType = parts.dropFirst().joined(separator: "的").trimmingCharacters(in: .whitespacesAndNewlines)
        guard owner.isEmpty == false, skillType.contains("技能") else { return nil }
        return (owner, skillType)
    }

    private static func parseToken(_ raw: String) -> (base: String, variantIndex: Int?) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return ("", nil) }
        let circledNumbers = [
            "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
            "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
        ]
        if let suffix = circledNumbers.first(where: { cleaned.hasSuffix($0) }),
           let index = circledNumbers.firstIndex(of: suffix) {
            let base = String(cleaned.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            return (base.ifBlank(cleaned), index + 1)
        }
        let trailingMatchRange: Range<String.Index>?
        if let regex = BaStudentSkillDisplayModel.trailingNumberRegex {
            let nsRange = NSRange(cleaned.startIndex ..< cleaned.endIndex, in: cleaned)
            trailingMatchRange = regex.firstMatch(in: cleaned, range: nsRange).flatMap { Range($0.range, in: cleaned) }
        } else {
            trailingMatchRange = cleaned.range(of: #"^(.*?)[\s\-_]*(\d{1,2})$"#, options: .regularExpression)
        }
        if let range = trailingMatchRange {
            let matched = String(cleaned[range])
            let numberRange: Range<String.Index>?
            if let regex = BaStudentSkillDisplayModel.trailingDigitsRegex {
                let nsRange = NSRange(matched.startIndex ..< matched.endIndex, in: matched)
                numberRange = regex.firstMatch(in: matched, range: nsRange).flatMap { Range($0.range, in: matched) }
            } else {
                numberRange = matched.range(of: #"\d{1,2}$"#, options: .regularExpression)
            }
            guard let numberRange,
                  let index = Int(matched[numberRange]),
                  index > 0
            else {
                return (cleaned, nil)
            }
            let base = matched[..<numberRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            return (String(base).ifBlank(cleaned), index)
        }
        return (cleaned, nil)
    }

    private static func normalizeStateTag(_ raw: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = cleaned.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "　", with: "")
        if compact.hasPrefix("对"), compact.hasSuffix("使用"), compact.count > 3 {
            return String(compact.dropLast(2))
        }
        return cleaned
    }
}

enum BaStudentSkillTextNormalizer {
    // The skill rich-text path is hit every time SwiftUI renders a skill
    // description segment list, which happens on every body recompose for
    // expanded skill cards. Compiling these regexes from a literal pattern
    // each invocation showed up as a notable allocation hotspot.
    private nonisolated(unsafe) static let descriptionNumberRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"(?<![A-Za-z])[-+]?\d+(?:\.\d+)?\s*(?:%|％|秒|s|S|倍)?"#
        )
    }()
    private nonisolated(unsafe) static let highlightedAttributedRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"(?<![A-Za-z])[-+]?\d+(?:\.\d+)?\s*(?:%|％|秒|s|S|倍)?|COST[:：]?\s*\d+|Lv\.?\s*\d+"#
        )
    }()
    private nonisolated(unsafe) static let glossaryWhitespaceRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"[\s\u{3000}]"#)
    }()
    private nonisolated(unsafe) static let glossaryPunctuationRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"[，。、“”‘’：:；;（）()【】\[\]《》<>·•\-—_+*/\\|!?！？]"#
        )
    }()

    static func richTextSegments(
        description: String,
        glossaryIcons: [String: URL],
        leadingIcons: [URL]
    ) -> [BaStudentSkillDescriptionSegment] {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedDescription.isEmpty == false else { return [] }

        let glossary = glossaryIcons
            .filter { label, _ in label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { lhs, rhs in
                if lhs.key.count == rhs.key.count {
                    return lhs.key < rhs.key
                }
                return lhs.key.count > rhs.key.count
            }
        let normalizedDescription = normalizeGlossaryToken(trimmedDescription)
        let fuzzyLeadingIcons = glossary
            .filter { label, _ in
                trimmedDescription.contains(label) == false &&
                    normalizedDescription.contains(normalizeGlossaryToken(label))
            }
            .map(\.value)
        let prefixIcons = dedupeURLs(leadingIcons + fuzzyLeadingIcons).prefix(6)

        var segments: [BaStudentSkillDescriptionSegment] = prefixIcons.map { .icon($0) }
        if segments.isEmpty == false {
            segments.append(.text(" "))
        }

        guard let numberRegex = Self.descriptionNumberRegex else {
            segments.append(.text(trimmedDescription))
            return segments
        }

        var cursor = trimmedDescription.startIndex
        while cursor < trimmedDescription.endIndex {
            let glossaryMatch = nextGlossaryMatch(
                in: trimmedDescription,
                from: cursor,
                glossary: glossary
            )
            let numberRange = nextNumberRange(
                in: trimmedDescription,
                from: cursor,
                regex: numberRegex
            )

            let shouldUseGlossary: Bool
            switch (glossaryMatch, numberRange) {
            case (nil, nil):
                appendPlainText(String(trimmedDescription[cursor...]), to: &segments)
                cursor = trimmedDescription.endIndex
                continue
            case (.some, nil):
                shouldUseGlossary = true
            case (nil, .some):
                shouldUseGlossary = false
            case let (.some(glossary), .some(numberRange)):
                shouldUseGlossary = glossary.range.lowerBound <= numberRange.lowerBound
            }

            if shouldUseGlossary, let match = glossaryMatch {
                if match.range.lowerBound > cursor {
                    appendPlainText(String(trimmedDescription[cursor ..< match.range.lowerBound]), to: &segments)
                }
                segments.append(.icon(match.url))
                segments.append(.term(match.label))
                cursor = match.range.upperBound
            } else if let numberRange {
                if numberRange.lowerBound > cursor {
                    appendPlainText(String(trimmedDescription[cursor ..< numberRange.lowerBound]), to: &segments)
                }
                segments.append(.highlightedText(String(trimmedDescription[numberRange])))
                cursor = numberRange.upperBound
            }
        }

        return coalescedTextSegments(segments)
    }

    static func highlightedAttributedString(in text: String, tint: Color) -> AttributedString {
        var attributed = AttributedString(text)
        guard let regex = Self.highlightedAttributedRegex else {
            return attributed
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            guard let stringRange = Range(match.range, in: text),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attributed)
            else {
                continue
            }
            attributed[lower ..< upper].foregroundColor = tint
            attributed[lower ..< upper].inlinePresentationIntent = .stronglyEmphasized
        }
        return attributed
    }

    static func normalizeGlossaryToken(_ raw: String) -> String {
        let stripped = stripWithCachedRegex(
            raw,
            regex: Self.glossaryWhitespaceRegex,
            fallbackPattern: #"[\s\u{3000}]"#
        )
        let cleaned = stripWithCachedRegex(
            stripped,
            regex: Self.glossaryPunctuationRegex,
            fallbackPattern: #"[，。、“”‘’：:；;（）()【】\[\]《》<>·•\-—_+*/\\|!?！？]"#
        )
        return cleaned.lowercased()
    }

    private static func stripWithCachedRegex(
        _ value: String,
        regex: NSRegularExpression?,
        fallbackPattern: String
    ) -> String {
        guard let regex else {
            // Defensive fallback: pattern is constant so this branch should
            // never fire in practice.
            return value.replacingOccurrences(of: fallbackPattern, with: "", options: .regularExpression)
        }
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
    }

    private static func appendPlainText(_ text: String, to segments: inout [BaStudentSkillDescriptionSegment]) {
        guard text.isEmpty == false else { return }
        segments.append(.text(text))
    }

    private static func nextGlossaryMatch(
        in description: String,
        from cursor: String.Index,
        glossary: [(key: String, value: URL)]
    ) -> (range: Range<String.Index>, label: String, url: URL)? {
        var best: (range: Range<String.Index>, label: String, url: URL)?
        for entry in glossary {
            guard let range = description.range(of: entry.key, range: cursor ..< description.endIndex) else {
                continue
            }
            if let current = best {
                if range.lowerBound < current.range.lowerBound ||
                    (range.lowerBound == current.range.lowerBound && entry.key.count > current.label.count) {
                    best = (range, entry.key, entry.value)
                }
            } else {
                best = (range, entry.key, entry.value)
            }
        }
        return best
    }

    private static func nextNumberRange(
        in description: String,
        from cursor: String.Index,
        regex: NSRegularExpression
    ) -> Range<String.Index>? {
        let searchRange = NSRange(cursor ..< description.endIndex, in: description)
        guard let match = regex.firstMatch(in: description, range: searchRange),
              let range = Range(match.range, in: description)
        else {
            return nil
        }
        return range
    }

    private static func coalescedTextSegments(
        _ segments: [BaStudentSkillDescriptionSegment]
    ) -> [BaStudentSkillDescriptionSegment] {
        segments.reduce(into: []) { result, segment in
            guard let last = result.last else {
                result.append(segment)
                return
            }
            switch (last, segment) {
            case let (.text(lhs), .text(rhs)):
                result[result.count - 1] = .text(lhs + rhs)
            case let (.highlightedText(lhs), .highlightedText(rhs)):
                result[result.count - 1] = .highlightedText(lhs + rhs)
            case let (.term(lhs), .term(rhs)):
                result[result.count - 1] = .term(lhs + rhs)
            default:
                result.append(segment)
            }
        }
    }

    private static func dedupeURLs(_ urls: [URL]) -> [URL] {
        urls.reduce(into: []) { result, url in
            if result.contains(url) == false {
                result.append(url)
            }
        }
    }
}

nonisolated enum BaStudentSkillDescriptionSegment: Hashable {
    case text(String)
    case highlightedText(String)
    case term(String)
    case icon(URL)
}

private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
