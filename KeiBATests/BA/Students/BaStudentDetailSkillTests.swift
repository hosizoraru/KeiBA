//
//  BaStudentDetailSkillTests.swift
//  KeiBATests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBA
import UniformTypeIdentifiers
import XCTest

final class BaStudentDetailSkillTests: XCTestCase {
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

        XCTAssertEqual(
            BaStudentSkillTextNormalizer.richTextSegments(
                description: "转换为集中射击姿态（持续10秒）。",
                glossaryIcons: card.glossaryIcons,
                leadingIcons: []
            ),
            [
                .text("转换为"),
                .icon(glossaryIcon),
                .term("集中射击"),
                .text("姿态（持续"),
                .highlightedText("10秒"),
                .text("）。"),
            ]
        )
        XCTAssertEqual(
            BaStudentSkillTextNormalizer.richTextSegments(
                description: "造成伤害。",
                glossaryIcons: card.glossaryIcons,
                leadingIcons: [burnIcon]
            ).prefix(2),
            [
                .icon(burnIcon),
                .text(" 造成伤害。"),
            ]
        )
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
            entry: makeStudentDetailCatalogEntry()
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
}
