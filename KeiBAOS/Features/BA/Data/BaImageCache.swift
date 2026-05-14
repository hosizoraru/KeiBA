//
//  BaImageCache.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import CryptoKit
import Foundation
import os

actor BaImageCache {
    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL
    private var deferredFailures: [URL: Date] = [:]
    private var hitCount = 0
    private var missCount = 0
    private var failureCount = 0
    private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaImageCache")
    private let failureTTL: TimeInterval = 45

    init(fileManager: FileManager = .default, client: GameKeeClient) {
        self.fileManager = fileManager
        self.client = client
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BAImages", isDirectory: true)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    func data(for url: URL, refererPath: String = "/ba") async throws -> Data {
        let fileURL = cachedFileURL(for: url)
        if let data = try? Data(contentsOf: fileURL), data.isEmpty == false {
            hitCount += 1
            logger.debug("image cache hit \(url.host ?? "unknown", privacy: .public)")
            return data
        }
        if let retryAt = deferredFailures[url], retryAt > Date() {
            throw GameKeeError.invalidResponse("Image retry deferred")
        }
        deferredFailures[url] = nil
        missCount += 1
        let data: Data
        do {
            data = try await client.fetchImageData(url: url, refererPath: refererPath)
        } catch {
            recordFailure(for: url)
            throw error
        }
        do {
            try data.write(to: fileURL, options: [.atomic])
            logger.debug("image cache stored \(url.host ?? "unknown", privacy: .public) bytes=\(data.count, privacy: .public)")
        } catch {
            logger.debug("image cache write failed \(error.localizedDescription, privacy: .public)")
        }
        return data
    }

    func recordFailure(for url: URL) {
        failureCount += 1
        deferredFailures[url] = Date().addingTimeInterval(failureTTL)
        logger.debug("image cache deferred \(url.host ?? "unknown", privacy: .public)")
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        deferredFailures.removeAll()
        hitCount = 0
        missCount = 0
        failureCount = 0
    }

    func summary() -> String {
        let fileCount = (try? fileManager.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: nil).count) ?? 0
        return "files=\(fileCount) hits=\(hitCount) misses=\(missCount) failures=\(failureCount)"
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }
}
