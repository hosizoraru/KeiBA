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

    func load<Value: Codable>(_: Value.Type, for key: CacheKey) -> BaCacheEnvelope<Value>? {
        let url = rootDirectory.appendingPathComponent(key.filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.ba.decode(BaCacheEnvelope<Value>.self, from: data)
    }

    func save<Value: Codable>(_ value: Value, for key: CacheKey, schemaVersion: Int, syncedAt: Date = Date()) {
        let envelope = BaCacheEnvelope(schemaVersion: schemaVersion, syncedAt: syncedAt, value: value)
        guard let data = try? JSONEncoder.ba.encode(envelope) else { return }
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let url = rootDirectory.appendingPathComponent(key.filename)
        try? data.write(to: url, options: [.atomic])
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }
}

extension JSONEncoder {
    // Shared encoder reused across cache writes. JSONEncoder is documented as safe
    // to use from multiple threads as long as configuration is not mutated after
    // creation; we never mutate it after this initial setup.
    nonisolated(unsafe) static let ba: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
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
