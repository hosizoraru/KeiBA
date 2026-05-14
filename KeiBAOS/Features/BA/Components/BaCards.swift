//
//  BaCards.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

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

struct BaScreenScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .safeAreaPadding(.bottom, 16)
        }
        .background(AppBackground())
    }
}

struct BaScreenHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BaGlassCard<Content: View>: View {
    var tint: Color = .secondary
    let content: Content

    init(tint: Color = .secondary, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(cornerRadius: 24, tint: tint.opacity(0.045), isInteractive: false)
    }
}

struct BaSectionHeader: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
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
    let content: Content

    init(
        title: String,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        BaGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                BaSectionHeader(title: title, systemImage: systemImage)
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
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            if let systemImage {
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
                    title: String(localized: "ba.timeline.start"),
                    value: start,
                    systemImage: "calendar.badge.clock",
                    tint: .secondary
                )
                timelineColumn(
                    title: String(localized: "ba.timeline.end"),
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

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat
    var contentMode: ContentMode = .fill
    var fallbackFont: Font = .title3.weight(.semibold)

    @State private var phase: BaRemoteImagePhase = .placeholder

    var body: some View {
        ZStack {
            if case let .success(image) = phase {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .liquidGlassSurface(cornerRadius: cornerRadius, tint: tint.opacity(0.08), isInteractive: false)
        .task(id: cacheTaskID) {
            await loadImage()
        }
        .onChange(of: model.settings.showPreviewImages) { _, _ in
            Task { await loadImage() }
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(model.settings.showPreviewImages)"
    }

    private func loadImage() async {
        guard model.settings.showPreviewImages, let url else {
            phase = model.settings.showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        guard let data = try? await model.imageData(for: url),
              let loaded = Self.image(from: data)
        else {
            phase = .failed
            return
        }
        phase = .success(loaded)
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

    fileprivate static func image(from data: Data) -> Image? {
        #if canImport(UIKit)
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
            guard let nsImage = NSImage(data: data) else { return nil }
            return Image(nsImage: nsImage)
        #else
            return nil
        #endif
    }
}

struct BaRowThumbnail: View {
    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var size: CGFloat = BaIconToken.rowThumbnail

    var body: some View {
        BaRemoteImageSurface(
            url: url,
            fallbackSystemImage: fallbackSystemImage,
            tint: tint,
            width: size,
            height: size,
            cornerRadius: 16
        )
    }
}

struct BaDetailRemoteImage: View {
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
            fallbackFont: .system(size: 52, weight: .semibold)
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
