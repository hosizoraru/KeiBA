//
//  BaMusicTrackViews.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import SwiftUI

struct BaMusicTrackRow: View {
    let track: BaMusicTrack
    let thumbnailSize: CGFloat
    let thumbnailMaxPixelDimension: Int
    let isCurrent: Bool
    let isPlaying: Bool
    let cacheState: BaMusicCacheState
    let onPrimaryAction: () -> Void
    let onCache: () -> Void
    let onClearCache: () -> Void
    let onLoadDetail: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        BaMusicAccentReader(track: accentSourceTrack) { accent in
            HStack(spacing: 12) {
                Button(action: onPrimaryAction) {
                    rowContent(accent: accent)
                }
                .buttonStyle(.plain)

                trackMenu
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(
                cornerRadius: 18,
                tint: isCurrent ? accent.opacity(0.065) : Color.white.opacity(0.024),
                isInteractive: true
            )
        }
        .id(track.id)
    }

    private var accentSourceTrack: BaMusicTrack? {
        if isCurrent || BaPlatformPerformanceProfile.musicSamplesRowAvatarAccent {
            return track
        }
        return nil
    }

    private func rowContent(accent: Color) -> some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(isCurrent ? accent : Color.clear)
                .frame(width: 3, height: 36)

            BaRowThumbnail(
                url: track.artworkURL,
                fallbackSystemImage: "music.note",
                tint: accent,
                size: thumbnailSize,
                maxPixelDimension: thumbnailMaxPixelDimension,
                usesGlassSurface: false
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isCurrent {
                        Image(systemName: "waveform")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                            .accessibilityHidden(true)
                    }
                }

                secondaryContent(accent: accent)
            }

            Spacer(minLength: 8)

            if track.availability == .loadingDetail {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func secondaryContent(accent: Color) -> some View {
        switch track.availability {
        case .ready:
            cacheStatusLabel(accent: accent)
        case .needsDetail, .failed, .missing:
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    statusLabel(accent: accent)
                    cacheStatusLabel(accent: accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    statusLabel(accent: accent)
                    cacheStatusLabel(accent: accent)
                }
            }
        case .loadingDetail:
            statusLabel(accent: accent)
        }
    }

    private var trackMenu: some View {
        Menu {
            Button(action: onOpenDetail) {
                Label(BaL10n.string("ba.music.action.openDetail"), systemImage: "person.crop.circle")
            }

            if track.availability == .ready {
                Button(action: onPrimaryAction) {
                    Label(
                        isCurrent && isPlaying ? BaL10n.string("ba.music.action.pause") : BaL10n.string("ba.music.action.play"),
                        systemImage: isCurrent && isPlaying ? "pause.fill" : "play.fill"
                    )
                }
            } else {
                Button(action: onLoadDetail) {
                    Label(BaL10n.string("ba.music.action.loadDetail"), systemImage: "arrow.clockwise")
                }
            }

            cacheMenuItems
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(BaMusicControlButtonStyle())
        .accessibilityLabel(Text(BaL10n.string("ba.music.action.moreTrack")))
    }

    @ViewBuilder
    private var cacheMenuItems: some View {
        if track.audioURL == nil {
            unloadedCacheMenuItems
        } else if cacheState.isCached {
            Button(role: .destructive, action: onClearCache) {
                Label(BaL10n.string("ba.music.action.clearCache"), systemImage: "trash")
            }
        } else if cacheState.isCaching {
            Button {} label: {
                Label(BaL10n.string("ba.music.status.cache.caching"), systemImage: cacheState.systemImage)
            }
            .disabled(true)
        } else {
            Button(action: onCache) {
                Label(cacheState.accessibilityTitle, systemImage: cacheState.systemImage)
            }
        }
    }

    @ViewBuilder
    private var unloadedCacheMenuItems: some View {
        switch track.availability {
        case .needsDetail, .failed:
            Button(action: onCache) {
                Label(BaL10n.string("ba.music.action.cache"), systemImage: "arrow.down.circle")
            }
        case .loadingDetail:
            Button {} label: {
                Label(BaL10n.string("ba.music.status.loading"), systemImage: "arrow.down.circle.dotted")
            }
            .disabled(true)
        case .ready, .missing:
            EmptyView()
        }
    }

    private func statusLabel(accent: Color) -> some View {
        Text(statusText)
            .font(.caption)
            .foregroundStyle(statusColor(accent: accent))
            .lineLimit(1)
    }

    @ViewBuilder
    private func cacheStatusLabel(accent: Color) -> some View {
        if let cacheStatusText = visibleCacheStatusText {
            Label(cacheStatusText, systemImage: cacheState.systemImage)
                .font(.caption)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(cacheState.isCached ? accent : .secondary)
                .lineLimit(1)
        }
    }

    private var visibleCacheStatusText: String? {
        switch cacheState {
        case .cached, .caching, .failed:
            cacheState.statusText
        case .unknown, .notCached:
            nil
        }
    }

    private var statusText: String {
        switch track.availability {
        case .ready:
            ""
        case .needsDetail:
            BaL10n.string("ba.music.status.needsDetail")
        case .loadingDetail:
            BaL10n.string("ba.music.status.loading")
        case .missing:
            BaL10n.string("ba.music.status.missing")
        case let .failed(message):
            String(format: BaL10n.string("ba.music.status.failed.format"), message)
        }
    }

    private func statusColor(accent: Color) -> Color {
        switch track.availability {
        case .ready:
            isCurrent ? accent : .secondary
        case .failed, .missing:
            .orange
        case .needsDetail, .loadingDetail:
            .secondary
        }
    }
}

struct BaMusicQueueSection: View {
    let title: String
    let tracks: [BaMusicTrack]
    let thumbnailSize: CGFloat
    let thumbnailMaxPixelDimension: Int
    let currentTrackID: Int64?
    let isPlaying: Bool
    let cacheState: (BaMusicTrack) -> BaMusicCacheState
    let onPrimaryAction: (BaMusicTrack) -> Void
    let onCache: (BaMusicTrack) -> Void
    let onClearCache: (BaMusicTrack) -> Void
    let onCacheAll: ([BaMusicTrack]) -> Void
    let onClearAllCache: ([BaMusicTrack]) -> Void
    let onLoadDetail: (BaMusicTrack) -> Void
    let onRefreshCacheState: (BaMusicTrack) async -> Void

    @State private var selectedDetailEntry: BaGuideCatalogEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                BaSectionHeader(title: title, systemImage: "music.note.list")

                Spacer(minLength: 8)

                Button {
                    onCacheAll(tracks)
                } label: {
                    ViewThatFits(in: .horizontal) {
                        Label(BaL10n.string("ba.music.action.cacheAll"), systemImage: "arrow.down.circle")
                            .labelStyle(.titleAndIcon)

                        Image(systemName: "arrow.down.circle")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(BaMusicControlButtonStyle())
                .font(.caption.weight(.semibold))
                .disabled(hasCacheableTracks == false)
                .accessibilityLabel(Text(BaL10n.string("ba.music.action.cacheAll")))

                Menu {
                    Button(role: .destructive) {
                        onClearAllCache(tracks)
                    } label: {
                        Label(BaL10n.string("ba.music.action.clearAllCache"), systemImage: "trash")
                    }
                    .disabled(hasCachedTracks == false)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(Text(BaL10n.string("ba.music.action.moreQueue")))
            }

            LazyVStack(spacing: 10) {
                ForEach(tracks) { track in
                    let state = cacheState(track)
                    BaMusicTrackRow(
                        track: track,
                        thumbnailSize: thumbnailSize,
                        thumbnailMaxPixelDimension: thumbnailMaxPixelDimension,
                        isCurrent: currentTrackID == track.id,
                        isPlaying: isPlaying,
                        cacheState: state,
                        onPrimaryAction: { onPrimaryAction(track) },
                        onCache: { onCache(track) },
                        onClearCache: { onClearCache(track) },
                        onLoadDetail: { onLoadDetail(track) },
                        onOpenDetail: { selectedDetailEntry = track.entry }
                    )
                    .task(id: track.id) {
                        await onRefreshCacheState(track)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedDetailEntry) { entry in
            BaStudentDetailView(entry: entry)
        }
    }

    private var hasCacheableTracks: Bool {
        tracks.contains { track in
            canStartCache(track)
        }
    }

    private var hasCachedTracks: Bool {
        tracks.contains { track in
            cacheState(track).isCached
        }
    }

    private func canStartCache(_ track: BaMusicTrack) -> Bool {
        if track.audioURL != nil {
            return cacheState(track).canStartCaching
        }
        switch track.availability {
        case .needsDetail, .failed:
            return true
        case .loadingDetail, .ready, .missing:
            return false
        }
    }
}
