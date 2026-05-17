//
//  BaCards.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import ImageIO
import SwiftUI
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

enum BaIconToken {
    static let symbolTile: CGFloat = 42
    static let rowThumbnail: CGFloat = 58
    static let detailImageHeight: CGFloat = 220
}

enum BaTextToken {
    static let rowTitle = Font.body.weight(.semibold)
    static let rowSubtitle = Font.subheadline
    static let rowCaption = Font.caption
}

private struct BaShowPreviewImagesKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var baShowPreviewImages: Bool {
        get { self[BaShowPreviewImagesKey.self] }
        set { self[BaShowPreviewImagesKey.self] = newValue }
    }
}

struct BaScreenScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        BaAdaptiveGeometry { metrics in
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                    content
                }
                .baAdaptiveReadableContent(maxWidth: metrics.dashboardContentMaxWidth)
                .padding(.horizontal, metrics.screenHorizontalPadding)
                .padding(.vertical, metrics.screenVerticalPadding)
                .safeAreaPadding(.bottom, 16)
            }
            .background(AppBackground())
        }
    }
}

struct BaGlassCard<Content: View>: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    var tint: Color = .secondary
    let content: Content

    init(tint: Color = .secondary, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(metrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(cornerRadius: 24, tint: tint.opacity(0.045), isInteractive: false)
    }
}

struct BaSectionHeader: View {
    let title: String
    var systemImage: String?
    var asset: BaGameAsset?

    var body: some View {
        HStack(spacing: 8) {
            if let asset {
                BaGameAssetIcon(asset, size: 21)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

struct BaSymbolTile: View {
    let systemImage: String
    var tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: BaIconToken.symbolTile, height: BaIconToken.symbolTile)
            .liquidGlassSurface(cornerRadius: 14, tint: tint.opacity(0.08), isInteractive: false)
    }
}

struct BaStatusBadge: View {
    let title: String
    var tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .liquidGlassSurface(cornerRadius: 999, tint: tint.opacity(0.08), isInteractive: false)
    }
}

struct BaSummaryMetric: View {
    let title: String
    let value: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BaMetricGroup<Content: View>: View {
    let title: String
    var systemImage: String?
    var asset: BaGameAsset?
    let content: Content

    init(
        title: String,
        systemImage: String? = nil,
        asset: BaGameAsset? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.asset = asset
        self.content = content()
    }

    var body: some View {
        BaGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                BaSectionHeader(title: title, systemImage: systemImage, asset: asset)
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct BaMetricRow: View {
    let title: String
    let value: String
    var detail: String?
    var systemImage: String?
    var asset: BaGameAsset?
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            if let asset {
                BaGameAssetIcon(asset, size: 25)
                    .frame(width: 24)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            Text(value)
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(.vertical, 10)
    }
}

struct BaTimelineDatePair: View {
    let start: String
    let end: String
    let detail: String
    var tint: Color
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                timelineColumn(
                    title: BaL10n.string("ba.timeline.start"),
                    value: start,
                    systemImage: "calendar.badge.clock",
                    tint: .secondary
                )
                timelineColumn(
                    title: BaL10n.string("ba.timeline.end"),
                    value: end,
                    systemImage: "calendar.badge.checkmark",
                    tint: tint
                )
            }
            if let progress {
                ProgressView(value: progress)
                    .tint(tint)
                    .controlSize(.small)
            }
            if detail.isEmpty == false {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func timelineColumn(title: String, value: String, systemImage: String, tint: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BaTimelineStatusPill: View {
    let title: String
    var tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

extension View {
    func baTimelineScrollCardSurface(tint: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        return background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.fill(tint.opacity(0.045))
            }
            .overlay {
                shape.strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

extension Date {
    var baTimelineDisplayDate: Date {
        Date(timeIntervalSince1970: floor(timeIntervalSince1970 / 60) * 60)
    }
}

struct BaValueChip: View {
    let value: String
    var tint: Color

    var body: some View {
        Text(value)
            .font(.body.monospacedDigit().weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .liquidGlassSurface(cornerRadius: 999, tint: tint.opacity(0.09), isInteractive: false)
    }
}

struct BaDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 36)
    }
}

struct BaRemoteImageSurface: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baShowPreviewImages) private var showPreviewImages

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat
    var contentMode: ContentMode = .fill
    var usesImageBackdrop = false
    var fallbackFont: Font = .title3.weight(.semibold)
    var maxPixelDimension = 900
    var usesGlassSurface = true

    @State private var phase: BaRemoteImagePhase = .placeholder

    var body: some View {
        ZStack {
            if case let .success(image) = phase {
                if usesImageBackdrop {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(1.08)
                        .blur(radius: 10)
                        .saturation(1.05)
                        .opacity(0.42)
                }
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .baRemoteImageSurfaceChrome(
            cornerRadius: cornerRadius,
            tint: tint,
            usesGlassSurface: usesGlassSurface
        )
        .task(id: cacheTaskID) {
            await loadImage()
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(showPreviewImages)-\(maxPixelDimension)"
    }

    private func loadImage() async {
        guard showPreviewImages, let url else {
            phase = showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        do {
            let data = try await model.imageData(for: url)
            guard Task.isCancelled == false else { return }
            guard let loaded = await BaStillImageDecodeWorker.decode(data: data, maxPixelDimension: maxPixelDimension) else {
                if Task.isCancelled == false {
                    phase = .failed
                }
                return
            }
            guard Task.isCancelled == false else { return }
            phase = .success(loaded)
        } catch {
            if Task.isCancelled == false {
                phase = .failed
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        switch phase {
        case .loading:
            ZStack {
                fallbackIcon(systemImage: fallbackSystemImage, tint: tint.opacity(0.55))
                ProgressView()
                    .controlSize(.small)
            }
        case .failed:
            fallbackIcon(systemImage: "photo.badge.exclamationmark", tint: .secondary)
        case .hidden:
            fallbackIcon(systemImage: fallbackSystemImage, tint: .secondary)
        case .placeholder, .success:
            fallbackIcon(systemImage: fallbackSystemImage, tint: tint)
        }
    }

    private func fallbackIcon(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(fallbackFont)
            .foregroundStyle(tint)
    }

    nonisolated static func image(from data: Data, maxPixelDimension: Int = 900) -> Image? {
        #if canImport(UIKit)
            guard let uiImage = BaStillImageDecoder.uiImage(from: data, maxPixelDimension: maxPixelDimension) else { return nil }
            return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
            guard let nsImage = BaStillImageDecoder.nsImage(from: data, maxPixelDimension: maxPixelDimension) else { return nil }
            return Image(nsImage: nsImage)
        #else
            return nil
        #endif
    }
}

struct BaRemoteIconSurface: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baShowPreviewImages) private var showPreviewImages

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var size: CGFloat
    var width: CGFloat? = nil
    var fallbackFont: Font = .caption.weight(.semibold)
    var maxPixelDimension = 256

    @State private var phase: BaRemoteIconPhase = .placeholder

    var body: some View {
        ZStack {
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
            case .loading:
                ZStack {
                    fallbackIcon(systemImage: fallbackSystemImage, tint: tint.opacity(0.55))
                    ProgressView()
                        .controlSize(.small)
                }
            case .failed:
                fallbackIcon(systemImage: "photo.badge.exclamationmark", tint: .secondary)
            case .hidden:
                fallbackIcon(systemImage: fallbackSystemImage, tint: .secondary)
            case .placeholder:
                fallbackIcon(systemImage: fallbackSystemImage, tint: tint)
            }
        }
        .frame(width: width ?? size, height: size)
        .task(id: cacheTaskID) {
            await loadImage()
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(showPreviewImages)-\(maxPixelDimension)"
    }

    private func loadImage() async {
        guard showPreviewImages, let url else {
            phase = showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        do {
            let data = try await model.imageData(for: url)
            guard Task.isCancelled == false else { return }
            guard let loaded = await BaStillImageDecodeWorker.decode(data: data, maxPixelDimension: maxPixelDimension) else {
                if Task.isCancelled == false {
                    phase = .failed
                }
                return
            }
            guard Task.isCancelled == false else { return }
            phase = .success(loaded)
        } catch {
            if Task.isCancelled == false {
                phase = .failed
            }
        }
    }

    private func fallbackIcon(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(fallbackFont)
            .foregroundStyle(tint)
    }
}

struct BaRowThumbnail: View {
    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var size: CGFloat = BaIconToken.rowThumbnail
    var maxPixelDimension = 900
    var usesGlassSurface = true

    var body: some View {
        BaRemoteImageSurface(
            url: url,
            fallbackSystemImage: fallbackSystemImage,
            tint: tint,
            width: size,
            height: size,
            cornerRadius: 16,
            maxPixelDimension: maxPixelDimension,
            usesGlassSurface: usesGlassSurface
        )
    }
}

struct BaDetailRemoteImage: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color

    var body: some View {
        BaRemoteImageSurface(
            url: url,
            fallbackSystemImage: fallbackSystemImage,
            tint: tint,
            width: nil,
            height: BaIconToken.detailImageHeight,
            cornerRadius: 24,
            fallbackFont: .system(size: 52, weight: .semibold),
            maxPixelDimension: metrics.detailImageMaxPixelDimension
        )
    }
}

private enum BaRemoteImagePhase {
    case placeholder
    case hidden
    case loading
    case failed
    case success(Image)
}

private enum BaRemoteIconPhase {
    case placeholder
    case hidden
    case loading
    case failed
    case success(Image)
}

private enum BaStillImageDecodeWorker {
    nonisolated static func decode(data: Data, maxPixelDimension: Int) async -> Image? {
        await Task.detached(priority: .utility) {
            BaRemoteImageSurface.image(from: data, maxPixelDimension: max(maxPixelDimension, 1))
        }.value
    }
}

private enum BaStillImageDecoder {
    #if canImport(UIKit)
        nonisolated static func uiImage(from data: Data, maxPixelDimension: Int) -> UIImage? {
            guard let cgImage = thumbnailImage(from: data, maxPixelDimension: maxPixelDimension) else {
                return UIImage(data: data)
            }
            return UIImage(cgImage: cgImage)
        }
    #elseif canImport(AppKit)
        nonisolated static func nsImage(from data: Data, maxPixelDimension: Int) -> NSImage? {
            guard let cgImage = thumbnailImage(from: data, maxPixelDimension: maxPixelDimension) else {
                return NSImage(data: data)
            }
            return NSImage(cgImage: cgImage, size: .zero)
        }
    #endif

    nonisolated private static func thumbnailImage(from data: Data, maxPixelDimension: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

private extension View {
    @ViewBuilder
    func baRemoteImageSurfaceChrome(cornerRadius: CGFloat, tint: Color, usesGlassSurface: Bool) -> some View {
        if usesGlassSurface {
            liquidGlassSurface(cornerRadius: cornerRadius, tint: tint.opacity(0.08), isInteractive: false)
        } else {
            background(.clear)
        }
    }
}
