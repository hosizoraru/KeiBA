//
//  BaGuideSimulateParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

struct BaGuideSimulateParser {
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

        return Array(out.prefix(260))
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
}
