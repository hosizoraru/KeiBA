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

    var overviewDashboardRefreshInterval: TimeInterval {
        60
    }

    var overviewInnerGridColumnCount: Int {
        overviewColumnCount > 1 ? 2 : (containerWidth >= 760 ? 3 : 2)
    }

    var overviewInnerGridColumns: [GridItem] {
        return Array(
            repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
            count: overviewInnerGridColumnCount
        )
    }

    var usesCompactOverviewIdentityLayout: Bool {
        overviewCardInnerWidth < 370
    }

    var overviewSummaryGridColumnCount: Int {
        widthClass == .compact ? 1 : 2
    }

    var overviewSummaryGridColumns: [GridItem] {
        return Array(
            repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
            count: overviewSummaryGridColumnCount
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

    var timelineImageMaxPixelDimension: Int {
        #if os(macOS)
            640
        #else
            switch widthClass {
            case .compact:
                512
            case .regular:
                640
            case .expanded:
                768
            }
        #endif
    }

    var usesTimelineImageBackdrop: Bool {
        #if os(macOS)
            false
        #else
            widthClass != .compact
        #endif
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
        if timelineColumnCount == 1 {
            let target = (timelineCardColumnWidth * 0.24).rounded(.toNearestOrAwayFromZero)
            return min(max(target, 76), 88)
        }
        let target = (timelineCardColumnWidth * 0.28).rounded(.toNearestOrAwayFromZero)
        return min(max(target, 82), 92)
    }

    var poolCardThumbnailCornerRadius: CGFloat {
        min(max(poolCardThumbnailSize * 0.22, 16), 20)
    }

    var poolCardThumbnailMaxPixelDimension: Int {
        #if os(macOS)
            192
        #else
            widthClass == .compact ? 192 : 224
        #endif
    }

    var detailImageMaxPixelDimension: Int {
        #if os(macOS)
            900
        #else
            switch widthClass {
            case .compact:
                640
            case .regular:
                768
            case .expanded:
                900
            }
        #endif
    }

    var catalogColumnCount: Int {
        #if os(macOS)
            if containerWidth >= 1280 {
                return 4
            }
            if containerWidth >= 840 {
                return 3
            }
            if containerWidth >= 560 {
                return 2
            }
            return 1
        #else
            if widthClass == .compact {
                return 1
            }
            return containerWidth >= 1180 ? 3 : 2
        #endif
    }

    var catalogGridSpacing: CGFloat {
        #if os(macOS)
            12
        #else
            14
        #endif
    }

    var catalogColumnMinWidth: CGFloat {
        #if os(macOS)
            230
        #else
            280
        #endif
    }

    var catalogCardMaxWidth: CGFloat {
        #if os(macOS)
            286
        #else
            catalogColumnCount == 3 ? 384 : 433
        #endif
    }

    var catalogContentMaxWidth: CGFloat {
        let columns = CGFloat(max(catalogColumnCount, 1))
        return columns * catalogCardMaxWidth + CGFloat(max(catalogColumnCount - 1, 0)) * catalogGridSpacing
    }

    var catalogThumbnailSize: CGFloat {
        #if os(macOS)
            46
        #else
            widthClass == .compact ? BaIconToken.rowThumbnail : 54
        #endif
    }

    var catalogThumbnailMaxPixelDimension: Int {
        #if os(macOS)
            128
        #else
            widthClass == .compact ? 160 : 176
        #endif
    }

    var catalogCardMinHeight: CGFloat {
        #if os(macOS)
            74
        #else
            86
        #endif
    }

    var catalogCardCornerRadius: CGFloat {
        #if os(macOS)
            16
        #else
            20
        #endif
    }

    var catalogCardHorizontalPadding: CGFloat {
        #if os(macOS)
            12
        #else
            14
        #endif
    }

    var catalogCardVerticalPadding: CGFloat {
        #if os(macOS)
            10
        #else
            12
        #endif
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

    private var dashboardReadableWidth: CGFloat {
        let availableWidth = max(containerWidth - screenHorizontalPadding * 2, 1)
        guard let dashboardContentMaxWidth else { return availableWidth }
        return min(availableWidth, dashboardContentMaxWidth)
    }

    private var overviewCardInnerWidth: CGFloat {
        let cardWidth: CGFloat
        if overviewColumnCount > 1 {
            let totalSpacing = cardSpacing * CGFloat(overviewColumnCount - 1)
            cardWidth = max((dashboardReadableWidth - totalSpacing) / CGFloat(overviewColumnCount), 1)
        } else {
            cardWidth = dashboardReadableWidth
        }
        return max(cardWidth - cardPadding * 2, 1)
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
