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
    private let testActivityIDPrefix = BaNotificationPlan.debugIdentifierPrefix + "live."

    func synchronize(candidates: [BaLiveActivityCandidate]) async {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        guard enabled else {
            await endAllActivities()
            return
        }

        let selected = BaLiveActivitySelection.selectedCandidates(from: candidates)
        let selectedIDs = Set(selected.map(\.id))

        for activity in Activity<BaReminderLiveActivityAttributes>.activities
            where selectedIDs.contains(activity.attributes.id) == false
        {
            await end(activity)
        }

        for candidate in selected {
            let attributes = candidate.attributes
            let content = candidate.content
            if let activity = Activity<BaReminderLiveActivityAttributes>.activities.first(where: { $0.attributes.id == candidate.id }) {
                if activity.attributes.matches(attributes) == false {
                    await end(activity)
                    await request(attributes: attributes, content: content)
                } else if activity.content.state.hasDisplayChanges(comparedWith: content.state) {
                    await update(activity, content: content)
                }
            } else {
                await request(attributes: attributes, content: content)
            }
        }
    }

    func startTestActivity(kind: BaDebugLiveActivityKind = .resource, now: Date = Date()) async -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }

        let candidate = testCandidate(kind: kind, now: now)

        for activity in Activity<BaReminderLiveActivityAttributes>.activities {
            await end(activity)
        }

        return (try? Activity.request(
            attributes: candidate.attributes,
            content: candidate.content,
            pushType: nil
        )) != nil
    }

    func endTestActivities() async {
        for activity in Activity<BaReminderLiveActivityAttributes>.activities
            where activity.attributes.id.hasPrefix(testActivityIDPrefix)
        {
            await end(activity)
        }
    }

    private func testCandidate(kind: BaDebugLiveActivityKind, now: Date) -> BaLiveActivityCandidate {
        switch kind {
        case .resource:
            BaLiveActivityCandidate(
                id: testActivityIDPrefix + kind.rawValue,
                kind: .ap,
                title: NSLocalizedString("ba.notification.debug.live.title", bundle: .main, comment: ""),
                subtitle: NSLocalizedString("ba.notification.debug.live.subtitle", bundle: .main, comment: ""),
                startDate: now,
                endDate: now.addingTimeInterval(10 * 60),
                relevance: 1,
                resources: [
                    BaLiveActivityCandidate.Resource(
                        kind: .ap,
                        title: NSLocalizedString("ba.notification.live.ap.title", bundle: .main, comment: ""),
                        currentValue: 236,
                        limitValue: 240,
                        startDate: now,
                        endDate: now.addingTimeInterval(10 * 60)
                    ),
                    BaLiveActivityCandidate.Resource(
                        kind: .cafeAP,
                        title: NSLocalizedString("ba.notification.live.cafeAp.title", bundle: .main, comment: ""),
                        currentValue: 690,
                        limitValue: 740,
                        startDate: now,
                        endDate: now.addingTimeInterval(47 * 60)
                    ),
                ]
            )
        case .activity:
            BaLiveActivityCandidate(
                id: testActivityIDPrefix + kind.rawValue,
                kind: .activity,
                title: NSLocalizedString("ba.notification.debug.live.activity.title", bundle: .main, comment: ""),
                subtitle: NSLocalizedString("ba.notification.debug.live.activity.subtitle", bundle: .main, comment: ""),
                startDate: now.addingTimeInterval(-50 * 60),
                endDate: now.addingTimeInterval(42 * 60),
                relevance: 0.96
            )
        case .pool:
            BaLiveActivityCandidate(
                id: testActivityIDPrefix + kind.rawValue,
                kind: .pool,
                title: NSLocalizedString("ba.notification.debug.live.pool.title", bundle: .main, comment: ""),
                subtitle: NSLocalizedString("ba.notification.debug.live.pool.subtitle", bundle: .main, comment: ""),
                startDate: now.addingTimeInterval(-80 * 60),
                endDate: now.addingTimeInterval(58 * 60),
                relevance: 0.95
            )
        }
    }

    private func request(
        attributes: BaReminderLiveActivityAttributes,
        content: ActivityContent<BaReminderLiveActivityAttributes.ContentState>
    ) async {
        _ = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    private func update(
        _ activity: Activity<BaReminderLiveActivityAttributes>,
        content: ActivityContent<BaReminderLiveActivityAttributes.ContentState>
    ) async {
        await activity.update(content)
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
                updatedAt: Date(),
                markReadTitle: NSLocalizedString("ba.notification.live.markRead", bundle: .main, comment: ""),
                resources: resources.map(\.contentResource)
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

private extension BaLiveActivityCandidate.Resource {
    var contentResource: BaReminderLiveActivityAttributes.ContentState.Resource {
        BaReminderLiveActivityAttributes.ContentState.Resource(
            kind: contentKind,
            title: title,
            currentValue: currentValue,
            limitValue: limitValue,
            startDate: startDate,
            endDate: endDate
        )
    }

    private var contentKind: BaReminderLiveActivityAttributes.ContentState.Resource.Kind {
        switch kind {
        case .ap:
            .ap
        case .cafeAP:
            .cafeAP
        }
    }
}

private extension BaReminderLiveActivityAttributes {
    func matches(_ other: BaReminderLiveActivityAttributes) -> Bool {
        id == other.id &&
            kind == other.kind &&
            title == other.title
    }
}

private extension BaReminderLiveActivityAttributes.ContentState {
    func hasDisplayChanges(comparedWith other: BaReminderLiveActivityAttributes.ContentState) -> Bool {
        subtitle != other.subtitle ||
            startDate != other.startDate ||
            endDate != other.endDate ||
            markReadTitle != other.markReadTitle ||
            resources != other.resources
    }
}
#endif
