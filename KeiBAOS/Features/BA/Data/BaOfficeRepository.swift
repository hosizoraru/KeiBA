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
        let apLimit = Double(min(max(settings.apLimit, 0), BaTimeMath.apLimitMax))
        let isAPRecovering = apLimit > 0 && currentAP < apLimit
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
        let invite1Available = BaTimeMath.nextInviteAvailable(
            lastInviteAt: settings.lastInviteTicket1At ?? settings.lastInviteTicketAt
        )
        let invite2Available = BaTimeMath.nextInviteAvailable(lastInviteAt: settings.lastInviteTicket2At)
        let cafeActions = [
            cafeAction(
                kind: .headpat,
                title: String(localized: "ba.cafe.action.headpat"),
                asset: .dailyReward,
                tintName: "green",
                availableAt: headpatAvailable,
                now: now,
                server: settings.server
            ),
            cafeAction(
                kind: .inviteTicket1,
                title: String(localized: "ba.cafe.action.invite1"),
                asset: .cafeCoupon,
                tintName: "violet",
                availableAt: invite1Available,
                now: now,
                server: settings.server
            ),
            cafeAction(
                kind: .inviteTicket2,
                title: String(localized: "ba.cafe.action.invite2"),
                asset: .cafeCoupon,
                tintName: "violet",
                availableAt: invite2Available,
                now: now,
                server: settings.server
            ),
        ]

        return BaOfficeSnapshot(
            nickname: settings.nickname,
            teacherSuffix: String(localized: "ba.office.nickname.suffix"),
            friendCode: settings.friendCode,
            server: settings.server.title,
            apCurrent: "\(BaTimeMath.displayAP(currentAP))",
            apLimit: "\(settings.apLimit)",
            apNext: isAPRecovering
                ? BaDisplayFormatters.compactRemaining(until: nextAP, now: now)
                : String(localized: "ba.office.ap.paused.value"),
            apFullRemain: isAPRecovering
                ? BaDisplayFormatters.compactRemaining(until: fullAP, now: now, includingSeconds: false)
                : String(localized: "ba.office.ap.full.ready"),
            apSyncAt: BaDisplayFormatters.syncTime(
                settings.apSyncAt ?? settings.apRegenBaseAt,
                includingSeconds: false
            ),
            apFullAt: isAPRecovering
                ? BaDisplayFormatters.dateTime(fullAP, server: settings.server)
                : String(localized: "ba.office.ap.full.ready"),
            cafeApCurrent: "\(BaTimeMath.displayAP(cafeAP))",
            cafeApLimit: "\(cafeLimit)",
            cafeLevel: "Lv\(settings.cafeLevel)",
            cafeVisitRefresh: BaDisplayFormatters.compactRemaining(
                until: visitRefresh,
                now: now,
                includingSeconds: false
            ),
            tacticalRefresh: BaDisplayFormatters.compactRemaining(
                until: tacticalRefresh,
                now: now,
                includingSeconds: false
            ),
            headpatRemain: cooldownText(availableAt: headpatAvailable, now: now),
            headpatDetail: cooldownDetail(availableAt: headpatAvailable, now: now, server: settings.server),
            cafeActions: cafeActions
        )
    }

    private func cafeAction(
        kind: BaCafeActionKind,
        title: String,
        asset: BaGameAsset,
        tintName: String,
        availableAt: Date?,
        now: Date,
        server: BaServer
    ) -> BaCafeActionSnapshot {
        BaCafeActionSnapshot(
            kind: kind,
            title: title,
            value: cooldownText(availableAt: availableAt, now: now),
            detail: cooldownDetail(availableAt: availableAt, now: now, server: server),
            asset: asset,
            tintName: tintName,
            isReady: availableAt.map { $0 <= now } ?? true
        )
    }

    private func cooldownText(availableAt: Date?, now: Date) -> String {
        guard let availableAt, availableAt > now else {
            return String(localized: "ba.cafe.action.ready.value")
        }
        return BaDisplayFormatters.compactRemaining(until: availableAt, now: now, includingSeconds: false)
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
