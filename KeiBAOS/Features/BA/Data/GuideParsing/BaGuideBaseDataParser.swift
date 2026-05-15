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

            for guideRow in expandedRows(
                from: row,
                index: index,
                key: key,
                value: value,
                imageURLs: imageURLs,
                sourceURL: sourceURL
            ) {
                let dedupeKey = "\(guideRow.title)|\(guideRow.value)|\(guideRow.imageURLs?.map(\.absoluteString).joined(separator: ",") ?? "")"
                guard seen.insert(dedupeKey).inserted else { continue }

                route(guideRow, key: guideRow.title, value: guideRow.value, parsed: &parsed)
                if parsed.summary.isEmpty, isSummaryKey(guideRow.title), guideRow.value.isEmpty == false {
                    parsed.summary = guideRow.value
                }
                if parsed.imageURL == nil {
                    parsed.imageURL = guideRow.imageURL
                }
            }
        }
        parsed.stats = stats(from: parsed.profileRows)
        return parsed
    }

    private func route(_ row: BaGuideRow, key: String, value: String, parsed: inout BaStructuredGuideParse) {
        let merged = "\(key) \(value)"
        if isVoiceKey(merged) {
            return
        } else if isSkillKey(merged) {
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

    private func expandedRows(
        from row: [BaJSONObject],
        index: Int,
        key: String,
        value: String,
        imageURLs: [URL],
        sourceURL: URL?
    ) -> [BaGuideRow] {
        if shouldSplitPairedRows(key: key) {
            let splitRows = splitPairedRows(from: row, index: index, sourceURL: sourceURL)
            if splitRows.isEmpty == false {
                return splitRows
            }
        }
        let title = key.isEmpty ? String(format: String(localized: "ba.student.detail.row.format"), index + 1) : key
        let rowValue = value
        let signature = "\(title)|\(rowValue)|\(imageURLs.map(\.absoluteString).joined(separator: ","))"
        return [
            BaGuideRow(
                id: "base-\(index)-\(abs(signature.hashValue))",
                title: title,
                value: rowValue,
                imageURL: imageURLs.first,
                imageURLs: imageURLs.isEmpty ? nil : imageURLs
            )
        ]
    }

    private func splitPairedRows(
        from row: [BaJSONObject],
        index: Int,
        sourceURL: URL?
    ) -> [BaGuideRow] {
        let cells = Array(row.dropFirst())
        guard cells.count >= 2, cells.count.isMultiple(of: 2) else { return [] }

        var out: [BaGuideRow] = []
        for pairIndex in stride(from: 0, to: cells.count, by: 2) {
            let titleCell = cells[pairIndex]
            let valueCell = cells[pairIndex + 1]
            let title = BaGuideTextNormalizer.clean(titleCell.string("value") ?? "")
            let value = BaGuideTextNormalizer.cleanDisplayText(valueCell.string("value") ?? "")
            let imageURLs = BaGuideTextNormalizer.dedupe(
                BaGuideTextNormalizer.imageURLs(in: [titleCell, valueCell], sourceURL: sourceURL)
            )
            let rowValue = value
            guard title.isEmpty == false || rowValue.isEmpty == false || imageURLs.isEmpty == false else { continue }
            let fallbackTitle = String(format: String(localized: "ba.student.detail.row.format"), pairIndex / 2 + 1)
            let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallbackTitle : title
            let signature = "\(resolvedTitle)|\(rowValue)|\(imageURLs.map(\.absoluteString).joined(separator: ","))"
            out.append(
                BaGuideRow(
                    id: "base-\(index)-pair-\(pairIndex)-\(abs(signature.hashValue))",
                    title: resolvedTitle,
                    value: rowValue,
                    imageURL: imageURLs.first,
                    imageURLs: imageURLs.isEmpty ? nil : imageURLs
                )
            )
        }
        return out
    }

    private func shouldSplitPairedRows(key: String) -> Bool {
        let normalizedKey = BaGuideTextNormalizer.normalizedKey(key)
        guard normalizedKey.isEmpty == false else { return false }
        let headers = [
            "学生信息",
            "学生资料",
            "学生档案",
            "角色技能",
            "基础信息",
            "基础资料",
            "个人信息",
            "学生爱好",
            "兴趣爱好",
        ].map(BaGuideTextNormalizer.normalizedKey)
        return headers.contains { normalizedKey.contains($0) }
    }

    private func stats(from rows: [BaGuideRow]) -> [BaGuideRow] {
        let priorities: [[String]] = [
            ["稀有度", "星级"],
            ["所属", "学院", "学园", "school"],
            ["社团", "club"],
            ["战术位置作用", "战术位置", "战术作用", "作用"],
            ["攻击类型"],
            ["防御类型"],
            ["武器类型"],
            ["市街"],
            ["屋外"],
            ["室内", "屋内"],
            ["生日"],
            ["实装"],
        ]

        var used = Set<String>()
        var result: [BaGuideRow] = []
        for keywords in priorities {
            guard let row = rows.first(where: { row in
                return keywords.contains { keyword in
                    row.title.localizedCaseInsensitiveContains(keyword)
                }
            }) else {
                continue
            }
            if used.insert(row.id).inserted {
                result.append(row)
            }
        }
        return result
    }

    private func isProfileKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: [
                "学生信息",
                "角色名称",
                "全名",
                "档案",
                "基础",
                "资料",
                "阵营",
                "学院",
                "学园",
                "所属学园",
                "所属学院",
                "所属社团",
                "社团",
                "稀有度",
                "星级",
                "生日",
                "年龄",
                "身高",
                "兴趣",
                "画师",
                "声优",
                "实装",
                "战术位置",
                "战术作用",
                "作用",
                "攻击类型",
                "防御类型",
                "位置",
                "武器类型",
                "市街",
                "屋外",
                "室内",
                "屋内",
                "profile",
                "school",
                "club"
            ]
        )
    }

    private func isSkillKey(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: #"(?i)^LV\.?\d{1,2}\b"#, options: .regularExpression) != nil {
            return true
        }
        return BaGuideTextNormalizer.containsAny(
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

    private func isVoiceKey(_ value: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            value,
            tokens: [
                "配音语言",
                "配音大类",
                "配音",
                "语音",
                "台词",
                "voice",
                "audio",
                "通常",
                "战斗",
                "活动",
                "大厅",
                "咖啡馆",
                "事件",
                "好感度",
                "成长",
                "MomoTalk"
            ]
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
