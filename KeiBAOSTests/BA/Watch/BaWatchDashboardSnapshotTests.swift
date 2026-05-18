//
//  BaWatchDashboardSnapshotTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/18.
//

@testable import KeiBAOS
import XCTest

final class BaWatchDashboardSnapshotTests: XCTestCase {
    func testDashboardSnapshotKeepsWatchPayloadSmallAndLiveComputable() throws {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.selectedServer = .cn
        envelope.globalSettings.favoriteContentIDs = [1, 2, 3]
        envelope.globalSettings.dutyStudent = BaDutyStudent(
            contentId: 1,
            name: "爱丽丝",
            avatarURL: URL(string: "https://cdnimg.gamekee.com/student/alice.png")
        )

        var profile = envelope.profile(for: .cn)
        profile.nickname = "Voyager"
        profile.friendCode = "ba26test"
        profile.apCurrent = 10
        profile.apLimit = 20
        profile.apRegenBaseAt = base
        profile.cafeLevel = 10
        profile.cafeApCurrent = 100
        profile.cafeStorageBaseAt = base
        envelope.setProfile(profile, for: .cn)

        let snapshot = BaWatchDashboardSnapshot(
            userData: envelope.userData(updatedAt: base),
            now: base.addingTimeInterval(60)
        )
        let later = base.addingTimeInterval(BaWatchTimeMath.apRegenInterval * 3)
        let data = try BaWatchDashboardSnapshotCoding.encode(snapshot)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        let decoded = try BaWatchDashboardSnapshotCoding.decode(data)

        XCTAssertEqual(decoded.teacherName, "Voyager")
        XCTAssertEqual(decoded.friendCode, "BA26TEST")
        XCTAssertEqual(decoded.dutyStudentName, "爱丽丝")
        XCTAssertEqual(decoded.favoriteStudentCount, 3)
        XCTAssertEqual(decoded.currentAP(at: later), 13)
        XCTAssertEqual(decoded.currentCafeAP(at: base.addingTimeInterval(2 * 60 * 60)), 161)
        XCTAssertFalse(json.contains("favoriteCatalogEntries"))
        XCTAssertFalse(json.contains("serverProfiles"))
    }

    func testWatchTimeMathReturnsFullDatesForResources() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)

        let apFullAt = BaWatchTimeMath.apFullAt(
            baseAP: 18,
            apLimit: 20,
            apRegenBaseAt: base,
            now: base
        )

        let cafeFullAt = BaWatchTimeMath.cafeFullAt(
            baseAP: 100,
            cafeLevel: 10,
            cafeStorageBaseAt: base,
            now: base
        )

        XCTAssertEqual(apFullAt, base.addingTimeInterval(2 * BaWatchTimeMath.apRegenInterval))
        XCTAssertNotNil(cafeFullAt)
        XCTAssertLessThan(cafeFullAt ?? .distantFuture, base.addingTimeInterval(24 * 60 * 60))
    }
}
