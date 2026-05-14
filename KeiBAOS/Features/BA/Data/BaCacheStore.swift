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
            case .activities(let server):
                "activities-\(server.rawValue).json"
            case .pools(let server):
                "pools-\(server.rawValue).json"
            case .catalog:
                "catalog.json"
            case .studentDetail(let contentId):
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
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    func load<Value: Codable>(_ type: Value.Type, for key: CacheKey) -> BaCacheEnvelope<Value>? {
        let url = rootDirectory.appendingPathComponent(key.filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.ba.decode(BaCacheEnvelope<Value>.self, from: data)
    }

    func save<Value: Codable>(_ value: Value, for key: CacheKey, schemaVersion: Int, syncedAt: Date = Date()) {
        let envelope = BaCacheEnvelope(schemaVersion: schemaVersion, syncedAt: syncedAt, value: value)
        guard let data = try? JSONEncoder.ba.encode(envelope) else { return }
        let url = rootDirectory.appendingPathComponent(key.filename)
        try? data.write(to: url, options: [.atomic])
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }
}

extension JSONEncoder {
    nonisolated static var ba: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    nonisolated static var ba: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
