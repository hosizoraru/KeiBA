//
//  BaReminderLiveActivityAttributes.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

nonisolated struct BaReminderLiveActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        nonisolated struct Resource: Codable, Hashable {
            nonisolated enum Kind: String, Codable, Hashable {
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
        var markReadTitle: String?
        var resources: [Resource]?
    }

    nonisolated enum Kind: String, Codable, Hashable {
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
