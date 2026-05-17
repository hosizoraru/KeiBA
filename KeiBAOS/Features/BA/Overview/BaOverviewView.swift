//
//  BaOverviewView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaOverviewView: View {
    @Environment(BaAppModel.self) private var model

    var onOpenTab: (AppTab) -> Void = { _ in }

    var body: some View {
        BaScreenScaffold {
            BaOverviewAdaptiveCards {
                BaOverviewIdentityCard(
                    settings: model.settings,
                    onServerSelected: selectServer
                )
            } ap: {
                BaOverviewAPTimelineCard(onCommit: model.setAPEditorValues)
            } cafe: {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    BaOverviewCafeCard(
                        office: model.officeSnapshot(now: context.date),
                        settings: model.settings,
                        onClaimCafeAP: model.claimCafeAP,
                        onPerformAction: model.performCafeAction,
                        onResetAction: model.resetCafeAction,
                        onCafeSettingsCommit: setCafeSettings
                    )
                }
            } timeline: {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    BaOverviewTimelineSummaryCard(
                        summary: BaOverviewTimelineSummary(
                            activities: model.activityState.value ?? [],
                            pools: model.poolState.value ?? [],
                            now: context.date
                        ),
                        activitySyncAt: model.activityState.lastSyncAt,
                        poolSyncAt: model.poolState.lastSyncAt,
                        onOpenTab: onOpenTab
                    )
                }
            }
        }
        .task(id: model.settings.server) {
            model.refreshOfficeSnapshot()
            await Task.yield()
            async let activities: Void = model.loadActivitiesIfNeeded()
            async let pools: Void = model.loadPoolsIfNeeded()
            _ = await (activities, pools)
        }
    }

    private func selectServer(_ server: BaServer) {
        model.selectServer(server)
        Task {
            async let activities: Void = model.loadActivitiesIfNeeded()
            async let pools: Void = model.loadPoolsIfNeeded()
            _ = await (activities, pools)
        }
    }

    private func setCafeSettings(level: Int, threshold: Int) {
        model.updateCurrentProfile { profile in
            profile.cafeLevel = min(max(level, 1), 10)
            profile.cafeApNotifyThreshold = min(max(threshold, 0), BaTimeMath.apMax)
        }
    }
}

private struct BaOverviewAPTimelineCard: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baAdaptiveMetrics) private var metrics

    let onCommit: (Int, Int, Int) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: metrics.overviewAPRefreshInterval)) { context in
            BaOverviewAPCard(
                office: model.officeAPSnapshot(now: context.date),
                settings: model.settings,
                onCommit: onCommit
            )
        }
    }
}

private struct BaOverviewAdaptiveCards<Identity: View, AP: View, Cafe: View, Timeline: View>: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let identity: Identity
    let ap: AP
    let cafe: Cafe
    let timeline: Timeline

    init(
        @ViewBuilder identity: () -> Identity,
        @ViewBuilder ap: () -> AP,
        @ViewBuilder cafe: () -> Cafe,
        @ViewBuilder timeline: () -> Timeline
    ) {
        self.identity = identity()
        self.ap = ap()
        self.cafe = cafe()
        self.timeline = timeline()
    }

    var body: some View {
        if metrics.overviewColumnCount > 1 {
            HStack(alignment: .top, spacing: metrics.cardSpacing) {
                VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                    identity
                    cafe
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                    ap
                    timeline
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                identity
                ap
                cafe
                timeline
            }
        }
    }
}

#Preview {
    NavigationStack {
        BaOverviewView()
    }
    .environment(BaAppModel.live())
}
