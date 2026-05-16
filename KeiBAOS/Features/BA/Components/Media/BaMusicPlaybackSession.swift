//
//  BaMusicPlaybackSession.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation
import Observation

enum BaMusicRepeatMode: Hashable {
    case off
    case all
    case one

    var isActive: Bool {
        self != .off
    }

    var systemImage: String {
        switch self {
        case .off, .all:
            "repeat"
        case .one:
            "repeat.1"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .off:
            String(localized: "ba.music.action.repeat.off")
        case .all:
            String(localized: "ba.music.action.repeat.all")
        case .one:
            String(localized: "ba.music.action.repeat.one")
        }
    }

    var next: BaMusicRepeatMode {
        switch self {
        case .off:
            .all
        case .all:
            .one
        case .one:
            .off
        }
    }
}

nonisolated enum BaMusicPreviousPlaybackAction: Equatable {
    case restartCurrentTrack
    case moveToPreviousTrack
}

nonisolated enum BaMusicPlaybackNavigationPolicy {
    static let previousRestartThreshold: TimeInterval = 3

    static func previousAction(elapsedTime: TimeInterval) -> BaMusicPreviousPlaybackAction {
        guard elapsedTime.isFinite,
              elapsedTime >= previousRestartThreshold
        else {
            return .moveToPreviousTrack
        }
        return .restartCurrentTrack
    }

    static func nextIndex(after currentIndex: Int?, queueCount: Int, wraps: Bool) -> Int? {
        guard queueCount > 0 else { return nil }
        guard let currentIndex, currentIndex >= 0, currentIndex < queueCount else { return 0 }
        let nextIndex = currentIndex + 1
        if nextIndex < queueCount {
            return nextIndex
        }
        return wraps ? 0 : nil
    }

    static func previousIndex(before currentIndex: Int?, queueCount: Int, wraps: Bool) -> Int? {
        guard queueCount > 0 else { return nil }
        guard let currentIndex, currentIndex >= 0, currentIndex < queueCount else { return 0 }
        if currentIndex > 0 {
            return currentIndex - 1
        }
        return wraps ? queueCount - 1 : nil
    }
}

enum BaMusicCacheState: Hashable {
    case unknown
    case notCached
    case caching
    case cached
    case failed(String)

    var isCached: Bool {
        if case .cached = self { return true }
        return false
    }

    var isCaching: Bool {
        if case .caching = self { return true }
        return false
    }

    var statusText: String? {
        switch self {
        case .unknown:
            nil
        case .notCached:
            String(localized: "ba.music.status.cache.notCached")
        case .caching:
            String(localized: "ba.music.status.cache.caching")
        case .cached:
            String(localized: "ba.music.status.cache.cached")
        case .failed:
            String(localized: "ba.music.status.cache.failed")
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .unknown, .notCached:
            String(localized: "ba.music.action.cache")
        case .caching:
            String(localized: "ba.music.status.cache.caching")
        case .cached:
            String(localized: "ba.music.status.cache.cached")
        case .failed:
            String(localized: "ba.music.action.cache.retry")
        }
    }

    var systemImage: String {
        switch self {
        case .unknown, .notCached:
            "arrow.down.circle"
        case .caching:
            "arrow.down.circle.dotted"
        case .cached:
            "checkmark.circle.fill"
        case .failed:
            "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
}

@Observable
@MainActor
final class BaMusicPlaybackSession: BaMusicSystemMediaCommandHandling {
    let player: BaAudioPlaybackController
    @ObservationIgnored private let audioCache: any BaAudioCaching
    @ObservationIgnored private let systemMediaController: any BaMusicSystemMediaControlling
    @ObservationIgnored private var systemMediaTimer: Timer?

    var selectedTrack: BaMusicTrack?
    var queue: [BaMusicTrack] = []
    var isExpanded = false
    var repeatMode: BaMusicRepeatMode = .all
    var cacheStates: [URL: BaMusicCacheState] = [:]

    convenience init(audioCache: any BaAudioCaching = BaAudioCache.shared) {
        self.init(
            audioCache: audioCache,
            systemMediaController: BaMusicSystemMediaController()
        )
    }

    init(
        audioCache: any BaAudioCaching,
        systemMediaController: any BaMusicSystemMediaControlling
    ) {
        self.audioCache = audioCache
        self.systemMediaController = systemMediaController
        player = BaAudioPlaybackController(audioCache: audioCache, profile: .music)
        player.onPlaybackFinished = { [weak self] in
            self?.handlePlaybackFinished()
        }
        systemMediaController.configure(commandHandler: self)
    }

    deinit {
        systemMediaTimer?.invalidate()
        let systemMediaController = systemMediaController
        Task { @MainActor in
            systemMediaController.clear()
        }
    }

    var hasCurrentTrack: Bool {
        selectedTrack != nil
    }

    var currentIndex: Int? {
        guard let selectedTrack else { return nil }
        return queue.firstIndex { $0.id == selectedTrack.id }
    }

    var canPlayPrevious: Bool {
        selectedTrack != nil
    }

    func updateQueue(_ tracks: [BaMusicTrack]) {
        queue = tracks
        guard let selectedTrack else { return }
        if let refreshed = tracks.first(where: { $0.id == selectedTrack.id }) {
            self.selectedTrack = selectedTrack.refreshed(with: refreshed)
            syncSystemMediaState()
        } else if tracks.isEmpty {
            stop()
        }
    }

    func play(_ track: BaMusicTrack) {
        guard let audioURL = track.audioURL else { return }
        if selectedTrack?.id == track.id, player.currentRemoteURL == audioURL {
            player.toggle(remoteURL: audioURL)
            return
        }
        start(track)
    }

    func cycleRepeatMode() {
        repeatMode = repeatMode.next
    }

    func cacheState(for track: BaMusicTrack) -> BaMusicCacheState {
        guard let audioURL = track.audioURL else { return .notCached }
        return cacheStates[audioURL] ?? .unknown
    }

    func refreshCacheState(for track: BaMusicTrack) async {
        guard let audioURL = track.audioURL else { return }
        if cacheStates[audioURL]?.isCaching == true { return }
        cacheStates[audioURL] = await audioCache.isCached(audioURL) ? .cached : .notCached
    }

    func cache(_ track: BaMusicTrack) {
        guard let audioURL = track.audioURL else { return }
        cacheStates[audioURL] = .caching
        Task {
            do {
                _ = try await audioCache.localURL(for: audioURL, refererPath: "/ba")
                guard Task.isCancelled == false else { return }
                cacheStates[audioURL] = .cached
            } catch {
                guard Task.isCancelled == false else { return }
                cacheStates[audioURL] = .failed(error.localizedDescription)
            }
        }
    }

    func start(_ track: BaMusicTrack) {
        guard let audioURL = track.audioURL else { return }
        selectedTrack = track
        player.play(remoteURL: audioURL)
        syncSystemMediaState()
        Task {
            try? await Task.sleep(for: .seconds(1))
            await refreshCacheState(for: track)
        }
    }

    func toggleCurrent() {
        if let selectedTrack, let audioURL = selectedTrack.audioURL {
            player.toggle(remoteURL: audioURL)
            syncSystemMediaState()
            return
        }
        if let firstTrack = queue.first {
            play(firstTrack)
        }
    }

    func playPrevious() {
        if selectedTrack != nil,
           BaMusicPlaybackNavigationPolicy.previousAction(elapsedTime: player.currentTime) == .restartCurrentTrack {
            restartSelectedTrack()
            return
        }
        guard let track = previousTrack(wraps: true) else { return }
        start(track)
    }

    func playNext() {
        guard let track = nextTrack(wraps: true) else { return }
        start(track)
    }

    func stop() {
        player.stop()
        selectedTrack = nil
        isExpanded = false
        stopSystemMediaTimer()
        systemMediaController.clear()
    }

    private func handlePlaybackFinished() {
        guard let selectedTrack else { return }
        switch repeatMode {
        case .one:
            start(selectedTrack)
        case .all:
            if let track = nextTrack(wraps: true) {
                start(track)
            }
        case .off:
            if let track = nextTrack(wraps: false) {
                start(track)
            } else {
                syncSystemMediaState()
            }
        }
    }

    private func previousTrack(wraps: Bool) -> BaMusicTrack? {
        guard let index = BaMusicPlaybackNavigationPolicy.previousIndex(
            before: currentIndex,
            queueCount: queue.count,
            wraps: wraps
        ) else {
            return nil
        }
        return queue[index]
    }

    private func nextTrack(wraps: Bool) -> BaMusicTrack? {
        guard let index = BaMusicPlaybackNavigationPolicy.nextIndex(
            after: currentIndex,
            queueCount: queue.count,
            wraps: wraps
        ) else {
            return nil
        }
        return queue[index]
    }

    func handleSystemMediaCommand(_ command: BaMusicSystemMediaCommand) -> Bool {
        switch command {
        case .play:
            if player.isPlaying == false {
                toggleCurrent()
            }
        case .pause:
            pauseCurrent()
        case .togglePlayPause:
            toggleCurrent()
        case .previous:
            playPrevious()
        case .next:
            playNext()
        }
        syncSystemMediaState()
        return true
    }

    func handleSystemMediaSeek(to elapsedTime: TimeInterval) -> Bool {
        guard let duration = player.duration, duration > 0 else { return false }
        player.seek(to: elapsedTime / duration)
        syncSystemMediaState()
        return true
    }

    func nowPlayingMetadata() -> BaMusicNowPlayingMetadata? {
        guard let selectedTrack else { return nil }
        return BaMusicNowPlayingMetadata(
            track: selectedTrack,
            elapsedTime: player.currentTime,
            duration: player.duration,
            isPlaying: player.isPlaying,
            queueIndex: currentIndex,
            queueCount: queue.count
        )
    }

    private func pauseCurrent() {
        guard player.isPlaying,
              let selectedTrack,
              let audioURL = selectedTrack.audioURL
        else {
            return
        }
        player.toggle(remoteURL: audioURL)
    }

    private func restartSelectedTrack() {
        guard let selectedTrack else { return }
        if selectedTrack.audioURL == player.currentRemoteURL, player.canSeek {
            player.seek(to: 0)
            syncSystemMediaState()
        } else {
            start(selectedTrack)
        }
    }

    private func syncSystemMediaState() {
        guard let metadata = nowPlayingMetadata() else {
            systemMediaController.clear()
            stopSystemMediaTimer()
            return
        }
        systemMediaController.update(metadata: metadata)
        if player.isLoading || player.isPlaying {
            startSystemMediaTimer()
        } else {
            stopSystemMediaTimer()
        }
    }

    private func startSystemMediaTimer() {
        guard systemMediaTimer == nil else { return }
        systemMediaTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncSystemMediaState()
            }
        }
    }

    private func stopSystemMediaTimer() {
        systemMediaTimer?.invalidate()
        systemMediaTimer = nil
    }
}
