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

@Observable
@MainActor
final class BaMusicPlaybackSession {
    let player = BaGuideAudioPlaybackController()

    var selectedTrack: BaMusicTrack?
    var queue: [BaMusicTrack] = []
    var isExpanded = false
    var repeatMode: BaMusicRepeatMode = .off

    init() {
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

    func start(_ track: BaMusicTrack) {
        guard let audioURL = track.audioURL else { return }
        selectedTrack = track
        player.play(remoteURL: audioURL)
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
