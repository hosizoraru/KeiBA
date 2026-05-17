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
            BaL10n.string("ba.calendar.kind.event")
        case 15:
            BaL10n.string("ba.calendar.kind.totalGrandAssault")
        case 16:
            BaL10n.string("ba.calendar.kind.doubleRewards")
        case 17:
            BaL10n.string("ba.calendar.kind.tower")
        case 18:
            BaL10n.string("ba.calendar.kind.guideMission")
        case 19:
            BaL10n.string("ba.calendar.kind.tacticalTest")
        case 31:
            BaL10n.string("ba.calendar.kind.other")
        default:
            fallback.isEmpty ? BaL10n.string("ba.calendar.kind.other") : fallback
        }
    }

    static func poolTagTitle(tagId: Int, fallback: String) -> String {
        switch tagId {
        case 5:
            BaL10n.string("ba.pool.tag.permanent")
        case 6:
            BaL10n.string("ba.pool.tag.limited")
        case 7:
            BaL10n.string("ba.pool.tag.fesLimited")
        case 8:
            BaL10n.string("ba.pool.tag.collab")
        case 9:
            BaL10n.string("ba.pool.tag.rerun")
        case 92:
            BaL10n.string("ba.pool.tag.recollection")
        default:
            fallback.isEmpty ? BaL10n.string("ba.pool.tag.recruitment") : fallback
        }
    }
}
