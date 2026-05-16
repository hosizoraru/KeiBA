//
//  BaStudentGalleryCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

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
        ForEach(state.rows) { row in
            switch row {
            case let .item(item):
                BaStudentGalleryItemCard(item: item, onPreview: onPreview)
                    .equatable()
                    .baGalleryListCardRow()
            case let .expression(items):
                BaStudentGalleryExpressionCard(items: items, onPreview: onPreview)
                    .baGalleryListCardRow()
            case let .videoGroup(group):
                BaStudentGalleryVideoGroupCard(group: group, onPreview: onPreview)
                    .baGalleryListCardRow()
            case let .memoryUnlock(level):
                BaStudentGalleryMemoryUnlockCard(level: level)
                    .baGalleryListCardRow()
            case let .relatedLinks(rows):
                BaStudentGalleryRelatedLinksCard(rows: rows)
                    .baGalleryListCardRow()
            }
        }
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
        let presentation = BaStudentGalleryCardPresentation(item: item)
        switch kind {
        case .audio:
            BaStudentGalleryAudioCard(item: item)
        default:
            BaGlassCard(tint: presentation.tint) {
                VStack(alignment: .leading, spacing: BaStudentGalleryMetrics.cardSpacing) {
                    BaStudentGalleryCardHeader(
                        title: presentation.title,
                        detail: presentation.detail,
                        kind: kind,
                        tint: presentation.tint
                    ) {
                        BaStudentGalleryHeaderActions {
                            if let saveURL = presentation.saveURL {
                                ShareLink(item: saveURL) {
                                    BaGalleryIconActionSurface(
                                        systemImage: "square.and.arrow.up",
                                        tint: presentation.tint,
                                        isEnabled: true
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(String(localized: "ba.action.share"))
                            }

                            BaGalleryMediaSaveButton(
                                url: presentation.saveURL,
                                title: presentation.title,
                                tint: presentation.tint
                            )
                        }
                    }

                    Button {
                        onPreview(BaStudentGalleryPreviewItem(item: item))
                    } label: {
                        BaStudentGalleryAdaptiveMediaSurface(presentation: presentation)
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: presentation.layout.cornerRadius, style: .continuous))
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
            VStack(alignment: .leading, spacing: BaStudentGalleryMetrics.cardSpacing) {
                BaStudentGalleryGroupHeader(
                    title: String(localized: "ba.student.detail.gallery.expression.title"),
                    detail: String(format: String(localized: "ba.student.detail.gallery.expression.count.format"), items.count),
                    systemImage: "face.smiling",
                    tint: BaDesign.pink
                ) {
                    BaStudentGalleryHeaderActions {
                        BaGalleryMenuPicker(
                            title: String(localized: "ba.student.detail.gallery.expression.variant"),
                            selectionTitle: selectedItem?.galleryShortTitle ?? "",
                            tint: BaDesign.pink
                        ) {
                            ForEach(items) { item in
                                Button(item.galleryShortTitle) {
                                    selectedID = item.id
                                }
                            }
                        }

                        BaGalleryMediaSaveButton(
                            url: selectedItem?.mediaURL ?? selectedItem?.imageURL,
                            title: selectedItem?.galleryDisplayTitle ?? String(localized: "ba.student.detail.gallery.expression.title"),
                            tint: BaDesign.pink
                        )
                    }
                }

                if let selectedItem {
                    let selectedPresentation = BaStudentGalleryCardPresentation(item: selectedItem)
                    Button {
                        onPreview(BaStudentGalleryPreviewItem(item: selectedItem))
                    } label: {
                        BaStudentGalleryAdaptiveMediaSurface(presentation: selectedPresentation)
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: selectedPresentation.layout.cornerRadius, style: .continuous))
                    .accessibilityLabel(String(localized: "ba.student.detail.media.preview"))
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
            VStack(alignment: .leading, spacing: BaStudentGalleryMetrics.cardSpacing) {
                BaStudentGalleryGroupHeader(
                    title: group.title,
                    detail: String(format: String(localized: "ba.student.detail.gallery.video.count.format"), group.items.count),
                    systemImage: "play.rectangle",
                    tint: BaDesign.violet
                ) {
                    BaStudentGalleryHeaderActions {
                        if group.items.count > 1 {
                            BaGalleryMenuPicker(
                                title: String(localized: "ba.student.detail.media.video"),
                                selectionTitle: selectedItem.map { videoVariantTitle(for: $0) } ?? "",
                                tint: BaDesign.violet
                            ) {
                                ForEach(group.items) { item in
                                    Button(videoVariantTitle(for: item)) {
                                        selectedID = item.id
                                    }
                                }
                            }
                        }

                        if let selectedItem {
                            BaGalleryIconActionButton(
                                title: String(localized: "ba.student.detail.media.preview"),
                                systemImage: "arrow.up.left.and.arrow.down.right",
                                tint: BaDesign.violet
                            ) {
                                onPreview(BaStudentGalleryPreviewItem(item: selectedItem))
                            }
                        }

                        BaGalleryMediaSaveButton(
                            url: selectedItem?.mediaURL ?? selectedItem?.imageURL,
                            title: selectedItem?.galleryDisplayTitle ?? group.title,
                            tint: BaDesign.violet
                        )
                    }
                }

                if let selectedItem {
                    let selectedPresentation = BaStudentGalleryCardPresentation(item: selectedItem)
                    Button {
                        onPreview(BaStudentGalleryPreviewItem(item: selectedItem))
                    } label: {
                        BaStudentGalleryAdaptiveVideoPreviewSurface(
                            item: selectedItem,
                            presentation: selectedPresentation
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: selectedPresentation.layout.cornerRadius, style: .continuous))
                    .accessibilityLabel(String(localized: "ba.student.detail.media.preview"))
                }
            }
        }
        .onAppear {
            selectedID = selectedID ?? group.items.first?.id
        }
    }

    private func videoVariantTitle(for item: BaGuideGalleryItem) -> String {
        BaGalleryVariantTitleResolver.title(for: item, in: group.items)
    }
}

struct BaStudentGalleryAudioCard: View {
    let item: BaGuideGalleryItem

    @State private var playback = BaGuideAudioPlaybackController()
    @State private var scrubProgress = 0.0
    @State private var isScrubbing = false

    private var isCurrentItem: Bool {
        playback.currentRemoteURL == item.mediaURL
    }

    private var sliderProgress: Binding<Double> {
        Binding {
            isScrubbing ? scrubProgress : (isCurrentItem ? playback.progress : 0)
        } set: { newValue in
            scrubProgress = min(max(newValue, 0), 1)
        }
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.amber) {
            VStack(alignment: .leading, spacing: BaStudentGalleryMetrics.cardSpacing) {
                BaStudentGalleryCardHeader(
                    title: item.title,
                    detail: item.galleryDisplayDetail,
                    kind: .audio,
                    tint: BaDesign.amber
                ) {
                    BaGalleryMediaSaveButton(url: item.mediaURL, title: item.title, tint: BaDesign.amber)
                }

                audioControls

                Slider(value: sliderProgress, in: 0 ... 1) { editing in
                    if editing {
                        isScrubbing = true
                        scrubProgress = isCurrentItem ? playback.progress : 0
                    } else {
                        if isCurrentItem {
                            playback.seek(to: scrubProgress)
                        }
                        isScrubbing = false
                    }
                }
                .disabled(isCurrentItem == false || playback.canSeek == false)
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
        .onChange(of: playback.progress) { _, newValue in
            guard isScrubbing == false else { return }
            scrubProgress = isCurrentItem ? newValue : 0
        }
        .onChange(of: playback.currentRemoteURL) { _, _ in
            isScrubbing = false
            scrubProgress = isCurrentItem ? playback.progress : 0
        }
    }

    private var audioControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                playButton

                if playback.isLoading, isCurrentItem {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: BaStudentGalleryMetrics.actionSpacing) {
                playButton

                if playback.isLoading, isCurrentItem {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var playButton: some View {
        Button {
            if let url = item.mediaURL {
                playback.toggle(remoteURL: url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: playback.isPlaying && isCurrentItem ? "pause.fill" : "play.fill")
                    .font(.callout.weight(.bold))
                    .frame(width: 18)

                Text(
                    playback.isPlaying && isCurrentItem
                        ? String(localized: "ba.student.detail.gallery.audio.pause")
                        : String(localized: "ba.student.detail.gallery.audio.play")
                )
                .font(.callout.weight(.semibold))
            }
            .foregroundStyle(BaDesign.amber)
            .padding(.horizontal, 14)
            .frame(minWidth: 92, minHeight: BaStudentGalleryMetrics.minimumActionHeight)
            .background(BaDesign.amber.opacity(item.mediaURL == nil ? 0.04 : 0.10), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(BaDesign.amber.opacity(item.mediaURL == nil ? 0.12 : 0.26), lineWidth: 1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .disabled(item.mediaURL == nil || playback.isLoading)
        .contentShape(Capsule())
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
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.galleryRelatedLinkTitle)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(url.host ?? url.absoluteString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(BaDesign.green)
                                    .frame(width: 30, height: 30)
                                    .background(BaDesign.green.opacity(0.10), in: Circle())
                            }
                            .padding(12)
                            .background(BaDesign.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
