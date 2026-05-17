//
//  BaReminderLiveActivityAttributes.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

struct BaReminderLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var subtitle: String
        var startDate: Date
        var endDate: Date
        var updatedAt: Date
    }

    enum Kind: String, Codable, Hashable {
        case ap
        case cafeAP
        case activity
        case pool
    }

    var id: String
    var kind: Kind
    var title: String
}
#endif
