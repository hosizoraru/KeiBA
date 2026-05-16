//
//  BaStudentDetailWeaponSimulationTests.swift
//  KeiBAOSTests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBAOS
import UniformTypeIdentifiers
import XCTest

final class BaStudentDetailWeaponSimulationTests: XCTestCase {
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

    func testWeaponCardDoesNotPullAbilityUnlockRowsIntoStarEffects() throws {
        let growthRows = [
            BaGuideRow(id: "weapon", title: "专武", value: "", imageURL: nil),
            BaGuideRow(id: "weapon-name", title: "专武名称", value: "终幕：毁灭者", imageURL: nil),
            BaGuideRow(id: "star3", title: "★3", value: "屋内战适应性强化至SS", imageURL: nil),
            BaGuideRow(id: "star4", title: "★4", value: "爆炸克制率增加10%", imageURL: nil),
            BaGuideRow(id: "ability", title: "能力解放", value: "*25级的数值*", imageURL: nil),
            BaGuideRow(id: "ability-lv", title: "25级", value: "生命值 / 775 / 攻击力 / 158 / 治愈力 / 199", imageURL: nil),
            BaGuideRow(id: "ability-extra1", title: "附加属性1", value: "生命值 / 775", imageURL: nil),
            BaGuideRow(id: "ability-extra2", title: "附加属性2", value: "攻击力 / 158", imageURL: nil),
            BaGuideRow(id: "ability-extra3", title: "附加属性3", value: "治愈力 / 199", imageURL: nil),
        ]

        let card = try XCTUnwrap(BaStudentWeaponDisplayModel.card(growthRows: growthRows, skillRows: []))

        XCTAssertEqual(card.starEffects.map(\.name), ["屋内战适应性强化至SS", "爆炸克制率增加10%"])
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

    func testContentParserKeepsWeaponStatsAndStarEffectsInGrowthRows() throws {
        let weaponIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/weapon.png"))
        let indoorIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/indoor.png"))
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["type": "text", "value": "专武"],
                ],
                [
                    ["type": "text", "value": "专武图标"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/weapon.png"],
                ],
                [
                    ["type": "text", "value": "专武名称"],
                    ["type": "text", "value": "终幕：毁灭者"],
                ],
                [
                    ["type": "text", "value": "专武数值"],
                    ["type": "text", "value": "Lv1 / Lv30 / Lv40 / Lv50 / Lv60"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "152 / 554 / 692 / 831 / 969"],
                ],
                [
                    ["type": "text", "value": "生命值"],
                    ["type": "text", "value": "492 / 1789 / 2237 / 2684 / 3132"],
                ],
                [
                    ["type": "text", "value": "★3"],
                    ["type": "text", "value": "屋内战适应性强化至SS"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/indoor.png"],
                ],
                [
                    ["type": "text", "value": "★4"],
                    ["type": "text", "value": "爆炸克制率增加10%"],
                ],
                [
                    ["type": "text", "value": "学生信息"],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )
        let card = try XCTUnwrap(
            BaStudentWeaponDisplayModel.card(
                growthRows: parsed.growthRows,
                skillRows: parsed.skillRows,
                simulateRows: parsed.simulateRows
            )
        )

        XCTAssertEqual(parsed.growthRows.map(\.title), [
            "专武", "专武图标", "专武名称", "专武数值", "攻击力", "生命值", "★3", "★4",
        ])
        XCTAssertFalse(parsed.profileRows.contains { $0.title == "攻击力" && $0.value.contains("969") })
        XCTAssertEqual(card.imageURL, weaponIcon)
        XCTAssertEqual(card.statHeaders, ["Lv1", "Lv30", "Lv40", "Lv50", "Lv60"])
        XCTAssertEqual(card.statRows, [
            BaStudentWeaponStatRow(title: "攻击力", values: ["152", "554", "692", "831", "969"]),
            BaStudentWeaponStatRow(title: "生命值", values: ["492", "1789", "2237", "2684", "3132"]),
        ])
        XCTAssertEqual(card.starEffects.map(\.name), ["屋内战适应性强化至SS", "爆炸克制率增加10%"])
        XCTAssertEqual(card.starEffects.first?.iconURL, indoorIcon)
    }

    func testSimulateParserFeedsWeaponStatsAndExtraStarEffects() throws {
        let weaponIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/weapon.png"))
        let indoorIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/indoor.png"))
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["type": "text", "value": "初始数据"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "100"],
                ],
                [
                    ["type": "text", "value": "顶级数据"],
                ],
                [
                    ["type": "text", "value": "专武"],
                    ["type": "text", "value": "*【Lv60】的数值*"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "969"],
                ],
                [
                    ["type": "text", "value": "生命值"],
                    ["type": "text", "value": "3132"],
                ],
                [
                    ["type": "text", "value": "★3"],
                    ["type": "text", "value": "屋内战适应性强化至SS"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/indoor.png"],
                ],
                [
                    ["type": "text", "value": "附加属性4"],
                    ["type": "text", "value": "★4 / 爆炸克制率增加10%"],
                ],
                [
                    ["type": "text", "value": "装备"],
                ],
            ],
        ]
        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )
        let growthRows = [
            BaGuideRow(id: "weapon", title: "专武", value: "", imageURL: nil),
            BaGuideRow(id: "weapon-icon", title: "专武图标", value: "", imageURL: weaponIcon),
            BaGuideRow(id: "weapon-name", title: "专武名称", value: "终幕：毁灭者", imageURL: nil),
            BaGuideRow(id: "weapon-levels", title: "专武数值", value: "Lv1 / Lv30 / Lv40 / Lv50 / Lv60", imageURL: nil),
            BaGuideRow(id: "favorite", title: "爱用品", value: "", imageURL: nil),
        ]

        let card = try XCTUnwrap(
            BaStudentWeaponDisplayModel.card(
                growthRows: growthRows,
                skillRows: [],
                simulateRows: parsed.simulateRows
            )
        )

        XCTAssertEqual(parsed.simulateRows.map(\.title), [
            "初始数据", "攻击力", "顶级数据", "专武", "攻击力", "生命值", "★3", "附加属性4", "装备",
        ])
        XCTAssertEqual(card.statHeaders, ["Lv60"])
        XCTAssertEqual(card.statRows, [
            BaStudentWeaponStatRow(title: "攻击力", values: ["969"]),
            BaStudentWeaponStatRow(title: "生命值", values: ["3132"]),
        ])
        XCTAssertEqual(card.starEffects.map(\.starLabel), ["★3", "★4"])
        XCTAssertEqual(card.starEffects[0].name, "屋内战适应性强化至SS")
        XCTAssertEqual(card.starEffects[0].iconURL, indoorIcon)
        XCTAssertEqual(card.starEffects[1].name, "爆炸克制率增加10%")
    }

    func testSimulateParserBackfillsSupplementIcons() throws {
        let content: BaJSONObject = [
            "baseData": [
                [
                    ["type": "text", "value": "专武图标"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/weapon.png"],
                ],
                [
                    ["type": "text", "value": "装备1"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/equipment1.png"],
                ],
                [
                    ["type": "text", "value": "爱用品图标"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/favor.png"],
                ],
                [
                    ["type": "text", "value": "能力解放所需材料"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/unlock-a.png"],
                    ["type": "image", "value": "//cdnimg.gamekee.com/unlock-b.png"],
                ],
                [
                    ["type": "text", "value": "初始数据"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "100"],
                ],
                [
                    ["type": "text", "value": "顶级数据"],
                ],
                [
                    ["type": "text", "value": "专武"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "969"],
                ],
                [
                    ["type": "text", "value": "装备"],
                ],
                [
                    ["type": "text", "value": "1号装备"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "12"],
                ],
                [
                    ["type": "text", "value": "爱用品"],
                ],
                [
                    ["type": "text", "value": "攻击力"],
                    ["type": "text", "value": "20"],
                ],
                [
                    ["type": "text", "value": "能力解放"],
                ],
                [
                    ["type": "text", "value": "25级"],
                ],
                [
                    ["type": "text", "value": "生命值"],
                    ["type": "text", "value": "300"],
                ],
            ],
        ]

        let parsed = BaGuideContentParser().parse(
            content: content,
            apiData: [:],
            html: nil,
            entry: makeStudentDetailCatalogEntry()
        )

        let weaponRow = try XCTUnwrap(parsed.simulateRows.first { $0.title == "攻击力" && $0.value == "969" })
        XCTAssertEqual(weaponRow.imageURL?.absoluteString, "https://cdnimg.gamekee.com/weapon.png")

        let equipmentSlot = try XCTUnwrap(parsed.simulateRows.first { $0.title == "1号装备" })
        XCTAssertEqual(equipmentSlot.imageURL?.absoluteString, "https://cdnimg.gamekee.com/equipment1.png")

        let favoriteRow = try XCTUnwrap(parsed.simulateRows.first { $0.title == "攻击力" && $0.value == "20" })
        XCTAssertEqual(favoriteRow.imageURL?.absoluteString, "https://cdnimg.gamekee.com/favor.png")

        let unlockLevelRow = try XCTUnwrap(parsed.simulateRows.first { $0.title == "25级" })
        XCTAssertEqual(unlockLevelRow.imageURLs?.map(\.absoluteString), [
            "https://cdnimg.gamekee.com/unlock-a.png",
            "https://cdnimg.gamekee.com/unlock-b.png",
        ])
    }

    func testSimulationDisplayModelBuildsSectionsAndGroups() throws {
        let equipmentIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/equipment1.png"))
        let weaponIcon = try XCTUnwrap(URL(string: "https://cdnimg.gamekee.com/weapon.png"))
        let rows = [
            BaGuideRow(id: "initial", title: "初始数据", value: "", imageURL: nil),
            BaGuideRow(id: "atk1", title: "攻击力", value: "100", imageURL: nil),
            BaGuideRow(id: "hp1", title: "生命值", value: "1000", imageURL: nil),
            BaGuideRow(id: "max", title: "顶级数据", value: "", imageURL: nil),
            BaGuideRow(id: "atk2", title: "攻击力", value: "180", imageURL: nil),
            BaGuideRow(id: "hp2", title: "生命值", value: "1400", imageURL: nil),
            BaGuideRow(id: "weapon", title: "专武", value: "*【Lv60】的数值*", imageURL: nil),
            BaGuideRow(id: "weapon-stat", title: "攻击力", value: "969", imageURL: weaponIcon),
            BaGuideRow(id: "equipment", title: "装备", value: "", imageURL: nil),
            BaGuideRow(id: "slot", title: "1号装备", value: "", imageURL: equipmentIcon),
            BaGuideRow(id: "item", title: "帽子", value: "T9", imageURL: nil),
            BaGuideRow(id: "equipment-stat", title: "攻击力", value: "45", imageURL: nil),
            BaGuideRow(id: "bond", title: "羁绊等级奖励", value: "*25级*", imageURL: nil),
            BaGuideRow(id: "role", title: "羁绊角色1", value: "", imageURL: weaponIcon),
            BaGuideRow(id: "bond-stat", title: "攻击力", value: "12", imageURL: nil),
        ]

        let data = BaStudentSimulationDisplayModel.build(rows: rows)
        XCTAssertEqual(data.initialRows.map(\.title), ["攻击力", "生命值"])
        XCTAssertEqual(data.maximumRows.map(\.title), ["攻击力", "生命值"])
        XCTAssertEqual(data.weaponHint, "【Lv60】的数值")
        XCTAssertEqual(BaStudentSimulationDisplayModel.levelCapsule(from: data.weaponHint), "Lv60")
        XCTAssertEqual(BaStudentSimulationDisplayModel.maxDeltaText(maxValue: "180", initialValue: "100"), "(+80)")

        let equipmentGroups = BaStudentSimulationDisplayModel.equipmentGroups(from: data.equipmentRows)
        XCTAssertEqual(equipmentGroups.first?.slotLabel, "1号装备")
        XCTAssertEqual(equipmentGroups.first?.itemName, "帽子")
        XCTAssertEqual(equipmentGroups.first?.iconURL, equipmentIcon)
        XCTAssertEqual(equipmentGroups.first?.statRows.map(\.title), ["攻击力"])

        let weaponData = BaStudentSimulationDisplayModel.weaponViewData(rows: data.weaponRows)
        XCTAssertEqual(weaponData.imageURL, weaponIcon)

        let bondGroups = BaStudentSimulationDisplayModel.bondGroups(from: data.bondRows)
        XCTAssertEqual(bondGroups.first?.roleLabel, "羁绊角色1")
        XCTAssertEqual(bondGroups.first?.statRows.first?.value, "12")
    }

    func testStudentDetailSourceErrorUsesFriendlyMessage() {
        XCTAssertEqual(
            BaDataErrorPresenter.studentDetailMessage(for: "content_cdn-empty"),
            String(localized: "ba.student.detail.partialSource.warning")
        )
    }
}
