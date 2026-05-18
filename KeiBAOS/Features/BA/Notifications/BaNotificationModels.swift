//
//  BaNotificationModels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated struct BaNotificationPlan: Equatable, Sendable {
    static let managedIdentifierPrefix = "os.kei.KeiBAOS.ba.notification."
    static let debugIdentifierPrefix = "os.kei.KeiBAOS.ba.notification.debug."

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
        let profile = envelope.profile(for: envelope.selectedServer)
        let global = envelope.globalSettings
        ap = profile.apNotificationsEnabled
        cafeAP = profile.cafeApNotificationsEnabled
        cafeVisit = profile.visitNotificationsEnabled
        arenaRefresh = profile.arenaRefreshNotificationsEnabled
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
