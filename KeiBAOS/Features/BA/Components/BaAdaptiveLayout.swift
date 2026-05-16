//
//  BaAdaptiveLayout.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

enum BaAdaptiveWidthClass: Hashable {
    case compact
    case regular
    case expanded
}

struct BaAdaptiveMetrics: Equatable {
    let containerWidth: CGFloat
    let widthClass: BaAdaptiveWidthClass

    init(containerWidth: CGFloat) {
        self.containerWidth = max(containerWidth, 1)
        widthClass = Self.widthClass(for: containerWidth)
    }

    var screenHorizontalPadding: CGFloat {
        switch widthClass {
        case .compact:
            20
        case .regular:
            24
        case .expanded:
            28
        }
    }

    var screenVerticalPadding: CGFloat {
        switch widthClass {
        case .compact:
            16
        case .regular, .expanded:
            18
        }
    }

    var cardSpacing: CGFloat {
        switch widthClass {
        case .compact:
            18
        case .regular, .expanded:
            16
        }
    }

    var cardPadding: CGFloat {
        switch widthClass {
        case .compact:
            16
        case .regular, .expanded:
            17
        }
    }

    var readableContentMaxWidth: CGFloat? {
        switch widthClass {
        case .compact:
            nil
        case .regular:
            760
        case .expanded:
            1120
        }
    }

    var dashboardContentMaxWidth: CGFloat? {
        switch widthClass {
        case .compact:
            nil
        case .regular:
            820
        case .expanded:
            1180
        }
    }

    var listRowHorizontalInset: CGFloat {
        switch widthClass {
        case .compact:
            16
        case .regular:
            22
        case .expanded:
            28
        }
    }

    var overviewColumnCount: Int {
        containerWidth >= 760 ? 2 : 1
    }

    var timelineColumnCount: Int {
        widthClass == .compact ? 1 : 2
    }

    var overviewInnerGridColumns: [GridItem] {
        let count = overviewColumnCount > 1 ? 2 : (containerWidth >= 760 ? 3 : 2)
        return Array(
            repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
            count: count
        )
    }

    var overviewSummaryGridColumns: [GridItem] {
        let count = widthClass == .compact ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
            count: count
        )
    }

    var timelineCardImageHeight: CGFloat {
        guard timelineColumnCount > 1 else { return 172 }
        let targetHeight = (timelineCardColumnWidth / 1.92).rounded(.toNearestOrAwayFromZero)
        switch widthClass {
        case .compact:
            return 172
        case .regular:
            return min(max(targetHeight, 156), 214)
        case .expanded:
            return min(max(targetHeight, 220), 270)
        }
    }

    var timelineCardHorizontalPadding: CGFloat {
        widthClass == .expanded ? 16 : 14
    }

    var timelineCardVerticalPadding: CGFloat {
        widthClass == .expanded ? 15 : 13
    }

    var overviewTimelineTitleLineLimit: Int {
        widthClass == .compact ? 2 : 3
    }

    var poolCardThumbnailSize: CGFloat {
        guard timelineColumnCount > 1 else { return 88 }
        return containerWidth < 760 ? 84 : 92
    }

    var usesFullWidthPageRail: Bool {
        containerWidth >= 760
    }

    private static func widthClass(for width: CGFloat) -> BaAdaptiveWidthClass {
        if width >= 980 {
            return .expanded
        }
        if width >= 640 {
            return .regular
        }
        return .compact
    }

    private var timelineReadableWidth: CGFloat {
        let contentWidth = min(containerWidth, readableContentMaxWidth ?? containerWidth)
        return max(contentWidth - listRowHorizontalInset * 2, 1)
    }

    private var timelineCardColumnWidth: CGFloat {
        guard timelineColumnCount > 1 else { return timelineReadableWidth }
        let totalSpacing = cardSpacing * CGFloat(timelineColumnCount - 1)
        return max((timelineReadableWidth - totalSpacing) / CGFloat(timelineColumnCount), 1)
    }
}

private struct BaAdaptiveMetricsKey: EnvironmentKey {
    static let defaultValue = BaAdaptiveMetrics(containerWidth: 390)
}

extension EnvironmentValues {
    var baAdaptiveMetrics: BaAdaptiveMetrics {
        get { self[BaAdaptiveMetricsKey.self] }
        set { self[BaAdaptiveMetricsKey.self] = newValue }
    }
}

struct BaAdaptiveGeometry<Content: View>: View {
    let content: (BaAdaptiveMetrics) -> Content

    init(@ViewBuilder content: @escaping (BaAdaptiveMetrics) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = BaAdaptiveMetrics(containerWidth: proxy.size.width)
            content(metrics)
                .environment(\.baAdaptiveMetrics, metrics)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension View {
    func baAdaptiveReadableContent(maxWidth explicitMaxWidth: CGFloat? = nil) -> some View {
        modifier(BaAdaptiveReadableContentModifier(explicitMaxWidth: explicitMaxWidth))
    }

    func baAdaptiveListCardRow(top: CGFloat = 8, bottom: CGFloat = 10) -> some View {
        modifier(BaAdaptiveClearListRowModifier(top: top, bottom: bottom))
    }
}

private struct BaAdaptiveReadableContentModifier: ViewModifier {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let explicitMaxWidth: CGFloat?

    func body(content: Content) -> some View {
        let preferredMaxWidth = explicitMaxWidth ?? metrics.readableContentMaxWidth
        if let preferredMaxWidth {
            content
                .frame(maxWidth: preferredMaxWidth, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            content
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct BaAdaptiveClearListRowModifier: ViewModifier {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let top: CGFloat
    let bottom: CGFloat

    func body(content: Content) -> some View {
        content
            .baAdaptiveReadableContent()
            .listRowInsets(
                EdgeInsets(
                    top: top,
                    leading: metrics.listRowHorizontalInset,
                    bottom: bottom,
                    trailing: metrics.listRowHorizontalInset
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

extension Array {
    func baChunked(into size: Int) -> [[Element]] {
        guard size > 1 else { return map { [$0] } }
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start ..< Swift.min(start + size, count)])
        }
    }
}
