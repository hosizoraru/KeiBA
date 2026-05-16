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
    let onStop: () -> Void
    let onLoadDetail: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(isCurrent ? BaDesign.pink : Color.clear)
                .frame(width: 3, height: 36)

            BaRowThumbnail(
                url: track.artworkURL,
                fallbackSystemImage: "music.note",
                tint: BaDesign.pink,
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
                            .foregroundStyle(BaDesign.pink)
                            .accessibilityHidden(true)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        statusLabel
                        cacheStatusLabel
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        statusLabel
                        cacheStatusLabel
                    }
                }
            }

            Spacer(minLength: 8)

            trailingControl
            trackMenu

            NavigationLink {
                BaStudentDetailView(entry: track.entry)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 26, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(localized: "ba.music.action.openDetail")))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassSurface(
            cornerRadius: 18,
            tint: isCurrent ? BaDesign.pink.opacity(0.055) : Color.white.opacity(0.024),
            isInteractive: true
        )
    }

    @ViewBuilder
    private var trailingControl: some View {
        switch track.availability {
        case .ready:
            Button(action: onPrimaryAction) {
                Image(systemName: isCurrent && isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isCurrent ? BaDesign.pink : .primary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(BaMusicControlButtonStyle())
            .accessibilityLabel(Text(isCurrent && isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play")))
        case .loadingDetail:
            ProgressView()
                .controlSize(.small)
                .frame(width: 36, height: 36)
        case .needsDetail, .failed, .missing:
            Button(action: onLoadDetail) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(BaMusicControlButtonStyle())
            .accessibilityLabel(Text(String(localized: "ba.music.action.loadDetail")))
        }
    }

    private var trackMenu: some View {
        Menu {
            if track.availability == .ready {
                Button(action: onPrimaryAction) {
                    Label(
                        isCurrent && isPlaying ? String(localized: "ba.music.action.pause") : String(localized: "ba.music.action.play"),
                        systemImage: isCurrent && isPlaying ? "pause.fill" : "play.fill"
                    )
                }

                if isCurrent {
                    Button(action: onStop) {
                        Label(String(localized: "ba.music.action.stop"), systemImage: "stop.fill")
                    }
                }
            } else {
                Button(action: onLoadDetail) {
                    Label(String(localized: "ba.music.action.loadDetail"), systemImage: "arrow.clockwise")
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
        .accessibilityLabel(Text(String(localized: "ba.music.action.moreTrack")))
    }

    @ViewBuilder
    private var cacheMenuItems: some View {
        if track.audioURL == nil {
            unloadedCacheMenuItems
        } else if cacheState.isCached {
            Button(role: .destructive, action: onClearCache) {
                Label(String(localized: "ba.music.action.clearCache"), systemImage: "trash")
            }
        } else if cacheState.isCaching {
            Button {} label: {
                Label(String(localized: "ba.music.status.cache.caching"), systemImage: cacheState.systemImage)
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
                Label(String(localized: "ba.music.action.cache"), systemImage: "arrow.down.circle")
            }
        case .loadingDetail:
            Button {} label: {
                Label(String(localized: "ba.music.status.loading"), systemImage: "arrow.down.circle.dotted")
            }
            .disabled(true)
        case .ready, .missing:
            EmptyView()
        }
    }

    private var statusLabel: some View {
        Text(statusText)
            .font(.caption)
            .foregroundStyle(statusColor)
            .lineLimit(1)
    }

    @ViewBuilder
    private var cacheStatusLabel: some View {
        if let cacheStatusText = cacheState.statusText {
            Label(cacheStatusText, systemImage: cacheState.systemImage)
                .font(.caption)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(cacheState.isCached ? BaDesign.pink : .secondary)
                .lineLimit(1)
        }
    }

    private var statusText: String {
        switch track.availability {
        case .ready:
            track.galleryTitle.isEmpty ? track.subtitle : "\(track.subtitle) · \(track.galleryTitle)"
        case .needsDetail:
            String(localized: "ba.music.status.needsDetail")
        case .loadingDetail:
            String(localized: "ba.music.status.loading")
        case .missing:
            String(localized: "ba.music.status.missing")
        case let .failed(message):
            String(format: String(localized: "ba.music.status.failed.format"), message)
        }
    }

    private var statusColor: Color {
        switch track.availability {
        case .ready:
            isCurrent ? BaDesign.pink : .secondary
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
    let onStop: () -> Void
    let onCacheAll: ([BaMusicTrack]) -> Void
    let onClearAllCache: ([BaMusicTrack]) -> Void
    let onLoadDetail: (BaMusicTrack) -> Void
    let onRefreshCacheState: (BaMusicTrack) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                BaSectionHeader(title: title, systemImage: "music.note.list")

                Spacer(minLength: 8)

                Button {
                    onCacheAll(tracks)
                } label: {
                    ViewThatFits(in: .horizontal) {
                        Label(String(localized: "ba.music.action.cacheAll"), systemImage: "arrow.down.circle")
                            .labelStyle(.titleAndIcon)

                        Image(systemName: "arrow.down.circle")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(BaMusicControlButtonStyle())
                .font(.caption.weight(.semibold))
                .disabled(hasCacheableTracks == false)
                .accessibilityLabel(Text(String(localized: "ba.music.action.cacheAll")))

                Menu {
                    Button(role: .destructive) {
                        onClearAllCache(tracks)
                    } label: {
                        Label(String(localized: "ba.music.action.clearAllCache"), systemImage: "trash")
                    }
                    .disabled(hasCachedTracks == false)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(Text(String(localized: "ba.music.action.moreQueue")))
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
                        onStop: onStop,
                        onLoadDetail: { onLoadDetail(track) }
                    )
                    .task(id: track.id) {
                        if track.availability == .needsDetail {
                            onLoadDetail(track)
                        }
                        await onRefreshCacheState(track)
                    }
                }
            }
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
