//
//  BaStudentProfileSanitizers.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

// Compiled-once regex caches. The profile sanitizer pipeline runs once
// per row on every student detail load, and several of these patterns
// (additionalAttribute, tLevel, dataDigit, …) fan out to per-row checks
// inside isSkillMigratedProfileRow / isProfileValuePlaceholder /
// stripProfileInstructionNotes / stripProfileCopyHint. Allocating a
// fresh NSRegularExpression on every check showed up during initial
// detail loads.
private nonisolated let additionalAttributeRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"^附加属性\d+$"#)
private nonisolated let tLevelRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"^t\d+$"#, options: [.caseInsensitive])
private nonisolated let tLevelEffectRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"^t\d+(效果|所需升级材料|技能图标)$"#, options: [.caseInsensitive])
private nonisolated let containsDigitRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"\d"#)
private nonisolated let placeholderPunctuationRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"^[\\/|｜／,，;；:：._\-—~·*]+$"#)
private nonisolated let instructionNoteRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#)
private nonisolated let copyHintRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"(?:<-|←)?\s*大部分时候可以去别的图鉴复制"#)
private nonisolated let voicePlaceholderRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"被CC\d+"#)
private nonisolated let simulateStatLabelRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"^(初始|顶级|最大|基础)?(攻击力|防御力|生命值|治愈力|命中值|闪避值|暴击值|暴击伤害|稳定值|射程)"#)
private nonisolated let httpURLRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"https?://[^\s]+"#, options: [.caseInsensitive])
private nonisolated let wwwURLRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"www\.[^\s]+"#, options: [.caseInsensitive])
private nonisolated let digitsRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"\d+"#)

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
    if matchesEntireString(key, regex: additionalAttributeRegex, fallbackPattern: #"^附加属性\d+$"#) { return true }
    if key == normalizeProfileFieldKey("初始数据") { return true }
    if key == normalizeProfileFieldKey("顶级数据") { return true }
    if key == normalizeProfileFieldKey("25级") { return true }
    if matchesEntireString(key, regex: tLevelRegex, fallbackPattern: #"^t\d+$"#, options: [.caseInsensitive]) { return true }
    if matchesEntireString(key, regex: tLevelEffectRegex, fallbackPattern: #"^t\d+(效果|所需升级材料|技能图标)$"#, options: [.caseInsensitive]) {
        return true
    }
    if isLikelySimulateStatLabel(row.title),
       isLikelySimulateStatLabel(row.value),
       containsRegexMatch(value, regex: containsDigitRegex, fallbackPattern: #"\d"#) == false
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
    if matchesEntireString(compact, regex: placeholderPunctuationRegex, fallbackPattern: #"^[\\/|｜／,，;；:：._\-—~·*]+$"#) {
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
    let fallbackPattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard containsRegexMatch(raw, regex: instructionNoteRegex, fallbackPattern: fallbackPattern) else {
        return raw.baProfileTrimmed
    }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map { segment in
            replaceMatches(segment, regex: instructionNoteRegex, fallbackPattern: fallbackPattern, replacement: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
                .baProfileTrimmed
        }
        .filter(\.baProfileIsNotBlank)
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").baProfileTrimmed
    }
    return replaceMatches(raw, regex: instructionNoteRegex, fallbackPattern: fallbackPattern, replacement: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
}

nonisolated func isProfileInstructionPlaceholder(_ value: String) -> Bool {
    guard value.baProfileIsBlank == false else { return false }
    let fallbackPattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard containsRegexMatch(value, regex: instructionNoteRegex, fallbackPattern: fallbackPattern) else { return false }
    return isProfileValuePlaceholder(stripProfileInstructionNotes(value))
}

nonisolated func stripProfileCopyHint(_ raw: String) -> String {
    guard raw.baProfileIsBlank == false else { return "" }
    let fallbackPattern = #"(?:<-|←)?\s*大部分时候可以去别的图鉴复制"#
    guard containsRegexMatch(raw, regex: copyHintRegex, fallbackPattern: fallbackPattern) else {
        return raw.baProfileTrimmed
    }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map(\.baProfileTrimmed)
        .filter {
            $0.baProfileIsNotBlank &&
                containsRegexMatch($0, regex: copyHintRegex, fallbackPattern: fallbackPattern) == false
        }
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").baProfileTrimmed
    }
    return replaceMatches(raw, regex: copyHintRegex, fallbackPattern: fallbackPattern, replacement: "")
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
    return containsRegexMatch(merged, regex: voicePlaceholderRegex, fallbackPattern: #"被CC\d+"#)
}

nonisolated func isLikelySimulateStatLabel(_ raw: String) -> Bool {
    let key = normalizeProfileFieldKey(raw)
    return topDataStatKeys.contains(key) ||
        containsRegexMatch(
            key,
            regex: simulateStatLabelRegex,
            fallbackPattern: #"^(初始|顶级|最大|基础)?(攻击力|防御力|生命值|治愈力|命中值|闪避值|暴击值|暴击伤害|稳定值|射程)"#
        )
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
    guard let embedded = firstRegexMatch(in: source, regex: httpURLRegex, fallbackPattern: #"https?://[^\s]+"#) else {
        return nil
    }
    return URL(string: sanitizeSameNameLinkToken(embedded))
}

nonisolated func containsGuideWebLink(_ raw: String) -> Bool {
    containsRegexMatch(raw, regex: httpURLRegex, fallbackPattern: #"https?://[^\s]+"#) ||
        containsRegexMatch(raw, regex: wwwURLRegex, fallbackPattern: #"www\.[^\s]+"#)
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
    let matches: [String]
    if let regex = digitsRegex {
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        matches = regex.matches(in: raw, range: range).compactMap { match in
            guard let r = Range(match.range(at: 0), in: raw) else { return nil }
            return String(raw[r])
        }
    } else {
        matches = regexMatches(in: raw, pattern: #"\d+"#)
    }
    return matches.compactMap(Int.init)
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

// MARK: - Cached-regex helpers

private nonisolated func matchesEntireString(
    _ value: String,
    regex: NSRegularExpression?,
    fallbackPattern: String,
    options: NSString.CompareOptions = []
) -> Bool {
    if let regex {
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range) else { return false }
        return match.range.location == 0 && match.range.length == (value as NSString).length
    }
    var compareOptions: NSString.CompareOptions = options
    compareOptions.insert(.regularExpression)
    guard let matched = value.range(of: fallbackPattern, options: compareOptions) else { return false }
    return matched.lowerBound == value.startIndex && matched.upperBound == value.endIndex
}

private nonisolated func containsRegexMatch(
    _ value: String,
    regex: NSRegularExpression?,
    fallbackPattern: String,
    options: NSString.CompareOptions = []
) -> Bool {
    if let regex {
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        return regex.firstMatch(in: value, range: range) != nil
    }
    var compareOptions: NSString.CompareOptions = options
    compareOptions.insert(.regularExpression)
    return value.range(of: fallbackPattern, options: compareOptions) != nil
}

private nonisolated func firstRegexMatch(
    in value: String,
    regex: NSRegularExpression?,
    fallbackPattern: String,
    options: NSString.CompareOptions = []
) -> String? {
    if let regex {
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range),
              let r = Range(match.range, in: value)
        else {
            return nil
        }
        return String(value[r])
    }
    var compareOptions: NSString.CompareOptions = options
    compareOptions.insert(.regularExpression)
    guard let r = value.range(of: fallbackPattern, options: compareOptions) else { return nil }
    return String(value[r])
}

private nonisolated func replaceMatches(
    _ value: String,
    regex: NSRegularExpression?,
    fallbackPattern: String,
    replacement: String,
    options: NSString.CompareOptions = []
) -> String {
    if let regex {
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: replacement)
    }
    var compareOptions: NSString.CompareOptions = options
    compareOptions.insert(.regularExpression)
    return value.replacingOccurrences(of: fallbackPattern, with: replacement, options: compareOptions)
}
