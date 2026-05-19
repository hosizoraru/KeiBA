//
//  BaDashboardWidgets.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

nonisolated struct BaDashboardWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: BaWatchDashboardSnapshot?
    let isPlaceholder: Bool

    static func placeholder(date: Date = Date()) -> BaDashboardWidgetEntry {
        BaDashboardWidgetEntry(
            date: date,
            snapshot: .widgetPreview(now: date),
            isPlaceholder: true
        )
    }

    static func current(date: Date = Date()) -> BaDashboardWidgetEntry {
        BaDashboardWidgetEntry(
            date: date,
            snapshot: BaDashboardSnapshotSharing.loadSnapshot(),
            isPlaceholder: false
        )
    }
}

nonisolated struct BaDashboardWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BaDashboardWidgetEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (BaDashboardWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder() : .current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BaDashboardWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = BaDashboardSnapshotSharing.loadSnapshot()
        let dates = BaDashboardWidgetSchedule.entryDates(for: snapshot, from: now)
        let entries = dates.map { date in
            BaDashboardWidgetEntry(date: date, snapshot: snapshot, isPlaceholder: false)
        }
        let refreshDate = dates.last?.addingTimeInterval(60) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

struct BaDashboardResourcesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: BaDashboardWidgetKind.resources,
            provider: BaDashboardWidgetProvider()
        ) { entry in
            BaDashboardResourcesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ba.widget.resources.name")
        .description("ba.widget.resources.description")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
    }
}

struct BaDashboardTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: BaDashboardWidgetKind.timeline,
            provider: BaDashboardWidgetProvider()
        ) { entry in
            BaDashboardTimelineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ba.widget.timeline.name")
        .description("ba.widget.timeline.description")
        #if os(watchOS)
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
        #endif
    }
}

private struct BaDashboardResourcesWidgetView: View {
    let entry: BaDashboardWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                BaAPCircularWidget(entry: entry)
            case .accessoryInline:
                BaAPInlineWidget(entry: entry)
            case .accessoryRectangular:
                BaAPRectangularWidget(entry: entry)
            case .systemMedium:
                BaResourceMediumWidget(entry: entry)
            default:
                BaResourceSmallWidget(entry: entry)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

private struct BaDashboardTimelineWidgetView: View {
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

private struct BaResourceSmallWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 8) {
                BaWidgetHeader(snapshot: snapshot)

                Spacer(minLength: 0)

                BaResourceSummaryTable(snapshot: snapshot, date: entry.date, style: .small)
            }
            .baWidgetRootFrame()
        } else {
            BaWidgetNoDataView()
        }
    }
}

private struct BaResourceMediumWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            HStack(alignment: .top, spacing: 14) {
                BaResourceMediumColumn(snapshot: snapshot, date: entry.date)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 10) {
                    BaTimelineFeaturedCompactSection(
                        title: Text("ba.widget.activity.title"),
                        section: snapshot.timeline.activities,
                        systemImage: "calendar.badge.clock",
                        tint: BaWidgetPalette.activity,
                        date: entry.date
                    )
                    BaTimelineFeaturedCompactSection(
                        title: Text("ba.widget.pool.title"),
                        section: snapshot.timeline.pools,
                        systemImage: "sparkles",
                        tint: BaWidgetPalette.pool,
                        date: entry.date
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .baWidgetRootFrame()
        } else {
            BaWidgetNoDataView()
        }
    }
}

private struct BaResourceMediumColumn: View {
    let snapshot: BaWatchDashboardSnapshot
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            BaWidgetCompactHeader(snapshot: snapshot)
            BaResourceSummaryTable(snapshot: snapshot, date: date, style: .medium)
        }
    }
}

private struct BaAPCircularWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let current = snapshot.currentAP(at: entry.date)
            Gauge(value: Double(current), in: 0...Double(max(snapshot.apLimit, 1))) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(BaWidgetPalette.ap)
            } currentValueLabel: {
                VStack(spacing: -1) {
                    Text("ba.widget.ap.title")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("\(current)")
                        .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.52)
                        .contentTransition(.numericText())
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(BaWidgetPalette.ap)
            .widgetAccentable()
            .accessibilityLabel(Text("ba.widget.ap.title"))
            .accessibilityValue(Text("\(current)/\(snapshot.apLimit)"))
        } else {
            Image(systemName: "bolt.slash.fill")
        }
    }
}

private struct BaAPInlineWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            Text("AP \(snapshot.currentAP(at: entry.date))/\(snapshot.apLimit)")
        } else {
            Text("ba.widget.empty.inline")
        }
    }
}

private struct BaAPRectangularWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let current = snapshot.currentAP(at: entry.date)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BaWidgetPalette.ap)

                    Text("ba.widget.ap.title")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text("\(current)/\(snapshot.apLimit)")
                        .font(.callout.monospacedDigit().weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                        .contentTransition(.numericText())
                }

                HStack(alignment: .center, spacing: 7) {
                    BaWidgetCompactMeter(
                        value: Double(current),
                        limit: Double(max(snapshot.apLimit, 1)),
                        tint: BaWidgetPalette.ap
                    )
                    .frame(width: 42, height: 4)

                    BaWidgetFullTimeText(date: snapshot.apFullAt(from: entry.date), now: entry.date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
            }
            .padding(.horizontal, 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .widgetAccentable()
            .accessibilityLabel(Text("ba.widget.ap.title"))
            .accessibilityValue(Text("\(current)/\(snapshot.apLimit)"))
        } else {
            BaWidgetNoDataCompactView()
        }
    }
}

private struct BaTimelineMediumWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 12) {
                BaWidgetHeader(snapshot: snapshot)

                HStack(alignment: .top, spacing: 14) {
                    BaTimelineFeaturedSection(
                        title: Text("ba.widget.activity.title"),
                        section: snapshot.timeline.activities,
                        systemImage: "calendar.badge.clock",
                        tint: BaWidgetPalette.activity,
                        date: entry.date
                    )
                    BaTimelineFeaturedSection(
                        title: Text("ba.widget.pool.title"),
                        section: snapshot.timeline.pools,
                        systemImage: "sparkles",
                        tint: BaWidgetPalette.pool,
                        date: entry.date
                    )
                }
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
            VStack(alignment: .leading, spacing: 14) {
                BaWidgetHeader(snapshot: snapshot)

                BaTimelineFeaturedSection(
                    title: Text("ba.widget.activity.title"),
                    section: snapshot.timeline.activities,
                    systemImage: "calendar.badge.clock",
                    tint: BaWidgetPalette.activity,
                    date: entry.date
                )
                BaTimelineFeaturedSection(
                    title: Text("ba.widget.pool.title"),
                    section: snapshot.timeline.pools,
                    systemImage: "sparkles",
                    tint: BaWidgetPalette.pool,
                    date: entry.date
                )

                Divider()

                HStack(spacing: 12) {
                    BaResourceMiniPill(
                        title: Text("ba.widget.ap.title"),
                        value: "\(snapshot.currentAP(at: entry.date))/\(snapshot.apLimit)",
                        systemImage: "bolt.fill",
                        tint: BaWidgetPalette.ap
                    )
                    BaResourceMiniPill(
                        title: Text("ba.widget.cafeAP.title"),
                        value: "\(snapshot.currentCafeAP(at: entry.date))/\(snapshot.cafeAPCapacity)",
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

private struct BaWidgetHeader: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tint)
                .frame(width: 20, height: 20)
                .background(.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.officeShortName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(snapshot.teacherName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct BaWidgetCompactHeader: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tint)
                .frame(width: 18, height: 18)
                .background(.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text(snapshot.officeShortName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(snapshot.teacherName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct BaResourceSummaryTable: View {
    let snapshot: BaWatchDashboardSnapshot
    let date: Date
    let style: BaResourceSummaryTableStyle

    var body: some View {
        VStack(alignment: .leading, spacing: style.itemSpacing) {
            BaResourceSummaryRow(
                title: Text("ba.widget.ap.title"),
                value: "\(snapshot.currentAP(at: date))/\(snapshot.apLimit)",
                footnote: BaWidgetFullTimeText(date: snapshot.apFullAt(from: date), now: date),
                systemImage: "bolt.fill",
                tint: BaWidgetPalette.ap,
                meterValue: Double(snapshot.currentAP(at: date)),
                meterLimit: Double(max(snapshot.apLimit, 1)),
                style: style
            )

            BaResourceSummaryRow(
                title: Text("ba.widget.cafeAP.title"),
                shortTitle: Text("ba.widget.cafeAP.shortTitle"),
                value: "\(snapshot.currentCafeAP(at: date))/\(snapshot.cafeAPCapacity)",
                footnote: BaWidgetFullTimeText(date: snapshot.cafeAPFullAt(from: date), now: date),
                systemImage: "cup.and.saucer.fill",
                tint: BaWidgetPalette.cafeAP,
                meterValue: Double(snapshot.currentCafeAP(at: date)),
                meterLimit: Double(max(snapshot.cafeAPCapacity, 1)),
                style: style
            )
        }
    }
}

private struct BaResourceSummaryRow<Footnote: View>: View {
    let title: Text
    var shortTitle: Text? = nil
    let value: String
    let footnote: Footnote
    let systemImage: String
    let tint: Color
    let meterValue: Double
    let meterLimit: Double
    let style: BaResourceSummaryTableStyle

    var body: some View {
        VStack(alignment: .leading, spacing: style.rowSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                BaWidgetResourceLabel(
                    title: title,
                    shortTitle: shortTitle,
                    systemImage: systemImage,
                    tint: tint
                )

                Spacer(minLength: 6)

                Text(value)
                    .font(style.valueFont)
                    .lineLimit(1)
                    .minimumScaleFactor(style.valueMinimumScale)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(1)
                    .contentTransition(.numericText())
            }

            HStack(alignment: .center, spacing: 7) {
                BaWidgetCompactMeter(value: meterValue, limit: meterLimit, tint: tint)
                    .frame(height: style.meterHeight)

                footnote
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                    .layoutPriority(1)
            }
        }
    }
}

private struct BaWidgetResourceLabel: View {
    let title: Text
    var shortTitle: Text? = nil
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)

            ViewThatFits(in: .horizontal) {
                title
                if let shortTitle {
                    shortTitle
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
    }
}

private enum BaResourceSummaryTableStyle {
    case small
    case medium

    var rowSpacing: CGFloat {
        2
    }

    var itemSpacing: CGFloat {
        switch self {
        case .small:
            7
        case .medium:
            6
        }
    }

    var valueFont: Font {
        switch self {
        case .small:
            .title3.monospacedDigit().weight(.bold)
        case .medium:
            .title3.monospacedDigit().weight(.bold)
        }
    }

    var valueMinimumScale: CGFloat {
        switch self {
        case .small:
            0.72
        case .medium:
            0.7
        }
    }

    var meterHeight: CGFloat {
        switch self {
        case .small:
            5
        case .medium:
            4
        }
    }
}

private struct BaWidgetCompactMeter: View {
    let value: Double
    let limit: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.20))
                Capsule()
                    .fill(tint)
                    .frame(width: max(proxy.size.width * min(max(value / limit, 0), 1), proxy.size.height))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
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
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        BaTimelineStatusLabel(status: item.status)
                        Spacer(minLength: 4)
                        Text(item.endAt, style: item.status == .running ? .relative : .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countSummary: String {
        String(format: String(localized: "ba.widget.timeline.counts.format"), section.runningCount, section.upcomingCount)
    }
}

private struct BaTimelineFeaturedCompactSection: View {
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
                    .minimumScaleFactor(0.78)

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

            Spacer(minLength: 4)

            if let countSummary {
                Text(countSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
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

private struct BaResourceMiniPill: View {
    let title: Text
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    title
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(value)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .layoutPriority(1)
                }

                VStack(alignment: .leading, spacing: 1) {
                    title
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(value)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .layoutPriority(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct BaWidgetFullTimeText: View {
    let date: Date?
    let now: Date

    var body: some View {
        if let date, date > now {
            Text(date, style: .relative)
        } else {
            Text("ba.widget.resource.full")
        }
    }
}

private struct BaWidgetNoDataView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tint)
            Text("ba.widget.empty.title")
                .font(.headline.weight(.semibold))
            Text("ba.widget.empty.message")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct BaWidgetNoDataCompactView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("ba.widget.empty.inline")
        }
        .font(.caption.weight(.semibold))
    }
}

private enum BaWidgetPalette {
    static let ap = Color(red: 0.20, green: 0.90, blue: 0.24)
    static let cafeAP = Color(red: 1.00, green: 0.42, blue: 0.74)
    static let activity = Color.orange
    static let pool = Color.pink
}

private extension View {
    func baWidgetRootFrame(alignment: Alignment = .topLeading) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

private extension BaTimelineGlanceSnapshot {
    var primaryFeaturedItem: BaTimelineGlanceItem? {
        activities.featuredItem ?? pools.featuredItem
    }
}

private enum BaDashboardWidgetSchedule {
    nonisolated static func entryDates(for snapshot: BaWatchDashboardSnapshot?, from now: Date) -> [Date] {
        guard let snapshot else {
            return [roundedMinute(now)]
        }

        var dates = Set<Date>()
        dates.insert(roundedMinute(now))

        for offset in 1...12 {
            dates.insert(roundedMinute(now.addingTimeInterval(TimeInterval(offset) * BaWatchTimeMath.apRegenInterval)))
        }

        for offset in 1...4 {
            dates.insert(roundedMinute(now.addingTimeInterval(TimeInterval(offset) * BaWatchTimeMath.cafeHourlyInterval)))
        }

        add(snapshot.apFullAt(from: now), to: &dates, now: now)
        add(snapshot.cafeAPFullAt(from: now), to: &dates, now: now)
        add(snapshot.timeline.activities.featuredItem?.startAt, to: &dates, now: now)
        add(snapshot.timeline.activities.featuredItem?.endAt, to: &dates, now: now)
        add(snapshot.timeline.pools.featuredItem?.startAt, to: &dates, now: now)
        add(snapshot.timeline.pools.featuredItem?.endAt, to: &dates, now: now)

        return Array(dates)
            .filter { $0 >= now.addingTimeInterval(-60) }
            .sorted()
            .prefix(24)
            .map { $0 }
    }

    nonisolated private static func add(_ date: Date?, to dates: inout Set<Date>, now: Date) {
        guard let date, date > now else { return }
        dates.insert(roundedMinute(date))
    }

    nonisolated private static func roundedMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60)
    }
}

private extension BaWatchDashboardSnapshot {
    nonisolated static func widgetPreview(now: Date) -> BaWatchDashboardSnapshot {
        BaWatchDashboardSnapshot(
            sourceUpdatedAt: now,
            generatedAt: now,
            officeName: "沙勒办公室",
            officeShortName: "沙勒",
            serverName: "国服",
            teacherName: "Voyager",
            friendCode: "BA26TEST",
            dutyStudentName: "阿罗娜",
            dutyStudentAvatarURLString: nil,
            dutyStudentAvatarImageData: nil,
            apBaseValue: 126,
            apLimit: 240,
            apRegenBaseAt: now.addingTimeInterval(-18 * 60),
            apNotificationsEnabled: true,
            apNotifyThreshold: 220,
            cafeLevel: 10,
            cafeAPBaseValue: 420,
            cafeStorageBaseAt: now.addingTimeInterval(-2 * 60 * 60),
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 650,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: true,
            favoriteStudentCount: 12,
            timeline: BaTimelineGlanceSnapshot(
                generatedAt: now,
                activities: BaTimelineGlanceSection(
                    runningCount: 2,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "特别委托活动",
                        status: .running,
                        startAt: now.addingTimeInterval(-2 * 24 * 60 * 60),
                        endAt: now.addingTimeInterval(20 * 60 * 60),
                        relatedItemCount: 1
                    ),
                    lastSyncAt: now,
                    isShowingCache: false
                ),
                pools: BaTimelineGlanceSection(
                    runningCount: 1,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "FES 招募",
                        status: .running,
                        startAt: now.addingTimeInterval(-6 * 60 * 60),
                        endAt: now.addingTimeInterval(3 * 24 * 60 * 60)
                    ),
                    lastSyncAt: now,
                    isShowingCache: false
                )
            )
        )
    }
}
