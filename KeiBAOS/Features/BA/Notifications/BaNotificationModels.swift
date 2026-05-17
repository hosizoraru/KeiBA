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

nonisolated struct BaLiveActivityCandidate: Equatable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case ap
        case cafeAP
        case activity
        case pool
    }

    var id: String
    var kind: Kind
    var title: String
    var subtitle: String
    var startDate: Date
    var endDate: Date
    var relevance: Double
}
