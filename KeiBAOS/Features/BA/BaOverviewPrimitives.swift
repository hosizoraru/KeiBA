//
//  BaOverviewPrimitives.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

enum BaOverviewGrid {
    static let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]
}

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

struct BaOverviewAPReadout: View {
    let currentAP: String
    let remaining: String
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BaGameAssetIcon(.actionPoint, size: BaOverviewMetricStyle.mainIcon)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "ba.office.ap.current.title"))
                    .font(BaOverviewTextToken.caption)
                    .foregroundStyle(.secondary)
                Text(currentAP)
                    .font(.largeTitle.monospacedDigit().weight(.semibold))
                    .foregroundStyle(BaDesign.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())
                Text(remaining)
                    .font(BaOverviewTextToken.timeDetail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Button(action: onEdit) {
                Label(String(localized: "ba.overview.ap.edit.title"), systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(String(localized: "ba.overview.ap.edit.title"))
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18, tint: BaDesign.green.opacity(0.045), isInteractive: false)
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
    let title: String
    let entryTitle: String
    let timeText: String
    let syncAt: Date?
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(BaOverviewTextToken.rowTitle)
                .foregroundStyle(.primary)
                .frame(height: 24, alignment: .leading)

            Text(entryTitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(height: 44, alignment: .topLeading)

            Text(timeText)
                .font(BaOverviewTextToken.timeValue)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(height: 24, alignment: .leading)

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
