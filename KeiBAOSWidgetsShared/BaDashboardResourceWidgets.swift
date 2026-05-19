//
//  BaDashboardResourceWidgets.swift
//  KeiBAOS
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
