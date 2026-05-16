//
//  BaDataBridgeTestSupport.swift
//  KeiBAOSTests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBAOS
import Foundation
import XCTest

func makeDataBridgeCatalogEntry(
    contentId: Int64 = 609_145,
    name: String = "Test",
    alias: String = ""
) -> BaGuideCatalogEntry {
    BaGuideCatalogEntry(
        entryId: Int(contentId),
        pid: 49443,
        contentId: contentId,
        name: name,
        alias: alias,
        aliasDisplay: alias,
        iconURL: nil,
        type: 0,
        order: 0,
        createdAt: nil,
        releaseDate: nil,
        detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
        category: .students
    )
}

func makeDataBridgePoolEntry(
    id: Int,
    name: String,
    linkURL: URL,
    studentGuideURL: URL? = nil
) -> BaPoolEntry {
    BaPoolEntry(
        id: id,
        name: name,
        tagId: 6,
        tagName: "",
        alias: "",
        startAt: Date(timeIntervalSince1970: 1_699_990_000),
        endAt: Date(timeIntervalSince1970: 1_700_010_000),
        linkURL: linkURL,
        imageURL: nil,
        contentId: nil,
        studentGuideURL: studentGuideURL
    )
}

func fetchHinaDressTitleOggFixtureDataForTesting() async throws -> Data {
    let url = try XCTUnwrap(URL(string: "https://cdnimg-v2.gamekee.com/wiki2.0/images/w_0/h_0/829/43637/2025/4/26/648025.ogg"))
    var request = URLRequest(url: url)
    request.setValue("https://www.gamekee.com/", forHTTPHeaderField: "Referer")
    request.setValue("bytes=0-", forHTTPHeaderField: "Range")
    do {
        let result = try await URLSession.shared.data(for: request)
        let statusCode = (result.1 as? HTTPURLResponse)?.statusCode ?? 0
        guard (200 ..< 300).contains(statusCode) else {
            throw XCTSkip("GameKee title OGG fixture unavailable: HTTP \(statusCode)")
        }
        return result.0
    } catch let error as XCTSkip {
        throw error
    } catch {
        throw XCTSkip("GameKee title OGG fixture unavailable: \(error.localizedDescription)")
    }
}

extension Array {
    var single: Element? {
        count == 1 ? first : nil
    }
}
