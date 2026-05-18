//
//  BaDashboardWidgetSnapshotTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/19.
//

@testable import KeiBAOS
import XCTest

final class BaDashboardWidgetSnapshotTests: XCTestCase {
    override func tearDown() {
        BaDashboardSnapshotSharing.clear()
        super.tearDown()
    }

    func testWidgetSnapshotSharingRoundTripsDashboardSnapshot() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = BaWatchDashboardSnapshot(
            sourceUpdatedAt: now,
            generatedAt: now,
            officeName: "沙勒办公室",
            officeShortName: "沙勒",
            serverName: "国服",
            teacherName: "Voyager",
            friendCode: "BA26TEST",
            apBaseValue: 120,
            apLimit: 240,
            apRegenBaseAt: now,
            apNotificationsEnabled: true,
            apNotifyThreshold: 220,
            cafeLevel: 10,
            cafeAPBaseValue: 360,
            cafeStorageBaseAt: now,
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 600,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: true,
            favoriteStudentCount: 8
        )

        BaDashboardSnapshotSharing.clear()
        BaDashboardSnapshotSharing.save(snapshot)

        let loaded = BaDashboardSnapshotSharing.loadSnapshot()
        XCTAssertEqual(loaded?.officeShortName, "沙勒")
        XCTAssertEqual(loaded?.teacherName, "Voyager")
        XCTAssertEqual(loaded?.currentAP(at: now.addingTimeInterval(BaWatchTimeMath.apRegenInterval * 2)), 122)
        XCTAssertEqual(loaded?.currentCafeAP(at: now.addingTimeInterval(BaWatchTimeMath.cafeHourlyInterval)), 390)
    }
}
