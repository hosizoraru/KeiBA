//
//  BaOfficeRepository.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaOfficeRepository {
    func snapshot(settings: BaAppSettings, now: Date = Date()) -> BaOfficeSnapshot {
        let currentAP = BaTimeMath.currentAP(settings: settings, now: now)
        let nextAP = BaTimeMath.nextAPPointAt(settings: settings, now: now)
        let fullAP = BaTimeMath.apFullAt(settings: settings, now: now)
        let cafeAP = BaTimeMath.currentCafeAP(settings: settings, now: now)
        let cafeLimit = BaTimeMath.cafeDailyCapacity(level: settings.cafeLevel)
        let visitRefresh = BaTimeMath.nextCafeStudentRefresh(from: now, server: settings.server)
        let tacticalRefresh = BaTimeMath.nextArenaRefresh(from: now, server: settings.server)
        let headpatAvailable = BaTimeMath.nextHeadpatAvailable(
            lastHeadpatAt: settings.lastHeadpatAt,
            server: settings.server
        )
        let inviteAvailable = BaTimeMath.nextInviteAvailable(lastInviteAt: settings.lastInviteTicketAt)

        return BaOfficeSnapshot(
            nickname: settings.nickname,
            teacherSuffix: String(localized: "ba.office.nickname.suffix"),
            friendCode: settings.friendCode,
            server: settings.server.title,
            apCurrent: "\(BaTimeMath.displayAP(currentAP))",
            apLimit: "\(settings.apLimit)",
            apNext: BaDisplayFormatters.compactRemaining(until: nextAP, now: now),
            apFullRemain: BaDisplayFormatters.compactRemaining(until: fullAP, now: now),
            apSyncAt: BaDisplayFormatters.syncTime(settings.apRegenBaseAt),
            apFullAt: BaDisplayFormatters.dateTime(fullAP, server: settings.server),
            cafeApCurrent: "\(BaTimeMath.displayAP(cafeAP))",
            cafeApLimit: "\(cafeLimit)",
            cafeLevel: "Lv\(settings.cafeLevel)",
            cafeVisitRefresh: BaDisplayFormatters.compactRemaining(until: visitRefresh, now: now),
            tacticalRefresh: BaDisplayFormatters.compactRemaining(until: tacticalRefresh, now: now),
            headpatRemain: cooldownText(availableAt: headpatAvailable, now: now),
            headpatDetail: cooldownDetail(availableAt: headpatAvailable, now: now, server: settings.server),
            inviteRemain: cooldownText(availableAt: inviteAvailable, now: now),
            inviteDetail: cooldownDetail(availableAt: inviteAvailable, now: now, server: settings.server)
        )
    }

    private func cooldownText(availableAt: Date?, now: Date) -> String {
        guard let availableAt, availableAt > now else {
            return String(localized: "ba.cafe.action.ready.value")
        }
        return BaDisplayFormatters.compactRemaining(until: availableAt, now: now)
    }

    private func cooldownDetail(availableAt: Date?, now: Date, server: BaServer) -> String {
        guard let availableAt, availableAt > now else {
            return String(localized: "ba.cafe.action.ready")
        }
        return String(
            format: String(localized: "ba.cafe.action.availableAt.format"),
            BaDisplayFormatters.dateTime(availableAt, server: server)
        )
    }
}
