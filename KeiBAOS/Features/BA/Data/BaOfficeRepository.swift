//
//  BaOfficeRepository.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaOfficeRepository {
    func snapshot(settings: BaAppSettings, now: Date = Date()) -> BaOfficeSnapshot {
        let apSnapshot = apSnapshot(settings: settings, now: now)
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
        let cafeActions = cafeActionSnapshots(
            headpatAvailable: headpatAvailable,
            invite1Available: invite1Available,
            invite2Available: invite2Available,
            now: now
        )

        return BaOfficeSnapshot(
            nickname: settings.nickname,
            teacherSuffix: String(localized: "ba.office.nickname.suffix"),
            friendCode: settings.friendCode,
            server: settings.server.title,
            apCurrent: apSnapshot.apCurrent,
            apLimit: apSnapshot.apLimit,
            apCurrentLimit: apSnapshot.apCurrentLimit,
            apRemaining: apSnapshot.apRemaining,
            apNext: apSnapshot.apNext,
            apFullRemain: apSnapshot.apFullRemain,
            apSyncAt: apSnapshot.apSyncAt,
            apFullAt: apSnapshot.apFullAt,
            cafeApCurrent: "\(BaTimeMath.displayAP(cafeAP))",
            cafeApLimit: "\(cafeLimit)",
            cafeLevel: "Lv\(settings.cafeLevel)",
            cafeVisitRefresh: BaDisplayFormatters.compactRemaining(
                until: visitRefresh,
                now: now,
                includingSeconds: false
            ),
            cafeVisitDetail: String(
                format: String(localized: "ba.cafe.metric.visit.detail.format"),
                BaTimeMath.localCafeStudentRefreshTimes(server: settings.server, reference: now)
            ),
            tacticalRefresh: BaDisplayFormatters.compactRemaining(
                until: tacticalRefresh,
                now: now,
                includingSeconds: false
            ),
            tacticalRefreshDetail: String(
                format: String(localized: "ba.cafe.metric.tactical.detail.format"),
                BaTimeMath.localArenaRefreshTime(server: settings.server, reference: now)
            ),
            headpatRemain: cooldownText(availableAt: headpatAvailable, now: now),
            headpatDetail: cooldownDetail(availableAt: headpatAvailable, now: now),
            cafeActions: cafeActions
        )
    }

    func apSnapshot(settings: BaAppSettings, now: Date = Date()) -> BaOfficeAPSnapshot {
        let currentAP = BaTimeMath.currentAP(settings: settings, now: now)
        let apLimit = min(max(settings.apLimit, 0), BaTimeMath.apLimitMax)
        let isAPRecovering = apLimit > 0 && currentAP < Double(apLimit)
        let nextAP = BaTimeMath.nextAPPointAt(settings: settings, now: now)
        let fullAP = BaTimeMath.apFullAt(settings: settings, now: now)
        let displayedAP = "\(BaTimeMath.displayAP(currentAP))"
        let displayedLimit = "\(apLimit)"

        return BaOfficeAPSnapshot(
            apCurrent: displayedAP,
            apLimit: displayedLimit,
            apCurrentLimit: String(
                format: String(localized: "ba.office.ap.currentLimit.format"),
                displayedAP,
                displayedLimit
            ),
            apRemaining: apRemainingText(currentAP: currentAP, apLimit: apLimit),
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
                ? BaDisplayFormatters.dateTime(fullAP)
                : String(localized: "ba.office.ap.full.ready")
        )
    }

    private func apRemainingText(currentAP: Double, apLimit: Int) -> String {
        let remaining = max(apLimit - BaTimeMath.displayAP(currentAP), 0)
        guard remaining > 0 else {
            return String(localized: "ba.office.ap.remaining.ready")
        }
        return String(
            format: String(localized: "ba.office.ap.remaining.format"),
            "\(remaining)"
        )
    }

    private func cafeActionSnapshots(
        headpatAvailable: Date?,
        invite1Available: Date?,
        invite2Available: Date?,
        now: Date
    ) -> [BaCafeActionSnapshot] {
        [
            BaCafeActionSeed(
                kind: .headpat,
                title: String(localized: "ba.cafe.action.headpat"),
                asset: .dailyReward,
                tintName: "green",
                availableAt: headpatAvailable
            ),
            BaCafeActionSeed(
                kind: .inviteTicket1,
                title: String(localized: "ba.cafe.action.invite1"),
                asset: .cafeCoupon,
                tintName: "violet",
                availableAt: invite1Available
            ),
            BaCafeActionSeed(
                kind: .inviteTicket2,
                title: String(localized: "ba.cafe.action.invite2"),
                asset: .cafeCoupon,
                tintName: "violet",
                availableAt: invite2Available
            ),
        ].map { cafeAction(seed: $0, now: now) }
    }

    private func cafeAction(seed: BaCafeActionSeed, now: Date) -> BaCafeActionSnapshot {
        BaCafeActionSnapshot(
            kind: seed.kind,
            title: seed.title,
            value: cooldownText(availableAt: seed.availableAt, now: now),
            detail: cooldownDetail(availableAt: seed.availableAt, now: now),
            asset: seed.asset,
            tintName: seed.tintName,
            isReady: seed.availableAt.map { $0 <= now } ?? true
        )
    }

    private func cooldownText(availableAt: Date?, now: Date) -> String {
        guard let availableAt, availableAt > now else {
            return String(localized: "ba.cafe.action.ready.value")
        }
        return BaDisplayFormatters.compactRemaining(until: availableAt, now: now, includingSeconds: false)
    }

    private func cooldownDetail(availableAt: Date?, now: Date) -> String {
        guard let availableAt, availableAt > now else {
            return String(localized: "ba.cafe.action.ready")
        }
        return String(
            format: String(localized: "ba.cafe.action.availableAt.format"),
            BaDisplayFormatters.dateTime(availableAt)
        )
    }
}

private struct BaCafeActionSeed {
    let kind: BaCafeActionKind
    let title: String
    let asset: BaGameAsset
    let tintName: String
    let availableAt: Date?
}
