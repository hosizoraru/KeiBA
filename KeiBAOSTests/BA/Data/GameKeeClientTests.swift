//
//  GameKeeClientTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/15.
//

@testable import KeiBAOS
import Foundation
import XCTest

final class GameKeeClientTests: XCTestCase {
    override func tearDown() {
        GameKeeClientURLProtocol.reset()
        super.tearDown()
    }

    func testBAAPIRequestsUseAndroidFirefoxUserAgentFirst() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GameKeeClientURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = GameKeeClient(session: session, retryAttempts: 1)
        GameKeeClientURLProtocol.handler = { request in
            GameKeeClientURLProtocol.requests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data(#"{"code":0,"data":{}}"#.utf8))
        }

        _ = try await client.fetchJSONData(
            GameKeeRequest(
                pathOrURL: "/v1/content/detail/170295",
                refererPath: "/ba/tj/170295.html",
                extraHeaders: GameKeeClient.baHeaders
            )
        )

        let request = try XCTUnwrap(GameKeeClientURLProtocol.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), GameKeeClient.firefoxAndroidUserAgent)
        XCTAssertEqual(request.value(forHTTPHeaderField: "device-num"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "game-alias"), "ba")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://www.gamekee.com/ba/tj/170295.html")
    }

    func testMediaPlaybackHeadersMatchGameKeeVoicePlaybackRequirements() throws {
        let url = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/audio/title.ogg"))
        let headers = GameKeeClient.mediaPlaybackHeaders(
            for: url,
            referer: "https://www.gamekee.com/ba/tj/611753.html"
        )

        XCTAssertEqual(headers["Accept"], "*/*")
        XCTAssertEqual(headers["Accept-Language"], "zh-CN")
        XCTAssertEqual(headers["Referer"], "https://www.gamekee.com/ba/tj/611753.html")
        XCTAssertEqual(headers["Origin"], "https://www.gamekee.com")
        XCTAssertEqual(headers["User-Agent"], GameKeeClient.firefoxAndroidUserAgent)
        XCTAssertEqual(headers["device-num"], "1")
        XCTAssertEqual(headers["game-alias"], "ba")
    }

    func testAudioFetchRequestsUseGameKeeMediaHeaders() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GameKeeClientURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = GameKeeClient(session: session, retryAttempts: 1)
        GameKeeClientURLProtocol.handler = { request in
            GameKeeClientURLProtocol.requests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "audio/ogg"]
                )
            )
            return (response, Data([0x4F, 0x67, 0x67, 0x53, 0, 0, 0, 0]))
        }

        let url = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/audio/title.ogg"))
        _ = try await client.fetchAudioData(url: url, refererPath: "/ba/tj/611753.html")

        let request = try XCTUnwrap(GameKeeClientURLProtocol.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "*/*")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "zh-CN")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://www.gamekee.com/")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Origin"), "https://www.gamekee.com")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), GameKeeClient.firefoxAndroidUserAgent)
        XCTAssertEqual(request.value(forHTTPHeaderField: "device-num"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "game-alias"), "ba")
    }

    func testGenericMediaFetchRequestsUseGameKeeMediaHeaders() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GameKeeClientURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = GameKeeClient(session: session, retryAttempts: 1)
        GameKeeClientURLProtocol.handler = { request in
            GameKeeClientURLProtocol.requests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "video/mp4"]
                )
            )
            return (response, Data([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70]))
        }

        let url = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/video/memory.mp4"))
        _ = try await client.fetchMediaData(url: url, refererPath: "/ba/tj/611753.html")

        let request = try XCTUnwrap(GameKeeClientURLProtocol.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "*/*")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), "https://www.gamekee.com/")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Origin"), "https://www.gamekee.com")
        XCTAssertEqual(request.value(forHTTPHeaderField: "device-num"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "game-alias"), "ba")
    }

    func testStudentDetailFetchRecoversLegacyNPCEntryIDFromCatalog() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GameKeeClientURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = GameKeeClient(session: session, retryAttempts: 1)
        let repository = BaStudentGuideRepository(client: client)
        let staleEntry = BaGuideCatalogEntry(
            entryId: 174_603,
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            contentId: 174_603,
            name: "爱丽丝(冬装)",
            alias: "",
            aliasDisplay: "",
            iconURL: nil,
            type: 1,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/174603.html"),
            category: .npcSatellite
        )
        let cdnPath = "/wiki2.0/pro/829/content/647097.json"
        GameKeeClientURLProtocol.handler = { request in
            GameKeeClientURLProtocol.requests.append(request)
            guard let url = request.url,
                  let response = HTTPURLResponse(
                      url: url,
                      statusCode: 200,
                      httpVersion: nil,
                      headerFields: ["Content-Type": "application/json"]
                  )
            else {
                throw GameKeeError.invalidURL(request.url?.absoluteString ?? "")
            }
            if url.path == "/v1/entry/treesByPid" {
                return (response, Data(#"{"code":0,"data":[{"id":174603,"pid":107619,"content_id":647097,"name":"爱丽丝(冬装)","type":1}]}"#.utf8))
            }
            if url.path == "/v1/content/detail/174603" {
                return (response, Data(#"{"code":500,"msg":"record not found","data":null}"#.utf8))
            }
            if url.path == "/v1/content/detail/647097" {
                return (
                    response,
                    Data(
                        """
                        {
                          "code": 0,
                          "data": {
                            "id": 647097,
                            "entry_id": 174603,
                            "content_id": 647097,
                            "title": "爱丽丝（冬装）",
                            "summary": "卫星学生",
                            "content_json": "",
                            "content": "",
                            "content_cdn": "//api-cdn.gamekee.com\(cdnPath)"
                          }
                        }
                        """.utf8
                    )
                )
            }
            if url.host == "api-cdn.gamekee.com", url.path == cdnPath {
                return (
                    response,
                    Data(
                        #"""
                        {
                          "content": "[{\"key\":\"root\",\"type\":\"illustrated-book\",\"data\":[{\"key\":\"profile\",\"type\":\"character-profile\",\"data\":{\"name\":\"爱丽丝（冬装）\",\"desc\":\"卫星学生\",\"content\":[{\"key\":\"角色定位\",\"content\":\"冬装卫星\"}]}}]}]"
                        }
                        """#.utf8
                    )
                )
            }
            throw GameKeeError.invalidURL(url.absoluteString)
        }

        let snapshot = try await repository.fetchStudentDetail(entry: staleEntry)

        XCTAssertEqual(snapshot.value.contentId, 647_097)
        XCTAssertEqual(snapshot.value.title, "爱丽丝（冬装）")
        XCTAssertEqual(snapshot.value.sourceURL?.absoluteString, "https://www.gamekee.com/ba/tj/647097.html")
        XCTAssertEqual(snapshot.sourceErrors, [])
        let cdnRequest = try XCTUnwrap(GameKeeClientURLProtocol.requests.first { $0.url?.host == "api-cdn.gamekee.com" })
        XCTAssertEqual(cdnRequest.value(forHTTPHeaderField: "Referer"), "https://www.gamekee.com/")
    }

    func testStudentDetailResolverKeepsNPCEntryIDSeparateFromContentID() throws {
        let staleEntry = BaGuideCatalogEntry(
            entryId: 174_603,
            pid: BaCatalogCategory.npcSatellite.gameKeePID,
            contentId: 174_603,
            name: "爱丽丝(冬装)",
            alias: "",
            aliasDisplay: "",
            iconURL: nil,
            type: 1,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/174603.html"),
            category: .npcSatellite
        )
        let rows: [BaJSONObject] = [
            [
                "id": 174_603,
                "pid": BaCatalogCategory.npcSatellite.gameKeePID,
                "content_id": 647_097,
                "name": "爱丽丝(冬装)",
                "type": 1,
            ],
        ]

        XCTAssertEqual(BaStudentGuideRepository.resolvedContentID(for: staleEntry, catalogRows: rows), 647_097)
    }

    func testGuideMediaCacheHitsLocalFileAfterFirstDownload() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GameKeeClientURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = GameKeeClient(session: session, retryAttempts: 1)
        let cache = BaGuideMediaCache(client: client)
        GameKeeClientURLProtocol.handler = { request in
            GameKeeClientURLProtocol.requests.append(request)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "image/gif"]
                )
            )
            return (response, Data([0x47, 0x49, 0x46, 0x38]))
        }

        let url = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/\(UUID().uuidString).gif"))
        let first = try await cache.localURL(for: url)
        let second = try await cache.localURL(for: url)

        XCTAssertEqual(first, second)
        XCTAssertEqual(GameKeeClientURLProtocol.requests.count, 1)
        XCTAssertEqual(BaGuideMediaCache.cachedFileExtension(for: url), "gif")
    }
}

private final class GameKeeClientURLProtocol: URLProtocol {
    static var requests: [URLRequest] = []
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requests = []
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: GameKeeError.emptyBody)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
