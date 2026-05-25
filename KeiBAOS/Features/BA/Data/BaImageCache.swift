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
    private struct RequestKey: Hashable {
        let url: URL
        let refererPath: String
    }

    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL
    // NSCache is thread-safe so it lives outside actor isolation. The fast path
    // can serve hits without bouncing through the actor, which matters when
    // SwiftUI grids re-issue the same URL during scroll/recompose.
    private nonisolated let memoryCache: NSCache<NSURL, NSData> = {
        let cache = NSCache<NSURL, NSData>()
        cache.name = "os.kei.KeiBAOS.BaImageCache"
        cache.countLimit = BaPlatformPerformanceProfile.imageMemoryCacheCountLimit
        cache.totalCostLimit = BaPlatformPerformanceProfile.imageMemoryCacheCostLimit
        return cache
    }()
    private var inFlightRequests: [RequestKey: Task<Data, Error>] = [:]
    private var deferredFailures: [URL: Date] = [:]
    private var hitCount = 0
    private var missCount = 0
    private var memoryHitCount = 0
    private var failureCount = 0
    private let logger = Logger(subsystem: "os.kei.KeiBAOS", category: "BaImageCache")
    private let failureTTL: TimeInterval = 45
    // Defensive cap so a long-running session never accumulates an unbounded
    // backlog of failed URLs. Random eviction is fine because entries are
    // short-lived (failureTTL) and only used to back off retries.
    private let deferredFailureCap = 256

    init(fileManager: FileManager = .default, client: GameKeeClient) {
        self.fileManager = fileManager
        self.client = client
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BAImages", isDirectory: true)
    }

    func data(for url: URL, refererPath: String = "/ba") async throws -> Data {
        // Fast path: in-memory hit. NSCache is thread-safe, so this resolves
        // without any actor hop and avoids both the disk read and the
        // signature scan that disk hits perform.
        if let cached = memoryCache.object(forKey: url as NSURL) {
            memoryHitCount += 1
            return Data(referencing: cached)
        }

        // Disk hit: read off the actor so a slow disk doesn't serialize every
        // other image lookup behind it. SwiftUI grids reissue many thumbnail
        // requests in parallel during scroll/recompose; running the
        // Data(contentsOf:) + signature scan on the actor's serial executor
        // turned that into a head-of-line block.
        let fileURL = cachedFileURL(for: url)
        if let data = await Self.readCachedImage(at: fileURL), data.isEmpty == false {
            if Self.looksLikeImageData(data) {
                hitCount += 1
                memoryCache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
                return data
            }
            try? fileManager.removeItem(at: fileURL)
            logger.debug("image cache invalidated \(url.host ?? "unknown", privacy: .public)")
        }
        if let retryAt = deferredFailures[url], retryAt > Date() {
            throw GameKeeError.invalidResponse("Image retry deferred")
        }
        deferredFailures[url] = nil
        let requestKey = RequestKey(url: url, refererPath: refererPath)
        if let inFlightRequest = inFlightRequests[requestKey] {
            return try await inFlightRequest.value
        }

        missCount += 1
        let request = Task.detached(priority: .utility) { [client] in
            try await client.fetchImageData(url: url, refererPath: refererPath)
        }
        inFlightRequests[requestKey] = request
        let data: Data
        do {
            data = try await request.value
            inFlightRequests[requestKey] = nil
        } catch {
            inFlightRequests[requestKey] = nil
            if Self.isCancellation(error) == false {
                recordFailure(for: url)
            }
            throw error
        }
        memoryCache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        do {
            try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
            logger.debug("image cache stored \(url.host ?? "unknown", privacy: .public) bytes=\(data.count, privacy: .public)")
        } catch {
            logger.debug("image cache write failed \(error.localizedDescription, privacy: .public)")
        }
        return data
    }

    func recordFailure(for url: URL) {
        failureCount += 1
        pruneExpiredFailures()
        if deferredFailures.count >= deferredFailureCap {
            // Drop an arbitrary entry; backoff windows naturally rotate as TTLs
            // expire. Picking the first key is O(1) on Dictionary and avoids a
            // sort over the whole map.
            if let staleKey = deferredFailures.keys.first {
                deferredFailures.removeValue(forKey: staleKey)
            }
        }
        deferredFailures[url] = Date().addingTimeInterval(failureTTL)
        logger.debug("image cache deferred \(url.host ?? "unknown", privacy: .public)")
    }

    private func pruneExpiredFailures() {
        let now = Date()
        deferredFailures = deferredFailures.filter { $0.value > now }
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        memoryCache.removeAllObjects()
        for request in inFlightRequests.values {
            request.cancel()
        }
        inFlightRequests.removeAll()
        deferredFailures.removeAll()
        hitCount = 0
        missCount = 0
        memoryHitCount = 0
        failureCount = 0
    }

    func summary() -> String {
        let fileCount = (try? fileManager.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: nil).count) ?? 0
        return "files=\(fileCount) memHits=\(memoryHitCount) hits=\(hitCount) misses=\(missCount) failures=\(failureCount)"
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }

    private nonisolated static func looksLikeImageData(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(16))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return true }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return true }
        if bytes.starts(with: [0x47, 0x49, 0x46]) { return true }
        if bytes.count >= 12,
           bytes[0 ..< 4].elementsEqual([0x52, 0x49, 0x46, 0x46]),
           bytes[8 ..< 12].elementsEqual([0x57, 0x45, 0x42, 0x50])
        {
            return true
        }
        guard let head = String(data: data.prefix(128), encoding: .utf8) else {
            return false
        }
        return head.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("<svg")
    }

    private nonisolated static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    // Read the cache file off the actor so a slow disk doesn't serialize the
    // rest of the actor's work. Returns nil for missing files; throws are
    // swallowed because callers treat any failure as "no hit."
    private nonisolated static func readCachedImage(at fileURL: URL) async -> Data? {
        await Task.detached(priority: .utility) {
            try? Data(contentsOf: fileURL)
        }.value
    }
}
