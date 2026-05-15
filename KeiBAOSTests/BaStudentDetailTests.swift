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

    func testStudentDetailPagesUseSixTabsInBenchmarkOrder() {
        XCTAssertEqual(
            BaStudentDetailPage.allCases,
            [.overviewProfile, .skills, .profile, .voice, .gallery, .simulate]
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

    func testGuideMetaKeepsOverviewFieldsDistinctWhenImageRowsLead() throws {
        let starURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/star.png"))
        let academyURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/gehinna.png"))
        let tacticURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/striker-wide.png"))
        let positionURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/back-wide.png"))
        let info = BaStudentGuideInfo(
            contentId: 1,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "club", title: "所属社团", value: "风纪委员会", imageURL: nil),
                BaGuideRow(id: "rarity", title: "稀有度", value: "3星", imageURL: starURL),
                BaGuideRow(id: "academy", title: "所属学院", value: "格黑娜学园", imageURL: academyURL),
                BaGuideRow(id: "tactic-image", title: "战术作用", value: "318534.png", imageURL: tacticURL),
                BaGuideRow(id: "role", title: "作用", value: "输出", imageURL: nil),
                BaGuideRow(id: "position", title: "位置", value: "", imageURL: positionURL),
                BaGuideRow(id: "indoor", title: "屋内", value: "S", imageURL: nil),
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
        let tactical = try XCTUnwrap(combat.first {
            $0.title == String(localized: "ba.student.detail.meta.tacticalPosition")
        })
        let indoor = try XCTUnwrap(combat.first {
            $0.title == String(localized: "ba.student.detail.meta.indoor")
        })

        XCTAssertEqual(profile.map(\.value), ["3星", "格黑娜学园", "风纪委员会"])
        XCTAssertEqual(profile[0].imageRepeatCount, 3)
        XCTAssertEqual(profile[1].imageURL, academyURL)
        XCTAssertEqual(tactical.value, "输出")
        XCTAssertEqual(tactical.imageURL, tacticURL)
        XCTAssertEqual(tactical.extraImageURL, positionURL)
        XCTAssertEqual(indoor.value, "S")
    }

    func testProfileSectionsKeepBenchmarkArchiveBuckets() {
        let info = BaStudentGuideInfo(
            contentId: 1,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "name", title: "角色名称", value: "日奈(礼服)", imageURL: nil),
                BaGuideRow(id: "full-name", title: "全名", value: "空崎ヒナ（ドレス）", imageURL: nil),
                BaGuideRow(id: "kana", title: "假名注音", value: "空崎 / そらさき", imageURL: nil),
                BaGuideRow(id: "trad-cn", title: "简中译名", value: "日奈(礼服)", imageURL: nil),
                BaGuideRow(id: "age", title: "年龄", value: "17岁", imageURL: nil),
                BaGuideRow(id: "birthday", title: "生日", value: "2月19日", imageURL: nil),
                BaGuideRow(id: "hobby", title: "兴趣爱好", value: "睡眠、休息", imageURL: nil),
                BaGuideRow(id: "intro", title: "介绍", value: "为了参加派对上了礼服裙。", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let sections = info.profileSections

        XCTAssertEqual(sections.map(\.title), [
            String(localized: "ba.student.detail.profile.names.title"),
            String(localized: "ba.student.detail.profile.info.title"),
            String(localized: "ba.student.detail.profile.hobby.title"),
        ])
        XCTAssertEqual(sections[0].rows.map(\.title), ["角色名称", "全名", "假名注音", "简中译名"])
        XCTAssertEqual(sections[1].rows.map(\.title), ["年龄", "生日"])
        XCTAssertEqual(sections[2].rows.map(\.title), ["兴趣爱好", "介绍"])
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

        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).first)

        XCTAssertEqual(entry.title, "标题")
        XCTAssertNil(entry.audioURL)
        XCTAssertNil(entry.audioURLs)
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
