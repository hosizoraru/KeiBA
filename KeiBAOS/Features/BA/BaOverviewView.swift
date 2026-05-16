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
            BaScreenHeader(
                title: String(localized: "ba.overview.title"),
                detail: String(localized: "ba.overview.detail")
            )

            BaOverviewAdaptiveCards {
                BaOverviewIdentityCard(
                    settings: model.settings,
                    onServerSelected: selectServer
                )
            } ap: {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    BaOverviewAPCard(
                        office: model.officeAPSnapshot(now: context.date),
                        settings: model.settings,
                        onCommit: model.setAPEditorValues
                    )
                }
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
            await model.loadActivitiesIfNeeded()
            await model.loadPoolsIfNeeded()
        }
    }

    private func selectServer(_ server: BaServer) {
        model.selectServer(server)
        Task {
            await model.loadActivitiesIfNeeded()
            await model.loadPoolsIfNeeded()
        }
    }

    private func setCafeSettings(level: Int, threshold: Int) {
        model.updateCurrentProfile { profile in
            profile.cafeLevel = min(max(level, 1), 10)
            profile.cafeApNotifyThreshold = min(max(threshold, 0), BaTimeMath.apMax)
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
            LazyVGrid(columns: columns, alignment: .leading, spacing: metrics.cardSpacing) {
                identity
                ap
                cafe
                timeline
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

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: metrics.cardSpacing, alignment: .top),
            count: metrics.overviewColumnCount
        )
    }
}

#Preview {
    NavigationStack {
        BaOverviewView()
    }
    .environment(BaAppModel.live())
}
