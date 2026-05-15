//
//  BaDataBridgeTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/14.
//

@testable import KeiBAOS
import XCTest

final class BaDataBridgeTests: XCTestCase {
    func testActivityParserClassifiesAndSortsEntries() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 1,
              "title": "Running Event",
              "activity_kind_id": 14,
              "activity_kind_name": "活动",
              "begin_at": 1699990000,
              "end_at": 1700010000,
              "link_url": "/ba/700001.html",
              "picture": "//cdnimg.gamekee.com/activity.webp"
            },
            {
              "id": 2,
              "title": "Upcoming Event",
              "activity_kind_id": 16,
              "activity_kind_name": "多倍活动",
              "begin_at": 1700100000,
              "end_at": 1700200000,
              "link_url": "/ba/700002.html",
              "picture": "//cdnimg.gamekee.com/upcoming.webp"
            }
          ]
        }
        """
        let repository = BaActivityPoolRepository(client: GameKeeClient())
        let entries = try repository.parseActivities(data: Data(json.utf8), now: now)

        XCTAssertEqual(entries.map(\.id), [1, 2])
        XCTAssertEqual(entries[0].status(at: now), .running)
        XCTAssertEqual(entries[1].status(at: now), .upcoming)
        XCTAssertEqual(entries[0].imageURL?.scheme, "https")
    }

    func testPoolParserKeepsKnownTagsAndImages() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 10,
              "name": "Example Pickup",
              "start_at": 1699990000,
              "end_at": 1700010000,
              "tag_id": "6",
              "icon": "//cdnimg.gamekee.com/pool.png",
              "name_alias": "研讨会",
              "link_url": "/ba/700010.html",
              "content_id": 609145
            }
          ]
        }
        """
        let repository = BaActivityPoolRepository(client: GameKeeClient())
        let entries = try repository.parsePools(data: Data(json.utf8), now: now)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tagId, 6)
        XCTAssertEqual(entries[0].contentId, 609_145)
        XCTAssertEqual(entries[0].imageURL?.absoluteString, "https://cdnimg.gamekee.com/pool.png")
    }

    func testPoolParserExtractsExplicitStudentGuideLinks() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 11,
              "name": "妃咲",
              "start_at": 1699990000,
              "end_at": 1700010000,
              "tag_id": "9",
              "link_url": "/ba/tj/68993.html"
            },
            {
              "id": 12,
              "name": "妃咲",
              "start_at": 1699990000,
              "end_at": 1700010000,
              "tag_id": "9",
              "link_url": "/v1/content/detail/68993"
            }
          ]
        }
        """
        let repository = BaActivityPoolRepository(client: GameKeeClient())
        let entries = try repository.parsePools(data: Data(json.utf8), now: now)

        XCTAssertEqual(entries.map { $0.studentGuideURL?.absoluteString }, [
            "https://www.gamekee.com/ba/tj/68993.html",
            "https://www.gamekee.com/ba/tj/68993.html",
        ])
    }

    func testPoolParserLeavesCNPoolSourceLinkOutOfStudentGuideURL() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 2388,
              "name": "优香(体操服)",
              "start_at": 1699990000,
              "end_at": 1700010000,
              "tag_id": "6",
              "link_url": "https://www.gamekee.com/ba/701261.html",
              "content_id": 0
            }
          ]
        }
        """
        let repository = BaActivityPoolRepository(client: GameKeeClient())
        let entry = try XCTUnwrap(repository.parsePools(data: Data(json.utf8), now: now).first)

        XCTAssertEqual(entry.linkURL?.absoluteString, "https://www.gamekee.com/ba/701261.html")
        XCTAssertNil(entry.studentGuideURL)
    }

    func testPoolStudentGuideResolverMapsCNPoolByExactCatalogName() throws {
        let resolver = BaPoolStudentGuideResolver(
            catalogEntries: [
                makeCatalogEntry(contentId: 67_658, name: "优香"),
                makeCatalogEntry(contentId: 170_295, name: "优香(体操服)"),
            ]
        )
        let sportswearPool = makePoolEntry(
            id: 2388,
            name: "优香(体操服)",
            linkURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/701261.html"))
        )
        let basePool = makePoolEntry(
            id: 2387,
            name: "优香",
            linkURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/701261.html"))
        )

        XCTAssertEqual(
            resolver.resolve(sportswearPool).studentGuideURL?.absoluteString,
            "https://www.gamekee.com/ba/tj/170295.html"
        )
        XCTAssertEqual(
            resolver.resolve(basePool).studentGuideURL?.absoluteString,
            "https://www.gamekee.com/ba/tj/67658.html"
        )
    }

    func testPoolCacheRoundTripPreservesStudentGuideURL() throws {
        let guideURL = try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/tj/170295.html"))
        let pool = makePoolEntry(
            id: 2388,
            name: "优香(体操服)",
            linkURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/701261.html")),
            studentGuideURL: guideURL
        )
        let envelope = BaCacheEnvelope(schemaVersion: 6, syncedAt: Date(timeIntervalSince1970: 1_700_000_000), value: [pool])
        let data = try JSONEncoder.ba.encode(envelope)
        let decoded = try JSONDecoder.ba.decode(BaCacheEnvelope<[BaPoolEntry]>.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, 6)
        XCTAssertEqual(decoded.value.single?.linkURL?.absoluteString, "https://www.gamekee.com/ba/701261.html")
        XCTAssertEqual(decoded.value.single?.studentGuideURL?.absoluteString, "https://www.gamekee.com/ba/tj/170295.html")
    }

    func testPoolCacheDecodesLegacyEntryWithoutStudentGuideURL() throws {
        let raw = """
        {
          "schemaVersion": 5,
          "syncedAt": "2023-11-14T22:13:20Z",
          "value": [
            {
              "id": 2388,
              "name": "优香(体操服)",
              "tagId": 6,
              "tagName": "",
              "alias": "",
              "startAt": "2023-11-14T19:26:40Z",
              "endAt": "2023-11-15T01:00:00Z",
              "linkURL": "https://www.gamekee.com/ba/701261.html",
              "imageURL": null,
              "contentId": null
            }
          ]
        }
        """
        let decoded = try JSONDecoder.ba.decode(BaCacheEnvelope<[BaPoolEntry]>.self, from: Data(raw.utf8))

        XCTAssertEqual(decoded.schemaVersion, 5)
        XCTAssertEqual(decoded.value.single?.name, "优香(体操服)")
        XCTAssertNil(decoded.value.single?.studentGuideURL)
    }

    @MainActor
    func testResolvedPoolBuildsStudentCatalogEntryForDetailNavigation() throws {
        let model = BaAppModel.live()
        let pool = makePoolEntry(
            id: 2388,
            name: "优香(体操服)",
            linkURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/701261.html")),
            studentGuideURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/tj/170295.html"))
        )
        let entry = try XCTUnwrap(model.studentCatalogEntry(for: pool))

        XCTAssertEqual(entry.contentId, 170_295)
        XCTAssertEqual(entry.name, "优香(体操服)")
        XCTAssertEqual(entry.detailURL?.absoluteString, "https://www.gamekee.com/ba/tj/170295.html")
        XCTAssertEqual(entry.category, .students)
    }

    func testCatalogTreeParserBuildsDetailURL() throws {
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 107661,
              "pid": 49443,
              "content_id": 161248,
              "name": "妮可",
              "name_alias": "nico,niko",
              "icon": "//cdnimg.gamekee.com/nico.png",
              "type": 3,
              "created_at": 1656741538
            }
          ]
        }
        """
        let repository = BaGuideCatalogRepository(client: GameKeeClient())
        let entries = try repository.parseEntries(data: Data(json.utf8), pid: 49443, category: .students)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].contentId, 161_248)
        XCTAssertEqual(entries[0].aliasDisplay, "nico · niko")
        XCTAssertEqual(entries[0].detailURL?.absoluteString, "https://www.gamekee.com/ba/tj/161248.html")
    }

    func testAPMathUsesSixMinuteRecovery() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var settings = BaAppSettings.defaults(now: base)
        settings.apCurrent = 10
        settings.apLimit = 240
        settings.apRegenBaseAt = base
        let now = base.addingTimeInterval(12 * 60)

        XCTAssertEqual(BaTimeMath.displayAP(BaTimeMath.currentAP(settings: settings, now: now)), 12)
        XCTAssertEqual(BaTimeMath.nextAPPointAt(settings: settings, now: now), now.addingTimeInterval(6 * 60))
    }

    func testImageRequestStrategyUsesGameKeeRootRefererAndFallbackUA() {
        let client = GameKeeClient()

        XCTAssertEqual(
            client.resolvedReferer(
                pathOrURL: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_61/h_61/480420.webp",
                refererPath: "/ba/huodong/16"
            ),
            "https://www.gamekee.com/"
        )
        XCTAssertEqual(client.imageRetryUserAgents.count, 2)
        XCTAssertTrue(client.imageRetryUserAgents[0].contains("Firefox"))
        XCTAssertTrue(client.imageRetryUserAgents[1].contains("Safari"))
    }

    func testHTMLAttributeExtractionUsesSourceValue() {
        let html = #"<div><img class="gift-img" src="//cdnimg.gamekee.com/gift.webp"></div>"#
        let urls = BaGuideTextNormalizer.imageURLsFromHTML(html, sourceURL: nil)

        XCTAssertEqual(urls.map(\.absoluteString), ["https://cdnimg.gamekee.com/gift.webp"])
    }

    func testDisplayTextRemovesEmbeddedMediaURL() {
        let raw = #"贯通 / //cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/type.png"#

        XCTAssertEqual(BaGuideTextNormalizer.cleanDisplayText(raw), "贯通")
    }

    func testContentJSONBaseDataUnwrapsObjectAndArrayRows() {
        let objectContent: BaJSONObject = [
            "baseData": [
                [
                    ["value": "学生信息"],
                    ["value": "实装日期 2024-01-24"],
                ],
            ],
        ]
        let arrayContent: [Any] = [
            [
                ["value": "学生信息"],
                ["value": "实装日期 2024-01-24"],
            ],
        ]

        XCTAssertEqual(BaGuideContentParser.baseDataRows(from: objectContent).count, 1)
        XCTAssertEqual(BaGuideContentParser.baseDataRows(from: arrayContent).count, 1)
    }

    func testContentParserReadsHTMLMetaSummary() {
        let html = #"<html><head><meta name="description" content="GameKee summary"></head></html>"#
        let parsed = BaGuideContentParser().parse(
            content: nil,
            apiData: [:],
            html: html,
            entry: makeCatalogEntry()
        )

        XCTAssertEqual(parsed.summary, "GameKee summary")
    }

    func testContentParserBuildsBenchmarkLikeBuckets() throws {
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["value": "学生信息"],
                    ["value": "角色名称"],
                    ["value": "日奈(礼服)"],
                    ["value": "全名"],
                    ["value": "空崎ヒナ（ドレス）"],
                    ["value": "假名注音"],
                    ["value": "空崎 / そらさき"],
                    ["value": "简中译名"],
                    ["value": "日奈(礼服)"],
                ],
                [
                    ["value": "学生信息"],
                    ["value": "年龄"],
                    ["value": "17岁"],
                    ["value": "生日"],
                    ["value": "2月19日"],
                    ["value": "身高"],
                    ["value": "142cm"],
                    ["value": "画师"],
                    ["value": "DoReMi"],
                    ["value": "实装日期"],
                    ["value": "2024/1/31"],
                    ["value": "声优"],
                    ["value": "日｜广桥凉｜中｜王雅欣｜韩｜박신희"],
                ],
                [
                    ["value": "学生爱好"],
                    ["value": "兴趣爱好"],
                    ["value": "睡眠、休息"],
                ],
                [
                    ["value": "介绍"],
                    ["value": "为了参加派对上了礼服裙。"],
                ],
                [
                    ["value": "稀有度"],
                    ["value": "3星"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/star.png"],
                ],
                [
                    ["value": "学院"],
                    ["value": "格黑娜学园"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/school.png"],
                ],
                [
                    ["value": "所属社团"],
                    ["value": "风纪委员会"],
                ],
                [
                    ["value": "战术位置作用"],
                    ["value": "输出"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/striker.png"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/back.png"],
                ],
                [
                    ["value": "攻击类型"],
                    ["value": "爆炸"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/explosion.png"],
                ],
                [
                    ["value": "防御类型"],
                    ["value": "弹力装甲"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/armor.png"],
                ],
                [
                    ["value": "武器类型"],
                    ["value": "MG"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/mg.png"],
                ],
                [
                    ["value": "市街"],
                    ["value": "D"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/street.png"],
                ],
                [
                    ["value": "屋外"],
                    ["value": "A"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/outdoor.png"],
                ],
                [
                    ["value": "室内"],
                    ["value": "S"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/indoor.png"],
                ],
                [
                    ["value": "角色技能"],
                    ["value": "技能名称"],
                    ["value": "开幕演出"],
                    ["value": "技能类型"],
                    ["value": "EX技能"],
                    ["value": "技能等级"],
                    ["value": "Lv.5"],
                    ["value": "技能COST"],
                    ["value": "COST: 6"],
                    ["value": "技能描述"],
                    ["value": "转换为集中射击姿态。"],
                ],
                [
                    ["value": "配音语言"],
                    ["value": "日配"],
                    ["value": "中配"],
                    ["value": "韩配"],
                ],
                [
                    ["value": "通常"],
                    ["value": "标题"],
                    ["value": "ブルーアーカイブ。"],
                    ["value": "蔚蓝档案。"],
                    ["value": "Blue Archive"],
                    ["type": "audio", "value": "//cdnimg.gamekee.com/voice/jp.mp3"],
                    ["type": "audio", "value": "//cdnimg.gamekee.com/voice/cn.mp3"],
                    ["type": "audio", "value": "//cdnimg.gamekee.com/voice/kr.mp3"],
                ],
                [
                    ["value": "立绘"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/student/portrait.webp"],
                ],
                [
                    ["value": "养成模拟"],
                    ["value": "攻击力 9812 (+9389)"],
                    ["value": "防御力 377 (+309)"],
                ],
            ],
            "styleData": [
                [
                    "name": "默认",
                    "data": [
                        ["value": "//cdnimg.gamekee.com/student/gallery.webp"],
                    ],
                ],
            ],
            "thumb": "//cdnimg.gamekee.com/student/thumb.webp",
            "summary": "Benchmark summary",
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [
                "thumb": "//cdnimg.gamekee.com/student/thumb.webp",
            ],
            html: nil,
            entry: makeCatalogEntry(contentId: 170_295, name: "日奈(礼服)", alias: "日奈")
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

        XCTAssertEqual(parsed.summary, "为了参加派对上了礼服裙。")
        XCTAssertEqual(parsed.profileRows.map(\.title), [
            "角色名称",
            "全名",
            "假名注音",
            "简中译名",
            "年龄",
            "生日",
            "身高",
            "画师",
            "实装日期",
            "声优",
            "兴趣爱好",
            "介绍",
            "稀有度",
            "学院",
            "所属社团",
            "战术位置作用",
            "攻击类型",
            "防御类型",
            "武器类型",
            "市街",
            "屋外",
            "室内",
        ])
        XCTAssertEqual(parsed.stats.map(\.title), [
            "稀有度",
            "学院",
            "所属社团",
            "战术位置作用",
            "攻击类型",
            "防御类型",
            "武器类型",
            "市街",
            "屋外",
            "室内",
            "生日",
            "实装日期",
        ])
        XCTAssertEqual(info.profileSections.map(\.kind), [.names, .info, .hobby, .sameName])
        XCTAssertEqual(info.profileSections[0].rows.map(\.title), [
            "角色名称",
            "全名",
            "假名注音",
            "简中译名",
        ])
        XCTAssertEqual(info.profileSections[1].rows.map(\.title), [
            "年龄",
            "生日",
            "身高",
            "画师",
            "实装日期",
            "声优",
        ])
        XCTAssertEqual(info.profileSections[2].rows.map(\.title), [
            "兴趣爱好",
        ])
        let profileMeta = BaStudentGuideMeta.profileMetaItems(from: info)
        XCTAssertEqual(profileMeta.map(\.value), [
            "3星",
            "格黑娜学园",
            "风纪委员会",
        ])
        let combatMetaValues = Dictionary(uniqueKeysWithValues: BaStudentGuideMeta.combatMetaItems(from: info).map {
            ($0.title, $0.value)
        })
        XCTAssertEqual(
            combatMetaValues[String(localized: "ba.student.detail.meta.tacticalPosition")],
            "输出"
        )
        XCTAssertEqual(
            combatMetaValues[String(localized: "ba.student.detail.meta.attackType")],
            "爆炸"
        )
        XCTAssertEqual(
            combatMetaValues[String(localized: "ba.student.detail.meta.defenseType")],
            "弹力装甲"
        )
        XCTAssertEqual(
            combatMetaValues[String(localized: "ba.student.detail.meta.weaponType")],
            "MG"
        )
        XCTAssertEqual(combatMetaValues[String(localized: "ba.student.detail.meta.street")], "D")
        XCTAssertEqual(combatMetaValues[String(localized: "ba.student.detail.meta.outdoor")], "A")
        XCTAssertEqual(combatMetaValues[String(localized: "ba.student.detail.meta.indoor")], "S")
        XCTAssertEqual(parsed.skillRows.first?.title, "技能名称")
        XCTAssertEqual(parsed.voiceRows.first?.lineHeaders, ["日配", "中配", "韩配"])
        XCTAssertEqual(parsed.galleryItems.first?.mediaKind, .image)
        XCTAssertFalse(parsed.simulateRows.isEmpty)
        XCTAssertEqual(parsed.imageURL?.absoluteString, "https://cdnimg.gamekee.com/student/portrait.webp")
    }

    func testContentParserMatchesBenchmarkOverviewFieldsFromLiveJSONShape() throws {
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["type": "text", "value": "稀有度"],
                    ["type": "text", "value": "3星"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_438/h_141/829/43637/2025/4/26/773868.png"],
                ],
                [
                    ["type": "text", "value": "战术作用"],
                    ["type": "text", "value": ""],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_160/h_40/829/43637/2025/4/27/318534.png"],
                ],
                [
                    ["type": "text", "value": "所属学园"],
                    ["type": "text", "value": "格黑娜学园"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/829/191981/2025/6/17/982730.png"],
                ],
                [
                    ["type": "text", "value": "所属社团"],
                    ["type": "text", "value": "风纪委员会"],
                ],
                [
                    ["type": "text", "value": "作用"],
                    ["type": "text", "value": "输出"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/829/103682/2025/6/1/546791.png"],
                ],
                [
                    ["type": "text", "value": "攻击类型"],
                    ["type": "text", "value": "爆炸"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/829/191981/2025/6/17/262482.png"],
                ],
                [
                    ["type": "text", "value": "防御类型"],
                    ["type": "text", "value": "弹力装甲"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/829/103682/2025/6/1/60247.png"],
                ],
                [
                    ["type": "text", "value": "位置"],
                    ["type": "text", "value": ""],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_210/h_55/829/43637/2025/4/26/219503.png"],
                ],
                [
                    ["type": "text", "value": "市街"],
                    ["type": "text", "value": "D"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_61/h_61/829/43637/2025/4/26/60850.png"],
                ],
                [
                    ["type": "text", "value": "屋外"],
                    ["type": "text", "value": "A"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_61/h_61/829/43637/2025/4/26/65737.png"],
                ],
                [
                    ["type": "text", "value": "屋内"],
                    ["type": "text", "value": "S"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_61/h_61/829/43637/2025/4/26/615650.png"],
                ],
                [
                    ["type": "text", "value": "武器类型"],
                    ["type": "text", "value": "MG"],
                    ["type": "image", "value": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_334/h_158/829/43637/2025/4/26/160682.png"],
                ],
                [
                    ["type": "text", "value": "个人简介"],
                    ["type": "text", "value": "为了参加派对换上了礼服裙，所属于格黑娜学园的风纪委员长。"],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeCatalogEntry(contentId: 611_753, name: "日奈(礼服)", alias: "日奈")
        )
        let info = BaStudentGuideInfo(
            contentId: 611_753,
            sourceURL: URL(string: "https://www.gamekee.com/ba/tj/611753.html"),
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
            contentSource: "content_cdn",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertTrue(parsed.profileRows.contains { $0.title == "作用" && $0.value == "输出" })
        XCTAssertTrue(parsed.profileRows.contains { $0.title == "所属学园" && $0.value == "格黑娜学园" })
        XCTAssertTrue(parsed.profileRows.contains { $0.title == "屋内" && $0.value == "S" })

        let profileMeta = BaStudentGuideMeta.profileMetaItems(from: info)
        XCTAssertEqual(profileMeta.map(\.value), ["3星", "格黑娜学园", "风纪委员会"])
        XCTAssertEqual(
            profileMeta[1].imageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_43/h_32/829/191981/2025/6/17/982730.png"
        )

        let combatMeta = BaStudentGuideMeta.combatMetaItems(from: info)
        let tactical = try XCTUnwrap(combatMeta.first {
            $0.title == String(localized: "ba.student.detail.meta.tacticalPosition")
        })
        let indoor = try XCTUnwrap(combatMeta.first {
            $0.title == String(localized: "ba.student.detail.meta.indoor")
        })

        XCTAssertEqual(tactical.value, "输出")
        XCTAssertEqual(
            tactical.imageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_160/h_40/829/43637/2025/4/27/318534.png"
        )
        XCTAssertEqual(
            tactical.extraImageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_210/h_55/829/43637/2025/4/26/219503.png"
        )
        XCTAssertEqual(indoor.value, "S")
        XCTAssertEqual(
            indoor.imageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_61/h_61/829/43637/2025/4/26/615650.png"
        )
    }

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
        let rows = BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil)

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
        let entry = try XCTUnwrap(BaGuideVoiceParser().parse(baseData: baseData, content: nil, sourceURL: nil).first)

        XCTAssertEqual(entry.title, "大厅1")
        XCTAssertEqual(entry.lineHeaders, ["日配", "中配"])
        XCTAssertEqual(entry.lines, ["日本語", "中文台词"])
        XCTAssertEqual(entry.audioURLs, [jpURL, cnURL])
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
            audioURLs: [jpURL, cnURL]
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
            audioURLs: [jpURL]
        )
        XCTAssertEqual(
            BaVoiceLanguageResolver.playbackURL(for: jpOnlyEntry, headers: ["日配", "中配"], selectedHeader: "中配"),
            jpURL
        )
        XCTAssertEqual(
            BaVoiceLanguageResolver.linePairs(for: entry, fallbackHeaders: headers).map(\.language),
            ["日配", "中配", "官翻"]
        )
    }

    func testVoicePlaybackSupportsOggThroughStreamingPath() throws {
        let mp3URL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.mp3"))
        let oggURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.ogg"))
        let opusURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.opus"))
        let flacURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/jp.flac"))
        let unknownVoiceURL = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/voice/play"))
        let pageURL = try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/detail"))

        XCTAssertTrue(BaVoicePlaybackController.supportsNativePlayback(mp3URL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(mp3URL))
        XCTAssertFalse(BaVoicePlaybackController.supportsNativePlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsOggPlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsOggPlayback(opusURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(opusURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsNativePlayback(flacURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(flacURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(unknownVoiceURL))
        XCTAssertFalse(BaVoicePlaybackController.supportsPlayback(pageURL))
    }

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

    func testReleaseDateExtractionHandlesGameKeeChineseDate() throws {
        let date = BaGuideTextNormalizer.extractDate(from: "实装日期：2024年1月24日")
        let components = try Calendar.current.dateComponents([.year, .month, .day], from: XCTUnwrap(date))

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 24)
    }

    private func makeCatalogEntry(
        contentId: Int64 = 609_145,
        name: String = "Test",
        alias: String = ""
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: 49443,
            contentId: contentId,
            name: name,
            alias: alias,
            aliasDisplay: alias,
            iconURL: nil,
            type: 0,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
            category: .students
        )
    }

    private func makePoolEntry(
        id: Int,
        name: String,
        linkURL: URL,
        studentGuideURL: URL? = nil
    ) -> BaPoolEntry {
        BaPoolEntry(
            id: id,
            name: name,
            tagId: 6,
            tagName: "",
            alias: "",
            startAt: Date(timeIntervalSince1970: 1_699_990_000),
            endAt: Date(timeIntervalSince1970: 1_700_010_000),
            linkURL: linkURL,
            imageURL: nil,
            contentId: nil,
            studentGuideURL: studentGuideURL
        )
    }
}

private extension Array {
    var single: Element? {
        count == 1 ? first : nil
    }
}
