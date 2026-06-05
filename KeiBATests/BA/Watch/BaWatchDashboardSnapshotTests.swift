//
//  BaWatchDashboardSnapshotTests.swift
//  KeiBATests
//
//  Created by Codex on 2026/05/18.
//

@testable import KeiBA
import XCTest

final class BaWatchDashboardSnapshotTests: XCTestCase {
    func testDashboardSnapshotKeepsWatchPayloadSmallAndLiveComputable() throws {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.selectedServer = .cn
        envelope.globalSettings.appLanguage = .simplifiedChinese
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

        XCTAssertEqual(decoded.officeName, "沙勒办公室")
        XCTAssertEqual(decoded.officeShortName, "沙勒")
        XCTAssertEqual(decoded.teacherName, "Voyager")
        XCTAssertEqual(decoded.friendCode, "BA26TEST")
        XCTAssertEqual(decoded.dutyStudentName, "爱丽丝")
        XCTAssertEqual(decoded.dutyStudentAvatarURLString, "https://cdnimg.gamekee.com/student/alice.png")
        XCTAssertNil(decoded.dutyStudentAvatarImageData)
        XCTAssertEqual(decoded.favoriteStudentCount, 3)
        XCTAssertEqual(decoded.currentAP(at: later), 13)
        XCTAssertEqual(decoded.currentCafeAP(at: base.addingTimeInterval(2 * 60 * 60)), 161)
        XCTAssertFalse(json.contains("favoriteCatalogEntries"))
        XCTAssertFalse(json.contains("serverProfiles"))
    }

    func testDashboardSnapshotCanCarrySmallDutyAvatarThumbnail() async throws {
        let sourcePNG = try XCTUnwrap(Data(base64Encoded: Self.onePixelPNGBase64))
        let encodedAvatarData = await BaWatchAvatarThumbnailEncoder.encodedThumbnailData(from: sourcePNG)
        let avatarData = try XCTUnwrap(encodedAvatarData)

        let snapshot = BaWatchDashboardSnapshot(
            sourceUpdatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            officeName: "夏莱办公室",
            serverName: "日服",
            teacherName: "Kei",
            friendCode: "ARISUKEI",
            dutyStudentName: "夏莱",
            dutyStudentAvatarURLString: "https://cdnimg.gamekee.com/student/schale.png",
            dutyStudentAvatarImageData: avatarData,
            apBaseValue: 67,
            apLimit: 240,
            apRegenBaseAt: Date(timeIntervalSince1970: 1_800_000_000),
            apNotificationsEnabled: true,
            apNotifyThreshold: 120,
            cafeLevel: 10,
            cafeAPBaseValue: 120,
            cafeStorageBaseAt: Date(timeIntervalSince1970: 1_800_000_000),
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 120,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: true,
            favoriteStudentCount: 4
        )

        let encoded = try BaWatchDashboardSnapshotCoding.encode(snapshot)
        let decoded = try BaWatchDashboardSnapshotCoding.decode(encoded)

        XCTAssertLessThanOrEqual(avatarData.count, BaWatchAvatarThumbnailEncoder.maxPayloadBytes)
        XCTAssertEqual(decoded.officeName, "夏莱办公室")
        XCTAssertEqual(decoded.officeShortName, "夏莱")
        XCTAssertEqual(decoded.dutyStudentAvatarImageData, avatarData)
    }

    func testWatchSnapshotUsesGlobalOfficeTerminologyForSimplifiedChinese() throws {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.selectedServer = .global
        envelope.globalSettings.appLanguage = .simplifiedChinese

        let snapshot = BaWatchDashboardSnapshot(
            userData: envelope.userData(updatedAt: base),
            now: base
        )

        XCTAssertEqual(snapshot.officeName, "夏萊行政室")
        XCTAssertEqual(snapshot.officeShortName, "夏萊")
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

    func testWatchCompactDurationFormatterKeepsTimeLabelsBrief() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)

        XCTAssertEqual(
            BaWatchCompactDurationFormatter.text(until: base.addingTimeInterval(30), from: base),
            "1m"
        )
        XCTAssertEqual(
            BaWatchCompactDurationFormatter.text(until: base.addingTimeInterval(17 * 60), from: base),
            "17m"
        )
        XCTAssertEqual(
            BaWatchCompactDurationFormatter.text(until: base.addingTimeInterval(2 * 60 * 60 + 5 * 60), from: base),
            "2h 5m"
        )
        XCTAssertEqual(
            BaWatchCompactDurationFormatter.text(until: base.addingTimeInterval(2 * 24 * 60 * 60 + 3 * 60 * 60), from: base),
            "2d 3h"
        )
        XCTAssertNil(BaWatchCompactDurationFormatter.text(until: base, from: base))
        XCTAssertNil(BaWatchCompactDurationFormatter.text(until: nil, from: base))
    }

    func testDashboardGlanceSummaryKeepsWatchTopLevelContentLiveAndCompact() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let now = base.addingTimeInterval(BaWatchTimeMath.apRegenInterval * 2)
        let snapshot = BaWatchDashboardSnapshot(
            sourceUpdatedAt: base,
            generatedAt: base,
            officeName: "シャーレオフィス",
            serverName: "JP",
            teacherName: "Kei",
            friendCode: "ARISUKEI",
            apBaseValue: 18,
            apLimit: 24,
            apRegenBaseAt: base,
            apNotificationsEnabled: true,
            apNotifyThreshold: 20,
            cafeLevel: 10,
            cafeAPBaseValue: 100,
            cafeStorageBaseAt: base,
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 600,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: true,
            favoriteStudentCount: 5,
            timeline: BaTimelineGlanceSnapshot(
                generatedAt: base,
                activities: BaTimelineGlanceSection(
                    runningCount: 2,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "総決算",
                        status: .running,
                        startAt: base.addingTimeInterval(-3_600),
                        endAt: base.addingTimeInterval(3_600)
                    )
                ),
                pools: BaTimelineGlanceSection(
                    runningCount: 0,
                    upcomingCount: 2,
                    featuredItem: BaTimelineGlanceItem(
                        title: "ピックアップ募集",
                        status: .upcoming,
                        startAt: base.addingTimeInterval(7_200),
                        endAt: base.addingTimeInterval(86_400)
                    )
                )
            )
        )

        let summary = snapshot.glanceSummary(at: now)

        XCTAssertEqual(summary.currentAP, 20)
        XCTAssertEqual(summary.apLimit, 24)
        XCTAssertEqual(summary.apFullAt, base.addingTimeInterval(BaWatchTimeMath.apRegenInterval * 6))
        XCTAssertEqual(summary.currentCafeAP, 100)
        XCTAssertEqual(summary.cafeAPCapacity, BaWatchTimeMath.cafeDailyCapacity(level: 10))
        XCTAssertEqual(summary.cafeAPFullAt, base.addingTimeInterval(21 * 60 * 60))
        XCTAssertEqual(summary.activityRunningCount, 2)
        XCTAssertEqual(summary.activityUpcomingCount, 1)
        XCTAssertEqual(summary.featuredActivityTitle, "総決算")
        XCTAssertEqual(summary.poolRunningCount, 0)
        XCTAssertEqual(summary.poolUpcomingCount, 2)
        XCTAssertEqual(summary.featuredPoolTitle, "ピックアップ募集")
    }

    private static let onePixelPNGBase64 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII="
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
