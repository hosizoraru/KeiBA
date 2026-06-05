//
//  BaStudentDetailVoiceTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import UniformTypeIdentifiers
import XCTest

final class BaStudentDetailVoiceTests: XCTestCase {
    func testVoiceParserKeepsAudioURLsOutOfDisplayLines() throws {
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "配音语言"],
                ["value": "日配"],
                ["value": "中配"],
                ["value": "音频"],
            ],
            [
                ["value": "通常"],
            ],
            [
                ["value": "标题"],
                ["value": "ブルーアーカイブ。"],
                ["value": "蔚蓝档案。"],
                ["type": "audio", "value": "//cdnimg.gamekee.com/voice/nico.ogg"],
            ],
        ]

        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).entries.first)

        XCTAssertEqual(entry.audioURLs?.first?.absoluteString, "https://cdnimg.gamekee.com/voice/nico.ogg")
        XCTAssertEqual(entry.lines, ["ブルーアーカイブ。", "蔚蓝档案。"])
    }

    func testVoiceParserKeepsTextOnlyTitleRowsUnplayable() throws {
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "配音语言"],
                ["value": "日配"],
                ["value": "中配"],
            ],
            [
                ["value": "通常"],
                ["value": "标题"],
                ["value": "ブルーアーカイブ。"],
                ["value": "蔚蓝档案。"],
            ],
        ]

        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).entries.first)

        XCTAssertEqual(entry.title, "标题")
        XCTAssertNil(entry.audioURL)
        XCTAssertNil(entry.audioURLs)
        XCTAssertEqual(entry.lines, ["ブルーアーカイブ。", "蔚蓝档案。"])
    }
}
