//
//  BaDashboardResourceWidgets.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

struct BaDashboardResourcesWidgetView: View {
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

private struct BaResourceSmallWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 10) {
                BaWidgetCompactHeader(snapshot: snapshot)

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
            HStack(alignment: .top, spacing: 12) {
                BaResourceMediumColumn(snapshot: snapshot, date: entry.date)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        VStack(alignment: .leading, spacing: 10) {
            BaWidgetCompactHeader(snapshot: snapshot)
            BaResourceSummaryTable(snapshot: snapshot, date: date, style: .medium)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct BaAPCircularWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let summary = snapshot.glanceSummary(at: entry.date)
            Gauge(value: Double(summary.currentAP), in: 0...Double(max(summary.apLimit, 1))) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(BaWidgetPalette.ap)
            } currentValueLabel: {
                VStack(spacing: -1) {
                    Text("ba.widget.ap.title")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("\(summary.currentAP)")
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
            .accessibilityValue(Text("\(summary.currentAP)/\(summary.apLimit)"))
        } else {
            Image(systemName: "bolt.slash.fill")
        }
    }
}

private struct BaAPInlineWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let summary = snapshot.glanceSummary(at: entry.date)
            Text("AP \(summary.currentAP)/\(summary.apLimit)")
        } else {
            Text("ba.widget.empty.inline")
        }
    }
}

private struct BaAPRectangularWidget: View {
    let entry: BaDashboardWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let summary = snapshot.glanceSummary(at: entry.date)
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

                    Text("\(summary.currentAP)/\(summary.apLimit)")
                        .font(.callout.monospacedDigit().weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                        .contentTransition(.numericText())
                }

                HStack(alignment: .center, spacing: 7) {
                    BaWidgetCompactMeter(
                        value: Double(summary.currentAP),
                        limit: Double(max(summary.apLimit, 1)),
                        tint: BaWidgetPalette.ap
                    )
                    .frame(width: 42, height: 4)

                    BaWidgetFullTimeText(date: summary.apFullAt, now: entry.date)
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
            .accessibilityValue(Text("\(summary.currentAP)/\(summary.apLimit)"))
        } else {
            BaWidgetNoDataCompactView()
        }
    }
}

private struct BaResourceSummaryTable: View {
    let snapshot: BaWatchDashboardSnapshot
    let date: Date
    let style: BaResourceSummaryTableStyle

    var body: some View {
        let summary = snapshot.glanceSummary(at: date)

        VStack(alignment: .leading, spacing: style.itemSpacing) {
            BaResourceSummaryRow(
                title: Text("ba.widget.ap.title"),
                value: "\(summary.currentAP)/\(summary.apLimit)",
                footnote: BaWidgetFullTimeText(date: summary.apFullAt, now: date),
                systemImage: "bolt.fill",
                tint: BaWidgetPalette.ap,
                meterValue: Double(summary.currentAP),
                meterLimit: Double(max(summary.apLimit, 1)),
                style: style
            )

            BaResourceSummaryRow(
                title: Text("ba.widget.cafeAP.title"),
                shortTitle: Text("ba.widget.cafeAP.shortTitle"),
                value: "\(summary.currentCafeAP)/\(summary.cafeAPCapacity)",
                footnote: BaWidgetFullTimeText(date: summary.cafeAPFullAt, now: date),
                systemImage: "cup.and.saucer.fill",
                tint: BaWidgetPalette.cafeAP,
                meterValue: Double(summary.currentCafeAP),
                meterLimit: Double(max(summary.cafeAPCapacity, 1)),
                style: style,
                labelDisplayMode: style.cafeLabelDisplayMode
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
    var labelDisplayMode: BaWidgetResourceLabel.DisplayMode = .text

    var body: some View {
        VStack(alignment: .leading, spacing: style.rowSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: style.headerSpacing) {
                BaWidgetResourceLabel(
                    title: title,
                    shortTitle: shortTitle,
                    systemImage: systemImage,
                    tint: tint,
                    displayMode: labelDisplayMode
                )

                Spacer(minLength: style.valueSpacing)

                ViewThatFits(in: .horizontal) {
                    Text(value)
                        .font(style.valueFont)
                        .allowsTightening(true)
                    Text(value)
                        .font(style.compactValueFont)
                        .allowsTightening(true)
                    Text(value)
                        .font(style.minimumValueFont)
                        .allowsTightening(true)
                }
                    .lineLimit(1)
                    .minimumScaleFactor(style.valueMinimumScale)
                    .multilineTextAlignment(.trailing)
                    .layoutPriority(2)
                    .contentTransition(.numericText())
            }

            HStack(alignment: .center, spacing: style.meterSpacing) {
                BaWidgetCompactMeter(value: meterValue, limit: meterLimit, tint: tint)
                    .frame(minWidth: style.meterMinimumWidth, maxWidth: .infinity)
                    .frame(height: style.meterHeight)

                footnote
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(style.footnoteMinimumScale)
                    .layoutPriority(2)
            }
        }
    }
}

private struct BaWidgetResourceLabel: View {
    enum DisplayMode {
        case iconOnly
        case text
    }

    let title: Text
    var shortTitle: Text? = nil
    let systemImage: String
    let tint: Color
    var displayMode: DisplayMode = .text

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)

            if displayMode == .text {
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
        .layoutPriority(0)
    }
}

private enum BaResourceSummaryTableStyle {
    case small
    case medium

    var rowSpacing: CGFloat {
        switch self {
        case .small:
            3
        case .medium:
            2
        }
    }

    var itemSpacing: CGFloat {
        switch self {
        case .small:
            8
        case .medium:
            9
        }
    }

    var headerSpacing: CGFloat {
        switch self {
        case .small:
            4
        case .medium:
            8
        }
    }

    var valueSpacing: CGFloat {
        switch self {
        case .small:
            4
        case .medium:
            6
        }
    }

    var meterSpacing: CGFloat {
        switch self {
        case .small:
            6
        case .medium:
            7
        }
    }

    var valueFont: Font {
        switch self {
        case .small:
            .title3.monospacedDigit().weight(.bold)
        case .medium:
            .title2.monospacedDigit().weight(.bold)
        }
    }

    var compactValueFont: Font {
        switch self {
        case .small:
            .headline.monospacedDigit().weight(.bold)
        case .medium:
            .title3.monospacedDigit().weight(.bold)
        }
    }

    var minimumValueFont: Font {
        switch self {
        case .small:
            .subheadline.monospacedDigit().weight(.bold)
        case .medium:
            .headline.monospacedDigit().weight(.bold)
        }
    }

    var valueMinimumScale: CGFloat {
        switch self {
        case .small:
            0.58
        case .medium:
            0.62
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

    var meterMinimumWidth: CGFloat {
        switch self {
        case .small:
            42
        case .medium:
            56
        }
    }

    var footnoteMinimumScale: CGFloat {
        switch self {
        case .small:
            0.58
        case .medium:
            0.64
        }
    }

    var cafeLabelDisplayMode: BaWidgetResourceLabel.DisplayMode {
        switch self {
        case .small:
            .iconOnly
        case .medium:
            .text
        }
    }
}
