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

    private var decodedPlayer: AVAudioPlayer?
    private var streamingPlayer: AudioPlayer?
    private var progressTimer: Timer?
    private var playbackToken = UUID()

    var canSeek: Bool {
        if let decodedPlayer {
            return decodedPlayer.duration.isFinite && decodedPlayer.duration > 0
        }
        guard let duration = streamingPlayer?.duration else { return false }
        return duration.isFinite && duration > 0
    }

    var duration: TimeInterval? {
        if let decodedPlayer, decodedPlayer.duration.isFinite, decodedPlayer.duration > 0 {
            return decodedPlayer.duration
        }
        if let duration = streamingPlayer?.duration, duration.isFinite, duration > 0 {
            return duration
        }
        return nil
    }

    var currentTime: TimeInterval {
        if let decodedPlayer {
            return min(max(decodedPlayer.currentTime, 0), decodedPlayer.duration)
        }
        guard let streamingPlayer, let duration, duration > 0 else {
            return 0
        }
        return min(max(streamingPlayer.progress, 0), duration)
    }

    deinit {
        progressTimer?.invalidate()
        decodedPlayer?.delegate = nil
        decodedPlayer?.stop()
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
                let decodedURL = try Self.decodedAudioFileURL(for: localURL)
                await MainActor.run { [weak self] in
                    self?.startDecodedPlayback(decodedURL: decodedURL, originalURL: localURL, token: token)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.startStreamingPlayback(localURL: localURL, token: token)
                }
            }
        }
    }

    func pause() {
        if let decodedPlayer {
            decodedPlayer.pause()
        } else {
            streamingPlayer?.pause()
        }
        stopProgressTimer()
        onEvent?(.paused)
    }

    func resume() {
        if let decodedPlayer {
            decodedPlayer.play()
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
        let clampedProgress = min(max(progressFraction, 0), 1)
        if let decodedPlayer, decodedPlayer.duration.isFinite, decodedPlayer.duration > 0 {
            decodedPlayer.currentTime = decodedPlayer.duration * clampedProgress
            onEvent?(.progress(clampedProgress))
            return
        }
        guard let player = streamingPlayer, player.duration.isFinite, player.duration > 0 else {
            return
        }
        player.seek(to: player.duration * clampedProgress)
        onEvent?(.progress(clampedProgress))
    }

    private func stopCurrentPlayer() {
        let oldDecodedPlayer = decodedPlayer
        decodedPlayer = nil
        oldDecodedPlayer?.delegate = nil
        oldDecodedPlayer?.stop()

        let oldStreamingPlayer = streamingPlayer
        streamingPlayer = nil
        oldStreamingPlayer?.delegate = nil
        oldStreamingPlayer?.stop()
    }

    private func startDecodedPlayback(decodedURL: URL, originalURL: URL, token: UUID) {
        guard token == playbackToken else { return }
        stopCurrentPlayer()

        do {
            let nextPlayer = try AVAudioPlayer(contentsOf: decodedURL)
            nextPlayer.volume = 1
            nextPlayer.delegate = self
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                startStreamingPlayback(localURL: originalURL, token: token)
                return
            }
            decodedPlayer = nextPlayer
            onEvent?(.ready)
            startProgressTimer()
            onEvent?(.playing)
        } catch {
            startStreamingPlayback(localURL: originalURL, token: token)
        }
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
        if let decodedPlayer {
            guard decodedPlayer.duration > 0 else {
                onEvent?(.progress(0))
                return
            }
            onEvent?(.progress(decodedPlayer.currentTime / decodedPlayer.duration))
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

    private func emitEnd(for callbackPlayer: AVAudioPlayer, successfully flag: Bool) {
        guard let currentPlayer = decodedPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        decodedPlayer = nil
        if flag {
            onEvent?(.ended)
        } else {
            onEvent?(.failed(String(localized: "ba.student.detail.voice.error.playback")))
        }
    }

    private func emitFailure(for callbackPlayer: AVAudioPlayer) {
        guard let currentPlayer = decodedPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        decodedPlayer = nil
        onEvent?(.failed(String(localized: "ba.student.detail.voice.error.playback")))
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

private extension BaOggAudioPlayer {
    nonisolated static func decodedAudioFileURL(for localURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let directory = try decodedAudioCacheDirectory(fileManager: fileManager)
        let cacheURL = directory.appendingPathComponent("\(decodedAudioCacheKey(for: localURL)).caf")

        if isUsableAudioFile(cacheURL, fileManager: fileManager) {
            return cacheURL
        }

        let decoded = try BaOggVorbisDecoder().decode(localURL: localURL)
        let scratchURL = directory.appendingPathComponent("\(cacheURL.deletingPathExtension().lastPathComponent).\(UUID().uuidString).caf")

        do {
            let outputFile = try AVAudioFile(forWriting: scratchURL, settings: decoded.buffer.format.settings)
            try outputFile.write(from: decoded.buffer)
            try? fileManager.removeItem(at: cacheURL)
            try fileManager.moveItem(at: scratchURL, to: cacheURL)
            return cacheURL
        } catch {
            try? fileManager.removeItem(at: scratchURL)
            throw error
        }
    }

    private nonisolated static func decodedAudioCacheDirectory(fileManager: FileManager) throws -> URL {
        let baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directory = baseURL.appendingPathComponent("KeiBAOSDecodedOggAudio", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private nonisolated static func isUsableAudioFile(_ url: URL, fileManager: FileManager) -> Bool {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber
        else {
            return false
        }
        return size.intValue > 44
    }

    private nonisolated static func decodedAudioCacheKey(for localURL: URL) -> String {
        var descriptor = localURL.resolvingSymlinksInPath().path
        if let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path) {
            descriptor += ":\(String(describing: attributes[.size]))"
            descriptor += ":\((attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0)"
        }

        let stem = safeFileStem(localURL.deletingPathExtension().lastPathComponent)
        return "\(stem)-\(fnv1aHash(descriptor))"
    }

    private nonisolated static func safeFileStem(_ value: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let mapped = String(value.map { allowed.contains($0) ? $0 : "-" })
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let fallback = mapped.isEmpty ? "ogg-audio" : mapped
        return String(fallback.prefix(48))
    }

    private nonisolated static func fnv1aHash(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}

extension BaOggAudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self, weak player] in
            guard let player else { return }
            self?.emitEnd(for: player, successfully: flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error _: (any Error)?) {
        Task { @MainActor [weak self, weak player] in
            guard let player else { return }
            self?.emitFailure(for: player)
        }
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
