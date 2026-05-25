//
//  BaAudioCache.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import CryptoKit
import Foundation
import os

nonisolated protocol BaAudioCaching: Sendable {
    func localURL(for url: URL, refererPath: String) async throws -> URL
    func cachedURL(for url: URL) async -> URL?
    func isCached(_ url: URL) async -> Bool
    func removeCachedAudio(for url: URL) async
}

actor BaAudioCache: BaAudioCaching {
    nonisolated static let shared = BaAudioCache(client: GameKeeClient())

    private struct RequestKey: Hashable {
        let url: URL
        let refererPath: String
    }

    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL
    private var inFlightRequests: [RequestKey: Task<Data, Error>] = [:]
    private var deferredFailures: [URL: Date] = [:]
    private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaAudioCache")
    private let failureTTL: TimeInterval = 45
    private let deferredFailureCap = 128

    init(fileManager: FileManager = .default, client: GameKeeClient) {
        self.fileManager = fileManager
        self.client = client
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BAVoiceAudio", isDirectory: true)
    }

    func localURL(for url: URL, refererPath: String = "/ba") async throws -> URL {
        if let cachedURL = validatedCachedFileURL(for: url) {
            logger.debug("audio cache hit \(url.host ?? "unknown", privacy: .public)")
            return cachedURL
        }
        if let retryAt = deferredFailures[url], retryAt > Date() {
            throw GameKeeError.invalidResponse("Audio retry deferred")
        }
        deferredFailures[url] = nil

        let requestKey = RequestKey(url: url, refererPath: refererPath)
        if let inFlightRequest = inFlightRequests[requestKey] {
            let data = try await inFlightRequest.value
            if let cachedURL = validatedCachedFileURL(for: url) {
                return cachedURL
            }
            return try storeAudioData(data, for: url)
        }

        let request = Task.detached(priority: .utility) { [client] in
            try await client.fetchAudioData(url: url, refererPath: refererPath)
        }
        inFlightRequests[requestKey] = request
        do {
            let data = try await request.value
            inFlightRequests[requestKey] = nil
            return try storeAudioData(data, for: url)
        } catch {
            inFlightRequests[requestKey] = nil
            if Self.isCancellation(error) == false {
                recordFailure(for: url)
            }
            throw error
        }
    }

    private func storeAudioData(_ data: Data, for url: URL) throws -> URL {
        let fileURL = cachedFileURL(for: url)
        do {
            guard Self.looksLikeAudioData(data, expectedExtension: url.pathExtension) else {
                recordFailure(for: url)
                throw GameKeeError.invalidResponse(String(decoding: data.prefix(120), as: UTF8.self))
            }
            try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
            logger.debug("audio cache stored \(url.host ?? "unknown", privacy: .public) bytes=\(data.count, privacy: .public)")
        } catch {
            logger.debug("audio cache write failed \(error.localizedDescription, privacy: .public)")
            throw error
        }
        return fileURL
    }

    func isCached(_ url: URL) async -> Bool {
        await cachedURL(for: url) != nil
    }

    func cachedURL(for url: URL) async -> URL? {
        validatedCachedFileURL(for: url)
    }

    private func validatedCachedFileURL(for url: URL) -> URL? {
        let fileURL = cachedFileURL(for: url)
        guard let data = try? Data(contentsOf: fileURL), data.isEmpty == false else {
            return nil
        }
        guard Self.looksLikeAudioData(data, expectedExtension: url.pathExtension) else {
            try? fileManager.removeItem(at: fileURL)
            logger.debug("audio cache invalidated \(url.host ?? "unknown", privacy: .public)")
            return nil
        }
        return fileURL
    }

    func removeCachedAudio(for url: URL) async {
        let fileURL = cachedFileURL(for: url)
        try? fileManager.removeItem(at: fileURL)
        deferredFailures[url] = nil
        logger.debug("audio cache removed \(url.host ?? "unknown", privacy: .public)")
    }

    private func recordFailure(for url: URL) {
        pruneExpiredFailures()
        if deferredFailures.count >= deferredFailureCap, let staleKey = deferredFailures.keys.first {
            deferredFailures.removeValue(forKey: staleKey)
        }
        deferredFailures[url] = Date().addingTimeInterval(failureTTL)
        logger.debug("audio cache deferred \(url.host ?? "unknown", privacy: .public)")
    }

    private func pruneExpiredFailures() {
        let now = Date()
        deferredFailures = deferredFailures.filter { $0.value > now }
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = url.pathExtension.isEmpty ? "audio" : url.pathExtension
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }

    private nonisolated static func looksLikeAudioData(_ data: Data, expectedExtension: String) -> Bool {
        let ext = expectedExtension.lowercased()
        let bytes = [UInt8](data.prefix(16))
        let isOgg = bytes.starts(with: [0x4F, 0x67, 0x67, 0x53])
        let isID3 = bytes.starts(with: [0x49, 0x44, 0x33])
        let isMP3Frame = bytes.count >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0
        let isFLAC = bytes.starts(with: [0x66, 0x4C, 0x61, 0x43])
        let isWave = bytes.count >= 12 &&
            bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46]) &&
            bytes[8 ..< 12].elementsEqual([0x57, 0x41, 0x56, 0x45])
        let isMP4Family = bytes.count >= 8 &&
            bytes[4 ..< 8].elementsEqual([0x66, 0x74, 0x79, 0x70])
        let recognized = isOgg || isID3 || isMP3Frame || isFLAC || isWave || isMP4Family
        if recognized { return true }
        if ["ogg", "oga", "opus"].contains(ext) { return false }
        return ext.isEmpty || ext == "audio"
    }

    private nonisolated static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    nonisolated static func recognizesAudioDataForTesting(_ data: Data, expectedExtension: String) -> Bool {
        looksLikeAudioData(data, expectedExtension: expectedExtension)
    }
}
