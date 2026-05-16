//
//  BaStudentDetailProfileSections.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated enum BaStudentProfileSectionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case names
    case info
    case hobby
    case gifts
    case sameName
    case chocolate
    case furniture
    case other

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .names:
            String(localized: "ba.student.detail.profile.names.title")
        case .info:
            String(localized: "ba.student.detail.profile.info.title")
        case .hobby:
            String(localized: "ba.student.detail.profile.hobby.title")
        case .gifts:
            String(localized: "ba.student.detail.profile.gifts.title")
        case .sameName:
            String(localized: "ba.student.detail.profile.sameName.title")
        case .chocolate:
            String(localized: "ba.student.detail.profile.chocolate.title")
        case .furniture:
            String(localized: "ba.student.detail.profile.furniture.title")
        case .other:
            String(localized: "ba.student.detail.profile.other.title")
        }
    }

    var systemImage: String {
        switch self {
        case .names:
            "person.text.rectangle"
        case .info:
            "info.circle"
        case .hobby:
            "quote.bubble"
        case .gifts:
            "gift"
        case .sameName:
            "person.2"
        case .chocolate:
            "heart.square"
        case .furniture:
            "sofa"
        case .other:
            "text.alignleft"
        }
    }
}

nonisolated enum BaStudentProfileRoleRelationKind: Hashable {
    case sameName
    case related

    var title: String {
        switch self {
        case .sameName:
            String(localized: "ba.student.detail.profile.sameName.title")
        case .related:
            String(localized: "ba.student.detail.profile.relatedRoles.title")
        }
    }

    var emptyText: String {
        switch self {
        case .sameName:
            String(localized: "ba.student.detail.profile.sameName.empty")
        case .related:
            String(localized: "ba.student.detail.profile.relatedRoles.empty")
        }
    }

    var fallbackItemTitle: String {
        switch self {
        case .sameName:
            String(localized: "ba.student.detail.profile.sameName.item")
        case .related:
            String(localized: "ba.student.detail.profile.relatedRoles.item")
        }
    }

    var openDetailHint: String {
        switch self {
        case .sameName:
            String(localized: "ba.student.detail.profile.sameName.openDetail")
        case .related:
            String(localized: "ba.student.detail.profile.relatedRoles.openDetail")
        }
    }
}

nonisolated struct BaStudentProfileFieldRow: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let imageURL: URL?
    let imageURLs: [URL]
    let externalURL: URL?
    let prefersCapsule: Bool
}

nonisolated struct BaStudentProfileGiftItem: Identifiable, Hashable {
    let id: String
    let label: String
    let giftImageURL: URL
    let emojiImageURL: URL?
}

nonisolated struct BaStudentProfileSameNameRoleItem: Identifiable, Hashable {
    let id: String
    let name: String
    let guideURL: URL?
    let imageURL: URL?

    var catalogEntry: BaGuideCatalogEntry? {
        guard let guideURL,
              let contentId = BaSameNameStudentGuideLinkResolver.contentID(from: guideURL)
        else {
            return nil
        }
        return BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: 0,
            contentId: contentId,
            name: name,
            alias: "",
            aliasDisplay: "",
            iconURL: imageURL,
            type: 3,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: guideURL,
            category: .students
        )
    }
}

nonisolated struct BaStudentProfileSection: Identifiable, Hashable {
    let kind: BaStudentProfileSectionKind
    var rows: [BaStudentProfileFieldRow] = []
    var giftItems: [BaStudentProfileGiftItem] = []
    var sameNameRoleItems: [BaStudentProfileSameNameRoleItem] = []
    var sameNameRoleHint: String = ""
    var roleRelationKind: BaStudentProfileRoleRelationKind = .sameName
    var galleryItems: [BaGuideGalleryItem] = []

    var id: BaStudentProfileSectionKind {
        kind
    }

    var title: String {
        if kind == .sameName {
            return roleRelationKind.title
        }
        return kind.title
    }

    var isEmpty: Bool {
        rows.isEmpty &&
            giftItems.isEmpty &&
            sameNameRoleItems.isEmpty &&
            sameNameRoleHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            galleryItems.isEmpty
    }
}

nonisolated struct BaStudentProfileDisplayModel: Hashable {
    let sections: [BaStudentProfileSection]

    init(info: BaStudentGuideInfo, includesOtherRows: Bool = false) {
        sections = Self.sections(from: info, includesOtherRows: includesOtherRows)
    }

    static func sections(from info: BaStudentGuideInfo, includesOtherRows: Bool = false) -> [BaStudentProfileSection] {
        let profileRowsBase = info.profileDisplayRows
            .filter { BaStudentGuideMeta.shouldHideMovedHeaderRow($0) == false }
            .filter { isGrowthTitleVoiceRow($0) == false }
            .filter { isVoicePlaceholderRow($0) == false }
            .filter { isProfileSectionHeaderRow($0) == false }
            .filter { isGalleryRelatedProfileLinkRow($0) == false }

        let sameNameRoleRows = profileRowsBase.filter(isSameNameRoleRow)
        let sameNameRoleItems = buildSameNameRoleItems(from: sameNameRoleRows)
        let sameNameRoleHint = sameNameRoleRows.compactMap(extractSameNameRoleHint).first ?? ""
        let roleRelationKind = relationKind(for: sameNameRoleRows)

        let hasTopDataHeader = profileRowsBase.contains {
            normalizeProfileFieldKey($0.title) == normalizeProfileFieldKey("顶级数据")
        }
        let hasInitialDataHeader = profileRowsBase.contains {
            normalizeProfileFieldKey($0.title) == normalizeProfileFieldKey("初始数据")
        }

        let allProfileRows = profileRowsBase.filter { row in
            isSkillMigratedProfileRow(
                row,
                hasTopDataHeader: hasTopDataHeader,
                hasInitialDataHeader: hasInitialDataHeader
            ) == false && isSameNameRoleRow(row) == false
        }

        let nicknameRows = buildProfileCardRows(rows: allProfileRows, specs: nicknameFieldSpecs, section: .names)
        let studentInfoRows = buildProfileCardRows(rows: allProfileRows, specs: studentInfoFieldSpecs, section: .info)
        let hobbyRows = buildProfileCardRows(rows: allProfileRows, specs: hobbyFieldSpecs, section: .hobby)

        let giftRows = allProfileRows
            .filter(isGiftPreferenceProfileRow)
            .sortedByKeyNumbers()
        let giftItems = buildGiftPreferenceItems(from: giftRows)

        let chocolateInfoRows = allProfileRows
            .filter { $0.title.localizedCaseInsensitiveContains("巧克力") }
            .sortedByKeyNumbers()
            .compactMap { visibleProfileRow($0, section: .chocolate, prefersCapsule: true) }
        let furnitureInfoRows = allProfileRows
            .filter { $0.title.localizedCaseInsensitiveContains("互动家具") }
            .sortedByKeyNumbers()
            .compactMap { visibleProfileRow($0, section: .furniture, prefersCapsule: false) }
        let otherInfoRows = allProfileRows.filter { row in
            let title = row.title.trimmed
            return title.localizedCaseInsensitiveContains("巧克力") == false &&
                title.localizedCaseInsensitiveContains("互动家具") == false &&
                isGiftPreferenceProfileRow(row) == false &&
                isStructuredProfileCardRow(row) == false
        }
        .sortedByKeyNumbers()
        .compactMap { visibleProfileRow($0, section: .other, prefersCapsule: false) }

        let chocolateGalleryItems = info.galleryItems
            .filter(isChocolateGalleryItem)
            .filter(hasRenderableGalleryMedia)
            .distinctByMedia()
            .sortedByTitleNumbers()
        let furnitureGalleryItems = info.galleryItems
            .filter(isInteractiveFurnitureGalleryItem)
            .filter(hasRenderableGalleryMedia)
            .distinctByMedia()
            .sortedByTitleNumbers()

        var sections: [BaStudentProfileSection] = []
        appendSection(.names, rows: nicknameRows, to: &sections)
        appendSection(.info, rows: studentInfoRows, to: &sections)
        appendSection(.hobby, rows: hobbyRows, to: &sections)
        if includesOtherRows {
            appendSection(.other, rows: otherInfoRows, to: &sections)
        }
        if giftItems.isEmpty == false {
            sections.append(BaStudentProfileSection(kind: .gifts, giftItems: giftItems))
        }
        let sameNameSection = BaStudentProfileSection(
            kind: .sameName,
            sameNameRoleItems: sameNameRoleItems,
            sameNameRoleHint: sameNameRoleHint,
            roleRelationKind: roleRelationKind
        )
        if sameNameSection.isEmpty == false {
            sections.append(sameNameSection)
        }
        if chocolateInfoRows.isEmpty == false || chocolateGalleryItems.isEmpty == false {
            sections.append(
                BaStudentProfileSection(
                    kind: .chocolate,
                    rows: chocolateInfoRows,
                    galleryItems: chocolateGalleryItems
                )
            )
        }
        if furnitureInfoRows.isEmpty == false || furnitureGalleryItems.isEmpty == false {
            sections.append(
                BaStudentProfileSection(
                    kind: .furniture,
                    rows: furnitureInfoRows,
                    galleryItems: furnitureGalleryItems
                )
            )
        }
        return sections
    }

    private static func appendSection(
        _ kind: BaStudentProfileSectionKind,
        rows: [BaStudentProfileFieldRow],
        to sections: inout [BaStudentProfileSection]
    ) {
        guard rows.isEmpty == false else { return }
        sections.append(BaStudentProfileSection(kind: kind, rows: rows))
    }
}

extension BaStudentGuideInfo {
    nonisolated var profileSections: [BaStudentProfileSection] {
        BaStudentProfileDisplayModel(info: self).sections
    }

    nonisolated func profileSections(for category: BaCatalogCategory) -> [BaStudentProfileSection] {
        BaStudentProfileDisplayModel(
            info: self,
            includesOtherRows: category == .npcSatellite
        ).sections
    }
}

private struct BaStudentProfileFieldSpec {
    let title: String
    let aliases: [String]
    let hideWhenEmpty: Bool

    init(_ title: String, aliases: [String], hideWhenEmpty: Bool = false) {
        self.title = title
        self.aliases = aliases
        self.hideWhenEmpty = hideWhenEmpty
    }
}

nonisolated private let nicknameFieldSpecs = [
    BaStudentProfileFieldSpec("角色名称", aliases: ["角色名称"]),
    BaStudentProfileFieldSpec("全名", aliases: ["全名"]),
    BaStudentProfileFieldSpec("假名注音", aliases: ["假名注音", "假名注明"]),
    BaStudentProfileFieldSpec("繁中译名", aliases: ["繁中译名"]),
    BaStudentProfileFieldSpec("简中译名", aliases: ["简中译名"]),
]

nonisolated private let studentInfoFieldSpecs = [
    BaStudentProfileFieldSpec("年龄", aliases: ["年龄"]),
    BaStudentProfileFieldSpec("生日", aliases: ["生日"]),
    BaStudentProfileFieldSpec("身高", aliases: ["身高"]),
    BaStudentProfileFieldSpec("画师", aliases: ["画师", "原画师"]),
    BaStudentProfileFieldSpec("实装日期", aliases: ["实装日期", "首次登场日期"]),
    BaStudentProfileFieldSpec("声优", aliases: ["声优"]),
    BaStudentProfileFieldSpec("角色考据", aliases: ["角色考据"], hideWhenEmpty: true),
    BaStudentProfileFieldSpec("设计", aliases: ["设计", "设计师"], hideWhenEmpty: true),
]

nonisolated private let hobbyFieldSpecs = [
    BaStudentProfileFieldSpec("兴趣爱好", aliases: ["兴趣爱好"]),
    BaStudentProfileFieldSpec("个人简介", aliases: ["个人简介"]),
    BaStudentProfileFieldSpec("MomoTalk状态消息", aliases: ["MomoTalk状态消息", "Momotalk状态消息"]),
    BaStudentProfileFieldSpec("MomoTalk解锁等级", aliases: ["MomoTalk解锁等级", "Momotalk解锁等级"], hideWhenEmpty: true),
]

nonisolated private let profileInlineNoteStripFieldKeys = Set([
    "角色考据",
    "设计",
    "MomoTalk解锁等级",
    "Momotalk解锁等级",
].map(normalizeProfileFieldKey))

nonisolated private let profileCapsuleFieldKeys = Set([
    "角色名称", "年龄", "生日", "身高",
    "实装日期", "MomoTalk解锁等级",
    "繁中译名", "简中译名", "假名注音", "假名注明",
].map(normalizeProfileFieldKey))

nonisolated private let profileLongTextFieldKeys = Set([
    "全名", "个人简介", "兴趣爱好", "MomoTalk状态消息",
].map(normalizeProfileFieldKey))

nonisolated private let topDataStatKeys = Set([
    "攻击力", "防御力", "生命值", "治愈力",
    "命中值", "闪避值", "暴击值", "暴击伤害",
    "稳定值", "射程", "群控强化力", "群控抵抗力",
    "装弹数", "防御无视值", "受恢复率", "COST恢复力",
].map(normalizeProfileFieldKey))

nonisolated private func buildProfileCardRows(
    rows: [BaGuideRow],
    specs: [BaStudentProfileFieldSpec],
    section: BaStudentProfileSectionKind
) -> [BaStudentProfileFieldRow] {
    specs.compactMap { spec in
        guard let matched = rows.first(where: { isProfileRowAliasMatch($0, aliases: spec.aliases) }) else {
            return nil
        }
        let normalizedValue = sanitizeProfileFieldValue(key: spec.title, value: matched.value)
        if isProfileInstructionPlaceholder(matched.value), isProfileValuePlaceholder(normalizedValue) {
            return nil
        }
        if spec.hideWhenEmpty, isProfileValuePlaceholder(normalizedValue) {
            return nil
        }
        return fieldRow(
            id: "\(section.rawValue)-\(matched.id)",
            title: spec.title,
            value: normalizedValue,
            source: matched,
            prefersCapsule: shouldUseProfileValueCapsule(key: spec.title, value: normalizedValue, externalURL: nil)
        )
    }
}

nonisolated private func visibleProfileRow(
    _ row: BaGuideRow,
    section: BaStudentProfileSectionKind,
    prefersCapsule: Bool
) -> BaStudentProfileFieldRow? {
    let cleanedValue = sanitizeProfileFieldValue(key: row.title, value: row.value)
    let hasImage = row.imageURL != nil || (row.imageURLs?.isEmpty == false)
    let shouldDrop = (isProfileInstructionPlaceholder(row.value) && isProfileValuePlaceholder(cleanedValue)) ||
        (isProfileValuePlaceholder(cleanedValue) && hasImage == false)
    guard shouldDrop == false else { return nil }

    let displayValue: String
    if cleanedValue.isBlank, hasImage {
        displayValue = String(localized: "ba.student.detail.profile.imageBelow")
    } else {
        displayValue = cleanedValue
    }
    let externalURL = extractProfileExternalURL(displayValue)
    return fieldRow(
        id: "\(section.rawValue)-\(row.id)",
        title: row.title,
        value: displayValue,
        source: row,
        externalURL: externalURL,
        prefersCapsule: prefersCapsule && shouldUseProfileValueCapsule(
            key: row.title,
            value: displayValue,
            externalURL: externalURL
        )
    )
}

nonisolated private func fieldRow(
    id: String,
    title: String,
    value: String,
    source: BaGuideRow,
    externalURL: URL? = nil,
    prefersCapsule: Bool
) -> BaStudentProfileFieldRow {
    let imageURLs = source.imageURLs ?? source.imageURL.map { [$0] } ?? []
    return BaStudentProfileFieldRow(
        id: id,
        title: title,
        value: value,
        imageURL: source.imageURL,
        imageURLs: imageURLs,
        externalURL: externalURL,
        prefersCapsule: prefersCapsule
    )
}

nonisolated private func buildGiftPreferenceItems(from rows: [BaGuideRow]) -> [BaStudentProfileGiftItem] {
    var seen = Set<String>()
    return rows.enumerated().compactMap { index, row in
        let normalizedImages = (row.imageURLs ?? row.imageURL.map { [$0] } ?? [])
            .filter { BaGuideTextNormalizer.looksLikeImageURL($0) }
            .dedupedByAbsoluteString()
        guard let giftImage = normalizedImages.first else { return nil }
        let emojiImage = normalizedImages.first { $0 != giftImage }
        let fallbackIndex = extractOrderedNumbers(row.title).first ?? (index + 1)
        let label = row.value.trimmed.nonEmptyUnlessPlaceholder ?? String(
            format: String(localized: "ba.student.detail.gift.item.format"),
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

nonisolated private func buildSameNameRoleItems(from rows: [BaGuideRow]) -> [BaStudentProfileSameNameRoleItem] {
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

nonisolated private func sameNameRoleItems(
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
            let resolvedName = name.ifBlank(pendingName)
            seeds.append((resolvedName, guideURL, nil))
            pendingName = ""
        } else if name.isBlank == false,
                  isProfileValuePlaceholder(name) == false,
                  extractProfileExternalURL(name) == nil,
                  isSameNameRoleHintText(name) == false
        {
            if pendingName.isBlank == false {
                seeds.append((pendingName, nil, nil))
            }
            pendingName = name
        }
    }

    if pendingName.isBlank == false {
        seeds.append((pendingName, nil, nil))
    }

    if seeds.isEmpty {
        let guideURL = extractSameNameGuideURL(raw)
        let name = sameNameRoleNameCandidate(from: raw)
        if name.isBlank == false || guideURL != nil || imageURLs.isEmpty == false {
            seeds.append((name, guideURL, nil))
        }
    }

    if seeds.isEmpty || (seeds.count == 1 && seeds[0].name.isBlank && seeds[0].guideURL == nil && isSameNameRoleHintText(raw)) {
        return []
    }

    return seeds.enumerated().compactMap { index, seed in
        let imageURL = imageURLs.indices.contains(index) ? imageURLs[index] : imageURLs.first
        guard seed.name.isBlank == false || seed.guideURL != nil || imageURL != nil else { return nil }
        if seed.name.isBlank, seed.guideURL == nil, isSameNameRoleHintText(raw) {
            return nil
        }
        if isRelatedRoleHeaderKey(headerKey), seed.guideURL == nil, imageURL == nil {
            return nil
        }
        let fallbackName = seed.guideURL.map { fallbackProfileLinkTitle($0) } ?? relationKind.fallbackItemTitle
        let resolvedName = seed.name.ifBlank(fallbackName)
        let key = "\(fallbackIDSeed)|\(index)|\(resolvedName)|\(seed.guideURL?.absoluteString ?? "")|\(imageURL?.absoluteString ?? "")"
        return BaStudentProfileSameNameRoleItem(
            id: "same-name-\(abs(key.hashValue))",
            name: resolvedName,
            guideURL: seed.guideURL,
            imageURL: imageURL
        )
    }
}

nonisolated private func isProfileRowAliasMatch(_ row: BaGuideRow, aliases: [String]) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    guard key.isEmpty == false else { return false }
    return aliases.contains { key == normalizeProfileFieldKey($0) }
}

nonisolated private func isStructuredProfileCardRow(_ row: BaGuideRow) -> Bool {
    let specs = nicknameFieldSpecs + studentInfoFieldSpecs + hobbyFieldSpecs
    return specs.contains { spec in
        isProfileRowAliasMatch(row, aliases: spec.aliases)
    }
}

nonisolated private func isGiftPreferenceProfileRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    return key.hasPrefix(giftPreferenceRowPrefixKey) ||
        (row.id.hasPrefix("gift-") && row.imageURL != nil) ||
        (key.hasPrefix(normalizeProfileFieldKey("礼物")) && row.imageURL != nil)
}

nonisolated private func isSameNameRoleRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    return isSameNameRoleKey(key)
}

nonisolated private func extractSameNameRoleHint(_ row: BaGuideRow) -> String? {
    guard isRelatedRoleHeaderKey(normalizeProfileFieldKey(row.title)) else { return nil }
    let rawValue = row.value.trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
    guard rawValue.isBlank == false, isProfileValuePlaceholder(rawValue) == false else { return nil }
    let hasLink = extractProfileExternalURL(rawValue) != nil
    let hasImage = (row.imageURLs ?? row.imageURL.map { [$0] } ?? [])
        .contains { BaGuideTextNormalizer.looksLikeImageURL($0) }
    guard hasLink == false, hasImage == false, isSameNameRoleHintText(rawValue) else { return nil }
    return rawValue
}

nonisolated private func relationKind(for rows: [BaGuideRow]) -> BaStudentProfileRoleRelationKind {
    rows.contains { relationKind(forNormalizedKey: normalizeProfileFieldKey($0.title)) == .related } ? .related : .sameName
}

nonisolated private func relationKind(forNormalizedKey key: String) -> BaStudentProfileRoleRelationKind {
    relatedRoleKeys.contains(key) ? .related : .sameName
}

nonisolated private func isSameNameRoleKey(_ key: String) -> Bool {
    sameNameRoleKeys.contains(key) || relatedRoleKeys.contains(key)
}

nonisolated private func isRelatedRoleHeaderKey(_ key: String) -> Bool {
    relatedRoleHeaderKeys.contains(key) || key == relatedSameNameRoleHeaderKey
}

nonisolated private func isProfileSectionHeaderRow(_ row: BaGuideRow) -> Bool {
    profileSectionHeaderKeys.contains(normalizeProfileFieldKey(row.title))
}

nonisolated private func isGalleryRelatedProfileLinkRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    guard key.isEmpty == false else { return false }
    let hasGalleryLinkKey = galleryRelatedProfileLinkKeyTokens.contains { token in
        token.isEmpty == false && key.contains(token)
    }
    guard hasGalleryLinkKey else { return false }
    return containsGuideWebLink("\(row.title) \(row.value)")
}

nonisolated private func isSkillMigratedProfileRow(
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

nonisolated private func sanitizeProfileFieldValue(key: String, value: String) -> String {
    guard value.isBlank == false else { return "" }
    let normalizedKey = normalizeProfileFieldKey(key)
    var cleaned = value.trimmed
    if normalizedKey == normalizeProfileFieldKey("声优") {
        cleaned = stripProfileCopyHint(cleaned)
    }
    if profileInlineNoteStripFieldKeys.contains(normalizedKey) {
        cleaned = stripGuideInlineNotes(cleaned)
    }
    cleaned = stripProfileInstructionNotes(cleaned)
    return cleaned
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .trimmed
}

nonisolated private func shouldUseProfileValueCapsule(key: String, value: String, externalURL: URL?) -> Bool {
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

nonisolated private func normalizeProfileFieldKey(_ raw: String) -> String {
    raw
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "　", with: "")
        .replacingOccurrences(of: "（", with: "(")
        .replacingOccurrences(of: "）", with: ")")
        .trimmed
        .lowercased()
}

nonisolated private func isProfileValuePlaceholder(_ value: String) -> Bool {
    let normalized = value.trimmed
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

nonisolated private func stripProfileInstructionNotes(_ raw: String) -> String {
    guard raw.isBlank == false else { return "" }
    let pattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard raw.range(of: pattern, options: .regularExpression) != nil else { return raw.trimmed }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map {
            $0.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
                .trimmed
        }
        .filter(\.isNotBlank)
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").trimmed
    }
    return raw
        .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .trimmed
}

nonisolated private func isProfileInstructionPlaceholder(_ value: String) -> Bool {
    guard value.isBlank == false else { return false }
    let pattern = #"(?:<-|←)?\s*(?:这个|这里|此处|这条)?\s*不用写"#
    guard value.range(of: pattern, options: .regularExpression) != nil else { return false }
    return isProfileValuePlaceholder(stripProfileInstructionNotes(value))
}

nonisolated private func stripProfileCopyHint(_ raw: String) -> String {
    guard raw.isBlank == false else { return "" }
    let pattern = #"(?:<-|←)?\s*大部分时候可以去别的图鉴复制"#
    guard raw.range(of: pattern, options: .regularExpression) != nil else { return raw.trimmed }
    let segments = raw
        .components(separatedBy: CharacterSet(charactersIn: "/／|｜,，\n"))
        .map(\.trimmed)
        .filter { $0.isNotBlank && $0.range(of: pattern, options: .regularExpression) == nil }
    if segments.isEmpty == false {
        return segments.joined(separator: " / ").trimmed
    }
    return raw
        .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .trimmed
}

nonisolated private func stripGuideInlineNotes(_ raw: String) -> String {
    raw
        .substringBefore("<-")
        .substringBefore("←")
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .trimmed
}

nonisolated private func isGrowthTitleVoiceRow(_ row: BaGuideRow) -> Bool {
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

nonisolated private func isVoicePlaceholderRow(_ row: BaGuideRow) -> Bool {
    let merged = "\(row.title) \(row.value)".replacingOccurrences(of: " ", with: "")
    return merged.range(of: #"被CC\d+"#, options: .regularExpression) != nil
}

nonisolated private func isLikelySimulateStatLabel(_ raw: String) -> Bool {
    let key = normalizeProfileFieldKey(raw)
    return topDataStatKeys.contains(key) ||
        key.range(of: #"^(初始|顶级|最大|基础)?(攻击力|防御力|生命值|治愈力|命中值|闪避值|暴击值|暴击伤害|稳定值|射程)"#,
                  options: .regularExpression) != nil
}

nonisolated private func splitRoleRowTokens(_ raw: String) -> [String] {
    let linkPattern = #"https?://[^\s|｜]+|/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)|(?<![A-Za-z0-9])\d{4,}(?![A-Za-z0-9])"#
    guard let regex = try? NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive]) else {
        return raw
            .components(separatedBy: CharacterSet(charactersIn: "/／|｜\n"))
            .map(\.trimmed)
            .filter(\.isNotBlank)
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
        .map { replacements[$0.trimmed] ?? $0.trimmed }
        .filter(\.isNotBlank)
}

nonisolated private func extractSameNameGuideURL(_ raw: String) -> URL? {
    BaSameNameStudentGuideLinkResolver.canonicalURL(from: raw)
}

nonisolated private func sameNameRoleNameCandidate(from raw: String) -> String {
    let cleaned = raw
        .replacingOccurrences(of: #"https?://[^\s/／|｜]+"#, with: "", options: [.regularExpression, .caseInsensitive])
        .replacingOccurrences(of: #"https?://[^\s]+"#, with: "", options: [.regularExpression, .caseInsensitive])
        .replacingOccurrences(
            of: #"/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        .replacingOccurrences(of: #"(?<![A-Za-z0-9])\d{4,}(?![A-Za-z0-9])"#, with: "", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；"))
        .trimmed
    guard cleaned.isNotBlank,
          isProfileValuePlaceholder(cleaned) == false,
          isSameNameRoleHintText(cleaned) == false
    else {
        return ""
    }
    return cleaned
}

nonisolated private func sanitizeSameNameLinkToken(_ raw: String) -> String {
    raw.trimmed.trimmingCharacters(in: CharacterSet(charactersIn: ")]},。 ，,;；"))
}

nonisolated private func isSameNameRoleHintText(_ raw: String) -> Bool {
    let value = raw.trimmed
    guard value.isBlank == false else { return false }
    let compact = value
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "　", with: "")
        .lowercased()
    if compact.count >= 20 { return true }
    return sameNameRoleHintKeywords.contains { compact.contains($0.lowercased()) }
}

nonisolated private func extractProfileExternalURL(_ raw: String) -> URL? {
    let source = raw.trimmed
    guard source.isBlank == false else { return nil }
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

nonisolated private func fallbackProfileLinkTitle(_ url: URL) -> String {
    let lastPath = url.lastPathComponent.trimmed
    if lastPath.isNotBlank { return lastPath }
    let host = url.host?.trimmed ?? ""
    return host.ifBlank(url.absoluteString)
}

nonisolated private func containsGuideWebLink(_ raw: String) -> Bool {
    raw.range(of: #"https?://[^\s]+"#, options: [.regularExpression, .caseInsensitive]) != nil ||
        raw.range(of: #"www\.[^\s]+"#, options: [.regularExpression, .caseInsensitive]) != nil
}

nonisolated private func isChocolateGalleryItem(_ item: BaGuideGalleryItem) -> Bool {
    let merged = "\(item.title) \(item.detail) \(item.note ?? "")"
    return merged.localizedCaseInsensitiveContains("巧克力")
}

nonisolated private func isInteractiveFurnitureGalleryItem(_ item: BaGuideGalleryItem) -> Bool {
    let merged = "\(item.title) \(item.detail) \(item.note ?? "")"
    return merged.localizedCaseInsensitiveContains("互动家具")
}

nonisolated private func hasRenderableGalleryMedia(_ item: BaGuideGalleryItem) -> Bool {
    item.mediaURL != nil || item.imageURL != nil
}

nonisolated private func extractOrderedNumbers(_ raw: String) -> [Int] {
    regexMatches(in: raw, pattern: #"\d+"#).compactMap(Int.init)
}

nonisolated private func sortKeyNumbers(_ raw: String) -> (Int, Int) {
    let numbers = extractOrderedNumbers(raw)
    return (numbers.first ?? -1, numbers.dropFirst().first ?? -1)
}

nonisolated private func regexMatches(in raw: String, pattern: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
        return []
    }
    let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
    return regex.matches(in: raw, range: range).compactMap { match in
        guard let range = Range(match.range(at: 0), in: raw) else { return nil }
        return String(raw[range])
    }
}

nonisolated private let relatedSameNameRoleHeaderKey = normalizeProfileFieldKey("相关同名角色")
nonisolated private let sameNameRoleNameRowKey = normalizeProfileFieldKey("同名角色名称")
nonisolated private let relatedRoleHeaderKeys = Set(["相关角色", "相关人物"].map(normalizeProfileFieldKey))
nonisolated private let relatedRoleNameRowKey = normalizeProfileFieldKey("相关角色名称")
nonisolated private let sameNameRoleKeys = Set([relatedSameNameRoleHeaderKey, sameNameRoleNameRowKey])
nonisolated private let relatedRoleKeys = relatedRoleHeaderKeys.union([relatedRoleNameRowKey])
nonisolated private let giftPreferenceRowPrefixKey = normalizeProfileFieldKey("礼物偏好礼物")
nonisolated private let profileSectionHeaderKeys = Set(["介绍", "学生信息", "信息"].map(normalizeProfileFieldKey))
nonisolated private let galleryRelatedProfileLinkKeyTokens = [
    "影画相关链接", "相关链接", "来源链接", "个人账号主页", "账号主页", "个人主页", "主页链接", "主页",
].map(normalizeProfileFieldKey)
nonisolated private let sameNameRoleHintKeywords = [
    "暂无同名角色", "未填写", "占位", "说明", "备注", "复制", "不用写", "暂时没", "待补充",
]

private extension Array where Element == BaGuideRow {
    nonisolated func sortedByKeyNumbers() -> [BaGuideRow] {
        sorted {
            let lhs = sortKeyNumbers($0.title)
            let rhs = sortKeyNumbers($1.title)
            if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return normalizeProfileFieldKey($0.title) < normalizeProfileFieldKey($1.title)
        }
    }
}

private extension Array where Element == BaGuideGalleryItem {
    nonisolated func distinctByMedia() -> [BaGuideGalleryItem] {
        var seen = Set<String>()
        return filter { item in
            let media = item.mediaURL ?? item.imageURL
            let key = "\(item.mediaKind?.rawValue ?? "")|\(media?.absoluteString ?? item.id)"
            return seen.insert(key).inserted
        }
    }

    nonisolated func sortedByTitleNumbers() -> [BaGuideGalleryItem] {
        sorted {
            let lhs = sortKeyNumbers($0.title)
            let rhs = sortKeyNumbers($1.title)
            if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return $0.title < $1.title
        }
    }
}

private extension Array where Element == URL {
    nonisolated func dedupedByAbsoluteString() -> [URL] {
        var seen = Set<String>()
        return filter { seen.insert($0.absoluteString).inserted }
    }
}

private extension Array where Element == String {
    nonisolated func deduped() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    nonisolated var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var isBlank: Bool {
        trimmed.isEmpty
    }

    nonisolated var isNotBlank: Bool {
        isBlank == false
    }

    nonisolated var nonEmptyUnlessPlaceholder: String? {
        let value = trimmed
        guard value.isNotBlank, isProfileValuePlaceholder(value) == false else { return nil }
        return value
    }

    nonisolated func ifBlank(_ fallback: String) -> String {
        isBlank ? fallback : self
    }

    nonisolated func substringBefore(_ delimiter: String) -> String {
        guard let range = range(of: delimiter) else { return self }
        return String(self[..<range.lowerBound])
    }
}
