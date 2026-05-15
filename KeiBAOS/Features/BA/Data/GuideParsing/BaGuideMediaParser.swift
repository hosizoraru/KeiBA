//
//  BaGuideMediaParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideMediaParser {
    func parse(
        baseData: [[BaJSONObject]],
        styleData: [BaJSONObject],
        content: Any?,
        apiData: BaJSONObject,
        sourceURL: URL?
    ) -> [BaGuideGalleryItem] {
        var items = parseBaseData(baseData, sourceURL: sourceURL)
        items.append(contentsOf: parseStyleData(styleData, sourceURL: sourceURL))

        if items.isEmpty {
            let images = BaGuideTextNormalizer.imageURLs(in: content, sourceURL: sourceURL)
            items.append(contentsOf: mediaItems(title: "立绘", imageURLs: images, mediaURLs: images, kind: .image))
        }

        if items.isEmpty, let image = GameKeeJSON.findImageURL(in: apiData) {
            items.append(
                BaGuideGalleryItem(
                    id: "api-image-\(abs(image.absoluteString.hashValue))",
                    title: "立绘",
                    detail: BaGuideMediaKind.image.title,
                    imageURL: image,
                    mediaURL: image,
                    mediaKind: .image
                )
            )
        }

        return Self.sortedDistinct(items).prefix(100).map { $0 }
    }

    nonisolated static func sortedDistinct(_ items: [BaGuideGalleryItem]) -> [BaGuideGalleryItem] {
        var seen = Set<String>()
        return items
            .filter { item in
                guard BaGuideGallerySupport.isRenderable(item) else { return false }
                let media = item.mediaURL ?? item.imageURL
                let key = "\(item.mediaKind?.rawValue ?? "")|\(media?.absoluteString ?? item.id)"
                return seen.insert(key).inserted
            }
            .sorted {
                let leftOrder = BaGuideGallerySupport.categoryOrder($0.title)
                let rightOrder = BaGuideGallerySupport.categoryOrder($1.title)
                if leftOrder != rightOrder { return leftOrder < rightOrder }

                let leftGroup = BaGuideGallerySupport.titleGroupKey($0.title)
                let rightGroup = BaGuideGallerySupport.titleGroupKey($1.title)
                if leftGroup != rightGroup { return leftGroup < rightGroup }

                let leftIndex = BaGuideGallerySupport.itemIndex($0.title)
                let rightIndex = BaGuideGallerySupport.itemIndex($1.title)
                if leftIndex != rightIndex { return leftIndex < rightIndex }

                return ($0.mediaURL ?? $0.imageURL)?.absoluteString ?? $0.id <
                    (($1.mediaURL ?? $1.imageURL)?.absoluteString ?? $1.id)
            }
    }

    private func parseBaseData(_ baseData: [[BaJSONObject]], sourceURL: URL?) -> [BaGuideGalleryItem] {
        var out: [BaGuideGalleryItem] = []
        var inGalleryContext = false
        var lastGalleryTitle = ""
        let memoryUnlockLevel = findMemoryUnlockLevel(baseData)

        for row in baseData {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            if key == "回忆大厅解锁等级" { continue }
            if BaGuideGallerySupport.normalizeTitle(key).hasPrefix("回忆大厅文件") { continue }

            let isGalleryContextStart = containsAny(key, tokens: galleryContextStartKeywords)
            let isNonGallerySectionStart = key.isEmpty == false && containsAny(key, tokens: nonGallerySectionKeywords)
            if isNonGallerySectionStart, isGalleryContextStart == false {
                inGalleryContext = false
                lastGalleryTitle = ""
            }
            if isGalleryContextStart {
                inGalleryContext = true
                if key.isEmpty == false {
                    lastGalleryTitle = key
                }
            }

            var images: [URL] = []
            var videos: [URL] = []
            var audios: [URL] = []
            var notes: [String] = []

            for cell in row.dropFirst() {
                let type = (cell.string("type") ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let value = cell["value"]
                let valueText = cell.string("value") ?? ""

                switch type {
                case "image":
                    images.append(contentsOf: directMediaURL(valueText, sourceURL: sourceURL, predicate: BaGuideTextNormalizer.looksLikeImageURL).map { [$0] } ?? [])
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                case "imageset", "live2d":
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                case "video":
                    videos.append(contentsOf: directMediaURL(valueText, sourceURL: sourceURL, predicate: BaGuideTextNormalizer.looksLikeVideoURL).map { [$0] } ?? [])
                    videos.append(contentsOf: BaGuideTextNormalizer.videoURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                case "audio":
                    audios.append(contentsOf: directMediaURL(valueText, sourceURL: sourceURL, predicate: BaGuideTextNormalizer.looksLikeAudioURL).map { [$0] } ?? [])
                    audios.append(contentsOf: BaGuideTextNormalizer.audioURLs(in: value, sourceURL: sourceURL))
                default:
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                    videos.append(contentsOf: BaGuideTextNormalizer.videoURLs(in: value, sourceURL: sourceURL))
                    audios.append(contentsOf: BaGuideTextNormalizer.audioURLs(in: value, sourceURL: sourceURL))
                    let plain = BaGuideTextNormalizer.cleanDisplayText(valueText)
                    if plain.isEmpty == false {
                        notes.append(plain)
                    }
                }
            }

            images = BaGuideTextNormalizer.dedupe(images)
            videos = BaGuideTextNormalizer.dedupe(videos)
            audios = BaGuideTextNormalizer.dedupe(audios)

            let hasMedia = images.isEmpty == false || videos.isEmpty == false || audios.isEmpty == false
            let isFallbackGallery = hasMedia &&
                inGalleryContext &&
                containsAny(key, tokens: nonGalleryFallbackKeywords) == false
            guard isGalleryKey(key) || isFallbackGallery else { continue }

            let galleryTitle = key.ifBlank(lastGalleryTitle.ifBlank("影画"))
            let unlockLevel = key.hasPrefix("回忆大厅") ? memoryUnlockLevel : nil
            out.append(contentsOf: mediaItems(
                title: galleryTitle,
                imageURLs: images,
                mediaURLs: images,
                kind: .image,
                memoryUnlockLevel: unlockLevel,
                notes: notes
            ))
            out.append(contentsOf: mediaItems(
                title: galleryTitle,
                imageURLs: images,
                mediaURLs: videos,
                kind: .video,
                memoryUnlockLevel: unlockLevel,
                notes: notes
            ))
            out.append(contentsOf: mediaItems(
                title: galleryTitle,
                imageURLs: images,
                mediaURLs: audios,
                kind: .audio,
                memoryUnlockLevel: unlockLevel,
                notes: notes
            ))
        }
        return out
    }

    private func parseStyleData(_ styleData: [BaJSONObject], sourceURL: URL?) -> [BaGuideGalleryItem] {
        styleData.enumerated().flatMap { index, block in
            let title = BaGuideTextNormalizer.clean(block.string("name") ?? "")
                .ifBlank(String(format: String(localized: "ba.student.detail.media.style.format"), index + 1))
            let data = block["data"]
            let images = BaGuideTextNormalizer.dedupe(BaGuideTextNormalizer.imageURLs(in: data, sourceURL: sourceURL))
            let videos = BaGuideTextNormalizer.dedupe(BaGuideTextNormalizer.videoURLs(in: data, sourceURL: sourceURL))
            return mediaItems(title: title, imageURLs: images, mediaURLs: images, kind: .image) +
                mediaItems(title: title, imageURLs: images, mediaURLs: videos, kind: .video)
        }
    }

    private func mediaItems(
        title: String,
        imageURLs: [URL],
        mediaURLs: [URL],
        kind: BaGuideMediaKind,
        memoryUnlockLevel: String? = nil,
        notes: [String] = []
    ) -> [BaGuideGalleryItem] {
        mediaURLs.enumerated().map { index, mediaURL in
            let displayTitle = mediaURLs.count > 1 ? "\(title) \(index + 1)" : title
            let note = note(for: index, mediaCount: mediaURLs.count, notes: notes)
            return BaGuideGalleryItem(
                id: "\(kind.rawValue)-\(index)-\(abs(mediaURL.absoluteString.hashValue))",
                title: displayTitle,
                detail: kind.title,
                imageURL: kind == .image ? mediaURL : imageURLs.first,
                mediaURL: mediaURL,
                mediaKind: kind,
                memoryUnlockLevel: memoryUnlockLevel,
                note: note.isEmpty ? nil : note
            )
        }
    }

    private func note(for index: Int, mediaCount: Int, notes: [String]) -> String {
        let normalized = notes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.isEmpty == false }
        guard normalized.isEmpty == false else { return "" }
        if mediaCount <= 1 { return normalized.joined(separator: " / ") }
        if normalized.count == mediaCount { return normalized.indices.contains(index) ? normalized[index] : "" }
        if normalized.count == 1 { return index == mediaCount - 1 ? normalized[0] : "" }
        return normalized.indices.contains(index) ? normalized[index] : (normalized.last ?? "")
    }

    private func directMediaURL(_ raw: String, sourceURL: URL?, predicate: (URL) -> Bool) -> URL? {
        guard BaGuideTextNormalizer.isPlaceholderMediaToken(raw) == false,
              let url = BaGuideTextNormalizer.normalizeMediaURL(raw, sourceURL: sourceURL),
              predicate(url)
        else {
            return nil
        }
        return url
    }

    private func findMemoryUnlockLevel(_ baseData: [[BaJSONObject]]) -> String {
        for row in baseData {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            guard key == "回忆大厅解锁等级" else { continue }
            let text = row.dropFirst()
                .compactMap { $0.string("value") }
                .map(BaGuideTextNormalizer.clean)
                .first { $0.isEmpty == false } ?? ""
            return text.range(of: #"\d+"#, options: .regularExpression).map { String(text[$0]) } ?? text
        }
        return ""
    }

    private func isGalleryKey(_ key: String) -> Bool {
        key.isEmpty == false && containsAny(key, tokens: galleryKeywords)
    }

    private func containsAny(_ raw: String, tokens: [String]) -> Bool {
        BaGuideTextNormalizer.containsAny(raw, tokens: tokens)
    }
}

private let galleryKeywords = [
    "立绘", "本家画", "TV动画设定图", "回忆大厅视频", "回忆大厅", "PV", "Live", "巧克力图",
    "互动家具", "角色表情", "表情", "角色演示", "设定集", "官方介绍", "官方衍生", "情人节巧克力", "BGM",
]

private let galleryContextStartKeywords = galleryKeywords + ["视频"]

private let nonGallerySectionKeywords = [
    "技能", "技能类型", "技能名词", "EX技能升级材料", "其他技能升级材料",
    "专武", "爱用品", "能力解放", "礼物偏好", "初始数据", "顶级数据",
    "学生信息", "介绍", "配音",
]

private let nonGalleryFallbackKeywords = [
    "头像", "技能", "图标", "语音", "台词", "专武", "武器", "装备", "材料",
    "能力解放", "礼物偏好", "初始数据", "学生信息", "角色名称", "稀有度", "所属学园", "所属社团",
    "战术作用", "攻击类型", "防御类型", "位置", "武器类型", "市街", "屋外", "屋内", "室内",
]

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
