//
//  BaGuideBaseDataParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideBaseDataParser {
    func parse(baseData: [[BaJSONObject]], sourceURL: URL?) -> BaStructuredGuideParse {
        var parsed = BaStructuredGuideParse()
        var seen = Set<String>()
        for (index, row) in baseData.enumerated() {
            guard let keyCell = row.first else { continue }
            let rawKey = keyCell.string("value") ?? ""
            let key = BaGuideTextNormalizer.clean(rawKey)
            let values = row.dropFirst()
                .compactMap { $0.string("value") }
                .map(BaGuideTextNormalizer.cleanDisplayText)
                .filter { $0.isEmpty == false }
            let value = values.joined(separator: " / ")
            let imageURLs = BaGuideTextNormalizer.imageURLs(in: Array(row), sourceURL: sourceURL)
            guard key.isEmpty == false || value.isEmpty == false || imageURLs.isEmpty == false else { continue }

            let title = key.isEmpty ? String(format: String(localized: "ba.student.detail.row.format"), index + 1) : key
            let rowValue = value.isEmpty ? imageURLs.first?.lastPathComponent ?? "" : value
            let dedupeKey = "\(title)|\(rowValue)|\(imageURLs.map(\.absoluteString).joined(separator: ","))"
            guard seen.insert(dedupeKey).inserted else { continue }
            let guideRow = BaGuideRow(
                id: "base-\(index)-\(abs(dedupeKey.hashValue))",
                title: title,
                value: rowValue,
                imageURL: imageURLs.first,
                imageURLs: imageURLs.isEmpty ? nil : imageURLs
            )

            route(guideRow, key: title, value: rowValue, parsed: &parsed)
            if parsed.summary.isEmpty, isSummaryKey(title), rowValue.isEmpty == false {
                parsed.summary = rowValue
            }
            if parsed.imageURL == nil {
                parsed.imageURL = imageURLs.first
            }
        }
        parsed.stats = stats(from: parsed.profileRows)
        return parsed
    }

    private func route(_ row: BaGuideRow, key: String, value: String, parsed: inout BaStructuredGuideParse) {
        let merged = "\(key) \(value)"
        if isSkillKey(merged) {
            parsed.skillRows.append(row)
        } else if isSimulateKey(merged) {
            parsed.simulateRows.append(row)
        } else if isGrowthKey(merged) {
            parsed.growthRows.append(row)
        } else if isProfileKey(merged) {
            parsed.profileRows.append(row)
        } else if row.imageURL != nil {
            parsed.galleryItems.append(
                BaGuideGalleryItem(
                    id: "row-media-\(row.id)",
                    title: row.title,
                    detail: row.value,
                    imageURL: row.imageURL,
                    mediaURL: row.imageURL,
                    mediaKind: .image,
                    note: row.value.isEmpty ? nil : row.value
                )
            )
        } else if row.value.isEmpty == false {
            parsed.profileRows.append(row)
        }
    }

    private func stats(from rows: [BaGuideRow]) -> [BaGuideRow] {
        rows.filter { row in
            BaGuideTextNormalizer.containsAny(row.title, tokens: ["学院", "社团", "生日", "实装", "攻击类型", "防御类型", "位置", "school", "club"])
        }
        .prefix(6)
        .map { $0 }
    }

    private func isProfileKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: ["学生信息", "角色名称", "全名", "档案", "基础", "资料", "学院", "社团", "生日", "年龄", "身高", "兴趣", "画师", "声优", "实装", "攻击类型", "防御类型", "位置", "武器类型", "profile", "school", "club"]
        )
    }

    private func isSkillKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: ["技能", "EX", "普通技能", "被动技能", "辅助技能", "技能COST", "技能图标", "技能描述", "技能名称", "skill"]
        )
    }

    private func isGrowthKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: ["成长", "装备", "专武", "固有", "礼物", "羁绊", "升星", "爱用品", "能力解放", "升级材料", "growth", "gift"]
        )
    }

    private func isSimulateKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: ["模拟", "伤害", "配置", "轴", "演习", "simulate", "damage"]
        )
    }

    private func isSummaryKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(value, tokens: ["介绍", "简介", "官方介绍", "summary"])
    }
}
