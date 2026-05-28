//
//  BaGuideSimulateParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

struct BaGuideSimulateParser {
    // Compiled-once regex caches. parse() is called every time a student
    // detail loads, and patchSupplementIcons() invokes these patterns once
    // per row in the simulate block. Caching avoids repeated
    // NSRegularExpression compilations during initial student loads.
    fileprivate nonisolated static let equipmentSlotRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^([123])号装备$"#)
    }()
    fileprivate nonisolated static let equipmentTitleRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^装备([123])$"#)
    }()
    fileprivate nonisolated static let unlockLevelRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^\d+级$"#)
    }()

    private let sectionHeaders = [
        "初始数据",
        "顶级数据",
        "专武",
        "装备",
        "爱用品",
        "能力解放",
        "羁绊等级奖励",
    ]

    func parse(baseData: [[BaJSONObject]], sourceURL: URL?) -> [BaGuideRow] {
        guard baseData.isEmpty == false else { return [] }
        guard let startIndex = simulateStartIndex(in: baseData) else { return [] }

        let stopKeys = [
            "学生信息", "介绍", "配音语言", "配音", "配音大类", "官方介绍", "角色表情",
            "立绘", "本家画", "设定集", "TV动画设定图", "礼物偏好", "技能类型", "技能名词",
        ].map(BaGuideTextNormalizer.normalizedKey)

        var out: [BaGuideRow] = []
        var inSimulateBlock = false
        var seenBondReward = false
        var trailingEmptyRows = 0

        for index in startIndex ..< baseData.count {
            let row = rowToGuideRow(baseData[index], index: index, sourceURL: sourceURL)
            let normalizedKey = BaGuideTextNormalizer.normalizedKey(row.title)
            if let header = resolveSectionHeader(row.title) {
                inSimulateBlock = true
                trailingEmptyRows = 0
                if header == "羁绊等级奖励" {
                    seenBondReward = true
                }
                out.append(
                    BaGuideRow(
                        id: row.id,
                        title: header,
                        value: row.value,
                        imageURL: row.imageURL,
                        imageURLs: row.imageURLs
                    )
                )
                continue
            }
            guard inSimulateBlock else { continue }
            if normalizedKey.isEmpty == false, stopKeys.contains(normalizedKey) {
                break
            }

            let hasRenderableContent = row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
                row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
                row.imageURL != nil ||
                row.imageURLs?.isEmpty == false
            if hasRenderableContent == false {
                if seenBondReward {
                    trailingEmptyRows += 1
                }
                if trailingEmptyRows >= 2, seenBondReward {
                    break
                }
                continue
            }
            trailingEmptyRows = 0
            out.append(row)
        }

        return Array(patchSupplementIcons(in: out, baseData: baseData, sourceURL: sourceURL).prefix(260))
    }

    private func simulateStartIndex(in baseData: [[BaJSONObject]]) -> Int? {
        var startIndex: Int?
        for index in baseData.indices {
            let key = firstCellText(in: baseData[index])
            guard resolveSectionHeader(key) == "初始数据" else { continue }
            let upperBound = min(baseData.count, index + 24)
            let hasTopData = (index + 1 ..< upperBound).contains { nextIndex in
                resolveSectionHeader(firstCellText(in: baseData[nextIndex])) == "顶级数据"
            }
            if hasTopData {
                startIndex = index
            }
        }
        return startIndex
    }

    private func rowToGuideRow(_ row: [BaJSONObject], index: Int, sourceURL: URL?) -> BaGuideRow {
        let key = firstCellText(in: row)
        var textValues: [String] = []
        var imageValues: [URL] = []

        for cell in row.dropFirst() {
            let type = (cell.string("type") ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let rawValue = (cell.string("value") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard rawValue.isEmpty == false else { continue }

            switch type {
            case "image":
                imageValues.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: cell, sourceURL: sourceURL))
            case "imageset", "live2d":
                imageValues.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: cell["value"], sourceURL: sourceURL))
            default:
                imageValues.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(rawValue, sourceURL: sourceURL))
                imageValues.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: cell["value"], sourceURL: sourceURL))
                let text = BaGuideTextNormalizer.cleanDisplayText(rawValue)
                if text.isEmpty == false {
                    textValues.append(text)
                }
            }
        }

        let dedupedImages = BaGuideTextNormalizer.dedupe(imageValues)
        let value = textValues.joined(separator: " / ").trimmingCharacters(in: .whitespacesAndNewlines)
        let signature = "\(key)|\(value)|\(dedupedImages.map(\.absoluteString).joined(separator: ","))"
        return BaGuideRow(
            id: "simulate-\(index)-\(abs(signature.hashValue))",
            title: key,
            value: value,
            imageURL: dedupedImages.first,
            imageURLs: dedupedImages.isEmpty ? nil : dedupedImages
        )
    }

    private func resolveSectionHeader(_ rawKey: String) -> String? {
        let key = BaGuideTextNormalizer.normalizedKey(rawKey)
        return sectionHeaders.first {
            key == BaGuideTextNormalizer.normalizedKey($0)
        }
    }

    private func firstCellText(in row: [BaJSONObject]) -> String {
        guard let first = row.first else { return "" }
        return BaGuideTextNormalizer.clean(first.string("value") ?? "")
    }

    private func patchSupplementIcons(
        in rows: [BaGuideRow],
        baseData: [[BaJSONObject]],
        sourceURL: URL?
    ) -> [BaGuideRow] {
        let icons = collectSupplementIcons(baseData: baseData, sourceURL: sourceURL)
        var patchedRows: [BaGuideRow] = []
        var currentSection = ""
        var currentEquipmentSlot = ""
        var appliedWeaponIcon = false
        var appliedFavorIcon = false

        for row in rows {
            if let section = resolveSectionHeader(row.title) {
                currentSection = section
                currentEquipmentSlot = ""
                patchedRows.append(row)
                continue
            }

            var patched = row
            switch currentSection {
            case "专武":
                if appliedWeaponIcon == false, patched.imageURL == nil, let icon = icons.weaponIcon {
                    patched = patched.withImages([icon])
                    appliedWeaponIcon = true
                }
            case "装备":
                let normalizedKey = BaGuideTextNormalizer.normalizedKey(patched.title)
                if let slot = firstRegexGroup(in: normalizedKey, regex: Self.equipmentSlotRegex, fallbackPattern: #"^([123])号装备$"#) {
                    currentEquipmentSlot = "\(slot)号装备"
                }
                if let icon = icons.equipmentSlotIcons[currentEquipmentSlot], patched.imageURL == nil {
                    let keyURL = BaGuideTextNormalizer.normalizeMediaURL(patched.title, sourceURL: sourceURL)
                    let keyLooksLikeMedia = keyURL.map {
                        BaGuideTextNormalizer.looksLikeImageURL($0) || BaGuideTextNormalizer.looksLikeVideoURL($0)
                    } ?? false
                    let shouldAttachIcon = currentEquipmentSlot.isEmpty == false || isLikelyStatLabel(patched.title) == false
                    if shouldAttachIcon, keyLooksLikeMedia == false {
                        patched = patched.withImages([icon])
                    }
                }
            case "爱用品":
                if appliedFavorIcon == false, patched.imageURL == nil, let icon = icons.favorIcon {
                    patched = patched.withImages([icon])
                    appliedFavorIcon = true
                }
            case "能力解放":
                let normalizedKey = BaGuideTextNormalizer.normalizedKey(patched.title)
                if matchesUnlockLevel(normalizedKey),
                   patched.imageURL == nil,
                   icons.unlockMaterialIcons.isEmpty == false
                {
                    patched = patched.withImages(icons.unlockMaterialIcons)
                }
            default:
                break
            }

            patchedRows.append(patched)
        }

        return patchedRows.filter { row in
            row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
                row.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
                row.imageURL != nil ||
                row.imageURLs?.isEmpty == false
        }
    }

    private func collectSupplementIcons(baseData: [[BaJSONObject]], sourceURL: URL?) -> SupplementIcons {
        var weaponIcon: URL?
        var favorIcon: URL?
        var equipmentSlotIcons: [String: URL] = [:]
        var unlockMaterialIcons: [URL] = []

        for row in baseData {
            let key = firstCellText(in: row)
            let normalizedKey = BaGuideTextNormalizer.normalizedKey(key)
            let images = BaGuideTextNormalizer.dedupe(
                row.dropFirst().flatMap { cell -> [URL] in
                    let type = (cell.string("type") ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let rawValue = (cell.string("value") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if rawValue.isEmpty { return [] }
                    switch type {
                    case "image":
                        return BaGuideTextNormalizer.imageURLs(in: cell, sourceURL: sourceURL)
                    case "imageset", "live2d":
                        return BaGuideTextNormalizer.imageURLs(in: cell["value"], sourceURL: sourceURL)
                    default:
                        return BaGuideTextNormalizer.imageURLsFromHTML(rawValue, sourceURL: sourceURL) +
                            BaGuideTextNormalizer.imageURLs(in: cell["value"], sourceURL: sourceURL)
                    }
                }
            )
            guard let firstImage = images.first else { continue }

            switch normalizedKey {
            case BaGuideTextNormalizer.normalizedKey("专武图标"):
                weaponIcon = weaponIcon ?? firstImage
            case BaGuideTextNormalizer.normalizedKey("爱用品图标"):
                favorIcon = favorIcon ?? firstImage
            case BaGuideTextNormalizer.normalizedKey("能力解放所需材料"):
                unlockMaterialIcons = images
            default:
                if let slot = firstRegexGroup(in: normalizedKey, regex: Self.equipmentTitleRegex, fallbackPattern: #"^装备([123])$"#) {
                    equipmentSlotIcons["\(slot)号装备"] = firstImage
                }
            }
        }

        return SupplementIcons(
            weaponIcon: weaponIcon,
            favorIcon: favorIcon,
            equipmentSlotIcons: equipmentSlotIcons,
            unlockMaterialIcons: unlockMaterialIcons
        )
    }

    private func firstRegexGroup(
        in value: String,
        regex cachedRegex: NSRegularExpression?,
        fallbackPattern: String
    ) -> String? {
        if let regex = cachedRegex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            guard let match = regex.firstMatch(in: value, range: range),
                  match.numberOfRanges > 1,
                  let groupRange = Range(match.range(at: 1), in: value)
            else {
                return nil
            }
            return String(value[groupRange])
        }
        guard let regex = try? NSRegularExpression(pattern: fallbackPattern) else { return nil }
        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range),
              match.numberOfRanges > 1,
              let groupRange = Range(match.range(at: 1), in: value)
        else {
            return nil
        }
        return String(value[groupRange])
    }

    private func matchesUnlockLevel(_ value: String) -> Bool {
        if let regex = Self.unlockLevelRegex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            return regex.firstMatch(in: value, range: range) != nil
        }
        return value.range(of: #"^\d+级$"#, options: .regularExpression) != nil
    }

    private func isLikelyStatLabel(_ raw: String) -> Bool {
        let normalized = BaGuideTextNormalizer.normalizedKey(raw)
        let keys = [
            "攻击力", "防御力", "生命值", "治愈力", "命中值", "闪避值", "暴击值", "暴击伤害",
            "稳定值", "射程", "群控强化力", "群控抵抗力", "装弹数", "防御无视值", "受恢复率",
            "COST恢复力", "暴伤抵抗率", "暴击抵抗值", "暴伤抵抗值",
        ].map(BaGuideTextNormalizer.normalizedKey)
        return keys.contains(normalized) || normalized.hasSuffix("值") || normalized.hasSuffix("率")
    }

    private struct SupplementIcons {
        var weaponIcon: URL?
        var favorIcon: URL?
        var equipmentSlotIcons: [String: URL]
        var unlockMaterialIcons: [URL]
    }
}

private extension BaGuideRow {
    func withImages(_ urls: [URL]) -> BaGuideRow {
        let images = BaGuideTextNormalizer.dedupe(urls)
        return BaGuideRow(
            id: id,
            title: title,
            value: value,
            imageURL: images.first,
            imageURLs: images.isEmpty ? nil : images
        )
    }
}
