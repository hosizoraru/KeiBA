//
//  BaActivityPoolDataBridgeTests.swift
//  KeiBAOSTests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBAOS
import AVFAudio
import Foundation
import XCTest

final class BaActivityPoolDataBridgeTests: XCTestCase {
    func testCatalogParserKeepsNPCContentIDSeparateFromEntryID() throws {
        let json = """
        {
          "code": 0,
          "data": [
            {
              "id": 174603,
              "pid": 107619,
              "content_id": 647097,
              "name": "爱丽丝(冬装)",
              "type": 1,
              "icon": "//cdnimg-v2.gamekee.com/wiki2.0/images/w_200/h_200/829/alice.png"
            }
          ]
        }
        """
        let repository = BaGuideCatalogRepository(client: GameKeeClient())
        let entries = try repository.parseEntries(
            data: Data(json.utf8),
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            category: .npcSatellite
        )

        XCTAssertEqual(entries.first?.entryId, 174_603)
        XCTAssertEqual(entries.first?.contentId, 647_097)
        XCTAssertEqual(entries.first?.detailURL?.absoluteString, "https://www.gamekee.com/ba/tj/647097.html")
    }

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
                makeDataBridgeCatalogEntry(contentId: 67_658, name: "优香"),
                makeDataBridgeCatalogEntry(contentId: 170_295, name: "优香(体操服)"),
            ]
        )
        let sportswearPool = makeDataBridgePoolEntry(
            id: 2388,
            name: "优香(体操服)",
            linkURL: try XCTUnwrap(URL(string: "https://www.gamekee.com/ba/701261.html"))
        )
        let basePool = makeDataBridgePoolEntry(
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
        let pool = makeDataBridgePoolEntry(
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
        let pool = makeDataBridgePoolEntry(
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
            entry: makeDataBridgeCatalogEntry()
        )

        XCTAssertEqual(parsed.summary, "GameKee summary")
    }
}
