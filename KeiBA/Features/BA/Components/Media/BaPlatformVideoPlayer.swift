//
//  BaPlatformVideoPlayer.swift
//  KeiBA
//
//  Created by Codex on 2026/05/29.
//

import AVKit
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct BaPlatformVideoPlayer: View {
    let player: AVPlayer
    var showsControls = true
    var allowsPictureInPicture = true

    var body: some View {
        #if canImport(UIKit)
            BaPlatformVideoPlayerRepresentable(
                player: player,
                showsControls: showsControls,
                allowsPictureInPicture: allowsPictureInPicture
            )
        #elseif canImport(AppKit)
            BaPlatformVideoPlayerRepresentable(
                player: player,
                showsControls: showsControls
            )
        #else
            Color.black
        #endif
    }
}

#if canImport(UIKit)
    private struct BaPlatformVideoPlayerRepresentable: UIViewControllerRepresentable {
        let player: AVPlayer
        let showsControls: Bool
        let allowsPictureInPicture: Bool

        func makeUIViewController(context _: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            player.isMuted = false
            player.volume = 1
            controller.player = player
            controller.showsPlaybackControls = showsControls
            controller.allowsPictureInPicturePlayback = allowsPictureInPicture
            controller.canStartPictureInPictureAutomaticallyFromInline = allowsPictureInPicture
            controller.entersFullScreenWhenPlaybackBegins = false
            controller.exitsFullScreenWhenPlaybackEnds = false
            controller.videoGravity = .resizeAspect
            return controller
        }

        func updateUIViewController(_ controller: AVPlayerViewController, context _: Context) {
            player.isMuted = false
            player.volume = 1
            controller.player = player
        }

        static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
            controller.player?.pause()
            controller.player = nil
        }
    }
#elseif canImport(AppKit)
    private struct BaPlatformVideoPlayerRepresentable: NSViewRepresentable {
        let player: AVPlayer
        let showsControls: Bool

        func makeNSView(context _: Context) -> AVPlayerView {
            let view = AVPlayerView()
            view.controlsStyle = showsControls ? .floating : .none
            view.videoGravity = .resizeAspect
            player.isMuted = false
            player.volume = 1
            view.player = player
            return view
        }

        func updateNSView(_ nsView: AVPlayerView, context _: Context) {
            player.isMuted = false
            player.volume = 1
            nsView.player = player
        }

        static func dismantleNSView(_ nsView: AVPlayerView, coordinator: ()) {
            nsView.player?.pause()
            nsView.player = nil
        }
    }
#endif
