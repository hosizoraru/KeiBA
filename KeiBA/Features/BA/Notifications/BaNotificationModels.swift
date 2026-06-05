//
//  BaNotificationModels.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated struct BaNotificationPlan: Equatable, Sendable {
    static let managedIdentifierPrefix = "os.kei.KeiBA.ba.notification."
    static let debugIdentifierPrefix = "os.kei.KeiBA.ba.notification.debug."

    var reminders: [BaNotificationReminder]

    var identifiers: [String] {
        reminders.map(\.id)
    }
}

nonisolated struct BaNotificationReminder: Identifiable, Equatable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case ap
        case cafeAP
        case cafeVisit
        case arenaRefresh
        case activityStart
        case activityEnd
        case poolStart
        case poolEnd
        case timelineChange
    }

    var id: String
    var kind: Kind
    var fireDate: Date
    var titleKey: String
    var bodyKey: String
    var bodyArguments: [String]
    var threadIdentifier: String
}

nonisolated struct BaNotificationPreferenceSnapshot: Equatable, Sendable {
    var ap: Bool
    var cafeAP: Bool
    var cafeVisit: Bool
    var arenaRefresh: Bool
    var activityStart: Bool
    var activityEnd: Bool
    var poolStart: Bool
    var poolEnd: Bool
    var timelineChange: Bool

    init(envelope: BaSettingsEnvelope) {
        let normalized = envelope.normalized()
        let profiles = normalized.accounts.filter(\.isEnabled).map(\.profile)
        let activeProfile = normalized.selectedAccount.profile
        let scopedProfiles = profiles.isEmpty ? [activeProfile] : profiles
        let global = normalized.globalSettings
        ap = scopedProfiles.contains { $0.apNotificationsEnabled }
        cafeAP = scopedProfiles.contains { $0.cafeApNotificationsEnabled }
        cafeVisit = scopedProfiles.contains { $0.visitNotificationsEnabled }
        arenaRefresh = scopedProfiles.contains { $0.arenaRefreshNotificationsEnabled }
        activityStart = global.calendarUpcomingNotificationsEnabled
        activityEnd = global.calendarEndingNotificationsEnabled
        poolStart = global.poolUpcomingNotificationsEnabled
        poolEnd = global.poolEndingNotificationsEnabled
        timelineChange = global.calendarPoolChangeNotificationsEnabled
    }

    var hasEnabledReminder: Bool {
        enabledValues.contains(true)
    }

    func becameEnabled(from previous: BaNotificationPreferenceSnapshot) -> Bool {
        zip(enabledValues, previous.enabledValues).contains { current, previous in
            current && previous == false
        }
    }

    private var enabledValues: [Bool] {
        [
            ap,
            cafeAP,
            cafeVisit,
            arenaRefresh,
            activityStart,
            activityEnd,
            poolStart,
            poolEnd,
            timelineChange,
        ]
    }
}

nonisolated struct BaNotificationScheduleSnapshot: Equatable, Sendable {
    var selectedServer: BaServer
    var preferences: BaNotificationPreferenceSnapshot
    var appLanguage: BaAppLanguage
    var calendarPoolNotifyLead: BaCalendarPoolNotifyLead
    var apCurrent: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var apNotifyThreshold: Int
    var cafeLevel: Int
    var cafeApCurrent: Double
    var cafeStorageBaseAt: Date
    var cafeApNotifyThreshold: Int
    var lastHeadpatAt: Date?
    var lastInviteTicket1At: Date?
    var lastInviteTicket2At: Date?
    var accounts: [BaAccountNotificationScheduleSnapshot]

    init(envelope: BaSettingsEnvelope) {
        let normalized = envelope.normalized()
        let settings = normalized.flattenedSettings()
        selectedServer = normalized.selectedServer
        preferences = BaNotificationPreferenceSnapshot(envelope: normalized)
        appLanguage = normalized.globalSettings.appLanguage
        calendarPoolNotifyLead = normalized.globalSettings.calendarPoolNotifyLead
        apCurrent = settings.apCurrent
        apLimit = settings.apLimit
        apRegenBaseAt = settings.apRegenBaseAt
        apNotifyThreshold = settings.apNotifyThreshold
        cafeLevel = settings.cafeLevel
        cafeApCurrent = settings.cafeApCurrent
        cafeStorageBaseAt = settings.cafeStorageBaseAt
        cafeApNotifyThreshold = settings.cafeApNotifyThreshold
        lastHeadpatAt = settings.lastHeadpatAt
        lastInviteTicket1At = settings.lastInviteTicket1At
        lastInviteTicket2At = settings.lastInviteTicket2At
        accounts = normalized.accounts
            .filter(\.isEnabled)
            .map { account in
                BaAccountNotificationScheduleSnapshot(account: account)
            }
    }
}

nonisolated struct BaAccountNotificationScheduleSnapshot: Equatable, Sendable {
    var id: BaAccountID
    var server: BaServer
    var apCurrent: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var apNotificationsEnabled: Bool
    var apNotifyThreshold: Int
    var cafeLevel: Int
    var cafeApCurrent: Double
    var cafeStorageBaseAt: Date
    var cafeApNotificationsEnabled: Bool
    var cafeApNotifyThreshold: Int
    var visitNotificationsEnabled: Bool
    var arenaRefreshNotificationsEnabled: Bool
    var lastHeadpatAt: Date?
    var lastInviteTicket1At: Date?
    var lastInviteTicket2At: Date?

    init(account: BaAccountProfile) {
        let normalized = account.profile.normalized()
        id = account.id
        server = account.server
        apCurrent = normalized.apCurrent
        apLimit = normalized.apLimit
        apRegenBaseAt = normalized.apRegenBaseAt
        apNotificationsEnabled = normalized.apNotificationsEnabled
        apNotifyThreshold = normalized.apNotifyThreshold
        cafeLevel = normalized.cafeLevel
        cafeApCurrent = normalized.cafeApCurrent
        cafeStorageBaseAt = normalized.cafeStorageBaseAt
        cafeApNotificationsEnabled = normalized.cafeApNotificationsEnabled
        cafeApNotifyThreshold = normalized.cafeApNotifyThreshold
        visitNotificationsEnabled = normalized.visitNotificationsEnabled
        arenaRefreshNotificationsEnabled = normalized.arenaRefreshNotificationsEnabled
        lastHeadpatAt = normalized.lastHeadpatAt
        lastInviteTicket1At = normalized.lastInviteTicket1At
        lastInviteTicket2At = normalized.lastInviteTicket2At
    }
}

nonisolated struct BaLiveActivityCandidate: Equatable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case ap
        case cafeAP
        case activity
        case pool
    }

    struct Resource: Equatable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case ap
            case cafeAP
        }

        var kind: Kind
        var title: String
        var currentValue: Int
        var limitValue: Int
        var startDate: Date
        var endDate: Date
    }

    var id: String
    var kind: Kind
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var relevance: Double
    var resources: [Resource] = []
}

nonisolated enum BaDebugLiveActivityKind: String, Equatable, Sendable, CaseIterable {
    case resource
    case activity
    case pool
}
