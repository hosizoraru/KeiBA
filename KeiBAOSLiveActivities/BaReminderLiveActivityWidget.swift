//
//  BaReminderLiveActivityWidget.swift
//  KeiBAOSLiveActivities
//
//  Created by Codex on 2026/05/17.
//

import ActivityKit
import AppIntents
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
                    .font(.caption.weight(.bold))
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
                    .font(.caption.weight(.bold))
                    .foregroundStyle(context.attributes.kind.tint)
            }
            .keylineTint(context.attributes.kind.tint)
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

private struct BaReminderLockScreenLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>
    @Environment(\.activityFamily) private var activityFamily

    var body: some View {
        switch activityFamily {
        case .small:
            BaReminderSmallLiveActivityView(context: context)
        default:
            if context.resourceRows.isEmpty {
                fallbackBody
            } else {
                BaReminderMediumLiveActivityView(context: context)
            }
        }
    }

    private var fallbackBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                BaReminderBrandChip(iconSize: 20)

                Image(systemName: context.attributes.kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(context.attributes.kind.tint)
                    .frame(width: 18, height: 18)

                Text(context.attributes.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(context.attributes.kind.tint)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)

                BaReminderAcknowledgeButton(
                    title: context.markReadTitle,
                    presentation: .lockScreen
                )
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

private struct BaReminderMediumLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 8) {
                BaReminderBrandChip(iconSize: 20)

                Spacer(minLength: 8)

                BaReminderAcknowledgeButton(
                    title: context.markReadTitle,
                    presentation: .lockScreen
                )
            }

            BaReminderResourceRows(
                resources: context.resourceRows,
                presentation: .lockScreen
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

private struct BaReminderSmallLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                KeiBAOSLiveActivityIcon(size: 18)

                Text("KeiBAOS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)
            }

            if context.resourceRows.isEmpty {
                fallbackBody
            } else {
                ForEach(context.resourceRows.prefix(2), id: \.kind) { resource in
                    BaReminderSmallResourceLine(resource: resource)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var fallbackBody: some View {
        HStack(spacing: 6) {
            Image(systemName: context.attributes.kind.symbolName)
                .font(.caption.weight(.bold))
                .foregroundStyle(context.attributes.kind.tint)

            Text(context.primaryCompactValue)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(context.attributes.kind.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct BaReminderSmallResourceLine: View {
    let resource: BaReminderLiveActivityAttributes.ContentState.Resource

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: resource.symbolName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(resource.tint)
                .frame(width: 12)

            Text(resource.valueText)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 4)

            Text(resource.endDate, style: .timer)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(resource.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .contentTransition(.numericText())
        }
    }
}

private struct BaReminderBrandChip: View {
    var iconSize: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            KeiBAOSLiveActivityIcon(size: iconSize)

            Text("KeiBAOS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct KeiBAOSLiveActivityIcon: View {
    var size: CGFloat

    var body: some View {
        Image("KeiBAOSLiveActivityIcon")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

private struct BaReminderIslandSymbol: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 5) {
            KeiBAOSLiveActivityIcon(size: 13)

            Image(systemName: context.primarySymbolName)
                .font(.headline.weight(.bold))
                .foregroundStyle(context.attributes.kind.tint)
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            if let title = context.primaryResource?.title {
                Text(title)
                    .font(.headline.weight(.semibold))
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
            HStack(alignment: .center, spacing: 8) {
                BaReminderResourceRows(
                    resources: context.resourceRows,
                    presentation: .dynamicIsland
                )
                .layoutPriority(1)

                BaReminderAcknowledgeButton(
                    title: context.markReadTitle,
                    presentation: .dynamicIsland
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
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
        if presentation.usesFlexibleWidth {
            flexibleBody
        } else {
            compactBody
        }
    }

    private var flexibleBody: some View {
        VStack(alignment: .leading, spacing: presentation.progressSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: presentation.horizontalSpacing) {
                resourceIcon

                resourceTitle

                Spacer(minLength: 6)

                resourceValue

                resourceTimer
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            BaReminderProgressTimeline(
                startDate: resource.startDate,
                endDate: resource.endDate,
                tint: resource.tint,
                height: presentation.progressHeight
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var compactBody: some View {
        VStack(alignment: .center, spacing: presentation.progressSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: presentation.horizontalSpacing) {
                resourceIcon

                resourceTitle

                resourceValue

                resourceTimer
            }
            .frame(maxWidth: presentation.maximumContentWidth, alignment: .center)

            BaReminderProgressTimeline(
                startDate: resource.startDate,
                endDate: resource.endDate,
                tint: resource.tint,
                height: presentation.progressHeight
            )
            .frame(width: presentation.progressWidth)
        }
    }

    private var resourceIcon: some View {
        Image(systemName: resource.symbolName)
            .font(presentation.iconFont)
            .foregroundStyle(resource.tint)
            .frame(width: presentation.iconWidth)
    }

    private var resourceTitle: some View {
        Text(resource.title)
            .font(presentation.titleFont)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: presentation.titleWidth, alignment: .leading)
    }

    private var resourceValue: some View {
        Text(resource.valueText)
            .font(presentation.valueFont)
            .foregroundStyle(presentation.valueStyle)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: presentation.valueWidth, alignment: .leading)
    }

    private var resourceTimer: some View {
        Text(resource.endDate, style: .timer)
            .font(presentation.timerFont)
            .foregroundStyle(resource.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .contentTransition(.numericText())
            .frame(width: presentation.timerWidth, alignment: .trailing)
    }
}

private struct BaReminderAcknowledgeButton: View {
    let title: String
    let presentation: BaReminderResourcePresentation

    var body: some View {
        Button(intent: AcknowledgeBaReminderLiveActivityIntent()) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(
                width: presentation.acknowledgeButtonWidth,
                height: presentation.acknowledgeButtonHeight
            )
            .contentShape(.rect)
        }
        .font(presentation.acknowledgeFont)
        .foregroundStyle(presentation.acknowledgeForegroundColor)
        .background(presentation.acknowledgeBackgroundColor, in: Capsule())
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private enum BaReminderResourcePresentation {
    case dynamicIsland
    case lockScreen

    var rowSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            4
        case .lockScreen:
            5
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
            6
        case .lockScreen:
            6
        }
    }

    var iconWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            16
        case .lockScreen:
            18
        }
    }

    var titleWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            58
        case .lockScreen:
            84
        }
    }

    var valueWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            56
        case .lockScreen:
            66
        }
    }

    var timerWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            46
        case .lockScreen:
            48
        }
    }

    var maximumContentWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            194
        case .lockScreen:
            234
        }
    }

    var progressWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            194
        case .lockScreen:
            218
        }
    }

    var acknowledgeButtonWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            56
        case .lockScreen:
            58
        }
    }

    var acknowledgeButtonHeight: CGFloat {
        switch self {
        case .dynamicIsland:
            30
        case .lockScreen:
            30
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
            .caption.weight(.bold)
        case .lockScreen:
            .footnote.weight(.bold)
        }
    }

    var titleFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.weight(.semibold)
        case .lockScreen:
            .footnote.weight(.semibold)
        }
    }

    var valueFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.monospacedDigit().weight(.semibold)
        case .lockScreen:
            .footnote.monospacedDigit().weight(.semibold)
        }
    }

    var timerFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.monospacedDigit().weight(.semibold)
        case .lockScreen:
            .footnote.monospacedDigit().weight(.semibold)
        }
    }

    var acknowledgeFont: Font {
        switch self {
        case .dynamicIsland:
            .caption2.weight(.semibold)
        case .lockScreen:
            .caption.weight(.semibold)
        }
    }

    var acknowledgeForegroundColor: Color {
        switch self {
        case .dynamicIsland:
            .white
        case .lockScreen:
            .primary
        }
    }

    var acknowledgeBackgroundColor: Color {
        switch self {
        case .dynamicIsland:
            .white.opacity(0.16)
        case .lockScreen:
            .primary.opacity(0.12)
        }
    }

    var valueStyle: HierarchicalShapeStyle {
        .primary
    }

    var usesFlexibleWidth: Bool {
        self == .lockScreen
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

    var markReadTitle: String {
        state.markReadTitle ?? "Read"
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
            Color(red: 0.20, green: 0.90, blue: 0.24)
        case .cafeAP:
            Color(red: 1.00, green: 0.42, blue: 0.74)
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
            Color(red: 0.20, green: 0.90, blue: 0.24)
        case .cafeAP:
            Color(red: 1.00, green: 0.42, blue: 0.74)
        case .activity:
            .orange
        case .pool:
            .pink
        }
    }
}
