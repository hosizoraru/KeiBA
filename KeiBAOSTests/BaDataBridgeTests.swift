//
//  BaDataBridgeTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/14.
//

import XCTest
@testable import KeiBAOS

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
        XCTAssertEqual(entries[0].contentId, 609145)
        XCTAssertEqual(entries[0].imageURL?.absoluteString, "https://cdnimg.gamekee.com/pool.png")
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
        XCTAssertEqual(entries[0].contentId, 161248)
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
}
