//
//  BaGuideGallerySupport.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaGuideGallerySupport {
    static func normalizeTitle(_ raw: String) -> String {
        raw.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeArrayTitle(_ raw: String) -> String {
        let title = BaGuideTextNormalizer.clean(raw)
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty == false else { return "影画" }
        if title == "表情包" || title.hasPrefix("表情包(") || title.hasPrefix("表情包（") {
            return title.replacingOccurrences(of: "表情包", with: "角色表情包")
        }
        if title == "差分" || title == "表情差分" {
            return "角色表情"
        }
        if title.hasPrefix("表情") {
            let suffix = String(title.dropFirst("表情".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return "角色表情\(suffix)"
        }
        if title.contains("表情差分") {
            return title.replacingOccurrences(of: "表情差分", with: "角色表情")
        }
        if title.contains("差分") {
            let context = title
                .replacingOccurrences(of: "差分", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "（）()-· "))
            return context.isEmpty ? "角色表情" : "角色表情（\(context)）"
        }
        return title
    }

    static func categoryOrder(_ title: String) -> Int {
        let normalized = normalizeTitle(title)
        if normalized.hasPrefix("立绘") { return 0 }
        if normalized.hasPrefix("回忆大厅"), normalized.hasPrefix("回忆大厅视频") == false { return 1 }
        if normalized.hasPrefix("回忆大厅视频") { return 2 }
        if normalized.hasPrefix("BGM") { return 3 }
        if normalized.hasPrefix("官方介绍") { return 4 }
        if normalized.hasPrefix("本家画") { return 5 }
        if normalized.hasPrefix("官方衍生") { return 6 }
        if normalized.hasPrefix("TV动画设定图") { return 7 }
        if normalized.hasPrefix("设定集") { return 8 }
        if isExpressionTitle(normalized) { return 9 }
        if normalized.hasPrefix("互动家具") { return 10 }
        if normalized.hasPrefix("情人节巧克力") { return 11 }
        if normalized.hasPrefix("巧克力图") { return 12 }
        if normalized.hasPrefix("PV") { return 13 }
        if normalized.hasPrefix("角色演示") { return 14 }
        if normalized.hasPrefix("Live") { return 15 }
        return 99
    }

    static func titleGroupKey(_ title: String) -> String {
        normalizeTitle(title).replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
    }

    static func itemIndex(_ title: String) -> Int {
        guard let range = normalizeTitle(title).range(of: #"(\d+)(?!.*\d)"#, options: .regularExpression) else {
            return Int.max
        }
        return Int(normalizeTitle(title)[range]) ?? Int.max
    }

    static func expressionOrder(title: String, fallback: Int) -> Int {
        let normalized = normalizeTitle(title)
        if normalized == "角色表情" || normalized == "表情" || normalized == "差分" {
            return 1
        }
        return itemIndex(title) == Int.max ? fallback : itemIndex(title)
    }

    static func isRenderable(_ item: BaGuideGalleryItem) -> Bool {
        let imageRenderable = item.imageURL.map(isRenderableImageURL) ?? false
        let mediaRenderable: Bool
        switch item.mediaKind ?? .image {
        case .video:
            mediaRenderable = item.mediaURL.map(isRenderableVideoURL) ?? false
        case .audio:
            mediaRenderable = item.mediaURL.map(isRenderableAudioURL) ?? false
        case .image, .live2d, .unknown:
            mediaRenderable = item.mediaURL.map(isRenderableImageURL) ?? false
        }
        return imageRenderable || mediaRenderable
    }

    static func isRenderableImageURL(_ url: URL) -> Bool {
        BaGuideTextNormalizer.looksLikeImageURL(url)
    }

    static func isRenderableVideoURL(_ url: URL) -> Bool {
        BaGuideTextNormalizer.looksLikeVideoURL(url)
    }

    static func isRenderableAudioURL(_ url: URL) -> Bool {
        BaGuideTextNormalizer.looksLikeAudioURL(url)
    }

    static func isGIFURL(_ url: URL) -> Bool {
        let lower = url.absoluteString.lowercased()
        return lower.range(of: #"\.gif(\?.*)?(#.*)?$"#, options: .regularExpression) != nil ||
            lower.contains("format=gif") ||
            lower.contains("image/gif")
    }

    static func isMemoryHallFile(_ item: BaGuideGalleryItem) -> Bool {
        normalizeTitle(item.title).hasPrefix("回忆大厅文件")
    }

    static func isExpression(_ item: BaGuideGalleryItem) -> Bool {
        isExpressionTitle(item.title)
    }

    static func isExpressionTitleForLayout(_ raw: String) -> Bool {
        isExpressionTitle(raw)
    }

    static func isMemoryHall(_ item: BaGuideGalleryItem) -> Bool {
        let title = normalizeTitle(item.title)
        return title.hasPrefix("回忆大厅") &&
            title.hasPrefix("回忆大厅视频") == false &&
            title.hasPrefix("回忆大厅文件") == false
    }

    static func isOfficialIntro(_ item: BaGuideGalleryItem) -> Bool {
        normalizeTitle(item.title).hasPrefix("官方介绍")
    }

    static func isChocolate(_ item: BaGuideGalleryItem) -> Bool {
        let title = normalizeTitle(item.title)
        return title.hasPrefix("巧克力图") || title.hasPrefix("情人节巧克力")
    }

    static func isInteractiveFurniture(_ item: BaGuideGalleryItem) -> Bool {
        normalizeTitle(item.title).hasPrefix("互动家具")
    }

    static func isPreviewVideoCategoryTitle(_ raw: String) -> Bool {
        let title = normalizeTitle(raw)
        return title.hasPrefix("回忆大厅视频") || title.hasPrefix("PV") || title.hasPrefix("角色演示")
    }

    static func isPreviewVideo(_ item: BaGuideGalleryItem) -> Bool {
        (item.mediaKind ?? .unknown) == .video && isPreviewVideoCategoryTitle(item.title)
    }

    private static func isExpressionTitle(_ raw: String) -> Bool {
        let title = normalizeTitle(raw)
        if title.hasPrefix("角色表情") { return true }
        if title.hasPrefix("表情") { return true }
        if title == "差分" { return true }
        if title.contains("表情差分") { return true }
        return title.contains("差分")
    }
}
