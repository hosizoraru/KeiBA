//
//  BaMusicPlaybackSessionTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

import Foundation
@testable import KeiBAOS
import XCTest

@MainActor
final class BaMusicPlaybackSessionTests: XCTestCase {
    func testDefaultRepeatModeUsesSequentialLoop() {
        let session = BaMusicPlaybackSession(
            audioCache: FakeAudioCache(),
            systemMediaController: RecordingSystemMediaController()
        )

        XCTAssertEqual(session.repeatMode, .all)
        XCTAssertTrue(session.repeatMode.isActive)
    }

    func testPreviousActionRestartsCurrentTrackAfterPlaybackHasAdvanced() {
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.previousAction(elapsedTime: 2.9),
            .moveToPreviousTrack
        )
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.previousAction(elapsedTime: 3),
            .restartCurrentTrack
        )
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.previousAction(elapsedTime: 42),
            .restartCurrentTrack
        )
    }

    func testQueueNavigationWrapsForSequentialLoop() {
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.nextIndex(after: 2, queueCount: 3, wraps: true),
            0
        )
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.nextIndex(after: 2, queueCount: 3, wraps: false),
            nil
        )
        XCTAssertEqual(
            BaMusicPlaybackNavigationPolicy.previousIndex(before: 0, queueCount: 3, wraps: true),
            2
        )
    }

    func testMiniNowPlayingUsesExpandedOnlyInsideMusicContext() {
        XCTAssertEqual(
            BaMusicMiniNowPlayingDisplayMode.resolved(
                prefersExpanded: true,
                systemPlacementIsExpanded: true
            ),
            .expanded
        )
        XCTAssertEqual(
            BaMusicMiniNowPlayingDisplayMode.resolved(
                prefersExpanded: true,
                systemPlacementIsExpanded: false
            ),
            .mini
        )
        XCTAssertEqual(
            BaMusicMiniNowPlayingDisplayMode.resolved(
                prefersExpanded: false,
                systemPlacementIsExpanded: true
            ),
            .mini
        )
    }

    func testTouchMusicLibraryKeepsStackedLayoutForSidebarWidths() {
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.layoutStyle(
                for: BaAdaptiveMetrics(containerWidth: 1_024),
                platform: .touch,
                navigationChrome: .sidebar
            ),
            .stacked
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.layoutStyle(
                for: BaAdaptiveMetrics(containerWidth: 1_366),
                platform: .touch,
                navigationChrome: .sidebar
            ),
            .stacked
        )
    }

    func testTouchMusicLibraryUsesSplitForWideTopBarPlacement() {
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.layoutStyle(
                for: BaAdaptiveMetrics(containerWidth: 1_024),
                platform: .touch,
                navigationChrome: .topBar
            ),
            .split
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.contentMaxWidth(
                for: BaAdaptiveMetrics(containerWidth: 1_366),
                platform: .touch,
                navigationChrome: .topBar
            ),
            1_180
        )
    }

    func testDesktopMusicLibraryUsesSplitOnlyWhenThereIsRoom() {
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.layoutStyle(
                for: BaAdaptiveMetrics(containerWidth: 960),
                platform: .desktop
            ),
            .stacked
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.layoutStyle(
                for: BaAdaptiveMetrics(containerWidth: 1_180),
                platform: .desktop
            ),
            .split
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.heroColumnWidth(for: BaAdaptiveMetrics(containerWidth: 1_180)),
            401.2,
            accuracy: 0.01
        )
    }

    func testFullNowPlayingHeroUsesSideBySideOnlyWhenThereIsRoom() {
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.automaticHeroLayout(
                for: BaAdaptiveMetrics(containerWidth: 740),
                presentation: .full
            ),
            .stacked
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.automaticHeroLayout(
                for: BaAdaptiveMetrics(containerWidth: 820),
                presentation: .full
            ),
            .sideBySide
        )
        XCTAssertEqual(
            BaMusicLibraryLayoutPolicy.automaticHeroLayout(
                for: BaAdaptiveMetrics(containerWidth: 1_180),
                presentation: .inline
            ),
            .stacked
        )
    }

    func testNowPlayingMetadataKeepsTrackAndQueueContext() throws {
        let track = try musicTrack(contentId: 1001, title: "日奈(礼服)", audioFileName: "hina.ogg")
        let metadata = BaMusicNowPlayingMetadata(
            track: track,
            elapsedTime: 42,
            duration: 186,
            isPlaying: true,
            queueIndex: 1,
            queueCount: 3
        )

        XCTAssertEqual(metadata.title, "日奈(礼服)")
        XCTAssertEqual(metadata.subtitle, "回忆大厅 BGM")
        XCTAssertEqual(metadata.artworkURL, track.artworkURL)
        XCTAssertEqual(metadata.elapsedTime, 42)
        XCTAssertEqual(metadata.duration, 186)
        XCTAssertEqual(metadata.playbackRate, 1)
        XCTAssertEqual(metadata.queueIndex, 1)
        XCTAssertEqual(metadata.queueCount, 3)
    }

    func testNowPlayingMetadataDropsInvalidTimingValues() throws {
        let track = try musicTrack(contentId: 1002, title: "爱丽丝", audioFileName: "alice.ogg")
        let metadata = BaMusicNowPlayingMetadata(
            track: track,
            elapsedTime: -4,
            duration: .nan,
            isPlaying: false,
            queueIndex: nil,
            queueCount: -2
        )

        XCTAssertEqual(metadata.elapsedTime, 0)
        XCTAssertNil(metadata.duration)
        XCTAssertEqual(metadata.playbackRate, 0)
        XCTAssertNil(metadata.queueIndex)
        XCTAssertEqual(metadata.queueCount, 0)
    }

    func testPlaybackTimeFormatterUsesMusicTimeStyle() {
        XCTAssertEqual(BaMusicPlaybackTimeFormatter.string(from: 0), "0:00")
        XCTAssertEqual(BaMusicPlaybackTimeFormatter.string(from: 65.8), "1:05")
        XCTAssertEqual(BaMusicPlaybackTimeFormatter.string(from: 601), "10:01")
        XCTAssertEqual(BaMusicPlaybackTimeFormatter.string(from: .infinity), BaMusicPlaybackTimeFormatter.placeholder)
    }

    func testRemoteNextCommandUpdatesSelectedTrackAndSystemMetadata() throws {
        let audioCache = FakeAudioCache()
        let systemMediaController = RecordingSystemMediaController()
        let session = BaMusicPlaybackSession(
            audioCache: audioCache,
            systemMediaController: systemMediaController
        )
        let firstTrack = try musicTrack(contentId: 2001, title: "日奈(礼服)", audioFileName: "hina.ogg")
        let nextTrack = try musicTrack(contentId: 2002, title: "爱丽丝(临战)", audioFileName: "alice.ogg")

        session.updateQueue([firstTrack, nextTrack])
        session.selectedTrack = firstTrack

        XCTAssertTrue(session.handleSystemMediaCommand(.next))

        XCTAssertEqual(session.selectedTrack?.id, nextTrack.id)
        XCTAssertEqual(systemMediaController.updates.last?.title, "爱丽丝(临战)")
        XCTAssertEqual(systemMediaController.updates.last?.queueIndex, 1)
        XCTAssertEqual(systemMediaController.updates.last?.queueCount, 2)
    }

    func testStopClearsSystemMediaState() throws {
        let systemMediaController = RecordingSystemMediaController()
        let session = BaMusicPlaybackSession(
            audioCache: FakeAudioCache(),
            systemMediaController: systemMediaController
        )
        session.selectedTrack = try musicTrack(contentId: 3001, title: "星野", audioFileName: "hoshino.ogg")

        session.stop()

        XCTAssertEqual(systemMediaController.clearCount, 1)
        XCTAssertNil(session.selectedTrack)
    }

    func testRemoteStopCommandClearsPlaybackOnce() throws {
        let systemMediaController = RecordingSystemMediaController()
        let session = BaMusicPlaybackSession(
            audioCache: FakeAudioCache(),
            systemMediaController: systemMediaController
        )
        session.selectedTrack = try musicTrack(contentId: 3002, title: "爱丽丝", audioFileName: "alice.ogg")

        XCTAssertTrue(session.handleSystemMediaCommand(.stop))

        XCTAssertEqual(systemMediaController.clearCount, 1)
        XCTAssertNil(session.selectedTrack)
    }

    func testCacheAllCachesPlayableTracks() async throws {
        let audioCache = FakeAudioCache()
        let session = BaMusicPlaybackSession(
            audioCache: audioCache,
            systemMediaController: RecordingSystemMediaController()
        )
        let firstTrack = try musicTrack(contentId: 4001, title: "日奈(礼服)", audioFileName: "hina.ogg")
        let nextTrack = try musicTrack(contentId: 4002, title: "爱丽丝(临战)", audioFileName: "alice.ogg")

        session.cacheAll([firstTrack, nextTrack])
        try await Task.sleep(for: .milliseconds(60))

        XCTAssertTrue(session.cacheState(for: firstTrack).isCached)
        XCTAssertTrue(session.cacheState(for: nextTrack).isCached)
        let cachedAudioURLs = await audioCache.cachedAudioURLs()
        XCTAssertEqual(cachedAudioURLs, Set([try XCTUnwrap(firstTrack.audioURL), try XCTUnwrap(nextTrack.audioURL)]))
    }

    func testClearCacheRemovesCachedTrackState() async throws {
        let audioCache = FakeAudioCache()
        let session = BaMusicPlaybackSession(
            audioCache: audioCache,
            systemMediaController: RecordingSystemMediaController()
        )
        let track = try musicTrack(contentId: 5001, title: "柯伊", audioFileName: "kei.ogg")

        session.cache(track)
        try await Task.sleep(for: .milliseconds(60))
        session.clearCache(for: track)
        try await Task.sleep(for: .milliseconds(60))

        XCTAssertFalse(session.cacheState(for: track).isCached)
        let cachedAudioURLs = await audioCache.cachedAudioURLs()
        let removedAudioURLs = await audioCache.removedAudioURLs()
        XCTAssertEqual(cachedAudioURLs, [])
        XCTAssertEqual(removedAudioURLs, [try XCTUnwrap(track.audioURL)])
    }

    private func musicTrack(
        contentId: Int64,
        title: String,
        audioFileName: String
    ) throws -> BaMusicTrack {
        let audioURL = try XCTUnwrap(URL(string: "https://static.example.com/\(audioFileName)"))
        let entry = BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: BaCatalogCategory.students.gameKeePID,
            contentId: contentId,
            name: title,
            alias: "",
            aliasDisplay: "",
            iconURL: URL(string: "https://static.example.com/\(contentId).png"),
            type: 0,
            order: Int(contentId),
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/\(contentId).html"),
            category: .students
        )
        return BaMusicTrack(
            entry: entry,
            title: title,
            subtitle: "回忆大厅 BGM",
            artworkURL: entry.iconURL,
            audioURL: audioURL,
            sourceURL: entry.detailURL,
            galleryTitle: "BGM",
            availability: .ready
        )
    }
}

private final class RecordingSystemMediaController: BaMusicSystemMediaControlling {
    weak var commandHandler: BaMusicSystemMediaCommandHandling?
    private(set) var updates: [BaMusicNowPlayingMetadata] = []
    private(set) var clearCount = 0

    func configure(commandHandler: BaMusicSystemMediaCommandHandling) {
        self.commandHandler = commandHandler
    }

    func update(metadata: BaMusicNowPlayingMetadata) {
        updates.append(metadata)
    }

    func clear() {
        clearCount += 1
    }
}

private actor FakeAudioCache: BaAudioCaching {
    private var cachedURLs: Set<URL> = []
    private var removedURLs: [URL] = []

    func localURL(for url: URL, refererPath _: String) async throws -> URL {
        cachedURLs.insert(url)
        return FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
    }

    func cachedURL(for url: URL) async -> URL? {
        guard cachedURLs.contains(url) else { return nil }
        return FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
    }

    func isCached(_ url: URL) async -> Bool {
        cachedURLs.contains(url)
    }

    func removeCachedAudio(for url: URL) async {
        cachedURLs.remove(url)
        removedURLs.append(url)
    }

    func cachedAudioURLs() async -> Set<URL> {
        cachedURLs
    }

    func removedAudioURLs() async -> [URL] {
        removedURLs
    }
}
