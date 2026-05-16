//
//  BaOfficeModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation

nonisolated struct BaOfficeSnapshot: Equatable {
    let nickname: String
    let teacherSuffix: String
    let friendCode: String
    let server: String
    let apCurrent: String
    let apLimit: String
    let apCurrentLimit: String
    let apRemaining: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
    let cafeApCurrent: String
    let cafeApLimit: String
    let cafeLevel: String
    let cafeVisitRefresh: String
    let cafeVisitDetail: String
    let cafeVisitSlots: [BaCafeVisitSnapshot]
    let tacticalRefresh: String
    let tacticalRefreshDetail: String
    let headpatRemain: String
    let headpatDetail: String
    let cafeActions: [BaCafeActionSnapshot]
}

nonisolated struct BaOfficeAPSnapshot: Equatable {
    let apCurrent: String
    let apLimit: String
    let apCurrentLimit: String
    let apRemaining: String
    let apNext: String
    let apFullRemain: String
    let apSyncAt: String
    let apFullAt: String
}

nonisolated struct BaCafeVisitSnapshot: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let value: String
    let detail: String
}

nonisolated enum BaCafeActionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case headpat
    case inviteTicket1
    case inviteTicket2

    var id: Self {
        self
    }
}

nonisolated struct BaCafeActionSnapshot: Identifiable, Codable, Equatable, Hashable {
    let kind: BaCafeActionKind
    let title: String
    let value: String
    let detail: String
    let asset: BaGameAsset
    let tintName: String
    let isReady: Bool

    var id: BaCafeActionKind {
        kind
    }
}
