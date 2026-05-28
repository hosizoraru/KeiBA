//
//  BaStudentGalleryCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct BaStudentGalleryCardsSection: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let info: BaStudentGuideInfo?
    var onPreview: (BaStudentGalleryPreviewItem) -> Void = { _ in }

    @State private var collectionHeight: CGFloat = 1

    var body: some View {
        // BaStudentGalleryDisplayState scans the entire info to compute rows,
        // hasRenderableContent and partition expression/video groups. The
        // previous computed property re-ran the full classification on every
        // body call (twice per recompose: once for the empty-state guard and
        // again for the ForEach). Build it once per evaluation.
        let state = BaStudentGalleryDisplayState(info: info)
        Section {
            if state.hasRenderableContent == false {
                BaStudentDetailEmptyRow(section: .gallery)
                    .baGalleryListCardRow()
            } else {
                galleryRows(state: state)
            }
        }
    }

    @ViewBuilder
    private func galleryRows(state: BaStudentGalleryDisplayState) -> some View {
        #if os(iOS)
            if metrics.usesGalleryCollectionLayout {
                BaStudentGalleryCollectionContainer(
                    rows: state.rows,
                    columnCount: metrics.galleryCollectionColumnCount,
                    height: $collectionHeight,
                    onPreview: onPreview
                )
                .frame(height: max(collectionHeight, 1))
                .baGalleryListCardRow()
            } else {
                galleryListRows(rows: state.rows)
            }
        #else
            galleryListRows(rows: state.rows)
        #endif
    }

    @ViewBuilder
    private func galleryListRows(rows: [BaStudentGalleryDisplayRow]) -> some View {
        ForEach(rows) { row in
            BaStudentGalleryRowCard(row: row, onPreview: onPreview)
                .baGalleryListCardRow()
        }
    }
}

private struct BaStudentGalleryRowCard: View {
    let row: BaStudentGalleryDisplayRow
    let onPreview: (BaStudentGalleryPreviewItem) -> Void

    var body: some View {
        switch row {
        case let .item(item):
            BaStudentGalleryItemCard(item: item, onPreview: onPreview)
                .equatable()
        case let .expression(items):
            BaStudentGalleryExpressionCard(items: items, onPreview: onPreview)
        case let .videoGroup(group):
            BaStudentGalleryVideoGroupCard(group: group, onPreview: onPreview)
        case let .memoryUnlock(level):
            BaStudentGalleryMemoryUnlockCard(level: level)
        case let .relatedLinks(rows):
            BaStudentGalleryRelatedLinksCard(rows: rows)
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
                                .accessibilityLabel(BaL10n.string("ba.action.share"))
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
                    .accessibilityLabel(BaL10n.string("ba.student.detail.media.preview"))

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
                    title: BaL10n.string("ba.student.detail.gallery.expression.title"),
                    detail: String(format: BaL10n.string("ba.student.detail.gallery.expression.count.format"), items.count),
                    systemImage: "face.smiling",
                    tint: BaDesign.pink
                ) {
                    BaStudentGalleryHeaderActions {
                        BaGalleryMenuPicker(
                            title: BaL10n.string("ba.student.detail.gallery.expression.variant"),
                            selectionTitle: selectedItem?.galleryShortTitle ?? "",
                            tint: BaDesign.pink
                        ) {
                            ForEach(items) { item in
                                Button(item.galleryShortTitle) {
                                    BaMenuActionDispatcher.perform {
                                        selectedID = item.id
                                    }
                                }
                            }
                        }

                        BaGalleryMediaSaveButton(
                            url: selectedItem?.mediaURL ?? selectedItem?.imageURL,
                            title: selectedItem?.galleryDisplayTitle ?? BaL10n.string("ba.student.detail.gallery.expression.title"),
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
                    .accessibilityLabel(BaL10n.string("ba.student.detail.media.preview"))
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
                    detail: String(format: BaL10n.string("ba.student.detail.gallery.video.count.format"), group.items.count),
                    systemImage: "play.rectangle",
                    tint: BaDesign.violet
                ) {
                    BaStudentGalleryHeaderActions {
                        if group.items.count > 1 {
                            BaGalleryMenuPicker(
                                title: BaL10n.string("ba.student.detail.media.video"),
                                selectionTitle: selectedItem.map { videoVariantTitle(for: $0) } ?? "",
                                tint: BaDesign.violet
                            ) {
                                ForEach(group.items) { item in
                                    Button(videoVariantTitle(for: item)) {
                                        BaMenuActionDispatcher.perform {
                                            selectedID = item.id
                                        }
                                    }
                                }
                            }
                        }

                        if let selectedItem {
                            BaGalleryIconActionButton(
                                title: BaL10n.string("ba.student.detail.media.preview"),
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
                    .accessibilityLabel(BaL10n.string("ba.student.detail.media.preview"))
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
                        ? BaL10n.string("ba.student.detail.gallery.audio.pause")
                        : BaL10n.string("ba.student.detail.gallery.audio.play")
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
                    Text(BaL10n.string("ba.student.detail.gallery.memory.unlock.title"))
                        .font(.headline.weight(.semibold))
                    Text(String(format: BaL10n.string("ba.student.detail.memory.unlock.format"), level))
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
                Label(BaL10n.string("ba.student.detail.gallery.relatedLinks"), systemImage: "link")
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

#if canImport(UIKit)
    nonisolated private enum BaStudentGalleryCollectionSection: Hashable {
        case main
    }

    private struct BaStudentGalleryCollectionContainer: UIViewRepresentable {
        let rows: [BaStudentGalleryDisplayRow]
        let columnCount: Int
        @Binding var height: CGFloat
        let onPreview: (BaStudentGalleryPreviewItem) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(height: $height, onPreview: onPreview)
        }

        func makeUIView(context: Context) -> UICollectionView {
            let collectionView = UICollectionView(
                frame: .zero,
                collectionViewLayout: Self.makeLayout(columnCount: columnCount)
            )
            collectionView.backgroundColor = .clear
            collectionView.isScrollEnabled = false
            collectionView.alwaysBounceVertical = false
            collectionView.contentInsetAdjustmentBehavior = .never
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.setContentHuggingPriority(.required, for: .vertical)
            collectionView.setContentCompressionResistancePriority(.required, for: .vertical)
            context.coordinator.configureDataSource(collectionView: collectionView)
            return collectionView
        }

        func updateUIView(_ collectionView: UICollectionView, context: Context) {
            context.coordinator.height = $height
            context.coordinator.onPreview = onPreview
            context.coordinator.apply(
                rows: rows,
                columnCount: columnCount,
                to: collectionView
            )
        }

        static func dismantleUIView(_ uiView: UICollectionView, coordinator: Coordinator) {
            coordinator.dataSource = nil
            uiView.delegate = nil
        }

        private static func makeLayout(columnCount: Int) -> UICollectionViewCompositionalLayout {
            UICollectionViewCompositionalLayout { _, environment in
                let columns = max(columnCount, 1)
                let width = environment.container.effectiveContentSize.width
                let spacing = Self.spacing(for: width)

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(380)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(380)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: Array(repeating: item, count: columns)
                )
                group.interItemSpacing = .fixed(spacing)

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = spacing
                return section
            }
        }

        private static func spacing(for width: CGFloat) -> CGFloat {
            width >= 900 ? 16 : 14
        }

        final class Coordinator: NSObject {
            var height: Binding<CGFloat>
            var onPreview: (BaStudentGalleryPreviewItem) -> Void
            var dataSource: UICollectionViewDiffableDataSource<BaStudentGalleryCollectionSection, BaStudentGalleryDisplayRow>?

            private var appliedRows: [BaStudentGalleryDisplayRow] = []
            private var appliedColumnCount = 0

            init(
                height: Binding<CGFloat>,
                onPreview: @escaping (BaStudentGalleryPreviewItem) -> Void
            ) {
                self.height = height
                self.onPreview = onPreview
            }

            func configureDataSource(collectionView: UICollectionView) {
                let registration = UICollectionView.CellRegistration<UICollectionViewCell, BaStudentGalleryDisplayRow> { [weak self] cell, _, row in
                    guard let self else { return }
                    cell.backgroundConfiguration = .clear()
                    cell.contentConfiguration = UIHostingConfiguration {
                        BaStudentGalleryRowCard(row: row, onPreview: self.onPreview)
                    }
                    .margins(.all, 0)
                    .background {
                        Color.clear
                    }
                }

                dataSource = UICollectionViewDiffableDataSource<BaStudentGalleryCollectionSection, BaStudentGalleryDisplayRow>(
                    collectionView: collectionView
                ) { collectionView, indexPath, row in
                    collectionView.dequeueConfiguredReusableCell(
                        using: registration,
                        for: indexPath,
                        item: row
                    )
                }
            }

            func apply(
                rows: [BaStudentGalleryDisplayRow],
                columnCount: Int,
                to collectionView: UICollectionView
            ) {
                if appliedColumnCount != columnCount {
                    collectionView.setCollectionViewLayout(
                        BaStudentGalleryCollectionContainer.makeLayout(columnCount: columnCount),
                        animated: false
                    )
                    appliedColumnCount = columnCount
                }

                guard let dataSource else { return }
                if appliedRows == rows {
                    updateHeight(for: collectionView)
                    return
                }

                appliedRows = rows
                var snapshot = NSDiffableDataSourceSnapshot<BaStudentGalleryCollectionSection, BaStudentGalleryDisplayRow>()
                snapshot.appendSections([.main])
                snapshot.appendItems(rows, toSection: .main)
                dataSource.apply(snapshot, animatingDifferences: false) { [weak self, weak collectionView] in
                    guard let self, let collectionView else { return }
                    self.updateHeight(for: collectionView)
                }
            }

            private func updateHeight(for collectionView: UICollectionView) {
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.layoutIfNeeded()
                let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
                guard contentHeight.isFinite, contentHeight > 0 else { return }
                guard abs(height.wrappedValue - contentHeight) > 1 else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.height.wrappedValue = contentHeight.rounded(.up)
                }
            }
        }
    }
#endif
