//
//  BaMusicNowPlayingViews.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

private enum BaMusicVisualToken {
    static let accent = BaDesign.pink
    static let compactControlSize: CGFloat = 42
    static let regularControlSize: CGFloat = 48
    static let primaryControlSize: CGFloat = 64
}

enum BaMusicNowPlayingPresentation {
    case inline
    case full
}

struct BaMusicMiniNowPlayingBar: View {
    let session: BaMusicPlaybackSession

    var body: some View {
        if let track = session.selectedTrack {
            HStack(spacing: 10) {
                Button {
                    session.isExpanded = true
                } label: {
                    HStack(spacing: 10) {
                        BaRowThumbnail(
                            url: track.artworkURL,
                            fallbackSystemImage: "music.note",
                            tint: BaMusicVisualToken.accent,
                            size: 38,
                            maxPixelDimension: 144,
                            usesGlassSurface: false
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(track.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                if session.player.isPlaying {
                                    Image(systemName: "waveform")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(BaMusicVisualToken.accent)
                                        .accessibilityHidden(true)
                                }
                            }

                            ProgressView(value: session.player.progress)
                                .progressViewStyle(.linear)
                                .tint(BaMusicVisualToken.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Text(String(format: String(localized: "ba.music.mini.accessibility.format"), track.title)))

                Button {
                    session.toggleCurrent()
                } label: {
                    Image(systemName: session.player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 38, height: 38)
                        .baMusicGlassCircle(isInteractive: true)
                }
                .buttonStyle(BaMusicControlButtonStyle())
                .accessibilityLabel(Text(session.player.isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")))

                Button {
                    session.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 38, height: 38)
                        .baMusicGlassCircle(isInteractive: true)
                }
                .buttonStyle(BaMusicControlButtonStyle())
                .disabled(session.queue.count < 2)
                .opacity(session.queue.count < 2 ? 0.42 : 1)
                .accessibilityLabel(Text(String(localized: "ba.music.action.next")))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .baMusicGlassSurface(cornerRadius: 24, isInteractive: true)
        }
    }
}

struct BaMusicNowPlayingHero: View {
    let track: BaMusicTrack?
    let session: BaMusicPlaybackSession
    let metrics: BaAdaptiveMetrics
    var presentation: BaMusicNowPlayingPresentation = .inline

    var body: some View {
        Group {
            if let track {
                heroContent(track)
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

    @ViewBuilder
    private func heroContent(_ track: BaMusicTrack) -> some View {
        if metrics.widthClass == .expanded {
            HStack(alignment: .center, spacing: 30) {
                artwork(track, size: artworkSize)

                VStack(spacing: 18) {
                    trackInfo(track)
                    BaMusicProgressControl(session: session, prefersSlider: prefersSlider)
                    BaMusicTransportControls(track: track, session: session)
                    playbackError
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            VStack(spacing: 18) {
                artwork(track, size: artworkSize)
                trackInfo(track)
                BaMusicProgressControl(session: session, prefersSlider: prefersSlider)
                BaMusicTransportControls(track: track, session: session)
                playbackError
            }
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title.weight(.semibold))
                .foregroundStyle(BaMusicVisualToken.accent)
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

    private func artwork(_ track: BaMusicTrack, size: CGFloat) -> some View {
        BaRemoteImageSurface(
            url: track.artworkURL,
            fallbackSystemImage: "music.note",
            tint: BaMusicVisualToken.accent,
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

    private func trackInfo(_ track: BaMusicTrack) -> some View {
        VStack(spacing: 6) {
            if showsPlayingLabel, session.selectedTrack?.id == track.id, session.player.isPlaying {
                Label(String(localized: "ba.music.nowPlaying.title"), systemImage: "waveform")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BaMusicVisualToken.accent)
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

            if track.galleryTitle.isEmpty == false {
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
                min(max(metrics.containerWidth - 154, 160), 210)
            case .full:
                min(max(metrics.containerWidth - 126, 172), 242)
            }
        case .regular:
            264
        case .expanded:
            300
        }
    }

    private var prefersSlider: Bool {
        presentation == .full || metrics.widthClass != .compact
    }

    private var showsPlayingLabel: Bool {
        presentation == .full || metrics.widthClass != .compact
    }
}

private struct BaMusicTransportControls: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let track: BaMusicTrack
    let session: BaMusicPlaybackSession

    var body: some View {
        GlassEffectContainer(spacing: transportSpacing) {
            ViewThatFits(in: .horizontal) {
                controlRow(scale: 1)
                controlRow(scale: 0.88)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func controlRow(scale: CGFloat) -> some View {
        HStack(spacing: transportSpacing * scale) {
            Group {
                BaMusicTransportButton(
                    systemImage: session.repeatMode.systemImage,
                    size: compactSize * scale,
                    isActive: session.repeatMode.isActive,
                    accessibilityLabel: session.repeatMode.accessibilityTitle
                ) {
                    session.cycleRepeatMode()
                }

                BaMusicTransportButton(
                    systemImage: "backward.fill",
                    size: regularSize * scale,
                    isDisabled: session.queue.count < 2,
                    accessibilityLabel: String(localized: "ba.music.action.previous")
                ) {
                    session.playPrevious()
                }

                BaMusicTransportButton(
                    systemImage: isCurrentPlaying ? "pause.fill" : "play.fill",
                    size: primarySize * scale,
                    fontSize: 24 * scale,
                    isProminent: true,
                    isDisabled: track.isPlayable == false,
                    accessibilityLabel: isCurrentPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")
                ) {
                    session.play(track)
                }

                BaMusicTransportButton(
                    systemImage: "forward.fill",
                    size: regularSize * scale,
                    isDisabled: session.queue.count < 2,
                    accessibilityLabel: String(localized: "ba.music.action.next")
                ) {
                    session.playNext()
                }

                BaMusicCacheButton(track: track, session: session, size: compactSize * scale)
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
                .baMusicGlassCircle(isInteractive: true)
                .overlay {
                    Circle()
                        .strokeBorder(foregroundStyle.opacity(isActive || isProminent ? 0.28 : 0), lineWidth: 1)
                }
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var foregroundStyle: Color {
        if isProminent || isActive {
            return BaMusicVisualToken.accent
        }
        return .primary
    }
}

private struct BaMusicCacheButton: View {
    let track: BaMusicTrack
    let session: BaMusicPlaybackSession
    let size: CGFloat

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
                        .foregroundStyle(state.isCached ? BaMusicVisualToken.accent : .primary)
                }
            }
            .frame(width: size, height: size)
            .baMusicGlassCircle(isInteractive: true)
            .overlay {
                Circle()
                    .strokeBorder(BaMusicVisualToken.accent.opacity(state.isCached ? 0.28 : 0), lineWidth: 1)
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

    func baMusicGlassCircle(isInteractive: Bool) -> some View {
        background(.clear, in: Circle())
            .glassEffect(isInteractive ? .clear.interactive() : .clear, in: Circle())
    }
}

struct BaMusicNowPlayingSheet: View {
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
                                onLoadDetail: { _ in },
                                onRefreshCacheState: session.refreshCacheState(for:)
                            )
                        }
                    }
                    .baAdaptiveReadableContent(maxWidth: metrics.dashboardContentMaxWidth)
                    .padding(.horizontal, metrics.screenHorizontalPadding)
                    .padding(.vertical, metrics.screenVerticalPadding)
                }
                .background(AppBackground())
            }
            .navigationTitle(String(localized: "ba.music.nowPlaying.title"))
            .platformInlineNavigationTitle()
        }
        .baMusicNowPlayingSheetStyle()
    }
}

private struct BaMusicProgressControl: View {
    let session: BaMusicPlaybackSession
    let prefersSlider: Bool
    @State private var editingProgress = 0.0
    @State private var isEditing = false

    var body: some View {
        if session.player.canSeek, prefersSlider {
            Slider(
                value: Binding(
                    get: { isEditing ? editingProgress : session.player.progress },
                    set: { editingProgress = $0 }
                ),
                in: 0 ... 1,
                onEditingChanged: handleEditingChanged
            )
            .tint(BaMusicVisualToken.accent)
            .accessibilityLabel(Text(String(localized: "ba.music.progress.accessibility")))
        } else {
            ProgressView(value: session.player.progress)
                .progressViewStyle(.linear)
                .tint(BaMusicVisualToken.accent)
        }
    }

    private func handleEditingChanged(_ editing: Bool) {
        if editing {
            editingProgress = session.player.progress
            isEditing = true
        } else {
            isEditing = false
            session.player.seek(to: editingProgress)
        }
    }
}

private extension View {
    @ViewBuilder
    func baMusicNowPlayingSheetStyle() -> some View {
        #if os(iOS)
            presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        #else
            frame(minWidth: 460, minHeight: 560)
        #endif
    }
}
