//
//  BaStudentProfileSanitizers.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated let profileInlineNoteStripFieldKeys = Set([
    "角色考据",
    "设计",
    "MomoTalk解锁等级",
    "Momotalk解锁等级",
].map(normalizeProfileFieldKey))

nonisolated let profileCapsuleFieldKeys = Set([
    "角色名称", "年龄", "生日", "身高",
    "实装日期", "MomoTalk解锁等级",
    "繁中译名", "简中译名", "假名注音", "假名注明",
].map(normalizeProfileFieldKey))

nonisolated let profileLongTextFieldKeys = Set([
    "全名", "个人简介", "兴趣爱好", "MomoTalk状态消息",
].map(normalizeProfileFieldKey))

nonisolated let topDataStatKeys = Set([
    "攻击力", "防御力", "生命值", "治愈力",
    "命中值", "闪避值", "暴击值", "暴击伤害",
    "稳定值", "射程", "群控强化力", "群控抵抗力",
    "装弹数", "防御无视值", "受恢复率", "COST恢复力",
].map(normalizeProfileFieldKey))

nonisolated let profileSectionHeaderKeys = Set(["介绍", "学生信息", "信息"].map(normalizeProfileFieldKey))
nonisolated let galleryRelatedProfileLinkKeyTokens = [
    "影画相关链接", "相关链接", "来源链接", "个人账号主页", "账号主页", "个人主页", "主页链接", "主页",
].map(normalizeProfileFieldKey)

nonisolated func isProfileSectionHeaderRow(_ row: BaGuideRow) -> Bool {
    profileSectionHeaderKeys.contains(normalizeProfileFieldKey(row.title))
}

nonisolated func isGalleryRelatedProfileLinkRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    guard key.isEmpty == false else { return false }
    let hasGalleryLinkKey = galleryRelatedProfileLinkKeyTokens.contains { token in
        token.isEmpty == false && key.contains(token)
    }
    guard hasGalleryLinkKey else { return false }
    return containsGuideWebLink("\(row.title) \(row.value)")
}

nonisolated func isSkillMigratedProfileRow(
    _ row: BaGuideRow,
    hasTopDataHeader: Bool,
    hasInitialDataHeader: Bool
) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    let value = normalizeProfileFieldKey(row.value)
    if key.range(of: #"^附加属性\d+$"#, options: .regularExpression) != nil { return true }
    if key == normalizeProfileFieldKey("初始数据") { return true }
    if key == normalizeProfileFieldKey("顶级数据") { return true }
    if key == normalizeProfileFieldKey("25级") { return true }
    if key.range(of: #"^t\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil { return true }
    if key.range(of: #"^t\d+(效果|所需升级材料|技能图标)$"#, options: [.regularExpression, .caseInsensitive]) != nil {
        return true
    }
    if isLikelySimulateStatLabel(row.title),
       isLikelySimulateStatLabel(row.value),
       value.range(of: #"\d"#, options: .regularExpression) == nil
    {
        return true
    }
    if (hasTopDataHeader || hasInitialDataHeader), topDataStatKeys.contains(key) {
        return true
    }
    return false
}

nonisolated func sanitizeProfileFieldValue(key: String, value: String) -> String {
    guard value.baProfileIsBlank == false else { return "" }
    let normalizedKey = normalizeProfileFieldKey(key)
    var cleaned = value.baProfileTrimmed
    if normalizedKey == normalizeProfileFieldKey("声优") {
        cleaned = stripProfileCopyHint(cleaned)
    }
    if profileInlineNoteStripFieldKeys.contains(normalizedKey) {
        cleaned = stripGuideInlineNotes(cleaned)
    }
    cleaned = stripProfileInstructionNotes(cleaned)
    return cleaned
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
}

nonisolated func shouldUseProfileValueCapsule(key: String, value: String, externalURL: URL?) -> Bool {
    if externalURL != nil { return false }
    if isProfileValuePlaceholder(value) { return false }
    let normalizedKey = normalizeProfileFieldKey(key)
    if value.count > 12 || value.contains("\n") { return false }
    if value.localizedCaseInsensitiveContains("http") { return false }
    if value.contains("/") || value.contains(" / ") { return false }
    if value.contains("：") || value.contains(":") { return false }
    if profileLongTextFieldKeys.contains(normalizedKey) { return false }
    if profileCapsuleFieldKeys.contains(normalizedKey) { return true }
    return value.count <= 8 && value.contains(" ") == false
}

nonisolated func normalizeProfileFieldKey(_ raw: String) -> String {
    raw
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "　", with: "")
        .replacingOccurrences(of: "（", with: "(")
        .replacingOccurrences(of: "）", with: ")")
        .baProfileTrimmed
        .lowercased()
}

nonisolated func isProfileValuePlaceholder(_ value: String) -> Bool {
    let normalized = value.baProfileTrimmed
    let compact = normalized
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "　", with: "")
        .lowercased()
    if normalized.isEmpty { return true }
    if compact.range(of: #"^[\\/|｜／,，;；:：._\-—~·*]+$"#, options: .regularExpression) != nil {
        return true
    }
    return normalized == "-" ||
        normalized == "—" ||
        normalized == "--" ||
        normalized == "暂无" ||
        normalized == "无" ||
        compact == "n" ||
        compact == "none" ||
        compact == "null" ||
        compact == "undefined" ||
        compact == "nan"
}

nonisolated func stripProfileInstructionNotes(_ raw: String) -> String {
    guard raw.baProfileIsBlank == false else { return "" }
    let pattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard raw.range(of: pattern, options: .regularExpression) != nil else { return raw.baProfileTrimmed }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map {
            $0.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
                .baProfileTrimmed
        }
        .filter(\.baProfileIsNotBlank)
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").baProfileTrimmed
    }
    return raw
        .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
}

nonisolated func isProfileInstructionPlaceholder(_ value: String) -> Bool {
    guard value.baProfileIsBlank == false else { return false }
    let pattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard value.range(of: pattern, options: .regularExpression) != nil else { return false }
    return isProfileValuePlaceholder(stripProfileInstructionNotes(value))
}

nonisolated func stripProfileCopyHint(_ raw: String) -> String {
    guard raw.baProfileIsBlank == false else { return "" }
    let pattern = #"(?:<-|←)?\s*大部分时候可以去别的图鉴复制"#
    guard raw.range(of: pattern, options: .regularExpression) != nil else { return raw.baProfileTrimmed }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map(\.baProfileTrimmed)
        .filter { $0.baProfileIsNotBlank && $0.range(of: pattern, options: .regularExpression) == nil }
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").baProfileTrimmed
    }
    return raw
        .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
}

nonisolated func stripGuideInlineNotes(_ raw: String) -> String {
    raw
        .baProfileSubstringBefore("<-")
        .baProfileSubstringBefore("←")
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
}

nonisolated func isGrowthTitleVoiceRow(_ row: BaGuideRow) -> Bool {
    func matches(_ text: String) -> Bool {
        let normalized = text.replacingOccurrences(of: " ", with: "").lowercased()
        guard normalized.isEmpty == false else { return false }
        return (normalized.contains("成长") && normalized.contains("title")) ||
            normalized.contains("成长标题") ||
            normalized.contains("growthtitle") ||
            normalized.contains("growth_title")
    }
    return matches(row.title) || matches(row.value)
}

nonisolated func isVoicePlaceholderRow(_ row: BaGuideRow) -> Bool {
    let merged = "\(row.title) \(row.value)".replacingOccurrences(of: " ", with: "")
    return merged.range(of: #"被CC\d+"#, options: .regularExpression) != nil
}

nonisolated func isLikelySimulateStatLabel(_ raw: String) -> Bool {
    let key = normalizeProfileFieldKey(raw)
    return topDataStatKeys.contains(key) ||
        key.range(of: #"^(初始|顶级|最大|基础)?(攻击力|防御力|生命值|治愈力|命中值|闪避值|暴击值|暴击伤害|稳定值|射程)"#,
                  options: .regularExpression) != nil
}

nonisolated func extractProfileExternalURL(_ raw: String) -> URL? {
    let source = raw.baProfileTrimmed
    guard source.baProfileIsBlank == false else { return nil }
    if source.hasPrefix("http://") ||
        source.hasPrefix("https://") ||
        source.hasPrefix("www.") ||
        source.hasPrefix("/")
    {
        let normalized = source.hasPrefix("www.") ? "https://\(source)" : source
        return GameKeeJSON.normalizeGameKeeLink(normalized, fallback: "")
    }
    guard let embedded = regexMatches(in: source, pattern: #"https?://[^\s]+"#).first else {
        return nil
    }
    return URL(string: sanitizeSameNameLinkToken(embedded))
}

nonisolated func containsGuideWebLink(_ raw: String) -> Bool {
    raw.range(of: #"https?://[^\s]+"#, options: [.regularExpression, .caseInsensitive]) != nil ||
        raw.range(of: #"www\.[^\s]+"#, options: [.regularExpression, .caseInsensitive]) != nil
}

nonisolated func isChocolateGalleryItem(_ item: BaGuideGalleryItem) -> Bool {
    let merged = "\(item.title) \(item.detail) \(item.note ?? "")"
    return merged.localizedCaseInsensitiveContains("巧克力")
}

nonisolated func isInteractiveFurnitureGalleryItem(_ item: BaGuideGalleryItem) -> Bool {
    let merged = "\(item.title) \(item.detail) \(item.note ?? "")"
    return merged.localizedCaseInsensitiveContains("互动家具")
}

nonisolated func hasRenderableGalleryMedia(_ item: BaGuideGalleryItem) -> Bool {
    item.mediaURL != nil || item.imageURL != nil
}

nonisolated func extractOrderedNumbers(_ raw: String) -> [Int] {
    regexMatches(in: raw, pattern: #"\d+"#).compactMap(Int.init)
}

nonisolated func sortKeyNumbers(_ raw: String) -> (Int, Int) {
    let numbers = extractOrderedNumbers(raw)
    return (numbers.first ?? -1, numbers.dropFirst().first ?? -1)
}

nonisolated func regexMatches(in raw: String, pattern: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
        return []
    }
    let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
    return regex.matches(in: raw, range: range).compactMap { match in
        guard let range = Range(match.range(at: 0), in: raw) else { return nil }
        return String(raw[range])
    }
}
