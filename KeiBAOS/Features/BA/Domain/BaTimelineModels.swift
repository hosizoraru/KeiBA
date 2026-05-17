//
//  BaTimelineModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation
import SwiftUI

enum BaTimelineStatus: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case running
    case upcoming
    case ended

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .running:
            BaL10n.string("ba.status.running")
        case .upcoming:
            BaL10n.string("ba.status.upcoming")
        case .ended:
            BaL10n.string("ba.status.ended")
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

nonisolated struct BaActivityEntry: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let title: String
    let kindId: Int
    let kindName: String
    let beginAt: Date
    let endAt: Date
    let linkURL: URL?
    let imageURL: URL?

    func status(at now: Date = Date()) -> BaTimelineStatus {
        if now >= beginAt && now < endAt {
            return .running
        }
        if now < beginAt {
            return .upcoming
        }
        return .ended
    }

    func progress(at now: Date = Date()) -> Double {
        guard endAt > beginAt else { return 0 }
        let elapsed = now.timeIntervalSince(beginAt)
        let total = endAt.timeIntervalSince(beginAt)
        return min(max(elapsed / total, 0), 1)
    }
}

nonisolated struct BaPoolEntry: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let tagId: Int
    let tagName: String
    let alias: String
    let startAt: Date
    let endAt: Date
    let linkURL: URL?
    let imageURL: URL?
    let contentId: Int64?
    let studentGuideURL: URL?

    func status(at now: Date = Date()) -> BaTimelineStatus {
        if now >= startAt && now < endAt {
            return .running
        }
        if now < startAt {
            return .upcoming
        }
        return .ended
    }

    func progress(at now: Date = Date()) -> Double {
        guard endAt > startAt else { return 0 }
        let elapsed = now.timeIntervalSince(startAt)
        let total = endAt.timeIntervalSince(startAt)
        return min(max(elapsed / total, 0), 1)
    }

    func withStudentGuideURL(_ studentGuideURL: URL?) -> BaPoolEntry {
        BaPoolEntry(
            id: id,
            name: name,
            tagId: tagId,
            tagName: tagName,
            alias: alias,
            startAt: startAt,
            endAt: endAt,
            linkURL: linkURL,
            imageURL: imageURL,
            contentId: contentId,
            studentGuideURL: studentGuideURL
        )
    }
}
