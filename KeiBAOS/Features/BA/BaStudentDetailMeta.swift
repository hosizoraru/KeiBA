//
//  BaStudentDetailMeta.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideMetaItem: Identifiable, Hashable {
    let title: String
    let value: String
    let imageURL: URL?
    var extraImageURL: URL?
    var imageRepeatCount = 1

    var id: String {
        "\(title)|\(value)|\(imageURL?.absoluteString ?? "")|\(extraImageURL?.absoluteString ?? "")|\(imageRepeatCount)"
    }
}

enum BaStudentGuideMeta {
    nonisolated static func profileMetaItems(from info: BaStudentGuideInfo) -> [BaGuideMetaItem] {
        [
            buildMetaItem(
                title: String(localized: "ba.student.detail.meta.rarity"),
                role: .rarity,
                valueKeywords: ["稀有度", "星级"],
                rows: info.profileDisplayRows,
                stats: info.stats
            ),
            buildMetaItem(
                title: String(localized: "ba.student.detail.meta.academy"),
                role: .academy,
                valueKeywords: ["所属学园", "所属学院", "学园", "学院", "school"],
                rows: info.profileDisplayRows,
                stats: info.stats
            ),
            buildMetaItem(
                title: String(localized: "ba.student.detail.meta.club"),
                role: .club,
                valueKeywords: ["所属社团", "社团"],
                rows: info.profileDisplayRows,
                stats: info.stats
            ),
        ]
    }

    nonisolated static func combatMetaItems(from info: BaStudentGuideInfo) -> [BaGuideMetaItem] {
        let rows = info.profileDisplayRows + info.skillDisplayRows
        return [
            tacticalPositionItem(info: info, rows: rows),
            combatFieldItem(
                title: String(localized: "ba.student.detail.meta.attackType"),
                role: .attackType,
                valueKeywords: ["攻击类型"],
                rows: rows,
                stats: info.stats
            ),
            combatFieldItem(
                title: String(localized: "ba.student.detail.meta.defenseType"),
                role: .defenseType,
                valueKeywords: ["防御类型"],
                rows: rows,
                stats: info.stats
            ),
            weaponTypeItem(rows: rows, stats: info.stats),
            combatFieldItem(
                title: String(localized: "ba.student.detail.meta.street"),
                role: .terrain,
                valueKeywords: ["市街"],
                rows: rows,
                stats: info.stats
            ),
            combatFieldItem(
                title: String(localized: "ba.student.detail.meta.outdoor"),
                role: .terrain,
                valueKeywords: ["屋外"],
                rows: rows,
                stats: info.stats
            ),
            combatFieldItem(
                title: String(localized: "ba.student.detail.meta.indoor"),
                role: .terrain,
                valueKeywords: ["屋内", "室内"],
                rows: rows,
                stats: info.stats
            ),
        ]
    }

    nonisolated static func shouldHideMovedHeaderRow(_ row: BaGuideRow) -> Bool {
        let key = row.title
        let movedKeywords = [
            "头像", "角色头像", "角色图片",
            "稀有度", "星级", "学院", "学园", "所属学园", "所属学院", "所属社团",
            "战术位置作用", "战术位置", "战术作用", "攻击类型", "防御类型", "位置", "武器类型",
            "市街", "屋外", "屋内", "室内",
        ]
        if movedKeywords.contains(where: { key.localizedCaseInsensitiveContains($0) }) {
            return true
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("作用") == .orderedSame
    }

    private nonisolated static func tacticalPositionItem(
        info: BaStudentGuideInfo,
        rows: [BaGuideRow]
    ) -> BaGuideMetaItem {
        let iconRows = rows + info.stats
        let tacticalRow = findFirstRowByTitleKeywords(
            rows: iconRows,
            keywords: ["战术作用", "战术位置作用"],
            requireImage: true
        )
        let combinedRow = findFirstRowByTitleKeywords(
            rows: iconRows,
            keywords: ["战术位置作用"],
            requireImage: true
        )
        let positionRow = findFirstRowByExactTitleKeywords(rows: iconRows, keywords: ["位置"], requireImage: true)
        let tacticalIcon = imageURL(in: tacticalRow, at: 0) ?? imageURL(in: combinedRow, at: 0)
        let positionIcon = imageURL(in: positionRow, at: 0) ?? imageURL(in: combinedRow, at: 1)
        return BaGuideMetaItem(
            title: String(localized: "ba.student.detail.meta.tacticalPosition"),
            value: sanitizeMetaValue(
                role: .tacticalPosition,
                raw: findGuideFieldValue(
                    keywords: ["作用", "战术位置作用", "战术作用"],
                    rows: info.profileDisplayRows,
                    stats: info.stats
                )
            ),
            imageURL: tacticalIcon,
            extraImageURL: positionIcon
        )
    }

    private nonisolated static func weaponTypeItem(rows: [BaGuideRow], stats: [BaGuideRow]) -> BaGuideMetaItem {
        let weapon = combatFieldItem(
            title: String(localized: "ba.student.detail.meta.weaponType"),
            role: .weaponType,
            valueKeywords: ["武器类型"],
            rows: rows,
            stats: stats
        )
        return BaGuideMetaItem(
            title: weapon.title,
            value: normalizeWeaponTypeMetaValue(weapon.value),
            imageURL: weapon.imageURL,
            extraImageURL: weapon.extraImageURL
        )
    }

    private nonisolated static func combatFieldItem(
        title: String,
        role: MetaRole,
        valueKeywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow]
    ) -> BaGuideMetaItem {
        buildMetaItem(
            title: title,
            role: role,
            valueKeywords: valueKeywords,
            rows: rows,
            stats: stats
        )
    }

    private nonisolated static func buildMetaItem(
        title: String,
        role: MetaRole,
        valueKeywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow]
    ) -> BaGuideMetaItem {
        let iconRow = findFirstRowByTitleKeywords(rows: rows + stats, keywords: valueKeywords, requireImage: true)
        let value = sanitizeMetaValue(
            role: role,
            raw: findGuideFieldValue(keywords: valueKeywords, rows: rows, stats: stats)
        )
        return BaGuideMetaItem(
            title: title,
            value: value,
            imageURL: iconRow?.imageURL,
            imageRepeatCount: role == .rarity ? rarityImageRepeatCount(from: value) : 1
        )
    }

    private nonisolated static func findGuideFieldValue(
        keywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow]
    ) -> String {
        let normalizedKeywords = keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        guard normalizedKeywords.isEmpty == false else { return "-" }

        let allRows = rows + stats
        func isUsableValue(_ value: String) -> Bool {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty == false && isMediaFilenameValue(trimmed) == false
        }
        func normalized(_ key: String) -> String {
            BaGuideTextNormalizer.normalizedKey(key)
        }

        for keyword in normalizedKeywords {
            let normalizedKeyword = normalized(keyword)
            if let row = allRows.first(where: {
                normalized($0.title) == normalizedKeyword && isUsableValue($0.value)
            }) {
                return row.value
            }
        }
        if let row = allRows.first(where: { row in
            normalizedKeywords.contains { row.title.localizedCaseInsensitiveContains($0) } &&
                isUsableValue(row.value)
        }) {
            return row.value
        }
        if let row = allRows.first(where: { row in
            let merged = "\(row.title) \(row.value)"
            return normalizedKeywords.contains { merged.localizedCaseInsensitiveContains($0) } &&
                isUsableValue(row.value)
        }) {
            return row.value
        }
        return "-"
    }

    private nonisolated static func findFirstRowByTitleKeywords(
        rows: [BaGuideRow],
        keywords: [String],
        requireImage: Bool
    ) -> BaGuideRow? {
        rows.first { row in
            let hasKeyword = keywords.contains { row.title.localizedCaseInsensitiveContains($0) }
            return hasKeyword && (requireImage == false || row.imageURL != nil)
        }
    }

    private nonisolated static func findFirstRowByExactTitleKeywords(
        rows: [BaGuideRow],
        keywords: [String],
        requireImage: Bool
    ) -> BaGuideRow? {
        rows.first { row in
            let normalizedTitle = BaGuideTextNormalizer.normalizedKey(row.title)
            let hasKeyword = keywords.contains {
                normalizedTitle == BaGuideTextNormalizer.normalizedKey($0)
            }
            return hasKeyword && (requireImage == false || row.imageURL != nil)
        }
    }

    private nonisolated static func imageURL(in row: BaGuideRow?, at index: Int) -> URL? {
        guard let row else { return nil }
        let urls = row.imageURLs ?? row.imageURL.map { [$0] } ?? []
        guard urls.indices.contains(index) else { return nil }
        return urls[index]
    }

    private nonisolated static func sanitizeMetaValue(role: MetaRole, raw: String) -> String {
        let cleaned = stripInlineNotes(raw)
        guard cleaned.isEmpty == false, cleaned != "-", isMediaFilenameValue(cleaned) == false else {
            return String(localized: "ba.common.none")
        }
        if role == .rarity || role == .academy || role == .tacticalPosition {
            let segments = splitSlashSegments(cleaned)
            if let first = segments.first, segments.dropFirst().contains(where: isLikelyGuideNoteSegment) {
                return first
            }
        }
        return cleaned
    }

    private nonisolated static func stripInlineNotes(_ raw: String) -> String {
        raw
            .substringBefore("<-")
            .substringBefore("←")
            .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；").union(.whitespacesAndNewlines))
    }

    private nonisolated static func splitSlashSegments(_ raw: String) -> [String] {
        raw
            .replacingOccurrences(of: "／", with: "/")
            .replacingOccurrences(of: "|", with: "/")
            .replacingOccurrences(of: "｜", with: "/")
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private nonisolated static func isLikelyGuideNoteSegment(_ raw: String) -> Bool {
        let compact = raw.replacingOccurrences(of: " ", with: "").lowercased()
        guard compact.isEmpty == false else { return true }
        if ["-", "--", "—", "...", "…"].contains(compact) { return true }
        return ["可以用", "后面的", "后面", "图标", "替换", "占位", "备注", "说明", "注释", "样式", "不用写", "待补", "todo", "tbd"]
            .contains { compact.contains($0.lowercased()) }
    }

    private nonisolated static func isMediaFilenameValue(_ raw: String) -> Bool {
        let value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: "?")
            .first
            .map(String.init) ?? ""
        return value.range(of: #"\.(png|jpe?g|webp|gif|svg)$"#, options: .regularExpression) != nil
    }

    private nonisolated static func rarityImageRepeatCount(from raw: String) -> Int {
        let compact = raw.replacingOccurrences(of: " ", with: "")
        let starCount = compact.filter { $0 == "★" || $0 == "⭐" }.count
        if starCount > 0 {
            return min(max(starCount, 1), 5)
        }
        if let range = compact.range(of: #"\d+"#, options: .regularExpression),
           let count = Int(compact[range])
        {
            return min(max(count, 1), 5)
        }
        return 1
    }

    private nonisolated static func normalizeWeaponTypeMetaValue(_ raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value == "-" || value == String(localized: "ba.common.none") {
            return String(localized: "ba.common.none")
        }
        if value == "原网站暂无该数据" {
            return String(localized: "ba.common.none")
        }
        let compact = value.replacingOccurrences(of: " ", with: "")
        let hasPlaceholderHints = compact.contains("这一行") ||
            compact.contains("素材") ||
            compact.contains("占位") ||
            compact.contains("请填写") ||
            compact.contains("暂无")
        return hasPlaceholderHints || compact.count > 18 ? String(localized: "ba.common.none") : value
    }

    private nonisolated enum MetaRole {
        case rarity
        case academy
        case club
        case tacticalPosition
        case attackType
        case defenseType
        case weaponType
        case terrain
    }
}

extension BaStudentGuideInfo {
    nonisolated var profileDisplayRows: [BaGuideRow] {
        profileRows.isEmpty ? stats : profileRows
    }

    nonisolated var skillDisplayRows: [BaGuideRow] {
        if skillRows.isEmpty == false {
            return skillRows
        }
        return stats.filter { row in
            let merged = "\(row.title) \(row.value)"
            return ["技能", "EX", "普通技能", "被动技能", "辅助技能"].contains {
                merged.localizedCaseInsensitiveContains($0)
            }
        }
    }

    nonisolated var growthDisplayRows: [BaGuideRow] {
        if growthRows.isEmpty == false {
            return growthRows
        }
        return stats.filter { row in
            let merged = "\(row.title) \(row.value)"
            return ["装备", "专武", "爱用品", "能力解放", "羁绊", "升级材料", "所需"].contains {
                merged.localizedCaseInsensitiveContains($0)
            }
        }
    }

    nonisolated var overviewProfileRows: [BaGuideRow] {
        profileDisplayRows.filter { BaStudentGuideMeta.shouldHideMovedHeaderRow($0) == false }
    }

    nonisolated func preferredPortraitURL(fallback: URL?) -> URL? {
        imageURL ?? fallback
    }
}

private extension String {
    nonisolated func substringBefore(_ delimiter: String) -> String {
        guard let range = range(of: delimiter) else { return self }
        return String(self[..<range.lowerBound])
    }
}
