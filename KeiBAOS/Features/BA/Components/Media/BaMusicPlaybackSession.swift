//
//  BaMusicPlaybackSession.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation
import Observation

@Observable
@MainActor
final class BaMusicPlaybackSession {
    let player = BaGuideAudioPlaybackController()

    var selectedTrack: BaMusicTrack?
    var queue: [BaMusicTrack] = []
    var isExpanded = false

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
        selectedTrack = track
        player.toggle(remoteURL: audioURL)
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
        guard let currentIndex, queue.isEmpty == false else { return }
        let previousIndex = currentIndex == 0 ? queue.index(before: queue.endIndex) : queue.index(before: currentIndex)
        play(queue[previousIndex])
    }

    func playNext() {
        guard let currentIndex, queue.isEmpty == false else { return }
        let nextIndex = queue.index(after: currentIndex) == queue.endIndex ? queue.startIndex : queue.index(after: currentIndex)
        play(queue[nextIndex])
    }

    func stop() {
        player.stop()
        selectedTrack = nil
        isExpanded = false
    }
}
