//
//  BaReminderLiveActivityWidget.swift
//  KeiBAOSLiveActivities
//
//  Created by Codex on 2026/05/17.
//

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct KeiBAOSLiveActivityWidgets: WidgetBundle {
    var body: some Widget {
        BaReminderLiveActivityWidget()
    }
}

struct BaReminderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BaReminderLiveActivityAttributes.self) { context in
            BaReminderLockScreenLiveActivityView(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(context.attributes.kind.tint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    BaReminderCompactHeader(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endDate, style: .timer)
                        .monospacedDigit()
                        .font(.headline)
                        .foregroundStyle(context.attributes.kind.tint)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    BaReminderProgressView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.attributes.kind.symbolName)
                    .foregroundStyle(context.attributes.kind.tint)
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundStyle(context.attributes.kind.tint)
                    .minimumScaleFactor(0.7)
            } minimal: {
                Image(systemName: context.attributes.kind.symbolName)
                    .foregroundStyle(context.attributes.kind.tint)
            }
            .keylineTint(context.attributes.kind.tint)
        }
    }
}

private struct BaReminderLockScreenLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: context.attributes.kind.symbolName)
                    .font(.title3)
                    .foregroundStyle(context.attributes.kind.tint)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.state.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .font(.headline)
                    .foregroundStyle(context.attributes.kind.tint)
                    .contentTransition(.numericText())
            }

            BaReminderProgressView(context: context)
        }
        .padding(.vertical, 4)
    }
}

private struct BaReminderCompactHeader: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(context.attributes.title)
                    .lineLimit(1)
                Text(context.state.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: context.attributes.kind.symbolName)
                .foregroundStyle(context.attributes.kind.tint)
        }
        .font(.caption)
    }
}

private struct BaReminderProgressView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        ProgressView(
            timerInterval: context.state.startDate...context.state.endDate,
            countsDown: false
        )
        .tint(context.attributes.kind.tint)
    }
}

private extension BaReminderLiveActivityAttributes.Kind {
    var symbolName: String {
        switch self {
        case .ap:
            "bolt.fill"
        case .cafeAP:
            "cup.and.saucer.fill"
        case .activity:
            "calendar.badge.clock"
        case .pool:
            "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .ap:
            .cyan
        case .cafeAP:
            .mint
        case .activity:
            .orange
        case .pool:
            .pink
        }
    }
}
