//
//  BaStudentGalleryCardComponents.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import AVKit
import SwiftUI
import UniformTypeIdentifiers

enum BaStudentGalleryMetrics {
    static let cardSpacing: CGFloat = 12
    static let actionSpacing: CGFloat = 8
    static let minimumActionHeight: CGFloat = 42
    static let mediaInset: CGFloat = 6
}

struct BaStudentGalleryCardHeader<Actions: View>: View {
    let title: String
    let detail: String
    let kind: BaGuideMediaKind
    let tint: Color
    @ViewBuilder let actions: Actions

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                titleBlock
                    .layoutPriority(1)

                Spacer(minLength: 8)

                actionRow
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 10) {
                titleBlock
                actionRow
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail.baGalleryIfBlank(kind.title))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionRow: some View {
        HStack(alignment: .top, spacing: 12) {
            BaStudentGalleryHeaderActions {
                Image(systemName: kind.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                actions
            }
        }
    }
}

extension BaStudentGalleryCardHeader where Actions == EmptyView {
    init(title: String, detail: String, kind: BaGuideMediaKind, tint: Color) {
        self.title = title
        self.detail = detail
        self.kind = kind
        self.tint = tint
        self.actions = EmptyView()
    }
}

struct BaStudentGalleryGroupHeader<Trailing: View>: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                titleBlock
                    .layoutPriority(1)
                Spacer(minLength: 8)
                trailing
                    .fixedSize(horizontal: true, vertical: false)
            }

            VStack(alignment: .leading, spacing: 10) {
                titleBlock
                trailing
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var titleBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct BaStudentGalleryHeaderActions<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: BaStudentGalleryMetrics.actionSpacing) {
            content
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct BaGalleryMenuPicker<Content: View>: View {
    let title: String
    let selectionTitle: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 5) {
                Text(selectionTitle.baGalleryIfBlank(title))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: 112, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .frame(height: BaStudentGalleryMetrics.minimumActionHeight)
            .background(tint.opacity(0.09), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(tint.opacity(0.24), lineWidth: 1)
            }
        }
        .accessibilityLabel(title)
    }
}

struct BaStudentGalleryPillRow: View {
    let item: BaGuideGalleryItem

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chips
            VStack(alignment: .leading, spacing: 8) {
                chipViews
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            chipViews
        }
    }

    @ViewBuilder
    private var chipViews: some View {
        BaGalleryTextChip(title: kind.title, tint: kind.galleryTint)
        if let unlock = item.memoryUnlockLevel, unlock.baGalleryIsBlank == false {
            BaGalleryTextChip(
                title: String(format: String(localized: "ba.student.detail.memory.unlock.format"), unlock),
                tint: BaDesign.blue
            )
        }
        if item.mediaURL?.baIsGIFURL == true || item.imageURL?.baIsGIFURL == true {
            BaGalleryTextChip(title: "GIF", tint: BaDesign.green)
        }
    }
}

struct BaStudentGalleryVideoPlayerSurface: View {
    let title: String
    let previewURL: URL?
    let mediaURL: URL?
    let height: CGFloat

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Button {
                    Task { await loadVideo() }
                } label: {
                    ZStack {
                        BaStudentGalleryMediaSurface(
                            url: previewURL,
                            kind: .video,
                            height: height,
                            cornerRadius: 18,
                            maxPixelDimension: 900
                        )

                        Circle()
                            .fill(BaDesign.violet.opacity(0.88))
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.10), radius: 12, y: 5)
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.white)
                                        .offset(x: 2)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
                .disabled(mediaURL == nil || isLoading)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .alert(
            String(localized: "ba.student.detail.gallery.video.loadFailed"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "ba.common.done")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear {
            player?.pause()
        }
    }

    @MainActor
    private func loadVideo() async {
        guard let mediaURL else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let localURL = try await BaGuideMediaCache.shared.localURL(for: mediaURL)
            player = AVPlayer(url: localURL)
            player?.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BaStudentGalleryMediaSurface: View {
    @Environment(BaAppModel.self) private var model

    let url: URL?
    let kind: BaGuideMediaKind
    let height: CGFloat
    let cornerRadius: CGFloat
    let maxPixelDimension: Int
    var contentPadding: CGFloat = BaStudentGalleryMetrics.mediaInset

    @State private var phase: BaGalleryImagePhase = .placeholder

    var body: some View {
        let targetURL = url
        if targetURL?.baIsGIFURL == true {
            ZStack {
                Color.clear
                BaRemoteAnimatedImageSurface(
                    url: targetURL,
                    fallbackSystemImage: kind.systemImage,
                    tint: kind.galleryTint,
                    width: nil,
                    height: height,
                    cornerRadius: cornerRadius,
                    maxPixelDimension: maxPixelDimension
                )
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(kind.gallerySurfaceFill)

                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(contentPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loading:
                    ProgressView()
                        .controlSize(.regular)
                case .failed:
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                case .hidden:
                    Image(systemName: kind.systemImage)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                case .placeholder:
                    Image(systemName: kind.systemImage)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(kind.galleryTint)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .task(id: cacheTaskID) {
                await loadImage()
            }
            .onChange(of: model.settings.showPreviewImages) { _, _ in
                Task { await loadImage() }
            }
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(model.settings.showPreviewImages)"
    }

    @MainActor
    private func loadImage() async {
        guard model.settings.showPreviewImages, let url else {
            phase = model.settings.showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        guard let data = try? await model.imageData(for: url),
              let image = BaRemoteImageSurface.image(from: data)
        else {
            phase = .failed
            return
        }
        phase = .success(image)
    }
}

struct BaStudentGalleryAdaptiveMediaSurface: View {
    let presentation: BaStudentGalleryCardPresentation

    #if os(macOS)
        private var layoutContext: BaStudentGalleryLayoutContext { .desktop }
    #else
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        private var layoutContext: BaStudentGalleryLayoutContext {
            horizontalSizeClass == .regular ? .regular : .compact
        }
    #endif

    var body: some View {
        let resolvedLayout = presentation.layout.resolved(for: layoutContext)
        BaStudentGalleryMediaSurface(
            url: presentation.previewURL,
            kind: presentation.kind,
            height: resolvedLayout.height,
            cornerRadius: resolvedLayout.cornerRadius,
            maxPixelDimension: resolvedLayout.maxPixelDimension,
            contentPadding: resolvedLayout.contentPadding
        )
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaStudentGalleryAdaptiveVideoPlayerSurface: View {
    let item: BaGuideGalleryItem
    let presentation: BaStudentGalleryCardPresentation

    #if os(macOS)
        private var layoutContext: BaStudentGalleryLayoutContext { .desktop }
    #else
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        private var layoutContext: BaStudentGalleryLayoutContext {
            horizontalSizeClass == .regular ? .regular : .compact
        }
    #endif

    var body: some View {
        let resolvedLayout = presentation.layout.resolved(for: layoutContext)
        BaStudentGalleryVideoPlayerSurface(
            title: item.title,
            previewURL: item.imageURL,
            mediaURL: item.mediaURL,
            height: resolvedLayout.height
        )
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaStudentGalleryAdaptiveVideoPreviewSurface: View {
    let item: BaGuideGalleryItem
    let presentation: BaStudentGalleryCardPresentation

    #if os(macOS)
        private var layoutContext: BaStudentGalleryLayoutContext { .desktop }
    #else
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        private var layoutContext: BaStudentGalleryLayoutContext {
            horizontalSizeClass == .regular ? .regular : .compact
        }
    #endif

    var body: some View {
        let resolvedLayout = presentation.layout.resolved(for: layoutContext)
        ZStack {
            BaStudentGalleryMediaSurface(
                url: item.imageURL,
                kind: .video,
                height: resolvedLayout.height,
                cornerRadius: resolvedLayout.cornerRadius,
                maxPixelDimension: resolvedLayout.maxPixelDimension,
                contentPadding: resolvedLayout.contentPadding
            )

            Circle()
                .fill(BaDesign.violet.opacity(0.88))
                .frame(width: 58, height: 58)
                .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .offset(x: 2)
                }
                .accessibilityHidden(true)
        }
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaStudentGalleryPreviewMediaSurface: View {
    let presentation: BaStudentGalleryCardPresentation

    var body: some View {
        let resolvedLayout = presentation.layout.resolved(for: .preview)
        BaStudentGalleryMediaSurface(
            url: presentation.previewURL,
            kind: presentation.kind,
            height: resolvedLayout.height,
            cornerRadius: resolvedLayout.cornerRadius,
            maxPixelDimension: resolvedLayout.maxPixelDimension,
            contentPadding: resolvedLayout.contentPadding
        )
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaStudentGalleryPreviewVideoSurface: View {
    let item: BaGuideGalleryItem
    let presentation: BaStudentGalleryCardPresentation

    var body: some View {
        let resolvedLayout = presentation.layout.resolved(for: .preview)
        BaStudentGalleryVideoPlayerSurface(
            title: item.title,
            previewURL: item.imageURL,
            mediaURL: item.mediaURL,
            height: resolvedLayout.height
        )
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaGalleryTextChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(0.24), lineWidth: 1)
            }
    }
}

struct BaStudentGalleryCardPresentation {
    let item: BaGuideGalleryItem
    let kind: BaGuideMediaKind
    let title: String
    let detail: String
    let tint: Color
    let previewURL: URL?
    let saveURL: URL?
    let layout: BaStudentGalleryMediaLayout

    init(item: BaGuideGalleryItem) {
        self.item = item
        kind = item.mediaKind ?? .image
        title = item.galleryDisplayTitle
        detail = item.galleryDisplayDetail
        tint = item.galleryTint
        previewURL = item.imageURL ?? item.mediaURL
        saveURL = item.mediaURL ?? item.imageURL
        layout = BaStudentGalleryMediaLayout(item: item)
    }
}

struct BaGalleryMediaSaveButton: View {
    let url: URL?
    let title: String
    var tint: Color = BaDesign.blue

    @State private var exportDocument = BaGuideMediaExportDocument()
    @State private var exportType: UTType = .data
    @State private var exportFilename = "BA_media.bin"
    @State private var isExporterPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            Task { await prepareExport() }
        } label: {
            if isLoading {
                BaGalleryIconActionSurface(systemImage: "square.and.arrow.down", tint: tint, isLoading: true, isEnabled: false)
            } else {
                BaGalleryIconActionSurface(systemImage: "square.and.arrow.down", tint: tint, isEnabled: url != nil)
            }
        }
        .buttonStyle(.plain)
        .disabled(url == nil || isLoading)
        .accessibilityLabel(String(localized: "ba.action.save"))
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentType: exportType,
            defaultFilename: exportFilename
        ) { result in
            if case let .failure(error) = result {
                errorMessage = error.localizedDescription
            }
        }
        .alert(
            String(localized: "ba.student.detail.media.saveFailed"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "ba.common.done")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func prepareExport() async {
        guard let url else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await BaGuideMediaCache.shared.data(for: url)
            let metadata = BaGuideMediaExportBuilder.metadata(for: url, title: title)
            exportDocument = BaGuideMediaExportDocument(data: data)
            exportType = metadata.contentType
            exportFilename = metadata.fileName
            isExporterPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BaGalleryIconActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BaGalleryIconActionSurface(systemImage: systemImage, tint: tint, isEnabled: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct BaGalleryIconActionSurface: View {
    let systemImage: String
    let tint: Color
    var isLoading = false
    var isEnabled = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
            }
        }
        .foregroundStyle(isEnabled ? tint : .secondary)
        .frame(width: BaStudentGalleryMetrics.minimumActionHeight, height: BaStudentGalleryMetrics.minimumActionHeight)
        .background((isEnabled ? tint : Color.secondary).opacity(0.09), in: Circle())
        .overlay {
            Circle()
                .strokeBorder((isEnabled ? tint : Color.secondary).opacity(0.24), lineWidth: 1)
        }
    }
}

enum BaGalleryVariantTitleResolver {
    static func title(for item: BaGuideGalleryItem, in items: [BaGuideGalleryItem]) -> String {
        let baseTitle = item.galleryShortTitle
        let matchingItems = items.filter { $0.galleryShortTitle == baseTitle }
        guard matchingItems.count > 1,
              let zeroBasedIndex = matchingItems.firstIndex(where: { $0.id == item.id })
        else {
            return baseTitle
        }
        return "\(baseTitle)\(zeroBasedIndex + 1)"
    }
}

enum BaGalleryImagePhase {
    case placeholder
    case hidden
    case loading
    case failed
    case success(Image)
}

extension BaGuideGalleryItem {
    var galleryDisplayTitle: String {
        galleryShortTitle
    }

    var galleryDisplayDetail: String {
        let kind = mediaKind ?? .image
        var parts = [kind.title]
        if detail.baGalleryIsBlank == false, detail != kind.title {
            parts.append(detail)
        }
        if let note, note.baGalleryIsBlank == false, parts.contains(note) == false {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }

    var galleryShortTitle: String {
        let title = BaGuideGallerySupport.normalizeTitle(title)
        return title.isEmpty ? String(localized: "ba.student.detail.media.gallery") : title
    }

    var galleryImageHeight: CGFloat {
        BaStudentGalleryMediaLayout(item: self).height
    }

    var galleryTint: Color {
        let title = BaGuideGallerySupport.normalizeTitle(title)
        if BaGuideGallerySupport.isMemoryHall(self) { return BaDesign.blue }
        if BaGuideGallerySupport.isExpression(self) { return BaDesign.pink }
        if title.hasPrefix("设定集") || title.hasPrefix("TV动画设定图") { return BaDesign.green }
        if title.hasPrefix("本家画") || title.hasPrefix("官方衍生") { return BaDesign.violet }
        return (mediaKind ?? .image).galleryTint
    }
}

extension BaGuideMediaKind {
    var galleryTint: Color {
        switch self {
        case .image:
            BaDesign.pink
        case .video:
            BaDesign.violet
        case .audio:
            BaDesign.amber
        case .live2d:
            BaDesign.blue
        case .unknown:
            .secondary
        }
    }

    var gallerySurfaceFill: Color {
        switch self {
        case .live2d:
            return BaDesign.blue.opacity(0.045)
        case .video:
            return BaDesign.violet.opacity(0.050)
        case .image, .audio, .unknown:
            return Color.secondary.opacity(0.050)
        }
    }
}

extension BaGuideRow {
    var galleryRelatedLinkTitle: String {
        let value = title.replacingOccurrences(of: "影画", with: "")
            .replacingOccurrences(of: "相关链接", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.baGalleryIfBlank(String(localized: "ba.student.detail.gallery.relatedLinks"))
    }
}

extension URL {
    var baIsGIFURL: Bool {
        BaGuideGallerySupport.isGIFURL(self)
    }
}

extension View {
    func baGalleryListCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 9, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

extension String {
    var baGalleryTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var baGalleryIsBlank: Bool {
        baGalleryTrimmed.isEmpty
    }

    func baGalleryIfBlank(_ fallback: String) -> String {
        baGalleryIsBlank ? fallback : self
    }
}
