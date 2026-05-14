//
//  BaTimeMath.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

enum BaTimeMath {
    static let apMax = 999
    static let apLimitMax = 240
    static let apRegenInterval: TimeInterval = 6 * 60
    static let cafeHourlyInterval: TimeInterval = 60 * 60
    static let cafeStudentRefreshInterval: TimeInterval = 12 * 60 * 60
    static let arenaRefreshInterval: TimeInterval = 24 * 60 * 60
    static let headpatCooldown: TimeInterval = 3 * 60 * 60
    static let inviteCooldown: TimeInterval = 20 * 60 * 60
    static let cafeDailyAPByLevel = [92, 152, 222, 302, 390, 460, 530, 600, 570, 740]

    static func displayAP(_ value: Double) -> Int {
        Int(max(value, 0))
    }

    static func normalizedAP(_ value: Double) -> Double {
        let clamped = min(max(value, 0), Double(apMax))
        return (clamped * 1000).rounded() / 1000
    }

    static func currentAP(settings: BaAppSettings, now: Date = Date()) -> Double {
        let elapsed = max(now.timeIntervalSince(settings.apRegenBaseAt), 0)
        let recovered = floor(elapsed / apRegenInterval)
        let limit = Double(min(max(settings.apLimit, 0), apLimitMax))
        return normalizedAP(min(settings.apCurrent + recovered, limit))
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

    static func nextCafeStudentRefresh(from date: Date, server: BaServer) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = server.timeZone
        let start = calendar.startOfDay(for: date)
        let refresh4 = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: start) ?? start
        let refresh16 = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: start) ?? start
        if date < refresh4 {
            return refresh4
        }
        if date < refresh16 {
            return refresh16
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return calendar.date(bySettingHour: 4, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    static func nextArenaRefresh(from date: Date, server: BaServer) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = server.timeZone
        let start = calendar.startOfDay(for: date)
        let today = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: start) ?? start
        if date < today {
            return today
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow) ?? tomorrow
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
}

enum BaDisplayFormatters {
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

    static func dateTime(_ date: Date, server: BaServer? = nil) -> String {
        if let server {
            dateFormatter.timeZone = server.timeZone
        } else {
            dateFormatter.timeZone = .current
        }
        return dateFormatter.string(from: date)
    }

    static func syncTime(_ date: Date) -> String {
        syncFormatter.timeZone = .current
        return syncFormatter.string(from: date)
    }

    static func compactRemaining(until target: Date, now: Date = Date()) -> String {
        compactDuration(max(target.timeIntervalSince(now), 0))
    }

    static func compactDuration(_ interval: TimeInterval) -> String {
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

    static func timelineDetail(start: Date, end: Date, now: Date = Date()) -> String {
        if now < start {
            return String(
                format: String(localized: "ba.timeline.remaining.startsIn.format"),
                compactRemaining(until: start, now: now)
            )
        }
        if now < end {
            return String(
                format: String(localized: "ba.timeline.remaining.endsIn.format"),
                compactRemaining(until: end, now: now)
            )
        }
        return String(localized: "ba.timeline.remaining.ended")
    }
}
