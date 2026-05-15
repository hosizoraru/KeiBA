//
//  BaVoicePlaybackController.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import AVFoundation
import Foundation
import Observation
import os

@Observable
@MainActor
final class BaVoicePlaybackController {
    private nonisolated static let nativePlaybackExtensions = Set(
        "3gp 3gpp aac aif aifc aiff amr caf flac m4a m4b m4p mp3 mp4 wav".split(separator: " ")
            .map(String.init)
    )
    private nonisolated static let oggPlaybackExtensions = Set(
        "oga ogg opus".split(separator: " ").map(String.init)
    )
    private nonisolated static let vorbisEngineExtensions = Set(
        "oga ogg".split(separator: " ").map(String.init)
    )

    var currentRemoteURL: URL?
    var isLoading = false
    var isPlaying = false
    var progress = 0.0
    var errorMessage: String?

    private let audioCache: any BaAudioCaching
    @ObservationIgnored private let oggPlayer = BaOggVoicePlayer()
    @ObservationIgnored private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaVoicePlayback")
    private var player: AVAudioPlayer?
    private var playbackBackend: PlaybackBackend?
    private var loadToken = UUID()
    private var progressTimer: Timer?

    init(audioCache: any BaAudioCaching = BaAudioCache.shared) {
        self.audioCache = audioCache
        oggPlayer.onEvent = { [weak self] event in
            self?.handleOggEvent(event)
        }
    }

    nonisolated static func supportsNativePlayback(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ext.isEmpty == false else { return false }
        return nativePlaybackExtensions.contains(ext)
    }

    nonisolated static func supportsOggPlayback(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ext.isEmpty == false else { return false }
        return oggPlaybackExtensions.contains(ext)
    }

    nonisolated static func supportsPlayback(_ url: URL) -> Bool {
        supportsNativePlayback(url) ||
            supportsOggPlayback(url) ||
            looksLikeAudioSource(url)
    }

    func toggle(remoteURL: URL) {
        guard Self.supportsPlayback(remoteURL) else {
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
        stopOggPlayer()
        currentRemoteURL = nil
        isLoading = false
        isPlaying = false
        progress = 0
        playbackBackend = nil
    }

    private func play(remoteURL: URL) {
        let token = UUID()
        loadToken = token
        tearDownPlayer()
        stopOggPlayer()
        currentRemoteURL = remoteURL
        errorMessage = nil
        isLoading = true
        isPlaying = false
        progress = 0
        playbackBackend = Self.preferredBackend(for: remoteURL)

        Task {
            do {
                let localURL = try await audioCache.localURL(for: remoteURL, refererPath: "/ba")
                guard loadToken == token, currentRemoteURL == remoteURL else { return }
                startPlayer(localURL: localURL, backend: playbackBackend)
            } catch {
                guard loadToken == token, currentRemoteURL == remoteURL else { return }
                fail(message: error.localizedDescription)
            }
        }
    }

    private func resume() {
        errorMessage = nil
        if playbackBackend == .vorbisEngine || playbackBackend == .audioStreaming {
            resumeOggPlayer()
            return
        }
        guard let player else { return }
        configureAudioSession()
        player.play()
        isPlaying = true
        startProgressTimer()
    }

    private func pause() {
        if playbackBackend == .vorbisEngine || playbackBackend == .audioStreaming {
            pauseOggPlayer()
            isPlaying = false
            return
        }
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    private func startPlayer(localURL: URL, backend: PlaybackBackend?) {
        if backend == .vorbisEngine || backend == .audioStreaming {
            startOggPlayer(localURL: localURL)
            return
        }
        do {
            configureAudioSession()
            let nextPlayer = try AVAudioPlayer(contentsOf: localURL)
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                if isOggFile(localURL) {
                    playbackBackend = .audioStreaming
                    startOggPlayer(localURL: localURL)
                } else {
                    fail(message: String(localized: "ba.student.detail.voice.error.playback"))
                }
                return
            }
            player = nextPlayer
            isLoading = false
            isPlaying = true
            startProgressTimer()
        } catch {
            if isOggFile(localURL) {
                playbackBackend = .audioStreaming
                startOggPlayer(localURL: localURL)
            } else {
                fail(message: String(localized: "ba.student.detail.voice.error.unsupported"))
            }
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
        currentRemoteURL = nil
        isPlaying = false
        progress = 0
        playbackBackend = nil
        stopProgressTimer()
    }

    private func fail(message: String) {
        tearDownPlayer()
        stopOggPlayer()
        isLoading = false
        isPlaying = false
        progress = 0
        currentRemoteURL = nil
        playbackBackend = nil
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

    private enum PlaybackBackend: String {
        case avFoundation
        case vorbisEngine
        case audioStreaming
    }

    private nonisolated static func preferredBackend(for url: URL) -> PlaybackBackend {
        if vorbisEngineExtensions.contains(url.pathExtension.lowercased()) {
            return .vorbisEngine
        }
        return supportsOggPlayback(url) ? .audioStreaming : .avFoundation
    }

    nonisolated static func preferredBackendNameForTesting(_ url: URL) -> String {
        preferredBackend(for: url).rawValue
    }

    private nonisolated static func looksLikeAudioSource(_ url: URL) -> Bool {
        guard url.pathExtension.isEmpty else { return false }
        let path = url.path.lowercased()
        let query = url.query?.lowercased() ?? ""
        return path.contains("/voice/") ||
            path.contains("/audio/") ||
            query.contains("voice") ||
            query.contains("audio")
    }

    private func isOggFile(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 4) else { return false }
        return data.prefix(4).elementsEqual([0x4F, 0x67, 0x67, 0x53])
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [])
            try? session.setActive(true)
        #endif
    }
}

private extension BaVoicePlaybackController {
    func startOggPlayer(localURL: URL) {
        configureAudioSession()
        logger.debug("voice ogg local playback start")
        oggPlayer.play(localURL: localURL)
    }

    func pauseOggPlayer() {
        oggPlayer.pause()
    }

    func resumeOggPlayer() {
        configureAudioSession()
        oggPlayer.resume()
    }

    func stopOggPlayer() {
        oggPlayer.stop()
    }

    func handleOggEvent(_ event: BaOggVoiceEvent) {
        switch event {
        case .ready:
            isLoading = false
        case .playing:
            isLoading = false
            isPlaying = true
        case .paused:
            isPlaying = false
        case .ended:
            isLoading = false
            isPlaying = false
            progress = 0
            currentRemoteURL = nil
            playbackBackend = nil
        case let .progress(value):
            progress = min(max(value, 0), 1)
        case let .failed(message):
            fail(message: message.isEmpty ? String(localized: "ba.student.detail.voice.error.playback") : message)
        }
    }
}
