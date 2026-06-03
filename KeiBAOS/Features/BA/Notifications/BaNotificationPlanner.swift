//
//  BaNotificationPlanner.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated enum BaNotificationPlanner {
    static let defaultMaximumReminderCount = 48
    private static let minimumFutureOffset: TimeInterval = 5
    private static let timelineLookahead: TimeInterval = 30 * 24 * 60 * 60
    private static let liveActivityMaximumDuration: TimeInterval = 12 * 60 * 60

    static func makePlan(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date = Date(),
        maximumReminderCount: Int = defaultMaximumReminderCount
    ) -> BaNotificationPlan {
        filteredPlan(
            reminders: reminders(
                settings: settings,
                activities: activities,
                pools: pools,
                now: now,
                account: nil
            ),
            now: now,
            maximumReminderCount: maximumReminderCount
        )
    }

    static func makePlan(
        envelope: BaSettingsEnvelope,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date = Date(),
        maximumReminderCount: Int = defaultMaximumReminderCount
    ) -> BaNotificationPlan {
        let normalized = envelope.normalized()
        let enabledAccounts = normalized.accounts.filter(\.isEnabled)
        let accountReminders = enabledAccounts.flatMap { account in
            personalReminders(
                settings: normalized.flattenedSettings(for: account),
                now: now,
                account: account
            )
        }
        let timelineReminders = timelineReminders(
            settings: normalized.flattenedSettings(),
            activities: activities,
            pools: pools,
            now: now
        )

        return filteredPlan(
            reminders: accountReminders + timelineReminders,
            now: now,
            maximumReminderCount: maximumReminderCount
        )
    }

    private static func reminders(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date,
        account: BaAccountProfile?
    ) -> [BaNotificationReminder] {
        personalReminders(
            settings: settings,
            now: now,
            account: account
        ) + timelineReminders(
            settings: settings,
            activities: activities,
            pools: pools,
            now: now
        )
    }

    private static func personalReminders(
        settings: BaAppSettings,
        now: Date,
        account: BaAccountProfile?
    ) -> [BaNotificationReminder] {
        var reminders: [BaNotificationReminder] = []

        if settings.apNotificationsEnabled,
           let reminder = apReminder(settings: settings, now: now, account: account)
        {
            reminders.append(reminder)
        }

        if settings.cafeApNotificationsEnabled,
           let reminder = cafeAPReminder(settings: settings, now: now, account: account)
        {
            reminders.append(reminder)
        }

        if settings.visitNotificationsEnabled {
            reminders.append(contentsOf: cafeVisitReminders(settings: settings, now: now, account: account))
        }

        if settings.arenaRefreshNotificationsEnabled {
            reminders.append(contentsOf: arenaRefreshReminders(settings: settings, now: now, account: account))
        }

        return reminders
    }

    private static func timelineReminders(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date
    ) -> [BaNotificationReminder] {
        var reminders: [BaNotificationReminder] = []
        reminders.append(
            contentsOf: activityReminders(
                settings: settings,
                entries: activities,
                now: now
            )
        )
        reminders.append(
            contentsOf: poolReminders(
                settings: settings,
                entries: pools,
                now: now
            )
        )

        return reminders
    }

    private static func filteredPlan(
        reminders: [BaNotificationReminder],
        now: Date,
        maximumReminderCount: Int
    ) -> BaNotificationPlan {
        let horizon = now.addingTimeInterval(timelineLookahead)
        let filtered = reminders
            .filter { $0.fireDate.timeIntervalSince(now) >= minimumFutureOffset }
            .filter { $0.fireDate <= horizon }
            .sorted { lhs, rhs in
                if lhs.fireDate == rhs.fireDate {
                    return lhs.id < rhs.id
                }
                return lhs.fireDate < rhs.fireDate
            }
            .prefix(maximumReminderCount)

        return BaNotificationPlan(reminders: Array(filtered))
    }

    static func liveActivityCandidates(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date = Date()
    ) -> [BaLiveActivityCandidate] {
        var candidates: [BaLiveActivityCandidate] = []

        if let resourceCandidate = resourceLiveActivityCandidate(settings: settings, now: now) {
            candidates.append(resourceCandidate)
        }

        candidates.append(
            contentsOf: timelineLiveActivityCandidates(
                settings: settings,
                activities: activities,
                pools: pools,
                now: now
            )
        )

        return candidates.sorted { lhs, rhs in
            if lhs.endDate == rhs.endDate {
                return lhs.relevance > rhs.relevance
            }
            return lhs.endDate < rhs.endDate
        }
    }

    private static func resourceLiveActivityCandidate(settings: BaAppSettings, now: Date) -> BaLiveActivityCandidate? {
        var resources: [BaLiveActivityCandidate.Resource] = []

        if settings.apNotificationsEnabled {
            let current = BaTimeMath.currentAP(settings: settings, now: now)
            let limit = min(max(settings.apLimit, 0), BaTimeMath.apLimitMax)
            if let fullAt = apTargetDate(
                current: current,
                target: limit,
                limit: limit,
                baseAt: settings.apRegenBaseAt,
                now: now
            ),
                shouldStartLiveActivity(target: fullAt, now: now)
            {
                resources.append(
                    BaLiveActivityCandidate.Resource(
                        kind: .ap,
                        title: localized("ba.notification.live.ap.title"),
                        currentValue: BaTimeMath.displayAP(current),
                        limitValue: limit,
                        startDate: now,
                        endDate: fullAt
                    )
                )
            }
        }

        if settings.cafeApNotificationsEnabled {
            let current = BaTimeMath.currentCafeAP(settings: settings, now: now)
            let capacity = BaTimeMath.cafeDailyCapacity(level: settings.cafeLevel)
            if let fullAt = cafeAPTargetDate(settings: settings, target: capacity, now: now),
               shouldStartLiveActivity(target: fullAt, now: now)
            {
                resources.append(
                    BaLiveActivityCandidate.Resource(
                        kind: .cafeAP,
                        title: localized("ba.notification.live.cafeAp.title"),
                        currentValue: BaTimeMath.displayAP(current),
                        limitValue: capacity,
                        startDate: now,
                        endDate: fullAt
                    )
                )
            }
        }

        guard let primary = resources.first else { return nil }
        let activityEndDate = resources.map(\.endDate).max() ?? primary.endDate

        return BaLiveActivityCandidate(
            id: identifier(settings.server, "live", "resource"),
            kind: primary.kind.liveActivityKind,
            title: primary.title,
            subtitle: localized("ba.notification.live.resource.subtitle"),
            startDate: primary.startDate,
            endDate: activityEndDate,
            relevance: resources.contains { $0.kind == .ap } ? 0.92 : 0.88,
            resources: resources
        )
    }

    private static func apReminder(
        settings: BaAppSettings,
        now: Date,
        account: BaAccountProfile?
    ) -> BaNotificationReminder? {
        let current = BaTimeMath.currentAP(settings: settings, now: now)
        guard current < Double(settings.apLimit) else { return nil }

        let threshold = min(max(settings.apNotifyThreshold, 0), settings.apLimit)
        let target = threshold > BaTimeMath.displayAP(current) ? threshold : settings.apLimit
        guard let fireDate = apTargetDate(
            current: current,
            target: target,
            limit: settings.apLimit,
            baseAt: settings.apRegenBaseAt,
            now: now
        ) else { return nil }

        return BaNotificationReminder(
            id: identifier(settings.server, BaNotificationReminder.Kind.ap.rawValue, "threshold", accountID: account?.id),
            kind: .ap,
            fireDate: fireDate,
            titleKey: "ba.notification.ap.title",
            bodyKey: account == nil ? "ba.notification.ap.body" : "ba.notification.account.ap.body",
            bodyArguments: accountArguments(
                account,
                values: "\(target)",
                BaDisplayFormatters.clockTime(fireDate)
            ),
            threadIdentifier: threadIdentifier(settings.server, "resource", accountID: account?.id)
        )
    }

    private static func cafeAPReminder(
        settings: BaAppSettings,
        now: Date,
        account: BaAccountProfile?
    ) -> BaNotificationReminder? {
        let capacity = BaTimeMath.cafeDailyCapacity(level: settings.cafeLevel)
        let current = BaTimeMath.currentCafeAP(settings: settings, now: now)
        guard current < Double(capacity) else { return nil }

        let threshold = min(max(settings.cafeApNotifyThreshold, 0), capacity)
        let target = threshold > BaTimeMath.displayAP(current) ? threshold : capacity
        guard let fireDate = cafeAPTargetDate(settings: settings, target: target, now: now) else { return nil }

        return BaNotificationReminder(
            id: identifier(settings.server, BaNotificationReminder.Kind.cafeAP.rawValue, "threshold", accountID: account?.id),
            kind: .cafeAP,
            fireDate: fireDate,
            titleKey: "ba.notification.cafeAp.title",
            bodyKey: account == nil ? "ba.notification.cafeAp.body" : "ba.notification.account.cafeAp.body",
            bodyArguments: accountArguments(
                account,
                values: "\(target)",
                BaDisplayFormatters.clockTime(fireDate)
            ),
            threadIdentifier: threadIdentifier(settings.server, "resource", accountID: account?.id)
        )
    }

    private static func cafeVisitReminders(
        settings: BaAppSettings,
        now: Date,
        account: BaAccountProfile?
    ) -> [BaNotificationReminder] {
        nextServerRefreshes(
            count: 4,
            server: settings.server,
            now: now,
            next: BaTimeMath.nextCafeStudentRefresh(from:server:)
        ).enumerated().map { offset, fireDate in
            BaNotificationReminder(
                id: identifier(
                    settings.server,
                    BaNotificationReminder.Kind.cafeVisit.rawValue,
                    "\(offset)-\(Int(fireDate.timeIntervalSince1970))",
                    accountID: account?.id
                ),
                kind: .cafeVisit,
                fireDate: fireDate,
                titleKey: "ba.notification.visit.title",
                bodyKey: account == nil ? "ba.notification.visit.body" : "ba.notification.account.visit.body",
                bodyArguments: accountArguments(account, values: BaDisplayFormatters.clockTime(fireDate)),
                threadIdentifier: threadIdentifier(settings.server, "cafe", accountID: account?.id)
            )
        }
    }

    private static func arenaRefreshReminders(
        settings: BaAppSettings,
        now: Date,
        account: BaAccountProfile?
    ) -> [BaNotificationReminder] {
        nextServerRefreshes(
            count: 3,
            server: settings.server,
            now: now,
            next: BaTimeMath.nextArenaRefresh(from:server:)
        ).enumerated().map { offset, fireDate in
            BaNotificationReminder(
                id: identifier(
                    settings.server,
                    BaNotificationReminder.Kind.arenaRefresh.rawValue,
                    "\(offset)-\(Int(fireDate.timeIntervalSince1970))",
                    accountID: account?.id
                ),
                kind: .arenaRefresh,
                fireDate: fireDate,
                titleKey: "ba.notification.arena.title",
                bodyKey: account == nil ? "ba.notification.arena.body" : "ba.notification.account.arena.body",
                bodyArguments: accountArguments(account, values: BaDisplayFormatters.clockTime(fireDate)),
                threadIdentifier: threadIdentifier(settings.server, "arena", accountID: account?.id)
            )
        }
    }

    private static func activityReminders(
        settings: BaAppSettings,
        entries: [BaActivityEntry],
        now: Date
    ) -> [BaNotificationReminder] {
        let lead = settings.calendarPoolNotifyLead.timeInterval
        return entries.flatMap { entry in
            var reminders: [BaNotificationReminder] = []
            if settings.calendarUpcomingNotificationsEnabled {
                reminders.append(
                    timelineReminder(
                        server: settings.server,
                        kind: .activityStart,
                        sourceID: entry.id,
                        title: entry.title,
                        milestone: entry.beginAt,
                        fireDate: entry.beginAt.addingTimeInterval(-lead),
                        titleKey: "ba.notification.activity.start.title",
                        bodyKey: "ba.notification.activity.start.body",
                        now: now
                    )
                )
            }
            if settings.calendarEndingNotificationsEnabled {
                reminders.append(
                    timelineReminder(
                        server: settings.server,
                        kind: .activityEnd,
                        sourceID: entry.id,
                        title: entry.title,
                        milestone: entry.endAt,
                        fireDate: entry.endAt.addingTimeInterval(-lead),
                        titleKey: "ba.notification.activity.end.title",
                        bodyKey: "ba.notification.activity.end.body",
                        now: now
                    )
                )
            }
            if settings.calendarPoolChangeNotificationsEnabled {
                reminders.append(
                    timelineChangeReminder(
                        server: settings.server,
                        source: "activity",
                        sourceID: entry.id,
                        title: entry.title,
                        fireDate: entry.beginAt,
                        bodyKey: "ba.notification.activity.changed.body",
                        now: now
                    )
                )
                reminders.append(
                    timelineChangeReminder(
                        server: settings.server,
                        source: "activity",
                        sourceID: entry.id,
                        title: entry.title,
                        fireDate: entry.endAt,
                        bodyKey: "ba.notification.activity.changed.body",
                        now: now
                    )
                )
            }
            return reminders
        }
    }

    private static func poolReminders(
        settings: BaAppSettings,
        entries: [BaPoolEntry],
        now: Date
    ) -> [BaNotificationReminder] {
        let lead = settings.calendarPoolNotifyLead.timeInterval
        return entries.flatMap { entry in
            var reminders: [BaNotificationReminder] = []
            if settings.poolUpcomingNotificationsEnabled {
                reminders.append(
                    timelineReminder(
                        server: settings.server,
                        kind: .poolStart,
                        sourceID: entry.id,
                        title: entry.name,
                        milestone: entry.startAt,
                        fireDate: entry.startAt.addingTimeInterval(-lead),
                        titleKey: "ba.notification.pool.start.title",
                        bodyKey: "ba.notification.pool.start.body",
                        now: now
                    )
                )
            }
            if settings.poolEndingNotificationsEnabled {
                reminders.append(
                    timelineReminder(
                        server: settings.server,
                        kind: .poolEnd,
                        sourceID: entry.id,
                        title: entry.name,
                        milestone: entry.endAt,
                        fireDate: entry.endAt.addingTimeInterval(-lead),
                        titleKey: "ba.notification.pool.end.title",
                        bodyKey: "ba.notification.pool.end.body",
                        now: now
                    )
                )
            }
            if settings.calendarPoolChangeNotificationsEnabled {
                reminders.append(
                    timelineChangeReminder(
                        server: settings.server,
                        source: "pool",
                        sourceID: entry.id,
                        title: entry.name,
                        fireDate: entry.startAt,
                        bodyKey: "ba.notification.pool.changed.body",
                        now: now
                    )
                )
                reminders.append(
                    timelineChangeReminder(
                        server: settings.server,
                        source: "pool",
                        sourceID: entry.id,
                        title: entry.name,
                        fireDate: entry.endAt,
                        bodyKey: "ba.notification.pool.changed.body",
                        now: now
                    )
                )
            }
            return reminders
        }
    }

    private static func timelineReminder(
        server: BaServer,
        kind: BaNotificationReminder.Kind,
        sourceID: Int,
        title: String,
        milestone: Date,
        fireDate: Date,
        titleKey: String,
        bodyKey: String,
        now: Date
    ) -> BaNotificationReminder {
        BaNotificationReminder(
            id: identifier(server, kind.rawValue, "\(sourceID)"),
            kind: kind,
            fireDate: fireDate,
            titleKey: titleKey,
            bodyKey: bodyKey,
            bodyArguments: [
                title,
                BaDisplayFormatters.dateTime(milestone, server: server),
            ],
            threadIdentifier: threadIdentifier(server, "timeline")
        )
    }

    private static func timelineChangeReminder(
        server: BaServer,
        source: String,
        sourceID: Int,
        title: String,
        fireDate: Date,
        bodyKey: String,
        now: Date
    ) -> BaNotificationReminder {
        BaNotificationReminder(
            id: identifier(server, BaNotificationReminder.Kind.timelineChange.rawValue, "\(source)-\(sourceID)-\(Int(fireDate.timeIntervalSince1970))"),
            kind: .timelineChange,
            fireDate: fireDate,
            titleKey: "ba.notification.timeline.changed.title",
            bodyKey: bodyKey,
            bodyArguments: [
                title,
                BaDisplayFormatters.dateTime(fireDate, server: server),
            ],
            threadIdentifier: threadIdentifier(server, "timeline")
        )
    }

    private static func timelineLiveActivityCandidates(
        settings: BaAppSettings,
        activities: [BaActivityEntry],
        pools: [BaPoolEntry],
        now: Date
    ) -> [BaLiveActivityCandidate] {
        var candidates: [BaLiveActivityCandidate] = []

        if settings.calendarEndingNotificationsEnabled {
            candidates += activities
                .filter { $0.status(at: now) == .running && shouldStartLiveActivity(target: $0.endAt, now: now) }
                .map {
                    BaLiveActivityCandidate(
                        id: identifier(settings.server, "liveActivity", "activity-\($0.id)"),
                        kind: .activity,
                        title: $0.title,
                        subtitle: localized("ba.notification.live.activity.subtitle"),
                        startDate: max($0.beginAt, now),
                        endDate: $0.endAt,
                        relevance: 0.82
                    )
                }
        }

        if settings.poolEndingNotificationsEnabled {
            candidates += pools
                .filter { $0.status(at: now) == .running && shouldStartLiveActivity(target: $0.endAt, now: now) }
                .map {
                    BaLiveActivityCandidate(
                        id: identifier(settings.server, "liveActivity", "pool-\($0.id)"),
                        kind: .pool,
                        title: $0.name,
                        subtitle: localized("ba.notification.live.pool.subtitle"),
                        startDate: max($0.startAt, now),
                        endDate: $0.endAt,
                        relevance: 0.84
                    )
                }
        }

        return candidates
    }

    private static func apTargetDate(
        current: Double,
        target: Int,
        limit: Int,
        baseAt: Date,
        now: Date
    ) -> Date? {
        let clampedLimit = min(max(limit, 0), BaTimeMath.apLimitMax)
        let clampedTarget = min(max(target, 0), clampedLimit)
        guard clampedLimit > 0, current < Double(clampedLimit), clampedTarget > BaTimeMath.displayAP(current) else {
            return nil
        }

        let elapsed = max(now.timeIntervalSince(baseAt), 0)
        let remainder = elapsed.truncatingRemainder(dividingBy: BaTimeMath.apRegenInterval)
        let untilNext = remainder == 0 ? BaTimeMath.apRegenInterval : BaTimeMath.apRegenInterval - remainder
        let pointsNeeded = max(clampedTarget - BaTimeMath.displayAP(current), 1)
        return now
            .addingTimeInterval(untilNext)
            .addingTimeInterval(TimeInterval(pointsNeeded - 1) * BaTimeMath.apRegenInterval)
    }

    private static func cafeAPTargetDate(settings: BaAppSettings, target: Int, now: Date) -> Date? {
        let capacity = BaTimeMath.cafeDailyCapacity(level: settings.cafeLevel)
        let clampedTarget = min(max(target, 0), capacity)
        let current = BaTimeMath.currentCafeAP(settings: settings, now: now)
        guard capacity > 0, current < Double(capacity), clampedTarget > BaTimeMath.displayAP(current) else {
            return nil
        }

        let hourlyGain = BaTimeMath.cafeHourlyGain(level: settings.cafeLevel)
        guard hourlyGain > 0 else { return nil }
        let elapsed = max(now.timeIntervalSince(settings.cafeStorageBaseAt), 0)
        let remainder = elapsed.truncatingRemainder(dividingBy: BaTimeMath.cafeHourlyInterval)
        let untilNext = remainder == 0 ? BaTimeMath.cafeHourlyInterval : BaTimeMath.cafeHourlyInterval - remainder
        let pointsNeeded = max(Double(clampedTarget) - current, hourlyGain)
        let hoursNeeded = max(Int(ceil(pointsNeeded / hourlyGain)), 1)
        return now
            .addingTimeInterval(untilNext)
            .addingTimeInterval(TimeInterval(hoursNeeded - 1) * BaTimeMath.cafeHourlyInterval)
    }

    private static func nextServerRefreshes(
        count: Int,
        server: BaServer,
        now: Date,
        next: (Date, BaServer) -> Date
    ) -> [Date] {
        var cursor = now
        var dates: [Date] = []
        while dates.count < count {
            let date = next(cursor, server)
            guard date > cursor else { break }
            dates.append(date)
            cursor = date.addingTimeInterval(1)
        }
        return dates
    }

    private static func shouldStartLiveActivity(target: Date, now: Date) -> Bool {
        let remaining = target.timeIntervalSince(now)
        return remaining >= minimumFutureOffset && remaining <= liveActivityMaximumDuration
    }

    private static func identifier(
        _ server: BaServer,
        _ kind: String,
        _ key: String,
        accountID: BaAccountID? = nil
    ) -> String {
        if let accountID {
            return "\(BaNotificationPlan.managedIdentifierPrefix)account.\(safeIdentifierPart(accountID)).\(server.rawValue).\(kind).\(key)"
        }
        return "\(BaNotificationPlan.managedIdentifierPrefix)\(server.rawValue).\(kind).\(key)"
    }

    private static func threadIdentifier(
        _ server: BaServer,
        _ topic: String,
        accountID: BaAccountID? = nil
    ) -> String {
        if let accountID {
            return "os.kei.KeiBAOS.ba.account.\(safeIdentifierPart(accountID)).\(server.rawValue).\(topic)"
        }
        return "os.kei.KeiBAOS.ba.\(server.rawValue).\(topic)"
    }

    private static func accountArguments(
        _ account: BaAccountProfile?,
        values: String...
    ) -> [String] {
        guard let account else { return values }
        return [account.title] + values
    }

    private static func safeIdentifierPart(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? String(scalar) : "_"
        }
        .joined()
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, comment: "")
    }
}

private extension BaLiveActivityCandidate.Resource.Kind {
    nonisolated var liveActivityKind: BaLiveActivityCandidate.Kind {
        switch self {
        case .ap:
            .ap
        case .cafeAP:
            .cafeAP
        }
    }
}

private extension BaCalendarPoolNotifyLead {
    nonisolated var timeInterval: TimeInterval {
        TimeInterval(rawValue) * 60 * 60
    }
}
