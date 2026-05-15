//
//  BaMediaPlaybackCoordinator.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import AVFoundation
import Foundation
import os

enum BaMediaPlaybackCoordinator {
    static let willStartPlaybackNotification = Notification.Name("BaMediaPlaybackCoordinatorWillStartPlayback")
    private static let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaMediaPlayback")
    private enum PlaybackMode {
        case audio
        case video
    }

    static func notifyWillStartPlayback(sender: AnyObject) {
        NotificationCenter.default.post(
            name: willStartPlaybackNotification,
            object: sender
        )
    }

    static func configurePrimaryPlaybackSession() {
        configureAudioPlaybackSession()
    }

    static func configureAudioPlaybackSession() {
        configurePlaybackSession(mode: .audio)
    }

    static func configureVideoPlaybackSession() {
        configurePlaybackSession(mode: .video)
    }

    private static func configurePlaybackSession(mode: PlaybackMode) {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let session = AVAudioSession.sharedInstance()
            let sessionMode: AVAudioSession.Mode = switch mode {
            case .audio:
                .default
            case .video:
                .moviePlayback
            }
            do {
                try session.setCategory(.playback, mode: sessionMode, options: [.allowAirPlay])
                try session.setActive(true)
            } catch {
                logger.error("audio session activation failed: \(error.localizedDescription, privacy: .public)")
            }
        #endif
    }
}
