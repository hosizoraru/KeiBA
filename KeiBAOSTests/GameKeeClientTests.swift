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
