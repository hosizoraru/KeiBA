//
//  BaDashboardTimelineWidgets.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

struct BaDashboardTimelineWidgetView: View {
    let entry: BaDashboardWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                BaTimelineInlineWidget(entry: entry)
            case .accessoryRectangular:
                BaTimelineRectangularWidget(entry: entry)
            case .systemLarge:
                BaTimelineLargeWidget(entry: entry)
            default:
                BaTimelineMediumWidget(entry: entry)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

private struct BaTimelineMediumWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 10) {
                BaWidgetHeader(snapshot: snapshot)

                HStack(alignment: .top, spacing: 14) {
                    BaTimelineFeaturedSection(
                        title: Text("ba.widget.activity.title"),
                        section: snapshot.timeline.activities,
                        systemImage: "calendar.badge.clock",
                        tint: BaWidgetPalette.activity,
                        date: entry.date
                    )
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    BaTimelineFeaturedSection(
                        title: Text("ba.widget.pool.title"),
                        section: snapshot.timeline.pools,
                        systemImage: "sparkles",
                        tint: BaWidgetPalette.pool,
                        date: entry.date
                    )
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .baWidgetRootFrame()
        } else {
            BaWidgetNoDataView()
        }
    }
}

private struct BaTimelineLargeWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let summary = snapshot.glanceSummary(at: entry.date)
            VStack(alignment: .leading, spacing: 9) {
                BaWidgetHeader(snapshot: snapshot)

                VStack(alignment: .leading, spacing: 8) {
                    BaTimelineLargeSection(
                        title: Text("ba.widget.activity.title"),
                        section: snapshot.timeline.activities,
                        systemImage: "calendar.badge.clock",
                        tint: BaWidgetPalette.activity,
                        date: entry.date
                    )
                    .frame(maxHeight: .infinity, alignment: .topLeading)

                    BaTimelineLargeSection(
                        title: Text("ba.widget.pool.title"),
                        section: snapshot.timeline.pools,
                        systemImage: "sparkles",
                        tint: BaWidgetPalette.pool,
                        date: entry.date
                    )
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)

                Divider()

                HStack(spacing: 12) {
                    BaResourceMiniPill(
                        title: Text("ba.widget.ap.title"),
                        value: "\(summary.currentAP)/\(summary.apLimit)",
                        systemImage: "bolt.fill",
                        tint: BaWidgetPalette.ap
                    )
                    BaResourceMiniPill(
                        title: Text("ba.widget.cafeAP.title"),
                        value: "\(summary.currentCafeAP)/\(summary.cafeAPCapacity)",
                        systemImage: "cup.and.saucer.fill",
                        tint: BaWidgetPalette.cafeAP
                    )
                }
            }
            .baWidgetRootFrame()
        } else {
            BaWidgetNoDataView()
        }
    }
}

private struct BaTimelineLargeSection: View {
    let title: Text
    let section: BaTimelineGlanceSection
    let systemImage: String
    let tint: Color
    let date: Date

    private var items: ArraySlice<BaTimelineGlanceItem> {
        section.displayItems.prefix(2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BaTimelineSectionHeader(
                title: title,
                systemImage: systemImage,
                tint: tint,
                countSummary: countSummary
            )

            if items.isEmpty {
                Text("ba.widget.timeline.empty")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        BaTimelineLargeItemRow(item: item, tint: tint, date: date, isPrimary: index == 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countSummary: String {
        String(format: String(localized: "ba.widget.timeline.counts.format"), section.runningCount, section.upcomingCount)
    }
}

private struct BaTimelineLargeItemRow: View {
    let item: BaTimelineGlanceItem
    let tint: Color
    let date: Date
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(item.title)
                    .font(titleFont)
                    .lineLimit(isPrimary ? 2 : 1)
                    .minimumScaleFactor(isPrimary ? 0.74 : 0.70)
                    .allowsTightening(true)
                    .layoutPriority(2)

                Spacer(minLength: 4)

                Text(item.endAt, style: item.status == .running ? .relative : .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .allowsTightening(true)
            }

            HStack(alignment: .center, spacing: 6) {
                BaTimelineStatusLabel(status: item.status)
                BaWidgetCompactMeter(value: item.progress(at: date), limit: 1, tint: tint)
            }
        }
    }

    private var titleFont: Font {
        isPrimary ? .subheadline.weight(.semibold) : .caption.weight(.semibold)
    }
}

private struct BaTimelineRectangularWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            if snapshot.timeline.activities.hasContent {
                BaTimelineAccessoryRectangularContent(
                    title: Text("ba.widget.activity.title"),
                    section: snapshot.timeline.activities,
                    systemImage: "calendar.badge.clock",
                    tint: BaWidgetPalette.activity,
                    date: entry.date
                )
            } else {
                BaTimelineAccessoryRectangularContent(
                    title: Text("ba.widget.pool.title"),
                    section: snapshot.timeline.pools,
                    systemImage: "sparkles",
                    tint: BaWidgetPalette.pool,
                    date: entry.date
                )
            }
        } else {
            BaWidgetNoDataCompactView()
        }
    }
}

private struct BaTimelineAccessoryRectangularContent: View {
    let title: Text
    let section: BaTimelineGlanceSection
    let systemImage: String
    let tint: Color
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)

                title
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)

                if let item = section.featuredItem {
                    Text(item.endAt, style: item.status == .running ? .relative : .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
            }

            if let item = section.featuredItem {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(alignment: .center, spacing: 6) {
                    BaTimelineStatusLabel(status: item.status)

                    BaWidgetCompactMeter(
                        value: item.progress(at: date),
                        limit: 1,
                        tint: tint
                    )
                    .frame(maxWidth: 76)
                }
            } else {
                Text("ba.widget.timeline.empty")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct BaTimelineInlineWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let item = entry.snapshot?.timeline.primaryFeaturedItem {
            Text(item.title)
        } else {
            Text("ba.widget.timeline.empty")
        }
    }
}

struct BaTimelineFeaturedCompactSection: View {
    let title: Text
    let section: BaTimelineGlanceSection
    let systemImage: String
    let tint: Color
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            BaTimelineSectionHeader(
                title: title,
                systemImage: systemImage,
                tint: tint,
                countSummary: countSummary
            )

            if let item = section.featuredItem {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 5) {
                    BaTimelineStatusLabel(status: item.status)
                    Spacer(minLength: 2)
                    Text(item.endAt, style: item.status == .running ? .relative : .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                BaWidgetCompactMeter(value: item.progress(at: date), limit: 1, tint: tint)
            } else {
                Text("ba.widget.timeline.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var countSummary: String {
        String(format: String(localized: "ba.widget.timeline.counts.format"), section.runningCount, section.upcomingCount)
    }
}

private struct BaTimelineFeaturedSection: View {
    let title: Text
    let section: BaTimelineGlanceSection
    let systemImage: String
    let tint: Color
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BaTimelineSectionHeader(
                title: title,
                systemImage: systemImage,
                tint: tint,
                countSummary: countSummary
            )

            if let item = section.featuredItem {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        BaTimelineStatusLabel(status: item.status)
                        Spacer(minLength: 4)
                        Text(item.endAt, style: item.status == .running ? .relative : .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                            .allowsTightening(true)
                    }

                    BaWidgetCompactMeter(
                        value: item.progress(at: date),
                        limit: 1,
                        tint: tint
                    )
                }
            } else {
                Text("ba.widget.timeline.empty")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countSummary: String {
        String(format: String(localized: "ba.widget.timeline.counts.format"), section.runningCount, section.upcomingCount)
    }
}

private struct BaTimelineSectionHeader: View {
    let title: Text
    let systemImage: String
    let tint: Color
    var countSummary: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            title
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .allowsTightening(true)

            Spacer(minLength: 4)

            if let countSummary {
                Text(countSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
            }
        }
    }
}

private struct BaTimelineStatusLabel: View {
    let status: BaTimelineGlanceStatus

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var title: LocalizedStringKey {
        switch status {
        case .running:
            "ba.widget.timeline.status.running"
        case .upcoming:
            "ba.widget.timeline.status.upcoming"
        case .ended:
            "ba.widget.timeline.status.ended"
        }
    }

    private var color: Color {
        switch status {
        case .running:
            .green
        case .upcoming:
            .orange
        case .ended:
            .secondary
        }
    }
}

private extension BaTimelineGlanceSnapshot {
    var primaryFeaturedItem: BaTimelineGlanceItem? {
        activities.featuredItem ?? pools.featuredItem
    }
}
