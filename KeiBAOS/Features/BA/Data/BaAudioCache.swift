//
//  BaAudioCache.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import CryptoKit
import Foundation
import os

actor BaAudioCache {
    static let shared = BaAudioCache(client: GameKeeClient())

    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL
    private var deferredFailures: [URL: Date] = [:]
    private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaAudioCache")
    private let failureTTL: TimeInterval = 45

    init(fileManager: FileManager = .default, client: GameKeeClient) {
        self.fileManager = fileManager
        self.client = client
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BAVoiceAudio", isDirectory: true)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    func localURL(for url: URL, refererPath: String = "/ba") async throws -> URL {
        let fileURL = cachedFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL), data.isEmpty == false {
            logger.debug("audio cache hit \(url.host ?? "unknown", privacy: .public)")
            return fileURL
        }
        if let retryAt = deferredFailures[url], retryAt > Date() {
            throw GameKeeError.invalidResponse("Audio retry deferred")
        }
        deferredFailures[url] = nil
        let data: Data
        do {
            data = try await client.fetchAudioData(url: url, refererPath: refererPath)
        } catch {
            recordFailure(for: url)
            throw error
        }
        do {
            try data.write(to: fileURL, options: [.atomic])
            logger.debug("audio cache stored \(url.host ?? "unknown", privacy: .public) bytes=\(data.count, privacy: .public)")
        } catch {
            logger.debug("audio cache write failed \(error.localizedDescription, privacy: .public)")
        }
        return fileURL
    }

    private func recordFailure(for url: URL) {
        deferredFailures[url] = Date().addingTimeInterval(failureTTL)
        logger.debug("audio cache deferred \(url.host ?? "unknown", privacy: .public)")
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = url.pathExtension.isEmpty ? "audio" : url.pathExtension
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }
}
