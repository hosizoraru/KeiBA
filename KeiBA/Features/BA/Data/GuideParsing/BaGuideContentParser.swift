//
//  BaGuideContentParser.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaStructuredGuideParse {
    var summary: String = ""
    var imageURL: URL?
    var stats: [BaGuideRow] = []
    var profileRows: [BaGuideRow] = []
    var skillRows: [BaGuideRow] = []
    var voiceLanguageHeaders: [String] = []
    var voiceRows: [BaGuideVoiceEntry] = []
    var galleryItems: [BaGuideGalleryItem] = []
    var growthRows: [BaGuideRow] = []
    var simulateRows: [BaGuideRow] = []
}

struct BaGuideContentParser {
    func parse(
        content: Any?,
        apiData: BaJSONObject,
        html: String?,
        entry: BaGuideCatalogEntry
    ) -> BaStructuredGuideParse {
        let sourceURL = entry.detailURL ?? URL(string: "https://www.gamekee.com/ba/tj/\(entry.contentId).html")
        let baseData = Self.baseDataRows(from: content)
        let styleData = Self.styleDataRows(from: content)

        var parsed = BaGuideBaseDataParser().parse(baseData: baseData, sourceURL: sourceURL)
        let supplemental = BaGuideSupplementalContentParser().parse(content: content, sourceURL: sourceURL)
        let portraitURL = Self.preferredPortraitURL(from: baseData, sourceURL: sourceURL)
        let giftRows = BaGuideGiftParser().parse(baseData: baseData, sourceURL: sourceURL)
        parsed.profileRows.append(contentsOf: giftRows)
        parsed.profileRows = Self.dedupeRows(parsed.profileRows + supplemental.profileRows)
        let simulateRows = BaGuideSimulateParser().parse(baseData: baseData, sourceURL: sourceURL)
        if simulateRows.isEmpty == false {
            parsed.simulateRows = simulateRows
        }
        let voiceParse = BaGuideVoiceParser().parse(baseData: baseData, content: content, sourceURL: sourceURL)
        parsed.voiceLanguageHeaders = voiceParse.languageHeaders
        parsed.voiceRows = voiceParse.entries
        parsed.galleryItems = BaGuideMediaParser().parse(
            baseData: baseData,
            styleData: styleData,
            content: content,
            apiData: apiData,
            sourceURL: sourceURL
        )
        parsed.galleryItems = BaGuideMediaParser.sortedDistinct(supplemental.galleryItems + parsed.galleryItems)
        parsed.imageURL = portraitURL
            ?? supplemental.imageURL
            ?? parsed.imageURL
            ?? GameKeeJSON.normalizeImageURL(apiData.string("thumb") ?? "")
            ?? GameKeeJSON.findImageURL(in: apiData)
            ?? parsed.galleryItems.first?.imageURL
            ?? html.flatMap { parseHTMLImage($0) }
            ?? entry.iconURL
        if parsed.summary.isEmpty {
            parsed.summary = supplemental.summary.ifBlank(apiData.string("summary") ?? html.flatMap { parseHTMLSummary($0) } ?? "")
        }
        if parsed.stats.isEmpty {
            parsed.stats = makeStats(from: parsed.profileRows, fallback: entry)
        }
        return parsed
    }

    private func parseHTMLSummary(_ html: String) -> String? {
        firstHTMLMetaContent(html, names: ["description", "og:description"])
    }

    private func parseHTMLImage(_ html: String) -> URL? {
        firstHTMLMetaContent(html, names: ["og:image", "twitter:image"]).flatMap(GameKeeJSON.normalizeImageURL)
    }

    // NSRegularExpression is thread-safe once created; reuse compiled patterns
    // instead of recompiling per call.
    private nonisolated static let metaContentRegexCache: [String: NSRegularExpression] = {
        let names = ["description", "og:description", "og:image", "twitter:image"]
        var cache: [String: NSRegularExpression] = [:]
        for name in names {
            let pattern = #"<meta[^>]+(?:name|property)=["']\#(name)["'][^>]+content=["']([^"']+)["'][^>]*>"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                cache[name] = regex
            }
        }
        return cache
    }()

    private func firstHTMLMetaContent(_ html: String, names: [String]) -> String? {
        let range = NSRange(html.startIndex ..< html.endIndex, in: html)
        for name in names {
            let regex: NSRegularExpression?
            if let cached = Self.metaContentRegexCache[name] {
                regex = cached
            } else {
                let pattern = #"<meta[^>]+(?:name|property)=["']\#(name)["'][^>]+content=["']([^"']+)["'][^>]*>"#
                regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            }
            guard let regex else { continue }
            if let match = regex.firstMatch(in: html, range: range),
               let contentRange = Range(match.range(at: 1), in: html)
            {
                return BaGuideTextNormalizer.clean(String(html[contentRange]))
            }
        }
        return nil
    }

    private func makeStats(from profileRows: [BaGuideRow], fallback: BaGuideCatalogEntry) -> [BaGuideRow] {
        let preferred = profileRows.filter { row in
            BaGuideTextNormalizer.containsAny(
                row.title,
                tokens: ["学院", "社团", "生日", "实装", "school", "club"]
            )
        }
        if preferred.isEmpty == false {
            return Array(preferred.prefix(6))
        }
        return [
            BaGuideRow(
                id: "stat-content-id",
                title: BaL10n.string("ba.student.detail.contentId.title"),
                value: "\(fallback.contentId)",
                imageURL: nil
            ),
        ]
    }

    private static func dedupeRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        var seen = Set<String>()
        return rows.filter { row in
            let key = "\(row.title.trimmingCharacters(in: .whitespacesAndNewlines))|\(row.value.trimmingCharacters(in: .whitespacesAndNewlines))|\(row.imageURL?.absoluteString ?? "")|\((row.imageURLs ?? []).map(\.absoluteString).joined(separator: "|"))"
            return seen.insert(key).inserted
        }
    }

    static func baseDataRows(from content: Any?) -> [[BaJSONObject]] {
        if let object = content as? BaJSONObject {
            return rows(from: object["baseData"])
        }
        return rows(from: content)
    }

    static func styleDataRows(from content: Any?) -> [BaJSONObject] {
        guard let object = content as? BaJSONObject else { return [] }
        return (object["styleData"] as? [Any])?.compactMap { $0 as? BaJSONObject } ?? []
    }

    private static func preferredPortraitURL(from baseData: [[BaJSONObject]], sourceURL: URL?) -> URL? {
        let preferredKeys = ["角色图片", "角色头像", "头像", "角色立绘", "立绘", "站绘"]
        for row in baseData {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            guard preferredKeys.contains(where: { key.localizedCaseInsensitiveContains($0) }) else {
                continue
            }
            let images = BaGuideTextNormalizer.imageURLs(in: row, sourceURL: sourceURL)
            if let image = images.first {
                return image
            }
        }
        return nil
    }

    private static func rows(from any: Any?) -> [[BaJSONObject]] {
        guard let array = any as? [Any] else { return [] }
        return array.compactMap { row in
            if let cells = row as? [BaJSONObject] {
                return cells
            }
            if let values = row as? [Any] {
                return values.compactMap { $0 as? BaJSONObject }
            }
            return nil
        }.filter { $0.isEmpty == false }
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
