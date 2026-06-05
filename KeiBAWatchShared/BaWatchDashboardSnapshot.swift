//
//  BaWatchDashboardSnapshot.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated struct BaWatchDashboardSnapshot: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 5
    static let applicationContextKey = "ba.watch.dashboardSnapshot.v1"

    var schemaVersion: Int
    var sourceUpdatedAt: Date
    var generatedAt: Date
    var officeName: String
    var officeShortName: String
    var serverName: String
    var teacherName: String
    var friendCode: String
    var dutyStudentName: String?
    var dutyStudentAvatarURLString: String?
    var dutyStudentAvatarImageData: Data?
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
    var timeline: BaTimelineGlanceSnapshot

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case sourceUpdatedAt
        case generatedAt
        case officeName
        case officeShortName
        case serverName
        case teacherName
        case friendCode
        case dutyStudentName
        case dutyStudentAvatarURLString
        case dutyStudentAvatarImageData
        case apBaseValue
        case apLimit
        case apRegenBaseAt
        case apNotificationsEnabled
        case apNotifyThreshold
        case cafeLevel
        case cafeAPBaseValue
        case cafeStorageBaseAt
        case cafeAPNotificationsEnabled
        case cafeAPNotifyThreshold
        case nextHeadpatAvailableAt
        case nextInviteTicket1AvailableAt
        case nextInviteTicket2AvailableAt
        case activityNotificationsEnabled
        case poolNotificationsEnabled
        case favoriteStudentCount
        case timeline
    }

    init(
        schemaVersion: Int = currentSchemaVersion,
        sourceUpdatedAt: Date,
        generatedAt: Date = Date(),
        officeName: String,
        officeShortName: String? = nil,
        serverName: String,
        teacherName: String,
        friendCode: String,
        dutyStudentName: String? = nil,
        dutyStudentAvatarURLString: String? = nil,
        dutyStudentAvatarImageData: Data? = nil,
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
        favoriteStudentCount: Int,
        timeline: BaTimelineGlanceSnapshot? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.sourceUpdatedAt = sourceUpdatedAt
        self.generatedAt = generatedAt
        self.officeName = officeName
        self.officeShortName = officeShortName ?? Self.shortOfficeNameFallback(from: officeName)
        self.serverName = serverName
        self.teacherName = teacherName
        self.friendCode = friendCode
        self.dutyStudentName = dutyStudentName
        self.dutyStudentAvatarURLString = dutyStudentAvatarURLString
        self.dutyStudentAvatarImageData = dutyStudentAvatarImageData
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
        self.timeline = timeline ?? BaTimelineGlanceSnapshot.empty(generatedAt: generatedAt)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        sourceUpdatedAt = try container.decode(Date.self, forKey: .sourceUpdatedAt)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        officeName = try container.decodeIfPresent(String.self, forKey: .officeName) ??
            container.decode(String.self, forKey: .serverName)
        officeShortName = try container.decodeIfPresent(String.self, forKey: .officeShortName) ??
            Self.shortOfficeNameFallback(from: officeName)
        serverName = try container.decode(String.self, forKey: .serverName)
        teacherName = try container.decode(String.self, forKey: .teacherName)
        friendCode = try container.decode(String.self, forKey: .friendCode)
        dutyStudentName = try container.decodeIfPresent(String.self, forKey: .dutyStudentName)
        dutyStudentAvatarURLString = try container.decodeIfPresent(String.self, forKey: .dutyStudentAvatarURLString)
        dutyStudentAvatarImageData = try container.decodeIfPresent(Data.self, forKey: .dutyStudentAvatarImageData)
        apBaseValue = BaWatchTimeMath.normalizedAP(try container.decode(Double.self, forKey: .apBaseValue))
        apLimit = min(max(try container.decode(Int.self, forKey: .apLimit), 0), BaWatchTimeMath.apLimitMax)
        apRegenBaseAt = try container.decode(Date.self, forKey: .apRegenBaseAt)
        apNotificationsEnabled = try container.decode(Bool.self, forKey: .apNotificationsEnabled)
        apNotifyThreshold = min(max(try container.decode(Int.self, forKey: .apNotifyThreshold), 0), BaWatchTimeMath.apMax)
        cafeLevel = min(max(try container.decode(Int.self, forKey: .cafeLevel), 1), BaWatchTimeMath.cafeLevelMax)
        cafeAPBaseValue = BaWatchTimeMath.normalizedAP(try container.decode(Double.self, forKey: .cafeAPBaseValue))
        cafeStorageBaseAt = try container.decode(Date.self, forKey: .cafeStorageBaseAt)
        cafeAPNotificationsEnabled = try container.decode(Bool.self, forKey: .cafeAPNotificationsEnabled)
        cafeAPNotifyThreshold = min(max(try container.decode(Int.self, forKey: .cafeAPNotifyThreshold), 0), BaWatchTimeMath.apMax)
        nextHeadpatAvailableAt = try container.decodeIfPresent(Date.self, forKey: .nextHeadpatAvailableAt)
        nextInviteTicket1AvailableAt = try container.decodeIfPresent(Date.self, forKey: .nextInviteTicket1AvailableAt)
        nextInviteTicket2AvailableAt = try container.decodeIfPresent(Date.self, forKey: .nextInviteTicket2AvailableAt)
        activityNotificationsEnabled = try container.decode(Bool.self, forKey: .activityNotificationsEnabled)
        poolNotificationsEnabled = try container.decode(Bool.self, forKey: .poolNotificationsEnabled)
        favoriteStudentCount = max(try container.decode(Int.self, forKey: .favoriteStudentCount), 0)
        timeline = try container.decodeIfPresent(BaTimelineGlanceSnapshot.self, forKey: .timeline) ??
            BaTimelineGlanceSnapshot.empty(generatedAt: generatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(sourceUpdatedAt, forKey: .sourceUpdatedAt)
        try container.encode(generatedAt, forKey: .generatedAt)
        try container.encode(officeName, forKey: .officeName)
        try container.encode(officeShortName, forKey: .officeShortName)
        try container.encode(serverName, forKey: .serverName)
        try container.encode(teacherName, forKey: .teacherName)
        try container.encode(friendCode, forKey: .friendCode)
        try container.encodeIfPresent(dutyStudentName, forKey: .dutyStudentName)
        try container.encodeIfPresent(dutyStudentAvatarURLString, forKey: .dutyStudentAvatarURLString)
        try container.encodeIfPresent(dutyStudentAvatarImageData, forKey: .dutyStudentAvatarImageData)
        try container.encode(apBaseValue, forKey: .apBaseValue)
        try container.encode(apLimit, forKey: .apLimit)
        try container.encode(apRegenBaseAt, forKey: .apRegenBaseAt)
        try container.encode(apNotificationsEnabled, forKey: .apNotificationsEnabled)
        try container.encode(apNotifyThreshold, forKey: .apNotifyThreshold)
        try container.encode(cafeLevel, forKey: .cafeLevel)
        try container.encode(cafeAPBaseValue, forKey: .cafeAPBaseValue)
        try container.encode(cafeStorageBaseAt, forKey: .cafeStorageBaseAt)
        try container.encode(cafeAPNotificationsEnabled, forKey: .cafeAPNotificationsEnabled)
        try container.encode(cafeAPNotifyThreshold, forKey: .cafeAPNotifyThreshold)
        try container.encodeIfPresent(nextHeadpatAvailableAt, forKey: .nextHeadpatAvailableAt)
        try container.encodeIfPresent(nextInviteTicket1AvailableAt, forKey: .nextInviteTicket1AvailableAt)
        try container.encodeIfPresent(nextInviteTicket2AvailableAt, forKey: .nextInviteTicket2AvailableAt)
        try container.encode(activityNotificationsEnabled, forKey: .activityNotificationsEnabled)
        try container.encode(poolNotificationsEnabled, forKey: .poolNotificationsEnabled)
        try container.encode(favoriteStudentCount, forKey: .favoriteStudentCount)
        try container.encode(timeline, forKey: .timeline)
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

    private static func shortOfficeNameFallback(from officeName: String) -> String {
        if officeName.hasPrefix("Schale") {
            return "Schale"
        }
        if officeName.hasPrefix("シャーレ") {
            return "シャーレ"
        }
        return String(officeName.prefix(2))
    }
}

nonisolated enum BaWatchDashboardSnapshotCoding {
    // Reuse the encoder/decoder across calls. JSONEncoder is documented as
    // safe to use from multiple threads after initial configuration; we
    // never mutate either after this setup. The previous code paid the
    // configuration cost on every Watch sync (which can fire on every
    // settings/timeline change) and on every widget timeline build.
    private nonisolated static let sharedEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private nonisolated static let sharedDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func encode(_ snapshot: BaWatchDashboardSnapshot) throws -> Data {
        try sharedEncoder.encode(snapshot)
    }

    static func decode(_ data: Data) throws -> BaWatchDashboardSnapshot {
        try sharedDecoder.decode(BaWatchDashboardSnapshot.self, from: data)
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
