//
//  BaVoicePlaybackController.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import AVFoundation
import Foundation
import Observation
import os

nonisolated enum BaAudioPlaybackProfile: Sendable {
    case voice
    case music

    var defaultOggPlaybackMode: BaOggPlaybackMode {
        switch self {
        case .voice:
            .decodedPreferred
        case .music:
            .decodedPreferred
        }
    }

    var progressUpdateInterval: TimeInterval {
        switch self {
        case .voice:
            0.25
        case .music:
            BaPlatformPerformanceProfile.musicProgressUpdateInterval
        }
    }
}

@Observable
@MainActor
final class BaAudioPlaybackController {
    private nonisolated static let nativePlaybackExtensions = Set(
        "3gp 3gpp aac aif aifc aiff amr caf flac m4a m4b m4p mp3 mp4 wav".split(separator: " ")
            .map(String.init)
    )
    private nonisolated static let decodedOggExtensions = Set(
        "oga ogg".split(separator: " ").map(String.init)
    )
    private nonisolated static let avPlayerPlaybackExtensions = Set(
        "m3u8 m4v mov mp4".split(separator: " ").map(String.init)
    )

    var currentRemoteURL: URL?
    var isLoading = false
    var isPlaying = false
    var progress = 0.0
    var errorMessage: String?
    @ObservationIgnored var onPlaybackFinished: (() -> Void)?
    @ObservationIgnored var onPlaybackStateChanged: (() -> Void)?

    var canSeek: Bool {
        switch playbackBackend {
        case .avFoundation:
            guard let duration = player?.duration else { return false }
            return duration.isFinite && duration > 0
        case .avPlayer:
            return avPlayerDuration?.isFinite == true && (avPlayerDuration ?? 0) > 0
        case .decodedOgg:
            return oggPlayer.canSeek
        case nil:
            return false
        }
    }

    var duration: TimeInterval? {
        switch playbackBackend {
        case .avFoundation:
            guard let duration = player?.duration, duration.isFinite, duration > 0 else { return nil }
            return duration
        case .avPlayer:
            return avPlayerDuration
        case .decodedOgg:
            return oggPlayer.duration
        case nil:
            return nil
        }
    }

    var currentTime: TimeInterval {
        switch playbackBackend {
        case .avFoundation:
            return player?.currentTime ?? 0
        case .avPlayer:
            return avPlayer?.currentTime().seconds ?? 0
        case .decodedOgg:
            return oggPlayer.currentTime
        case nil:
            guard let duration else { return 0 }
            return duration * progress
        }
    }

    private let audioCache: any BaAudioCaching
    @ObservationIgnored private let oggPlayer = BaOggAudioPlayer()
    @ObservationIgnored private let logger = Logger(subsystem: "os.kei.KeiBA", category: "BaVoicePlayback")
    @ObservationIgnored private lazy var audioPlayerDelegate = BaAudioPlayerDelegateProxy { [weak self] player, didFinishSuccessfully in
        self?.handleAudioPlayerDidFinish(player, successfully: didFinishSuccessfully)
    } onDecodeError: { [weak self] player in
        self?.handleAudioPlayerDecodeError(player)
    }
    @ObservationIgnored private var playbackObserver: NSObjectProtocol?
    @ObservationIgnored private var avPlayerEndObserver: NSObjectProtocol?
    private let playbackProfile: BaAudioPlaybackProfile
    private var player: AVAudioPlayer?
    private var avPlayer: AVPlayer?
    private var playbackBackend: PlaybackBackend?
    private var loadToken = UUID()
    private var progressTimer: Timer?
    private var avPlayerDuration: TimeInterval?

    init(audioCache: any BaAudioCaching = BaAudioCache.shared, profile: BaAudioPlaybackProfile = .voice) {
        self.audioCache = audioCache
        playbackProfile = profile
        oggPlayer.onEvent = { [weak self] event in
            self?.handleOggEvent(event)
        }
        playbackObserver = NotificationCenter.default.addObserver(
            forName: BaMediaPlaybackCoordinator.willStartPlaybackNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let senderID = (notification.object as AnyObject?).map(ObjectIdentifier.init)
            Task { @MainActor [weak self, senderID] in
                guard let self, senderID != ObjectIdentifier(self) else { return }
                self.stop()
            }
        }
    }

    deinit {
        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver)
        }
        if let avPlayerEndObserver {
            NotificationCenter.default.removeObserver(avPlayerEndObserver)
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
        return decodedOggExtensions.contains(ext)
    }

    nonisolated static func supportsPlayback(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty == false {
            return supportsNativePlayback(url) || supportsOggPlayback(url)
        }
        return looksLikeAudioSource(url)
    }

    func toggle(remoteURL: URL) {
        guard Self.supportsPlayback(remoteURL) else {
            fail(message: BaL10n.string("ba.student.detail.voice.error.unsupported"))
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
        notifyPlaybackStateChanged()
    }

    func seek(to progressFraction: Double) {
        let clampedProgress = min(max(progressFraction, 0), 1)
        progress = clampedProgress
        switch playbackBackend {
        case .avFoundation:
            guard let player, player.duration.isFinite, player.duration > 0 else { return }
            player.currentTime = player.duration * clampedProgress
            updateProgress()
        case .avPlayer:
            guard let duration = avPlayerDuration, duration.isFinite, duration > 0 else { return }
            avPlayer?.seek(to: CMTime(seconds: duration * clampedProgress, preferredTimescale: 600))
            updateProgress()
        case .decodedOgg:
            oggPlayer.seek(to: clampedProgress)
        case nil:
            break
        }
    }

    func play(remoteURL: URL) {
        BaMediaPlaybackCoordinator.notifyWillStartPlayback(sender: self)
        let token = UUID()
        loadToken = token
        tearDownPlayer()
        stopOggPlayer()
        currentRemoteURL = remoteURL
        errorMessage = nil
        isLoading = true
        isPlaying = false
        progress = 0
        playbackBackend = Self.preferredBackend(for: remoteURL, profile: playbackProfile)
        notifyPlaybackStateChanged()

        if playbackBackend == .avPlayer, BaMediaPlaybackSource.requiresRemotePlayback(remoteURL) {
            startAVPlayer(remoteURL: remoteURL)
            return
        }

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
        BaMediaPlaybackCoordinator.notifyWillStartPlayback(sender: self)
        errorMessage = nil
        if playbackBackend == .decodedOgg {
            resumeOggPlayer()
            return
        }
        if playbackBackend == .avPlayer {
            configureAudioSession()
            avPlayer?.play()
            isPlaying = true
            startProgressTimer()
            notifyPlaybackStateChanged()
            return
        }
        guard let player else { return }
        configureAudioSession()
        player.play()
        isPlaying = true
        startProgressTimer()
        notifyPlaybackStateChanged()
    }

    private func pause() {
        if playbackBackend == .decodedOgg {
            pauseOggPlayer()
            isPlaying = false
            notifyPlaybackStateChanged()
            return
        }
        if playbackBackend == .avPlayer {
            avPlayer?.pause()
            isPlaying = false
            stopProgressTimer()
            notifyPlaybackStateChanged()
            return
        }
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        notifyPlaybackStateChanged()
    }

    private func startPlayer(localURL: URL, backend: PlaybackBackend?) {
        if backend == .decodedOgg {
            startOggPlayer(localURL: localURL)
            return
        }
        if backend == .avPlayer {
            startAVPlayer(localURL: localURL)
            return
        }
        do {
            configureAudioSession()
            let nextPlayer = try AVAudioPlayer(contentsOf: localURL)
            nextPlayer.volume = 1
            nextPlayer.delegate = audioPlayerDelegate
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                if isOggFile(localURL) {
                    playbackBackend = .decodedOgg
                    startOggPlayer(localURL: localURL)
                } else {
                    fail(message: BaL10n.string("ba.student.detail.voice.error.playback"))
                }
                return
            }
            player = nextPlayer
            isLoading = false
            isPlaying = true
            startProgressTimer()
            notifyPlaybackStateChanged()
        } catch {
            if isOggFile(localURL) {
                playbackBackend = .decodedOgg
                startOggPlayer(localURL: localURL)
            } else {
                fail(message: BaL10n.string("ba.student.detail.voice.error.unsupported"))
            }
        }
    }

    private func updateProgress() {
        if playbackBackend == .avPlayer {
            updateAVPlayerProgress()
            return
        }
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
        let finished = onPlaybackFinished
        loadToken = UUID()
        player?.delegate = nil
        player?.currentTime = 0
        player?.stop()
        player = nil
        stopAVPlayer()
        currentRemoteURL = nil
        isLoading = false
        isPlaying = false
        progress = 0
        playbackBackend = nil
        stopProgressTimer()
        notifyPlaybackStateChanged()
        finished?()
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
        notifyPlaybackStateChanged()
    }

    private func tearDownPlayer() {
        stopProgressTimer()
        player?.delegate = nil
        player?.stop()
        player = nil
        stopAVPlayer()
    }

    private func startProgressTimer() {
        stopProgressTimer()
        let interval = playbackProfile.progressUpdateInterval
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

    private func notifyPlaybackStateChanged() {
        onPlaybackStateChanged?()
    }

    private enum PlaybackBackend: String {
        case avFoundation
        case avPlayer
        case decodedOgg

        nonisolated var oggPlaybackMode: BaOggPlaybackMode {
            .decodedPreferred
        }
    }

    private nonisolated static func preferredBackend(for url: URL, profile: BaAudioPlaybackProfile) -> PlaybackBackend {
        let ext = url.pathExtension.lowercased()
        if decodedOggExtensions.contains(ext) {
            return .decodedOgg
        }
        if avPlayerPlaybackExtensions.contains(ext) {
            return .avPlayer
        }
        return .avFoundation
    }

    nonisolated static func preferredBackendNameForTesting(_ url: URL) -> String {
        preferredBackend(for: url, profile: .voice).rawValue
    }

    nonisolated static func preferredMusicBackendNameForTesting(_ url: URL) -> String {
        preferredBackend(for: url, profile: .music).rawValue
    }

    nonisolated static func preferredOggPlaybackModeNameForTesting(
        _ url: URL,
        profile: BaAudioPlaybackProfile
    ) -> String {
        preferredBackend(for: url, profile: profile).oggPlaybackMode.rawValue
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
        BaMediaPlaybackCoordinator.configureAudioPlaybackSession()
    }

    private func startAVPlayer(localURL: URL) {
        configureAudioSession()
        stopAVPlayer()
        let item = AVPlayerItem(url: localURL)
        startAVPlayer(item: item)
    }

    private func startAVPlayer(remoteURL: URL) {
        configureAudioSession()
        stopAVPlayer()
        let item = BaMediaPlaybackSource.remotePlayerItem(for: remoteURL)
        startAVPlayer(item: item)
    }

    private func startAVPlayer(item: AVPlayerItem) {
        let nextPlayer = AVPlayer(playerItem: item)
        nextPlayer.isMuted = false
        nextPlayer.volume = 1
        avPlayer = nextPlayer
        avPlayerDuration = nil
        avPlayerEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.finishAVPlayerPlayback()
            }
        }
        nextPlayer.play()
        isLoading = false
        isPlaying = true
        startProgressTimer()
        notifyPlaybackStateChanged()
    }

    private func stopAVPlayer() {
        if let avPlayerEndObserver {
            NotificationCenter.default.removeObserver(avPlayerEndObserver)
            self.avPlayerEndObserver = nil
        }
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        avPlayer = nil
        avPlayerDuration = nil
    }

    private func updateAVPlayerProgress() {
        guard let avPlayer else {
            progress = 0
            return
        }
        let duration = avPlayer.currentItem?.duration.seconds ?? 0
        let previousDuration = avPlayerDuration
        avPlayerDuration = duration.isFinite && duration > 0 ? duration : avPlayerDuration
        if previousDuration == nil, avPlayerDuration != nil {
            notifyPlaybackStateChanged()
        }
        guard let avPlayerDuration, avPlayerDuration > 0 else {
            progress = 0
            return
        }
        let currentTime = avPlayer.currentTime().seconds
        progress = min(max(currentTime / avPlayerDuration, 0), 1)
    }

    private func finishAVPlayerPlayback() {
        avPlayer?.seek(to: .zero)
        finishPlayback()
    }

    private func handleAudioPlayerDidFinish(_ finishedPlayer: AVAudioPlayer, successfully flag: Bool) {
        guard player === finishedPlayer else { return }
        if flag {
            finishPlayback()
        } else {
            fail(message: BaL10n.string("ba.student.detail.voice.error.playback"))
        }
    }

    private func handleAudioPlayerDecodeError(_ failedPlayer: AVAudioPlayer) {
        guard player === failedPlayer else { return }
        fail(message: BaL10n.string("ba.student.detail.voice.error.playback"))
    }
}

private final class BaAudioPlayerDelegateProxy: NSObject, AVAudioPlayerDelegate {
    private let onFinish: @MainActor (AVAudioPlayer, Bool) -> Void
    private let onDecodeError: @MainActor (AVAudioPlayer) -> Void

    init(
        onFinish: @escaping @MainActor (AVAudioPlayer, Bool) -> Void,
        onDecodeError: @escaping @MainActor (AVAudioPlayer) -> Void
    ) {
        self.onFinish = onFinish
        self.onDecodeError = onDecodeError
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak player, onFinish] in
            guard let player else { return }
            onFinish(player, flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error _: (any Error)?) {
        Task { @MainActor [weak player, onDecodeError] in
            guard let player else { return }
            onDecodeError(player)
        }
    }
}

private extension BaAudioPlaybackController {
    func startOggPlayer(localURL: URL) {
        configureAudioSession()
        let mode = playbackBackend?.oggPlaybackMode ?? playbackProfile.defaultOggPlaybackMode
        oggPlayer.progressUpdateInterval = playbackProfile.progressUpdateInterval
        logger.debug("ogg local playback start, profile: \(String(describing: self.playbackProfile)), mode: \(String(describing: mode))")
        oggPlayer.play(localURL: localURL, mode: mode)
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

    func handleOggEvent(_ event: BaOggAudioEvent) {
        switch event {
        case .ready:
            isLoading = false
            notifyPlaybackStateChanged()
        case .playing:
            isLoading = false
            isPlaying = true
            notifyPlaybackStateChanged()
        case .paused:
            isPlaying = false
            notifyPlaybackStateChanged()
        case .ended:
            finishPlayback()
        case let .progress(value):
            progress = min(max(value, 0), 1)
        case let .failed(message):
            fail(message: message.isEmpty ? BaL10n.string("ba.student.detail.voice.error.playback") : message)
        }
    }
}

typealias BaVoicePlaybackController = BaAudioPlaybackController
