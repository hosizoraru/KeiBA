//
//  BaStudentSimulationDisplayModel.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaStudentSimulationSectionName: String, CaseIterable, Identifiable {
    case initial = "初始数据"
    case maximum = "顶级数据"
    case weapon = "专武"
    case equipment = "装备"
    case favorite = "爱用品"
    case unlock = "能力解放"
    case bond = "羁绊等级奖励"

    var id: String {
        rawValue
    }
}

nonisolated struct BaStudentSimulationData: Hashable {
    var initialHint = ""
    var initialRows: [BaGuideRow] = []
    var maximumHint = ""
    var maximumRows: [BaGuideRow] = []
    var weaponHint = ""
    var weaponRows: [BaGuideRow] = []
    var equipmentHint = ""
    var equipmentRows: [BaGuideRow] = []
    var favoriteHint = ""
    var favoriteRows: [BaGuideRow] = []
    var unlockHint = ""
    var unlockRows: [BaGuideRow] = []
    var bondHint = ""
    var bondRows: [BaGuideRow] = []

    var hasRenderableContent: Bool {
        initialRows.isEmpty == false ||
            maximumRows.isEmpty == false ||
            weaponRows.isEmpty == false ||
            equipmentRows.isEmpty == false ||
            favoriteRows.isEmpty == false ||
            unlockRows.isEmpty == false ||
            bondRows.isEmpty == false
    }
}

nonisolated struct BaStudentSimulationEquipmentGroup: Identifiable, Hashable {
    let id: String
    let slotLabel: String
    let itemName: String
    let tierText: String
    let iconURL: URL?
    let statRows: [BaGuideRow]
}

nonisolated struct BaStudentSimulationBondGroup: Identifiable, Hashable {
    let id: String
    let roleLabel: String
    let iconURL: URL?
    let statRows: [BaGuideRow]
}

nonisolated struct BaStudentSimulationUnlockViewData: Hashable {
    let levelCapsule: String
    let rows: [BaGuideRow]
}

nonisolated struct BaStudentSimulationWeaponViewData: Hashable {
    let imageURL: URL?
    let statRows: [BaGuideRow]
}

nonisolated enum BaStudentSimulationDisplayModel {
    static func build(rows: [BaGuideRow]) -> BaStudentSimulationData {
        guard rows.isEmpty == false else { return BaStudentSimulationData() }

        var sections: [BaStudentSimulationSectionName: [BaGuideRow]] = [:]
        var hints: [BaStudentSimulationSectionName: String] = [:]
        var currentSection: BaStudentSimulationSectionName?

        for row in rows {
            if let section = resolveSectionName(row.title) {
                currentSection = section
                sections[section, default: []] = sections[section, default: []]
                let hint = cleanHint(row.value)
                if hint.isEmpty == false {
                    hints[section] = hint
                }
                continue
            }
            guard let currentSection else { continue }
            let cleaned = clean(row)
            guard hasRenderableContent(cleaned) else { continue }
            sections[currentSection, default: []].append(cleaned)
        }

        return BaStudentSimulationData(
            initialHint: hints[.initial] ?? "",
            initialRows: expandRows(sections[.initial] ?? []),
            maximumHint: hints[.maximum] ?? "",
            maximumRows: expandRows(sections[.maximum] ?? []),
            weaponHint: hints[.weapon] ?? "",
            weaponRows: sanitizeWeaponRows(expandRows(sections[.weapon] ?? [])),
            equipmentHint: hints[.equipment] ?? "",
            equipmentRows: expandRows(sections[.equipment] ?? []),
            favoriteHint: hints[.favorite] ?? "",
            favoriteRows: sanitizeFavoriteRows(expandRows(sections[.favorite] ?? [])),
            unlockHint: hints[.unlock] ?? "",
            unlockRows: expandRows(sections[.unlock] ?? []),
            bondHint: hints[.bond] ?? "",
            bondRows: sanitizeBondRows(expandRows(sections[.bond] ?? []))
        )
    }

    static func resolveSectionName(_ rawKey: String) -> BaStudentSimulationSectionName? {
        let normalized = normalizeKey(rawKey)
        return BaStudentSimulationSectionName.allCases.first { normalizeKey($0.rawValue) == normalized }
    }

    static func equipmentGroups(from rows: [BaGuideRow]) -> [BaStudentSimulationEquipmentGroup] {
        guard rows.isEmpty == false else { return [] }

        var groups: [BaStudentSimulationEquipmentGroup] = []
        var currentSlot = ""
        var currentItemName = ""
        var currentTierText = ""
        var currentIcon: URL?
        var currentStats: [BaGuideRow] = []

        func commitGroup() {
            guard currentSlot.isEmpty == false || currentItemName.isEmpty == false || currentStats.isEmpty == false else {
                return
            }
            let signature = "\(currentSlot)|\(currentItemName)|\(currentTierText)|\(currentIcon?.absoluteString ?? "")|\(currentStats.map(\.id).joined(separator: ","))"
            groups.append(
                BaStudentSimulationEquipmentGroup(
                    id: "equipment-\(abs(signature.hashValue))",
                    slotLabel: currentSlot.ifBlank(fallbackEquipmentSlot),
                    itemName: currentItemName,
                    tierText: currentTierText,
                    iconURL: currentIcon,
                    statRows: currentStats
                )
            )
            currentSlot = ""
            currentItemName = ""
            currentTierText = ""
            currentIcon = nil
            currentStats.removeAll()
        }

        for row in rows {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedKey = normalizeKey(key)
            let rowIcon = primaryImageURL(row)

            if normalizedKey.range(of: #"^\d+号装备$"#, options: .regularExpression) != nil {
                commitGroup()
                currentSlot = key
                currentIcon = rowIcon ?? currentIcon
                continue
            }

            if let ghostURL = mediaURLFromGhostRow(row) {
                currentIcon = ghostURL
                continue
            }

            let isMetaRow = isLikelyStatLabel(key) == false && isSubHeader(key) == false
            if currentItemName.isEmpty, isMetaRow {
                currentItemName = key
                currentTierText = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
                currentIcon = currentIcon ?? rowIcon
                continue
            }

            guard key.isEmpty == false || row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                continue
            }
            currentStats.append(row.removingImages())
        }

        commitGroup()
        return groups
    }

    static func unlockViewData(rows: [BaGuideRow], hint: String) -> BaStudentSimulationUnlockViewData {
        guard rows.isEmpty == false else {
            return BaStudentSimulationUnlockViewData(levelCapsule: levelCapsule(from: hint), rows: [])
        }
        let levelIndex = rows.firstIndex { normalizeKey($0.title).range(of: #"^\d+级$"#, options: .regularExpression) != nil }
        let capsule = levelIndex.map { rows[$0].title.trimmingCharacters(in: .whitespacesAndNewlines) } ?? levelCapsule(from: hint)
        let contentRows = rows.enumerated().compactMap { index, row in
            levelIndex == index ? nil : row
        }
        return BaStudentSimulationUnlockViewData(levelCapsule: capsule, rows: contentRows)
    }

    static func bondGroups(from rows: [BaGuideRow]) -> [BaStudentSimulationBondGroup] {
        guard rows.isEmpty == false else { return [] }

        var groups: [BaStudentSimulationBondGroup] = []
        var currentRole = ""
        var currentIcon: URL?
        var currentRows: [BaGuideRow] = []

        func commitGroup() {
            guard currentRole.isEmpty == false || currentRows.isEmpty == false else { return }
            let signature = "\(currentRole)|\(currentIcon?.absoluteString ?? "")|\(currentRows.map(\.id).joined(separator: ","))"
            groups.append(
                BaStudentSimulationBondGroup(
                    id: "bond-\(abs(signature.hashValue))",
                    roleLabel: currentRole.ifBlank(fallbackBondRole),
                    iconURL: currentIcon,
                    statRows: currentRows
                )
            )
            currentRole = ""
            currentIcon = nil
            currentRows.removeAll()
        }

        for row in rows {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizeKey(key).range(of: #"^羁绊角色\d+$"#, options: .regularExpression) != nil {
                commitGroup()
                currentRole = key
                currentIcon = primaryImageURL(row)
                continue
            }
            guard key.isEmpty == false || row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                continue
            }
            currentRows.append(row.removingImages())
        }

        commitGroup()
        return groups
    }

    static func weaponViewData(rows: [BaGuideRow]) -> BaStudentSimulationWeaponViewData {
        guard rows.isEmpty == false else {
            return BaStudentSimulationWeaponViewData(imageURL: nil, statRows: [])
        }
        let imageURL = rows.compactMap(primaryImageURL).first
        let statRows = rows
            .filter { row in
                row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
                    row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
            .map { row in
                guard let imageURL, primaryImageURL(row) == imageURL else { return row }
                return row.removingImages()
            }
        return BaStudentSimulationWeaponViewData(imageURL: imageURL, statRows: statRows)
    }

    static func levelCapsule(from rawHint: String) -> String {
        let hint = cleanHint(rawHint)
        guard hint.isEmpty == false else { return "" }
        if let value = firstMatch(in: hint, pattern: #"(?i)Lv\s*\d+"#) {
            let digits = firstMatch(in: value, pattern: #"\d+"#) ?? ""
            if digits.isEmpty == false {
                return "Lv\(digits)"
            }
        }
        if let value = firstMatch(in: hint, pattern: #"(?i)T\d+"#) {
            return value.replacingOccurrences(of: " ", with: "").uppercased()
        }
        if let value = firstMatch(in: hint, pattern: #"\d+级"#) {
            return value
        }
        return ""
    }

    static func maxDeltaText(maxValue: String, initialValue: String?) -> String {
        let maxText = maxValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let initialText = initialValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard maxText.isEmpty == false, initialText.isEmpty == false else { return "" }
        if maxText.range(of: #"\([+-]\d+(\.\d+)?\)"#, options: .regularExpression) != nil {
            return ""
        }
        guard let maxNumber = comparableNumber(in: maxText),
              let initialNumber = comparableNumber(in: initialText)
        else {
            return ""
        }
        let diff = maxNumber - initialNumber
        guard abs(diff) >= 0.0001 else { return "" }
        let sign = diff > 0 ? "+" : "-"
        let absDiff = abs(diff)
        let value = abs(absDiff - absDiff.rounded()) < 0.0001
            ? String(Int64(absDiff.rounded()))
            : String(format: "%.2f", absDiff).trimmingTrailingZeros()
        return "(\(sign)\(value))"
    }

    static func statSystemImage(for title: String) -> String {
        let key = normalizeKey(title)
        if key.contains("攻击") { return "asterisk" }
        if key.contains("防御") { return "shield.lefthalf.filled" }
        if key.contains("生命") || key == "hp" { return "heart.fill" }
        if key.contains("治愈") || key.contains("治疗") { return "cross.fill" }
        if key.contains("命中") { return "target" }
        if key.contains("闪避") { return "circle.dotted" }
        if key.contains("暴击") || key.contains("暴伤") { return "sparkle" }
        if key.contains("稳定") { return "alternatingcurrent" }
        if key.contains("射程") { return "arrow.up.right" }
        if key.contains("cost") { return "hourglass" }
        if key.contains("装弹") { return "rectangle.stack" }
        return "diamond.fill"
    }

    static func isSubHeader(_ key: String) -> Bool {
        let normalized = normalizeKey(key)
        return normalized.range(of: #"^\d+号装备$"#, options: .regularExpression) != nil ||
            normalized.range(of: #"^羁绊角色\d+$"#, options: .regularExpression) != nil ||
            normalized.range(of: #"^\d+级$"#, options: .regularExpression) != nil
    }

    static func primaryImageURL(_ row: BaGuideRow) -> URL? {
        row.imageURL ?? row.imageURLs?.first
    }

    private static func expandRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        guard rows.isEmpty == false else { return [] }
        var expanded: [BaGuideRow] = []

        for row in rows {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
            let images = row.allImages
            let icon = images.first
            guard key.isEmpty == false || value.isEmpty == false || images.isEmpty == false else { continue }

            if value.isEmpty {
                if key.isEmpty == false || icon != nil {
                    expanded.append(row.with(title: key.ifBlank(fallbackInfoTitle), value: "", imageURLs: images))
                }
                continue
            }

            let tokens = splitCompositeValues(value)
            guard tokens.isEmpty == false else {
                expanded.append(row.with(title: key.ifBlank(fallbackInfoTitle), value: value, imageURLs: images))
                continue
            }

            var index = 0
            if isLikelyStatLabel(tokens[0]) == false {
                expanded.append(row.with(title: key.ifBlank(fallbackLevelTitle), value: tokens[0], imageURLs: images))
                index = 1
            } else if key.isEmpty == false, isLikelyStatLabel(key) == false, isSubHeader(key) == false {
                expanded.append(row.with(title: key, value: "", imageURLs: images))
            } else if icon != nil, key.isEmpty == false {
                expanded.append(row.with(title: key, value: "", imageURLs: images))
            }

            var pairIndex = 0
            while index + 1 < tokens.count {
                let statKey = tokens[index]
                let statValue = tokens[index + 1]
                if statKey.isEmpty == false, statValue.isEmpty == false {
                    let pairIcon = images.count > 1 ? images[safe: pairIndex] : nil
                    expanded.append(
                        row.with(
                            idSuffix: "pair-\(pairIndex)",
                            title: statKey,
                            value: statValue,
                            imageURLs: pairIcon.map { [$0] } ?? []
                        )
                    )
                }
                pairIndex += 1
                index += 2
            }
        }

        var seen = Set<String>()
        return expanded.filter { row in
            let key = "\(normalizeKey(row.title))|\(row.value.trimmingCharacters(in: .whitespacesAndNewlines))|\(row.allImages.map(\.absoluteString).joined(separator: "|"))"
            return seen.insert(key).inserted
        }
    }

    private static func sanitizeFavoriteRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        rows.filter { row in
            let normalizedKey = normalizeKey(row.title)
            let normalizedValue = normalizeKey(row.value)
            let hasMedia = primaryImageURL(row) != nil
            let isTierMetaKey = normalizedKey.range(of: #"^t\d+(效果|所需升级材料|技能图标)$"#, options: [.regularExpression, .caseInsensitive]) != nil
            let hasNumericValue = row.value.range(of: #"\d"#, options: .regularExpression) != nil
            let isBrokenStatPair = isLikelyStatLabel(row.title) && isLikelyStatLabel(row.value) && hasNumericValue == false && hasMedia == false
            let isTierOnlyPlaceholder = normalizedKey.range(of: #"^t\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil &&
                normalizedValue.isEmpty &&
                hasMedia == false
            return hasRenderableContent(row) && isTierMetaKey == false && isBrokenStatPair == false && isTierOnlyPlaceholder == false
        }
    }

    private static func sanitizeWeaponRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        rows.filter { isZeroBlankInstruction($0.value) == false }
    }

    private static func sanitizeBondRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        rows.filter { row in
            let normalizedKey = normalizeKey(row.title)
            let isBlankBondRole = normalizedKey.range(of: #"^羁绊角色\d+$"#, options: .regularExpression) != nil &&
                row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                primaryImageURL(row) == nil
            return isBlankBondRole == false
        }
    }

    private static func hasRenderableContent(_ row: BaGuideRow) -> Bool {
        row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
            row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
            primaryImageURL(row) != nil
    }

    private static func clean(_ row: BaGuideRow) -> BaGuideRow {
        row.with(
            title: row.title.trimmingCharacters(in: .whitespacesAndNewlines),
            value: row.value.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURLs: row.allImages
        )
    }

    private static func cleanHint(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "*＊"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitCompositeValues(_ raw: String) -> [String] {
        raw.replacingOccurrences(of: "／", with: "/")
            .replacingOccurrences(of: "|", with: "/")
            .replacingOccurrences(of: "｜", with: "/")
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false && $0 != "-" && $0 != "—" }
    }

    private static func mediaURLFromGhostRow(_ row: BaGuideRow) -> URL? {
        let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false,
              row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = BaGuideTextNormalizer.normalizeMediaURL(key, sourceURL: nil),
              BaGuideTextNormalizer.looksLikeImageURL(url) || BaGuideTextNormalizer.looksLikeVideoURL(url)
        else {
            return nil
        }
        return url
    }

    private static func isLikelyStatLabel(_ raw: String) -> Bool {
        let normalized = normalizeKey(raw)
        let topKeys = [
            "攻击力", "防御力", "生命值", "治愈力",
            "命中值", "闪避值", "暴击值", "暴击伤害",
            "稳定值", "射程", "群控强化力", "群控抵抗力",
            "装弹数", "防御无视值", "受恢复率", "COST恢复力",
            "暴伤抵抗率", "暴击抵抗值", "暴伤抵抗值",
        ].map(normalizeKey)
        return topKeys.contains(normalized) || normalized.hasSuffix("值") || normalized.hasSuffix("率")
    }

    private static func isZeroBlankInstruction(_ raw: String) -> Bool {
        guard raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return false }
        let normalized = raw
            .replacingOccurrences(of: "０", with: "0")
            .replacingOccurrences(of: #"[\s　*＊,，.。;；:：/／|｜_\-—~·]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.contains("0") && normalized.contains("格") && normalized.contains("留空")
    }

    private static func comparableNumber(in raw: String) -> Double? {
        let normalized = raw.replacingOccurrences(of: ",", with: "")
        guard let match = firstMatch(in: normalized, pattern: #"-?\d+(\.\d+)?"#) else {
            return nil
        }
        return Double(match)
    }

    private static func firstMatch(in value: String, pattern: String) -> String? {
        guard let range = value.range(of: pattern, options: .regularExpression) else { return nil }
        return String(value[range])
    }

    private static func normalizeKey(_ raw: String) -> String {
        BaGuideTextNormalizer.normalizedKey(raw)
    }

    private static var fallbackEquipmentSlot: String {
        String(localized: "ba.student.detail.simulate.equipment.slot")
    }

    private static var fallbackBondRole: String {
        String(localized: "ba.student.detail.simulate.bond.role")
    }

    private static var fallbackInfoTitle: String {
        String(localized: "ba.student.detail.simulate.info")
    }

    private static var fallbackLevelTitle: String {
        String(localized: "ba.student.detail.simulate.level")
    }
}

private extension BaGuideRow {
    nonisolated var allImages: [URL] {
        BaGuideTextNormalizer.dedupe((imageURLs ?? []) + [imageURL].compactMap { $0 })
    }

    nonisolated func removingImages() -> BaGuideRow {
        BaGuideRow(id: id, title: title, value: value, imageURL: nil, imageURLs: nil)
    }

    nonisolated func with(idSuffix: String? = nil, title: String, value: String, imageURLs: [URL]) -> BaGuideRow {
        let images = BaGuideTextNormalizer.dedupe(imageURLs)
        let suffix = idSuffix.map { "-\($0)" } ?? ""
        let signature = "\(id)\(suffix)|\(title)|\(value)|\(images.map(\.absoluteString).joined(separator: ","))"
        return BaGuideRow(
            id: "simulate-display-\(abs(signature.hashValue))",
            title: title,
            value: value,
            imageURL: images.first,
            imageURLs: images.isEmpty ? nil : images
        )
    }
}

private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }

    nonisolated func trimmingTrailingZeros() -> String {
        var value = self
        while value.contains("."), value.last == "0" {
            value.removeLast()
        }
        if value.last == "." {
            value.removeLast()
        }
        return value
    }
}

private extension Array {
    nonisolated subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
