//
//  BaAppModel+Settings.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    var currentProfile: BaServerProfile {
        envelope.profile(for: envelope.selectedServer)
    }

    var userData: BaUserDataEnvelope {
        settingsStore.loadUserData()
    }

    var watchUserSnapshot: BaWatchUserSnapshot {
        userData.watchSnapshot()
    }

    func applyUserData(_ userData: BaUserDataEnvelope) {
        let previousServer = settings.server
        let previousEnvelope = envelope
        envelope = userData.settingsEnvelope()
        persistEnvelope(previousServer: previousServer, updatedAt: userData.updatedAt, previousEnvelope: previousEnvelope)
    }

    func selectServer(_ server: BaServer) {
        let previousServer = settings.server
        let previousEnvelope = envelope
        envelope.selectedServer = server
        persistEnvelope(previousServer: previousServer, previousEnvelope: previousEnvelope)
    }

    func updateSettings(_ transform: (inout BaAppSettings) -> Void) {
        let previous = settings
        let previousServer = settings.server
        let previousEnvelope = envelope
        var next = settings
        transform(&next)
        applyFlattenedSettings(next, previous: previous)
        persistEnvelope(previousServer: previousServer, previousEnvelope: previousEnvelope)
    }

    func updateCurrentProfile(_ transform: (inout BaServerProfile) -> Void) {
        let previousServer = settings.server
        let previousEnvelope = envelope
        var profile = currentProfile
        transform(&profile)
        envelope.setProfile(profile, for: envelope.selectedServer)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
        persistEnvelope(previousServer: previousServer, previousEnvelope: previousEnvelope)
    }

    func updateGlobalSettings(_ transform: (inout BaGlobalSettings) -> Void) {
        let previousServer = settings.server
        let previousEnvelope = envelope
        transform(&envelope.globalSettings)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
        persistEnvelope(previousServer: previousServer, previousEnvelope: previousEnvelope)
    }

    func setCurrentAP(_ value: Int) {
        updateCurrentProfile { profile in
            let currentFraction = BaTimeMath.normalizedAP(profile.apCurrent) -
                Double(BaTimeMath.displayAP(profile.apCurrent))
            let clampedValue = Double(min(max(value, 0), BaTimeMath.apMax))
            profile.apCurrent = BaTimeMath.normalizedAP(clampedValue + currentFraction)
            profile.apRegenBaseAt = Date()
            profile.apSyncAt = Date()
        }
    }

    func setAPLimit(_ value: Int) {
        updateCurrentProfile { profile in
            let now = Date()
            profile.apCurrent = BaTimeMath.currentAP(profile: profile, now: now)
            profile.apRegenBaseAt = now
            profile.apLimit = min(max(value, 0), BaTimeMath.apLimitMax)
        }
    }

    func setAPNotifyThreshold(_ value: Int) {
        updateCurrentProfile { profile in
            profile.apNotifyThreshold = min(max(value, 0), BaTimeMath.apMax)
        }
    }

    func setAPEditorValues(currentAP: Int, apLimit: Int, apNotifyThreshold: Int) {
        updateCurrentProfile { profile in
            let now = Date()
            profile.apCurrent = BaTimeMath.normalizedAP(Double(min(max(currentAP, 0), BaTimeMath.apMax)))
            profile.apLimit = min(max(apLimit, 0), BaTimeMath.apLimitMax)
            profile.apNotifyThreshold = min(max(apNotifyThreshold, 0), BaTimeMath.apMax)
            profile.apRegenBaseAt = now
            profile.apSyncAt = now
        }
    }

    func claimCafeAP() {
        updateCurrentProfile { profile in
            let now = Date()
            let currentAP = BaTimeMath.currentAP(profile: profile, now: now)
            let currentCafeAP = BaTimeMath.currentCafeAP(profile: profile, now: now)
            guard currentCafeAP > 0 else { return }
            profile.apCurrent = BaTimeMath.normalizedAP(currentAP + currentCafeAP)
            profile.apRegenBaseAt = now
            profile.apSyncAt = now
            profile.cafeApCurrent = 0
            profile.cafeStorageBaseAt = now
        }
    }

    func performCafeAction(_ kind: BaCafeActionKind) {
        updateCurrentProfile { profile in
            let now = Date()
            switch kind {
            case .headpat:
                let availableAt = BaTimeMath.nextHeadpatAvailable(
                    lastHeadpatAt: profile.lastHeadpatAt,
                    server: settings.server
                )
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastHeadpatAt = now
            case .inviteTicket1:
                let availableAt = BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket1At)
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastInviteTicket1At = now
            case .inviteTicket2:
                let availableAt = BaTimeMath.nextInviteAvailable(lastInviteAt: profile.lastInviteTicket2At)
                guard availableAt.map({ $0 <= now }) ?? true else { return }
                profile.lastInviteTicket2At = now
            }
        }
    }

    func resetCafeAction(_ kind: BaCafeActionKind) {
        updateCurrentProfile { profile in
            switch kind {
            case .headpat:
                profile.lastHeadpatAt = nil
            case .inviteTicket1:
                profile.lastInviteTicket1At = nil
            case .inviteTicket2:
                profile.lastInviteTicket2At = nil
            }
        }
    }

    func persistEnvelope(
        previousServer: BaServer,
        updatedAt: Date = Date(),
        previousEnvelope: BaSettingsEnvelope? = nil
    ) {
        envelope = envelope.normalized()
        settings = envelope.flattenedSettings()
        BaL10n.configure(appLanguage: envelope.globalSettings.appLanguage)
        settingsStore.saveEnvelope(envelope, updatedAt: updatedAt)
        if previousServer != settings.server {
            activityState = BaLoadableState()
            poolState = BaLoadableState()
        }
        refreshOfficeSnapshot()
        let shouldRequestAuthorization = previousEnvelope.map {
            BaNotificationPreferenceSnapshot(envelope: envelope)
                .becameEnabled(from: BaNotificationPreferenceSnapshot(envelope: $0))
        } ?? false
        scheduleNotificationRefresh(requestAuthorizationIfNeeded: shouldRequestAuthorization)
    }

    private func applyFlattenedSettings(_ next: BaAppSettings, previous: BaAppSettings) {
        envelope.globalSettings.identityIndependentByServer = next.identityIndependentByServer
        envelope.globalSettings.showEndedActivities = next.showEndedActivities
        envelope.globalSettings.showEndedPools = next.showEndedPools
        envelope.globalSettings.showPreviewImages = next.showPreviewImages
        envelope.globalSettings.activityNotificationsEnabled = next.activityNotificationsEnabled
        envelope.globalSettings.poolNotificationsEnabled = next.poolNotificationsEnabled
        envelope.globalSettings.calendarUpcomingNotificationsEnabled = next.calendarUpcomingNotificationsEnabled
        envelope.globalSettings.calendarEndingNotificationsEnabled = next.calendarEndingNotificationsEnabled
        envelope.globalSettings.poolUpcomingNotificationsEnabled = next.poolUpcomingNotificationsEnabled
        envelope.globalSettings.poolEndingNotificationsEnabled = next.poolEndingNotificationsEnabled
        envelope.globalSettings.calendarPoolChangeNotificationsEnabled = next.calendarPoolChangeNotificationsEnabled
        envelope.globalSettings.calendarPoolNotifyLead = next.calendarPoolNotifyLead
        envelope.globalSettings.mediaAutoplayEnabled = next.mediaAutoplayEnabled
        envelope.globalSettings.mediaDownloadEnabled = next.mediaDownloadEnabled
        envelope.globalSettings.refreshInterval = next.refreshInterval
        envelope.globalSettings.appLanguage = next.appLanguage
        envelope.globalSettings.appAppearance = next.appAppearance
        envelope.globalSettings.favoriteContentIDs = next.favoriteContentIDs
        envelope.globalSettings.favoriteCatalogEntries = next.favoriteCatalogEntries
        envelope.globalSettings.dutyStudent = next.dutyStudent
        if next.server != previous.server {
            envelope.selectedServer = next.server
            return
        }
        var profile = currentProfile
        profile.nickname = next.nickname
        profile.friendCode = next.friendCode
        let now = Date()
        if next.apLimit != previous.apLimit {
            profile.apCurrent = BaTimeMath.currentAP(settings: previous, now: now)
            profile.apRegenBaseAt = now
        } else {
            profile.apCurrent = next.apCurrent
            profile.apRegenBaseAt = next.apRegenBaseAt
        }
        profile.apLimit = next.apLimit
        profile.apSyncAt = next.apSyncAt
        profile.cafeLevel = next.cafeLevel
        profile.cafeApCurrent = next.cafeApCurrent
        profile.cafeStorageBaseAt = next.cafeStorageBaseAt
        profile.lastHeadpatAt = next.lastHeadpatAt
        profile.lastInviteTicket1At = next.lastInviteTicket1At ?? next.lastInviteTicketAt
        profile.lastInviteTicket2At = next.lastInviteTicket2At
        profile.apNotificationsEnabled = next.apNotificationsEnabled
        profile.cafeApNotificationsEnabled = next.cafeApNotificationsEnabled
        profile.visitNotificationsEnabled = next.visitNotificationsEnabled
        profile.arenaRefreshNotificationsEnabled = next.arenaRefreshNotificationsEnabled
        profile.apNotifyThreshold = next.apNotifyThreshold
        profile.cafeApNotifyThreshold = next.cafeApNotifyThreshold
        profile.cafeVisitLastNotifiedAt = next.cafeVisitLastNotifiedAt
        profile.arenaRefreshLastNotifiedAt = next.arenaRefreshLastNotifiedAt
        envelope.setProfile(profile, for: envelope.selectedServer)
        synchronizeSharedIdentityIfNeeded(from: envelope.selectedServer)
    }

    private func synchronizeSharedIdentityIfNeeded(from server: BaServer) {
        guard envelope.globalSettings.identityIndependentByServer == false else { return }
        let source = envelope.profile(for: server)
        for target in BaServer.allCases {
            envelope.serverProfiles[target]?.nickname = source.nickname
            envelope.serverProfiles[target]?.friendCode = source.friendCode
        }
    }
}
