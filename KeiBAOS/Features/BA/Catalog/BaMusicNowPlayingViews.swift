//
//  BaMusicNowPlayingViews.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

private enum BaMusicVisualToken {
    static let compactControlSize: CGFloat = 42
    static let regularControlSize: CGFloat = 48
    static let primaryControlSize: CGFloat = 64
}

enum BaMusicNowPlayingPresentation {
    case inline
    case full
}

nonisolated enum BaMusicMiniNowPlayingDisplayMode: Hashable {
    case mini
    case expanded

    static func resolved(prefersExpanded: Bool, systemPlacementIsExpanded: Bool) -> Self {
        prefersExpanded && systemPlacementIsExpanded ? .expanded : .mini
    }
}

struct BaMusicMiniNowPlayingBar: View {
    let session: BaMusicPlaybackSession
    var prefersExpanded = true

    #if os(iOS)
        @Environment(\.tabViewBottomAccessoryPlacement) private var accessoryPlacement
    #endif

    var body: some View {
        if let track = session.selectedTrack {
            BaMusicAccentReader(track: track) { accent in
                switch displayMode {
                case .mini:
                    inlineContent(track, accent: accent)
                case .expanded:
                    expandedContent(track, accent: accent)
                }
            }
        }
    }

    private func inlineContent(_ track: BaMusicTrack, accent: Color) -> some View {
        HStack(spacing: 10) {
            miniTrackButton(track, accent: accent, showsSubtitle: false)

            miniPlayButton
            miniNextButton
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func expandedContent(_ track: BaMusicTrack, accent: Color) -> some View {
        HStack(spacing: 10) {
            miniTrackButton(track, accent: accent, showsSubtitle: true)

            miniPlayButton
            miniNextButton
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func miniTrackButton(_ track: BaMusicTrack, accent: Color, showsSubtitle: Bool) -> some View {
        Button {
            session.isExpanded = true
        } label: {
            HStack(spacing: 10) {
                BaRowThumbnail(
                    url: track.artworkURL,
                    fallbackSystemImage: "music.note",
                    tint: accent,
                    size: 38,
                    maxPixelDimension: 144,
                    usesGlassSurface: false
                )

                VStack(alignment: .leading, spacing: showsSubtitle ? 2 : 0) {
                    HStack(spacing: 6) {
                        Text(track.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if session.player.isPlaying {
                            Image(systemName: "waveform")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(accent)
                                .accessibilityHidden(true)
                        }
                    }

                    if showsSubtitle {
                        Text(track.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(Text(String(format: String(localized: "ba.music.mini.accessibility.format"), track.title)))
    }

    private var miniPlayButton: some View {
        Button {
            session.toggleCurrent()
        } label: {
            Image(systemName: session.player.isPlaying ? "pause.fill" : "play.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .accessibilityLabel(Text(session.player.isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")))
    }

    private var miniNextButton: some View {
        Button {
            session.playNext()
        } label: {
            Image(systemName: "forward.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .disabled(session.queue.count < 2)
        .opacity(session.queue.count < 2 ? 0.42 : 1)
        .accessibilityLabel(Text(String(localized: "ba.music.action.next")))
    }

    private var displayMode: BaMusicMiniNowPlayingDisplayMode {
        #if os(iOS)
            BaMusicMiniNowPlayingDisplayMode.resolved(
                prefersExpanded: prefersExpanded,
                systemPlacementIsExpanded: accessoryPlacement == .expanded
            )
        #else
            .expanded
        #endif
    }
}

struct BaMusicNowPlayingHero: View {
    let track: BaMusicTrack?
    let session: BaMusicPlaybackSession
    let metrics: BaAdaptiveMetrics
    var presentation: BaMusicNowPlayingPresentation = .inline

    var body: some View {
        BaMusicAccentReader(track: track) { accent in
            Group {
                if let track {
                    heroContent(track, accent: accent)
                } else {
                    placeholderContent
                }
            }
            .padding(metrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .center)
            .task(id: track?.audioURL?.absoluteString ?? "nil") {
                guard let track else { return }
                await session.refreshCacheState(for: track)
            }
        }
    }

    @ViewBuilder
    private func heroContent(_ track: BaMusicTrack, accent: Color) -> some View {
        if metrics.widthClass == .expanded {
            HStack(alignment: .center, spacing: 30) {
                artwork(track, accent: accent, size: artworkSize)

                VStack(spacing: 16) {
                    trackInfo(track, accent: accent)
                    BaMusicProgressControl(session: session, accent: accent)
                    BaMusicTransportControls(
                        track: track,
                        session: session,
                        accent: accent,
                        showsStop: true
                    )
                    playbackError
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            VStack(spacing: 14) {
                artwork(track, accent: accent, size: artworkSize)
                trackInfo(track, accent: accent)
                BaMusicProgressControl(session: session, accent: accent)
                BaMusicTransportControls(
                    track: track,
                    session: session,
                    accent: accent,
                    showsStop: true
                )
                playbackError
            }
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title.weight(.semibold))
                .foregroundStyle(BaMusicAccentPalette.fallback)
                .frame(width: 58, height: 58)
                .baMusicGlassSurface(cornerRadius: 18, isInteractive: false)

            Text(String(localized: "ba.music.nowPlaying.placeholder.title"))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(String(localized: "ba.music.nowPlaying.placeholder.detail"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }

    private func artwork(_ track: BaMusicTrack, accent: Color, size: CGFloat) -> some View {
        BaRemoteImageSurface(
            url: track.artworkURL,
            fallbackSystemImage: "music.note",
            tint: accent,
            width: size,
            height: size,
            cornerRadius: 26,
            contentMode: .fit,
            fallbackFont: .system(size: 52, weight: .semibold),
            maxPixelDimension: metrics.detailImageMaxPixelDimension,
            usesGlassSurface: false
        )
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 10)
    }

    private func trackInfo(_ track: BaMusicTrack, accent: Color) -> some View {
        VStack(spacing: 6) {
            if showsPlayingLabel, session.selectedTrack?.id == track.id, session.player.isPlaying {
                Label(String(localized: "ba.music.nowPlaying.title"), systemImage: "waveform")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .labelStyle(.titleAndIcon)
            }

            Text(track.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(track.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            if showsGalleryTitle, track.galleryTitle.isEmpty == false {
                Text(track.galleryTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var playbackError: some View {
        if let error = session.player.errorMessage, error.isEmpty == false {
            Label(error, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        }
    }

    private var artworkSize: CGFloat {
        switch metrics.widthClass {
        case .compact:
            switch presentation {
            case .inline:
                min(max(metrics.containerWidth * 0.46, 170), 208)
            case .full:
                min(max(metrics.containerWidth - 126, 172), 242)
            }
        case .regular:
            264
        case .expanded:
            300
        }
    }

    private var showsPlayingLabel: Bool {
        presentation == .full || metrics.widthClass != .compact
    }

    private var showsGalleryTitle: Bool {
        presentation == .full || metrics.widthClass != .compact
    }
}

private struct BaMusicTransportControls: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let track: BaMusicTrack
    let session: BaMusicPlaybackSession
    let accent: Color
    let showsStop: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            controlRow(scale: 1)
            controlRow(scale: 0.88)
            controlRow(scale: 0.78)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func controlRow(scale: CGFloat) -> some View {
        HStack(spacing: transportSpacing * scale) {
            Group {
                BaMusicTransportButton(
                    systemImage: session.repeatMode.systemImage,
                    size: compactSize * scale,
                    accent: accent,
                    isActive: session.repeatMode.isActive,
                    accessibilityLabel: session.repeatMode.accessibilityTitle
                ) {
                    session.cycleRepeatMode()
                }

                BaMusicTransportButton(
                    systemImage: "backward.fill",
                    size: regularSize * scale,
                    accent: accent,
                    isDisabled: session.canPlayPrevious == false,
                    accessibilityLabel: String(localized: "ba.music.action.previous")
                ) {
                    session.playPrevious()
                }

                BaMusicTransportButton(
                    systemImage: isCurrentPlaying ? "pause.fill" : "play.fill",
                    size: primarySize * scale,
                    fontSize: 24 * scale,
                    accent: accent,
                    isProminent: true,
                    isDisabled: track.isPlayable == false,
                    accessibilityLabel: isCurrentPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")
                ) {
                    session.play(track)
                }

                BaMusicTransportButton(
                    systemImage: "forward.fill",
                    size: regularSize * scale,
                    accent: accent,
                    isDisabled: session.queue.count < 2,
                    accessibilityLabel: String(localized: "ba.music.action.next")
                ) {
                    session.playNext()
                }

                if showsStop {
                    BaMusicTransportButton(
                        systemImage: "stop.fill",
                        size: compactSize * scale,
                        accent: accent,
                        isDisabled: session.hasCurrentTrack == false,
                        accessibilityLabel: String(localized: "ba.music.action.stop")
                    ) {
                        session.stop()
                    }
                }

                BaMusicCacheButton(track: track, session: session, size: compactSize * scale, accent: accent)
            }
        }
    }

    private var isCurrentPlaying: Bool {
        session.selectedTrack?.id == track.id && session.player.isPlaying
    }

    private var transportSpacing: CGFloat {
        metrics.widthClass == .compact ? 10 : 14
    }

    private var compactSize: CGFloat {
        metrics.widthClass == .compact ? 38 : BaMusicVisualToken.compactControlSize
    }

    private var regularSize: CGFloat {
        metrics.widthClass == .compact ? 44 : BaMusicVisualToken.regularControlSize
    }

    private var primarySize: CGFloat {
        metrics.widthClass == .compact ? 58 : BaMusicVisualToken.primaryControlSize
    }
}

private struct BaMusicTransportButton: View {
    let systemImage: String
    let size: CGFloat
    var fontSize: CGFloat = 18
    var accent: Color
    var isProminent = false
    var isActive = false
    var isDisabled = false
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(foregroundStyle)
                .frame(width: size, height: size)
                .contentShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(foregroundStyle.opacity(isActive ? 0.32 : 0), lineWidth: 1)
                }
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var foregroundStyle: Color {
        if isProminent || isActive {
            return accent
        }
        return .primary
    }
}

private struct BaMusicCacheButton: View {
    let track: BaMusicTrack
    let session: BaMusicPlaybackSession
    let size: CGFloat
    let accent: Color

    var body: some View {
        let state = session.cacheState(for: track)
        Button {
            if state.isCaching == false {
                session.cache(track)
            }
        } label: {
            ZStack {
                if state.isCaching {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: state.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(state.isCached ? accent : .primary)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(accent.opacity(state.isCached ? 0.28 : 0), lineWidth: 1)
            }
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .disabled(track.audioURL == nil || state.isCaching)
        .opacity(track.audioURL == nil ? 0.42 : 1)
        .accessibilityLabel(Text(state.accessibilityTitle))
    }
}

private extension View {
    func baMusicGlassSurface(cornerRadius: CGFloat, isInteractive: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(.clear, in: shape)
            .glassEffect(isInteractive ? .regular.interactive() : .regular, in: shape)
    }

}

struct BaMusicNowPlayingSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: BaMusicPlaybackSession

    var body: some View {
        NavigationStack {
            BaAdaptiveGeometry { metrics in
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                        BaMusicNowPlayingHero(
                            track: session.selectedTrack,
                            session: session,
                            metrics: metrics,
                            presentation: .full
                        )

                        if session.queue.isEmpty == false {
                            BaMusicQueueSection(
                                title: String(localized: "ba.music.queue.title"),
                                tracks: session.queue,
                                thumbnailSize: metrics.catalogThumbnailSize,
                                thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
                                currentTrackID: session.selectedTrack?.id,
                                isPlaying: session.player.isPlaying,
                                cacheState: session.cacheState(for:),
                                onPrimaryAction: { session.play($0) },
                                onCache: { session.cache($0) },
                                onClearCache: { session.clearCache(for: $0) },
                                onCacheAll: { session.cacheAll($0) },
                                onClearAllCache: { session.clearCachedTracks($0) },
                                onLoadDetail: { _ in },
                                onRefreshCacheState: session.refreshCacheState(for:)
                            )
                        }
                    }
                    .baAdaptiveReadableContent(maxWidth: metrics.dashboardContentMaxWidth)
                    .padding(.horizontal, metrics.screenHorizontalPadding)
                    .padding(.vertical, metrics.screenVerticalPadding)
                    .safeAreaPadding(.top, 10)
                    .safeAreaPadding(.bottom, 24)
                }
                .background(AppBackground())
            }
            .navigationTitle(String(localized: "ba.music.nowPlaying.title"))
            .platformInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.action.dismiss")) {
                        session.isExpanded = false
                        dismiss()
                    }
                }
            }
        }
        .baMusicNowPlayingSheetStyle()
    }
}

private struct BaMusicProgressControl: View {
    let session: BaMusicPlaybackSession
    let accent: Color
    @State private var editingProgress = 0.0
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { currentProgress },
                    set: { editingProgress = $0 }
                ),
                in: 0 ... 1,
                onEditingChanged: handleEditingChanged
            )
            .tint(accent)
            .accessibilityLabel(Text(String(localized: "ba.music.progress.accessibility")))
            .accessibilityValue(Text("\(elapsedText) / \(durationText)"))

            HStack {
                Text(elapsedText)

                Spacer(minLength: 12)

                Text(durationText)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
    }

    private func handleEditingChanged(_ editing: Bool) {
        if editing {
            editingProgress = session.player.progress
            isEditing = true
        } else {
            isEditing = false
            if session.player.canSeek {
                session.player.seek(to: editingProgress)
            } else {
                editingProgress = session.player.progress
            }
        }
    }

    private var currentProgress: Double {
        isEditing ? editingProgress : session.player.progress
    }

    private var elapsedText: String {
        if let duration = session.player.duration {
            return BaMusicPlaybackTimeFormatter.string(from: duration * currentProgress)
        }
        return BaMusicPlaybackTimeFormatter.string(from: session.player.currentTime)
    }

    private var durationText: String {
        guard let duration = session.player.duration else {
            return BaMusicPlaybackTimeFormatter.placeholder
        }
        return BaMusicPlaybackTimeFormatter.string(from: duration)
    }
}

nonisolated enum BaMusicPlaybackTimeFormatter {
    static let placeholder = "--:--"

    static func string(from seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return placeholder }
        let totalSeconds = Int(seconds.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(padded(seconds))"
    }

    private static func padded(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

private extension View {
    @ViewBuilder
    func baMusicNowPlayingSheetStyle() -> some View {
        #if os(iOS)
            presentationDetents([.large])
                .presentationDragIndicator(.visible)
        #else
            frame(minWidth: 460, minHeight: 560)
        #endif
    }
}
