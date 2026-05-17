//
//  BaLiveActivityController.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

@MainActor
final class BaLiveActivityController {
    private let maximumActivities = 2

    func synchronize(candidates: [BaLiveActivityCandidate]) async {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        guard enabled else {
            await endAllActivities()
            return
        }

        let selected = Array(candidates.prefix(maximumActivities))
        let selectedIDs = Set(selected.map(\.id))

        for activity in Activity<BaReminderLiveActivityAttributes>.activities
            where selectedIDs.contains(activity.attributes.id) == false
        {
            await end(activity)
        }

        for candidate in selected {
            if let activity = Activity<BaReminderLiveActivityAttributes>.activities.first(where: { $0.attributes.id == candidate.id }) {
                await update(activity, with: candidate)
            } else {
                try? Activity.request(
                    attributes: candidate.attributes,
                    content: candidate.content,
                    pushType: nil
                )
            }
        }
    }

    private func update(
        _ activity: Activity<BaReminderLiveActivityAttributes>,
        with candidate: BaLiveActivityCandidate
    ) async {
        await activity.update(candidate.content)
    }

    private func endAllActivities() async {
        for activity in Activity<BaReminderLiveActivityAttributes>.activities {
            await end(activity)
        }
    }

    private func end(_ activity: Activity<BaReminderLiveActivityAttributes>) async {
        let state = activity.content.state
        await activity.end(
            ActivityContent(
                state: state,
                staleDate: Date()
            ),
            dismissalPolicy: .immediate
        )
    }
}

private extension BaLiveActivityCandidate {
    var attributes: BaReminderLiveActivityAttributes {
        BaReminderLiveActivityAttributes(
            id: id,
            kind: liveActivityKind,
            title: title
        )
    }

    var content: ActivityContent<BaReminderLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: BaReminderLiveActivityAttributes.ContentState(
                subtitle: subtitle,
                startDate: startDate,
                endDate: endDate,
                updatedAt: Date()
            ),
            staleDate: endDate.addingTimeInterval(60),
            relevanceScore: relevance
        )
    }

    private var liveActivityKind: BaReminderLiveActivityAttributes.Kind {
        switch kind {
        case .ap:
            .ap
        case .cafeAP:
            .cafeAP
        case .activity:
            .activity
        case .pool:
            .pool
        }
    }
}
#endif
