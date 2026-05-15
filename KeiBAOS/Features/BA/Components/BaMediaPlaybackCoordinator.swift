//
//  BaMediaPlaybackCoordinator.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import AVFoundation
import Foundation

enum BaMediaPlaybackCoordinator {
    static let willStartPlaybackNotification = Notification.Name("BaMediaPlaybackCoordinatorWillStartPlayback")

    static func notifyWillStartPlayback(sender: AnyObject) {
        NotificationCenter.default.post(
            name: willStartPlaybackNotification,
            object: sender
        )
    }

    static func configurePrimaryPlaybackSession() {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .moviePlayback, options: [])
            try? session.setActive(true)
        #endif
    }
}
