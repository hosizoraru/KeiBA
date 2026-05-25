//
//  BaStudentWeaponDisplayModel.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated struct BaStudentWeaponDisplayModel: Identifiable, Hashable {
    // Cache once. The weapon-row parsing path is hit per-row whenever a
    // weapon panel rebuilds, so recompiling these literals adds up across
    // every visible weapon card.
    fileprivate nonisolated(unsafe) static let extraStatKeyRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^附加属性\d+$"#)
    }()
    fileprivate nonisolated(unsafe) static let digitsRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d+"#)
    }()
    fileprivate nonisolated(unsafe) static let starPrefixRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^★\d+"#)
    }()
    fileprivate nonisolated(unsafe) static let weaponLevelRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"Lv\.?\s*\d{1,3}"#,
            options: [.caseInsensitive]
        )
    }()

    let id: String
    let name: String
    let imageURL: URL?
    let description: String
    let statHeaders: [String]
    let statRows: [BaStudentWeaponStatRow]
    let starEffects: [BaStudentWeaponStarEffect]
    let glossaryIcons: [String: URL]

    var displayName: String {
        name.ifBlank(BaL10n.string("ba.student.detail.weapon.unique"))
    }

    static func card(from info: BaStudentGuideInfo) -> BaStudentWeaponDisplayModel? {
        card(growthRows: info.growthDisplayRows, skillRows: info.skillDisplayRows, simulateRows: info.simulateRows)
    }

    static func card(
        growthRows: [BaGuideRow],
        skillRows: [BaGuideRow],
        simulateRows: [BaGuideRow] = []
    ) -> BaStudentWeaponDisplayModel? {
        let mainRows = growthRows.contains { $0.trimmedTitle == "专武" }
            ? growthRows
            : growthRows + skillRows
        guard let start = mainRows.firstIndex(where: { $0.trimmedTitle == "专武" }) else {
            return nil
        }

        let glossaryIcons = BaStudentSkillDisplayModel.extractSkillGlossaryIcons(from: skillRows + growthRows)
        let simulateWeaponRows = weaponRows(from: simulateRows)
        let mainWeaponRows = weaponSectionRows(from: mainRows, start: start)
        let main = parseMainWeapon(rows: mainRows, start: start, supplementalRows: simulateWeaponRows)
        let starEffects = parseStarEffects(rows: mainWeaponRows + skillRows + simulateWeaponRows)
        let hasContent = main.name.isEmpty == false ||
            main.imageURL != nil ||
            main.description.isEmpty == false ||
            main.statRows.isEmpty == false ||
            starEffects.isEmpty == false
        guard hasContent else { return nil }

        return BaStudentWeaponDisplayModel(
            id: "weapon-\(main.name)-\(main.imageURL?.absoluteString ?? "")-\(starEffects.count)",
            name: main.name,
            imageURL: main.imageURL,
            description: main.description,
            statHeaders: main.statHeaders,
            statRows: main.statRows,
            starEffects: starEffects,
            glossaryIcons: glossaryIcons
        )
    }

    private static func parseMainWeapon(
        rows: [BaGuideRow],
        start: Array<BaGuideRow>.Index,
        supplementalRows: [BaGuideRow]
    ) -> WeaponMainDraft {
        var draft = WeaponMainDraft()
        guard start + 1 < rows.endIndex else { return draft }

        for row in rows[(start + 1)...] {
            let key = row.trimmedTitle
            let value = row.trimmedValue
            if isWeaponSectionStop(key) {
                break
            }
            if key.isEmpty, value.isEmpty, row.allImageURLs.isEmpty {
                continue
            }
            switch key {
            case "专武图标":
                draft.imageURL = row.imageURL ?? row.allImageURLs.first
            case "专武名称":
                draft.name = value
            case "专武描述":
                draft.description = value
            case "专武数值":
                draft.statHeaders = splitCompositeValues(value)
            default:
                let values = splitCompositeValues(value)
                if key.isEmpty == false, values.isEmpty == false, isLikelyStatLabel(key) {
                    draft.statRows.append(BaStudentWeaponStatRow(title: key, values: values))
                }
            }
        }
        let supplementalStatRows = statRows(from: supplementalRows)
        if draft.statRows.isEmpty, supplementalStatRows.isEmpty == false {
            draft.statRows = supplementalStatRows
            if draft.statRows.allSatisfy({ $0.values.count <= 1 }) {
                draft.statHeaders = supplementalLevelHeaders(from: supplementalRows).ifEmpty(["Lv60"])
            }
        }
        return draft
    }

    private static func parseStarEffects(rows: [BaGuideRow]) -> [BaStudentWeaponStarEffect] {
        var drafts: [WeaponStarDraft] = []
        var current: WeaponStarDraft?

        func commit() {
            guard let draft = current else { return }
            let hasDescription = draft.descriptionByLevel.isEmpty == false || draft.fallbackDescription.isEmpty == false
            let hasHeader = draft.name.isEmpty == false || draft.iconURL != nil || draft.starIconURL != nil
            if hasDescription || hasHeader {
                drafts.append(draft)
            }
            current = nil
        }

        for row in rows {
            let key = row.trimmedTitle
            let value = row.trimmedValue
            let iconCandidates = BaStudentSkillDisplayModel.rowDescriptionIcons(row)

            if let star = extractStarInfo(key: key, value: value) {
                let starLabel = star.label
                if current?.starLabel != starLabel {
                    commit()
                    current = WeaponStarDraft(starLabel: starLabel)
                }
                if current?.iconURL == nil {
                    current?.iconURL = row.allImageURLs.first
                }
                if key.contains("技能名称"), star.value.isEmpty == false {
                    current?.name = star.value
                } else if star.value.isEmpty == false {
                    current?.fallbackDescription = star.value
                }
                continue
            }

            guard current != nil else { continue }
            if isStarSectionStop(key) {
                commit()
                continue
            }

            switch true {
            case key.contains("技能名称"):
                if value.isEmpty == false {
                    current?.name = value
                }
            case key == "技能图标":
                current?.iconURL = row.imageURL ?? row.allImageURLs.first
            case key == "技能描述":
                if value.isEmpty == false {
                    current?.fallbackDescription = value
                }
                if iconCandidates.isEmpty == false {
                    current?.fallbackDescriptionIcons = iconCandidates
                }
            default:
                if let level = BaStudentSkillDisplayModel.toDisplayLevelLabel(key) {
                    if value.isEmpty == false {
                        current?.descriptionByLevel[level] = value
                    }
                    if iconCandidates.isEmpty == false {
                        current?.descriptionIconsByLevel[level] = iconCandidates
                    }
                } else if value.isEmpty == false, key != "所需个数", key.contains("升级材料") == false {
                    let fallback = key.isEmpty ? value : "\(key)：\(value)"
                    if current?.fallbackDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                        current?.fallbackDescription = fallback
                    }
                }
            }
        }
        commit()

        return drafts.enumerated().compactMap { index, draft in
            let hasDescription = draft.descriptionByLevel.isEmpty == false || draft.fallbackDescription.isEmpty == false
            let hasHeader = draft.name.isEmpty == false || draft.iconURL != nil || draft.starIconURL != nil
            guard hasDescription || hasHeader else { return nil }
            let fallbackAsTitle = draft.name.isEmpty &&
                draft.starLabel != "★2" &&
                draft.fallbackDescription.isEmpty == false
            return BaStudentWeaponStarEffect(
                id: "weapon-star-\(index)-\(draft.starLabel)",
                starLabel: draft.starLabel,
                starIconURL: draft.starIconURL,
                name: draft.name.ifBlank(
                    draft.starLabel == "★2"
                        ? BaL10n.string("ba.student.detail.weapon.passiveUpgrade")
                        : (fallbackAsTitle ? draft.fallbackDescription : draft.starLabel)
                ),
                iconURL: draft.iconURL,
                descriptionByLevel: draft.descriptionByLevel,
                descriptionIconsByLevel: draft.descriptionIconsByLevel,
                roleTag: draft.starLabel == "★2" ? BaL10n.string("ba.student.detail.skill.sub") : "",
                fallbackDescription: fallbackAsTitle ? "" : draft.fallbackDescription,
                fallbackDescriptionIcons: draft.fallbackDescriptionIcons
            )
        }
    }

    private static func splitCompositeValues(_ raw: String) -> [String] {
        raw
            .replacingOccurrences(of: "／", with: "/")
            .replacingOccurrences(of: "|", with: "/")
            .replacingOccurrences(of: "｜", with: "/")
            .components(separatedBy: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false && $0 != "-" && $0 != "—" }
    }

    private static func extractStarInfo(key rawKey: String, value rawValue: String) -> (label: String, value: String)? {
        if let label = extractStarLabel(rawKey) {
            return (label, rawValue)
        }
        if let label = extractStarLabel(rawValue) {
            let values = splitCompositeValues(rawValue)
            let description = values.dropFirst().joined(separator: " ").ifBlank(
                rawValue.replacingOccurrences(of: label, with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜：:　 \n\t"))
            )
            return (label, description)
        }
        let normalizedKey = rawKey.replacingOccurrences(of: " ", with: "")
        guard Self.matchesEntireString(normalizedKey, regex: Self.extraStatKeyRegex, fallbackPattern: #"^附加属性\d+$"#),
              let numberRange = Self.firstMatchRange(in: normalizedKey, regex: Self.digitsRegex, fallbackPattern: #"\d+"#)
        else {
            return nil
        }
        let label = "★\(normalizedKey[numberRange])"
        let values = splitCompositeValues(rawValue)
        let description = values.first == label ? values.dropFirst().joined(separator: " ") : rawValue
        return (label, description)
    }

    private static func matchesEntireString(
        _ value: String,
        regex: NSRegularExpression?,
        fallbackPattern: String
    ) -> Bool {
        if let regex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            guard let match = regex.firstMatch(in: value, range: range),
                  let matchRange = Range(match.range, in: value)
            else {
                return false
            }
            return matchRange.lowerBound == value.startIndex && matchRange.upperBound == value.endIndex
        }
        guard let range = value.range(of: fallbackPattern, options: .regularExpression) else { return false }
        return range.lowerBound == value.startIndex && range.upperBound == value.endIndex
    }

    private static func firstMatchRange(
        in value: String,
        regex: NSRegularExpression?,
        fallbackPattern: String,
        options: NSString.CompareOptions = []
    ) -> Range<String.Index>? {
        if let regex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            return regex.firstMatch(in: value, range: range).flatMap { Range($0.range, in: value) }
        }
        var combined: NSString.CompareOptions = options
        combined.insert(.regularExpression)
        return value.range(of: fallbackPattern, options: combined)
    }

    private static func extractStarLabel(_ rawKey: String) -> String? {
        guard let range = firstMatchRange(in: rawKey, regex: starPrefixRegex, fallbackPattern: #"^★\d+"#) else {
            return nil
        }
        return String(rawKey[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func weaponSectionRows(from rows: [BaGuideRow], start: Array<BaGuideRow>.Index) -> [BaGuideRow] {
        var out: [BaGuideRow] = []
        guard start < rows.endIndex else { return out }
        for row in rows[start...] {
            let key = row.trimmedTitle
            if out.isEmpty == false, isWeaponSectionStop(key) {
                break
            }
            out.append(row)
        }
        return out
    }

    private static func weaponRows(from simulateRows: [BaGuideRow]) -> [BaGuideRow] {
        var out: [BaGuideRow] = []
        var inWeaponSection = false
        for row in simulateRows {
            let key = row.trimmedTitle
            if isSimulateSectionHeader(key) {
                inWeaponSection = key == "专武"
                if inWeaponSection {
                    out.append(row)
                }
                continue
            }
            if inWeaponSection {
                out.append(row)
            }
        }
        return out.flatMap(expandedSimulateRows)
    }

    private static func expandedSimulateRows(_ row: BaGuideRow) -> [BaGuideRow] {
        let key = row.trimmedTitle
        let value = row.trimmedValue
        if key == "专武" {
            return [row]
        }
        let tokens = splitCompositeValues(value)
        guard tokens.count >= 2 else {
            return [row]
        }
        let firstLooksLikeStat = isLikelyStatLabel(tokens[0]) || extractStarLabel(tokens[0]) != nil
        guard firstLooksLikeStat else {
            return [row]
        }
        var out: [BaGuideRow] = []
        var index = 0
        while index + 1 < tokens.count {
            let title = tokens[index]
            let value = tokens[index + 1]
            out.append(
                BaGuideRow(
                    id: "\(row.id)-expanded-\(index)",
                    title: title,
                    value: value,
                    imageURL: row.imageURL,
                    imageURLs: row.imageURLs
                )
            )
            index += 2
        }
        return out.isEmpty ? [row] : out
    }

    private static func statRows(from rows: [BaGuideRow]) -> [BaStudentWeaponStatRow] {
        rows.compactMap { row in
            let key = row.trimmedTitle
            let value = row.trimmedValue
            guard isLikelyStatLabel(key), value.isEmpty == false, value.hasPrefix("*") == false else { return nil }
            return BaStudentWeaponStatRow(title: key, values: splitCompositeValues(value).ifEmpty([value]))
        }
    }

    private static func supplementalLevelHeaders(from rows: [BaGuideRow]) -> [String] {
        rows.compactMap { row -> String? in
            guard row.trimmedTitle == "专武" else { return nil }
            let value = row.trimmedValue
            if let range = firstMatchRange(
                in: value,
                regex: weaponLevelRegex,
                fallbackPattern: #"Lv\.?\s*\d{1,3}"#,
                options: [.caseInsensitive]
            ) {
                return String(value[range]).replacingOccurrences(of: " ", with: "")
            }
            return nil
        }
    }

    private static func isLikelyStatLabel(_ raw: String) -> Bool {
        let key = raw.replacingOccurrences(of: " ", with: "")
        return [
            "攻击力", "防御力", "生命值", "治愈力",
            "命中值", "闪避值", "暴击值", "暴击伤害",
            "稳定值", "射程", "群控强化力", "群控抵抗力",
            "装弹数", "防御无视值", "受恢复率", "COST恢复力",
        ].contains(key)
    }

    private static func isSimulateSectionHeader(_ key: String) -> Bool {
        [
            "初始数据", "顶级数据", "专武", "装备", "爱用品", "能力解放", "羁绊等级奖励",
        ].contains(key)
    }

    private static func isWeaponSectionStop(_ key: String) -> Bool {
        key.contains("爱用品") ||
            key.contains("专武考据") ||
            key.contains("能力解放") ||
            key.contains("羁绊") ||
            key.contains("礼物偏好") ||
            key.contains("初始数据")
    }

    private static func isStarSectionStop(_ key: String) -> Bool {
        key.contains("T2技能图标") ||
            key.contains("爱用品") ||
            key.contains("专武考据") ||
            key.contains("初始数据") ||
            key.contains("能力解放") ||
            key.contains("羁绊") ||
            key.contains("升级材料") ||
            key == "专武" ||
            key == "技能类型" ||
            key.hasPrefix("装备")
    }

    private struct WeaponMainDraft {
        var name = ""
        var imageURL: URL?
        var description = ""
        var statHeaders: [String] = []
        var statRows: [BaStudentWeaponStatRow] = []
    }

    private struct WeaponStarDraft {
        let starLabel: String
        var starIconURL: URL?
        var name = ""
        var iconURL: URL?
        var fallbackDescription = ""
        var fallbackDescriptionIcons: [URL] = []
        var descriptionByLevel: [String: String] = [:]
        var descriptionIconsByLevel: [String: [URL]] = [:]
    }
}

nonisolated struct BaStudentWeaponStatRow: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let values: [String]
}

nonisolated struct BaStudentWeaponStarEffect: Identifiable, Hashable {
    let id: String
    let starLabel: String
    let starIconURL: URL?
    let name: String
    let iconURL: URL?
    let descriptionByLevel: [String: String]
    let descriptionIconsByLevel: [String: [URL]]
    let roleTag: String
    let fallbackDescription: String
    let fallbackDescriptionIcons: [URL]

    var levelOptions: [String] {
        descriptionByLevel.keys.sorted {
            (BaStudentSkillDisplayModel.parseLevelNumber($0) ?? Int.max, $0) <
                (BaStudentSkillDisplayModel.parseLevelNumber($1) ?? Int.max, $1)
        }
    }

    var defaultLevel: String {
        levelOptions.max {
            (BaStudentSkillDisplayModel.parseLevelNumber($0) ?? Int.min, $0) <
                (BaStudentSkillDisplayModel.parseLevelNumber($1) ?? Int.min, $1)
        } ?? levelOptions.first ?? "Lv.1"
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
}

private extension BaGuideRow {
    nonisolated var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var trimmedValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var allImageURLs: [URL] {
        if let imageURLs, imageURLs.isEmpty == false {
            return imageURLs
        }
        return imageURL.map { [$0] } ?? []
    }
}

private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

private extension Array {
    nonisolated func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}
