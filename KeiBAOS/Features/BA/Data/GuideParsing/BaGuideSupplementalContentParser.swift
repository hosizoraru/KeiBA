//
//  BaGuideSupplementalContentParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

struct BaGuideSupplementalContentParser {
    func parse(content: Any?, sourceURL: URL?) -> BaStructuredGuideParse {
        var parsed = BaStructuredGuideParse()
        walk(content, sourceURL: sourceURL, parsed: &parsed)
        parsed.profileRows = dedupeRows(parsed.profileRows)
        parsed.galleryItems = dedupeGalleryItems(parsed.galleryItems)
        return parsed
    }

    private func walk(
        _ any: Any?,
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse,
        depth: Int = 0
    ) {
        guard depth <= 10, let any else { return }
        if let object = any as? BaJSONObject {
            switch object.string("type")?.trimmingCharacters(in: .whitespacesAndNewlines) {
            case "character-profile":
                processCharacterProfile(object, sourceURL: sourceURL, parsed: &parsed)
            case "relation-info":
                processRelationInfo(object, sourceURL: sourceURL, parsed: &parsed)
            case "tab-info":
                processTabInfo(object, sourceURL: sourceURL, parsed: &parsed)
            case "weapon-info":
                processWeaponInfo(object, sourceURL: sourceURL, parsed: &parsed)
            default:
                break
            }

            for value in object.values {
                walk(value, sourceURL: sourceURL, parsed: &parsed, depth: depth + 1)
            }
            return
        }

        if let array = any as? [Any] {
            for value in array {
                walk(value, sourceURL: sourceURL, parsed: &parsed, depth: depth + 1)
            }
        }
    }

    private func processCharacterProfile(
        _ object: BaJSONObject,
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse
    ) {
        guard let data = object.object("data") else { return }

        let profileName = text(from: data["name"])
        if profileName.isEmpty == false {
            appendProfileRow(title: "角色名称", value: profileName, sourceURL: sourceURL, parsed: &parsed)
        }

        for item in objectArray(data["attrList"]) {
            let key = text(from: item["title"])
            let value = text(from: item["content"], separator: " / ")
            let icons = BaGuideTextNormalizer.imageURLs(in: item["content"], sourceURL: sourceURL)
            appendProfileRow(title: key, value: value, imageURLs: icons, sourceURL: sourceURL, parsed: &parsed)
        }

        let descTitle = text(from: data["descTitle"]).ifBlank("个人简介")
        let desc = textLines(from: data["desc"]).joined(separator: "\n")
        if desc.isEmpty == false {
            appendProfileRow(title: descTitle, value: desc, sourceURL: sourceURL, parsed: &parsed)
            if parsed.summary.isEmpty {
                parsed.summary = desc.components(separatedBy: .newlines).prefix(2).joined(separator: " ")
            }
        }

        let images = BaGuideTextNormalizer.dedupe(
            BaGuideTextNormalizer.imageURLs(in: data["imageList"], sourceURL: sourceURL) +
                BaGuideTextNormalizer.imageURLs(in: data["imagesList"], sourceURL: sourceURL)
        )
        if parsed.imageURL == nil {
            parsed.imageURL = images.first
        }
        parsed.galleryItems.append(contentsOf: mediaItems(title: "立绘", imageURLs: images, mediaURLs: images, kind: .image))
    }

    private func processRelationInfo(
        _ object: BaJSONObject,
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse
    ) {
        guard let data = object.object("data") else { return }
        for group in objectArray(data["list"]) {
            let relationTitle = text(from: group["title"]).ifBlank("相关人物")
            let relationRoleTitle = relationTitle.localizedCaseInsensitiveContains("同名")
                ? "同名角色名称"
                : "相关角色名称"
            if relationTitle.localizedCaseInsensitiveContains("同名") {
                appendProfileRow(title: "相关同名角色", value: relationTitle, sourceURL: sourceURL, parsed: &parsed)
            }

            for item in objectArray(group["content"]) {
                let name = text(from: item["name"])
                let guideURL = relationGuideURL(from: item)
                let avatar = relationAvatarURL(from: item, sourceURL: sourceURL)
                let value = [name, guideURL?.absoluteString ?? ""]
                    .filter { $0.isEmpty == false }
                    .joined(separator: " / ")
                guard value.isEmpty == false || avatar != nil else { continue }
                appendProfileRow(
                    title: relationRoleTitle,
                    value: value,
                    imageURLs: [avatar].compactMap(\.self),
                    sourceURL: sourceURL,
                    parsed: &parsed,
                    preservesWebLinks: true
                )
            }
        }
    }

    private func relationGuideURL(from item: BaJSONObject) -> URL? {
        for key in relationGuideURLKeys {
            if let url = canonicalGuideURL(from: item.string(key) ?? "") {
                return url
            }
        }
        for key in relationGuideContentIDKeys {
            if let contentID = item.int64(key), contentID > 0,
               let url = URL(string: "https://www.gamekee.com/ba/tj/\(contentID).html")
            {
                return url
            }
        }
        for candidate in relationLinkCandidates(in: item) {
            if let url = canonicalGuideURL(from: candidate) {
                return url
            }
        }
        return nil
    }

    private func relationAvatarURL(from item: BaJSONObject, sourceURL: URL?) -> URL? {
        for key in relationAvatarURLKeys {
            if let url = BaGuideTextNormalizer.normalizeMediaURL(item.string(key) ?? "", sourceURL: sourceURL),
               BaGuideTextNormalizer.looksLikeImageURL(url)
            {
                return url
            }
        }
        return BaGuideTextNormalizer.imageURLs(in: item, sourceURL: sourceURL).first
    }

    private func processTabInfo(
        _ object: BaJSONObject,
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse
    ) {
        guard let data = object.object("data") else { return }
        for tab in objectArray(data["tabList"]) {
            let title = text(from: tab["title"])
                .ifBlank(tab.string("title") ?? "")
                .ifBlank(BaL10n.string("ba.student.detail.media.gallery"))
            let rawContent = tab["content"] ?? tab
            parsed.galleryItems.append(contentsOf: galleryItems(title: title, raw: rawContent, sourceURL: sourceURL))

            let links = BaGuideTextNormalizer.dedupe(
                webURLs(in: tab["topDesc"], sourceURL: sourceURL) +
                    webURLs(in: tab["bottomDesc"], sourceURL: sourceURL) +
                    webURLs(in: tab["desc"], sourceURL: sourceURL)
            )
            for link in links {
                appendProfileRow(
                    title: "影画相关链接",
                    value: title.isEmpty ? link.absoluteString : "\(title) / \(link.absoluteString)",
                    sourceURL: sourceURL,
                    parsed: &parsed,
                    preservesWebLinks: true
                )
            }
        }
    }

    private func processWeaponInfo(
        _ object: BaJSONObject,
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse
    ) {
        guard let data = object.object("data") else { return }
        let title = text(from: data["title"])
        guard title.localizedCaseInsensitiveContains("巧克力") else { return }
        let iconURL = BaGuideTextNormalizer.normalizeMediaURL(data.string("icon") ?? "", sourceURL: sourceURL)
        let name = text(from: data["name"], separator: " / ")
        let desc = text(from: data["desc"], separator: " / ")

        if name.isEmpty == false || iconURL != nil {
            appendProfileRow(
                title: "巧克力",
                value: name.ifBlank(title),
                imageURLs: [iconURL].compactMap(\.self),
                sourceURL: sourceURL,
                parsed: &parsed
            )
        }
        if desc.isEmpty == false {
            appendProfileRow(title: "巧克力简介", value: desc, sourceURL: sourceURL, parsed: &parsed)
        }
        if let iconURL {
            parsed.galleryItems.append(
                BaGuideGalleryItem(
                    id: "supplement-chocolate-\(abs(iconURL.absoluteString.hashValue))",
                    title: "巧克力图",
                    detail: BaGuideMediaKind.image.title,
                    imageURL: iconURL,
                    mediaURL: iconURL,
                    mediaKind: .image
                )
            )
        }
    }

    private func appendProfileRow(
        title: String,
        value: String,
        imageURLs: [URL] = [],
        sourceURL: URL?,
        parsed: inout BaStructuredGuideParse,
        preservesWebLinks: Bool = false
    ) {
        let cleanTitle = BaGuideTextNormalizer.clean(title)
        let cleanValue = preservesWebLinks
            ? BaGuideTextNormalizer.clean(value)
            : BaGuideTextNormalizer.cleanDisplayText(value)
        let images = BaGuideTextNormalizer.dedupe(imageURLs)
        guard cleanTitle.isEmpty == false || cleanValue.isEmpty == false || images.isEmpty == false else {
            return
        }
        let signature = "\(cleanTitle)|\(cleanValue)|\(images.map(\.absoluteString).joined(separator: ","))"
        parsed.profileRows.append(
            BaGuideRow(
                id: "supplement-profile-\(parsed.profileRows.count)-\(abs(signature.hashValue))",
                title: cleanTitle.ifBlank("信息"),
                value: cleanValue,
                imageURL: images.first,
                imageURLs: images.isEmpty ? nil : images
            )
        )
    }

    private func galleryItems(title: String, raw: Any?, sourceURL: URL?) -> [BaGuideGalleryItem] {
        let title = BaGuideGallerySupport.normalizeArrayTitle(title)
        let images = BaGuideTextNormalizer.dedupe(BaGuideTextNormalizer.imageURLs(in: raw, sourceURL: sourceURL))
        let videos = BaGuideTextNormalizer.dedupe(BaGuideTextNormalizer.videoURLs(in: raw, sourceURL: sourceURL))
        let audios = BaGuideTextNormalizer.dedupe(BaGuideTextNormalizer.audioURLs(in: raw, sourceURL: sourceURL))
        return mediaItems(title: title, imageURLs: images, mediaURLs: images, kind: .image) +
            mediaItems(title: title, imageURLs: images, mediaURLs: videos, kind: .video) +
            mediaItems(title: title, imageURLs: images, mediaURLs: audios, kind: .audio)
    }

    private func mediaItems(
        title: String,
        imageURLs: [URL],
        mediaURLs: [URL],
        kind: BaGuideMediaKind
    ) -> [BaGuideGalleryItem] {
        mediaURLs.enumerated().map { index, mediaURL in
            BaGuideGalleryItem(
                id: "supplement-\(kind.rawValue)-\(index)-\(abs(mediaURL.absoluteString.hashValue))",
                title: mediaURLs.count > 1 ? "\(title) \(index + 1)" : title,
                detail: kind.title,
                imageURL: kind == .image ? mediaURL : imageURLs.first,
                mediaURL: mediaURL,
                mediaKind: kind
            )
        }
    }

    private func canonicalGuideURL(from raw: String) -> URL? {
        BaSameNameStudentGuideLinkResolver.canonicalURL(from: raw)
    }

    private func relationLinkCandidates(in any: Any?, depth: Int = 0) -> [String] {
        guard depth <= 5, let any else { return [] }
        if let string = any as? String {
            return [string]
        }
        if let number = any as? NSNumber {
            return [number.stringValue]
        }
        if let object = any as? BaJSONObject {
            return object.values.flatMap { relationLinkCandidates(in: $0, depth: depth + 1) }
        }
        if let array = any as? [Any] {
            return array.flatMap { relationLinkCandidates(in: $0, depth: depth + 1) }
        }
        return []
    }

    private func objectArray(_ any: Any?) -> [BaJSONObject] {
        if let objects = any as? [BaJSONObject] {
            return objects
        }
        return (any as? [Any])?.compactMap { $0 as? BaJSONObject } ?? []
    }

    private func text(from any: Any?, separator: String = " ") -> String {
        BaGuideRichTextExtractor.text(from: any, separator: separator)
    }

    private func textLines(from any: Any?) -> [String] {
        BaGuideRichTextExtractor.lines(from: any)
    }

    private func dedupeRows(_ rows: [BaGuideRow]) -> [BaGuideRow] {
        var seen = Set<String>()
        return rows.filter { row in
            let key = "\(row.title.trimmed)|\(row.value.trimmed)|\(row.imageURL?.absoluteString ?? "")|\((row.imageURLs ?? []).map(\.absoluteString).joined(separator: "|"))"
            return seen.insert(key).inserted
        }
    }

    private func dedupeGalleryItems(_ items: [BaGuideGalleryItem]) -> [BaGuideGalleryItem] {
        var seen = Set<String>()
        return items.filter { item in
            let media = item.mediaURL ?? item.imageURL
            let key = "\(item.mediaKind?.rawValue ?? "")|\(media?.absoluteString ?? item.id)"
            return seen.insert(key).inserted
        }
    }

    private func webURLs(in any: Any?, sourceURL: URL?, depth: Int = 0) -> [URL] {
        guard depth <= 8, let any else { return [] }
        if let string = any as? String {
            return extractWebURLs(from: string, sourceURL: sourceURL)
        }
        if let object = any as? BaJSONObject {
            return object.values.flatMap { webURLs(in: $0, sourceURL: sourceURL, depth: depth + 1) }
        }
        if let array = any as? [Any] {
            return array.flatMap { webURLs(in: $0, sourceURL: sourceURL, depth: depth + 1) }
        }
        return []
    }

    private func extractWebURLs(from raw: String, sourceURL: URL?) -> [URL] {
        guard let regex = try? NSRegularExpression(pattern: #"((?:https?:)?//[^\s"'<>\\]+|/[A-Za-z0-9_\-./%]+(?:\?[^\s"'<>\\]+)?)"#, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        let urls = regex.matches(in: raw, range: range).compactMap { match -> URL? in
            guard let matchRange = Range(match.range(at: 1), in: raw),
                  let url = BaGuideTextNormalizer.normalizeMediaURL(String(raw[matchRange]), sourceURL: sourceURL)
            else {
                return nil
            }
            let pathExtension = url.pathExtension.lowercased()
            let mediaExtensions = ["jpg", "jpeg", "png", "webp", "gif", "svg", "mp4", "mov", "m3u8", "mp3", "m4a", "wav", "aac", "ogg", "oga", "opus", "flac"]
            return mediaExtensions.contains(pathExtension) ? nil : url
        }
        return BaGuideTextNormalizer.dedupe(urls)
    }
}

private let relationGuideURLKeys = [
    "jumpHref", "jumpUrl", "jump_url", "href", "url", "link", "linkUrl", "link_url", "detailUrl", "detail_url",
]

private let relationGuideContentIDKeys = [
    "contentId", "content_id", "cid", "id",
]

private let relationAvatarURLKeys = [
    "avatar", "icon", "image", "imageUrl", "image_url", "thumb", "thumbnail", "headIcon", "head_icon",
]

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func ifBlank(_ fallback: String) -> String {
        trimmed.isEmpty ? fallback : self
    }
}
