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
final class BaMusicPlaybackSession {
    let player = BaGuideAudioPlaybackController()
    @ObservationIgnored private let audioCache: any BaAudioCaching

    var selectedTrack: BaMusicTrack?
    var queue: [BaMusicTrack] = []
    var isExpanded = false
    var repeatMode: BaMusicRepeatMode = .off
    var cacheStates: [URL: BaMusicCacheState] = [:]

    init(audioCache: any BaAudioCaching = BaAudioCache.shared) {
        self.audioCache = audioCache
        player.onPlaybackFinished = { [weak self] in
            self?.handlePlaybackFinished()
        }
    }

    var hasCurrentTrack: Bool {
        selectedTrack != nil
    }

    var currentIndex: Int? {
        guard let selectedTrack else { return nil }
        return queue.firstIndex { $0.id == selectedTrack.id }
    }

    func updateQueue(_ tracks: [BaMusicTrack]) {
        queue = tracks
        guard let selectedTrack else { return }
        if let refreshed = tracks.first(where: { $0.id == selectedTrack.id }) {
            self.selectedTrack = selectedTrack.refreshed(with: refreshed)
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
        Task {
            try? await Task.sleep(for: .seconds(1))
            await refreshCacheState(for: track)
        }
    }

    func toggleCurrent() {
        if let selectedTrack, let audioURL = selectedTrack.audioURL {
            player.toggle(remoteURL: audioURL)
            return
        }
        if let firstTrack = queue.first {
            play(firstTrack)
        }
    }

    func playPrevious() {
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
            }
        }
    }

    private func previousTrack(wraps: Bool) -> BaMusicTrack? {
        guard queue.isEmpty == false else { return nil }
        guard let currentIndex else { return queue.first }
        if currentIndex == queue.startIndex {
            return wraps ? queue[queue.index(before: queue.endIndex)] : nil
        }
        return queue[queue.index(before: currentIndex)]
    }

    private func nextTrack(wraps: Bool) -> BaMusicTrack? {
        guard queue.isEmpty == false else { return nil }
        guard let currentIndex else { return queue.first }
        let nextIndex = queue.index(after: currentIndex)
        if nextIndex == queue.endIndex {
            return wraps ? queue[queue.startIndex] : nil
        }
        return queue[nextIndex]
    }
}
