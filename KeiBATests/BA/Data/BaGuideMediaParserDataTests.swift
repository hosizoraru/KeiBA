//
//  BaGuideMediaParserDataTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import AVFAudio
import Foundation
import XCTest

final class BaGuideMediaParserDataTests: XCTestCase {
    func testGalleryParserClassifiesVideoMedia() {
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "回忆大厅视频"],
                ["type": "video", "value": "https://cdnimg.gamekee.com/media/memory.mp4"],
            ],
        ]
        let items = BaGuideMediaParser().parse(
            baseData: baseData,
            styleData: [],
            content: nil,
            apiData: [:],
            sourceURL: nil
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].mediaKind, .video)
        XCTAssertEqual(items[0].mediaURL?.absoluteString, "https://cdnimg.gamekee.com/media/memory.mp4")
    }

    func testGalleryParserSortsAndKeepsHinaDressMediaCategories() throws {
        let baseData: [[BaJSONObject]] = [
            [
                ["value": "回忆大厅解锁等级"],
                ["value": "羁绊等级 5"],
            ],
            [
                ["value": "BGM"],
                ["type": "audio", "value": "https://cdnimg.gamekee.com/hina/bgm.ogg"],
            ],
            [
                ["value": "互动家具 1 2"],
                ["type": "image", "value": "https://cdnimg.gamekee.com/hina/furniture.gif"],
            ],
            [
                ["value": "巧克力图"],
                ["type": "image", "value": "https://cdnimg.gamekee.com/hina/chocolate.png"],
            ],
            [
                ["value": "角色表情"],
                ["type": "image", "value": "https://cdnimg.gamekee.com/hina/expression.png"],
            ],
            [
                ["value": "回忆大厅视频"],
                ["type": "video", "value": "https://cdnimg.gamekee.com/hina/memory.mp4"],
            ],
            [
                ["value": "回忆大厅"],
                ["type": "image", "value": "https://cdnimg.gamekee.com/hina/memory.png"],
            ],
            [
                ["value": "立绘"],
                ["type": "image", "value": "https://cdnimg.gamekee.com/hina/standing.png"],
            ],
        ]

        let items = BaGuideMediaParser().parse(
            baseData: baseData,
            styleData: [],
            content: nil,
            apiData: [:],
            sourceURL: nil
        )

        XCTAssertEqual(items.map(\.title), [
            "立绘",
            "回忆大厅",
            "回忆大厅视频",
            "BGM",
            "角色表情",
            "互动家具 1 2",
            "巧克力图",
        ])
        XCTAssertEqual(items.first { $0.title == "回忆大厅" }?.memoryUnlockLevel, "5")
        XCTAssertEqual(items.first { $0.title == "BGM" }?.mediaKind, .audio)
        XCTAssertEqual(items.first { $0.title == "回忆大厅视频" }?.mediaKind, .video)
    }

    func testReleaseDateExtractionHandlesGameKeeChineseDate() throws {
        let date = BaGuideTextNormalizer.extractDate(from: "实装日期：2024年1月24日")
        let components = try Calendar.current.dateComponents([.year, .month, .day], from: XCTUnwrap(date))

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 24)
    }
}
