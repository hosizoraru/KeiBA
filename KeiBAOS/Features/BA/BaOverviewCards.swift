//
//  BaOverviewCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

enum BaOverviewTextToken {
    static let sectionTitle = Font.headline
    static let rowTitle = Font.subheadline.weight(.semibold)
    static let caption = Font.caption
    static let timeValue = Font.body.monospacedDigit().weight(.semibold)
    static let timeDetail = Font.caption
    static let primaryNumber = Font.title3.monospacedDigit().weight(.semibold)
    static let number = Font.body.monospacedDigit().weight(.semibold)
}

enum BaOverviewMetricStyle {
    static let cardSpacing: CGFloat = 14
    static let rowSpacing: CGFloat = 10
    static let mainIcon: CGFloat = 32
    static let rowIcon: CGFloat = 24
    static let badgeIcon: CGFloat = 16
    static let actionMinHeight: CGFloat = 92
}

struct BaOverviewIdentityCard: View {
    let settings: BaAppSettings
    let onServerSelected: (BaServer) -> Void

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.office.overview.title"), asset: .schale)

                HStack(alignment: .top, spacing: 14) {
                    BaGameAssetIcon(.schale, size: 44)
                        .frame(width: 50, height: 50)
                        .liquidGlassSurface(cornerRadius: 18, tint: BaDesign.blue.opacity(0.06), isInteractive: false)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(settings.nickname) \(String(localized: "ba.office.nickname.suffix"))")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(settings.friendCode)
                            .font(BaOverviewTextToken.number)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Picker(String(localized: "ba.settings.server.title"), selection: serverBinding) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                BaOverviewInfoPill(
                    title: String(localized: "ba.settings.identity.mode.title"),
                    value: settings.identityIndependentByServer
                        ? String(localized: "ba.settings.identity.mode.independent")
                        : String(localized: "ba.settings.identity.mode.shared"),
                    systemImage: "person.2.badge.gearshape",
                    tint: BaDesign.blue
                )
            }
        }
    }

    private var serverBinding: Binding<BaServer> {
        Binding(
            get: { settings.server },
            set: onServerSelected
        )
    }
}

struct BaOverviewAPCard: View {
    let office: BaOfficeAPSnapshot
    let settings: BaAppSettings
    let onCurrentAPCommit: (Int) -> Void
    let onThresholdCommit: (Int) -> Void

    @State private var isEditorPresented = false

    var body: some View {
        BaGlassCard(tint: BaDesign.green) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.office.ap.label"), asset: .actionPoint)

                BaOverviewAPReadout(
                    currentAP: office.apCurrentLimit,
                    remaining: office.apRemaining,
                    onEdit: { isEditorPresented = true }
                )

                LazyVGrid(columns: BaOverviewGrid.columns, spacing: 10) {
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.next.title"),
                        value: office.apNext,
                        detail: String(localized: "ba.office.ap.next.detail"),
                        asset: .actionPointTight,
                        tint: BaDesign.green
                    )
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.full.label"),
                        value: office.apFullAt,
                        detail: office.apFullRemain,
                        systemImage: "calendar.badge.checkmark",
                        tint: BaDesign.cyan
                    )
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.sync.label"),
                        value: office.apSyncAt,
                        detail: String(localized: "ba.overview.sync.detail"),
                        systemImage: "clock.arrow.circlepath",
                        tint: BaDesign.blue
                    )
                    Button {
                        isEditorPresented = true
                    } label: {
                        BaOverviewMetricTile(
                            title: String(localized: "ba.settings.ap.threshold.title"),
                            value: "\(settings.apNotifyThreshold)",
                            detail: String(localized: "ba.settings.threshold.edit.detail"),
                            systemImage: "bell.badge",
                            tint: BaDesign.amber
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.ap.edit.title"))
                }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            BaOverviewAPEditorSheet(
                currentAP: office.apCurrent,
                apThreshold: "\(settings.apNotifyThreshold)",
                apLimit: office.apLimit
            ) { currentAP, threshold in
                onCurrentAPCommit(currentAP)
                onThresholdCommit(threshold)
            }
        }
    }
}

struct BaOverviewCafeCard: View {
    let office: BaOfficeSnapshot
    let onClaimCafeAP: () -> Void
    let onPerformAction: (BaCafeActionKind) -> Void
    let onResetAction: (BaCafeActionKind) -> Void

    var body: some View {
        BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                HStack(spacing: 10) {
                    BaOverviewSectionTitle(title: String(localized: "ba.cafe.title"), asset: .cafeAP)
                    Spacer()
                    Button(action: onClaimCafeAP) {
                        Label(String(localized: "ba.cafe.action.claimAp"), systemImage: "tray.and.arrow.down.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(String(localized: "ba.cafe.action.claimAp"))
                }

                HStack(spacing: 12) {
                    BaGameAssetIcon(.cafeAP, size: BaOverviewMetricStyle.mainIcon)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "ba.cafe.storage.title"))
                            .font(BaOverviewTextToken.rowTitle)
                        Text(String(localized: "ba.overview.cafe.shared.detail"))
                            .font(BaOverviewTextToken.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 10)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(office.cafeApCurrent)/\(office.cafeApLimit)")
                            .font(BaOverviewTextToken.primaryNumber)
                            .foregroundStyle(BaDesign.pink)
                        Text(office.cafeLevel)
                            .font(BaOverviewTextToken.timeDetail)
                            .foregroundStyle(.secondary)
                    }
                }

                LazyVGrid(columns: BaOverviewGrid.columns, spacing: 10) {
                    BaOverviewMetricTile(
                        title: String(localized: "ba.cafe.metric.visit"),
                        value: office.cafeVisitRefresh,
                        detail: office.cafeVisitDetail,
                        asset: .lobbyWork,
                        tint: BaDesign.pink
                    )
                    BaOverviewMetricTile(
                        title: String(localized: "ba.cafe.metric.tactical"),
                        value: office.tacticalRefresh,
                        detail: office.tacticalRefreshDetail,
                        asset: .arenaCoin,
                        tint: BaDesign.amber
                    )
                }

                LazyVGrid(columns: BaOverviewGrid.actionColumns, spacing: 10) {
                    ForEach(office.cafeActions) { action in
                        BaOverviewActionTile(
                            action: action,
                            onTap: { onPerformAction(action.kind) },
                            onReset: { onResetAction(action.kind) }
                        )
                    }
                }
            }
        }
    }
}

struct BaOverviewTimelineSummary: Equatable {
    let activityTitle: String
    let activityTime: String
    let poolTitle: String
    let poolTime: String

    init(activities: [BaActivityEntry], pools: [BaPoolEntry], now: Date) {
        let activity = activities
            .filter { $0.status(at: now) != .ended }
            .sorted { $0.beginAt < $1.beginAt }
            .first
        let pool = pools
            .filter { $0.status(at: now) != .ended }
            .sorted { $0.startAt < $1.startAt }
            .first

        activityTitle = activity?.title ?? String(localized: "ba.overview.timeline.empty")
        activityTime = activity.map {
            BaDisplayFormatters.timelineDetail(
                start: $0.beginAt,
                end: $0.endAt,
                now: now,
                includingSeconds: false
            )
        } ?? String(localized: "ba.state.notSynced")
        poolTitle = pool?.name ?? String(localized: "ba.overview.timeline.empty")
        poolTime = pool.map {
            BaDisplayFormatters.timelineDetail(
                start: $0.startAt,
                end: $0.endAt,
                now: now,
                includingSeconds: false
            )
        } ?? String(localized: "ba.state.notSynced")
    }
}

struct BaOverviewTimelineSummaryCard: View {
    let summary: BaOverviewTimelineSummary
    let activitySyncAt: Date?
    let poolSyncAt: Date?
    let onOpenTab: (AppTab) -> Void

    var body: some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.overview.timeline.title"), asset: .guideMission)

                LazyVGrid(columns: BaOverviewGrid.columns, spacing: 10) {
                    Button {
                        onOpenTab(.activity)
                    } label: {
                        BaOverviewTimelineTile(
                            title: String(localized: "ba.tab.activity"),
                            entryTitle: summary.activityTitle,
                            timeText: summary.activityTime,
                            syncAt: activitySyncAt,
                            systemImage: "calendar",
                            tint: BaDesign.blue
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.timeline.openActivity"))

                    Button {
                        onOpenTab(.pool)
                    } label: {
                        BaOverviewTimelineTile(
                            title: String(localized: "ba.tab.pool"),
                            entryTitle: summary.poolTitle,
                            timeText: summary.poolTime,
                            syncAt: poolSyncAt,
                            systemImage: "sparkles",
                            tint: BaDesign.violet
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.timeline.openPool"))
                }
            }
        }
    }
}
