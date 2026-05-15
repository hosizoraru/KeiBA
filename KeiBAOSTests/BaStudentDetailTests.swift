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

    func testSkillCardsParseLevelsCostAndDescriptionIcons() throws {
        let skillIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_64/h_64/skill.png"))
        let burnIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/burn.png"))
        let glossaryIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/focus.png"))
        let rows = [
            BaGuideRow(id: "type", title: "技能类型", value: "EX技能", imageURL: nil),
            BaGuideRow(id: "name", title: "技能名称", value: "开幕演出", imageURL: nil),
            BaGuideRow(id: "icon", title: "技能图标", value: "", imageURL: skillIcon),
            BaGuideRow(
                id: "lv1",
                title: "LV.1",
                value: "对1名敌人造成攻击力300%的伤害，并赋予集中射击。",
                imageURL: burnIcon,
                imageURLs: [burnIcon]
            ),
            BaGuideRow(id: "cost1", title: "技能COST", value: "COST: 6", imageURL: nil),
            BaGuideRow(
                id: "lv5",
                title: "LV.5",
                value: "对1名敌人造成攻击力650%的伤害，并赋予集中射击。",
                imageURL: burnIcon,
                imageURLs: [burnIcon]
            ),
            BaGuideRow(id: "cost5", title: "技能COST", value: "5", imageURL: nil),
            BaGuideRow(id: "glossary-start", title: "技能名词", value: "", imageURL: nil),
            BaGuideRow(id: "glossary", title: "集中射击", value: "", imageURL: glossaryIcon),
        ]

        let card = try XCTUnwrap(BaStudentSkillDisplayModel.cards(from: rows).first)

        XCTAssertEqual(card.type, "EX技能")
        XCTAssertEqual(card.name, "开幕演出")
        XCTAssertEqual(card.iconURL, skillIcon)
        XCTAssertEqual(card.levelOptions, ["Lv.1", "Lv.5"])
        XCTAssertEqual(card.defaultLevel, "Lv.5")
        XCTAssertEqual(card.description(for: "Lv.1"), "对1名敌人造成攻击力300%的伤害，并赋予集中射击。")
        XCTAssertEqual(card.description(for: "Lv.5"), "对1名敌人造成攻击力650%的伤害，并赋予集中射击。")
        XCTAssertEqual(card.cost(for: "Lv.1"), "6")
        XCTAssertEqual(card.cost(for: "Lv.5"), "5")
        XCTAssertEqual(card.descriptionIcons(for: "Lv.5"), [burnIcon])
        XCTAssertEqual(card.glossaryIcons["集中射击"], glossaryIcon)
    }

    func testContentParserSplitsRoleSkillPairsForSkillCards() throws {
        let parsed = BaGuideContentParser().parse(
            content: [
                "baseData": [
                    [
                        ["value": "角色技能"],
                        ["value": "技能名称"],
                        ["value": "开幕演出"],
                        ["value": "技能类型"],
                        ["value": "EX技能"],
                        ["value": "LV.1"],
                        ["value": "造成300%的伤害。"],
                        ["value": "技能COST"],
                        ["value": "COST: 6"],
                    ],
                ],
            ],
            apiData: [:],
            html: nil,
            entry: makeCatalogEntry()
        )
        let card = try XCTUnwrap(BaStudentSkillDisplayModel.cards(from: parsed.skillRows).first)

        XCTAssertEqual(parsed.skillRows.map(\.title), ["技能名称", "技能类型", "LV.1", "技能COST"])
        XCTAssertEqual(card.name, "开幕演出")
        XCTAssertEqual(card.type, "EX技能")
        XCTAssertEqual(card.description(for: "Lv.1"), "造成300%的伤害。")
        XCTAssertEqual(card.cost(for: "Lv.1"), "6")
    }

    func testSkillCardsAttachExplicitSkillLevelRowToDescriptionAndCost() throws {
        let rows = [
            BaGuideRow(id: "name", title: "技能名称", value: "开幕演出", imageURL: nil),
            BaGuideRow(id: "type", title: "技能类型", value: "EX技能", imageURL: nil),
            BaGuideRow(id: "level", title: "技能等级", value: "Lv.5", imageURL: nil),
            BaGuideRow(id: "cost", title: "技能COST", value: "COST: 6", imageURL: nil),
            BaGuideRow(id: "desc", title: "技能描述", value: "转换为集中射击姿态。", imageURL: nil),
        ]

        let card = try XCTUnwrap(BaStudentSkillDisplayModel.cards(from: rows).first)

        XCTAssertEqual(card.levelOptions, ["Lv.5"])
        XCTAssertEqual(card.defaultLevel, "Lv.5")
        XCTAssertEqual(card.cost(for: "Lv.5"), "6")
        XCTAssertEqual(card.description(for: "Lv.5"), "转换为集中射击姿态。")
    }

    func testSkillCardsKeepEXVariantsWhenOnlyFirstRowHasSkillType() throws {
        let rows = [
            BaGuideRow(id: "type", title: "技能类型", value: "EX技能", imageURL: nil),
            BaGuideRow(id: "name0", title: "技能名称", value: "开幕演出：伊施波设", imageURL: nil),
            BaGuideRow(id: "lv0", title: "LV5", value: "转换为集中射击姿态（持续10秒）。", imageURL: nil),
            BaGuideRow(id: "cost0", title: "技能COST", value: "6", imageURL: nil),
            BaGuideRow(id: "name1", title: "技能名称", value: "旋律第一音节", imageURL: nil),
            BaGuideRow(id: "lv1", title: "LV5", value: "造成攻击力618%的伤害。", imageURL: nil),
            BaGuideRow(id: "cost1", title: "技能COST", value: "0", imageURL: nil),
            BaGuideRow(id: "name2", title: "技能名称", value: "旋律第二音节", imageURL: nil),
            BaGuideRow(id: "name3", title: "技能名称", value: "终幕之旋律", imageURL: nil),
            BaGuideRow(id: "lv3", title: "LV5", value: "造成攻击力1288%的伤害。", imageURL: nil),
            BaGuideRow(id: "upgrade", title: "EX技能升级材料", value: "", imageURL: nil),
            BaGuideRow(id: "normal-type", title: "技能类型", value: "普通技能", imageURL: nil),
            BaGuideRow(id: "normal-name", title: "技能名称", value: "周密准备", imageURL: nil),
            BaGuideRow(id: "normal-lv", title: "LV10", value: "普通技能描述。", imageURL: nil),
        ]

        let cards = BaStudentSkillDisplayModel.cards(from: rows)

        XCTAssertEqual(cards.map(\.name), [
            "开幕演出：伊施波设",
            "旋律第一音节",
            "旋律第二音节",
            "终幕之旋律",
            "周密准备",
        ])
        XCTAssertEqual(cards.prefix(4).map(\.type), Array(repeating: "EX技能", count: 4))
        XCTAssertEqual(cards[1].description(for: "Lv.5"), "造成攻击力618%的伤害。")
        XCTAssertEqual(cards[2].description(for: "Lv.5"), "造成攻击力618%的伤害。")
        XCTAssertEqual(cards[2].cost(for: "Lv.5"), "0")
        XCTAssertEqual(cards[3].description(for: "Lv.5"), "造成攻击力1288%的伤害。")
        XCTAssertEqual(cards[3].cost(for: "Lv.5"), "0")
    }

    func testSkillCardsMatchHinaDressVariantPayloadShape() throws {
        let icon0 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/skill0.png"))
        let icon1 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/skill1.png"))
        let icon2 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/skill2.png"))
        let icon3 = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/skill3.png"))
        let passiveIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/passive.png"))
        let materialIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/material.png"))
        let rows = [
            BaGuideRow(id: "section", title: "技能", value: "", imageURL: nil),
            BaGuideRow(id: "type", title: "技能类型", value: "EX技能", imageURL: nil),
            BaGuideRow(id: "name0", title: "技能名称", value: "开幕演出：伊施波设", imageURL: nil),
            BaGuideRow(id: "icon0", title: "技能图标", value: "", imageURL: icon0),
            BaGuideRow(id: "desc", title: "技能描述", value: "", imageURL: nil),
            BaGuideRow(id: "lv0", title: "LV5", value: "转换为集中射击姿态。", imageURL: nil),
            BaGuideRow(id: "cost0", title: "技能COST", value: "6", imageURL: nil),
            BaGuideRow(id: "name1", title: "技能名称", value: "旋律第一音节", imageURL: nil),
            BaGuideRow(id: "icon1", title: "技能图标", value: "", imageURL: icon1),
            BaGuideRow(id: "lv1", title: "LV5", value: "造成攻击力618%的伤害。", imageURL: nil),
            BaGuideRow(id: "cost1", title: "技能COST", value: "0", imageURL: nil),
            BaGuideRow(id: "name2", title: "技能名称", value: "旋律第二音节", imageURL: nil),
            BaGuideRow(id: "icon2", title: "技能图标", value: "", imageURL: icon2),
            BaGuideRow(id: "name3", title: "技能名称", value: "终幕之旋律", imageURL: nil),
            BaGuideRow(id: "icon3", title: "技能图标", value: "", imageURL: icon3),
            BaGuideRow(id: "lv3", title: "LV5", value: "造成攻击力1288%的伤害。", imageURL: nil),
            BaGuideRow(id: "material", title: "EX技能升级材料", value: "", imageURL: nil),
            BaGuideRow(id: "material-lv", title: "LV2", value: "", imageURL: materialIcon),
            BaGuideRow(id: "normal-type", title: "技能类型", value: "普通技能", imageURL: nil),
            BaGuideRow(id: "normal-name", title: "技能名称", value: "周密准备", imageURL: nil),
            BaGuideRow(id: "normal-icon", title: "技能图标", value: "", imageURL: passiveIcon),
            BaGuideRow(id: "normal-lv", title: "LV10", value: "", imageURL: nil),
            BaGuideRow(id: "passive-type", title: "技能类型", value: "被动技能", imageURL: nil),
            BaGuideRow(id: "passive-name", title: "技能名称", value: "投入演奏的心情", imageURL: nil),
            BaGuideRow(id: "passive-icon", title: "技能图标", value: "", imageURL: passiveIcon),
            BaGuideRow(id: "passive-lv", title: "LV10", value: "攻击力增加16.2%，暴击值增加16.2%", imageURL: nil),
        ]

        let cards = BaStudentSkillDisplayModel.cards(from: rows)

        XCTAssertEqual(cards.map(\.name), [
            "开幕演出：伊施波设",
            "旋律第一音节",
            "旋律第二音节",
            "终幕之旋律",
            "投入演奏的心情",
        ])
        XCTAssertEqual(cards.prefix(4).map(\.type), Array(repeating: "EX技能", count: 4))
        XCTAssertEqual(cards[0].iconURL, icon0)
        XCTAssertEqual(cards[2].iconURL, icon2)
        XCTAssertEqual(cards[2].description(for: "Lv.5"), "造成攻击力618%的伤害。")
        XCTAssertEqual(cards[2].cost(for: "Lv.5"), "0")
        XCTAssertEqual(cards[3].iconURL, icon3)
        XCTAssertEqual(cards[3].cost(for: "Lv.5"), "0")
        XCTAssertEqual(cards[4].type, "被动技能")
        XCTAssertEqual(cards[4].description(for: "Lv.10"), "攻击力增加16.2%，暴击值增加16.2%")
    }

    func testSkillCardsDoNotInheritDescriptionAcrossSkillTypes() throws {
        let rows = [
            BaGuideRow(id: "type", title: "技能类型", value: "EX技能", imageURL: nil),
            BaGuideRow(id: "name", title: "技能名称", value: "终幕之旋律", imageURL: nil),
            BaGuideRow(id: "lv", title: "LV5", value: "造成攻击力1288%的伤害。", imageURL: nil),
            BaGuideRow(id: "passive-type", title: "技能类型", value: "被动技能", imageURL: nil),
            BaGuideRow(id: "passive-name", title: "技能名称", value: "空白占位", imageURL: nil),
        ]

        let cards = BaStudentSkillDisplayModel.cards(from: rows)

        XCTAssertEqual(cards.map(\.name), ["终幕之旋律"])
    }

    func testWeaponCardParsesMainWeaponAndStopsBeforeOtherGrowthBlocks() throws {
        let weaponIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/weapon.png"))
        let abilityIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/ability.png"))
        let growthRows = [
            BaGuideRow(id: "equip", title: "装备1", value: "帽子", imageURL: nil),
            BaGuideRow(id: "weapon", title: "专武", value: "", imageURL: nil),
            BaGuideRow(id: "weapon-icon", title: "专武图标", value: "", imageURL: weaponIcon),
            BaGuideRow(id: "weapon-name", title: "专武名称", value: "终幕：毁灭者", imageURL: nil),
            BaGuideRow(id: "weapon-desc", title: "专武描述", value: "像日奈手足一样被日常使用的机枪。", imageURL: nil),
            BaGuideRow(id: "weapon-levels", title: "专武数值", value: "Lv1 / Lv30 / Lv50", imageURL: nil),
            BaGuideRow(id: "attack", title: "攻击力", value: "10 / 20 / 30", imageURL: nil),
            BaGuideRow(id: "favorite", title: "爱用品", value: "", imageURL: nil),
            BaGuideRow(id: "ability", title: "能力解放所需材料", value: "素材", imageURL: abilityIcon),
        ]

        let card = try XCTUnwrap(BaStudentWeaponDisplayModel.card(growthRows: growthRows, skillRows: []))

        XCTAssertEqual(card.name, "终幕：毁灭者")
        XCTAssertEqual(card.imageURL, weaponIcon)
        XCTAssertEqual(card.description, "像日奈手足一样被日常使用的机枪。")
        XCTAssertEqual(card.statHeaders, ["Lv1", "Lv30", "Lv50"])
        XCTAssertEqual(card.statRows, [BaStudentWeaponStatRow(title: "攻击力", values: ["10", "20", "30"])])
        XCTAssertTrue(card.statRows.allSatisfy { $0.title != "能力解放所需材料" })
    }

    func testWeaponCardParsesHinaDressTwoStarPassiveUpgradeFromSkillRows() throws {
        let weaponIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/weapon.png"))
        let effectIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_64/h_64/effect.png"))
        let termIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_47/h_54/taunt.png"))
        let growthRows = [
            BaGuideRow(id: "weapon", title: "专武", value: "", imageURL: nil),
            BaGuideRow(id: "weapon-icon", title: "专武图标", value: "", imageURL: weaponIcon),
            BaGuideRow(id: "weapon-name", title: "专武名称", value: "终幕：毁灭者", imageURL: nil),
            BaGuideRow(id: "favorite", title: "爱用品", value: "", imageURL: nil),
        ]
        let skillRows = [
            BaGuideRow(id: "glossary-start", title: "技能名词", value: "名词图标 / 名词解释", imageURL: nil),
            BaGuideRow(id: "glossary", title: "嘲讽", value: "持有者只会攻击施加嘲讽的目标", imageURL: termIcon),
            BaGuideRow(id: "star", title: "★2 技能名称", value: "投入演奏的心情+", imageURL: nil),
            BaGuideRow(id: "effect-icon", title: "技能图标", value: "", imageURL: effectIcon),
            BaGuideRow(id: "lv1", title: "LV1", value: "攻击力增加266，暴击值增加80", imageURL: nil),
            BaGuideRow(id: "lv10", title: "LV10", value: "攻击力增加506，暴击值增加152", imageURL: nil),
            BaGuideRow(id: "t2", title: "T2技能图标", value: "", imageURL: nil),
            BaGuideRow(id: "normal", title: "技能类型", value: "普通技能", imageURL: nil),
        ]

        let card = try XCTUnwrap(BaStudentWeaponDisplayModel.card(growthRows: growthRows, skillRows: skillRows))
        let effect = try XCTUnwrap(card.starEffects.first)

        XCTAssertEqual(card.name, "终幕：毁灭者")
        XCTAssertEqual(card.starEffects.count, 1)
        XCTAssertEqual(effect.starLabel, "★2")
        XCTAssertEqual(effect.name, "投入演奏的心情+")
        XCTAssertEqual(effect.iconURL, effectIcon)
        XCTAssertEqual(effect.roleTag, String(localized: "ba.student.detail.skill.sub"))
        XCTAssertEqual(effect.levelOptions, ["Lv.1", "Lv.10"])
        XCTAssertEqual(effect.defaultLevel, "Lv.10")
        XCTAssertEqual(effect.description(for: "Lv.10"), "攻击力增加506，暴击值增加152")
        XCTAssertEqual(card.glossaryIcons["嘲讽"], termIcon)
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
