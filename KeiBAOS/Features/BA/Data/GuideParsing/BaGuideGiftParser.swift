//
//  BaGuideGiftParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideGiftParser {
    func parse(baseData: [[BaJSONObject]], sourceURL: URL?) -> [BaGuideRow] {
        var out: [BaGuideRow] = []
        var inGiftBlock = false
        var continuationQuota = 0
        var continuationEmojiImages: [URL] = []
        var continuationNote = ""
        var giftIndex = 1

        for row in baseData {
            guard let keyCell = row.first else { continue }
            let rawKey = keyCell.string("value") ?? ""
            let key = BaGuideTextNormalizer.clean(rawKey)
            let normalizedKey = BaGuideTextNormalizer.normalizedKey(key)

            if inGiftBlock == false {
                if normalizedKey == BaGuideTextNormalizer.normalizedKey("礼物偏好") {
                    inGiftBlock = true
                }
                continue
            }
            if isGiftTailKey(normalizedKey) || isGiftStopKey(normalizedKey) {
                break
            }

            let keyGiftImages = giftImages(rawKey, sourceURL: sourceURL)
            let keyEmojiImages = emojiImages(rawKey, sourceURL: sourceURL)
            let keyGenericImages = images(from: keyCell, sourceURL: sourceURL)

            var rowGiftImages: [URL] = []
            var rowEmojiImages: [URL] = []
            var rowGenericImages: [URL] = []
            var notes: [String] = []
            for cell in row.dropFirst() {
                let rawValue = cell.string("value") ?? ""
                rowGiftImages.append(contentsOf: giftImages(rawValue, sourceURL: sourceURL))
                rowEmojiImages.append(contentsOf: emojiImages(rawValue, sourceURL: sourceURL))
                rowGenericImages.append(contentsOf: images(from: cell, sourceURL: sourceURL))
                let note = BaGuideTextNormalizer.clean(rawValue)
                if note.isEmpty == false, BaGuideTextNormalizer.normalizeMediaURL(note, sourceURL: sourceURL).map(BaGuideTextNormalizer.looksLikeImageURL) != true {
                    notes.append(note)
                }
            }

            let explicitGifts = BaGuideTextNormalizer.dedupe(keyGiftImages + rowGiftImages)
            let explicitEmojis = BaGuideTextNormalizer.dedupe(keyEmojiImages + rowEmojiImages)
            let hasGiftIconKey = keyGenericImages.contains(where: isLikelyGiftPreferenceIcon) || keyGiftImages.isEmpty == false
            let isContinuationRow = normalizedKey.isEmpty &&
                continuationQuota > 0 &&
                rowGenericImages.isEmpty == false &&
                keyGiftImages.isEmpty &&
                rowGiftImages.isEmpty

            guard hasGiftIconKey || explicitGifts.isEmpty == false || isContinuationRow else {
                if normalizedKey.isEmpty == false {
                    continuationQuota = 0
                    continuationEmojiImages = []
                    continuationNote = ""
                } else if continuationQuota > 0 {
                    continuationQuota -= 1
                }
                continue
            }

            let giftURLs: [URL]
            if explicitGifts.isEmpty == false {
                giftURLs = explicitGifts
            } else {
                giftURLs = rowGenericImages.filter { isLikelyGiftPreferenceIcon($0) == false }
            }
            let emojiURLs: [URL]
            if isContinuationRow {
                emojiURLs = continuationEmojiImages
            } else {
                let genericEmoji = (keyGenericImages + rowGenericImages).filter(isLikelyGiftPreferenceIcon)
                emojiURLs = BaGuideTextNormalizer.dedupe(explicitEmojis.isEmpty ? genericEmoji : explicitEmojis)
            }
            let note = notes.first ?? (isContinuationRow ? continuationNote : "")

            for giftURL in BaGuideTextNormalizer.dedupe(giftURLs) {
                let imageURLs = BaGuideTextNormalizer.dedupe([giftURL] + emojiURLs)
                out.append(
                    BaGuideRow(
                        id: "gift-\(giftIndex)-\(abs(giftURL.absoluteString.hashValue))",
                        title: String(format: String(localized: "ba.student.detail.gift.item.format"), giftIndex),
                        value: note,
                        imageURL: giftURL,
                        imageURLs: imageURLs
                    )
                )
                giftIndex += 1
            }

            if isContinuationRow {
                continuationQuota = max(continuationQuota - 1, 0)
            } else if hasGiftIconKey || explicitGifts.isEmpty == false {
                continuationQuota = 3
                continuationEmojiImages = emojiURLs
                continuationNote = note
            }
        }
        return out
    }

    private func giftImages(_ raw: String, sourceURL: URL?) -> [URL] {
        BaGuideTextNormalizer.imageURLsFromHTMLClasses(raw, classKeywords: ["gif-img", "gift-img"], sourceURL: sourceURL)
    }

    private func emojiImages(_ raw: String, sourceURL: URL?) -> [URL] {
        BaGuideTextNormalizer.imageURLsFromHTMLClasses(raw, classKeywords: ["gif-emoji", "gift-emoji"], sourceURL: sourceURL)
    }

    private func images(from cell: BaJSONObject, sourceURL: URL?) -> [URL] {
        var out = BaGuideTextNormalizer.imageURLs(in: cell["value"], sourceURL: sourceURL)
        if let raw = cell.string("value") {
            out.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(raw, sourceURL: sourceURL))
        }
        return BaGuideTextNormalizer.dedupe(out)
    }

    private func isLikelyGiftPreferenceIcon(_ url: URL) -> Bool {
        let value = url.absoluteString
        if let range = value.range(of: #"/w_(\d{1,4})/h_(\d{1,4})/"#, options: .regularExpression) {
            let matched = value[range]
            let numbers = matched.split(whereSeparator: { $0 < "0" || $0 > "9" }).compactMap { Int($0) }
            if numbers.count >= 2, (24 ... 120).contains(numbers[0]), (24 ... 120).contains(numbers[1]) {
                return true
            }
        }
        return value.localizedCaseInsensitiveContains("gift") &&
            value.localizedCaseInsensitiveContains("furniture") == false &&
            value.localizedCaseInsensitiveContains("chocolate") == false
    }

    private func isGiftTailKey(_ normalizedKey: String) -> Bool {
        let tails = ["初始数据", "顶级数据", "学生信息", "介绍", "配音", "专武", "爱用品", "能力解放", "装备", "羁绊等级奖励", "技能类型", "技能名词", "EX技能升级材料", "其他技能升级材料"]
            .map(BaGuideTextNormalizer.normalizedKey)
        return normalizedKey.isEmpty == false && tails.contains(normalizedKey)
    }

    private func isGiftStopKey(_ normalizedKey: String) -> Bool {
        let fragments = ["互动家具", "情人节巧克力", "巧克力图", "巧克力名称", "巧克力简介", "相关同名角色", "同名角色名称", "配音", "配音语言", "配音大类", "官方介绍", "角色表情", "回忆大厅", "立绘", "本家画", "设定集", "TV动画设定图"]
            .map(BaGuideTextNormalizer.normalizedKey)
        return normalizedKey.isEmpty == false && fragments.contains { normalizedKey.contains($0) }
    }
}
