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
        BaDashboardResourcesWidget()
        BaDashboardTimelineWidget()
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
                DynamicIslandExpandedRegion(.leading, priority: 2) {
                    BaReminderIslandHeader(context: context)
                }
                DynamicIslandExpandedRegion(.trailing, priority: 2) {
                    BaReminderIslandStatus(context: context)
                }
                DynamicIslandExpandedRegion(.bottom, priority: 1) {
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
            .contentMargins(.horizontal, 24, for: .expanded)
            .contentMargins(.top, 16, for: .expanded)
            .contentMargins(.bottom, 18, for: .expanded)
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
                BaReminderTimelineLiveActivityView(context: context)
            } else {
                BaReminderMediumLiveActivityView(context: context)
            }
        }
    }
}

private struct BaReminderTimelineLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                BaReminderBrandChip(iconSize: 20)

                Spacer(minLength: 8)

                BaReminderAcknowledgeButton(
                    title: context.markReadTitle,
                    presentation: .lockScreen
                )
            }

            HStack(alignment: .center, spacing: 10) {
                Image(systemName: context.attributes.kind.symbolName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(context.attributes.kind.tint)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(context.state.subtitle)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.state.endDate, style: .timer)
                        .monospacedDigit()
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(context.attributes.kind.tint)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.78)
                        .lineLimit(1)

                    BaReminderProgressTimeline(
                        startDate: context.state.startDate,
                        endDate: context.state.endDate,
                        tint: context.attributes.kind.tint,
                        width: 50,
                        height: 4
                    )
                }
            }
        }
        .modifier(BaReminderReadableLiveActivityWidth())
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

private struct BaReminderMediumLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .modifier(BaReminderReadableLiveActivityWidth())
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

private struct BaReminderReadableLiveActivityWidth: ViewModifier {
    func body(content: Content) -> some View {
        content
            .containerRelativeFrame(.horizontal) { length, _ in
                min(max(length * 0.88, 280), 340)
            }
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct BaReminderSmallLiveActivityView: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                KeiBAOSLiveActivityIcon(size: 16)

                Text("KeiBAOS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)

                BaReminderSmallAcknowledgeButton(title: context.markReadTitle)
            }

            if context.resourceRows.isEmpty {
                fallbackBody
            } else {
                ForEach(context.resourceRows.prefix(2), id: \.kind) { resource in
                    BaReminderSmallResourceLine(resource: resource)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            ContainerRelativeShape()
                .fill(Color.black.opacity(0.82))
        )
    }

    private var fallbackBody: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: context.attributes.kind.symbolName)
                .font(.caption.weight(.bold))
                .foregroundStyle(context.attributes.kind.tint)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(context.attributes.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(context.primaryCompactValue)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(context.attributes.kind.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct BaReminderSmallResourceLine: View {
    let resource: BaReminderLiveActivityAttributes.ContentState.Resource

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: resource.symbolName)
                .font(.caption.weight(.bold))
                .foregroundStyle(resource.tint)
                .frame(width: 14)

            Text(resource.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 4)

            Text(resource.valueText)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(resource.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct BaReminderSmallAcknowledgeButton: View {
    let title: String

    var body: some View {
        Button(intent: AcknowledgeBaReminderLiveActivityIntent()) {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .frame(height: 21)
            .padding(.horizontal, 6)
            .contentShape(.rect)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .background(.white.opacity(0.16), in: Capsule())
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct BaReminderBrandChip: View {
    var iconSize: CGFloat
    var textFont: Font = .caption.weight(.semibold)

    var body: some View {
        HStack(spacing: 6) {
            KeiBAOSLiveActivityIcon(size: iconSize)

            Text("KeiBAOS")
                .font(textFont)
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

private struct BaReminderIslandHeader: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        BaReminderBrandChip(
            iconSize: 18,
            textFont: .headline.weight(.semibold)
        )
        .padding(.leading, 4)
    }
}

private struct BaReminderIslandStatus: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        BaReminderAcknowledgeButton(
            title: context.markReadTitle,
            presentation: .dynamicIslandHeader
        )
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 7)
            .padding(.leading, 4)
        }
    }
}

private struct BaReminderFallbackIslandDetails: View {
    let context: ActivityViewContext<BaReminderLiveActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: context.attributes.kind.symbolName)
                .font(.title3.weight(.bold))
                .foregroundStyle(context.attributes.kind.tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 6) {
                    Text(context.state.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(context.state.endDate, style: .timer)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(context.attributes.kind.tint)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            BaReminderProgressTimeline(
                startDate: context.state.startDate,
                endDate: context.state.endDate,
                tint: context.attributes.kind.tint,
                width: 48,
                height: 4
            )
        }
        .padding(.top, 7)
        .padding(.leading, 4)
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
        HStack(alignment: .center, spacing: presentation.horizontalSpacing) {
            resourceIcon

            VStack(alignment: .leading, spacing: presentation.textSpacing) {
                resourceTitle

                if presentation.showsSecondaryTimer {
                    resourceTimer
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            resourceMeter

            resourceValue
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    }

    private var resourceValue: some View {
        Text(resource.valueText)
            .font(presentation.valueFont)
            .foregroundStyle(presentation.valueColor(for: resource))
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
    }

    private var resourceMeter: some View {
        BaReminderProgressTimeline(
            startDate: resource.startDate,
            endDate: resource.endDate,
            tint: resource.tint,
            width: presentation.meterWidth,
            height: presentation.meterHeight
        )
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
            .frame(minWidth: presentation.acknowledgeButtonMinimumWidth)
            .frame(height: presentation.acknowledgeButtonHeight)
            .padding(.horizontal, presentation.acknowledgeHorizontalPadding)
            .contentShape(.rect)
        }
        .font(presentation.acknowledgeFont)
        .foregroundStyle(presentation.acknowledgeForegroundColor)
        .background(presentation.acknowledgeBackgroundColor, in: Capsule())
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .offset(y: presentation.acknowledgeVerticalOffset)
    }
}

private enum BaReminderResourcePresentation {
    case dynamicIsland
    case dynamicIslandHeader
    case lockScreen

    var rowSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            8
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            9
        }
    }

    var horizontalSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            7
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            8
        }
    }

    var iconWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            20
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            22
        }
    }

    var textSpacing: CGFloat {
        switch self {
        case .dynamicIsland:
            1
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            2
        }
    }

    var showsSecondaryTimer: Bool {
        switch self {
        case .dynamicIsland:
            true
        case .dynamicIslandHeader:
            false
        case .lockScreen:
            true
        }
    }

    var valueWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            62
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            78
        }
    }

    var meterWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            34
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            42
        }
    }

    var meterHeight: CGFloat {
        switch self {
        case .dynamicIsland:
            4
        case .dynamicIslandHeader:
            0
        case .lockScreen:
            5
        }
    }

    var acknowledgeButtonMinimumWidth: CGFloat {
        switch self {
        case .dynamicIsland:
            48
        case .dynamicIslandHeader:
            48
        case .lockScreen:
            52
        }
    }

    var acknowledgeHorizontalPadding: CGFloat {
        switch self {
        case .dynamicIsland:
            8
        case .dynamicIslandHeader:
            9
        case .lockScreen:
            8
        }
    }

    var acknowledgeButtonHeight: CGFloat {
        switch self {
        case .dynamicIsland:
            28
        case .dynamicIslandHeader:
            26
        case .lockScreen:
            30
        }
    }

    var acknowledgeVerticalOffset: CGFloat {
        switch self {
        case .lockScreen:
            4
        case .dynamicIsland, .dynamicIslandHeader:
            0
        }
    }

    var iconFont: Font {
        switch self {
        case .dynamicIsland:
            .callout.weight(.bold)
        case .dynamicIslandHeader:
            .caption.weight(.bold)
        case .lockScreen:
            .title3.weight(.bold)
        }
    }

    var titleFont: Font {
        switch self {
        case .dynamicIsland:
            .callout.weight(.semibold)
        case .dynamicIslandHeader:
            .caption.weight(.semibold)
        case .lockScreen:
            .title3.weight(.semibold)
        }
    }

    var valueFont: Font {
        switch self {
        case .dynamicIsland:
            .callout.monospacedDigit().weight(.bold)
        case .dynamicIslandHeader:
            .caption.monospacedDigit().weight(.bold)
        case .lockScreen:
            .title3.monospacedDigit().weight(.bold)
        }
    }

    var timerFont: Font {
        switch self {
        case .dynamicIsland:
            .caption.monospacedDigit().weight(.semibold)
        case .dynamicIslandHeader:
            .caption2.monospacedDigit().weight(.semibold)
        case .lockScreen:
            .footnote.monospacedDigit().weight(.semibold)
        }
    }

    var acknowledgeFont: Font {
        switch self {
        case .dynamicIsland:
            .caption2.weight(.semibold)
        case .dynamicIslandHeader:
            .caption2.weight(.semibold)
        case .lockScreen:
            .caption.weight(.semibold)
        }
    }

    var acknowledgeForegroundColor: Color {
        switch self {
        case .dynamicIsland:
            .white
        case .dynamicIslandHeader:
            .white
        case .lockScreen:
            .primary
        }
    }

    var acknowledgeBackgroundColor: Color {
        switch self {
        case .dynamicIsland:
            .white.opacity(0.16)
        case .dynamicIslandHeader:
            .white.opacity(0.18)
        case .lockScreen:
            .primary.opacity(0.12)
        }
    }

    func valueColor(for resource: BaReminderLiveActivityAttributes.ContentState.Resource) -> Color {
        switch self {
        case .dynamicIsland, .dynamicIslandHeader:
            resource.tint
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
