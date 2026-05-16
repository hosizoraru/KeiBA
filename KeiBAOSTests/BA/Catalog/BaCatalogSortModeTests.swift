//
//  BaCatalogSortModeTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/16.
//

@testable import KeiBAOS
import Foundation
import XCTest

final class BaCatalogSortModeTests: XCTestCase {
    func testDefaultOrderSortsByCatalogOrderAndPinsFavorites() {
        let entries = [
            makeCatalogEntry(contentId: 1, order: 30),
            makeCatalogEntry(contentId: 2, order: 10),
            makeCatalogEntry(contentId: 3, order: 20),
        ]

        let sorted = entries.sorted(using: .defaultOrder, favoriteContentIDs: [3])

        XCTAssertEqual(sorted.map(\.contentId), [3, 2, 1])
    }

    func testReleaseDateDescendingUsesCreatedAtFallbackAndLeavesUnknownLast() {
        let entries = [
            makeCatalogEntry(contentId: 1, order: 30, releaseDate: nil, createdAt: nil),
            makeCatalogEntry(contentId: 2, order: 10, releaseDate: date(day: 1), createdAt: nil),
            makeCatalogEntry(contentId: 3, order: 20, releaseDate: nil, createdAt: date(day: 3)),
        ]

        let sorted = entries.sorted(using: .releaseDateDescending, favoriteContentIDs: [])

        XCTAssertEqual(sorted.map(\.contentId), [3, 2, 1])
    }

    func testReleaseDateAscendingUsesCreatedAtFallbackAndLeavesUnknownLast() {
        let entries = [
            makeCatalogEntry(contentId: 1, order: 30, releaseDate: nil, createdAt: nil),
            makeCatalogEntry(contentId: 2, order: 10, releaseDate: date(day: 2), createdAt: nil),
            makeCatalogEntry(contentId: 3, order: 20, releaseDate: nil, createdAt: date(day: 1)),
        ]

        let sorted = entries.sorted(using: .releaseDateAscending, favoriteContentIDs: [])

        XCTAssertEqual(sorted.map(\.contentId), [3, 2, 1])
    }
}

private func makeCatalogEntry(
    contentId: Int64,
    order: Int,
    releaseDate: Date? = nil,
    createdAt: Date? = nil
) -> BaGuideCatalogEntry {
    BaGuideCatalogEntry(
        entryId: Int(contentId),
        pid: 49443,
        contentId: contentId,
        name: "Student \(contentId)",
        alias: "",
        aliasDisplay: "",
        iconURL: nil,
        type: 0,
        order: order,
        createdAt: createdAt,
        releaseDate: releaseDate,
        detailURL: nil,
        category: .students
    )
}

private func date(day: Int) -> Date {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = 2026
    components.month = 1
    components.day = day
    return components.date!
}
