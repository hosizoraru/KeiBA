//
//  BaGuideMediaCache.swift
//  KeiBA
//
//  Created by Codex on 2026/05/16.
//

import CryptoKit
import Foundation
import os

actor BaGuideMediaCache {
    nonisolated static let shared = BaGuideMediaCache(client: GameKeeClient())

    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL
    private var deferredFailures: [URL: Date] = [:]
    private let failureTTL: TimeInterval = 45
    private let deferredFailureCap = 128
    private var lastPruneDate: Date = .distantPast
    private let pruneInterval: TimeInterval = 600
    private let logger = Logger(subsystem: "os.kei.KeiBA", category: "BaGuideMediaCache")

    init(fileManager: FileManager = .default, client: GameKeeClient) {
        self.fileManager = fileManager
        self.client = client
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BAGuideMedia", isDirectory: true)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    func localURL(for url: URL, refererPath: String = "/ba") async throws -> URL {
        let fileURL = cachedFileURL(for: url)
        // Read + signature-validate off the actor. The disk read is the slow
        // part on a cold cache and looksLikeRenderableMediaData is pure;
        // hopping both off the actor keeps in-flight bookkeeping unblocked.
        let validation = await Self.validateMediaFile(at: fileURL)
        switch validation {
        case .valid:
            logger.debug("guide media cache hit \(url.host ?? "unknown", privacy: .public)")
            pruneStaleDiskCache()
            return fileURL
        case .invalid:
            try? fileManager.removeItem(at: fileURL)
            logger.debug("guide media cache invalidated \(url.host ?? "unknown", privacy: .public)")
        case .missing:
            break
        }
        if let retryAt = deferredFailures[url], retryAt > Date() {
            throw GameKeeError.invalidResponse("Media retry deferred")
        }
        deferredFailures[url] = nil
        do {
            let data = try await client.fetchMediaData(url: url, refererPath: refererPath)
            try data.write(to: fileURL, options: [.atomic])
            logger.debug("guide media cache stored \(url.host ?? "unknown", privacy: .public) bytes=\(data.count, privacy: .public)")
            return fileURL
        } catch {
            pruneExpiredFailures()
            if deferredFailures.count >= deferredFailureCap,
               let staleKey = deferredFailures.keys.first
            {
                deferredFailures.removeValue(forKey: staleKey)
            }
            deferredFailures[url] = Date().addingTimeInterval(failureTTL)
            throw error
        }
    }

    private func pruneExpiredFailures() {
        let now = Date()
        deferredFailures = deferredFailures.filter { $0.value > now }
    }

    func data(for url: URL, refererPath: String = "/ba") async throws -> Data {
        let fileURL = try await localURL(for: url, refererPath: refererPath)
        return try Data(contentsOf: fileURL)
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = Self.cacheKey(for: url)
        let ext = Self.cachedFileExtension(for: url)
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }

    private nonisolated static func looksLikeRenderableMediaData(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(16))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return true }
        if bytes.starts(with: [0x49, 0x44, 0x33]) { return true }
        if bytes.count >= 2, bytes[0] == 0xFF, (bytes[1] & 0xE0) == 0xE0 { return true }
        if bytes.starts(with: [0x4F, 0x67, 0x67, 0x53]) { return true }
        if bytes.starts(with: [0x66, 0x4C, 0x61, 0x43]) { return true }
        if bytes.count >= 8,
           bytes[4 ..< 8].elementsEqual([0x66, 0x74, 0x79, 0x70])
        {
            return true
        }
        if bytes.count >= 12,
           bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46])
        {
            return bytes[8 ..< 12].elementsEqual([0x57, 0x45, 0x42, 0x50]) ||
                bytes[8 ..< 12].elementsEqual([0x57, 0x41, 0x56, 0x45])
        }
        if bytes.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) { return true }
        guard let head = String(data: data.prefix(128), encoding: .utf8) else {
            return false
        }
        let trimmed = head.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("<svg") || trimmed.hasPrefix("#extm3u")
    }

    nonisolated static func cacheKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    nonisolated static func cachedFileExtension(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty == false {
            return ext
        }
        let lower = url.absoluteString.lowercased()
        if lower.contains("image/gif") || lower.contains("format=gif") { return "gif" }
        if lower.contains("video") { return "mp4" }
        if lower.contains("audio") { return "ogg" }
        return "media"
    }

    private enum MediaFileValidation: Sendable {
        case valid
        case invalid
        case missing
    }

    private nonisolated static func validateMediaFile(at fileURL: URL) async -> MediaFileValidation {
        await Task.detached(priority: .utility) {
            guard let data = try? Data(contentsOf: fileURL), data.isEmpty == false else {
                return MediaFileValidation.missing
            }
            return looksLikeRenderableMediaData(data) ? .valid : .invalid
        }.value
    }

    func pruneStaleDiskCache(maxAge: TimeInterval = 14 * 24 * 3600) {
        let now = Date()
        guard now.timeIntervalSince(lastPruneDate) > pruneInterval else { return }
        lastPruneDate = now
        guard let files = try? fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        let cutoff = now.addingTimeInterval(-maxAge)
        for file in files {
            guard let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = attrs.contentModificationDate,
                  modDate < cutoff
            else { continue }
            try? fileManager.removeItem(at: file)
        }
    }
}
