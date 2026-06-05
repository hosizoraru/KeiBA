//
//  BaAppModel.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation
import Observation

@Observable
@MainActor
final class BaAppModel {
    var envelope: BaSettingsEnvelope
    var settings: BaAppSettings
    var officeSnapshot: BaOfficeSnapshot
    var activityState = BaLoadableState<[BaActivityEntry]>()
    var poolState = BaLoadableState<[BaPoolEntry]>()
    var catalogState = BaLoadableState<BaGuideCatalogBundle>()
    var studentDetailStates: [Int64: BaLoadableState<BaStudentGuideInfo>] = [:]
    var watchSyncState = BaWatchSyncState.unavailable

    let settingsStore: BaSettingsStore
    let cacheStore: BaCacheStore
    let imageCache: BaImageCache
    let activityPoolRepository: BaActivityPoolRepository
    let catalogRepository: BaGuideCatalogRepository
    let catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator
    let studentRepository: BaStudentGuideRepository
    let officeRepository: BaOfficeRepository
    let notificationCoordinator: any BaNotificationCoordinating
    @ObservationIgnored let watchSnapshotSyncer: any BaWatchSnapshotSyncing
    @ObservationIgnored var notificationSyncTask: Task<Void, Never>?
    @ObservationIgnored var studentDetailRequests: [Int64: StudentDetailRequest] = [:]
    @ObservationIgnored var watchAvatarSnapshotTask: Task<Void, Never>?

    init(
        settingsStore: BaSettingsStore,
        cacheStore: BaCacheStore,
        imageCache: BaImageCache,
        activityPoolRepository: BaActivityPoolRepository,
        catalogRepository: BaGuideCatalogRepository,
        catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator,
        studentRepository: BaStudentGuideRepository,
        officeRepository: BaOfficeRepository,
        notificationCoordinator: (any BaNotificationCoordinating)? = nil,
        watchSnapshotSyncer: (any BaWatchSnapshotSyncing)? = nil
    ) {
        self.settingsStore = settingsStore
        self.cacheStore = cacheStore
        self.imageCache = imageCache
        self.activityPoolRepository = activityPoolRepository
        self.catalogRepository = catalogRepository
        self.catalogReleaseDateHydrator = catalogReleaseDateHydrator
        self.studentRepository = studentRepository
        self.officeRepository = officeRepository
        self.notificationCoordinator = notificationCoordinator ?? BaNoopNotificationCoordinator()
        self.watchSnapshotSyncer = watchSnapshotSyncer ?? BaNoopWatchSnapshotSyncer()
        let loadedEnvelope = settingsStore.loadEnvelope()
        let loadedSettings = loadedEnvelope.flattenedSettings()
        envelope = loadedEnvelope
        settings = loadedSettings
        officeSnapshot = officeRepository.snapshot(settings: loadedSettings)
        BaL10n.configure(appLanguage: loadedEnvelope.globalSettings.appLanguage)
        watchSyncState = self.watchSnapshotSyncer.state
        self.watchSnapshotSyncer.activate()
        let loadedUserData = loadedEnvelope.userData(
            updatedAt: settingsStore.userDataUpdatedAt(fallback: Date())
        )
        syncWatchSnapshot(updatedAt: loadedUserData.updatedAt, now: Date())
        watchSyncState = self.watchSnapshotSyncer.state
        self.watchSnapshotSyncer.onStateChanged = { [weak self] state in
            self?.watchSyncState = state
        }
    }

    static func live() -> BaAppModel {
        let client = GameKeeClient()
        let cacheStore = BaCacheStore()
        let imageCache = BaImageCache(client: client)
        let watchSnapshotSyncer: any BaWatchSnapshotSyncing
        #if os(iOS) && canImport(WatchConnectivity)
        watchSnapshotSyncer = BaWatchConnectivityBridge()
        #else
        watchSnapshotSyncer = BaNoopWatchSnapshotSyncer()
        #endif
        return BaAppModel(
            settingsStore: BaSettingsStore(),
            cacheStore: cacheStore,
            imageCache: imageCache,
            activityPoolRepository: BaActivityPoolRepository(client: client),
            catalogRepository: BaGuideCatalogRepository(client: client),
            catalogReleaseDateHydrator: BaCatalogReleaseDateHydrator(
                cacheStore: cacheStore,
                studentRepository: BaStudentGuideRepository(client: client)
            ),
            studentRepository: BaStudentGuideRepository(client: client),
            officeRepository: BaOfficeRepository(),
            notificationCoordinator: BaNotificationCoordinator(),
            watchSnapshotSyncer: watchSnapshotSyncer
        )
    }

    static func testHost() -> BaAppModel {
        let client = GameKeeClient()
        let cacheStore = BaCacheStore()
        let defaults = UserDefaults(suiteName: "os.kei.KeiBA.xctest.\(UUID().uuidString)") ?? .standard
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
            officeRepository: BaOfficeRepository(),
            notificationCoordinator: BaNoopNotificationCoordinator(),
            watchSnapshotSyncer: BaNoopWatchSnapshotSyncer()
        )
    }

    static let catalogCacheSchemaVersion = 6
    static let poolCacheSchemaVersion = 6
    static let studentCatalogPID = BaCatalogCategory.students.gameKeePID
}
