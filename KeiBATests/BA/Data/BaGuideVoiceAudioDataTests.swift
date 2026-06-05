//
//  BaGuideVoiceAudioDataTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import AVFAudio
import Foundation
import XCTest

final class BaGuideVoiceAudioDataTests: XCTestCase {
    func testGiftParserKeepsGiftAndEmojiImages() {
        let baseData: [[BaJSONObject]] = [
            [["value": "礼物偏好"]],
            [
                ["value": #"<img class="gif-emoji" src="//cdnimg.gamekee.com/w_61/h_61/emoji.webp">"#],
                ["value": #"<img class="gif-img" src="//cdnimg.gamekee.com/items/gift.webp">喜欢"#],
            ],
        ]
        let rows = BaGuideGiftParser().parse(baseData: baseData, sourceURL: nil)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].imageURL?.absoluteString, "https://cdnimg.gamekee.com/items/gift.webp")
        XCTAssertEqual(
            rows[0].imageURLs?.map(\.absoluteString),
            [
                "https://cdnimg.gamekee.com/items/gift.webp",
                "https://cdnimg.gamekee.com/w_61/h_61/emoji.webp",
            ]
        )
    }

    func testVoiceParserSortsLanguageLines() {
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "配音语言"],
                ["value": "中配"],
                ["value": "日配"],
                ["value": "韩配"],
            ],
            [
                ["value": "通常"],
                ["value": "标题"],
                ["value": "中文"],
                ["value": "日本語"],
                ["value": "한국어"],
            ],
        ]
        let rows = BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).entries

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].lineHeaders, ["日配", "中配", "韩配"])
        XCTAssertEqual(rows[0].lines, ["日本語", "中文", "한국어"])
    }

    func testVoiceParserAlignsAudioURLsAfterLanguageSort() throws {
        let cnURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/cn.mp3"))
        let jpURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.mp3"))
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "配音语言"],
                ["value": "中配"],
                ["value": "日配"],
            ],
            [
                ["value": "通常"],
                ["value": "大厅1"],
                ["value": "中文台词"],
                ["value": "日本語"],
                ["type": "audio", "value": cnURL.absoluteString],
                ["type": "audio", "value": jpURL.absoluteString],
            ],
        ]
        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).entries.first)

        XCTAssertEqual(entry.title, "大厅1")
        XCTAssertEqual(entry.lineHeaders, ["日配", "中配"])
        XCTAssertEqual(entry.lines, ["日本語", "中文台词"])
        XCTAssertEqual(entry.audioURLs, [jpURL, cnURL])
        XCTAssertEqual(entry.audioHeaders, ["日配", "中配"])
    }

    func testVoiceResolverChoosesAudioForSelectedLanguage() throws {
        let jpURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.mp3"))
        let cnURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/cn.mp3"))
        let entry = BaGuideVoiceEntry(
            id: "voice-1",
            title: "登录",
            subtitle: "通常",
            transcript: "JP\nCN",
            audioURL: jpURL,
            section: "通常",
            lineHeaders: ["日配", "中配", "官翻"],
            lines: ["JP", "CN", "官方翻译"],
            audioURLs: [jpURL, cnURL],
            audioHeaders: ["日配", "中配"]
        )

        let headers = BaVoiceLanguageResolver.playbackHeaders(for: [entry])
        XCTAssertEqual(headers, ["日配", "中配"])
        XCTAssertEqual(
            BaVoiceLanguageResolver.playbackURL(for: entry, headers: headers, selectedHeader: "中配"),
            cnURL
        )
        let jpOnlyEntry = BaGuideVoiceEntry(
            id: "voice-2",
            title: "登录",
            subtitle: "通常",
            transcript: "JP\nCN",
            audioURL: jpURL,
            section: "通常",
            lineHeaders: ["日配", "中配"],
            lines: ["JP", "CN"],
            audioURLs: [jpURL],
            audioHeaders: ["日配"]
        )
        XCTAssertEqual(
            BaVoiceLanguageResolver.playbackURL(for: jpOnlyEntry, headers: ["日配", "中配"], selectedHeader: "中配"),
            nil
        )
        XCTAssertEqual(
            BaVoiceLanguageResolver.linePairs(for: entry, fallbackHeaders: headers).map(\.language),
            ["日配", "中配", "官翻"]
        )
    }

    func testVoiceParserKeepsHinaDressTitleAudioIndependentFromTextOnlyTitleRows() throws {
        let hinaJp = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/43637/2025/4/26/648025.ogg"))
        let hinaCn = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2025/7/7/602581.ogg"))
        let hinaKr = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/157597/2025/5/17/23446.ogg"))
        let kurumiPool = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/492704/2026/3/22/64891.ogg"))
        let headers: [BaJSONObject] = [
            ["value": "配音语言"],
            ["value": ""],
            ["value": ""],
            ["value": ""],
            ["value": "日配"],
            ["value": ""],
            ["value": "中配"],
            ["value": "韩配"],
        ]
        let hinaRows: [[BaJSONObject]] = [
            headers,
            [
                ["value": "通常"],
                ["value": "标题"],
                ["value": "ブルーアーカイブ。"],
                ["value": "碧蓝档案。"],
                ["type": "audio", "value": hinaJp.absoluteString],
                ["value": "Blue Archive"],
                ["type": "audio", "value": hinaCn.absoluteString],
                ["type": "audio", "value": hinaKr.absoluteString],
            ],
        ]
        let kurumiRows: [[BaJSONObject]] = [
            headers,
            [
                ["value": "通常"],
                ["value": "标题"],
                ["value": "ブルーアーカイブ。"],
                ["value": "蔚蓝档案。"],
                ["value": ""],
                ["value": ""],
                ["value": ""],
                ["value": ""],
            ],
            [
                ["value": "通常"],
                ["value": "卡池抽取"],
                ["value": "SRT 特殊学園、FOX 小隊のポイントマン、高倉クルミよ。"],
                ["value": "我是 SRT 特殊学园，FOX 小队的尖兵，高仓胡桃。"],
                ["type": "audio", "value": kurumiPool.absoluteString],
                ["value": ""],
                ["value": ""],
                ["value": ""],
            ],
        ]

        let hinaParse = BaGuideVoiceParser().parse(baseData: hinaRows, content: nil, sourceURL: nil)
        let kurumiParse = BaGuideVoiceParser().parse(baseData: kurumiRows, content: nil, sourceURL: nil)
        let hinaTitle = try XCTUnwrap(hinaParse.entries.first)
        let kurumiEntries = kurumiParse.entries
        let kurumiTitle = try XCTUnwrap(kurumiEntries.first { $0.title == "标题" })
        let kurumiPoolEntry = try XCTUnwrap(kurumiEntries.first { $0.title == "卡池抽取" })
        let allEntries = [hinaTitle, kurumiTitle, kurumiPoolEntry]
        let playbackHeaders = BaVoiceLanguageResolver.playbackHeaders(for: allEntries)

        XCTAssertEqual(hinaParse.languageHeaders, ["日配", "中配", "韩配"])
        XCTAssertEqual(kurumiParse.languageHeaders, ["日配", "中配", "韩配"])
        XCTAssertEqual(BaVoiceLanguageResolver.playbackHeaders(for: kurumiEntries), ["日配"])
        XCTAssertEqual(hinaTitle.lineHeaders, ["日配", "中配", "官翻"])
        XCTAssertEqual(hinaTitle.audioURLs, [hinaJp, hinaCn, hinaKr])
        XCTAssertEqual(hinaTitle.audioHeaders, ["日配", "中配", "韩配"])
        XCTAssertEqual(BaVoiceLanguageResolver.playbackURL(for: hinaTitle, headers: playbackHeaders, selectedHeader: "日配"), hinaJp)
        XCTAssertEqual(BaVoiceLanguageResolver.playbackURL(for: hinaTitle, headers: playbackHeaders, selectedHeader: "韩配"), hinaKr)

        XCTAssertNil(kurumiTitle.audioURL)
        XCTAssertNil(BaVoiceLanguageResolver.playbackURL(for: kurumiTitle, headers: playbackHeaders, selectedHeader: "日配"))
        XCTAssertEqual(kurumiPoolEntry.audioHeaders, ["日配"])
        XCTAssertEqual(BaVoiceLanguageResolver.playbackURL(for: kurumiPoolEntry, headers: playbackHeaders, selectedHeader: "日配"), kurumiPool)
    }

    func testVoicePlaybackSupportsOggPlaybackBackends() throws {
        let mp3URL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.mp3"))
        let oggURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.ogg"))
        let opusURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.opus"))
        let flacURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.flac"))
        let unknownVoiceURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/play"))
        let pageURL = try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/detail"))

        XCTAssertTrue(BaVoicePlaybackController.supportsNativePlayback(mp3URL))
        XCTAssertEqual(BaVoicePlaybackController.preferredBackendNameForTesting(mp3URL), "avFoundation")
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(mp3URL))
        XCTAssertFalse(BaVoicePlaybackController.supportsNativePlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsOggPlayback(oggURL))
        XCTAssertEqual(BaVoicePlaybackController.preferredBackendNameForTesting(oggURL), "decodedOgg")
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(oggURL))
        XCTAssertFalse(BaVoicePlaybackController.supportsOggPlayback(opusURL))
        XCTAssertEqual(BaVoicePlaybackController.preferredBackendNameForTesting(opusURL), "avFoundation")
        XCTAssertFalse(BaVoicePlaybackController.supportsPlayback(opusURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsNativePlayback(flacURL))
        XCTAssertEqual(BaVoicePlaybackController.preferredBackendNameForTesting(flacURL), "avFoundation")
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(flacURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(unknownVoiceURL))
        XCTAssertFalse(BaVoicePlaybackController.supportsPlayback(pageURL))
    }

    func testMusicPlaybackDecodesOggForLongBGM() throws {
        let oggURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/bgm/memory.ogg"))
        let opusURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/bgm/memory.opus"))
        let mp3URL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/bgm/memory.mp3"))

        XCTAssertEqual(BaVoicePlaybackController.preferredMusicBackendNameForTesting(oggURL), "decodedOgg")
        XCTAssertEqual(BaVoicePlaybackController.preferredMusicBackendNameForTesting(opusURL), "avFoundation")
        XCTAssertEqual(BaVoicePlaybackController.preferredMusicBackendNameForTesting(mp3URL), "avFoundation")
        XCTAssertEqual(
            BaVoicePlaybackController.preferredOggPlaybackModeNameForTesting(oggURL, profile: .music),
            "decodedPreferred"
        )
        XCTAssertEqual(
            BaVoicePlaybackController.preferredOggPlaybackModeNameForTesting(opusURL, profile: .music),
            "decodedPreferred"
        )
        XCTAssertEqual(
            BaVoicePlaybackController.preferredOggPlaybackModeNameForTesting(oggURL, profile: .voice),
            "decodedPreferred"
        )
    }

    func testShortGameKeeOggDecoderBuildsPlayablePCMBuffer() async throws {
        let data = try await fetchHinaDressTitleOggFixtureDataForTesting()

        let decoded = try BaOggVorbisDecoder().decode(data: data)

        XCTAssertGreaterThan(decoded.duration, 0.5)
        XCTAssertGreaterThan(decoded.buffer.frameLength, 1_000)
        XCTAssertGreaterThan(decoded.buffer.format.channelCount, 0)
    }

    @MainActor
    func testShortGameKeeOggPlayerKeepsStateUntilDecodedBufferFinishes() async throws {
        let data = try await fetchHinaDressTitleOggFixtureDataForTesting()
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("hina-title-\(UUID().uuidString).ogg")
        try data.write(to: localURL)
        defer {
            try? FileManager.default.removeItem(at: localURL)
        }

        let player = BaOggVoicePlayer()
        let playingExpectation = expectation(description: "short ogg reaches playing")
        let endedExpectation = expectation(description: "short ogg ends after playback")
        var playingAt: Date?
        var endedAt: Date?
        player.onEvent = { event in
            switch event {
            case .playing where playingAt == nil:
                playingAt = Date()
                playingExpectation.fulfill()
            case .ended:
                endedAt = Date()
                endedExpectation.fulfill()
            default:
                break
            }
        }

        player.play(localURL: localURL)
        await fulfillment(of: [playingExpectation], timeout: 5)

        let duration = try XCTUnwrap(player.duration)
        XCTAssertTrue(player.canSeek)
        XCTAssertGreaterThan(duration, 0.5)
        player.seek(to: 0.45)
        XCTAssertGreaterThan(player.currentTime, duration * 0.35)

        await fulfillment(of: [endedExpectation], timeout: 5)
        player.stop()

        let elapsed = try XCTUnwrap(endedAt?.timeIntervalSince(try XCTUnwrap(playingAt)))
        XCTAssertGreaterThan(elapsed, 0.5)
    }

    @MainActor
    func testNativeVoicePlaybackClearsStateWhenAudioFinishes() async throws {
        let localURL = try Self.writeShortCAFVoiceFixture()
        defer {
            try? FileManager.default.removeItem(at: localURL)
        }
        let remoteURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/native.caf"))
        let playback = BaVoicePlaybackController(audioCache: StaticVoiceAudioCache(localURL: localURL))
        let startedExpectation = expectation(description: "native voice reaches playing")
        let finishedExpectation = expectation(description: "native voice finishes")
        var didStart = false
        playback.onPlaybackStateChanged = {
            if playback.isPlaying, didStart == false {
                didStart = true
                startedExpectation.fulfill()
            }
        }
        playback.onPlaybackFinished = {
            finishedExpectation.fulfill()
        }

        playback.play(remoteURL: remoteURL)

        await fulfillment(of: [startedExpectation, finishedExpectation], timeout: 10)
        XCTAssertNil(playback.currentRemoteURL)
        XCTAssertFalse(playback.isLoading)
        XCTAssertFalse(playback.isPlaying)
        XCTAssertEqual(playback.progress, 0, accuracy: 0.001)
        playback.stop()
    }

    func testSmallOggVoiceDataIsAcceptedByAudioCache() {
        let smallOggHeader = Data([0x4F, 0x67, 0x67, 0x53, 0x00, 0x02, 0x00, 0x00])

        XCTAssertTrue(BaAudioCache.recognizesAudioDataForTesting(smallOggHeader, expectedExtension: "ogg"))
    }

    private static func writeShortCAFVoiceFixture() throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("native-voice-\(UUID().uuidString).caf")
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * 0.18)
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        buffer.frameLength = frameCount
        let samples = try XCTUnwrap(buffer.floatChannelData?[0])

        for frame in 0 ..< Int(frameCount) {
            let sample = sin(2 * .pi * 440 * Double(frame) / sampleRate)
            samples[frame] = Float(sample * 0.25)
        }

        let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        try file.write(from: buffer)
        return fileURL
    }
}

private actor StaticVoiceAudioCache: BaAudioCaching {
    let localURL: URL

    init(localURL: URL) {
        self.localURL = localURL
    }

    func localURL(for _: URL, refererPath _: String) async throws -> URL {
        localURL
    }

    func cachedURL(for _: URL) async -> URL? {
        localURL
    }

    func isCached(_: URL) async -> Bool {
        true
    }

    func removeCachedAudio(for _: URL) async {}
}
