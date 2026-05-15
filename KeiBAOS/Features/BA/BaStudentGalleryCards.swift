//
//  BaStudentGalleryCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import AVKit
import SwiftUI
import UniformTypeIdentifiers

struct BaStudentGalleryCardsSection: View {
    let info: BaStudentGuideInfo?
    var onPreview: (BaStudentGalleryPreviewItem) -> Void = { _ in }

    private var state: BaStudentGalleryDisplayState {
        BaStudentGalleryDisplayState(info: info)
    }

    var body: some View {
        Section {
            if state.hasRenderableContent == false {
                BaStudentDetailEmptyRow(section: .gallery)
                    .baGalleryListCardRow()
            } else {
                galleryRows
            }
        }
    }

    @ViewBuilder
    private var galleryRows: some View {
        let displayItems = state.displayGalleryItems.filter { BaGuideGallerySupport.isExpression($0) == false }
        let expressionAnchor = state.firstExpressionIndex ?? displayItems.count
        let memoryAnchor = state.firstMemoryHallIndex
        let officialIntroAnchor = state.lastOfficialIntroIndex

        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
            if expressionAnchor == index, state.expressionItems.isEmpty == false {
                BaStudentGalleryExpressionCard(items: state.expressionItems, onPreview: onPreview)
                    .baGalleryListCardRow()
            }

            if memoryAnchor == index, state.memoryUnlockLevel.isEmpty == false {
                BaStudentGalleryMemoryUnlockCard(level: state.memoryUnlockLevel)
                    .baGalleryListCardRow()
            }

            BaStudentGalleryItemCard(item: item, onPreview: onPreview)
                .equatable()
                .baGalleryListCardRow()

            if memoryAnchor == index, let group = state.memoryHallVideoGroup {
                BaStudentGalleryVideoGroupCard(group: group, onPreview: onPreview)
                    .baGalleryListCardRow()
            }

            if officialIntroAnchor == index {
                ForEach(state.pvAndRoleVideoGroups) { group in
                    BaStudentGalleryVideoGroupCard(group: group, onPreview: onPreview)
                        .baGalleryListCardRow()
                }
            }
        }

        if expressionAnchor >= displayItems.count, state.expressionItems.isEmpty == false {
            BaStudentGalleryExpressionCard(items: state.expressionItems, onPreview: onPreview)
                .baGalleryListCardRow()
        }

        ForEach(state.otherTrailingVideoGroups) { group in
            BaStudentGalleryVideoGroupCard(group: group, onPreview: onPreview)
                .baGalleryListCardRow()
        }

        if state.galleryRelatedLinkRows.isEmpty == false {
            BaStudentGalleryRelatedLinksCard(rows: state.galleryRelatedLinkRows)
                .baGalleryListCardRow()
        }
    }
}

struct BaStudentGalleryPreviewItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let previewURL: URL?
    let mediaURL: URL?
    let kind: BaGuideMediaKind

    init(item: BaGuideGalleryItem) {
        kind = item.mediaKind ?? .image
        title = item.title
        detail = item.galleryDisplayDetail
        previewURL = item.imageURL ?? item.mediaURL
        mediaURL = item.mediaURL ?? item.imageURL
        id = "\(kind.rawValue)|\(mediaURL?.absoluteString ?? previewURL?.absoluteString ?? item.id)"
    }

    init(title: String, detail: String, previewURL: URL?, mediaURL: URL?, kind: BaGuideMediaKind) {
        self.title = title
        self.detail = detail
        self.previewURL = previewURL
        self.mediaURL = mediaURL
        self.kind = kind
        id = "\(kind.rawValue)|\(mediaURL?.absoluteString ?? previewURL?.absoluteString ?? title)"
    }
}

struct BaStudentGalleryPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BaStudentGalleryPreviewItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch item.kind {
                    case .video:
                        BaStudentGalleryVideoPlayerSurface(
                            title: item.title,
                            previewURL: item.previewURL,
                            mediaURL: item.mediaURL,
                            height: 420
                        )
                    case .audio:
                        BaStudentGalleryAudioCard(
                            item: BaGuideGalleryItem(
                                id: item.id,
                                title: item.title,
                                detail: item.detail,
                                imageURL: item.previewURL,
                                mediaURL: item.mediaURL,
                                mediaKind: .audio
                            )
                        )
                    case .image, .live2d, .unknown:
                        BaStudentGalleryMediaSurface(
                            url: item.previewURL ?? item.mediaURL,
                            kind: item.kind,
                            height: 520,
                            cornerRadius: 20,
                            maxPixelDimension: 1600
                        )
                    }

                    if item.detail.isBlank == false {
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }
            .navigationTitle(item.title)
            .platformInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    BaGalleryMediaSaveButton(url: item.mediaURL ?? item.previewURL, title: item.title)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct BaStudentGalleryItemCard: View, Equatable {
    let item: BaGuideGalleryItem
    let onPreview: (BaStudentGalleryPreviewItem) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item == rhs.item
    }

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        switch kind {
        case .audio:
            BaStudentGalleryAudioCard(item: item)
        default:
            BaGlassCard(tint: BaDesign.pink) {
                VStack(alignment: .leading, spacing: 14) {
                    BaStudentGalleryCardHeader(
                        title: item.title,
                        detail: item.galleryDisplayDetail,
                        kind: kind,
                        url: item.mediaURL ?? item.imageURL
                    )

                    Button {
                        onPreview(BaStudentGalleryPreviewItem(item: item))
                    } label: {
                        BaStudentGalleryMediaSurface(
                            url: item.imageURL ?? item.mediaURL,
                            kind: kind,
                            height: item.galleryImageHeight,
                            cornerRadius: 20,
                            maxPixelDimension: 1200
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityLabel(String(localized: "ba.student.detail.media.preview"))

                    BaStudentGalleryPillRow(item: item)
                }
            }
        }
    }
}

private struct BaStudentGalleryExpressionCard: View {
    let items: [BaGuideGalleryItem]
    let onPreview: (BaStudentGalleryPreviewItem) -> Void

    @State private var selectedID: BaGuideGalleryItem.ID?

    private var selectedItem: BaGuideGalleryItem? {
        if let selectedID, let item = items.first(where: { $0.id == selectedID }) {
            return item
        }
        return items.first
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(localized: "ba.student.detail.gallery.expression.title"))
                            .font(.title3.weight(.semibold))
                        Text(String(format: String(localized: "ba.student.detail.gallery.expression.count.format"), items.count))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Picker(String(localized: "ba.student.detail.gallery.expression.variant"), selection: Binding(
                        get: { selectedItem?.id ?? "" },
                        set: { selectedID = $0 }
                    )) {
                        ForEach(items) { item in
                            Text(item.galleryShortTitle).tag(item.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                if let selectedItem {
                    Button {
                        onPreview(BaStudentGalleryPreviewItem(item: selectedItem))
                    } label: {
                        BaStudentGalleryMediaSurface(
                            url: selectedItem.imageURL ?? selectedItem.mediaURL,
                            kind: selectedItem.mediaKind ?? .image,
                            height: 250,
                            cornerRadius: 18,
                            maxPixelDimension: 1100
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    BaStudentGalleryCardFooter(url: selectedItem.mediaURL ?? selectedItem.imageURL, title: selectedItem.title)
                }
            }
        }
        .onAppear {
            selectedID = selectedID ?? items.first?.id
        }
    }
}

private struct BaStudentGalleryVideoGroupCard: View {
    let group: BaStudentGalleryVideoGroup
    let onPreview: (BaStudentGalleryPreviewItem) -> Void

    @State private var selectedID: BaGuideGalleryItem.ID?

    private var selectedItem: BaGuideGalleryItem? {
        if let selectedID, let item = group.items.first(where: { $0.id == selectedID }) {
            return item
        }
        return group.items.first
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(group.title)
                            .font(.title3.weight(.semibold))
                        Text(String(format: String(localized: "ba.student.detail.gallery.video.count.format"), group.items.count))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    if group.items.count > 1 {
                        Picker(String(localized: "ba.student.detail.media.video"), selection: Binding(
                            get: { selectedItem?.id ?? "" },
                            set: { selectedID = $0 }
                        )) {
                            ForEach(group.items) { item in
                                Text(item.galleryShortTitle).tag(item.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                if let selectedItem {
                    BaStudentGalleryVideoPlayerSurface(
                        title: selectedItem.title,
                        previewURL: selectedItem.imageURL,
                        mediaURL: selectedItem.mediaURL,
                        height: 235
                    )

                    HStack {
                        Button {
                            onPreview(BaStudentGalleryPreviewItem(item: selectedItem))
                        } label: {
                            Label(String(localized: "ba.student.detail.media.preview"), systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .buttonStyle(.bordered)

                        Spacer(minLength: 8)

                        BaGalleryMediaSaveButton(url: selectedItem.mediaURL, title: selectedItem.title)
                    }
                }
            }
        }
        .onAppear {
            selectedID = selectedID ?? group.items.first?.id
        }
    }
}

private struct BaStudentGalleryVideoPlayerSurface: View {
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
                            .fill(.thinMaterial)
                            .frame(width: 58, height: 58)
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(BaDesign.violet)
                                        .offset(x: 2)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
                .disabled(mediaURL == nil || isLoading)
            }
        }
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

private struct BaStudentGalleryAudioCard: View {
    let item: BaGuideGalleryItem

    @State private var playback = BaGuideAudioPlaybackController()

    private var isCurrentItem: Bool {
        playback.currentRemoteURL == item.mediaURL
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.amber) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentGalleryCardHeader(
                    title: item.title,
                    detail: item.galleryDisplayDetail,
                    kind: .audio,
                    url: item.mediaURL
                )

                HStack(spacing: 12) {
                    Button {
                        if let url = item.mediaURL {
                            playback.toggle(remoteURL: url)
                        }
                    } label: {
                        Label(
                            playback.isPlaying && isCurrentItem
                                ? String(localized: "ba.student.detail.gallery.audio.pause")
                                : String(localized: "ba.student.detail.gallery.audio.play"),
                            systemImage: playback.isPlaying && isCurrentItem ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(item.mediaURL == nil || playback.isLoading)

                    if playback.isLoading, isCurrentItem {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer(minLength: 8)

                    BaGalleryMediaSaveButton(url: item.mediaURL, title: item.title)
                }

                ProgressView(value: isCurrentItem ? playback.progress : 0)
                    .tint(BaDesign.amber)

                if let error = playback.errorMessage, error.isEmpty == false {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onDisappear {
            playback.stop()
        }
    }
}

private struct BaStudentGalleryMemoryUnlockCard: View {
    let level: String

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.display")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BaDesign.blue)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "ba.student.detail.gallery.memory.unlock.title"))
                        .font(.headline.weight(.semibold))
                    Text(String(format: String(localized: "ba.student.detail.memory.unlock.format"), level))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct BaStudentGalleryRelatedLinksCard: View {
    let rows: [BaGuideRow]

    var body: some View {
        BaGlassCard(tint: BaDesign.green) {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "ba.student.detail.gallery.relatedLinks"), systemImage: "link")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                ForEach(rows) { row in
                    ForEach(BaStudentGalleryDisplayState.webURLs(in: row.value), id: \.self) { url in
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                Text(row.galleryRelatedLinkTitle)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer(minLength: 8)

                                Text(url.host ?? url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(BaDesign.green)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
}

private struct BaStudentGalleryCardHeader: View {
    let title: String
    let detail: String
    let kind: BaGuideMediaKind
    let url: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail.ifBlank(kind.title))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let url {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline.weight(.semibold))
                        .frame(width: 42, height: 38)
                        .liquidGlassSurface(
                            cornerRadius: 18,
                            tint: BaDesign.pink.opacity(0.10),
                            isInteractive: true
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "ba.action.share"))
            }
        }
    }
}

private struct BaStudentGalleryPillRow: View {
    let item: BaGuideGalleryItem

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        HStack(spacing: 8) {
            BaGalleryTextChip(title: kind.title, tint: BaDesign.pink)
            if let unlock = item.memoryUnlockLevel, unlock.isBlank == false {
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
}

private struct BaStudentGalleryCardFooter: View {
    let url: URL?
    let title: String

    var body: some View {
        HStack {
            if let url {
                ShareLink(item: url) {
                    Label(String(localized: "ba.action.share"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }

            Spacer(minLength: 8)

            BaGalleryMediaSaveButton(url: url, title: title)
        }
    }
}

private struct BaStudentGalleryMediaSurface: View {
    let url: URL?
    let kind: BaGuideMediaKind
    let height: CGFloat
    let cornerRadius: CGFloat
    let maxPixelDimension: Int

    var body: some View {
        let targetURL = url
        if targetURL?.baIsGIFURL == true {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.001))
                BaRemoteAnimatedImageSurface(
                    url: targetURL,
                    fallbackSystemImage: kind.systemImage,
                    tint: BaDesign.pink,
                    width: nil,
                    height: height,
                    cornerRadius: cornerRadius,
                    maxPixelDimension: maxPixelDimension
                )
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            BaRemoteImageSurface(
                url: targetURL,
                fallbackSystemImage: kind.systemImage,
                tint: BaDesign.pink,
                width: nil,
                height: height,
                cornerRadius: cornerRadius,
                contentMode: .fit,
                usesImageBackdrop: kind == .image || kind == .live2d,
                fallbackFont: .system(size: 48, weight: .semibold)
            )
        }
    }
}

private struct BaGalleryTextChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(0.24), lineWidth: 1)
            }
    }
}

private struct BaGalleryMediaSaveButton: View {
    let url: URL?
    let title: String

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
                ProgressView()
                    .controlSize(.small)
            } else {
                Label(String(localized: "ba.action.save"), systemImage: "square.and.arrow.down")
            }
        }
        .buttonStyle(.bordered)
        .disabled(url == nil || isLoading)
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

private extension BaGuideGalleryItem {
    var galleryDisplayDetail: String {
        let kind = mediaKind ?? .image
        var parts = [kind.title]
        if detail.isBlank == false, detail != kind.title {
            parts.append(detail)
        }
        if let note, note.isBlank == false, parts.contains(note) == false {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }

    var galleryShortTitle: String {
        let title = BaGuideGallerySupport.normalizeTitle(title)
        return title.isEmpty ? String(localized: "ba.student.detail.media.gallery") : title
    }

    var galleryImageHeight: CGFloat {
        if BaGuideGallerySupport.isMemoryHall(self) { return 330 }
        if BaGuideGallerySupport.isOfficialIntro(self) { return 270 }
        return 430
    }
}

private extension BaGuideRow {
    var galleryRelatedLinkTitle: String {
        let value = title.replacingOccurrences(of: "影画", with: "")
            .replacingOccurrences(of: "相关链接", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.ifBlank(String(localized: "ba.student.detail.gallery.relatedLinks"))
    }
}

private extension URL {
    var baIsGIFURL: Bool {
        BaGuideGallerySupport.isGIFURL(self)
    }
}

private extension View {
    func baGalleryListCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 9, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }

    func ifBlank(_ fallback: String) -> String {
        isBlank ? fallback : self
    }
}
