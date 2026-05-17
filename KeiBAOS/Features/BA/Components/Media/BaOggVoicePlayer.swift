//
//  BaOggVoicePlayer.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

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
}

@MainActor
final class BaOggAudioPlayer: NSObject {
    var onEvent: ((BaOggAudioEvent) -> Void)?
    var progressUpdateInterval: TimeInterval = 0.25

    private var decodedPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var playbackToken = UUID()

    var canSeek: Bool {
        if let decodedPlayer {
            return decodedPlayer.duration.isFinite && decodedPlayer.duration > 0
        }
        return false
    }

    var duration: TimeInterval? {
        if let decodedPlayer, decodedPlayer.duration.isFinite, decodedPlayer.duration > 0 {
            return decodedPlayer.duration
        }
        return nil
    }

    var currentTime: TimeInterval {
        if let decodedPlayer {
            return min(max(decodedPlayer.currentTime, 0), decodedPlayer.duration)
        }
        return 0
    }

    deinit {
        progressTimer?.invalidate()
        decodedPlayer?.delegate = nil
        decodedPlayer?.stop()
    }

    func play(localURL: URL, mode _: BaOggPlaybackMode = .decodedPreferred) {
        stop()
        let token = UUID()
        playbackToken = token

        Task.detached(priority: .userInitiated) { [localURL] in
            do {
                let decodedURL = try Self.decodedAudioFileURL(for: localURL)
                await MainActor.run { [weak self] in
                    self?.startDecodedPlayback(decodedURL: decodedURL, token: token)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, token == self.playbackToken else { return }
                    self.onEvent?(.failed(BaL10n.string("ba.student.detail.voice.error.unsupported")))
                }
            }
        }
    }

    func pause() {
        if let decodedPlayer {
            decodedPlayer.pause()
        }
        stopProgressTimer()
        onEvent?(.paused)
    }

    func resume() {
        if let decodedPlayer {
            decodedPlayer.play()
            startProgressTimer()
            onEvent?(.playing)
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
        }
    }

    private func stopCurrentPlayer() {
        let oldDecodedPlayer = decodedPlayer
        decodedPlayer = nil
        oldDecodedPlayer?.delegate = nil
        oldDecodedPlayer?.stop()
    }

    private func startDecodedPlayback(decodedURL: URL, token: UUID) {
        guard token == playbackToken else { return }
        stopCurrentPlayer()

        do {
            let nextPlayer = try AVAudioPlayer(contentsOf: decodedURL)
            nextPlayer.volume = 1
            nextPlayer.delegate = self
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                onEvent?(.failed(BaL10n.string("ba.student.detail.voice.error.playback")))
                return
            }
            decodedPlayer = nextPlayer
            onEvent?(.ready)
            startProgressTimer()
            onEvent?(.playing)
        } catch {
            onEvent?(.failed(BaL10n.string("ba.student.detail.voice.error.playback")))
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        let interval = max(progressUpdateInterval, 0.1)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateProgress()
            }
        }
        timer.tolerance = interval * 0.35
        progressTimer = timer
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

        onEvent?(.progress(0))
    }

    private func emitEnd(for callbackPlayer: AVAudioPlayer, successfully flag: Bool) {
        guard let currentPlayer = decodedPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        decodedPlayer = nil
        if flag {
            onEvent?(.ended)
        } else {
            onEvent?(.failed(BaL10n.string("ba.student.detail.voice.error.playback")))
        }
    }

    private func emitFailure(for callbackPlayer: AVAudioPlayer) {
        guard let currentPlayer = decodedPlayer, callbackPlayer === currentPlayer else { return }
        stopProgressTimer()
        callbackPlayer.delegate = nil
        decodedPlayer = nil
        onEvent?(.failed(BaL10n.string("ba.student.detail.voice.error.playback")))
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

extension BaOggAudioPlayer {
    nonisolated static func removeDecodedAudioFile(forCachedAudioURL localURL: URL) {
        let fileManager = FileManager.default
        guard let directory = try? decodedAudioCacheDirectory(fileManager: fileManager) else { return }
        let cacheURL = directory.appendingPathComponent("\(decodedAudioCacheKey(for: localURL)).caf")
        try? fileManager.removeItem(at: cacheURL)
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

typealias BaOggVoiceEvent = BaOggAudioEvent
typealias BaOggVoicePlayer = BaOggAudioPlayer
