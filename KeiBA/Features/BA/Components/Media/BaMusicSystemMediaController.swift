//
//  BaMusicSystemMediaController.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if canImport(MediaPlayer)
    import MediaPlayer
#endif
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

nonisolated struct BaMusicNowPlayingMetadata: Equatable {
    let title: String
    let subtitle: String
    let artworkURL: URL?
    let elapsedTime: TimeInterval
    let duration: TimeInterval?
    let playbackRate: Double
    let queueIndex: Int?
    let queueCount: Int
    let repeatMode: BaMusicRepeatMode

    init(
        track: BaMusicTrack,
        elapsedTime: TimeInterval,
        duration: TimeInterval?,
        isPlaying: Bool,
        queueIndex: Int?,
        queueCount: Int,
        repeatMode: BaMusicRepeatMode = .off
    ) {
        title = track.title
        subtitle = track.subtitle
        artworkURL = track.artworkURL
        self.elapsedTime = max(elapsedTime, 0)
        self.duration = duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        playbackRate = isPlaying ? 1 : 0
        self.queueIndex = queueIndex
        self.queueCount = max(queueCount, 0)
        self.repeatMode = repeatMode
    }
}

enum BaMusicSystemMediaCommand {
    case play
    case pause
    case togglePlayPause
    case previous
    case next
    case stop
    case changeRepeatMode(BaMusicRepeatMode)
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
        private let artworkClient = GameKeeClient()
        private var latestMetadata: BaMusicNowPlayingMetadata?
        private var artworkTask: Task<Void, Never>?
        private var loadingArtworkURL: URL?
        private var cachedArtworkURL: URL?
        private var cachedArtwork: MPMediaItemArtwork?
    #endif

    func configure(commandHandler: BaMusicSystemMediaCommandHandling) {
        self.commandHandler = commandHandler
        configureRemoteCommandsIfNeeded()
    }

    func update(metadata: BaMusicNowPlayingMetadata) {
        #if canImport(MediaPlayer)
            latestMetadata = metadata
            applyNowPlayingInfo(metadata: metadata)
            loadArtworkIfNeeded(for: metadata)
        #endif
    }

    func clear() {
        #if canImport(MediaPlayer)
            artworkTask?.cancel()
            artworkTask = nil
            loadingArtworkURL = nil
            latestMetadata = nil
            cachedArtworkURL = nil
            cachedArtwork = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #endif
    }

    deinit {
        #if canImport(MediaPlayer)
            artworkTask?.cancel()
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
            commandCenter.stopCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.isEnabled = true
            commandCenter.changeRepeatModeCommand.isEnabled = true

            addTarget(commandCenter.playCommand, command: .play)
            addTarget(commandCenter.pauseCommand, command: .pause)
            addTarget(commandCenter.togglePlayPauseCommand, command: .togglePlayPause)
            addTarget(commandCenter.previousTrackCommand, command: .previous)
            addTarget(commandCenter.nextTrackCommand, command: .next)
            addTarget(commandCenter.stopCommand, command: .stop)

            let repeatTarget = commandCenter.changeRepeatModeCommand.addTarget { [weak self] event in
                guard let repeatEvent = event as? MPChangeRepeatModeCommandEvent else {
                    return .commandFailed
                }
                let repeatMode = BaMusicRepeatMode(mpRepeatType: repeatEvent.repeatType)
                DispatchQueue.main.async { [weak self] in
                    _ = self?.commandHandler?.handleSystemMediaCommand(.changeRepeatMode(repeatMode))
                }
                return .success
            }
            remoteCommandTargets.append((commandCenter.changeRepeatModeCommand, repeatTarget))

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

        private func applyNowPlayingInfo(metadata: BaMusicNowPlayingMetadata) {
            let artwork = metadata.artworkURL == cachedArtworkURL ? cachedArtwork : nil
            MPRemoteCommandCenter.shared().changeRepeatModeCommand.currentRepeatType = metadata.repeatMode.mpRepeatType
            MPNowPlayingInfoCenter.default().nowPlayingInfo = metadata.nowPlayingInfo(artwork: artwork)
        }

        private func loadArtworkIfNeeded(for metadata: BaMusicNowPlayingMetadata) {
            guard let artworkURL = metadata.artworkURL else {
                artworkTask?.cancel()
                artworkTask = nil
                loadingArtworkURL = nil
                cachedArtworkURL = nil
                cachedArtwork = nil
                return
            }
            if artworkURL == cachedArtworkURL {
                return
            }
            if artworkURL == loadingArtworkURL {
                return
            }

            artworkTask?.cancel()
            loadingArtworkURL = artworkURL
            artworkTask = Task { [artworkClient, artworkURL] in
                do {
                    let data = try await artworkClient.fetchImageData(url: artworkURL, refererPath: "/ba")
                    guard Task.isCancelled == false else { return }
                    let artwork = Self.makeArtwork(from: data)
                    guard Task.isCancelled == false else { return }
                    await MainActor.run { [weak self] in
                        self?.applyLoadedArtwork(artwork, for: artworkURL)
                    }
                } catch {
                    guard Task.isCancelled == false else { return }
                    await MainActor.run { [weak self] in
                        self?.loadingArtworkURL = nil
                    }
                }
            }
        }

        private func applyLoadedArtwork(_ artwork: MPMediaItemArtwork?, for artworkURL: URL) {
            guard loadingArtworkURL == artworkURL else { return }
            loadingArtworkURL = nil
            cachedArtworkURL = artwork == nil ? nil : artworkURL
            cachedArtwork = artwork
            guard let latestMetadata,
                  latestMetadata.artworkURL == artworkURL
            else {
                return
            }
            applyNowPlayingInfo(metadata: latestMetadata)
        }

        private static func makeArtwork(from data: Data) -> MPMediaItemArtwork? {
            #if canImport(UIKit)
                guard let image = UIImage(data: data) else { return nil }
                return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            #elseif canImport(AppKit)
                guard let image = NSImage(data: data) else { return nil }
                return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            #else
                return nil
            #endif
        }
    #endif
}

#if canImport(MediaPlayer)
private extension BaMusicNowPlayingMetadata {
    func nowPlayingInfo(artwork: MPMediaItemArtwork?) -> [String: Any] {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyPlaybackQueueCount: queueCount,
        ]
        if let duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let queueIndex {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = queueIndex
        }
        if let artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        return info
    }
}

private extension BaMusicRepeatMode {
    init(mpRepeatType: MPRepeatType) {
        switch mpRepeatType {
        case .one:
            self = .one
        case .all:
            self = .all
        case .off:
            self = .off
        @unknown default:
            self = .off
        }
    }

    var mpRepeatType: MPRepeatType {
        switch self {
        case .off:
            .off
        case .all:
            .all
        case .one:
            .one
        }
    }
}
#endif
