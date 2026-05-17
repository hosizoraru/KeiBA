//
//  AcknowledgeBaReminderLiveActivityIntent.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if os(iOS) && canImport(ActivityKit) && canImport(AppIntents)
import ActivityKit
import AppIntents

struct AcknowledgeBaReminderLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: "ba.notification.live.markRead")
    }

    func perform() async throws -> some IntentResult {
        for activity in Activity<BaReminderLiveActivityAttributes>.activities {
            await activity.end(
                ActivityContent(
                    state: activity.content.state,
                    staleDate: Date()
                ),
                dismissalPolicy: .immediate
            )
        }

        return .result()
    }
}
#endif
