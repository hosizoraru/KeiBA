//
//  BaStudentGuideRepository.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaStudentGuideRepository {
    private let client: GameKeeClient

    init(client: GameKeeClient) {
        self.client = client
    }

    func fetchStudentDetail(
        entry: BaGuideCatalogEntry,
        now: Date = Date()
    ) async throws -> BaRepositorySnapshot<BaStudentGuideInfo> {
        let detail = try await fetchContentDetail(contentId: entry.contentId)
        let info = parseGuideInfo(
            apiData: detail.apiData,
            content: detail.content,
            html: detail.html,
            entry: entry,
            contentSource: detail.source,
            now: now
        )
        return BaRepositorySnapshot(value: info, syncedAt: now, sourceErrors: detail.errors)
    }

    private func fetchContentDetail(contentId: Int64) async throws -> RawContentDetail {
        let apiData = try await client.fetchJSONData(
            GameKeeRequest(
                pathOrURL: "/v1/content/detail/\(contentId)",
                refererPath: "/ba/tj/\(contentId).html",
                extraHeaders: GameKeeClient.baHeaders
            )
        )
        let dataObject = try GameKeeJSON.dataObject(from: apiData)
        var errors: [String] = []

        if let content = resolveContent(from: dataObject.string("content_json")) {
            return RawContentDetail(apiData: dataObject, content: content, html: nil, source: "content_json", errors: errors)
        }
        if let content = resolveContent(from: dataObject.string("content")) {
            return RawContentDetail(apiData: dataObject, content: content, html: nil, source: "content", errors: errors)
        }

        if let cdnURL = GameKeeJSON.normalizeImageURL(dataObject.string("content_cdn") ?? "") {
            do {
                let cdnData = try await client.fetchJSONData(
                    GameKeeRequest(pathOrURL: cdnURL.absoluteString, refererPath: "/ba/tj/\(contentId).html")
                )
                if let content = resolveContent(from: String(decoding: cdnData, as: UTF8.self)) {
                    return RawContentDetail(apiData: dataObject, content: content, html: nil, source: "content_cdn", errors: errors)
                }
                errors.append("content_cdn-empty")
            } catch {
                errors.append("content_cdn:\(error.localizedDescription)")
            }
        } else {
            errors.append("content_cdn-missing")
        }

        let html = try? await client.fetchHTML(
            GameKeeRequest(pathOrURL: "/ba/tj/\(contentId).html", refererPath: "/ba/tj/\(contentId).html")
        )
        return RawContentDetail(
            apiData: dataObject,
            content: nil,
            html: html,
            source: html == nil ? "api" : "html",
            errors: html == nil ? errors : []
        )
    }

    private func resolveContent(from raw: String?) -> Any? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, let data = trimmed.data(using: .utf8) else { return nil }
        guard let any = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let object = any as? BaJSONObject {
            if object["baseData"] != nil || object["styleData"] != nil {
                return object
            }
            if let nested = resolveContent(from: object.string("content")) {
                return nested
            }
            if let dataObject = object.object("data") {
                return dataObject
            }
        }
        if any is [Any] {
            return any
        }
        return nil
    }

    private func parseGuideInfo(
        apiData: BaJSONObject,
        content: Any?,
        html: String?,
        entry: BaGuideCatalogEntry,
        contentSource: String,
        now: Date
    ) -> BaStudentGuideInfo {
        let title = apiData.string("title") ?? entry.name
        let subtitle = apiData.object("game")?.string("name") ?? "GameKee"
        let parsed = BaGuideContentParser().parse(content: content, apiData: apiData, html: html, entry: entry)
        let apiSummary = parsed.summary
        let profileRows = parsed.profileRows
        let skillRows = parsed.skillRows
        let simulateRows = parsed.simulateRows
        let growthRows = parsed.growthRows
        let voiceRows = parsed.voiceRows
        let galleryItems = parsed.galleryItems
        let imageURL = parsed.imageURL ?? entry.iconURL

        return BaStudentGuideInfo(
            contentId: entry.contentId,
            sourceURL: entry.detailURL,
            title: title,
            subtitle: subtitle,
            summary: apiSummary.isEmpty ? entry.aliasDisplay : apiSummary,
            imageURL: imageURL,
            stats: parsed.stats.isEmpty ? stats(from: profileRows, fallback: entry) : parsed.stats,
            profileRows: profileRows.isEmpty ? fallbackProfileRows(entry: entry, summary: apiSummary) : profileRows,
            skillRows: skillRows,
            voiceRows: voiceRows,
            galleryItems: galleryItems,
            growthRows: growthRows,
            simulateRows: simulateRows,
            contentSource: contentSource,
            syncedAt: now
        )
    }

    private func rows(from pairs: [(String, String)]) -> [BaGuideRow] {
        var seen = Set<String>()
        return pairs.enumerated().compactMap { index, pair in
            let title = cleanText(pair.0)
            let value = cleanText(pair.1)
            guard title.isEmpty == false, value.isEmpty == false, title != value else { return nil }
            let key = "\(title)|\(value)"
            guard seen.insert(key).inserted else { return nil }
            return BaGuideRow(id: "row-\(index)-\(abs(key.hashValue))", title: title, value: value, imageURL: nil)
        }
    }

    private func stats(from profileRows: [BaGuideRow], fallback: BaGuideCatalogEntry) -> [BaGuideRow] {
        let preferred = profileRows.filter { row in
            let key = row.title
            return key.contains("学院") ||
                key.contains("社团") ||
                key.contains("生日") ||
                key.contains("实装") ||
                key.localizedCaseInsensitiveContains("school") ||
                key.localizedCaseInsensitiveContains("club")
        }
        if preferred.isEmpty == false {
            return Array(preferred.prefix(6))
        }
        return [
            BaGuideRow(
                id: "stat-content-id",
                title: String(localized: "ba.student.detail.contentId.title"),
                value: "\(fallback.contentId)",
                imageURL: nil
            ),
        ]
    }

    private func fallbackProfileRows(entry: BaGuideCatalogEntry, summary: String) -> [BaGuideRow] {
        [
            BaGuideRow(
                id: "profile-name",
                title: String(localized: "ba.student.detail.name.title"),
                value: entry.name,
                imageURL: nil
            ),
            BaGuideRow(
                id: "profile-alias",
                title: String(localized: "ba.student.detail.alias.title"),
                value: entry.aliasDisplay.isEmpty ? String(localized: "ba.common.none") : entry.aliasDisplay,
                imageURL: nil
            ),
            BaGuideRow(
                id: "profile-summary",
                title: String(localized: "ba.student.detail.summary.title"),
                value: summary.isEmpty ? String(localized: "ba.student.detail.summary.empty") : summary,
                imageURL: nil
            ),
        ]
    }

    private func voiceRows(from rows: [BaGuideRow], content: Any?) -> [BaGuideVoiceEntry] {
        let audioURLs = GameKeeJSON.findURLs(in: content) { raw in
            let lower = raw.lowercased()
            return lower.hasSuffix(".mp3") || lower.hasSuffix(".m4a") || lower.hasSuffix(".wav") || lower.contains("audio")
        }
        let voiceTextRows = rows.filter { row in
            isVoiceKey(row.title) || isVoiceKey(row.value)
        }
        let textEntries = voiceTextRows.enumerated().map { index, row in
            BaGuideVoiceEntry(
                id: "voice-\(index)-\(abs(row.id.hashValue))",
                title: row.title,
                subtitle: String(localized: "ba.student.detail.voice.subtitle"),
                transcript: row.value,
                audioURL: audioURLs.indices.contains(index) ? audioURLs[index] : nil
            )
        }
        if textEntries.isEmpty == false {
            return textEntries
        }
        return audioURLs.enumerated().map { index, url in
            BaGuideVoiceEntry(
                id: "voice-url-\(index)",
                title: String(format: String(localized: "ba.student.detail.voice.item.format"), index + 1),
                subtitle: url.lastPathComponent,
                transcript: "",
                audioURL: url
            )
        }
    }

    private func galleryItems(from content: Any?, apiData: BaJSONObject) -> [BaGuideGalleryItem] {
        var urls = GameKeeJSON.findURLs(in: content) { raw in
            let lower = raw.lowercased()
            return lower.hasSuffix(".jpg") ||
                lower.hasSuffix(".jpeg") ||
                lower.hasSuffix(".png") ||
                lower.hasSuffix(".webp") ||
                lower.hasSuffix(".gif") ||
                lower.contains("image") ||
                lower.contains("img") ||
                lower.contains("cdn")
        }
        if let image = GameKeeJSON.findImageURL(in: apiData) {
            urls.insert(image, at: 0)
        }
        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
            .prefix(18)
            .enumerated()
            .map { index, url in
                BaGuideGalleryItem(
                    id: "gallery-\(index)-\(abs(url.absoluteString.hashValue))",
                    title: String(format: String(localized: "ba.student.detail.gallery.item.format"), index + 1),
                    detail: url.host ?? "GameKee",
                    imageURL: url,
                    mediaURL: nil
                )
            }
    }

    private func parseHTMLMeta(_ html: String) -> HTMLMeta {
        HTMLMeta(
            summary: firstHTMLContent(html, names: ["description", "og:description"]),
            imageURL: firstHTMLContent(html, names: ["og:image", "twitter:image"]).flatMap(GameKeeJSON.normalizeImageURL)
        )
    }

    private func firstHTMLContent(_ html: String, names: [String]) -> String? {
        for name in names {
            let pattern = #"<meta[^>]+(?:name|property)=["']\#(name)["'][^>]+content=["']([^"']+)["'][^>]*>"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex ..< html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, range: range),
               let contentRange = Range(match.range(at: 1), in: html)
            {
                return GameKeeJSON.extractPlainText(from: String(html[contentRange]))
            }
        }
        return nil
    }

    private func cleanText(_ value: String) -> String {
        GameKeeJSON.extractPlainText(from: value)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isProfileKey(_ value: String) -> Bool {
        containsAny(value, tokens: ["档案", "基础", "资料", "学院", "社团", "生日", "年龄", "身高", "兴趣", "画师", "声优", "实装", "profile", "school", "club"])
    }

    private func isSkillKey(_ value: String) -> Bool {
        containsAny(value, tokens: ["技能", "EX", "普通", "被动", "辅助", "强化", "skill"])
    }

    private func isVoiceKey(_ value: String) -> Bool {
        containsAny(value, tokens: ["语音", "CV", "台词", "voice", "audio"])
    }

    private func isGrowthKey(_ value: String) -> Bool {
        containsAny(value, tokens: ["成长", "装备", "固有", "礼物", "羁绊", "升星", "growth", "gift"])
    }

    private func isSimulateKey(_ value: String) -> Bool {
        containsAny(value, tokens: ["模拟", "伤害", "配置", "轴", "演习", "simulate", "damage"])
    }

    private func containsAny(_ value: String, tokens: [String]) -> Bool {
        tokens.contains { value.localizedCaseInsensitiveContains($0) }
    }
}

private struct RawContentDetail {
    let apiData: BaJSONObject
    let content: Any?
    let html: String?
    let source: String
    let errors: [String]
}

private struct HTMLMeta {
    var summary: String?
    var imageURL: URL?
}
