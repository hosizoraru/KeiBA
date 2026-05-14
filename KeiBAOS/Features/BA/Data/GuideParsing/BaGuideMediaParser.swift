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
            items.append(contentsOf: mediaItems(title: "GameKee", detail: "", imageURLs: images, mediaURLs: images, kind: .image))
        }
        if let image = GameKeeJSON.findImageURL(in: apiData), items.contains(where: { $0.imageURL == image }) == false {
            items.insert(
                BaGuideGalleryItem(
                    id: "api-image-\(abs(image.absoluteString.hashValue))",
                    title: String(localized: "ba.student.detail.media.cover"),
                    detail: image.host ?? "GameKee",
                    imageURL: image,
                    mediaURL: image,
                    mediaKind: .image
                ),
                at: 0
            )
        }
        return dedupe(items).prefix(36).map { $0 }
    }

    private func parseBaseData(_ baseData: [[BaJSONObject]], sourceURL: URL?) -> [BaGuideGalleryItem] {
        var out: [BaGuideGalleryItem] = []
        var inGalleryContext = false
        var lastTitle = ""
        let memoryUnlockLevel = findMemoryUnlockLevel(baseData)
        for row in baseData {
            guard let keyCell = row.first else { continue }
            let key = BaGuideTextNormalizer.clean(keyCell.string("value") ?? "")
            if key == "回忆大厅解锁等级" {
                continue
            }
            let isGalleryStart = isGalleryKey(key) || BaGuideTextNormalizer.containsAny(key, tokens: ["视频"])
            if isNonGalleryKey(key), isGalleryStart == false {
                inGalleryContext = false
                lastTitle = ""
            }
            if isGalleryStart {
                inGalleryContext = true
                if key.isEmpty == false {
                    lastTitle = key
                }
            }

            var images: [URL] = []
            var videos: [URL] = []
            var audios: [URL] = []
            var live2d: [URL] = []
            var notes: [String] = []
            for cell in row.dropFirst() {
                let type = (cell.string("type") ?? "").lowercased()
                let value = cell["value"]
                let valueText = cell.string("value") ?? ""
                let cleaned = BaGuideTextNormalizer.cleanDisplayText(valueText)
                if cleaned.isEmpty == false {
                    notes.append(cleaned)
                }
                switch type {
                case "image", "imageset":
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                case "video":
                    videos.append(contentsOf: BaGuideTextNormalizer.videoURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                case "audio":
                    audios.append(contentsOf: BaGuideTextNormalizer.audioURLs(in: value, sourceURL: sourceURL))
                case "live2d":
                    live2d.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                default:
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLs(in: value, sourceURL: sourceURL))
                    images.append(contentsOf: BaGuideTextNormalizer.imageURLsFromHTML(valueText, sourceURL: sourceURL))
                    videos.append(contentsOf: BaGuideTextNormalizer.videoURLs(in: value, sourceURL: sourceURL))
                    audios.append(contentsOf: BaGuideTextNormalizer.audioURLs(in: value, sourceURL: sourceURL))
                }
            }
            images = BaGuideTextNormalizer.dedupe(images)
            videos = BaGuideTextNormalizer.dedupe(videos)
            audios = BaGuideTextNormalizer.dedupe(audios)
            live2d = BaGuideTextNormalizer.dedupe(live2d)
            let hasMedia = images.isEmpty == false || videos.isEmpty == false || audios.isEmpty == false || live2d.isEmpty == false
            guard hasMedia, isGalleryKey(key) || inGalleryContext else { continue }
            let title = key.isEmpty ? lastTitle.ifBlank(String(localized: "ba.student.detail.media.gallery")) : key
            let detail = notes.joined(separator: " / ")
            out.append(contentsOf: mediaItems(title: title, detail: detail, imageURLs: images, mediaURLs: images, kind: .image, memoryUnlockLevel: key.hasPrefix("回忆大厅") ? memoryUnlockLevel : nil))
            out.append(contentsOf: mediaItems(title: title, detail: detail, imageURLs: images, mediaURLs: videos, kind: .video, memoryUnlockLevel: key.hasPrefix("回忆大厅") ? memoryUnlockLevel : nil))
            out.append(contentsOf: mediaItems(title: title, detail: detail, imageURLs: images, mediaURLs: audios, kind: .audio))
            out.append(contentsOf: mediaItems(title: title, detail: detail, imageURLs: live2d, mediaURLs: live2d, kind: .live2d))
        }
        return out
    }

    private func parseStyleData(_ styleData: [BaJSONObject], sourceURL: URL?) -> [BaGuideGalleryItem] {
        styleData.enumerated().flatMap { index, block in
            let title = BaGuideTextNormalizer.clean(block.string("name") ?? "")
                .ifBlank(String(format: String(localized: "ba.student.detail.media.style.format"), index + 1))
            let data = block["data"]
            let images = BaGuideTextNormalizer.imageURLs(in: data, sourceURL: sourceURL)
            let videos = BaGuideTextNormalizer.videoURLs(in: data, sourceURL: sourceURL)
            return mediaItems(title: title, detail: "", imageURLs: images, mediaURLs: images, kind: .image) +
                mediaItems(title: title, detail: "", imageURLs: images, mediaURLs: videos, kind: .video)
        }
    }

    private func mediaItems(
        title: String,
        detail: String,
        imageURLs: [URL],
        mediaURLs: [URL],
        kind: BaGuideMediaKind,
        memoryUnlockLevel: String? = nil
    ) -> [BaGuideGalleryItem] {
        mediaURLs.enumerated().map { index, mediaURL in
            let imageURL = kind == .image ? mediaURL : imageURLs.first
            return BaGuideGalleryItem(
                id: "\(kind.rawValue)-\(index)-\(abs(mediaURL.absoluteString.hashValue))",
                title: mediaURLs.count > 1 ? "\(title) \(index + 1)" : title,
                detail: detail.ifBlank(kind.title),
                imageURL: imageURL,
                mediaURL: mediaURL,
                mediaKind: kind,
                memoryUnlockLevel: memoryUnlockLevel,
                note: detail.isEmpty ? nil : detail
            )
        }
    }

    private func dedupe(_ items: [BaGuideGalleryItem]) -> [BaGuideGalleryItem] {
        var seen = Set<String>()
        return items.filter { item in
            let key = item.mediaURL?.absoluteString ?? item.imageURL?.absoluteString ?? item.id
            return seen.insert(key).inserted
        }
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
        BaGuideTextNormalizer.containsAny(
            key,
            tokens: ["立绘", "本家画", "TV动画设定图", "回忆大厅视频", "回忆大厅", "PV", "Live", "巧克力图", "互动家具", "角色表情", "表情", "角色演示", "设定集", "官方介绍", "官方衍生", "情人节巧克力", "BGM"]
        )
    }

    private func isNonGalleryKey(_ key: String) -> Bool {
        BaGuideTextNormalizer.containsAny(
            key,
            tokens: ["技能", "专武", "爱用品", "能力解放", "礼物偏好", "初始数据", "顶级数据", "学生信息", "介绍", "配音"]
        )
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
