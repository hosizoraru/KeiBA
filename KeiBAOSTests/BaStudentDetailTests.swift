//
//  BaStudentDetailTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/14.
//

@testable import KeiBAOS
import XCTest

final class BaStudentDetailTests: XCTestCase {
    func testContentParserSkipsContentCDNAsCoverImage() {
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["value": "角色图片"],
                    ["value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_404/h_456/829/72324/cover.png"],
                ],
            ],
        ]
        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [
                "content_cdn": "//api-cdn.gamekee.com/wiki2.0/pro/829/content/67664.json?v=20260507153720.894682",
            ],
            html: nil,
            entry: makeCatalogEntry()
        )

        XCTAssertEqual(
            parsed.imageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_404/h_456/829/72324/cover.png"
        )
    }

    func testContentParserPrefersBaseDataPortraitOverAPIThumb() {
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["value": "角色图片"],
                    ["value": "//cdnimg.gamekee.com/student/portrait.webp"],
                ],
            ],
        ]
        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [
                "thumb": "//cdnimg.gamekee.com/student/thumb.webp",
            ],
            html: nil,
            entry: makeCatalogEntry()
        )

        XCTAssertEqual(parsed.imageURL?.absoluteString, "https://cdnimg.gamekee.com/student/portrait.webp")
    }

    func testStudentDetailPagesMergeArchiveAndProfileIntoFiveTabs() {
        XCTAssertEqual(
            BaStudentDetailPage.allCases,
            [.overviewProfile, .skills, .voice, .gallery, .simulate]
        )
    }

    func testGuideMetaExtractsArchiveRowsAndFiltersMovedRows() {
        let info = BaStudentGuideInfo(
            contentId: 1,
            sourceURL: nil,
            title: "优香",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "rarity", title: "稀有度", value: "★★★ / 图标占位", imageURL: nil),
                BaGuideRow(id: "school", title: "所属学院", value: "千年科学学园", imageURL: nil),
                BaGuideRow(id: "club", title: "所属社团", value: "研讨会", imageURL: nil),
                BaGuideRow(id: "attack", title: "攻击类型", value: "神秘", imageURL: nil),
                BaGuideRow(id: "weapon", title: "武器类型", value: "这一行素材占位", imageURL: nil),
                BaGuideRow(id: "birthday", title: "生日", value: "3月14日", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let profile = BaStudentGuideMeta.profileMetaItems(from: info)
        let combat = BaStudentGuideMeta.combatMetaItems(from: info)

        XCTAssertEqual(profile[0].value, "★★★")
        XCTAssertEqual(profile[1].value, "千年科学学园")
        XCTAssertEqual(profile[2].value, "研讨会")
        let weaponValue = combat.first {
            $0.title == String(localized: "ba.student.detail.meta.weaponType")
        }?.value
        XCTAssertEqual(weaponValue, String(localized: "ba.common.none"))
        XCTAssertEqual(info.overviewProfileRows.map(\.title), ["生日"])
    }

    func testStudentDetailSourceErrorUsesFriendlyMessage() {
        XCTAssertEqual(
            BaDataErrorPresenter.studentDetailMessage(for: "content_cdn-empty"),
            String(localized: "ba.student.detail.partialSource.warning")
        )
    }

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

        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).first)

        XCTAssertEqual(entry.audioURLs?.first?.absoluteString, "https://cdnimg.gamekee.com/voice/nico.ogg")
        XCTAssertEqual(entry.lines, ["ブルーアーカイブ。", "蔚蓝档案。"])
    }

    private func makeCatalogEntry() -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: 1,
            pid: 49443,
            contentId: 609_145,
            name: "Test",
            alias: "",
            aliasDisplay: "",
            iconURL: nil,
            type: 0,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/609145.html"),
            category: .students
        )
    }
}
