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
    var extraValue: String? = nil
    let imageURL: URL?
    var extraImageURL: URL? = nil

    var id: String {
        "\(title)|\(value)|\(extraValue ?? "")|\(imageURL?.absoluteString ?? "")|\(extraImageURL?.absoluteString ?? "")"
    }
}

enum BaStudentGuideMeta {
    nonisolated static func profileMetaItems(from info: BaStudentGuideInfo) -> [BaGuideMetaItem] {
        [
            buildMetaItem(
                title: BaL10n.string("ba.student.detail.meta.rarity"),
                role: .rarity,
                valueKeywords: ["稀有度", "星级"],
                rows: info.profileDisplayRows,
                stats: info.stats
            ),
            buildMetaItem(
                title: BaL10n.string("ba.student.detail.meta.academy"),
                role: .academy,
                valueKeywords: ["所属学园", "所属学院", "学园", "学院", "school"],
                rows: info.profileDisplayRows,
                stats: info.stats,
                valuePriority: academyValuePriority
            ),
            buildMetaItem(
                title: BaL10n.string("ba.student.detail.meta.club"),
                role: .club,
                valueKeywords: ["所属社团", "社团"],
                rows: info.profileDisplayRows,
                stats: info.stats
            ),
        ]
    }

    nonisolated static func profileMetaItems(
        from info: BaStudentGuideInfo,
        category: BaCatalogCategory
    ) -> [BaGuideMetaItem] {
        guard category == .npcSatellite else {
            return profileMetaItems(from: info)
        }
        return npcSatelliteProfileMetaItems(from: info)
    }

    nonisolated static func combatMetaItems(from info: BaStudentGuideInfo) -> [BaGuideMetaItem] {
        let rows = info.profileDisplayRows + info.skillDisplayRows
        return [
            tacticalPositionItem(info: info, rows: rows),
            combatFieldItem(
                title: BaL10n.string("ba.student.detail.meta.attackType"),
                role: .attackType,
                valueKeywords: ["攻击类型"],
                rows: rows,
                stats: info.stats
            ),
            combatFieldItem(
                title: BaL10n.string("ba.student.detail.meta.defenseType"),
                role: .defenseType,
                valueKeywords: ["防御类型"],
                rows: rows,
                stats: info.stats
            ),
            weaponTypeItem(rows: rows, stats: info.stats),
            combatFieldItem(
                title: BaL10n.string("ba.student.detail.meta.street"),
                role: .terrain,
                valueKeywords: ["市街"],
                rows: rows,
                stats: info.stats,
                valuePriority: terrainValuePriority
            ),
            combatFieldItem(
                title: BaL10n.string("ba.student.detail.meta.outdoor"),
                role: .terrain,
                valueKeywords: ["屋外"],
                rows: rows,
                stats: info.stats,
                valuePriority: terrainValuePriority
            ),
            combatFieldItem(
                title: BaL10n.string("ba.student.detail.meta.indoor"),
                role: .terrain,
                valueKeywords: ["屋内", "室内"],
                rows: rows,
                stats: info.stats,
                valuePriority: terrainValuePriority
            ),
        ]
    }

    nonisolated static func shouldHideMovedHeaderRow(_ row: BaGuideRow) -> Bool {
        let key = row.title
        let movedKeywords = [
            "头像", "角色头像", "角色图片",
            "稀有度", "星级", "学院", "学园", "所属", "所属学园", "所属学院", "所属社团",
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
        let tacticalRow = findBestRowByTitleKeywords(
            rows: iconRows,
            keywords: ["战术位置作用", "战术作用"],
            requireImage: true,
            valuePriority: tacticalRoleValuePriority
        )
        let combinedRow = findBestRowByTitleKeywords(
            rows: iconRows,
            keywords: ["战术位置作用", "战术作用", "作用"],
            requireImage: true,
            valuePriority: tacticalRoleValuePriority
        )
        let positionRow = findBestRowByTitleKeywords(
            rows: iconRows,
            keywords: ["位置"],
            requireImage: true,
            valuePriority: positionValuePriority
        )
        let tacticalIcon = imageURL(in: tacticalRow, at: 0) ?? imageURL(in: combinedRow, at: 0)
        let positionIcon = imageURL(in: positionRow, at: 0) ?? imageURL(in: combinedRow, at: 1)
        let tacticalValue = sanitizeMetaValue(
            role: .tacticalPosition,
            raw: findGuideFieldValue(
                keywords: ["作用", "战术位置作用", "战术作用"],
                rows: rows,
                stats: info.stats,
                valuePriority: tacticalRoleValuePriority
            )
        )
        let positionValue = sanitizeMetaValue(
            role: .position,
            raw: findGuideFieldValue(
                keywords: ["位置"],
                rows: iconRows,
                stats: info.stats,
                valuePriority: positionValuePriority
            )
        )
        return BaGuideMetaItem(
            title: BaL10n.string("ba.student.detail.meta.tacticalPosition"),
            value: tacticalValue,
            extraValue: positionValue == BaL10n.string("ba.common.none") ? nil : positionValue,
            imageURL: tacticalIcon,
            extraImageURL: positionIcon
        )
    }

    private nonisolated static func weaponTypeItem(rows: [BaGuideRow], stats: [BaGuideRow]) -> BaGuideMetaItem {
        let weapon = combatFieldItem(
            title: BaL10n.string("ba.student.detail.meta.weaponType"),
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
        stats: [BaGuideRow],
        valuePriority: ((String) -> Int)? = nil
    ) -> BaGuideMetaItem {
        buildMetaItem(
            title: title,
            role: role,
            valueKeywords: valueKeywords,
            rows: rows,
            stats: stats,
            valuePriority: valuePriority
        )
    }

    private nonisolated static func npcSatelliteProfileMetaItems(from info: BaStudentGuideInfo) -> [BaGuideMetaItem] {
        let rows = info.profileDisplayRows
        let stats = info.stats
        let items = [
            buildExactProfileMetaItem(
                title: BaL10n.string("ba.student.detail.meta.rarity"),
                role: .rarity,
                titleKeywords: ["稀有度", "星级"],
                rows: rows,
                stats: stats
            ),
            buildExactProfileMetaItem(
                title: BaL10n.string("ba.student.detail.meta.belongs"),
                role: .affiliation,
                titleKeywords: ["所属", "阵营"],
                rows: rows,
                stats: stats
            ),
            buildExactProfileMetaItem(
                title: BaL10n.string("ba.student.detail.meta.academy"),
                role: .academy,
                titleKeywords: ["所属学园", "所属学院", "学园", "学院", "school"],
                rows: rows,
                stats: stats,
                valuePriority: academyValuePriority
            ),
            buildExactProfileMetaItem(
                title: BaL10n.string("ba.student.detail.meta.club"),
                role: .club,
                titleKeywords: ["所属社团", "社团"],
                rows: rows,
                stats: stats
            ),
        ]
            .compactMap(\.self)
            .filter { $0.hasMeaningfulGuideValue }
        return deduplicatedMetaItems(items)
    }

    private nonisolated static func buildExactProfileMetaItem(
        title: String,
        role: MetaRole,
        titleKeywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow],
        valuePriority: ((String) -> Int)? = nil
    ) -> BaGuideMetaItem? {
        let allRows = rows + stats
        let candidates = fieldCandidates(
            rows: allRows,
            keywords: titleKeywords,
            requireImage: false,
            requireUsableValue: true,
            valuePriority: valuePriority,
            exactMatchOnly: true,
            allowsValueMatch: false
        )
        guard let best = candidates.max(by: { isWorseCandidate($0, than: $1) }) else {
            return nil
        }
        let iconRow = findBestRowByExactTitleKeywords(
            rows: allRows,
            keywords: titleKeywords,
            requireImage: true,
            valuePriority: valuePriority
        )
        return BaGuideMetaItem(
            title: title,
            value: sanitizeMetaValue(role: role, raw: best.value),
            imageURL: iconRow?.imageURL
        )
    }

    private nonisolated static func findBestRowByExactTitleKeywords(
        rows: [BaGuideRow],
        keywords: [String],
        requireImage: Bool,
        valuePriority: ((String) -> Int)? = nil
    ) -> BaGuideRow? {
        fieldCandidates(
            rows: rows,
            keywords: keywords,
            requireImage: requireImage,
            requireUsableValue: false,
            valuePriority: valuePriority,
            exactMatchOnly: true,
            allowsValueMatch: false
        )
        .max(by: { isWorseCandidate($0, than: $1) })?
        .row
    }

    private nonisolated static func deduplicatedMetaItems(_ items: [BaGuideMetaItem]) -> [BaGuideMetaItem] {
        var seen = Set<String>()
        return items.filter { item in
            let key = [
                BaGuideTextNormalizer.normalizedKey(item.title),
                BaGuideTextNormalizer.normalizedKey(item.value),
            ]
                .joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    private nonisolated static func buildMetaItem(
        title: String,
        role: MetaRole,
        valueKeywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow],
        valuePriority: ((String) -> Int)? = nil
    ) -> BaGuideMetaItem {
        let iconRow = findBestRowByTitleKeywords(
            rows: rows + stats,
            keywords: valueKeywords,
            requireImage: true,
            valuePriority: valuePriority
        )
        let value = sanitizeMetaValue(
            role: role,
            raw: findGuideFieldValue(
                keywords: valueKeywords,
                rows: rows,
                stats: stats,
                valuePriority: valuePriority
            )
        )
        return BaGuideMetaItem(
            title: title,
            value: value,
            imageURL: iconRow?.imageURL
        )
    }

    private nonisolated static func findGuideFieldValue(
        keywords: [String],
        rows: [BaGuideRow],
        stats: [BaGuideRow],
        valuePriority: ((String) -> Int)? = nil
    ) -> String {
        let normalizedKeywords = keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        guard normalizedKeywords.isEmpty == false else { return "-" }
        let allRows = rows + stats
        let exactCandidates = fieldCandidates(
            rows: allRows,
            keywords: normalizedKeywords,
            requireImage: false,
            requireUsableValue: true,
            valuePriority: valuePriority,
            exactMatchOnly: true,
            allowsValueMatch: false
        )
        if let best = exactCandidates.max(by: { isWorseCandidate($0, than: $1) }) {
            return best.value
        }
        let looseCandidates = fieldCandidates(
            rows: allRows,
            keywords: normalizedKeywords,
            requireImage: false,
            requireUsableValue: true,
            valuePriority: valuePriority,
            exactMatchOnly: false,
            allowsValueMatch: false
        )
        if let best = looseCandidates.max(by: { isWorseCandidate($0, than: $1) }) {
            return best.value
        }
        let valueFallbackCandidates = fieldCandidates(
            rows: allRows,
            keywords: normalizedKeywords,
            requireImage: false,
            requireUsableValue: true,
            valuePriority: valuePriority,
            exactMatchOnly: false,
            allowsValueMatch: true
        )
        if let best = valueFallbackCandidates.max(by: { isWorseCandidate($0, than: $1) }) {
            return best.value
        }
        return "-"
    }

    private nonisolated static func findBestRowByTitleKeywords(
        rows: [BaGuideRow],
        keywords: [String],
        requireImage: Bool,
        valuePriority: ((String) -> Int)? = nil
    ) -> BaGuideRow? {
        let normalizedKeywords = keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        guard normalizedKeywords.isEmpty == false else { return nil }
        let exactCandidates = fieldCandidates(
            rows: rows,
            keywords: normalizedKeywords,
            requireImage: requireImage,
            requireUsableValue: false,
            valuePriority: valuePriority,
            exactMatchOnly: true,
            allowsValueMatch: true
        )
        if let best = exactCandidates.max(by: { isWorseCandidate($0, than: $1) }) {
            return best.row
        }
        let looseCandidates = fieldCandidates(
            rows: rows,
            keywords: normalizedKeywords,
            requireImage: requireImage,
            requireUsableValue: false,
            valuePriority: valuePriority,
            exactMatchOnly: false,
            allowsValueMatch: true
        )
        return looseCandidates.max(by: { isWorseCandidate($0, than: $1) })?.row
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
            return BaL10n.string("ba.common.none")
        }
        if cleaned == "无", role == .academy || role == .tacticalPosition || role == .position || role == .terrain {
            return BaL10n.string("ba.common.none")
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

    private nonisolated static func fieldCandidates(
        rows: [BaGuideRow],
        keywords: [String],
        requireImage: Bool,
        requireUsableValue: Bool,
        valuePriority: ((String) -> Int)?,
        exactMatchOnly: Bool,
        allowsValueMatch: Bool
    ) -> [GuideFieldCandidate] {
        rows.compactMap { row in
            guard let titleScore = fieldMatchScore(
                title: row.title,
                value: row.value,
                keywords: keywords,
                exactMatchOnly: exactMatchOnly,
                allowsValueMatch: allowsValueMatch
            ) else {
                return nil
            }
            if requireImage, row.imageURL == nil {
                return nil
            }
            let cleanedValue = stripInlineNotes(row.value)
            if requireUsableValue, cleanedValue.isEmpty || isMediaFilenameValue(cleanedValue) {
                return nil
            }
            let score = titleScore + (valuePriority?(cleanedValue) ?? 0)
            return GuideFieldCandidate(row: row, value: cleanedValue, score: score)
        }
    }

    private nonisolated static func fieldMatchScore(
        title: String,
        value: String,
        keywords: [String],
        exactMatchOnly: Bool,
        allowsValueMatch: Bool
    ) -> Int? {
        let normalizedTitle = BaGuideTextNormalizer.normalizedKey(title)
        let normalizedValue = BaGuideTextNormalizer.normalizedKey(value)
        var bestScore: Int?
        for keyword in keywords {
            let normalizedKeyword = BaGuideTextNormalizer.normalizedKey(keyword)
            if normalizedTitle == normalizedKeyword {
                return 1_000
            }
            if allowsValueMatch, normalizedValue == normalizedKeyword {
                bestScore = max(bestScore ?? 0, 950)
                continue
            }
            guard exactMatchOnly == false else { continue }
            if normalizedTitle.localizedCaseInsensitiveContains(normalizedKeyword) ||
                normalizedKeyword.localizedCaseInsensitiveContains(normalizedTitle)
            {
                bestScore = max(bestScore ?? 0, 500)
            }
            if allowsValueMatch,
               normalizedValue.localizedCaseInsensitiveContains(normalizedKeyword) ||
                normalizedKeyword.localizedCaseInsensitiveContains(normalizedValue)
            {
                bestScore = max(bestScore ?? 0, 450)
            }
        }
        return bestScore
    }

    private nonisolated static func isWorseCandidate(_ lhs: GuideFieldCandidate, than rhs: GuideFieldCandidate) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score < rhs.score
        }
        if lhs.value.count != rhs.value.count {
            return lhs.value.count > rhs.value.count
        }
        return lhs.row.id > rhs.row.id
    }

    private nonisolated static func academyValuePriority(_ value: String) -> Int {
        let compact = value.replacingOccurrences(of: " ", with: "")
        var score = 0
        if compact.contains("学园") || compact.contains("学院") || compact.lowercased().contains("school") {
            score += 200
        }
        if compact.count <= 12 {
            score += 30
        }
        if compact.count > 18 {
            score -= 120
        }
        if compact.contains("。") || compact.contains("，") || compact.contains("、") {
            score -= 60
        }
        return score
    }

    private nonisolated static func tacticalRoleValuePriority(_ value: String) -> Int {
        let compact = value.replacingOccurrences(of: " ", with: "")
        var score = 0
        if ["输出", "坦克", "防御", "辅助", "治疗", "支援", "前卫", "中卫", "后卫"].contains(compact) {
            score += 200
        }
        if compact == "无" || compact == "-" {
            score -= 300
        }
        if compact.count <= 4 {
            score += 40
        }
        if compact.count > 8 {
            score -= 80
        }
        if compact.contains("。") || compact.contains("，") || compact.contains("、") {
            score -= 50
        }
        return score
    }

    private nonisolated static func positionValuePriority(_ value: String) -> Int {
        let compact = value.replacingOccurrences(of: " ", with: "")
        var score = 0
        if ["前卫", "中卫", "后卫"].contains(compact) {
            score += 200
        }
        if compact == "无" || compact == "-" {
            score -= 200
        }
        if compact.count <= 3 {
            score += 20
        }
        return score
    }

    private nonisolated static func terrainValuePriority(_ value: String) -> Int {
        let compact = value.replacingOccurrences(of: " ", with: "")
        var score = 0
        if compact.range(of: #"^[SABCDE][+-]?$"#, options: .regularExpression) != nil {
            score += 200
        }
        if compact == "无" || compact == "-" {
            score -= 300
        }
        if compact.count <= 2 {
            score += 30
        }
        if compact.count > 6 {
            score -= 80
        }
        return score
    }

    private nonisolated static func normalizeWeaponTypeMetaValue(_ raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value == "-" || value == BaL10n.string("ba.common.none") {
            return BaL10n.string("ba.common.none")
        }
        if value == "原网站暂无该数据" {
            return BaL10n.string("ba.common.none")
        }
        let compact = value.replacingOccurrences(of: " ", with: "")
        let hasPlaceholderHints = compact.contains("这一行") ||
            compact.contains("素材") ||
            compact.contains("占位") ||
            compact.contains("请填写") ||
            compact.contains("暂无")
        return hasPlaceholderHints || compact.count > 18 ? BaL10n.string("ba.common.none") : value
    }

    private nonisolated enum MetaRole {
        case rarity
        case affiliation
        case academy
        case club
        case tacticalPosition
        case position
        case attackType
        case defenseType
        case weaponType
        case terrain
    }

    private struct GuideFieldCandidate {
        let row: BaGuideRow
        let value: String
        let score: Int
    }
}

private extension BaGuideMetaItem {
    nonisolated var hasMeaningfulGuideValue: Bool {
        value.hasMeaningfulMetaValue ||
            extraValue?.hasMeaningfulMetaValue == true ||
            imageURL != nil ||
            extraImageURL != nil
    }
}

private extension String {
    nonisolated var hasMeaningfulMetaValue: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = normalized
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .lowercased()
        guard normalized.isEmpty == false else { return false }
        return normalized != BaL10n.string("ba.common.none") &&
            normalized != "-" &&
            normalized != "—" &&
            normalized != "--" &&
            normalized != "暂无" &&
            normalized != "无" &&
            compact != "n" &&
            compact != "none" &&
            compact != "null" &&
            compact != "undefined" &&
            compact != "nan"
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
