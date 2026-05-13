//
//  BaModels.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum BaDesign {
    static let blue = Color(red: 0.18, green: 0.50, blue: 0.95)
    static let green = Color(red: 0.12, green: 0.76, blue: 0.42)
    static let pink = Color(red: 0.93, green: 0.36, blue: 0.68)
    static let violet = Color(red: 0.54, green: 0.42, blue: 0.92)
    static let amber = Color(red: 0.94, green: 0.58, blue: 0.18)
    static let cyan = Color(red: 0.16, green: 0.64, blue: 0.86)
}

struct BaOfficeSnapshot {
    let nickname: String
    let teacherSuffix: String
    let friendCode: String
    let server: String
    let apCurrent: String
    let apLimit: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
    let cafeApCurrent: String
    let cafeApLimit: String
    let cafeLevel: String
    let cafeVisitRefresh: String
    let tacticalRefresh: String

    static var preview: BaOfficeSnapshot {
        BaOfficeSnapshot(
            nickname: String(localized: "ba.office.nickname.value"),
            teacherSuffix: String(localized: "ba.office.nickname.suffix"),
            friendCode: String(localized: "ba.office.friendCode.value"),
            server: String(localized: "ba.office.server.value"),
            apCurrent: "1",
            apLimit: "240",
            apNext: String(localized: "ba.office.ap.next.value"),
            apFullRemain: String(localized: "ba.office.ap.fullRemain.value"),
            apSyncAt: String(localized: "ba.office.ap.syncAt.value"),
            apFullAt: String(localized: "ba.office.ap.fullAt.value"),
            cafeApCurrent: "462",
            cafeApLimit: "740",
            cafeLevel: "Lv10",
            cafeVisitRefresh: String(localized: "ba.cafe.visitRefresh.value"),
            tacticalRefresh: String(localized: "ba.cafe.tacticalRefresh.value")
        )
    }
}

struct BaCatalogEntry: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    static var preview: [BaCatalogEntry] {
        [
            BaCatalogEntry(
                id: "students",
                title: String(localized: "ba.catalog.students.title"),
                detail: String(localized: "ba.catalog.students.detail"),
                systemImage: "person.3.fill",
                tint: BaDesign.blue
            ),
            BaCatalogEntry(
                id: "npc",
                title: String(localized: "ba.catalog.npc.title"),
                detail: String(localized: "ba.catalog.npc.detail"),
                systemImage: "person.crop.circle.badge.questionmark.fill",
                tint: BaDesign.violet
            ),
            BaCatalogEntry(
                id: "satellite",
                title: String(localized: "ba.catalog.satellite.title"),
                detail: String(localized: "ba.catalog.satellite.detail"),
                systemImage: "sparkles.rectangle.stack.fill",
                tint: BaDesign.cyan
            )
        ]
    }
}

enum BaQuickAction: String, CaseIterable, Identifiable {
    case notifications
    case edit
    case debug

    var id: Self { self }

    var title: String {
        switch self {
        case .notifications:
            String(localized: "ba.action.notifications.title")
        case .edit:
            String(localized: "ba.action.edit.title")
        case .debug:
            String(localized: "ba.action.debug.title")
        }
    }

    var message: String {
        switch self {
        case .notifications:
            String(localized: "ba.action.notifications.message")
        case .edit:
            String(localized: "ba.action.edit.message")
        case .debug:
            String(localized: "ba.action.debug.message")
        }
    }

    var systemImage: String {
        switch self {
        case .notifications:
            "bell.fill"
        case .edit:
            "square.and.pencil"
        case .debug:
            "flask.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notifications:
            BaDesign.blue
        case .edit:
            BaDesign.violet
        case .debug:
            BaDesign.amber
        }
    }
}
