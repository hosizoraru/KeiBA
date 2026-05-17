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
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    BaReminderIslandSymbol(context: context)
                }
                DynamicIslandExpandedRegion(.trailing, priority: 2) {
                    BaReminderCompactValue(context: context)
                }
                DynamicIslandExpandedRegion(.bottom, priority: 3) {
                    BaReminderIslandDetails(context: context)
                }
            } compactLeading: {
                Image(systemName: context.primarySymbolName)
                    .foregroundStyle(context.attributes.kind.tint)
            } compactTrailing: {
                Text(context.primaryCompactValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(context.attributes.kind.tint)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.primarySymbolName)
                    .foregroundStyle(context.attributes.kind.tint)
            }
            .keylineTint(context.attributes.kind.tint)
        }
    }
}

private struct BaReminderLockScreenLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        if context.resourceRows.isEmpty {
            fallbackBody
        } else {
            resourceBody
        }
    }

    private var resourceBody: some View {
        BaReminderResourceRows(
            resources: context.resourceRows,
            presentation: .lockScreen
        )
        .padding(.vertical, context.resourceRows.count > 1 ? 1 : 4)
    }

    private var fallbackBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: context.attributes.kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(context.attributes.kind.tint)
                    .frame(width: 24, height: 24)

                Text(context.attributes.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(context.attributes.kind.tint)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)
            }

            BaReminderProgressTimeline(
                startDate: context.state.startDate,
                endDate: context.state.endDate,
                tint: context.attributes.kind.tint,
                height: 4
            )
        }
        .padding(.vertical, 2)
    }
}

private struct BaReminderIslandSymbol: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: context.primarySymbolName)
                .font(.headline)
                .foregroundStyle(context.attributes.kind.tint)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)

            if let title = context.primaryResource?.title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private struct BaReminderCompactValue: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        Text(context.primaryCompactValue)
            .font(.headline.weight(.semibold))
            .foregroundStyle(context.attributes.kind.tint)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}

private struct BaReminderIslandDetails: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        if context.resourceRows.isEmpty {
            BaReminderFallbackIslandDetails(context: context)
        } else {
            BaReminderResourceRows(
                resources: context.resourceRows,
                presentation: .dynamicIsland
            )
            .padding(.top, 1)
        }
    }
}

private struct BaReminderFallbackIslandDetails: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(context.state.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(context.attributes.kind.tint)
                    .lineLimit(1)
            }

            BaReminderProgressTimeline(
                startDate: context.state.startDate,
                endDate: context.state.endDate,
                tint: context.attributes.kind.tint,
                height: 3
            )
        }
    }
}

private struct BaReminderResourceRows: View {
    let resources: [BaReminderLiveActivityAttributes.ContentState.Resource]
    let presentation: BaReminderResourcePresentation

    var body: some View {
        VStack(spacing: presentation.rowSpacing) {
            ForEach(resources, id: \.kind) { resource in
                BaReminderResourceRow(
                    resource: resource,
                    presentation: presentation
                )
            }
        }
    }
}

private struct BaReminderResourceRow: View {
    let resource: BaReminderLiveActivityAttributes.ContentState.Resource
    let presentation: BaReminderResourcePresentation

    var body: some View {
        VStack(spacing: presentation.progressSpacing) {
            HStack(spacing: presentation.horizontalSpacing) {
                Image(systemName: resource.symbolName)
                    .font(presentation.iconFont)
                    .foregroundStyle(resource.tint)
                    .frame(width: presentation.iconWidth)

                Text(resource.title)
                    .font(presentation.titleFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(resource.valueText)
                    .font(presentation.valueFont)
                    .foregroundStyle(presentation.valueStyle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: presentation.minimumSpacer)

                Text(resource.endDate, style: .timer)
                    .font(presentation.timerFont)
                    .foregroundStyle(resource.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
            }

            BaReminderProgressTimeline(
                startDate: resource.startDate,
                endDate: resource.endDate,
                tint: resource.tint,
                height: presentation.progressHeight
            )
        }
    }
}

private enum BaReminderResourcePresentation {
    case dynamicIsland
    case lockScreen

    var rowSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            5
        case .lockScreen:
            7
        }
    }

    var progressSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            3
        case .lockScreen:
            4
        }
    }

    var horizontalSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            7
        case .lockScreen:
            9
        }
    }

    var iconWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            15
        case .lockScreen:
            20
        }
    }

    var minimumSpacer: CGFloat {
        switch self {
        case .dynamicIsland:
            5
        case .lockScreen:
            8
        }
    }

    var progressHeight: CGFloat {
        switch self {
        case .dynamicIsland:
            3
        case .lockScreen:
            4
        }
    }

    var iconFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.weight(.semibold)
        case .lockScreen:
            .headline.weight(.semibold)
        }
    }

    var titleFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.weight(.semibold)
        case .lockScreen:
            .headline.weight(.semibold)
        }
    }

    var valueFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.monospacedDigit().weight(.semibold)
        case .lockScreen:
            .headline.monospacedDigit().weight(.semibold)
        }
    }

    var timerFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.monospacedDigit().weight(.semibold)
        case .lockScreen:
            .subheadline.monospacedDigit().weight(.semibold)
        }
    }

    var valueStyle: HierarchicalShapeStyle {
        switch self {
        case .dynamicIsland:
            .secondary
        case .lockScreen:
            .primary
        }
    }
}

private struct BaReminderProgressTimeline: View {
    let startDate: Date
    let endDate: Date
    let tint: Color
    var width: CGFloat?
    var height: CGFloat

    var body: some View {
        TimelineView(.periodic(from: startDate, by: 60)) { timeline in
            BaReminderProgressMeter(
                progress: progress(at: timeline.date),
                tint: tint
            )
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }

    private func progress(at date: Date) -> Double {
        let duration = max(endDate.timeIntervalSince(startDate), 1)
        let elapsed = date.timeIntervalSince(startDate)
        return min(max(elapsed / duration, 0), 1)
    }
}

private struct BaReminderProgressMeter: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.24))
                Capsule()
                    .fill(tint)
                    .frame(width: max(proxy.size.width * progress, proxy.size.height))
            }
        }
    }
}

private extension ActivityViewContext where Attributes == BaReminderLiveActivityAttributes {
    var resourceRows: [BaReminderLiveActivityAttributes.ContentState.Resource] {
        state.resources ?? []
    }

    var primaryResource: BaReminderLiveActivityAttributes.ContentState.Resource? {
        resourceRows.first
    }

    var primarySymbolName: String {
        primaryResource?.symbolName ?? attributes.kind.symbolName
    }

    var primaryCompactValue: String {
        primaryResource?.valueText ?? fallbackTimerText
    }

    private var fallbackTimerText: String {
        let remaining = max(state.endDate.timeIntervalSince(.now), 0)
        let minutes = Int(ceil(remaining / 60))
        return "\(minutes)m"
    }
}

private extension BaReminderLiveActivityAttributes.ContentState.Resource {
    var valueText: String {
        "\(currentValue)/\(limitValue)"
    }

    var symbolName: String {
        switch kind {
        case .ap:
            "bolt.fill"
        case .cafeAP:
            "cup.and.saucer.fill"
        }
    }

    var tint: Color {
        switch kind {
        case .ap:
            .cyan
        case .cafeAP:
            .mint
        }
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
