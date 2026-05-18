//
//  BaOverviewPrimitives.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaOverviewSectionTitle: View {
    let title: String
    var asset: BaGameAsset?

    var body: some View {
        HStack(spacing: 8) {
            if let asset {
                BaOverviewAssetIcon(asset, size: BaOverviewMetricStyle.sectionIconSlot)
            }
            Text(title)
                .font(BaOverviewTextToken.sectionTitle)
                .foregroundStyle(.primary)
        }
    }
}

struct BaOverviewInfoPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            BaOverviewSymbolIcon(systemImage, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BaOverviewTextToken.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(BaOverviewTextToken.rowTitle)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .liquidGlassSurface(cornerRadius: 16, tint: tint.opacity(0.045), isInteractive: false)
    }
}

struct BaOverviewAssetIcon: View {
    let asset: BaGameAsset
    let size: CGFloat
    var glyphSize: CGFloat?

    init(_ asset: BaGameAsset, size: CGFloat, glyphSize: CGFloat? = nil) {
        self.asset = asset
        self.size = size
        self.glyphSize = glyphSize
    }

    var body: some View {
        BaGameAssetIcon(
            asset,
            size: glyphSize ?? size,
            visualScale: asset.overviewIconVisualScale
        )
        .frame(width: size, height: size, alignment: .center)
        .accessibilityHidden(true)
    }
}

struct BaOverviewSymbolIcon: View {
    let systemImage: String
    let size: CGFloat
    let fontSize: CGFloat
    let tint: Color

    init(
        _ systemImage: String,
        size: CGFloat = BaOverviewMetricStyle.rowIconSlot,
        fontSize: CGFloat = BaOverviewMetricStyle.symbolIcon,
        tint: Color
    ) {
        self.systemImage = systemImage
        self.size = size
        self.fontSize = fontSize
        self.tint = tint
    }

    var body: some View {
        Image(systemName: systemImage)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: fontSize, weight: .semibold))
            .imageScale(.medium)
            .foregroundStyle(tint)
            .frame(width: size, height: size, alignment: .center)
            .accessibilityHidden(true)
    }
}

struct BaOverviewFixedGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columnCount: Int
    let spacing: CGFloat
    let content: (Item) -> Content

    init(
        items: [Item],
        columnCount: Int,
        spacing: CGFloat = 10,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columnCount = max(columnCount, 1)
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row) { item in
                        content(item)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(0 ..< placeholderCount(for: row), id: \.self) { _ in
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    private var rows: [[Item]] {
        items.baChunked(into: columnCount)
    }

    private func placeholderCount(for row: [Item]) -> Int {
        max(columnCount - row.count, 0)
    }
}

struct BaOverviewMetricTile: View {
    let title: String
    let value: String
    let detail: String
    var asset: BaGameAsset?
    var systemImage: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: BaOverviewMetricStyle.compactTileSpacing) {
            HStack(spacing: 7) {
                if let asset {
                    BaOverviewAssetIcon(asset, size: BaOverviewMetricStyle.rowIconSlot)
                } else if let systemImage {
                    BaOverviewSymbolIcon(systemImage, tint: tint)
                }
                Text(title)
                    .font(BaOverviewTextToken.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(height: BaOverviewMetricStyle.compactHeaderHeight, alignment: .leading)

            Text(value)
                .font(BaOverviewTextToken.timeValue)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .contentTransition(.numericText())
                .frame(height: BaOverviewMetricStyle.compactValueHeight, alignment: .leading)

            Text(detail)
                .font(BaOverviewTextToken.timeDetail)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .frame(height: BaOverviewMetricStyle.compactDetailHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, minHeight: BaOverviewMetricStyle.metricTileHeight, alignment: .topLeading)
        .padding(BaOverviewMetricStyle.compactTilePadding)
        .liquidGlassSurface(cornerRadius: 18, tint: tint.opacity(0.045), isInteractive: false)
    }
}

struct BaOverviewResourceReadout<Actions: View>: View {
    let title: String
    let value: String
    let detail: String
    let asset: BaGameAsset
    let tint: Color
    let actions: Actions

    init(
        title: String,
        value: String,
        detail: String,
        asset: BaGameAsset,
        tint: Color,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.asset = asset
        self.tint = tint
        self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BaOverviewAssetIcon(
                asset,
                size: BaOverviewMetricStyle.mainIconSlot,
                glyphSize: BaOverviewMetricStyle.mainIcon
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BaOverviewTextToken.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.largeTitle.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())

                Text(detail)
                    .font(BaOverviewTextToken.timeDetail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18, tint: tint.opacity(0.045), isInteractive: false)
        .accessibilityElement(children: .combine)
    }
}

struct BaOverviewIconGlassButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(title)
    }
}

struct BaOverviewActionTile: View {
    let action: BaCafeActionSnapshot
    let onTap: () -> Void
    let onReset: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                tileContent
            }
            .buttonStyle(.plain)

            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 8)
            .accessibilityLabel(BaL10n.string("ba.overview.action.resetCooldown"))
        }
        .accessibilityLabel(action.title)
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: BaOverviewMetricStyle.compactTileSpacing) {
            HStack(spacing: 7) {
                BaOverviewAssetIcon(action.asset, size: BaOverviewMetricStyle.rowIconSlot)

                Text(action.title)
                    .font(BaOverviewTextToken.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                BaOverviewSymbolIcon(
                    action.isReady ? "checkmark.circle.fill" : "clock.fill",
                    size: BaOverviewMetricStyle.badgeIconSlot,
                    fontSize: BaOverviewMetricStyle.badgeIcon,
                    tint: action.isReady ? BaDesign.green : tint
                )
                .padding(.trailing, 30)
            }
            .frame(height: BaOverviewMetricStyle.compactHeaderHeight, alignment: .leading)

            Text(action.value)
                .font(BaOverviewTextToken.timeValue)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .contentTransition(.numericText())
                .frame(height: BaOverviewMetricStyle.compactValueHeight, alignment: .leading)

            Text(action.detail)
                .font(BaOverviewTextToken.timeDetail)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .frame(height: BaOverviewMetricStyle.compactDetailHeight, alignment: .topLeading)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: BaOverviewMetricStyle.actionMinHeight,
            alignment: .topLeading
        )
        .padding(BaOverviewMetricStyle.compactTilePadding)
        .liquidGlassSurface(cornerRadius: 20, tint: tint.opacity(0.05), isInteractive: true)
    }

    private var tint: Color {
        switch action.tintName {
        case "green":
            BaDesign.green
        case "violet":
            BaDesign.violet
        case "amber":
            BaDesign.amber
        case "pink":
            BaDesign.pink
        default:
            BaDesign.blue
        }
    }
}

struct BaOverviewTimelineTile: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let title: String
    let item: BaOverviewTimelineSummaryItem
    let syncAt: Date?
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 7) {
                BaOverviewSymbolIcon(systemImage, tint: tint)

                Text(title)
                    .font(BaOverviewTextToken.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                BaOverviewSymbolIcon(
                    "chevron.right",
                    size: BaOverviewMetricStyle.badgeIconSlot,
                    fontSize: 12,
                    tint: .secondary
                )
            }
            .frame(height: BaOverviewMetricStyle.compactHeaderHeight, alignment: .leading)

            Text(item.primaryTitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(metrics.overviewTimelineTitleLineLimit)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)

            if let extraTitleText = item.extraTitleText {
                Text(extraTitleText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.remainingText)
                    .font(BaOverviewTextToken.timeValue)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .contentTransition(.numericText())

                if let endLineText = item.endLineText {
                    Text(endLineText)
                        .font(BaOverviewTextToken.timeDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }

            Text(syncText)
                .font(BaOverviewTextToken.timeDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(height: 18, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: BaOverviewMetricStyle.timelineTileHeight, alignment: .topLeading)
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18, tint: tint.opacity(0.045), isInteractive: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(item.accessibilityTitle)")
    }

    private var syncText: String {
        guard let syncAt else {
            return BaL10n.string("ba.state.notSynced")
        }
        return String(
            format: BaL10n.string("ba.state.syncedAt.format"),
            BaDisplayFormatters.syncTime(syncAt, includingSeconds: false)
        )
    }
}

private extension BaGameAsset {
    var overviewIconVisualScale: CGFloat {
        switch self {
        case .actionPoint:
            1.44
        case .actionPointTight:
            0.86
        case .arenaCoin:
            1.38
        case .guideMission:
            1.24
        case .guideMissionAlt:
            1.32
        case .dailyReward:
            0.88
        case .lobbyWork:
            0.96
        case .cafeAP:
            0.92
        case .cafeCoupon:
            0.98
        case .schale:
            1.04
        case .tabProfile, .tabSkill, .tabBGM, .tabPlay, .tabSimulate, .weaponStarBadge:
            1
        }
    }
}
