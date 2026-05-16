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
    let onPrimaryAction: () -> Void
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

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            trailingControl

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
            .buttonStyle(.borderless)
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
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(String(localized: "ba.music.action.loadDetail")))
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
    let onPrimaryAction: (BaMusicTrack) -> Void
    let onLoadDetail: (BaMusicTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BaSectionHeader(title: title, systemImage: "music.note.list")

            LazyVStack(spacing: 10) {
                ForEach(tracks) { track in
                    BaMusicTrackRow(
                        track: track,
                        thumbnailSize: thumbnailSize,
                        thumbnailMaxPixelDimension: thumbnailMaxPixelDimension,
                        isCurrent: currentTrackID == track.id,
                        isPlaying: isPlaying,
                        onPrimaryAction: { onPrimaryAction(track) },
                        onLoadDetail: { onLoadDetail(track) }
                    )
                    .task(id: track.id) {
                        if track.availability == .needsDetail {
                            onLoadDetail(track)
                        }
                    }
                }
            }
        }
    }
}
