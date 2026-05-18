//
//  BaWatchDashboardSnapshot.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated struct BaWatchDashboardSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let applicationContextKey = "ba.watch.dashboardSnapshot.v1"

    var schemaVersion: Int
    var sourceUpdatedAt: Date
    var generatedAt: Date
    var serverName: String
    var teacherName: String
    var friendCode: String
    var dutyStudentName: String?
    var dutyStudentAvatarURLString: String?
    var apBaseValue: Double
    var apLimit: Int
    var apRegenBaseAt: Date
    var apNotificationsEnabled: Bool
    var apNotifyThreshold: Int
    var cafeLevel: Int
    var cafeAPBaseValue: Double
    var cafeStorageBaseAt: Date
    var cafeAPNotificationsEnabled: Bool
    var cafeAPNotifyThreshold: Int
    var nextHeadpatAvailableAt: Date?
    var nextInviteTicket1AvailableAt: Date?
    var nextInviteTicket2AvailableAt: Date?
    var activityNotificationsEnabled: Bool
    var poolNotificationsEnabled: Bool
    var favoriteStudentCount: Int

    init(
        schemaVersion: Int = currentSchemaVersion,
        sourceUpdatedAt: Date,
        generatedAt: Date = Date(),
        serverName: String,
        teacherName: String,
        friendCode: String,
        dutyStudentName: String? = nil,
        dutyStudentAvatarURLString: String? = nil,
        apBaseValue: Double,
        apLimit: Int,
        apRegenBaseAt: Date,
        apNotificationsEnabled: Bool,
        apNotifyThreshold: Int,
        cafeLevel: Int,
        cafeAPBaseValue: Double,
        cafeStorageBaseAt: Date,
        cafeAPNotificationsEnabled: Bool,
        cafeAPNotifyThreshold: Int,
        nextHeadpatAvailableAt: Date? = nil,
        nextInviteTicket1AvailableAt: Date? = nil,
        nextInviteTicket2AvailableAt: Date? = nil,
        activityNotificationsEnabled: Bool,
        poolNotificationsEnabled: Bool,
        favoriteStudentCount: Int
    ) {
        self.schemaVersion = schemaVersion
        self.sourceUpdatedAt = sourceUpdatedAt
        self.generatedAt = generatedAt
        self.serverName = serverName
        self.teacherName = teacherName
        self.friendCode = friendCode
        self.dutyStudentName = dutyStudentName
        self.dutyStudentAvatarURLString = dutyStudentAvatarURLString
        self.apBaseValue = BaWatchTimeMath.normalizedAP(apBaseValue)
        self.apLimit = min(max(apLimit, 0), BaWatchTimeMath.apLimitMax)
        self.apRegenBaseAt = apRegenBaseAt
        self.apNotificationsEnabled = apNotificationsEnabled
        self.apNotifyThreshold = min(max(apNotifyThreshold, 0), BaWatchTimeMath.apMax)
        self.cafeLevel = min(max(cafeLevel, 1), BaWatchTimeMath.cafeLevelMax)
        self.cafeAPBaseValue = BaWatchTimeMath.normalizedAP(cafeAPBaseValue)
        self.cafeStorageBaseAt = cafeStorageBaseAt
        self.cafeAPNotificationsEnabled = cafeAPNotificationsEnabled
        self.cafeAPNotifyThreshold = min(max(cafeAPNotifyThreshold, 0), BaWatchTimeMath.apMax)
        self.nextHeadpatAvailableAt = nextHeadpatAvailableAt
        self.nextInviteTicket1AvailableAt = nextInviteTicket1AvailableAt
        self.nextInviteTicket2AvailableAt = nextInviteTicket2AvailableAt
        self.activityNotificationsEnabled = activityNotificationsEnabled
        self.poolNotificationsEnabled = poolNotificationsEnabled
        self.favoriteStudentCount = max(favoriteStudentCount, 0)
    }

    func currentAP(at date: Date = Date()) -> Int {
        BaWatchTimeMath.displayAP(
            BaWatchTimeMath.currentAP(
                baseAP: apBaseValue,
                apLimit: apLimit,
                apRegenBaseAt: apRegenBaseAt,
                now: date
            )
        )
    }

    func apFullAt(from date: Date = Date()) -> Date? {
        BaWatchTimeMath.apFullAt(
            baseAP: apBaseValue,
            apLimit: apLimit,
            apRegenBaseAt: apRegenBaseAt,
            now: date
        )
    }

    func currentCafeAP(at date: Date = Date()) -> Int {
        BaWatchTimeMath.displayAP(
            BaWatchTimeMath.currentCafeAP(
                baseAP: cafeAPBaseValue,
                cafeLevel: cafeLevel,
                cafeStorageBaseAt: cafeStorageBaseAt,
                now: date
            )
        )
    }

    var cafeAPCapacity: Int {
        BaWatchTimeMath.cafeDailyCapacity(level: cafeLevel)
    }

    func cafeAPFullAt(from date: Date = Date()) -> Date? {
        BaWatchTimeMath.cafeFullAt(
            baseAP: cafeAPBaseValue,
            cafeLevel: cafeLevel,
            cafeStorageBaseAt: cafeStorageBaseAt,
            now: date
        )
    }
}

nonisolated enum BaWatchDashboardSnapshotCoding {
    static func encode(_ snapshot: BaWatchDashboardSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> BaWatchDashboardSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BaWatchDashboardSnapshot.self, from: data)
    }
}

nonisolated enum BaWatchTimeMath {
    static let apMax = 999
    static let apLimitMax = 240
    static let cafeLevelMax = 10
    static let apRegenInterval: TimeInterval = 6 * 60
    static let cafeHourlyInterval: TimeInterval = 60 * 60
    static let cafeDailyAPByLevel = [92, 152, 222, 302, 390, 460, 530, 600, 570, 740]

    static func displayAP(_ value: Double) -> Int {
        Int(max(value, 0))
    }

    static func normalizedAP(_ value: Double) -> Double {
        let clamped = min(max(value, 0), Double(apMax))
        return (clamped * 1000).rounded() / 1000
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

    static func nextAPPointAt(
        baseAP: Double,
        apLimit: Int,
        apRegenBaseAt: Date,
        now: Date = Date()
    ) -> Date? {
        let limit = min(max(apLimit, 0), apLimitMax)
        guard limit > 0, currentAP(baseAP: baseAP, apLimit: apLimit, apRegenBaseAt: apRegenBaseAt, now: now) < Double(limit) else {
            return nil
        }
        let elapsed = max(now.timeIntervalSince(apRegenBaseAt), 0)
        let remainder = elapsed.truncatingRemainder(dividingBy: apRegenInterval)
        let untilNext = remainder == 0 ? apRegenInterval : apRegenInterval - remainder
        return now.addingTimeInterval(untilNext)
    }

    static func apFullAt(
        baseAP: Double,
        apLimit: Int,
        apRegenBaseAt: Date,
        now: Date = Date()
    ) -> Date? {
        let limit = min(max(apLimit, 0), apLimitMax)
        guard limit > 0 else { return nil }
        let current = currentAP(baseAP: baseAP, apLimit: apLimit, apRegenBaseAt: apRegenBaseAt, now: now)
        guard current < Double(limit) else { return now }
        let pointsNeeded = max(Int(ceil(Double(limit) - current)), 0)
        guard pointsNeeded > 0,
              let nextPoint = nextAPPointAt(baseAP: baseAP, apLimit: apLimit, apRegenBaseAt: apRegenBaseAt, now: now)
        else {
            return now
        }
        return nextPoint.addingTimeInterval(TimeInterval(pointsNeeded - 1) * apRegenInterval)
    }

    static func cafeDailyCapacity(level: Int) -> Int {
        cafeDailyAPByLevel[min(max(level, 1), cafeLevelMax) - 1]
    }

    static func cafeHourlyGain(level: Int) -> Double {
        Double(cafeDailyCapacity(level: level)) / 24
    }

    static func currentCafeAP(
        baseAP: Double,
        cafeLevel: Int,
        cafeStorageBaseAt: Date,
        now: Date = Date()
    ) -> Double {
        let elapsed = max(now.timeIntervalSince(cafeStorageBaseAt), 0)
        let gained = floor(elapsed / cafeHourlyInterval) * cafeHourlyGain(level: cafeLevel)
        return min(normalizedAP(baseAP) + gained, Double(cafeDailyCapacity(level: cafeLevel)))
    }

    static func cafeFullAt(
        baseAP: Double,
        cafeLevel: Int,
        cafeStorageBaseAt: Date,
        now: Date = Date()
    ) -> Date? {
        let capacity = Double(cafeDailyCapacity(level: cafeLevel))
        let current = currentCafeAP(
            baseAP: baseAP,
            cafeLevel: cafeLevel,
            cafeStorageBaseAt: cafeStorageBaseAt,
            now: now
        )
        guard current < capacity else { return now }
        let hourlyGain = cafeHourlyGain(level: cafeLevel)
        guard hourlyGain > 0 else { return nil }
        let elapsed = max(now.timeIntervalSince(cafeStorageBaseAt), 0)
        let remainder = elapsed.truncatingRemainder(dividingBy: cafeHourlyInterval)
        let untilNext = remainder == 0 ? cafeHourlyInterval : cafeHourlyInterval - remainder
        let ticksNeeded = max(Int(ceil((capacity - current) / hourlyGain)), 1)
        return now.addingTimeInterval(untilNext + TimeInterval(ticksNeeded - 1) * cafeHourlyInterval)
    }
}
