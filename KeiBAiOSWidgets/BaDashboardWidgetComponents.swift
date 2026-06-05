//
//  BaDashboardWidgetComponents.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

struct BaWidgetHeader: View {
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
                    .privacySensitive()
            }

            Spacer(minLength: 0)
        }
    }
}

struct BaWidgetCompactHeader: View {
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
                    .privacySensitive()
            }

            Spacer(minLength: 0)
        }
    }
}

struct BaWidgetCompactMeter: View {
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

struct BaResourceMiniPill: View {
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

struct BaWidgetFullTimeText: View {
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

struct BaWidgetNoDataView: View {
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

struct BaWidgetNoDataCompactView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("ba.widget.empty.inline")
        }
        .font(.caption.weight(.semibold))
    }
}

enum BaWidgetPalette {
    static let ap = Color(red: 0.20, green: 0.90, blue: 0.24)
    static let cafeAP = Color(red: 1.00, green: 0.42, blue: 0.74)
    static let activity = Color.orange
    static let pool = Color.pink
}

extension View {
    func baWidgetRootFrame(alignment: Alignment = .topLeading) -> some View {
        modifier(BaWidgetRootFrameModifier(alignment: alignment))
    }
}

private struct BaWidgetRootFrameModifier: ViewModifier {
    let alignment: Alignment

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var contentMargins

    func body(content: Content) -> some View {
        content
            .padding(resolvedPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    private var resolvedPadding: EdgeInsets {
        let margins = contentMargins

        switch family {
        case .systemSmall:
            return EdgeInsets(
                top: clipped(margins.top, preferred: 10),
                leading: clipped(margins.leading, preferred: 10),
                bottom: clipped(margins.bottom, preferred: 10),
                trailing: clipped(margins.trailing, preferred: 10)
            )
        case .systemMedium:
            return EdgeInsets(
                top: clipped(margins.top, preferred: 12),
                leading: clipped(margins.leading, preferred: 14),
                bottom: clipped(margins.bottom, preferred: 12),
                trailing: clipped(margins.trailing, preferred: 14)
            )
        case .systemLarge:
            return EdgeInsets(
                top: clipped(margins.top, preferred: 14),
                leading: clipped(margins.leading, preferred: 14),
                bottom: clipped(margins.bottom, preferred: 14),
                trailing: clipped(margins.trailing, preferred: 14)
            )
        default:
            return EdgeInsets()
        }
    }

    private func clipped(_ systemValue: CGFloat, preferred: CGFloat) -> CGFloat {
        guard systemValue > 0 else {
            return preferred
        }
        return max(8, min(systemValue, preferred))
    }
}
