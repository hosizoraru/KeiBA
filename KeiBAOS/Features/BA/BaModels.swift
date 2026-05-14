//
//  BaModels.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum BaDesign {
    static let blue = Color.blue
    static let green = Color.green
    static let pink = Color.pink
    static let violet = Color.purple
    static let amber = Color.orange
    static let cyan = Color.cyan
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

enum BaTimelineStatus: String, CaseIterable, Identifiable {
    case running
    case upcoming
    case ended

    var id: Self { self }

    var title: String {
        switch self {
        case .running:
            String(localized: "ba.status.running")
        case .upcoming:
            String(localized: "ba.status.upcoming")
        case .ended:
            String(localized: "ba.status.ended")
        }
    }

    var tint: Color {
        switch self {
        case .running:
            BaDesign.green
        case .upcoming:
            BaDesign.blue
        case .ended:
            .secondary
        }
    }
}

struct BaActivityEntry: Identifiable {
    let id: String
    let title: String
    let kind: String
    let startTime: String
    let endTime: String
    let remaining: String
    let status: BaTimelineStatus
    let systemImage: String
    let linkLabel: String

    static var preview: [BaActivityEntry] {
        [
            BaActivityEntry(
                id: "current-main",
                title: String(localized: "ba.activity.preview.current.title"),
                kind: String(localized: "ba.activity.kind.main"),
                startTime: String(localized: "ba.activity.preview.current.start"),
                endTime: String(localized: "ba.activity.preview.current.end"),
                remaining: String(localized: "ba.activity.preview.current.remaining"),
                status: .running,
                systemImage: "flag.checkered",
                linkLabel: String(localized: "ba.activity.link.gamekee")
            ),
            BaActivityEntry(
                id: "upcoming-mini",
                title: String(localized: "ba.activity.preview.upcoming.title"),
                kind: String(localized: "ba.activity.kind.mini"),
                startTime: String(localized: "ba.activity.preview.upcoming.start"),
                endTime: String(localized: "ba.activity.preview.upcoming.end"),
                remaining: String(localized: "ba.activity.preview.upcoming.remaining"),
                status: .upcoming,
                systemImage: "calendar.badge.plus",
                linkLabel: String(localized: "ba.activity.link.gamekee")
            ),
            BaActivityEntry(
                id: "ended-raid",
                title: String(localized: "ba.activity.preview.ended.title"),
                kind: String(localized: "ba.activity.kind.raid"),
                startTime: String(localized: "ba.activity.preview.ended.start"),
                endTime: String(localized: "ba.activity.preview.ended.end"),
                remaining: String(localized: "ba.activity.preview.ended.remaining"),
                status: .ended,
                systemImage: "archivebox",
                linkLabel: String(localized: "ba.activity.link.archive")
            )
        ]
    }
}

struct BaPoolEntry: Identifiable {
    let id: String
    let name: String
    let tag: String
    let startTime: String
    let endTime: String
    let remaining: String
    let status: BaTimelineStatus
    let systemImage: String
    let linkedStudent: BaStudentPreview

    static var preview: [BaPoolEntry] {
        [
            BaPoolEntry(
                id: "current-hoshino",
                name: String(localized: "ba.pool.preview.current.name"),
                tag: String(localized: "ba.pool.tag.pickup"),
                startTime: String(localized: "ba.pool.preview.current.start"),
                endTime: String(localized: "ba.pool.preview.current.end"),
                remaining: String(localized: "ba.pool.preview.current.remaining"),
                status: .running,
                systemImage: "sparkles",
                linkedStudent: .hoshino
            ),
            BaPoolEntry(
                id: "upcoming-shiroko",
                name: String(localized: "ba.pool.preview.upcoming.name"),
                tag: String(localized: "ba.pool.tag.fes"),
                startTime: String(localized: "ba.pool.preview.upcoming.start"),
                endTime: String(localized: "ba.pool.preview.upcoming.end"),
                remaining: String(localized: "ba.pool.preview.upcoming.remaining"),
                status: .upcoming,
                systemImage: "calendar.badge.plus",
                linkedStudent: .shiroko
            ),
            BaPoolEntry(
                id: "ended-serika",
                name: String(localized: "ba.pool.preview.ended.name"),
                tag: String(localized: "ba.pool.tag.rerun"),
                startTime: String(localized: "ba.pool.preview.ended.start"),
                endTime: String(localized: "ba.pool.preview.ended.end"),
                remaining: String(localized: "ba.pool.preview.ended.remaining"),
                status: .ended,
                systemImage: "archivebox",
                linkedStudent: .serika
            )
        ]
    }
}

enum BaCatalogCategory: String, CaseIterable, Identifiable {
    case students
    case npcSatellite
    case studentBgm
    case favorites

    var id: Self { self }

    var title: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.category.students")
        case .npcSatellite:
            String(localized: "ba.catalog.category.npcSatellite")
        case .studentBgm:
            String(localized: "ba.catalog.category.studentBgm")
        case .favorites:
            String(localized: "ba.catalog.category.favorites")
        }
    }

    var searchPrompt: String {
        switch self {
        case .students:
            String(localized: "ba.catalog.search.students.prompt")
        case .npcSatellite:
            String(localized: "ba.catalog.search.npc.prompt")
        case .studentBgm:
            String(localized: "ba.catalog.search.bgm.prompt")
        case .favorites:
            String(localized: "ba.catalog.search.favorites.prompt")
        }
    }
}

struct BaStudentPreview: Identifiable {
    let id: String
    let name: String
    let school: String
    let role: String
    let summary: String
    let systemImage: String
    let tint: Color

    static let hoshino = BaStudentPreview(
        id: "hoshino",
        name: String(localized: "ba.student.hoshino.name"),
        school: String(localized: "ba.student.school.abydos"),
        role: String(localized: "ba.student.role.tank"),
        summary: String(localized: "ba.student.hoshino.summary"),
        systemImage: "shield.lefthalf.filled",
        tint: BaDesign.amber
    )

    static let shiroko = BaStudentPreview(
        id: "shiroko",
        name: String(localized: "ba.student.shiroko.name"),
        school: String(localized: "ba.student.school.abydos"),
        role: String(localized: "ba.student.role.striker"),
        summary: String(localized: "ba.student.shiroko.summary"),
        systemImage: "scope",
        tint: BaDesign.blue
    )

    static let serika = BaStudentPreview(
        id: "serika",
        name: String(localized: "ba.student.serika.name"),
        school: String(localized: "ba.student.school.abydos"),
        role: String(localized: "ba.student.role.dealer"),
        summary: String(localized: "ba.student.serika.summary"),
        systemImage: "bolt.fill",
        tint: BaDesign.green
    )

    static var previewStudents: [BaStudentPreview] {
        [.hoshino, .shiroko, .serika]
    }

    static var favoriteStudents: [BaStudentPreview] {
        [.hoshino, .shiroko]
    }
}

enum BaStudentDetailSection: String, CaseIterable, Identifiable {
    case profile
    case skills
    case voice
    case gallery
    case simulate

    var id: Self { self }

    var title: String {
        switch self {
        case .profile:
            String(localized: "ba.student.detail.section.profile")
        case .skills:
            String(localized: "ba.student.detail.section.skills")
        case .voice:
            String(localized: "ba.student.detail.section.voice")
        case .gallery:
            String(localized: "ba.student.detail.section.gallery")
        case .simulate:
            String(localized: "ba.student.detail.section.simulate")
        }
    }

    var detail: String {
        switch self {
        case .profile:
            String(localized: "ba.student.detail.profile.detail")
        case .skills:
            String(localized: "ba.student.detail.skills.detail")
        case .voice:
            String(localized: "ba.student.detail.voice.detail")
        case .gallery:
            String(localized: "ba.student.detail.gallery.detail")
        case .simulate:
            String(localized: "ba.student.detail.simulate.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            "person.text.rectangle"
        case .skills:
            "sparkles"
        case .voice:
            "waveform"
        case .gallery:
            "photo.on.rectangle.angled"
        case .simulate:
            "chart.xyaxis.line"
        }
    }
}

enum BaPresentedSheet: String, Identifiable {
    case notifications
    case editOffice
    case debugTools

    var id: Self { self }

    var title: String {
        switch self {
        case .notifications:
            String(localized: "ba.action.notifications.title")
        case .editOffice:
            String(localized: "ba.action.edit.title")
        case .debugTools:
            String(localized: "ba.action.debug.title")
        }
    }

    var menuTitle: String {
        switch self {
        case .notifications:
            title
        case .editOffice:
            String(localized: "ba.action.edit.menuTitle")
        case .debugTools:
            String(localized: "ba.action.debug.menuTitle")
        }
    }

    var systemImage: String {
        switch self {
        case .notifications:
            "bell"
        case .editOffice:
            "square.and.pencil"
        case .debugTools:
            "flask"
        }
    }
}
