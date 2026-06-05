//
//  BaStudentDetailProfileTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import UniformTypeIdentifiers
import XCTest

final class BaStudentDetailProfileTests: XCTestCase {
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
            entry: makeStudentDetailCatalogEntry()
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
            entry: makeStudentDetailCatalogEntry()
        )

        XCTAssertEqual(parsed.imageURL?.absoluteString, "https://cdnimg.gamekee.com/student/portrait.webp")
    }

    func testStudentDetailPagesUseSixTabsInBenchmarkOrder() {
        XCTAssertEqual(
            BaStudentDetailPage.allCases,
            [.overviewProfile, .skills, .profile, .voice, .gallery, .simulate]
        )
    }

    func testNpcSatelliteDetailPagesOnlyShowAvailableContent() throws {
        let portraitURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/npc-president.webp"))
        let info = BaStudentGuideInfo(
            contentId: 702_789,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/702789.html"),
            title: "伪学生会长",
            subtitle: "GameKee",
            summary: "NPC及卫星图鉴条目数据较少，已展示可用信息。",
            imageURL: portraitURL,
            stats: [],
            profileRows: [
                BaGuideRow(id: "name", title: "角色名称", value: "伪学生会长", imageURL: nil),
                BaGuideRow(id: "role", title: "剧情定位", value: "联邦学生会相关角色", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "api",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(
            BaStudentDetailPageAvailability.pages(category: .npcSatellite, info: info),
            [.overviewProfile, .profile, .gallery]
        )
    }

    func testNpcSatelliteProfileKeepsOtherAvailableRows() throws {
        let info = BaStudentGuideInfo(
            contentId: 702_789,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/702789.html"),
            title: "伪学生会长",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "name", title: "角色名称", value: "伪学生会长", imageURL: nil),
                BaGuideRow(id: "alias", title: "其他译名", value: "会长", imageURL: nil),
                BaGuideRow(id: "role", title: "剧情定位", value: "联邦学生会相关角色", imageURL: nil),
                BaGuideRow(id: "placeholder", title: "未公开字段", value: "None", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let studentSections = info.profileSections
        let npcSections = info.profileSections(for: .npcSatellite)

        XCTAssertEqual(studentSections.map(\.kind), [.names])
        XCTAssertEqual(npcSections.map(\.kind), [.names, .other])
        XCTAssertEqual(npcSections.first { $0.kind == .other }?.rows.map(\.title), ["其他译名", "剧情定位"])
    }

    func testNpcSatelliteProfileMetaUsesOriginalAffiliationField() {
        let info = BaStudentGuideInfo(
            contentId: 702_789,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/702789.html"),
            title: "伪学生会长",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "name", title: "角色名称", value: "伪学生会长", imageURL: nil),
                BaGuideRow(id: "belongs", title: "所属", value: "联邦学生会 / 总学生会长", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let profile = BaStudentGuideMeta.profileMetaItems(from: info, category: .npcSatellite)

        XCTAssertEqual(profile.map(\.title), [String(localized: "ba.student.detail.meta.belongs")])
        XCTAssertEqual(profile.map(\.value), ["联邦学生会 / 总学生会长"])
    }

    func testNpcSatelliteProfileMetaKeepsExplicitSchoolAndClubFields() {
        let info = BaStudentGuideInfo(
            contentId: 611_754,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/611754.html"),
            title: "日奈(睡衣)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "academy", title: "所属学院", value: "格黑娜学园", imageURL: nil),
                BaGuideRow(id: "club", title: "所属社团", value: "风纪委员会", imageURL: nil),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let profile = BaStudentGuideMeta.profileMetaItems(from: info, category: .npcSatellite)

        XCTAssertEqual(profile.map(\.title), [
            String(localized: "ba.student.detail.meta.academy"),
            String(localized: "ba.student.detail.meta.club"),
        ])
        XCTAssertEqual(profile.map(\.value), ["格黑娜学园", "风纪委员会"])
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
        XCTAssertEqual(profile[1].imageURL, academyURL)
        XCTAssertEqual(tactical.value, "输出")
        XCTAssertEqual(tactical.imageURL, tacticURL)
        XCTAssertEqual(tactical.extraImageURL, positionURL)
        XCTAssertEqual(indoor.value, "S")
    }

    func testGuideMetaFindsAcademyFromValueFallback() throws {
        let academyURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/gehinna.png"))
        let info = BaStudentGuideInfo(
            contentId: 1,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "academy", title: "阵营", value: "格黑娜学园", imageURL: academyURL),
                BaGuideRow(id: "club", title: "所属社团", value: "风纪委员会", imageURL: nil),
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

        XCTAssertEqual(profile[1].value, "格黑娜学园")
        XCTAssertEqual(profile[1].imageURL, academyURL)
    }

    func testProfileSectionsKeepBenchmarkArchiveBuckets() throws {
        let giftURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/gift.webp"))
        let emojiURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/emoji.webp"))
        let sameNameImageURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina.webp"))
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
                BaGuideRow(id: "height", title: "身高", value: "142cm", imageURL: nil),
                BaGuideRow(id: "artist", title: "画师", value: "DoReMi", imageURL: nil),
                BaGuideRow(id: "voice", title: "声优", value: "广桥凉 ← 大部分时候可以去别的图鉴复制", imageURL: nil),
                BaGuideRow(id: "hobby", title: "兴趣爱好", value: "睡眠、休息", imageURL: nil),
                BaGuideRow(id: "intro", title: "个人简介", value: "为了参加派对上了礼服裙。", imageURL: nil),
                BaGuideRow(id: "momotalk", title: "MomoTalk状态消息", value: "今天也要加油。", imageURL: nil),
                BaGuideRow(id: "momotalk-lv", title: "MomoTalk解锁等级", value: "3级 <- 不用写", imageURL: nil),
                BaGuideRow(id: "gift", title: "礼物偏好礼物2", value: "古典乐谱", imageURL: giftURL, imageURLs: [giftURL, emojiURL]),
                BaGuideRow(id: "same-name", title: "同名角色名称", value: "日奈 / https://www.gamekee.com/ba/tj/123456.html", imageURL: sameNameImageURL),
                BaGuideRow(id: "header", title: "介绍", value: "这一行是分区标题", imageURL: nil),
                BaGuideRow(id: "top-header", title: "顶级数据", value: "", imageURL: nil),
                BaGuideRow(id: "attack", title: "攻击力", value: "969", imageURL: nil),
                BaGuideRow(id: "skill-tier", title: "T2技能图标", value: "", imageURL: nil),
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

        XCTAssertEqual(sections.map(\.kind), [.names, .info, .hobby, .gifts, .sameName])
        XCTAssertEqual(sections[0].rows.map(\.title), ["角色名称", "全名", "假名注音", "简中译名"])
        XCTAssertEqual(sections[1].rows.map(\.title), ["年龄", "生日", "身高", "画师", "声优"])
        XCTAssertEqual(sections[1].rows.first { $0.title == "声优" }?.value, "广桥凉")
        XCTAssertEqual(sections[2].rows.map(\.title), ["兴趣爱好", "个人简介", "MomoTalk状态消息", "MomoTalk解锁等级"])
        XCTAssertEqual(sections[2].rows.first { $0.title == "MomoTalk解锁等级" }?.value, "3级")
        XCTAssertEqual(sections[3].giftItems.map(\.label), ["古典乐谱"])
        XCTAssertEqual(sections[3].giftItems.first?.giftImageURL, giftURL)
        XCTAssertEqual(sections[3].giftItems.first?.emojiImageURL, emojiURL)
        XCTAssertEqual(sections[4].title, String(localized: "ba.student.detail.profile.sameName.title"))
        XCTAssertEqual(sections[4].sameNameRoleItems.map(\.name), ["日奈"])
        XCTAssertEqual(sections[4].sameNameRoleItems.first?.guideURL?.absoluteString, "https://www.gamekee.com/ba/tj/123456.html")
        let displayedRowTitles = sections.flatMap(\.rows).map(\.title)
        XCTAssertFalse(displayedRowTitles.contains("介绍"))
        XCTAssertFalse(displayedRowTitles.contains("攻击力"))
        XCTAssertFalse(displayedRowTitles.contains("T2技能图标"))
    }

    func testContentParserKeepsMomoTalkRowsInProfileData() {
        let parsed = BaGuideContentParser().parse(
            content: [
                "baseData": [
                    [
                        ["value": "MomoTalk状态消息"],
                        ["value": "今天也要加油。"],
                    ],
                    [
                        ["value": "MomoTalk解锁等级"],
                        ["value": "3级"],
                    ],
                ],
            ],
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )

        XCTAssertTrue(parsed.profileRows.contains { $0.title == "MomoTalk状态消息" && $0.value == "今天也要加油。" })
        XCTAssertTrue(parsed.profileRows.contains { $0.title == "MomoTalk解锁等级" && $0.value == "3级" })
    }

    func testSameNameRolesBuildStudentGuideEntryFromLegacyBAPath() throws {
        let avatarURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina.webp"))
        let info = BaStudentGuideInfo(
            contentId: 170_295,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(id: "same-name", title: "同名角色名称", value: "日奈 / /ba/123456.html", imageURL: avatarURL),
                BaGuideRow(id: "unknown", title: "未分组字段", value: "不应该形成其他档案卡", imageURL: nil),
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
        XCTAssertEqual(sections.map(\.kind), [.sameName])
        let item = try XCTUnwrap(sections.first?.sameNameRoleItems.first)
        XCTAssertEqual(item.name, "日奈")
        XCTAssertEqual(item.guideURL?.absoluteString, "https://www.gamekee.com/ba/tj/123456.html")
        XCTAssertEqual(item.catalogEntry?.contentId, 123_456)
        XCTAssertEqual(item.catalogEntry?.detailURL?.absoluteString, "https://www.gamekee.com/ba/tj/123456.html")
    }

    func testArrayContentParserKeepsRelationInfoAndInteractiveFurnitureGIFs() throws {
        let content: [Any] = [
            [
                "type": "relation-info",
                "data": [
                    "list": [
                        [
                            "title": "相关同名角色",
                            "content": [
                                [
                                    "name": "日奈",
                                    "jumpHref": "/ba/123456.html",
                                    "avatar": "//cdnimg.gamekee.com/hina.webp",
                                ],
                            ],
                        ],
                    ],
                ],
            ],
            [
                "type": "tab-info",
                "data": [
                    "tabList": [
                        [
                            "title": "互动家具",
                            "content": [
                                ["value": "//cdnimg.gamekee.com/furniture-1.gif"],
                                ["value": "//cdnimg.gamekee.com/furniture-2.gif"],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )
        let info = BaStudentGuideInfo(
            contentId: 170_295,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/170295.html"),
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: parsed.summary,
            imageURL: parsed.imageURL,
            stats: parsed.stats,
            profileRows: parsed.profileRows,
            skillRows: parsed.skillRows,
            voiceRows: parsed.voiceRows,
            galleryItems: parsed.galleryItems,
            growthRows: parsed.growthRows,
            simulateRows: parsed.simulateRows,
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let sameName = try XCTUnwrap(info.profileSections.first { $0.kind == .sameName }?.sameNameRoleItems.first)
        XCTAssertEqual(sameName.name, "日奈")
        XCTAssertEqual(sameName.catalogEntry?.contentId, 123_456)

        let furniture = try XCTUnwrap(info.profileSections.first { $0.kind == .furniture })
        XCTAssertEqual(furniture.galleryItems.map(\.title), ["互动家具 1", "互动家具 2"])
        XCTAssertEqual(furniture.galleryItems.map { $0.mediaURL?.pathExtension ?? "" }, ["gif", "gif"])
    }

    func testRelationInfoParserAcceptsContentIDAndAlternativeImageKeys() throws {
        let content: [Any] = [
            [
                "type": "relation-info",
                "data": [
                    "list": [
                        [
                            "title": "相关同名角色",
                            "content": [
                                [
                                    "name": "日奈（泳装）",
                                    "content_id": 83_729,
                                    "imageUrl": "//cdnimg.gamekee.com/hina-swimsuit.webp",
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )
        let row = try XCTUnwrap(parsed.profileRows.first { $0.title == "同名角色名称" })

        XCTAssertEqual(row.value, "日奈（泳装） / https://www.gamekee.com/ba/tj/83729.html")
        XCTAssertEqual(row.imageURL?.absoluteString, "https://cdnimg.gamekee.com/hina-swimsuit.webp")
    }

    func testRelationInfoParserKeepsGenericRelatedRolesDistinctFromSameNameRoles() throws {
        let content: [Any] = [
            [
                "type": "relation-info",
                "data": [
                    "list": [
                        [
                            "title": "相关角色",
                            "content": [
                                [
                                    "name": "桃香",
                                    "jumpHref": "/ba/702789.html",
                                    "avatar": "//cdnimg.gamekee.com/momoka.webp",
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )
        XCTAssertNil(parsed.profileRows.first { $0.title == "同名角色名称" })
        let row = try XCTUnwrap(parsed.profileRows.first { $0.title == "相关角色名称" })
        XCTAssertEqual(row.value, "桃香 / https://www.gamekee.com/ba/tj/702789.html")
        XCTAssertEqual(row.imageURL?.absoluteString, "https://cdnimg.gamekee.com/momoka.webp")

        let info = BaStudentGuideInfo(
            contentId: 161_188,
            sourceURL: URL(string: "https://www.gamekee.com/ba/161188.html"),
            title: "凛",
            subtitle: "GameKee",
            summary: parsed.summary,
            imageURL: parsed.imageURL,
            stats: parsed.stats,
            profileRows: parsed.profileRows,
            skillRows: parsed.skillRows,
            voiceRows: parsed.voiceRows,
            galleryItems: parsed.galleryItems,
            growthRows: parsed.growthRows,
            simulateRows: parsed.simulateRows,
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let section = try XCTUnwrap(info.profileSections.first { $0.kind == .sameName })
        XCTAssertEqual(section.roleRelationKind, .related)
        XCTAssertEqual(section.title, String(localized: "ba.student.detail.profile.relatedRoles.title"))
        XCTAssertEqual(section.sameNameRoleItems.map(\.name), ["桃香"])
    }

    func testSameNameRoleCatalogResolverMatchesExactStudentAndNpcNames() throws {
        let entries = [
            makeStudentDetailCatalogEntry(contentId: 59_934, name: "日奈", category: .students),
            makeStudentDetailCatalogEntry(contentId: 83_729, name: "日奈(泳装)", category: .students),
            makeStudentDetailCatalogEntry(contentId: 611_754, name: "日奈(睡衣)", category: .npcSatellite),
        ]

        let regular = BaStudentProfileSameNameRoleItem(id: "regular", name: "★3 日奈", guideURL: nil, imageURL: nil)
        let swimsuit = BaStudentProfileSameNameRoleItem(id: "swimsuit", name: "★3 日奈（泳装）", guideURL: nil, imageURL: nil)
        let pajama = BaStudentProfileSameNameRoleItem(id: "pajama", name: "NPC 日奈（睡衣）", guideURL: nil, imageURL: nil)

        XCTAssertEqual(BaSameNameStudentCatalogResolver.catalogEntry(for: regular, catalogEntries: entries)?.contentId, 59_934)
        XCTAssertEqual(BaSameNameStudentCatalogResolver.catalogEntry(for: swimsuit, catalogEntries: entries)?.contentId, 83_729)
        XCTAssertEqual(BaSameNameStudentCatalogResolver.catalogEntry(for: pajama, catalogEntries: entries)?.contentId, 611_754)
    }

    func testSameNameRoleCatalogResolverPrefersExplicitGuideID() throws {
        let guideURL = try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/tj/83729.html"))
        let entries = [
            makeStudentDetailCatalogEntry(contentId: 59_934, name: "日奈", category: .students),
            makeStudentDetailCatalogEntry(contentId: 83_729, name: "日奈(泳装)", category: .students),
        ]
        let item = BaStudentProfileSameNameRoleItem(id: "linked", name: "日奈", guideURL: guideURL, imageURL: nil)

        XCTAssertEqual(BaSameNameStudentCatalogResolver.catalogEntry(for: item, catalogEntries: entries)?.contentId, 83_729)
    }

    func testSameNameRoleRowsSplitMultipleLinkedRoles() throws {
        let regularIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina.webp"))
        let swimsuitIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/hina-swimsuit.webp"))
        let info = BaStudentGuideInfo(
            contentId: 611_753,
            sourceURL: nil,
            title: "日奈(礼服)",
            subtitle: "GameKee",
            summary: "",
            imageURL: nil,
            stats: [],
            profileRows: [
                BaGuideRow(
                    id: "same-name-many",
                    title: "同名角色名称",
                    value: "日奈 / https://www.gamekee.com/ba/tj/59934.html / 日奈(泳装) / /ba/83729.html",
                    imageURL: regularIcon,
                    imageURLs: [regularIcon, swimsuitIcon]
                ),
            ],
            skillRows: [],
            voiceRows: [],
            galleryItems: [],
            growthRows: [],
            simulateRows: [],
            contentSource: "content_json",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        let items = try XCTUnwrap(info.profileSections.first { $0.kind == .sameName }?.sameNameRoleItems)
        let entries = [
            makeStudentDetailCatalogEntry(contentId: 59_934, name: "日奈", category: .students),
            makeStudentDetailCatalogEntry(contentId: 83_729, name: "日奈(泳装)", category: .students),
        ]

        XCTAssertEqual(items.map(\.name), ["日奈", "日奈(泳装)"])
        XCTAssertEqual(items.map { $0.guideURL?.absoluteString }, [
            "https://www.gamekee.com/ba/tj/59934.html",
            "https://www.gamekee.com/ba/tj/83729.html",
        ])
        XCTAssertEqual(items.map(\.imageURL), [regularIcon, swimsuitIcon])
        XCTAssertEqual(items.map { BaSameNameStudentCatalogResolver.catalogEntry(for: $0, catalogEntries: entries)?.contentId }, [59_934, 83_729])
    }
}
