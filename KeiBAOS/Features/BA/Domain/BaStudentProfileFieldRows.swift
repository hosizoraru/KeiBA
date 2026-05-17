//
//  BaStudentProfileFieldRows.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

struct BaStudentProfileFieldSpec {
    let title: String
    let aliases: [String]
    let hideWhenEmpty: Bool

    init(_ title: String, aliases: [String], hideWhenEmpty: Bool = false) {
        self.title = title
        self.aliases = aliases
        self.hideWhenEmpty = hideWhenEmpty
    }
}

nonisolated let nicknameFieldSpecs = [
    BaStudentProfileFieldSpec("角色名称", aliases: ["角色名称"]),
    BaStudentProfileFieldSpec("全名", aliases: ["全名"]),
    BaStudentProfileFieldSpec("假名注音", aliases: ["假名注音", "假名注明"]),
    BaStudentProfileFieldSpec("繁中译名", aliases: ["繁中译名"]),
    BaStudentProfileFieldSpec("简中译名", aliases: ["简中译名"]),
]

nonisolated let studentInfoFieldSpecs = [
    BaStudentProfileFieldSpec("年龄", aliases: ["年龄"]),
    BaStudentProfileFieldSpec("生日", aliases: ["生日"]),
    BaStudentProfileFieldSpec("身高", aliases: ["身高"]),
    BaStudentProfileFieldSpec("画师", aliases: ["画师", "原画师"]),
    BaStudentProfileFieldSpec("实装日期", aliases: ["实装日期", "首次登场日期"]),
    BaStudentProfileFieldSpec("声优", aliases: ["声优"]),
    BaStudentProfileFieldSpec("角色考据", aliases: ["角色考据"], hideWhenEmpty: true),
    BaStudentProfileFieldSpec("设计", aliases: ["设计", "设计师"], hideWhenEmpty: true),
]

nonisolated let hobbyFieldSpecs = [
    BaStudentProfileFieldSpec("兴趣爱好", aliases: ["兴趣爱好"]),
    BaStudentProfileFieldSpec("个人简介", aliases: ["个人简介"]),
    BaStudentProfileFieldSpec("MomoTalk状态消息", aliases: ["MomoTalk状态消息", "Momotalk状态消息"]),
    BaStudentProfileFieldSpec("MomoTalk解锁等级", aliases: ["MomoTalk解锁等级", "Momotalk解锁等级"], hideWhenEmpty: true),
]

nonisolated func buildProfileCardRows(
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

nonisolated func visibleProfileRow(
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
    if cleanedValue.baProfileIsBlank, hasImage {
        displayValue = BaL10n.string("ba.student.detail.profile.imageBelow")
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

nonisolated func fieldRow(
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

nonisolated func isProfileRowAliasMatch(_ row: BaGuideRow, aliases: [String]) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    guard key.isEmpty == false else { return false }
    return aliases.contains { key == normalizeProfileFieldKey($0) }
}

nonisolated func isStructuredProfileCardRow(_ row: BaGuideRow) -> Bool {
    let specs = nicknameFieldSpecs + studentInfoFieldSpecs + hobbyFieldSpecs
    return specs.contains { spec in
        isProfileRowAliasMatch(row, aliases: spec.aliases)
    }
}

nonisolated func isGiftPreferenceProfileRow(_ row: BaGuideRow) -> Bool {
    let key = normalizeProfileFieldKey(row.title)
    return key.hasPrefix(giftPreferenceRowPrefixKey) ||
        (row.id.hasPrefix("gift-") && row.imageURL != nil) ||
        (key.hasPrefix(normalizeProfileFieldKey("礼物")) && row.imageURL != nil)
}
