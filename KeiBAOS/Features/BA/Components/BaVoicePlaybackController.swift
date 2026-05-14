//
//  BaVoicePlaybackController.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class BaVoicePlaybackController {
    private nonisolated static let nativePlaybackExtensions = Set(
        "aac aif aifc aiff caf m4a m4b m4p mp3 mp4 wav".split(separator: " ").map(String.init)
    )

    var currentRemoteURL: URL?
    var isLoading = false
    var isPlaying = false
    var progress = 0.0
    var errorMessage: String?

    private let audioCache: BaAudioCache
    private var player: AVAudioPlayer?
    private var loadToken = UUID()
    private var progressTimer: Timer?

    init(audioCache: BaAudioCache = .shared) {
        self.audioCache = audioCache
    }

    nonisolated static func supportsNativePlayback(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ext.isEmpty == false else { return true }
        return nativePlaybackExtensions.contains(ext)
    }

    func toggle(remoteURL: URL) {
        guard Self.supportsNativePlayback(remoteURL) else {
            fail(message: String(localized: "ba.student.detail.voice.error.unsupported"))
            return
        }
        if currentRemoteURL == remoteURL {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }
        play(remoteURL: remoteURL)
    }

    func stop() {
        loadToken = UUID()
        tearDownPlayer()
        currentRemoteURL = nil
        isLoading = false
        isPlaying = false
        progress = 0
    }

    private func play(remoteURL: URL) {
        let token = UUID()
        loadToken = token
        tearDownPlayer()
        currentRemoteURL = remoteURL
        errorMessage = nil
        isLoading = true
        isPlaying = false
        progress = 0

        Task {
            do {
                let localURL = try await audioCache.localURL(for: remoteURL)
                guard loadToken == token, currentRemoteURL == remoteURL else { return }
                startPlayer(localURL: localURL)
            } catch {
                guard loadToken == token, currentRemoteURL == remoteURL else { return }
                fail(message: error.localizedDescription)
            }
        }
    }

    private func resume() {
        guard let player else { return }
        errorMessage = nil
        configureAudioSession()
        player.play()
        isPlaying = true
        startProgressTimer()
    }

    private func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    private func startPlayer(localURL: URL) {
        do {
            configureAudioSession()
            let nextPlayer = try AVAudioPlayer(contentsOf: localURL)
            nextPlayer.prepareToPlay()
            nextPlayer.play()
            player = nextPlayer
            isLoading = false
            isPlaying = true
            startProgressTimer()
        } catch {
            fail(message: String(localized: "ba.student.detail.voice.error.unsupported"))
        }
    }

    private func updateProgress() {
        guard let player else {
            progress = 0
            return
        }
        guard player.duration > 0 else {
            progress = 0
            return
        }
        progress = min(max(player.currentTime / player.duration, 0), 1)
        if player.isPlaying == false, player.currentTime >= player.duration {
            finishPlayback()
        }
    }

    private func finishPlayback() {
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        stopProgressTimer()
    }

    private func fail(message: String) {
        tearDownPlayer()
        isLoading = false
        isPlaying = false
        progress = 0
        errorMessage = message
    }

    private func tearDownPlayer() {
        stopProgressTimer()
        player?.stop()
        player = nil
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [])
            try? session.setActive(true)
        #endif
    }
}
