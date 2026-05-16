//
//  BaGuideContentParserDataTests.swift
//  KeiBAOSTests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBAOS
import AVFAudio
import Foundation
import XCTest

final class BaGuideContentParserDataTests: XCTestCase {
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
            entry: makeDataBridgeCatalogEntry(contentId: 170_295, name: "日奈(礼服)", alias: "日奈")
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
            voiceLanguageHeaders: parsed.voiceLanguageHeaders,
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
        XCTAssertEqual(info.profileSections.map(\.kind), [.names, .info, .hobby])
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
            entry: makeDataBridgeCatalogEntry(contentId: 611_753, name: "日奈(礼服)", alias: "日奈")
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
            voiceLanguageHeaders: parsed.voiceLanguageHeaders,
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

    func testArrayRichTextProfileDropsEditorMetadataForNpcSatelliteShape() throws {
        let content: [Any] = [
            [
                "type": "illustrated-book",
                "data": [
                    [
                        "type": "character-profile",
                        "data": [
                            "name": richText(["伪学生会长"]),
                            "attrList": [
                                [
                                    "title": richText(["其他译名"]),
                                    "content": richText(["会长"]),
                                ],
                                [
                                    "title": richText(["所属"]),
                                    "content": richText(["联邦学生会 / 总学生会长"]),
                                ],
                                [
                                    "title": richText(["首次登场"]),
                                    "content": richText(["第二部主线 Vol.0"]),
                                ],
                            ],
                            "descTitle": richText(["个人简介"]),
                            "desc": richText([
                                "出处: 第二部主线 Vol.0 联邦学生会篇",
                                "学生会长，堂堂归来！",
                            ]),
                            "imageList": [
                                "//cdnimg-v2.gamekee.com/wiki2.0/images/w_918/h_2570/829/191981/2026/3/21/859265.png",
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
            entry: makeDataBridgeCatalogEntry(contentId: 702_789, name: "伪学生会长", category: .npcSatellite)
        )

        let packedProfileText = parsed.profileRows
            .flatMap { [$0.title, $0.value] }
            .joined(separator: "\n")
        XCTAssertFalse(packedProfileText.contains("simpleEditor"))
        XCTAssertFalse(packedProfileText.contains("paragraph"))
        XCTAssertTrue(parsed.profileRows.contains { $0.title == "角色名称" && $0.value == "伪学生会长" })
        XCTAssertTrue(parsed.profileRows.contains { $0.title == "所属" && $0.value == "联邦学生会 / 总学生会长" })
        XCTAssertTrue(parsed.summary.contains("出处: 第二部主线 Vol.0 联邦学生会篇"))
        XCTAssertEqual(
            parsed.imageURL?.absoluteString,
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_918/h_2570/829/191981/2026/3/21/859265.png"
        )
    }

    func testArrayAudioInfoBuildsNpcSatelliteVoiceRows() throws {
        let parsed = BaGuideContentParser().parse(
            content: audioInfoContentFixture(),
            apiData: [:],
            html: nil,
            entry: makeDataBridgeCatalogEntry(contentId: 161_175, name: "阿罗娜（阿洛娜）", category: .npcSatellite)
        )

        let voice = try XCTUnwrap(parsed.voiceRows.first { $0.title == "日程进入1" })
        XCTAssertEqual(parsed.voiceLanguageHeaders, ["日配", "中配", "旧版日配"])
        XCTAssertEqual(voice.section, "角色台词及语音")
        XCTAssertEqual(voice.lineHeaders, ["日配", "中配", "旧版日配", "官翻"])
        XCTAssertEqual(voice.lines, [
            "ログインしました。先生、おかえりなさい。",
            "老师，欢迎回来。",
            "先生、お待ちしていました。",
            "老师，欢迎回来。",
        ])
        XCTAssertEqual(voice.audioHeaders, ["日配", "中配", "旧版日配"])
        XCTAssertEqual(voice.audioURLs?.map(\.absoluteString), [
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/324967.ogg",
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/231550.ogg",
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/484551.ogg",
        ])

        let info = BaStudentGuideInfo(
            contentId: 161_175,
            sourceURL: URL(string: "https://www.gamekee.com/ba/161175.html"),
            title: "阿罗娜（阿洛娜）",
            subtitle: "GameKee",
            summary: parsed.summary,
            imageURL: parsed.imageURL,
            stats: parsed.stats,
            profileRows: parsed.profileRows,
            skillRows: parsed.skillRows,
            voiceLanguageHeaders: parsed.voiceLanguageHeaders,
            voiceRows: parsed.voiceRows,
            galleryItems: parsed.galleryItems,
            growthRows: parsed.growthRows,
            simulateRows: parsed.simulateRows,
            contentSource: "content_cdn",
            syncedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertTrue(BaStudentDetailPageAvailability.pages(category: .npcSatellite, info: info).contains(.voice))
    }

    func testArrayAudioInfoPreservesDuplicateNpcSatelliteVoiceComponentsAsOldVersions() throws {
        let parsed = BaGuideContentParser().parse(
            content: duplicatedAudioInfoContentFixture(),
            apiData: [:],
            html: nil,
            entry: makeDataBridgeCatalogEntry(contentId: 161_188, name: "凛", category: .npcSatellite)
        )

        let voice = try XCTUnwrap(parsed.voiceRows.first { $0.title == "日程进入1" })
        XCTAssertEqual(parsed.voiceLanguageHeaders, ["日配", "中配", "旧版日配", "旧版中配"])
        XCTAssertEqual(voice.lineHeaders, ["日配", "中配", "旧版日配", "旧版中配", "官翻"])
        XCTAssertEqual(voice.lines, [
            "お待ちしておりました。先生。",
            "老师，等您很久了。",
            "老师，等您很久了",
            "老师，欢迎回来。",
            "恭候您的光临，老师。",
        ])
        XCTAssertEqual(voice.audioHeaders, ["日配", "中配", "旧版日配", "旧版中配"])
        XCTAssertEqual(voice.audioURLs?.map(\.absoluteString), [
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/324967.ogg",
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/10/8/49278.ogg",
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/11/19/108692.ogg",
            "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/11/19/391048.ogg",
        ])
    }

    private func audioInfoContentFixture() -> [Any] {
        [
            [
                "type": "illustrated-book",
                "data": [
                    [
                        "type": "audio-info",
                        "data": [
                            "title": "角色台词及语音",
                            "tabs": [
                                ["key": "jp", "label": richText(["日配"])],
                                ["key": "cn", "label": richText(["国配"])],
                                ["key": "old-jp", "label": richText(["旧版日配"])],
                            ],
                            "list": [
                                voiceGroup(
                                    tabKey: "jp",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/324967.ogg",
                                    lines: [
                                        "ログインしました。先生、おかえりなさい。",
                                        "老师，欢迎回来。",
                                    ]
                                ),
                                voiceGroup(
                                    tabKey: "cn",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/231550.ogg",
                                    lines: [
                                        "老师，欢迎回来。",
                                    ]
                                ),
                                voiceGroup(
                                    tabKey: "old-jp",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/484551.ogg",
                                    lines: [
                                        "先生、お待ちしていました。",
                                    ]
                                ),
                            ],
                        ],
                    ],
                ],
            ],
        ]
    }

    private func duplicatedAudioInfoContentFixture() -> [Any] {
        [
            [
                "type": "illustrated-book",
                "data": [
                    [
                        "type": "audio-info",
                        "data": [
                            "title": "角色台词及语音",
                            "tabs": [
                                ["key": "jp", "label": richText(["日配"])],
                                ["key": "cn", "label": richText(["国配"])],
                            ],
                            "list": [
                                voiceGroup(
                                    tabKey: "jp",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/7/3/324967.ogg",
                                    lines: [
                                        "お待ちしておりました。先生。",
                                        "恭候您的光临，老师。",
                                    ]
                                ),
                                voiceGroup(
                                    tabKey: "cn",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/10/8/49278.ogg",
                                    lines: [
                                        "老师，等您很久了。",
                                    ]
                                ),
                            ],
                        ],
                    ],
                    [
                        "type": "audio-info",
                        "data": [
                            "title": "角色台词及语音",
                            "tabs": [
                                ["key": "jp", "label": richText(["日配"])],
                                ["key": "cn", "label": richText(["国配"])],
                            ],
                            "list": [
                                voiceGroup(
                                    tabKey: "jp",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/11/19/108692.ogg",
                                    lines: [
                                        "老师，等您很久了",
                                    ]
                                ),
                                voiceGroup(
                                    tabKey: "cn",
                                    audio: "//cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/191981/2024/11/19/391048.ogg",
                                    lines: [
                                        "老师，欢迎回来。",
                                    ]
                                ),
                            ],
                        ],
                    ],
                ],
            ],
        ]
    }

    private func voiceGroup(tabKey: String, audio: String, lines: [String]) -> BaJSONObject {
        [
            "filterTabKey": tabKey,
            "title": richText([""]),
            "content": [
                [
                    "name": richText(["日程进入1"]),
                    "desc": richText(lines),
                    "audio": audio,
                ],
            ],
        ]
    }

    private func richText(_ lines: [String]) -> BaJSONObject {
        [
            "type": "simpleEditor",
            "data": lines.map { line in
                [
                    "type": "paragraph",
                    "children": [
                        ["text": line],
                    ],
                ]
            },
        ]
    }
}
