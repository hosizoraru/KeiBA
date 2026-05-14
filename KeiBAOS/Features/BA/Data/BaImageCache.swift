//
//  BaImageCache.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import CryptoKit
import Foundation

actor BaImageCache {
    private let fileManager: FileManager
    private let client: GameKeeClient
    private let rootDirectory: URL

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
            return data
        }
        let data = try await client.fetchImageData(url: url, refererPath: refererPath)
        try? data.write(to: fileURL, options: [.atomic])
        return data
    }

    func clear() {
        try? fileManager.removeItem(at: rootDirectory)
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private func cachedFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
        return rootDirectory.appendingPathComponent("\(hash).\(ext)")
    }
}
