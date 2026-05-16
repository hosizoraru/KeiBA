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
        XCTAssertNil(compact.readableContentMaxWidth)

        let regular = BaAdaptiveMetrics(containerWidth: 760)
        XCTAssertEqual(regular.widthClass, .regular)
        XCTAssertEqual(regular.timelineColumnCount, 1)
        XCTAssertEqual(regular.overviewInnerGridColumns.count, 3)
        XCTAssertEqual(regular.readableContentMaxWidth, 760)

        let expanded = BaAdaptiveMetrics(containerWidth: 1_120)
        XCTAssertEqual(expanded.widthClass, .expanded)
        XCTAssertEqual(expanded.timelineColumnCount, 2)
        XCTAssertEqual(expanded.overviewColumnCount, 2)
        XCTAssertEqual(expanded.dashboardContentMaxWidth, 1_180)
    }

    func testChunkingKeepsTimelineRowsStableForAdaptiveColumns() {
        XCTAssertEqual([1, 2, 3, 4, 5].baChunked(into: 2), [[1, 2], [3, 4], [5]])
        XCTAssertEqual([1, 2, 3].baChunked(into: 1), [[1], [2], [3]])
    }
}
