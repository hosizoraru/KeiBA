//
//  BaStudentGalleryMediaLayout.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation
import SwiftUI

enum BaStudentGalleryLayoutContext {
    case compact
    case regular
    case desktop
    case preview
}

struct BaStudentGalleryMediaLayout: Hashable {
    let aspectRatio: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    let maxPixelDimension: Int
    let maxContentWidth: CGFloat
    private let constraints: BaStudentGalleryMediaLayoutConstraints

    init(item: BaGuideGalleryItem) {
        let kind = item.mediaKind ?? .image
        let title = BaGuideGallerySupport.normalizeTitle(item.title)
        let url = kind == .video ? item.mediaURL : (item.imageURL ?? item.mediaURL)
        let ratio = url?.baGalleryPixelSize?.aspectRatio ?? Self.fallbackAspectRatio(kind: kind, title: title)
        let constraints = Self.constraints(kind: kind, title: title, aspectRatio: ratio)
        aspectRatio = ratio
        self.constraints = constraints
        height = Self.resolvedHeight(
            aspectRatio: ratio,
            constraints: constraints,
            context: .compact
        )
        cornerRadius = constraints.cornerRadius
        contentPadding = constraints.contentPadding
        maxPixelDimension = constraints.maxPixelDimension
        maxContentWidth = constraints.maxContentWidth
    }

    func resolved(for context: BaStudentGalleryLayoutContext) -> BaStudentGalleryResolvedMediaLayout {
        BaStudentGalleryResolvedMediaLayout(
            height: Self.resolvedHeight(
                aspectRatio: aspectRatio,
                constraints: constraints,
                context: context
            ),
            cornerRadius: cornerRadius,
            contentPadding: contentPadding,
            maxPixelDimension: maxPixelDimension,
            maxContentWidth: constraints.maxContentWidth
        )
    }

    private static func referenceContentWidth(for context: BaStudentGalleryLayoutContext, maxContentWidth: CGFloat) -> CGFloat {
        let width: CGFloat
        switch context {
        case .compact:
            width = 356
        case .regular:
            width = 520
        case .desktop:
            width = 600
        case .preview:
            width = 720
        }
        return min(width, maxContentWidth)
    }

    private static func resolvedHeight(
        aspectRatio: CGFloat,
        constraints: BaStudentGalleryMediaLayoutConstraints,
        context: BaStudentGalleryLayoutContext
    ) -> CGFloat {
        let referenceWidth = referenceContentWidth(for: context, maxContentWidth: constraints.maxContentWidth)
        let naturalHeight = referenceWidth / max(aspectRatio, 0.38)
        let maxHeight = constraints.maxHeight * context.heightScale
        let minHeight = min(constraints.minHeight * context.minHeightScale, maxHeight)
        return min(max(naturalHeight, minHeight), maxHeight)
    }

    private static func fallbackAspectRatio(kind: BaGuideMediaKind, title: String) -> CGFloat {
        switch kind {
        case .video:
            return 16 / 9
        case .audio:
            return 1
        case .live2d:
            return 0.82
        case .image, .unknown:
            if title.hasPrefix("回忆大厅") { return 1210 / 888 }
            if title.hasPrefix("官方衍生") || title.hasPrefix("PV") { return 16 / 9 }
            // The title argument is already the result of normalizeTitle();
            // reuse the normalized fast path so we don't strip whitespace twice.
            if BaGuideGallerySupport.isExpressionForNormalizedTitle(title) { return 1 }
            if title.hasPrefix("立绘") || title.hasPrefix("官方介绍") { return 0.75 }
            return 1.18
        }
    }

    private static func constraints(
        kind: BaGuideMediaKind,
        title: String,
        aspectRatio: CGFloat
    ) -> BaStudentGalleryMediaLayoutConstraints {
        if kind == .video {
            return .init(minHeight: 196, maxHeight: 214, cornerRadius: 18, contentPadding: 0, maxPixelDimension: 900, maxContentWidth: 620)
        }
        if kind == .live2d {
            return .init(minHeight: 310, maxHeight: 430, cornerRadius: 20, contentPadding: 8, maxPixelDimension: 1300, maxContentWidth: 620)
        }
        if BaGuideGallerySupport.isExpressionForNormalizedTitle(title) {
            return .init(minHeight: 220, maxHeight: 252, cornerRadius: 18, contentPadding: 8, maxPixelDimension: 900, maxContentWidth: 360)
        }
        if title.hasPrefix("立绘") {
            return .init(minHeight: 360, maxHeight: 430, cornerRadius: 20, contentPadding: 8, maxPixelDimension: 1400, maxContentWidth: 520)
        }
        if title.hasPrefix("官方介绍") {
            return .init(minHeight: 330, maxHeight: 406, cornerRadius: 20, contentPadding: 6, maxPixelDimension: 1400, maxContentWidth: 520)
        }
        if title.hasPrefix("回忆大厅") {
            return .init(minHeight: 238, maxHeight: 278, cornerRadius: 20, contentPadding: 0, maxPixelDimension: 1400, maxContentWidth: 640)
        }
        if aspectRatio >= 1.55 {
            return .init(minHeight: 190, maxHeight: 226, cornerRadius: 18, contentPadding: 0, maxPixelDimension: 1200, maxContentWidth: 620)
        }
        if aspectRatio >= 1.18 {
            return .init(minHeight: 230, maxHeight: 282, cornerRadius: 18, contentPadding: 0, maxPixelDimension: 1300, maxContentWidth: 620)
        }
        if aspectRatio >= 0.92 {
            return .init(minHeight: 260, maxHeight: 328, cornerRadius: 18, contentPadding: 4, maxPixelDimension: 1200, maxContentWidth: 520)
        }
        return .init(minHeight: 330, maxHeight: 392, cornerRadius: 20, contentPadding: 6, maxPixelDimension: 1400, maxContentWidth: 520)
    }
}

struct BaStudentGalleryResolvedMediaLayout: Hashable {
    let height: CGFloat
    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    let maxPixelDimension: Int
    let maxContentWidth: CGFloat
}

struct BaGalleryMediaPixelSize: Hashable {
    let width: Int
    let height: Int

    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }
}

private struct BaStudentGalleryMediaLayoutConstraints: Hashable {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    let maxPixelDimension: Int
    let maxContentWidth: CGFloat
}

private extension BaStudentGalleryLayoutContext {
    var heightScale: CGFloat {
        switch self {
        case .compact:
            1
        case .regular:
            1.18
        case .desktop:
            1.24
        case .preview:
            1.35
        }
    }

    var minHeightScale: CGFloat {
        switch self {
        case .compact:
            1
        case .regular, .desktop:
            1.04
        case .preview:
            1.10
        }
    }
}

private enum BaGalleryURLPatterns {
    // Hit on every body recompose for visible gallery cells; cache once.
    nonisolated(unsafe) static let dimensionsRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"/w_(\d+)/h_(\d+)/"#)
    }()
}

extension URL {
    var baGalleryPixelSize: BaGalleryMediaPixelSize? {
        // The cached regex is built from a static literal that always
        // succeeds; the previous .regularExpression fallback would have
        // recompiled the same pattern per call when the cache happened
        // to be missing. Bail early instead so we never pay that cost.
        guard let regex = BaGalleryURLPatterns.dimensionsRegex else { return nil }
        let absoluteString = absoluteString
        let range = NSRange(absoluteString.startIndex ..< absoluteString.endIndex, in: absoluteString)
        guard let match = regex.firstMatch(in: absoluteString, range: range),
              let matchedRange = Range(match.range, in: absoluteString)
        else {
            return nil
        }
        let matched = absoluteString[matchedRange]
        var width = 0
        var height = 0
        for part in matched.split(separator: "/") {
            if part.hasPrefix("w_") {
                width = Int(part.dropFirst(2)) ?? 0
            } else if part.hasPrefix("h_") {
                height = Int(part.dropFirst(2)) ?? 0
            }
        }
        guard width > 0, height > 0 else { return nil }
        return BaGalleryMediaPixelSize(width: width, height: height)
    }
}
