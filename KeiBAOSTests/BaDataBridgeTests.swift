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
        XCTAssertTrue(client.imageRetryUserAgents[0].contains("Safari"))
        XCTAssertTrue(client.imageRetryUserAgents[1].contains("Firefox"))
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
        XCTAssertNil(
            BaVoiceLanguageResolver.playbackURL(for: jpOnlyEntry, headers: ["日配", "中配"], selectedHeader: "中配")
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

        XCTAssertTrue(BaVoicePlaybackController.supportsNativePlayback(mp3URL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(mp3URL))
        XCTAssertFalse(BaVoicePlaybackController.supportsNativePlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsOggPlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(oggURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsOggPlayback(opusURL))
        XCTAssertTrue(BaVoicePlaybackController.supportsPlayback(opusURL))
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
