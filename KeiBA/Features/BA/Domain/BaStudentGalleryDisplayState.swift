//
//  BaStudentGalleryDisplayState.swift
//  KeiBA
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated struct BaStudentGalleryVideoGroup: Identifiable, Hashable {
    let title: String
    let items: [BaGuideGalleryItem]

    var id: String {
        "\(title)|\(items.map(\.id).joined(separator: ","))"
    }
}

nonisolated enum BaStudentGalleryDisplayRow: Identifiable, Hashable {
    case item(BaGuideGalleryItem)
    case expression([BaGuideGalleryItem])
    case videoGroup(BaStudentGalleryVideoGroup)
    case memoryUnlock(String)
    case relatedLinks([BaGuideRow])

    var id: String {
        switch self {
        case let .item(item):
            "item-\(item.id)"
        case let .expression(items):
            "expression-\(items.map(\.id).joined(separator: ","))"
        case let .videoGroup(group):
            "video-\(group.id)"
        case let .memoryUnlock(level):
            "memory-unlock-\(level)"
        case let .relatedLinks(rows):
            "related-\(rows.map(\.id).joined(separator: ","))"
        }
    }
}

nonisolated struct BaStudentGalleryDisplayState: Hashable {
    let previewVideoGroups: [BaStudentGalleryVideoGroup]
    let memoryHallVideoGroup: BaStudentGalleryVideoGroup?
    let pvAndRoleVideoGroups: [BaStudentGalleryVideoGroup]
    let otherTrailingVideoGroups: [BaStudentGalleryVideoGroup]
    let displayGalleryItems: [BaGuideGalleryItem]
    let expressionItems: [BaGuideGalleryItem]
    let galleryRelatedLinkRows: [BaGuideRow]
    let memoryHallPreview: URL?
    let memoryUnlockLevel: String
    let firstExpressionIndex: Int?
    let firstMemoryHallIndex: Int?
    let lastOfficialIntroIndex: Int?
    let rows: [BaStudentGalleryDisplayRow]

    var hasRenderableContent: Bool {
        rows.isEmpty == false
    }

    init(info: BaStudentGuideInfo?) {
        guard let info else {
            previewVideoGroups = []
            memoryHallVideoGroup = nil
            pvAndRoleVideoGroups = []
            otherTrailingVideoGroups = []
            displayGalleryItems = []
            expressionItems = []
            galleryRelatedLinkRows = []
            memoryHallPreview = nil
            memoryUnlockLevel = ""
            firstExpressionIndex = nil
            firstMemoryHallIndex = nil
            lastOfficialIntroIndex = nil
            rows = []
            return
        }

        let sourceItems = Self.sourceGalleryItems(from: info)
        let cleanedItems = sourceItems.filter { BaGuideGallerySupport.isMemoryHallFile($0) == false }
        let memoryPreview = cleanedItems.first {
            BaGuideGallerySupport.isMemoryHall($0) &&
                $0.imageURL.map(BaGuideGallerySupport.isRenderableImageURL) == true
        }?.imageURL

        let videoGroups = Self.videoGroups(from: cleanedItems, memoryHallPreview: memoryPreview)
        previewVideoGroups = videoGroups
        memoryHallVideoGroup = videoGroups.first { $0.title == "回忆大厅视频" }
        pvAndRoleVideoGroups = videoGroups.filter { $0.title == "PV" || $0.title == "角色演示" }
        otherTrailingVideoGroups = videoGroups.filter { $0.title != "回忆大厅视频" && $0.title != "PV" && $0.title != "角色演示" }

        let displayItems = cleanedItems.filter { item in
            BaGuideGallerySupport.isPreviewVideo(item) == false &&
                BaGuideGallerySupport.isChocolate(item) == false &&
                BaGuideGallerySupport.isInteractiveFurniture(item) == false &&
                Self.canRenderInGallery(item)
        }
        displayGalleryItems = displayItems
        expressionItems = displayItems
            .enumerated()
            .filter { BaGuideGallerySupport.isExpression($0.element) }
            .sorted {
                BaGuideGallerySupport.expressionOrder(title: $0.element.title, fallback: $0.offset + 1) <
                    BaGuideGallerySupport.expressionOrder(title: $1.element.title, fallback: $1.offset + 1)
            }
            .map(\.element)
        galleryRelatedLinkRows = Self.galleryRelatedRows(from: info)
        memoryHallPreview = memoryPreview
        memoryUnlockLevel = Self.memoryUnlockLevel(from: cleanedItems, info: info)
        firstExpressionIndex = displayItems.firstIndex(where: BaGuideGallerySupport.isExpression)
        firstMemoryHallIndex = displayItems.firstIndex(where: BaGuideGallerySupport.isMemoryHall)
        lastOfficialIntroIndex = displayItems.lastIndex(where: BaGuideGallerySupport.isOfficialIntro)
        rows = Self.rows(
            displayItems: displayItems,
            expressionItems: expressionItems,
            memoryHallVideoGroup: memoryHallVideoGroup,
            pvAndRoleVideoGroups: pvAndRoleVideoGroups,
            otherTrailingVideoGroups: otherTrailingVideoGroups,
            relatedRows: galleryRelatedLinkRows,
            memoryUnlockLevel: memoryUnlockLevel,
            firstExpressionIndex: firstExpressionIndex,
            firstMemoryHallIndex: firstMemoryHallIndex,
            lastOfficialIntroIndex: lastOfficialIntroIndex
        )
    }

    private static func rows(
        displayItems: [BaGuideGalleryItem],
        expressionItems: [BaGuideGalleryItem],
        memoryHallVideoGroup: BaStudentGalleryVideoGroup?,
        pvAndRoleVideoGroups: [BaStudentGalleryVideoGroup],
        otherTrailingVideoGroups: [BaStudentGalleryVideoGroup],
        relatedRows: [BaGuideRow],
        memoryUnlockLevel: String,
        firstExpressionIndex: Int?,
        firstMemoryHallIndex: Int?,
        lastOfficialIntroIndex: Int?
    ) -> [BaStudentGalleryDisplayRow] {
        var out: [BaStudentGalleryDisplayRow] = []
        var insertedUnlockLevel = false
        var insertedMemoryHallVideo = false
        var insertedPvAndRoleVideos = false
        var insertedRelatedLinks = false

        for (index, item) in displayItems.enumerated() {
            let isExpression = BaGuideGallerySupport.isExpression(item)
            if isExpression, index != firstExpressionIndex {
                continue
            }

            if insertedUnlockLevel == false,
               memoryUnlockLevel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
               index == firstMemoryHallIndex
            {
                out.append(.memoryUnlock(memoryUnlockLevel))
                insertedUnlockLevel = true
            }

            if isExpression, expressionItems.isEmpty == false {
                out.append(.expression(expressionItems))
            } else {
                out.append(.item(item))
            }

            if insertedMemoryHallVideo == false,
               index == firstMemoryHallIndex,
               let memoryHallVideoGroup
            {
                out.append(.videoGroup(memoryHallVideoGroup))
                insertedMemoryHallVideo = true
            }

            if insertedPvAndRoleVideos == false, index == lastOfficialIntroIndex {
                out.append(contentsOf: pvAndRoleVideoGroups.map(BaStudentGalleryDisplayRow.videoGroup))
                insertedPvAndRoleVideos = true
                if insertedRelatedLinks == false, relatedRows.isEmpty == false {
                    out.append(.relatedLinks(relatedRows))
                    insertedRelatedLinks = true
                }
            }
        }

        if insertedUnlockLevel == false,
           memoryUnlockLevel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
           memoryHallVideoGroup != nil
        {
            out.append(.memoryUnlock(memoryUnlockLevel))
        }

        if insertedMemoryHallVideo == false, let memoryHallVideoGroup {
            out.append(.videoGroup(memoryHallVideoGroup))
        }

        if insertedPvAndRoleVideos == false {
            out.append(contentsOf: pvAndRoleVideoGroups.map(BaStudentGalleryDisplayRow.videoGroup))
            if insertedRelatedLinks == false, relatedRows.isEmpty == false {
                out.append(.relatedLinks(relatedRows))
                insertedRelatedLinks = true
            }
        }

        out.append(contentsOf: otherTrailingVideoGroups.map(BaStudentGalleryDisplayRow.videoGroup))

        if insertedRelatedLinks == false, relatedRows.isEmpty == false {
            out.append(.relatedLinks(relatedRows))
        }

        return out
    }

    private static func sourceGalleryItems(from info: BaStudentGuideInfo) -> [BaGuideGalleryItem] {
        let parsed = BaGuideMediaParser.sortedDistinct(info.galleryItems)
        if parsed.isEmpty == false {
            return parsed
        }
        guard let imageURL = info.imageURL, BaGuideGallerySupport.isRenderableImageURL(imageURL) else {
            return []
        }
        return [
            BaGuideGalleryItem(
                id: "fallback-portrait-\(abs(imageURL.absoluteString.hashValue))",
                title: "立绘",
                detail: BaGuideMediaKind.image.title,
                imageURL: imageURL,
                mediaURL: imageURL,
                mediaKind: .image
            ),
        ]
    }

    private static func videoGroups(from items: [BaGuideGalleryItem], memoryHallPreview: URL?) -> [BaStudentGalleryVideoGroup] {
        let categoryOrder = ["回忆大厅视频", "PV", "角色演示"]
        let categories = items.compactMap { item -> String? in
            guard BaGuideGallerySupport.isPreviewVideo(item) else { return nil }
            let title = BaGuideGallerySupport.normalizeTitle(item.title)
            if title.hasPrefix("回忆大厅视频") { return "回忆大厅视频" }
            if title.hasPrefix("PV") { return "PV" }
            if title.hasPrefix("角色演示") { return "角色演示" }
            return nil
        }
        .reduce(into: [String]()) { out, category in
            if out.contains(category) == false {
                out.append(category)
            }
        }
        .sorted {
            (categoryOrder.firstIndex(of: $0) ?? Int.max) < (categoryOrder.firstIndex(of: $1) ?? Int.max)
        }

        return categories.compactMap { category in
            let groupItems = items.compactMap { item -> BaGuideGalleryItem? in
                guard BaGuideGallerySupport.isPreviewVideo(item), item.mediaURL.map(BaGuideGallerySupport.isRenderableVideoURL) == true else {
                    return nil
                }
                let title = BaGuideGallerySupport.normalizeTitle(item.title)
                let belongs: Bool
                switch category {
                case "回忆大厅视频":
                    belongs = title.hasPrefix("回忆大厅视频")
                case "PV":
                    belongs = title.hasPrefix("PV")
                case "角色演示":
                    belongs = title.hasPrefix("角色演示")
                default:
                    belongs = false
                }
                guard belongs else { return nil }
                if item.imageURL == nil, category == "回忆大厅视频", let memoryHallPreview {
                    return BaGuideGalleryItem(
                        id: item.id,
                        title: item.title,
                        detail: item.detail,
                        imageURL: memoryHallPreview,
                        mediaURL: item.mediaURL,
                        mediaKind: item.mediaKind,
                        memoryUnlockLevel: item.memoryUnlockLevel,
                        note: item.note
                    )
                }
                return item
            }
            return groupItems.isEmpty ? nil : BaStudentGalleryVideoGroup(title: category, items: groupItems)
        }
    }

    private static func canRenderInGallery(_ item: BaGuideGalleryItem) -> Bool {
        switch item.mediaKind ?? .image {
        case .audio:
            return item.mediaURL.map(BaGuideGallerySupport.isRenderableAudioURL) == true
        case .video:
            return item.mediaURL.map(BaGuideGallerySupport.isRenderableVideoURL) == true
        case .image, .live2d, .unknown:
            return item.imageURL.map(BaGuideGallerySupport.isRenderableImageURL) == true ||
                item.mediaURL.map(BaGuideGallerySupport.isRenderableImageURL) == true
        }
    }

    private static func galleryRelatedRows(from info: BaStudentGuideInfo) -> [BaGuideRow] {
        let tokens = ["影画相关链接", "相关链接", "来源链接", "个人账号主页", "账号主页", "个人主页", "主页链接", "主页"]
        var seen = Set<String>()
        return info.profileDisplayRows
            .filter { row in
                tokens.contains { row.title.localizedCaseInsensitiveContains($0) } &&
                    webURLs(in: row.value).isEmpty == false
            }
            .filter { row in
                let key = "\(row.title.trimmingCharacters(in: .whitespacesAndNewlines))|\(row.value.trimmingCharacters(in: .whitespacesAndNewlines))"
                return seen.insert(key).inserted
            }
            .prefix(10)
            .map { $0 }
    }

    private static func memoryUnlockLevel(from items: [BaGuideGalleryItem], info: BaStudentGuideInfo) -> String {
        if let level = items.compactMap(\.memoryUnlockLevel).first(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }) {
            return level
        }
        let fallback = info.profileRows.first { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == "回忆大厅解锁等级" }?.value ?? ""
        if let range = fallback.range(of: #"\d+"#, options: .regularExpression) {
            return String(fallback[range])
        }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func webURLs(in raw: String) -> [URL] {
        guard let regex = try? NSRegularExpression(pattern: #"(?i)((?:https?://|www\.)[^\s<>"'，。；;）)】]+)"#) else {
            return []
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        var seen = Set<String>()
        return regex.matches(in: raw, range: range).compactMap { match -> URL? in
            guard let rawRange = Range(match.range(at: 1), in: raw) else { return nil }
            let value = String(raw[rawRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: "。，,;；）)】]》> "))
            let normalized = value.hasPrefix("www.") ? "https://\(value)" : value
            guard let url = URL(string: normalized), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                return nil
            }
            return seen.insert(url.absoluteString).inserted ? url : nil
        }
    }
}
