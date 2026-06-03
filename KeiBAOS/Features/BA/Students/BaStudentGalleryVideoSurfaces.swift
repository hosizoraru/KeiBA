//
//  BaStudentGalleryVideoSurfaces.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import AVKit
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

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
        BaStudentGalleryVideoPosterSurface(
            previewURL: item.imageURL,
            height: resolvedLayout.height,
            cornerRadius: resolvedLayout.cornerRadius,
            maxPixelDimension: resolvedLayout.maxPixelDimension,
            contentPadding: resolvedLayout.contentPadding,
            isLoading: false
        )
        .frame(maxWidth: resolvedLayout.maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct BaStudentGalleryVideoPlayerScreen: View {
    @Environment(\.dismiss) private var dismiss

    let item: BaStudentGalleryPreviewItem

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar

                ZStack {
                    if let player {
                        BaPlatformVideoPlayer(player: player)
                    } else {
                        poster
                            .padding(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: item.mediaURL) {
            await loadVideo()
        }
        .alert(
            BaL10n.string("ba.student.detail.gallery.video.loadFailed"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )
        ) {
            Button(BaL10n.string("ba.common.done")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: BaMediaPlaybackCoordinator.willStartPlaybackNotification)) { notification in
            guard notification.object as AnyObject? !== player else { return }
            player?.pause()
        }
        .onDisappear {
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
    }

    private var poster: some View {
        VStack(spacing: 16) {
            BaStudentGalleryMediaSurface(
                url: item.previewURL,
                kind: .video,
                height: 260,
                cornerRadius: 24,
                maxPixelDimension: 1200,
                contentPadding: 0
            )
            .frame(maxWidth: 620)
            .overlay {
                BaGalleryVideoControlSurface(systemImage: "play.fill", isLoading: isLoading)
            }

            if item.detail.baGalleryIsBlank == false {
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 620)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                BaGalleryVideoToolbarIconSurface(systemImage: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(BaL10n.string("ba.common.done"))

            Spacer(minLength: 12)

            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 12)

            if let shareURL = item.mediaURL ?? item.previewURL {
                ShareLink(item: shareURL) {
                    BaGalleryVideoToolbarIconSurface(systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BaL10n.string("ba.action.share"))
            }

            BaGalleryMediaSaveButton(url: item.mediaURL ?? item.previewURL, title: item.title, tint: .white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.26))
                }
        }
    }

    @MainActor
    private func loadVideo() async {
        player?.pause()
        player = nil
        errorMessage = nil
        guard let mediaURL = item.mediaURL else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let nextPlayer: AVPlayer
            if BaMediaPlaybackSource.requiresRemotePlayback(mediaURL) {
                nextPlayer = AVPlayer(playerItem: BaMediaPlaybackSource.remotePlayerItem(for: mediaURL))
            } else {
                let localURL = try await BaGuideMediaCache.shared.localURL(for: mediaURL)
                nextPlayer = AVPlayer(url: localURL)
            }
            nextPlayer.isMuted = false
            nextPlayer.volume = 1
            BaMediaPlaybackCoordinator.configureVideoPlaybackSession()
            BaMediaPlaybackCoordinator.notifyWillStartPlayback(sender: nextPlayer)
            player = nextPlayer
            nextPlayer.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BaStudentGalleryVideoPosterSurface: View {
    let previewURL: URL?
    let height: CGFloat
    let cornerRadius: CGFloat
    let maxPixelDimension: Int
    let contentPadding: CGFloat
    let isLoading: Bool

    var body: some View {
        ZStack {
            BaStudentGalleryMediaSurface(
                url: previewURL,
                kind: .video,
                height: height,
                cornerRadius: cornerRadius,
                maxPixelDimension: maxPixelDimension,
                contentPadding: contentPadding
            )

            BaGalleryVideoControlSurface(systemImage: "play.fill", isLoading: isLoading)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

private struct BaGalleryVideoControlSurface: View {
    let systemImage: String
    let isLoading: Bool

    var body: some View {
        ZStack {
            controlBackground
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)

            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.white)
            } else {
                Image(systemName: systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .offset(x: systemImage == "play.fill" ? 2 : 0)
            }
        }
        .frame(width: 58, height: 58)
    }

    @ViewBuilder
    private var controlBackground: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular.tint(.white.opacity(0.12)).interactive(), in: Circle())
        } else {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .fill(.black.opacity(0.18))
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                }
        }
    }
}

private struct BaGalleryVideoToolbarIconSurface: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .contentShape(Circle())
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle()
                            .fill(.black.opacity(0.18))
                    }
            }
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
    }
}
