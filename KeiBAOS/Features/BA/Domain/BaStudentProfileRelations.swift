//
//  BaStudentProfileRelations.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

// Compiled-once regex caches. splitRoleRowTokens and
// sameNameRoleNameCandidate run once per relation row during student
// detail parsing; the originals compiled the same patterns from string
// literals on every call.
private nonisolated let roleRowLinkRegex: NSRegularExpression? =
    try? NSRegularExpression(
        pattern: #"https?://[^\s|｜]+|/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)|(?<![A-Za-z0-9])\d{4,}(?![A-Za-z0-9])"#,
        options: [.caseInsensitive]
    )
private nonisolated let bareDomainURLRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"https?://[^\s/／|｜]+"#, options: [.caseInsensitive])
private nonisolated let plainURLRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"https?://[^\s]+"#, options: [.caseInsensitive])
private nonisolated let detailPathRegex: NSRegularExpression? =
    try? NSRegularExpression(
        pattern: #"/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)"#,
        options: [.caseInsensitive]
    )
private nonisolated let standaloneIDRegex: NSRegularExpression? =
    try? NSRegularExpression(pattern: #"(?<![A-Za-z0-9])\d{4,}(?![A-Za-z0-9])"#)

private nonisolated func stripWithCachedRegex(
    _ value: String,
    regex: NSRegularExpression?,
    fallbackPattern: String,
    options: NSString.CompareOptions = []
) -> String {
    if let regex {
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
    }
    var compareOptions: NSString.CompareOptions = options
    compareOptions.insert(.regularExpression)
    return value.replacingOccurrences(of: fallbackPattern, with: "", options: compareOptions)
}

nonisolated func buildGiftPreferenceItems(from rows: [BaGuideRow]) -> [BaStudentProfileGiftItem] {
    var seen = Set<String>()
    return rows.enumerated().compactMap { index, row in
        let normalizedImages = (row.imageURLs ?? row.imageURL.map { [$0] } ?? [])
            .filter { BaGuideTextNormalizer.looksLikeImageURL($0) }
            .dedupedByAbsoluteString()
        guard let giftImage = normalizedImages.first else { return nil }
        let emojiImage = normalizedImages.first { $0 != giftImage }
        let fallbackIndex = extractOrderedNumbers(row.title).first ?? (index + 1)
        let label = row.value.baProfileTrimmed.baProfileNonEmptyUnlessPlaceholder ?? String(
            format: BaL10n.string("ba.student.detail.gift.item.format"),
            fallbackIndex
        )
        let key = "\(giftImage.absoluteString)|\(emojiImage?.absoluteString ?? "")|\(label)"
        guard seen.insert(key).inserted else { return nil }
        return BaStudentProfileGiftItem(
            id: "gift-\(abs(key.hashValue))",
            label: label,
            giftImageURL: giftImage,
            emojiImageURL: emojiImage
        )
    }
}

nonisolated func buildSameNameRoleItems(from rows: [BaGuideRow]) -> [BaStudentProfileSameNameRoleItem] {
    var seen = Set<String>()
    return rows.flatMap { row -> [BaStudentProfileSameNameRoleItem] in
        let normalizedKey = normalizeProfileFieldKey(row.title)
        guard isSameNameRoleKey(normalizedKey) else {
            return []
        }
        let imageURLs = ((row.imageURLs ?? []) + (row.imageURL.map { [$0] } ?? []))
            .filter { BaGuideTextNormalizer.looksLikeImageURL($0) }
            .dedupedByAbsoluteString()
        let items = sameNameRoleItems(
            from: row.value,
            imageURLs: imageURLs,
            fallbackIDSeed: row.id,
            headerKey: normalizedKey,
            relationKind: relationKind(forNormalizedKey: normalizedKey)
        )
        if isRelatedRoleHeaderKey(normalizedKey),
           items.isEmpty,
           imageURLs.isEmpty
        {
            return []
        }
        return items
    }.filter { item in
        let key = "\(item.name)|\(item.guideURL?.absoluteString ?? "")|\(item.imageURL?.absoluteString ?? "")"
        return seen.insert(key).inserted
    }
}

nonisolated func sameNameRoleItems(
    from raw: String,
    imageURLs: [URL],
    fallbackIDSeed: String,
    headerKey: String,
    relationKind: BaStudentProfileRoleRelationKind
) -> [BaStudentProfileSameNameRoleItem] {
    var seeds: [(name: String, guideURL: URL?, imageURL: URL?)] = []
    var pendingName = ""
    let tokens = splitRoleRowTokens(raw)
    let scanTokens = tokens.isEmpty ? [raw] : tokens

    for token in scanTokens {
        let guideURL = extractSameNameGuideURL(token)
        let name = sameNameRoleNameCandidate(from: token)
        if let guideURL {
            let resolvedName = name.baProfileIfBlank(pendingName)
            seeds.append((resolvedName, guideURL, nil))
            pendingName = ""
        } else if name.baProfileIsBlank == false,
                  isProfileValuePlaceholder(name) == false,
                  extractProfileExternalURL(name) == nil,
                  isSameNameRoleHintText(name) == false
        {
            if pendingName.baProfileIsBlank == false {
                seeds.append((pendingName, nil, nil))
            }
            pendingName = name
        }
    }

    if pendingName.baProfileIsBlank == false {
        seeds.append((pendingName, nil, nil))
    }

    if seeds.isEmpty {
        let guideURL = extractSameNameGuideURL(raw)
        let name = sameNameRoleNameCandidate(from: raw)
        if name.baProfileIsBlank == false || guideURL != nil || imageURLs.isEmpty == false {
            seeds.append((name, guideURL, nil))
        }
    }

    if seeds.isEmpty || (seeds.count == 1 && seeds[0].name.baProfileIsBlank && seeds[0].guideURL == nil && isSameNameRoleHintText(raw)) {
        return []
    }

    return seeds.enumerated().compactMap { index, seed in
        let imageURL = imageURLs.indices.contains(index) ? imageURLs[index] : imageURLs.first
        guard seed.name.baProfileIsBlank == false || seed.guideURL != nil || imageURL != nil else { return nil }
        if seed.name.baProfileIsBlank, seed.guideURL == nil, isSameNameRoleHintText(raw) {
            return nil
        }
        if isRelatedRoleHeaderKey(headerKey), seed.guideURL == nil, imageURL == nil {
            return nil
        }
        let fallbackName = seed.guideURL.map { fallbackProfileLinkTitle($0) } ?? relationKind.fallbackItemTitle
        let resolvedName = seed.name.baProfileIfBlank(fallbackName)
        let key = "\(fallbackIDSeed)|\(index)|\(resolvedName)|\(seed.guideURL?.absoluteString ?? "")|\(imageURL?.absoluteString ?? "")"
        return BaStudentProfileSameNameRoleItem(
            id: "same-name-\(abs(key.hashValue))",
            name: resolvedName,
            guideURL: seed.guideURL,
            imageURL: imageURL
        )
    }
}

nonisolated func isSameNameRoleRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    return isSameNameRoleKey(key)
}

nonisolated func extractSameNameRoleHint(_ row: BaGuideRow) -> String? {
    guard isRelatedRoleHeaderKey(normalizeProfileFieldKey(row.title)) else { return nil }
    let rawValue = row.value.baProfileTrimmed.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
    guard rawValue.baProfileIsBlank == false, isProfileValuePlaceholder(rawValue) == false else { return nil }
    let hasLink = extractProfileExternalURL(rawValue) != nil
    let hasImage = (row.imageURLs ?? row.imageURL.map { [$0] } ?? [])
        .contains { BaGuideTextNormalizer.looksLikeImageURL($0) }
    guard hasLink == false, hasImage == false, isSameNameRoleHintText(rawValue) else { return nil }
    return rawValue
}

nonisolated func relationKind(for rows: [BaGuideRow]) -> BaStudentProfileRoleRelationKind {
    rows.contains { relationKind(forNormalizedKey: normalizeProfileFieldKey($0.title)) == .related } ? .related : .sameName
}

nonisolated func relationKind(forNormalizedKey key: String) -> BaStudentProfileRoleRelationKind {
    relatedRoleKeys.contains(key) ? .related : .sameName
}

nonisolated func isSameNameRoleKey(_ key: String) -> Bool {
    sameNameRoleKeys.contains(key) || relatedRoleKeys.contains(key)
}

nonisolated func isRelatedRoleHeaderKey(_ key: String) -> Bool {
    relatedRoleHeaderKeys.contains(key) || key == relatedSameNameRoleHeaderKey
}

nonisolated func splitRoleRowTokens(_ raw: String) -> [String] {
    guard let regex = roleRowLinkRegex else {
        return raw
            .components(separatedBy: CharacterSet(charactersIn: "/／|｜\n"))
            .map(\.baProfileTrimmed)
            .filter(\.baProfileIsNotBlank)
    }

    var protected = raw
    var replacements: [String: String] = [:]
    let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
    let matches = regex.matches(in: raw, range: range)
    for (index, match) in matches.enumerated().reversed() {
        guard let matchRange = Range(match.range, in: protected) else { continue }
        let token = String(protected[matchRange])
        let placeholder = "__BA_SAME_NAME_LINK_\(index)__"
        replacements[placeholder] = token
        protected.replaceSubrange(matchRange, with: placeholder)
    }

    return protected
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜\n"))
        .map { replacements[$0.baProfileTrimmed] ?? $0.baProfileTrimmed }
        .filter(\.baProfileIsNotBlank)
}

nonisolated func extractSameNameGuideURL(_ raw: String) -> URL? {
    BaSameNameStudentGuideLinkResolver.canonicalURL(from: raw)
}

nonisolated func sameNameRoleNameCandidate(from raw: String) -> String {
    let stage1 = stripWithCachedRegex(
        raw,
        regex: bareDomainURLRegex,
        fallbackPattern: #"https?://[^\s/／|｜]+"#,
        options: [.caseInsensitive]
    )
    let stage2 = stripWithCachedRegex(
        stage1,
        regex: plainURLRegex,
        fallbackPattern: #"https?://[^\s]+"#,
        options: [.caseInsensitive]
    )
    let stage3 = stripWithCachedRegex(
        stage2,
        regex: detailPathRegex,
        fallbackPattern: #"/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)"#,
        options: [.caseInsensitive]
    )
    let cleaned = stripWithCachedRegex(
        stage3,
        regex: standaloneIDRegex,
        fallbackPattern: #"(?<![A-Za-z0-9])\d{4,}(?![A-Za-z0-9])"#
    )
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .baProfileTrimmed
    guard cleaned.baProfileIsNotBlank,
          isProfileValuePlaceholder(cleaned) == false,
          isSameNameRoleHintText(cleaned) == false
    else {
        return ""
    }
    return cleaned
}

nonisolated func sanitizeSameNameLinkToken(_ raw: String) -> String {
    raw.baProfileTrimmed.trimmingCharacters(in: CharacterSet(charactersIn: ")]},。 ，,;；"))
}

nonisolated func isSameNameRoleHintText(_ raw: String) -> Bool {
    let value = raw.baProfileTrimmed
    guard value.baProfileIsBlank == false else { return false }
    let compact = value
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "　", with: "")
        .lowercased()
    if compact.count >= 20 { return true }
    return sameNameRoleHintKeywords.contains { compact.contains($0.lowercased()) }
}

nonisolated func fallbackProfileLinkTitle(_ url: URL) -> String {
    let lastPath = url.lastPathComponent.baProfileTrimmed
    if lastPath.baProfileIsNotBlank { return lastPath }
    let host = url.host?.baProfileTrimmed ?? ""
    return host.baProfileIfBlank(url.absoluteString)
}

nonisolated let relatedSameNameRoleHeaderKey = normalizeProfileFieldKey("相关同名角色")
nonisolated let sameNameRoleNameRowKey = normalizeProfileFieldKey("同名角色名称")
nonisolated let relatedRoleHeaderKeys = Set(["相关角色", "相关人物"].map(normalizeProfileFieldKey))
nonisolated let relatedRoleNameRowKey = normalizeProfileFieldKey("相关角色名称")
nonisolated let sameNameRoleKeys = Set([relatedSameNameRoleHeaderKey, sameNameRoleNameRowKey])
nonisolated let relatedRoleKeys = relatedRoleHeaderKeys.union([relatedRoleNameRowKey])
nonisolated let giftPreferenceRowPrefixKey = normalizeProfileFieldKey("礼物偏好礼物")
nonisolated let sameNameRoleHintKeywords = [
    "暂无同名角色", "未填写", "占位", "说明", "备注", "复制", "不用写", "暂时没", "待补充",
]
