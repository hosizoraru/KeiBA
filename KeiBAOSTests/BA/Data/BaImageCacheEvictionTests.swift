//
//  BaImageCacheEvictionTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/29.
//

@testable import KeiBAOS
import Foundation
import XCTest

final class BaImageCacheEvictionTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testPruneRemovesFilesOlderThanMaxAge() async throws {
        let cacheDir = tempDir.appendingPathComponent("BAImages", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let cache = BaImageCache(rootDirectory: cacheDir, client: GameKeeClient())

        let freshFile = cacheDir.appendingPathComponent("fresh.img")
        let staleFile = cacheDir.appendingPathComponent("stale.img")
        let data = Data("test".utf8)
        try data.write(to: freshFile)
        try data.write(to: staleFile)

        let staleDate = Date().addingTimeInterval(-8 * 24 * 3600)
        try FileManager.default.setAttributes(
            [.modificationDate: staleDate],
            ofItemAtPath: staleFile.path
        )

        await cache.pruneStaleDiskCache(maxAge: 7 * 24 * 3600)

        XCTAssertTrue(FileManager.default.fileExists(atPath: freshFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFile.path))
    }

    func testPruneKeepsFilesWithinMaxAge() async throws {
        let cacheDir = tempDir.appendingPathComponent("BAImages", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let cache = BaImageCache(rootDirectory: cacheDir, client: GameKeeClient())

        let freshFile = cacheDir.appendingPathComponent("fresh.img")
        let data = Data("test".utf8)
        try data.write(to: freshFile)

        let freshDate = Date().addingTimeInterval(-3 * 24 * 3600)
        try FileManager.default.setAttributes(
            [.modificationDate: freshDate],
            ofItemAtPath: freshFile.path
        )

        await cache.pruneStaleDiskCache(maxAge: 7 * 24 * 3600)

        XCTAssertTrue(FileManager.default.fileExists(atPath: freshFile.path))
    }

    func testPruneRespectsIntervalThrottle() async throws {
        let cacheDir = tempDir.appendingPathComponent("BAImages", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let cache = BaImageCache(rootDirectory: cacheDir, client: GameKeeClient())

        let staleFile = cacheDir.appendingPathComponent("stale.img")
        let data = Data("test".utf8)
        try data.write(to: staleFile)

        let staleDate = Date().addingTimeInterval(-8 * 24 * 3600)
        try FileManager.default.setAttributes(
            [.modificationDate: staleDate],
            ofItemAtPath: staleFile.path
        )

        // First prune should work
        await cache.pruneStaleDiskCache(maxAge: 7 * 24 * 3600)
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFile.path))

        // Re-create the stale file
        try data.write(to: staleFile)
        try FileManager.default.setAttributes(
            [.modificationDate: staleDate],
            ofItemAtPath: staleFile.path
        )

        // Second prune immediately should be throttled
        await cache.pruneStaleDiskCache(maxAge: 7 * 24 * 3600)
        XCTAssertTrue(FileManager.default.fileExists(atPath: staleFile.path))
    }
}
