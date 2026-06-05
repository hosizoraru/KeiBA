//
//  BaTimeMath.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated enum BaTimeMath {
    static let apMax = 999
    static let apLimitMax = 240
    static let apRegenInterval: TimeInterval = 6 * 60
    static let cafeHourlyInterval: TimeInterval = 60 * 60
    static let cafeStudentRefreshInterval: TimeInterval = 12 * 60 * 60
    static let arenaRefreshInterval: TimeInterval = 24 * 60 * 60
    static let headpatCooldown: TimeInterval = 3 * 60 * 60
    static let inviteCooldown: TimeInterval = 20 * 60 * 60
    static let cafeDailyAPByLevel = [92, 152, 222, 302, 390, 460, 530, 600, 570, 740]
    static let cafeStudentRefreshHours = [4, 16]
    static let arenaRefreshHour = 14

    static func displayAP(_ value: Double) -> Int {
        Int(max(value, 0))
    }

    static func normalizedAP(_ value: Double) -> Double {
        let clamped = min(max(value, 0), Double(apMax))
        return (clamped * 1000).rounded() / 1000
    }

    static func currentAP(settings: BaAppSettings, now: Date = Date()) -> Double {
        currentAP(
            baseAP: settings.apCurrent,
            apLimit: settings.apLimit,
            apRegenBaseAt: settings.apRegenBaseAt,
            now: now
        )
    }

    static func currentAP(profile: BaServerProfile, now: Date = Date()) -> Double {
        currentAP(
            baseAP: profile.apCurrent,
            apLimit: profile.apLimit,
            apRegenBaseAt: profile.apRegenBaseAt,
            now: now
        )
    }

    static func currentAP(
        baseAP: Double,
        apLimit: Int,
        apRegenBaseAt: Date,
        now: Date = Date()
    ) -> Double {
        let base = normalizedAP(baseAP)
        let limit = Double(min(max(apLimit, 0), apLimitMax))
        guard limit > 0, base < limit else {
            return base
        }
        let elapsed = max(now.timeIntervalSince(apRegenBaseAt), 0)
        let recovered = floor(elapsed / apRegenInterval)
        return normalizedAP(min(base + recovered, limit))
    }

    static func nextAPPointAt(settings: BaAppSettings, now: Date = Date()) -> Date {
        let limit = min(max(settings.apLimit, 0), apLimitMax)
        guard limit > 0, currentAP(settings: settings, now: now) < Double(limit) else {
            return now
        }
        let elapsed = max(now.timeIntervalSince(settings.apRegenBaseAt), 0)
        let remainder = elapsed.truncatingRemainder(dividingBy: apRegenInterval)
        let untilNext = remainder == 0 ? apRegenInterval : apRegenInterval - remainder
        return now.addingTimeInterval(untilNext)
    }

    static func apFullAt(settings: BaAppSettings, now: Date = Date()) -> Date {
        let limit = min(max(settings.apLimit, 0), apLimitMax)
        guard limit > 0 else { return now }
        let current = currentAP(settings: settings, now: now)
        guard current < Double(limit) else { return now }
        let pointsNeeded = max(Int(ceil(Double(limit) - current)), 0)
        guard pointsNeeded > 0 else { return now }
        let nextPoint = nextAPPointAt(settings: settings, now: now)
        return nextPoint.addingTimeInterval(TimeInterval(pointsNeeded - 1) * apRegenInterval)
    }

    static func cafeDailyCapacity(level: Int) -> Int {
        cafeDailyAPByLevel[min(max(level, 1), 10) - 1]
    }

    static func cafeHourlyGain(level: Int) -> Double {
        Double(cafeDailyCapacity(level: level)) / 24
    }

    static func currentCafeAP(settings: BaAppSettings, now: Date = Date()) -> Double {
        let elapsed = max(now.timeIntervalSince(settings.cafeStorageBaseAt), 0)
        let gained = floor(elapsed / cafeHourlyInterval) * cafeHourlyGain(level: settings.cafeLevel)
        return min(settings.cafeApCurrent + gained, Double(cafeDailyCapacity(level: settings.cafeLevel)))
    }

    static func currentCafeAP(profile: BaServerProfile, now: Date = Date()) -> Double {
        let elapsed = max(now.timeIntervalSince(profile.cafeStorageBaseAt), 0)
        let gained = floor(elapsed / cafeHourlyInterval) * cafeHourlyGain(level: profile.cafeLevel)
        return min(profile.cafeApCurrent + gained, Double(cafeDailyCapacity(level: profile.cafeLevel)))
    }

    static func nextCafeStudentRefresh(from date: Date, server: BaServer) -> Date {
        cafeStudentRefreshHours
            .map { nextServerRefresh(hour: $0, from: date, server: server) }
            .min() ?? date
    }

    static func nextArenaRefresh(from date: Date, server: BaServer) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = server.timeZone
        let start = calendar.startOfDay(for: date)
        let today = calendar.date(bySettingHour: arenaRefreshHour, minute: 0, second: 0, of: start) ?? start
        if date < today {
            return today
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return calendar.date(bySettingHour: arenaRefreshHour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    static func nextHeadpatAvailable(lastHeadpatAt: Date?, server: BaServer) -> Date? {
        guard let lastHeadpatAt else { return nil }
        let cooldownReady = lastHeadpatAt.addingTimeInterval(headpatCooldown)
        let refresh = nextCafeStudentRefresh(from: lastHeadpatAt, server: server)
        return min(cooldownReady, refresh)
    }

    static func nextInviteAvailable(lastInviteAt: Date?) -> Date? {
        lastInviteAt?.addingTimeInterval(inviteCooldown)
    }

    static func localCafeStudentRefreshTimes(
        server: BaServer,
        reference: Date = Date(),
        localTimeZone: TimeZone = .current
    ) -> String {
        cafeStudentRefreshHours
            .compactMap { serverDate(hour: $0, server: server, reference: reference) }
            .map { BaDisplayFormatters.clockTime($0, timeZone: localTimeZone) }
            .joined(separator: " / ")
    }

    static func localCafeStudentRefreshSlots(
        server: BaServer,
        reference: Date = Date(),
        localTimeZone: TimeZone = .current
    ) -> [BaCafeRefreshSlot] {
        cafeStudentRefreshHours.enumerated().map { index, hour in
            let localDate = serverDate(hour: hour, server: server, reference: reference) ?? reference
            return BaCafeRefreshSlot(
                id: index + 1,
                localClockTime: BaDisplayFormatters.clockTime(localDate, timeZone: localTimeZone),
                nextAt: nextServerRefresh(hour: hour, from: reference, server: server)
            )
        }
    }

    static func localArenaRefreshTime(
        server: BaServer,
        reference: Date = Date(),
        localTimeZone: TimeZone = .current
    ) -> String {
        guard let date = serverDate(hour: arenaRefreshHour, server: server, reference: reference) else {
            return "--:--"
        }
        return BaDisplayFormatters.clockTime(date, timeZone: localTimeZone)
    }

    private static func serverDate(hour: Int, server: BaServer, reference: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = server.timeZone
        let start = calendar.startOfDay(for: reference)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start)
    }

    private static func nextServerRefresh(hour: Int, from date: Date, server: BaServer) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = server.timeZone
        let start = calendar.startOfDay(for: date)
        let today = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start) ?? start
        if date < today {
            return today
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

nonisolated struct BaCafeRefreshSlot: Identifiable, Equatable, Hashable {
    let id: Int
    let localClockTime: String
    let nextAt: Date
}

nonisolated enum BaDisplayFormatters {
    private static let formatterLock = NSLock()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    private static let syncFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }()

    private static let syncMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func dateTime(_ date: Date, server: BaServer? = nil) -> String {
        format(date, using: dateFormatter, timeZone: server?.timeZone ?? .current)
    }

    static func syncTime(_ date: Date, includingSeconds: Bool = true) -> String {
        let formatter = includingSeconds ? syncFormatter : syncMinuteFormatter
        return format(date, using: formatter, timeZone: .current)
    }

    static func clockTime(_ date: Date, timeZone: TimeZone = .current) -> String {
        format(date, using: clockFormatter, timeZone: timeZone)
    }

    private static func format(_ date: Date, using formatter: DateFormatter, timeZone: TimeZone) -> String {
        formatterLock.lock()
        defer { formatterLock.unlock() }
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    static func compactRemaining(
        until target: Date,
        now: Date = Date(),
        includingSeconds: Bool = true
    ) -> String {
        compactDuration(max(target.timeIntervalSince(now), 0), includingSeconds: includingSeconds)
    }

    static func compactDuration(_ interval: TimeInterval, includingSeconds: Bool = true) -> String {
        if includingSeconds == false {
            return compactMinuteDuration(interval)
        }
        var seconds = Int(ceil(max(interval, 0)))
        let days = seconds / 86400
        seconds %= 86400
        let hours = seconds / 3600
        seconds %= 3600
        let minutes = seconds / 60
        seconds %= 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if seconds > 0 || parts.isEmpty { parts.append("\(seconds)s") }
        return parts.joined(separator: " ")
    }

    static func timelineDetail(
        start: Date,
        end: Date,
        now: Date = Date(),
        includingSeconds: Bool = true
    ) -> String {
        if now < start {
            return String(
                format: BaL10n.string("ba.timeline.remaining.startsIn.format"),
                compactRemaining(until: start, now: now, includingSeconds: includingSeconds)
            )
        }
        if now < end {
            return String(
                format: BaL10n.string("ba.timeline.remaining.endsIn.format"),
                compactRemaining(until: end, now: now, includingSeconds: includingSeconds)
            )
        }
        return BaL10n.string("ba.timeline.remaining.ended")
    }

    private static func compactMinuteDuration(_ interval: TimeInterval) -> String {
        var minutesTotal = Int(ceil(max(interval, 0) / 60))
        let days = minutesTotal / 1440
        minutesTotal %= 1440
        let hours = minutesTotal / 60
        let minutes = minutesTotal % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes)m") }
        return parts.joined(separator: " ")
    }
}
