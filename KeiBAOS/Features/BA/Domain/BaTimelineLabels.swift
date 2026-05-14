//
//  BaTimelineLabels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

enum BaTimelineLabels {
    static func calendarKindTitle(kindId: Int, fallback: String) -> String {
        switch kindId {
        case 14:
            String(localized: "ba.calendar.kind.event")
        case 15:
            String(localized: "ba.calendar.kind.totalGrandAssault")
        case 16:
            String(localized: "ba.calendar.kind.doubleRewards")
        case 17:
            String(localized: "ba.calendar.kind.tower")
        case 18:
            String(localized: "ba.calendar.kind.guideMission")
        case 19:
            String(localized: "ba.calendar.kind.tacticalTest")
        case 31:
            String(localized: "ba.calendar.kind.other")
        default:
            fallback.isEmpty ? String(localized: "ba.calendar.kind.other") : fallback
        }
    }

    static func poolTagTitle(tagId: Int, fallback: String) -> String {
        switch tagId {
        case 5:
            String(localized: "ba.pool.tag.permanent")
        case 6:
            String(localized: "ba.pool.tag.limited")
        case 7:
            String(localized: "ba.pool.tag.fesLimited")
        case 8:
            String(localized: "ba.pool.tag.collab")
        case 9:
            String(localized: "ba.pool.tag.rerun")
        case 92:
            String(localized: "ba.pool.tag.recollection")
        default:
            fallback.isEmpty ? String(localized: "ba.pool.tag.recruitment") : fallback
        }
    }
}
