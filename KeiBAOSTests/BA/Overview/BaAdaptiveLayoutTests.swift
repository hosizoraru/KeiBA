//
//  BaAdaptiveLayoutTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/16.
//

@testable import KeiBAOS
import XCTest

final class BaAdaptiveLayoutTests: XCTestCase {
    func testAdaptiveMetricsMatchStageManagerWidthBands() {
        let compact = BaAdaptiveMetrics(containerWidth: 520)
        XCTAssertEqual(compact.widthClass, .compact)
        XCTAssertEqual(compact.timelineColumnCount, 1)
        XCTAssertEqual(compact.overviewColumnCount, 1)
        XCTAssertEqual(compact.overviewSummaryGridColumns.count, 1)
        XCTAssertEqual(compact.poolCardThumbnailSize, 88)
        XCTAssertNil(compact.readableContentMaxWidth)

        let regular = BaAdaptiveMetrics(containerWidth: 760)
        XCTAssertEqual(regular.widthClass, .regular)
        XCTAssertEqual(regular.timelineColumnCount, 2)
        XCTAssertEqual(regular.overviewColumnCount, 2)
        XCTAssertEqual(regular.overviewInnerGridColumns.count, 2)
        XCTAssertEqual(regular.overviewSummaryGridColumns.count, 2)
        XCTAssertEqual(regular.readableContentMaxWidth, 760)

        let portraitIPad = BaAdaptiveMetrics(containerWidth: 834)
        XCTAssertEqual(portraitIPad.widthClass, .regular)
        XCTAssertEqual(portraitIPad.overviewColumnCount, 2)
        XCTAssertEqual(portraitIPad.overviewInnerGridColumns.count, 2)

        let expanded = BaAdaptiveMetrics(containerWidth: 1_120)
        XCTAssertEqual(expanded.widthClass, .expanded)
        XCTAssertEqual(expanded.timelineColumnCount, 2)
        XCTAssertEqual(expanded.overviewColumnCount, 2)
        XCTAssertEqual(expanded.dashboardContentMaxWidth, 1_180)
    }

    func testTimelineColumnsMatchIPadWindowDensity() {
        let narrowStageManagerWindow = BaAdaptiveMetrics(containerWidth: 620)
        XCTAssertEqual(narrowStageManagerWindow.timelineColumnCount, 1)

        let portraitIPadWindow = BaAdaptiveMetrics(containerWidth: 680)
        XCTAssertEqual(portraitIPadWindow.timelineColumnCount, 2)
        XCTAssertEqual(portraitIPadWindow.timelineCardImageHeight, 161)
        XCTAssertEqual(portraitIPadWindow.poolCardThumbnailSize, 87)

        let fullWidthIPadWindow = BaAdaptiveMetrics(containerWidth: 834)
        XCTAssertEqual(fullWidthIPadWindow.timelineColumnCount, 2)
        XCTAssertEqual(fullWidthIPadWindow.timelineCardImageHeight, 182)
        XCTAssertEqual(fullWidthIPadWindow.poolCardThumbnailSize, 92)

        let topRailIPadWindow = BaAdaptiveMetrics(containerWidth: 1_024)
        XCTAssertEqual(topRailIPadWindow.timelineColumnCount, 2)
        XCTAssertEqual(topRailIPadWindow.timelineCardImageHeight, 248)
        XCTAssertEqual(topRailIPadWindow.timelineCardHorizontalPadding, 16)
        XCTAssertEqual(topRailIPadWindow.timelineCardVerticalPadding, 15)

        let landscapeIPadWindow = BaAdaptiveMetrics(containerWidth: 1_120)
        XCTAssertEqual(landscapeIPadWindow.timelineColumnCount, 2)
        XCTAssertEqual(landscapeIPadWindow.timelineCardImageHeight, 270)
    }

    func testOverviewIdentityLayoutKeepsFriendCodeReadableOnNarrowCards() {
        let iPhone15Pro = BaAdaptiveMetrics(containerWidth: 393)
        XCTAssertTrue(iPhone15Pro.usesCompactOverviewIdentityLayout)
        XCTAssertEqual(iPhone15Pro.poolCardThumbnailSize, 87)

        let proMaxWidth = BaAdaptiveMetrics(containerWidth: 430)
        XCTAssertTrue(proMaxWidth.usesCompactOverviewIdentityLayout)
        XCTAssertEqual(proMaxWidth.poolCardThumbnailSize, 88)

        let compactWidth = BaAdaptiveMetrics(containerWidth: 375)
        XCTAssertEqual(compactWidth.poolCardThumbnailSize, 82)

        let portraitIPadTwoColumn = BaAdaptiveMetrics(containerWidth: 834)
        XCTAssertTrue(portraitIPadTwoColumn.usesCompactOverviewIdentityLayout)

        let landscapeIPadTwoColumn = BaAdaptiveMetrics(containerWidth: 1_024)
        XCTAssertFalse(landscapeIPadTwoColumn.usesCompactOverviewIdentityLayout)

        let macWindow = BaAdaptiveMetrics(containerWidth: 1_280)
        XCTAssertFalse(macWindow.usesCompactOverviewIdentityLayout)
    }

    func testChunkingKeepsTimelineRowsStableForAdaptiveColumns() {
        XCTAssertEqual([1, 2, 3, 4, 5].baChunked(into: 2), [[1, 2], [3, 4], [5]])
        XCTAssertEqual([1, 2, 3].baChunked(into: 1), [[1], [2], [3]])
    }
}
