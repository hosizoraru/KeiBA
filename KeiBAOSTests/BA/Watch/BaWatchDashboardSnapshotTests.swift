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
        XCTAssertEqual(decoded.dutyStudentAvatarURLString, "https://cdnimg.gamekee.com/student/alice.png")
        XCTAssertEqual(decoded.favoriteStudentCount, 3)
        XCTAssertEqual(decoded.currentAP(at: later), 13)
        XCTAssertEqual(decoded.currentCafeAP(at: base.addingTimeInterval(2 * 60 * 60)), 161)
        XCTAssertFalse(json.contains("favoriteCatalogEntries"))
        XCTAssertFalse(json.contains("serverProfiles"))
    }

    func testTimelineGlanceSnapshotKeepsActivityAndPoolHighlightsSmall() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let activitySyncAt = now.addingTimeInterval(-120)
        let poolSyncAt = now.addingTimeInterval(-60)

        let timeline = BaTimelineGlanceSnapshot(
            activities: [
                makeActivity(id: 1, title: "Later", beginAt: now.addingTimeInterval(-300), endAt: now.addingTimeInterval(3_600)),
                makeActivity(id: 2, title: "Soon", beginAt: now.addingTimeInterval(-120), endAt: now.addingTimeInterval(900)),
                makeActivity(id: 3, title: "Next", beginAt: now.addingTimeInterval(1_200), endAt: now.addingTimeInterval(4_200)),
                makeActivity(id: 4, title: "Done", beginAt: now.addingTimeInterval(-7_200), endAt: now.addingTimeInterval(-60)),
            ],
            pools: [
                makePool(id: 10, name: "FES", startAt: now.addingTimeInterval(600), endAt: now.addingTimeInterval(7_200)),
                makePool(id: 11, name: "Pickup", startAt: now.addingTimeInterval(1_200), endAt: now.addingTimeInterval(7_200)),
            ],
            activitySyncAt: activitySyncAt,
            poolSyncAt: poolSyncAt,
            activityIsShowingCache: true,
            poolIsShowingCache: false,
            now: now
        )

        XCTAssertEqual(timeline.activities.runningCount, 2)
        XCTAssertEqual(timeline.activities.upcomingCount, 1)
        XCTAssertEqual(timeline.activities.endedCount, 1)
        XCTAssertEqual(timeline.activities.featuredItem?.title, "Soon")
        XCTAssertEqual(timeline.activities.featuredItem?.status, .running)
        XCTAssertEqual(timeline.activities.featuredItem?.relatedItemCount, 1)
        XCTAssertEqual(timeline.activities.lastSyncAt, activitySyncAt)
        XCTAssertTrue(timeline.activities.isShowingCache)

        XCTAssertEqual(timeline.pools.runningCount, 0)
        XCTAssertEqual(timeline.pools.upcomingCount, 2)
        XCTAssertEqual(timeline.pools.featuredItem?.title, "FES")
        XCTAssertEqual(timeline.pools.featuredItem?.status, .upcoming)
        XCTAssertEqual(timeline.pools.featuredItem?.relatedItemCount, 1)
        XCTAssertEqual(timeline.pools.lastSyncAt, poolSyncAt)
        XCTAssertFalse(timeline.pools.isShowingCache)
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

private func makeActivity(id: Int, title: String, beginAt: Date, endAt: Date) -> BaActivityEntry {
    BaActivityEntry(
        id: id,
        title: title,
        kindId: 1,
        kindName: "活动",
        beginAt: beginAt,
        endAt: endAt,
        linkURL: nil,
        imageURL: nil
    )
}

private func makePool(id: Int, name: String, startAt: Date, endAt: Date) -> BaPoolEntry {
    BaPoolEntry(
        id: id,
        name: name,
        tagId: 1,
        tagName: "招募",
        alias: "",
        startAt: startAt,
        endAt: endAt,
        linkURL: nil,
        imageURL: nil,
        contentId: nil,
        studentGuideURL: nil
    )
}
