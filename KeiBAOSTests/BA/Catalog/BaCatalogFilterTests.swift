//
//  BaCatalogFilterTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/18.
//

@testable import KeiBAOS
import Foundation
import XCTest

final class BaCatalogFilterTests: XCTestCase {
    func testParsesFilterGroupsAndLeavesReleaseDateAsSortOnly() throws {
        let data = Data(
            """
            {
              "code": 0,
              "data": {
                "entry_filter": [
                  {
                    "id": 68,
                    "name": "星级",
                    "children": [
                      { "id": 176, "name": "三星" },
                      { "id": 70, "name": "二星" }
                    ]
                  },
                  {
                    "id": 3774,
                    "name": "实装日期",
                    "children": []
                  },
                  {
                    "id": 188,
                    "name": "武器种类",
                    "children": [
                      { "id": 193, "name": "手枪HG" }
                    ]
                  }
                ]
              }
            }
            """.utf8
        )

        let groups = try BaGuideCatalogRepository(client: GameKeeClient()).parseFilterGroups(data: data)

        XCTAssertEqual(groups.map(\.kind), [.rarity, .weaponType])
        XCTAssertEqual(groups.first?.options.map(\.title), ["三星", "二星"])
    }

    func testParsesStudentMetadataFromTjList() throws {
        let frontIcon = URL(string: "https://cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/829/43637/2023/7/4/406009.png")!
        let filterGroups = [
            BaCatalogFilterGroup(
                id: 183,
                title: "站位前后",
                kind: .rangePosition,
                options: [
                    BaCatalogFilterOption(id: 184, title: "Front（前排）", iconURL: frontIcon),
                ]
            ),
        ]
        let data = Data(
            """
            {
              "code": 0,
              "data": [
                {
                  "ba": {
                    "content_id": 53921,
                    "name": "遥香",
                    "level": "1星",
                    "zy": "坦克",
                    "wz": "//cdnimg.gamekee.com/wiki2.0/images/w_44/h_44/829/43637/2023/7/4/406009.png",
                    "wq": "SG",
                    "sj": "C",
                    "sw": "B",
                    "sn": "A",
                    "xy": "格黑娜学园",
                    "st": "社团"
                  }
                }
              ]
            }
            """.utf8
        )

        let metadata = try BaGuideCatalogRepository(client: GameKeeClient())
            .parseStudentMetadata(data: data, filterGroups: filterGroups)[53921]

        XCTAssertEqual(metadata?.rarity, "1星")
        XCTAssertEqual(metadata?.combatRole, "坦克")
        XCTAssertEqual(metadata?.rangePosition, "Front（前排）")
        XCTAssertEqual(metadata?.weaponType, "SG")
        XCTAssertEqual(metadata?.terrainStreet, "C")
        XCTAssertEqual(metadata?.school, "格黑娜学园")
        XCTAssertNil(metadata?.club)
    }

    func testFilterSelectionMatchesCanonicalizedValues() {
        let groups = [
            BaCatalogFilterGroup(
                id: 68,
                title: "星级",
                kind: .rarity,
                options: [
                    BaCatalogFilterOption(id: 176, title: "三星", iconURL: nil),
                ]
            ),
            BaCatalogFilterGroup(
                id: 188,
                title: "武器种类",
                kind: .weaponType,
                options: [
                    BaCatalogFilterOption(id: 193, title: "手枪HG", iconURL: nil),
                ]
            ),
            BaCatalogFilterGroup(
                id: 218,
                title: "就读学校",
                kind: .school,
                options: [
                    BaCatalogFilterOption(id: 223, title: "格黑娜", iconURL: nil),
                ]
            ),
        ]
        let selection = BaCatalogFilterSelection(
            selectedOptionIDsByKind: [
                .rarity: [176],
                .weaponType: [193],
                .school: [223],
            ]
        )
        let matched = makeCatalogEntry(
            contentId: 1,
            metadata: BaGuideCatalogMetadata(
                rarity: "3星",
                weaponType: "HG",
                school: "格黑娜学园"
            )
        )
        let unknown = makeCatalogEntry(contentId: 2, metadata: nil)

        XCTAssertTrue(selection.matches(matched, groups: groups))
        XCTAssertFalse(selection.matches(unknown, groups: groups))
    }
}

private func makeCatalogEntry(
    contentId: Int64,
    metadata: BaGuideCatalogMetadata?
) -> BaGuideCatalogEntry {
    BaGuideCatalogEntry(
        entryId: Int(contentId),
        pid: BaCatalogCategory.students.gameKeePID,
        contentId: contentId,
        name: "Student \(contentId)",
        alias: "",
        aliasDisplay: "",
        iconURL: nil,
        type: 0,
        order: Int(contentId),
        createdAt: nil,
        releaseDate: nil,
        detailURL: nil,
        category: .students,
        metadata: metadata
    )
}
