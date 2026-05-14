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

    private let player = AudioPlayer()
    private var progressTimer: Timer?

    override init() {
        super.init()
        player.delegate = self
    }

    deinit {
        progressTimer?.invalidate()
        player.stop()
    }

    func play(localURL: URL) {
        stopProgressTimer()
        onEvent?(.ready)
        player.stop()
        player.play(url: localURL)
        startProgressTimer()
    }

    func pause() {
        player.pause()
        stopProgressTimer()
        onEvent?(.paused)
    }

    func resume() {
        player.resume()
        startProgressTimer()
    }

    func stop() {
        stopProgressTimer()
        player.stop()
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
        let duration = player.duration
        guard duration > 0 else {
            onEvent?(.progress(0))
            return
        }
        onEvent?(.progress(player.progress / duration))
    }
}

extension BaOggVoicePlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player _: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self] in
            self?.onEvent?(.playing)
        }
    }

    nonisolated func audioPlayerDidFinishBuffering(player _: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self] in
            self?.onEvent?(.ready)
        }
    }

    nonisolated func audioPlayerStateChanged(
        player _: AudioPlayer,
        with newState: AudioPlayerState,
        previous _: AudioPlayerState
    ) {
        Task { @MainActor [weak self] in
            switch newState {
            case .playing:
                self?.onEvent?(.playing)
            case .paused:
                self?.onEvent?(.paused)
            case .stopped, .disposed:
                self?.onEvent?(.ended)
            case .error:
                self?.onEvent?(.failed(String(localized: "ba.student.detail.voice.error.playback")))
            default:
                break
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(
        player _: AudioPlayer,
        entryId _: AudioEntryId,
        stopReason _: AudioPlayerStopReason,
        progress _: Double,
        duration _: Double
    ) {
        Task { @MainActor [weak self] in
            self?.onEvent?(.ended)
        }
    }

    nonisolated func audioPlayerUnexpectedError(player _: AudioPlayer, error: AudioPlayerError) {
        Task { @MainActor [weak self] in
            self?.onEvent?(.failed(error.localizedDescription))
        }
    }

    nonisolated func audioPlayerDidCancel(player _: AudioPlayer, queuedItems _: [AudioEntryId]) {
        Task { @MainActor [weak self] in
            self?.onEvent?(.ended)
        }
    }

    nonisolated func audioPlayerDidReadMetadata(player _: AudioPlayer, metadata _: [String: String]) {}
}
