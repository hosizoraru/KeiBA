//
//  BaCacheStore.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

actor BaCacheStore {
    enum CacheKey {
        case activities(BaServer)
        case pools(BaServer)
        case catalog
        case studentDetail(Int64)

        var filename: String {
            switch self {
            case let .activities(server):
                "activities-\(server.rawValue).json"
            case let .pools(server):
                "pools-\(server.rawValue).json"
            case .catalog:
                "catalog.json"
            case let .studentDetail(contentId):
                "student-\(contentId).json"
            }
        }
    }

    private let fileManager: FileManager
    private let rootDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootDirectory = base.appendingPathComponent("BA", isDirectory: true)
    }

    func load<Value: Codable & Sendable>(_: Value.Type, for key: CacheKey) async -> BaCacheEnvelope<Value>? {
        // Read + decode off the actor: the catalog hydrator and pool resolver
        // iterate hundreds of cached student-detail files, and even though
        // BaCacheStore runs on its own serial executor, every load() blocked
        // every other cache user (timeline writes, image-cache bookkeeping
        // that calls back into shared utilities). Hopping the work to a
        // detached utility task keeps the actor free for short bookkeeping
        // operations and lets the OS schedule decodes in parallel.
        let url = rootDirectory.appendingPathComponent(key.filename)
        return await Self.readEnvelope(from: url)
    }

    func save<Value: Codable & Sendable>(_ value: Value, for key: CacheKey, schemaVersion: Int, syncedAt: Date = Date()) async {
        let envelope = BaCacheEnvelope(schemaVersion: schemaVersion, syncedAt: syncedAt, value: value)
        let url = rootDirectory.appendingPathComponent(key.filename)
        let rootDirectory = self.rootDirectory
        let fileManager = self.fileManager
        await Task.detached(priority: .utility) {
            guard let data = try? JSONEncoder.ba.encode(envelope) else { return }
            try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            try? data.write(to: url, options: [.atomic])
        }.value
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private nonisolated static func readEnvelope<Value: Codable & Sendable>(from url: URL) async -> BaCacheEnvelope<Value>? {
        await Task.detached(priority: .utility) {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder.ba.decode(BaCacheEnvelope<Value>.self, from: data)
        }.value
    }
}

extension JSONEncoder {
    // Shared encoder reused across cache writes. JSONEncoder is documented as safe
    // to use from multiple threads as long as configuration is not mutated after
    // creation; we never mutate it after this initial setup.
    //
    // No `.prettyPrinted` — cache files are read by the app, never by humans.
    // Pretty printing roughly doubles the on-disk size and the encode CPU cost,
    // which matters for the catalog snapshot (hundreds of KB) and the per-student
    // detail caches written on every refresh.
    nonisolated(unsafe) static let ba: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    // Shared decoder reused across cache reads. See note on JSONEncoder.ba.
    nonisolated(unsafe) static let ba: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
