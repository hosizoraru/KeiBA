//
//  BaOggVoicePlayer.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import AudioStreaming
import AVFoundation
import Foundation

enum BaOggAudioEvent {
    case ready
    case playing
    case paused
    case ended
    case progress(Double)
    case failed(String)
}

enum BaOggPlaybackMode: String, Sendable {
    case decodedPreferred
    case streaming
}

@MainActor
final class BaOggAudioPlayer: NSObject {
    var onEvent: ((BaOggAudioEvent) -> Void)?

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var decodedAudio: BaDecodedOggAudio?
    private var streamingPlayer: AudioPlayer?
    private var progressTimer: Timer?
    private var playbackToken = UUID()

    var canSeek: Bool {
        guard let duration = streamingPlayer?.duration else { return false }
        return duration.isFinite && duration > 0
    }

    var duration: TimeInterval? {
        if let duration = streamingPlayer?.duration, duration.isFinite, duration > 0 {
            return duration
        }
        if let duration = decodedAudio?.duration, duration.isFinite, duration > 0 {
            return duration
        }
        return nil
    }

    var currentTime: TimeInterval {
        if let decodedAudio, let playerNode {
            return min(max(decodedElapsedTime(playerNode: playerNode), 0), decodedAudio.duration)
        }
        guard let streamingPlayer, let duration, duration > 0 else {
            return 0
        }
        return min(max(streamingPlayer.progress, 0), duration)
    }

    deinit {
        progressTimer?.invalidate()
        playerNode?.stop()
        engine?.stop()
        streamingPlayer?.delegate = nil
        streamingPlayer?.stop()
    }

    func play(localURL: URL, mode: BaOggPlaybackMode = .decodedPreferred) {
        stop()
        let token = UUID()
        playbackToken = token
        if mode == .streaming {
            startStreamingPlayback(localURL: localURL, token: token)
            return
        }
        Task.detached(priority: .userInitiated) { [localURL] in
            do {
                let decoded = try BaOggVorbisDecoder().decode(localURL: localURL)
                await MainActor.run { [weak self] in
                    self?.startDecodedPlayback(decoded, localURL: localURL, token: token)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.startStreamingPlayback(localURL: localURL, token: token)
                }
            }
        }
    }

    func pause() {
        if let playerNode {
            playerNode.pause()
        } else {
            streamingPlayer?.pause()
        }
        stopProgressTimer()
        onEvent?(.paused)
    }

    func resume() {
        if let playerNode {
            try? engine?.start()
            playerNode.play()
            startProgressTimer()
            onEvent?(.playing)
        } else {
            streamingPlayer?.resume()
        }
    }

    func stop() {
        playbackToken = UUID()
        stopProgressTimer()
        stopCurrentPlayer()
    }

    func seek(to progressFraction: Double) {
        guard let player = streamingPlayer, player.duration.isFinite, player.duration > 0 else {
            return
        }
        let clampedProgress = min(max(progressFraction, 0), 1)
        player.seek(to: player.duration * clampedProgress)
        onEvent?(.progress(clampedProgress))
    }

    private func stopCurrentPlayer() {
        playerNode?.stop()
        engine?.stop()
        engine?.reset()
        playerNode = nil
        engine = nil
        decodedAudio = nil

        let oldStreamingPlayer = streamingPlayer
        streamingPlayer = nil
        oldStreamingPlayer?.delegate = nil
        oldStreamingPlayer?.stop()
    }

    private func startDecodedPlayback(_ decoded: BaDecodedOggAudio, localURL: URL, token: UUID) {
        guard token == playbackToken else { return }
        stopCurrentPlayer()

        let nextEngine = AVAudioEngine()
        let nextNode = AVAudioPlayerNode()
        nextEngine.attach(nextNode)
        nextEngine.connect(nextNode, to: nextEngine.mainMixerNode, format: decoded.buffer.format)
        nextEngine.prepare()

        do {
            try nextEngine.start()
        } catch {
            startStreamingPlayback(localURL: localURL, token: token)
            return
        }

        engine = nextEngine
        playerNode = nextNode
        decodedAudio = decoded
        onEvent?(.ready)

        nextNode.scheduleBuffer(
            decoded.buffer,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finishDecodedPlayback(token: token)
            }
        }
        nextNode.play()
        startProgressTimer()
        onEvent?(.playing)
    }

    private func startStreamingPlayback(localURL: URL, token: UUID) {
        guard token == playbackToken else { return }
        stopCurrentPlayer()
        let nextPlayer = AudioPlayer()
        nextPlayer.volume = 1
        nextPlayer.rate = 1
        nextPlayer.delegate = self
        streamingPlayer = nextPlayer
        nextPlayer.play(url: localURL, headers: [:])
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
        if let decodedAudio, let playerNode {
            guard decodedAudio.duration > 0 else {
                onEvent?(.progress(0))
                return
            }
            let elapsed = decodedElapsedTime(playerNode: playerNode)
            onEvent?(.progress(elapsed / decodedAudio.duration))
            return
        }

        guard let player = streamingPlayer else {
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

    private func decodedElapsedTime(playerNode: AVAudioPlayerNode) -> TimeInterval {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              playerTime.sampleRate > 0
        else {
            return 0
        }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    private func finishDecodedPlayback(token: UUID) {
        guard token == playbackToken else { return }
        stopProgressTimer()
        playerNode?.stop()
        engine?.stop()
        engine?.reset()
        playerNode = nil
        engine = nil
        decodedAudio = nil
        onEvent?(.ended)
    }

    private func emitEnd(for callbackPlayer: AudioPlayer) {
        guard let currentPlayer = streamingPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        streamingPlayer = nil
        onEvent?(.ended)
    }

    private func emitFailure(_ message: String, for callbackPlayer: AudioPlayer) {
        guard let currentPlayer = streamingPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        streamingPlayer = nil
        onEvent?(.failed(message))
    }
}

extension BaOggAudioPlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player callbackPlayer: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
            self.startProgressTimer()
            self.onEvent?(.playing)
        }
    }

    nonisolated func audioPlayerDidFinishBuffering(player callbackPlayer: AudioPlayer, with _: AudioEntryId) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
            self.onEvent?(.ready)
        }
    }

    nonisolated func audioPlayerStateChanged(
        player callbackPlayer: AudioPlayer,
        with newState: AudioPlayerState,
        previous _: AudioPlayerState
    ) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
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
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
            self.emitEnd(for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerUnexpectedError(player callbackPlayer: AudioPlayer, error: AudioPlayerError) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
            self.emitFailure(error.localizedDescription, for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerDidCancel(player callbackPlayer: AudioPlayer, queuedItems _: [AudioEntryId]) {
        Task { @MainActor [weak self, weak callbackPlayer] in
            guard let self, let callbackPlayer, let currentPlayer = self.streamingPlayer, callbackPlayer === currentPlayer else { return }
            self.emitEnd(for: callbackPlayer)
        }
    }

    nonisolated func audioPlayerDidReadMetadata(player _: AudioPlayer, metadata _: [String: String]) {}
}

typealias BaOggVoiceEvent = BaOggAudioEvent
typealias BaOggVoicePlayer = BaOggAudioPlayer
