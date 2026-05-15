//
//  BaOggVoicePlayer.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import AudioStreaming
import Foundation

enum BaOggVoiceEvent {
    case ready
    case playing
    case paused
    case ended
    case progress(Double)
    case failed(String)
}

@MainActor
final class BaOggVoicePlayer: NSObject {
    var onEvent: ((BaOggVoiceEvent) -> Void)?

    private var player: AudioPlayer?
    private var progressTimer: Timer?

    deinit {
        progressTimer?.invalidate()
        player?.delegate = nil
        player?.stop()
    }

    func play(localURL: URL) {
        play(url: localURL, headers: [:])
    }

    private func play(url: URL, headers: [String: String]) {
        stopProgressTimer()
        stopCurrentPlayer()
        let nextPlayer = AudioPlayer()
        nextPlayer.volume = 1
        nextPlayer.rate = 1
        nextPlayer.delegate = self
        player = nextPlayer
        nextPlayer.play(url: url, headers: headers)
    }

    func pause() {
        player?.pause()
        stopProgressTimer()
        onEvent?(.paused)
    }

    func resume() {
        player?.resume()
    }

    func stop() {
        stopProgressTimer()
        stopCurrentPlayer()
    }

    private func stopCurrentPlayer() {
        let oldPlayer = player
        player = nil
        oldPlayer?.delegate = nil
        oldPlayer?.stop()
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

    private func updateProgress() {
        guard let player else {
            onEvent?(.progress(0))
            return
        }
        let duration = player.duration
        guard duration > 0 else {
            onEvent?(.progress(0))
            return
        }
        onEvent?(.progress(player.progress / duration))
    }

    private func emitEnd(for callbackPlayer: AudioPlayer) {
        guard let currentPlayer = player, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        player = nil
        onEvent?(.ended)
    }

    private func emitFailure(_ message: String, for callbackPlayer: AudioPlayer) {
        guard let currentPlayer = player, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        player = nil
        onEvent?(.failed(message))
    }
}

extension BaOggVoicePlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player callbackPlayer: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            self.startProgressTimer()
            self.onEvent?(.playing)
        }
    }

    nonisolated func audioPlayerDidFinishBuffering(player callbackPlayer: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            self.onEvent?(.ready)
        }
    }

    nonisolated func audioPlayerStateChanged(
        player callbackPlayer: AudioPlayer,
        with newState: AudioPlayerState,
        previous _: AudioPlayerState
    ) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            switch newState {
            case .playing:
                self.startProgressTimer()
                self.onEvent?(.playing)
            case .paused:
                self.stopProgressTimer()
                self.onEvent?(.paused)
            case .stopped where callbackPlayer.stopReason == .eof:
                self.emitEnd(for: callbackPlayer)
            case .disposed:
                self.emitEnd(for: callbackPlayer)
            case .error:
                self.emitFailure(String(localized: "ba.student.detail.voice.error.playback"), for: callbackPlayer)
            default:
                break
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(
        player callbackPlayer: AudioPlayer,
        entryId _: AudioEntryId,
        stopReason _: AudioPlayerStopReason,
        progress _: Double,
        duration _: Double
    ) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            self.emitEnd(for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerUnexpectedError(player callbackPlayer: AudioPlayer, error: AudioPlayerError) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            self.emitFailure(error.localizedDescription, for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerDidCancel(player callbackPlayer: AudioPlayer, queuedItems _: [AudioEntryId]) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.player, callbackPlayer === currentPlayer else { return }
            self.emitEnd(for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerDidReadMetadata(player _: AudioPlayer, metadata _: [String: String]) {}
}
