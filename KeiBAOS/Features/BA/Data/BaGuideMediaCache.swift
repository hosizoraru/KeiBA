//
//  BaGuideMediaCache.swift
//  KeiBAOS
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
    private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaGuideMediaCache")

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
        if let data = try? Data(contentsOf: fileURL), data.isEmpty == false {
            logger.debug("guide media cache hit \(url.host ?? "unknown", privacy: .public)")
            return fileURL
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
            deferredFailures[url] = Date().addingTimeInterval(failureTTL)
            throw error
        }
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
}
