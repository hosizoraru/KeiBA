//
//  BaMusicNowPlayingViews.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

struct BaMusicMiniNowPlayingBar: View {
    let session: BaMusicPlaybackSession

    var body: some View {
        if let track = session.selectedTrack {
            HStack(spacing: 11) {
                Button {
                    session.isExpanded = true
                } label: {
                    HStack(spacing: 11) {
                        BaRowThumbnail(
                            url: track.artworkURL,
                            fallbackSystemImage: "music.note",
                            tint: BaDesign.pink,
                            size: 42,
                            maxPixelDimension: 160,
                            usesGlassSurface: false
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Text(track.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                if session.player.isPlaying {
                                    Image(systemName: "waveform")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(BaDesign.pink)
                                        .accessibilityHidden(true)
                                }
                            }

                            ProgressView(value: session.player.progress)
                                .progressViewStyle(.linear)
                                .tint(BaDesign.pink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Text(String(format: String(localized: "ba.music.mini.accessibility.format"), track.title)))

                Button {
                    session.toggleCurrent()
                } label: {
                    Image(systemName: session.player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline.weight(.semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(session.player.isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(cornerRadius: 22, tint: BaDesign.pink.opacity(0.08), isInteractive: true)
        }
    }
}

struct BaMusicNowPlayingHero: View {
    let track: BaMusicTrack?
    let session: BaMusicPlaybackSession
    let metrics: BaAdaptiveMetrics

    var body: some View {
        BaGlassCard(tint: BaDesign.pink) {
            if let track {
                heroContent(track)
            } else {
                placeholderContent
            }
        }
    }

    @ViewBuilder
    private func heroContent(_ track: BaMusicTrack) -> some View {
        if metrics.widthClass == .expanded {
            HStack(alignment: .center, spacing: 24) {
                artwork(track, size: artworkSize)
                trackInfo(track)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: 18) {
                artwork(track, size: artworkSize)
                    .frame(maxWidth: .infinity, alignment: .center)
                trackInfo(track)
            }
        }
    }

    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            BaSectionHeader(title: String(localized: "ba.music.nowPlaying.title"), systemImage: "music.quarternote.3")
            Text(String(localized: "ba.music.nowPlaying.placeholder.title"))
                .font(.title3.weight(.semibold))
            Text(String(localized: "ba.music.nowPlaying.placeholder.detail"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func artwork(_ track: BaMusicTrack, size: CGFloat) -> some View {
        BaRemoteImageSurface(
            url: track.artworkURL,
            fallbackSystemImage: "music.note",
            tint: BaDesign.pink,
            width: size,
            height: size,
            cornerRadius: 28,
            contentMode: .fit,
            fallbackFont: .system(size: 54, weight: .semibold),
            maxPixelDimension: metrics.detailImageMaxPixelDimension,
            usesGlassSurface: false
        )
        .shadow(color: BaDesign.pink.opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private func trackInfo(_ track: BaMusicTrack) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "ba.music.nowPlaying.title"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BaDesign.pink)
                    .textCase(.uppercase)

                Text(track.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(track.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            BaMusicProgressControl(session: session)

            HStack(spacing: 18) {
                Button {
                    session.playPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.borderless)
                .disabled(session.queue.count < 2)
                .accessibilityLabel(Text(String(localized: "ba.music.action.previous")))

                Button {
                    if track.isPlayable {
                        session.play(track)
                    }
                } label: {
                    Image(systemName: session.player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .disabled(track.isPlayable == false)
                .accessibilityLabel(Text(session.player.isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")))

                Button {
                    session.playNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.borderless)
                .disabled(session.queue.count < 2)
                .accessibilityLabel(Text(String(localized: "ba.music.action.next")))
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(BaDesign.pink)

            if let error = session.player.errorMessage, error.isEmpty == false {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var artworkSize: CGFloat {
        switch metrics.widthClass {
        case .compact:
            min(max(metrics.containerWidth - 96, 180), 260)
        case .regular:
            286
        case .expanded:
            320
        }
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
                            metrics: metrics
                        )

                        if session.queue.isEmpty == false {
                            BaMusicQueueSection(
                                title: String(localized: "ba.music.queue.title"),
                                tracks: session.queue,
                                thumbnailSize: metrics.catalogThumbnailSize,
                                thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
                                currentTrackID: session.selectedTrack?.id,
                                isPlaying: session.player.isPlaying,
                                onPrimaryAction: { session.play($0) },
                                onLoadDetail: { _ in }
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

    var body: some View {
        if session.player.canSeek {
            Slider(
                value: Binding(
                    get: { session.player.progress },
                    set: { session.player.seek(to: $0) }
                ),
                in: 0 ... 1
            )
            .tint(BaDesign.pink)
            .accessibilityLabel(Text(String(localized: "ba.music.progress.accessibility")))
        } else {
            ProgressView(value: session.player.progress)
                .progressViewStyle(.linear)
                .tint(BaDesign.pink)
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
