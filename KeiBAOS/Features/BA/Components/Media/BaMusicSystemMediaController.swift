//
//  BaMusicSystemMediaController.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if canImport(MediaPlayer)
import MediaPlayer
#endif

nonisolated struct BaMusicNowPlayingMetadata: Equatable {
    let title: String
    let subtitle: String
    let elapsedTime: TimeInterval
    let duration: TimeInterval?
    let playbackRate: Double
    let queueIndex: Int?
    let queueCount: Int

    init(
        track: BaMusicTrack,
        elapsedTime: TimeInterval,
        duration: TimeInterval?,
        isPlaying: Bool,
        queueIndex: Int?,
        queueCount: Int
    ) {
        title = track.title
        subtitle = track.subtitle
        self.elapsedTime = max(elapsedTime, 0)
        self.duration = duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        playbackRate = isPlaying ? 1 : 0
        self.queueIndex = queueIndex
        self.queueCount = max(queueCount, 0)
    }
}

enum BaMusicSystemMediaCommand {
    case play
    case pause
    case togglePlayPause
    case previous
    case next
}

@MainActor
protocol BaMusicSystemMediaCommandHandling: AnyObject {
    func handleSystemMediaCommand(_ command: BaMusicSystemMediaCommand) -> Bool
    func handleSystemMediaSeek(to elapsedTime: TimeInterval) -> Bool
}

@MainActor
protocol BaMusicSystemMediaControlling: AnyObject {
    func configure(commandHandler: BaMusicSystemMediaCommandHandling)
    func update(metadata: BaMusicNowPlayingMetadata)
    func clear()
}

@MainActor
final class BaMusicSystemMediaController: BaMusicSystemMediaControlling {
    private weak var commandHandler: BaMusicSystemMediaCommandHandling?

    #if canImport(MediaPlayer)
    private var remoteCommandTargets: [(command: MPRemoteCommand, target: Any)] = []
    #endif

    func configure(commandHandler: BaMusicSystemMediaCommandHandling) {
        self.commandHandler = commandHandler
        configureRemoteCommandsIfNeeded()
    }

    func update(metadata: BaMusicNowPlayingMetadata) {
        #if canImport(MediaPlayer)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = metadata.nowPlayingInfo
        #endif
    }

    func clear() {
        #if canImport(MediaPlayer)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #endif
    }

    deinit {
        #if canImport(MediaPlayer)
        for target in remoteCommandTargets {
            target.command.removeTarget(target.target)
        }
        #endif
    }

    private func configureRemoteCommandsIfNeeded() {
        #if canImport(MediaPlayer)
        guard remoteCommandTargets.isEmpty else { return }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        addTarget(commandCenter.playCommand, command: .play)
        addTarget(commandCenter.pauseCommand, command: .pause)
        addTarget(commandCenter.togglePlayPauseCommand, command: .togglePlayPause)
        addTarget(commandCenter.previousTrackCommand, command: .previous)
        addTarget(commandCenter.nextTrackCommand, command: .next)

        let seekTarget = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            DispatchQueue.main.async { [weak self] in
                _ = self?.commandHandler?.handleSystemMediaSeek(to: positionEvent.positionTime)
            }
            return .success
        }
        remoteCommandTargets.append((commandCenter.changePlaybackPositionCommand, seekTarget))
        #endif
    }

    #if canImport(MediaPlayer)
    private func addTarget(_ remoteCommand: MPRemoteCommand, command: BaMusicSystemMediaCommand) {
        let target = remoteCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                _ = self?.commandHandler?.handleSystemMediaCommand(command)
            }
            return .success
        }
        remoteCommandTargets.append((remoteCommand, target))
    }
    #endif
}

#if canImport(MediaPlayer)
private extension BaMusicNowPlayingMetadata {
    var nowPlayingInfo: [String: Any] {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyPlaybackQueueCount: queueCount,
        ]
        if let duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let queueIndex {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = queueIndex
        }
        return info
    }
}
#endif
