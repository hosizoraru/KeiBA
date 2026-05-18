//
//  BaVoiceDisplayTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/14.
//

@testable import KeiBAOS
import XCTest

final class BaVoiceDisplayTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BaL10n.configure(appLanguage: .simplifiedChinese)
    }

    override func tearDown() {
        BaL10n.configure(appLanguage: .system)
        super.tearDown()
    }

    func testVoiceDisplayFiltersBySectionAndSearchText() throws {
        let entries = try makeVoiceEntries()
        let headers = BaVoiceLanguageResolver.displayHeaders(for: entries)
        let battleFilter = BaVoiceSectionFilter(section: "战斗")

        let battleRows = BaVoiceDisplayModel.filteredEntries(
            entries,
            filter: battleFilter,
            query: "",
            fallbackHeaders: headers
        )
        XCTAssertEqual(battleRows.map(\.title), ["胜利"])

        let searchedRows = BaVoiceDisplayModel.filteredEntries(
            entries,
            filter: .all,
            query: "こんにちは",
            fallbackHeaders: headers
        )
        XCTAssertEqual(searchedRows.map(\.title), ["大厅"])
    }

    func testVoiceDisplayBuildsSelectedCopyAndFormatBadges() throws {
        let entry = try XCTUnwrap(makeVoiceEntries().first)
        let headers = ["日配", "中配"]
        let selectedLine = BaVoiceDisplayModel.selectedLine(
            for: entry,
            fallbackHeaders: headers,
            selectedLanguage: "中配"
        )

        XCTAssertEqual(selectedLine?.text, "你好")
        XCTAssertEqual(BaVoiceDisplayModel.officialLine(for: entry, fallbackHeaders: headers)?.text, "你好，老师。")
        XCTAssertEqual(
            BaVoiceDisplayModel.secondaryLines(
                for: entry,
                fallbackHeaders: headers,
                selectedLanguage: "中配"
            )
            .map(\.language),
            ["日配"]
        )
        XCTAssertEqual(BaVoiceDisplayModel.audioFormatTitle(for: entry.audioURLs?.first), "OGG")
        XCTAssertTrue(
            BaVoiceDisplayModel.copySelectedText(
                for: entry,
                fallbackHeaders: headers,
                selectedLanguage: "中配"
            )
            .contains("中配: 你好")
        )
    }

    func testGuideTextNormalizerFindsAndStripsOggAudioURLs() {
        let url = "https://cdnimg.gamekee.com/audio/voice.ogg"
        let urls = BaGuideTextNormalizer.audioURLs(in: "播放源 \(url)", sourceURL: nil)

        XCTAssertEqual(urls.map(\.absoluteString), [url])
        XCTAssertEqual(BaGuideTextNormalizer.cleanDisplayText("台词 \(url)"), "台词")
    }

    private func makeVoiceEntries() throws -> [BaGuideVoiceEntry] {
        let jpOgg = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.ogg"))
        let cnMp3 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/cn.mp3"))
        let battleMp3 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/battle.mp3"))
        let lobbyEntry = BaGuideVoiceEntry(
            id: "voice-lobby",
            title: "大厅",
            subtitle: "通常",
            transcript: "こんにちは\n你好\n你好，老师。",
            audioURL: jpOgg,
            section: "通常",
            lineHeaders: ["日配", "中配", "官翻"],
            lines: ["こんにちは", "你好", "你好，老师。"],
            audioURLs: [jpOgg, cnMp3]
        )
        let battleEntry = BaGuideVoiceEntry(
            id: "voice-battle",
            title: "胜利",
            subtitle: "战斗",
            transcript: "勝利",
            audioURL: battleMp3,
            section: "战斗",
            lineHeaders: ["日配"],
            lines: ["勝利"],
            audioURLs: [battleMp3]
        )
        return [lobbyEntry, battleEntry]
    }
}
