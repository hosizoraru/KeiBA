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
        struct Resource: Codable, Hashable {
            enum Kind: String, Codable, Hashable {
                case ap
                case cafeAP
            }

            var kind: Kind
            var title: String
            var currentValue: Int
            var limitValue: Int
            var startDate: Date
            var endDate: Date
        }

        var subtitle: String
        var startDate: Date
        var endDate: Date
        var updatedAt: Date
        var resources: [Resource]?
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
