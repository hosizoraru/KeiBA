//
//  BaUserDataSyncTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

@testable import KeiBAOS
import XCTest

final class BaUserDataSyncTests: XCTestCase {
    func testUserDataRoundTripPreservesSyncableState() throws {
        let sourceDefaults = try makeIsolatedDefaults()
        let destinationDefaults = try makeIsolatedDefaults()
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.selectedServer = .global
        envelope.globalSettings.identityIndependentByServer = true
        envelope.globalSettings.showEndedActivities = false
        envelope.globalSettings.mediaAutoplayEnabled = true
        envelope.globalSettings.appLanguage = .japanese
        envelope.globalSettings.appAppearance = .dark
        envelope.globalSettings.favoriteContentIDs = [647_097, 702_789]
        envelope.globalSettings.favoriteCatalogEntries = [
            makeCatalogEntry(contentId: 647_097, name: "爱丽丝（冬装）", category: .npcSatellite),
            makeCatalogEntry(contentId: 702_789, name: "新角色", category: .students),
        ]
        envelope.globalSettings.dutyStudent = BaDutyStudent(
            contentId: 647_097,
            name: "爱丽丝（冬装）",
            avatarURL: URL(string: "https://cdnimg.gamekee.com/student/alice.png")
        )

        var profile = envelope.profile(for: .global)
        profile.nickname = "Global Sensei"
        profile.friendCode = "gl000001"
        profile.apCurrent = 128
        profile.cafeApCurrent = 320
        profile.apNotifyThreshold = 200
        envelope.setProfile(profile, for: .global)

        let sourceStore = BaSettingsStore(defaults: sourceDefaults)
        sourceStore.saveEnvelope(envelope)
        let data = try sourceStore.exportUserData(updatedAt: base.addingTimeInterval(60))

        let imported = try BaSettingsStore(defaults: destinationDefaults).importUserData(from: data)
        let loaded = BaSettingsStore(defaults: destinationDefaults).loadEnvelope()
        let loadedUserData = BaSettingsStore(defaults: destinationDefaults).loadUserData()

        XCTAssertEqual(imported.updatedAt, base.addingTimeInterval(60))
        XCTAssertEqual(loadedUserData.updatedAt, imported.updatedAt)
        XCTAssertEqual(loaded.selectedServer, .global)
        XCTAssertTrue(loaded.globalSettings.identityIndependentByServer)
        XCTAssertFalse(loaded.globalSettings.showEndedActivities)
        XCTAssertTrue(loaded.globalSettings.mediaAutoplayEnabled)
        XCTAssertEqual(loaded.globalSettings.appLanguage, .japanese)
        XCTAssertEqual(loaded.globalSettings.appAppearance, .dark)
        XCTAssertEqual(loaded.globalSettings.favoriteContentIDs, [647_097, 702_789])
        XCTAssertEqual(loaded.globalSettings.favoriteCatalogEntries.map(\.contentId), [647_097, 702_789])
        XCTAssertEqual(loaded.globalSettings.dutyStudent?.contentId, 647_097)
        XCTAssertEqual(loaded.profile(for: .global).nickname, "Global Sensei")
        XCTAssertEqual(loaded.profile(for: .global).friendCode, "GL000001")
        XCTAssertEqual(loaded.profile(for: .global).apCurrent, 128)
        XCTAssertEqual(loaded.profile(for: .global).cafeApCurrent, 320)
        XCTAssertEqual(loaded.profile(for: .global).apNotifyThreshold, 200)
    }

    func testWatchSnapshotKeepsCompactCurrentServerPayload() throws {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        var envelope = BaSettingsEnvelope.defaults(now: base)
        envelope.selectedServer = .jp
        envelope.globalSettings.favoriteContentIDs = [702_789, 647_097]
        envelope.globalSettings.favoriteCatalogEntries = [
            makeCatalogEntry(contentId: 647_097, name: "爱丽丝（冬装）", category: .npcSatellite),
            makeCatalogEntry(contentId: 702_789, name: "新角色", category: .students),
        ]
        envelope.globalSettings.dutyStudent = BaDutyStudent(
            contentId: 702_789,
            name: "新角色",
            avatarURL: URL(string: "https://cdnimg.gamekee.com/student/new.png")
        )
        var jpProfile = envelope.profile(for: .jp)
        jpProfile.nickname = "JP Sensei"
        jpProfile.friendCode = "jp000001"
        jpProfile.apCurrent = 77
        jpProfile.cafeLevel = 8
        envelope.setProfile(jpProfile, for: .jp)

        let snapshot = envelope.userData(updatedAt: base).watchSnapshot(generatedAt: base.addingTimeInterval(30))
        let data = try JSONEncoder.ba.encode(snapshot)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertEqual(snapshot.generatedAt, base.addingTimeInterval(30))
        XCTAssertEqual(snapshot.selectedServer, .jp)
        XCTAssertEqual(snapshot.nickname, "JP Sensei")
        XCTAssertEqual(snapshot.friendCode, "JP000001")
        XCTAssertEqual(snapshot.profile.apCurrent, 77)
        XCTAssertEqual(snapshot.profile.cafeLevel, 8)
        XCTAssertEqual(snapshot.preferences.favoriteContentIDs, [647_097, 702_789])
        XCTAssertEqual(snapshot.preferences.favoriteCount, 2)
        XCTAssertEqual(snapshot.dutyStudent?.contentId, 702_789)
        XCTAssertFalse(json.contains("favoriteCatalogEntries"))
    }

    @MainActor
    func testApplyingUserDataResetsServerScopedTimelineStateAndKeepsCatalogCache() throws {
        let defaults = try makeIsolatedDefaults()
        let model = makeAppModel(defaults: defaults)
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let activity = BaActivityEntry(
            id: 1,
            title: "Event",
            kindId: 1,
            kindName: "Event",
            beginAt: base,
            endAt: base.addingTimeInterval(3_600),
            linkURL: nil,
            imageURL: nil
        )
        let pool = BaPoolEntry(
            id: 1,
            name: "Pickup",
            tagId: 1,
            tagName: "Pool",
            alias: "",
            startAt: base,
            endAt: base.addingTimeInterval(3_600),
            linkURL: nil,
            imageURL: nil,
            contentId: nil,
            studentGuideURL: nil
        )
        let catalog = BaGuideCatalogBundle(
            entries: [makeCatalogEntry(contentId: 702_789, name: "新角色", category: .students)],
            syncedAt: base
        )
        model.activityState = BaLoadableState(value: [activity], lastSyncAt: base)
        model.poolState = BaLoadableState(value: [pool], lastSyncAt: base)
        model.catalogState = BaLoadableState(value: catalog, lastSyncAt: base)

        var envelope = model.envelope
        envelope.selectedServer = .global
        var profile = envelope.profile(for: .global)
        profile.nickname = "Synced Sensei"
        profile.friendCode = "sync0001"
        envelope.setProfile(profile, for: .global)

        model.applyUserData(envelope.userData(updatedAt: base))

        XCTAssertEqual(model.settings.server, .global)
        XCTAssertEqual(model.settings.nickname, "Synced Sensei")
        XCTAssertEqual(model.settings.friendCode, "SYNC0001")
        XCTAssertNil(model.activityState.value)
        XCTAssertNil(model.poolState.value)
        XCTAssertEqual(model.catalogState.value?.entries.first?.contentId, 702_789)
        XCTAssertEqual(BaSettingsStore(defaults: defaults).loadEnvelope().selectedServer, .global)
    }

    func testUserDataMergePolicyPrefersNewerPayload() {
        let olderDate = Date(timeIntervalSince1970: 1_800_000_000)
        let newerDate = olderDate.addingTimeInterval(60)
        let local = BaSettingsEnvelope.defaults(now: olderDate).userData(updatedAt: olderDate)
        var remoteEnvelope = BaSettingsEnvelope.defaults(now: olderDate)
        remoteEnvelope.selectedServer = .global
        let remote = remoteEnvelope.userData(updatedAt: newerDate)

        XCTAssertEqual(BaUserDataMergePolicy.decision(local: local, remote: nil), .uploadLocal)
        XCTAssertEqual(BaUserDataMergePolicy.decision(local: local, remote: remote), .applyRemote)
        XCTAssertEqual(BaUserDataMergePolicy.decision(local: remote, remote: local), .uploadLocal)
        XCTAssertEqual(BaUserDataMergePolicy.decision(local: local, remote: local), .keepLocal)
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "KeiBAOSTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @MainActor
    private func makeAppModel(defaults: UserDefaults) -> BaAppModel {
        let client = GameKeeClient()
        let cacheStore = BaCacheStore()
        return BaAppModel(
            settingsStore: BaSettingsStore(defaults: defaults),
            cacheStore: cacheStore,
            imageCache: BaImageCache(client: client),
            activityPoolRepository: BaActivityPoolRepository(client: client),
            catalogRepository: BaGuideCatalogRepository(client: client),
            catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator(
                cacheStore: cacheStore,
                studentRepository: BaStudentGuideRepository(client: client)
            ),
            studentRepository: BaStudentGuideRepository(client: client),
            officeRepository: BaOfficeRepository()
        )
    }

    private func makeCatalogEntry(
        contentId: Int64,
        name: String,
        category: BaCatalogCategory
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: category.gameKeePID,
            contentId: contentId,
            name: name,
            alias: "",
            aliasDisplay: "",
            iconURL: URL(string: "https://cdnimg.gamekee.com/student/\(contentId).png"),
            type: 1,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
            category: category
        )
    }
}
