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
                BaGameAssetIcon(asset, size: BaOverviewMetricStyle.rowIcon)
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
            Image(systemName: systemImage)
                .font(.system(size: BaOverviewMetricStyle.badgeIcon, weight: .semibold))
                .foregroundStyle(tint)
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
                    BaGameAssetIcon(asset, size: BaOverviewMetricStyle.rowIcon)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: BaOverviewMetricStyle.badgeIcon, weight: .semibold))
                        .foregroundStyle(tint)
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
            BaGameAssetIcon(asset, size: BaOverviewMetricStyle.mainIcon)

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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.compactTileSpacing) {
                HStack(spacing: 7) {
                    BaGameAssetIcon(action.asset, size: BaOverviewMetricStyle.rowIcon)
                        .frame(width: BaOverviewMetricStyle.rowIcon, height: BaOverviewMetricStyle.rowIcon)

                    Text(action.title)
                        .font(BaOverviewTextToken.rowTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Spacer(minLength: 0)

                    Image(systemName: action.isReady ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: BaOverviewMetricStyle.badgeIcon, weight: .semibold))
                        .foregroundStyle(action.isReady ? BaDesign.green : tint)
                        .frame(width: BaOverviewMetricStyle.badgeIcon, height: BaOverviewMetricStyle.badgeIcon)
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
        .buttonStyle(.plain)
        .contextMenu {
            Button(
                String(localized: "ba.overview.action.resetCooldown"),
                systemImage: "arrow.counterclockwise",
                action: onReset
            )
        }
        .accessibilityLabel(action.title)
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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(BaOverviewTextToken.rowTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(height: 24, alignment: .leading)

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
            return String(localized: "ba.state.notSynced")
        }
        return String(
            format: String(localized: "ba.state.syncedAt.format"),
            BaDisplayFormatters.syncTime(syncAt, includingSeconds: false)
        )
    }
}
