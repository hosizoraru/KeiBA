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

            BaOverviewIdentityCard(
                settings: model.settings,
                onServerSelected: selectServer
            )
            TimelineView(.periodic(from: .now, by: 1)) { context in
                BaOverviewAPCard(
                    office: model.officeAPSnapshot(now: context.date),
                    settings: model.settings,
                    onCommit: model.setAPEditorValues
                )
            }
            TimelineView(.periodic(from: .now, by: 60)) { context in
                BaOverviewCafeCard(
                    office: model.officeSnapshot(now: context.date),
                    settings: model.settings,
                    onClaimCafeAP: model.claimCafeAP,
                    onPerformAction: model.performCafeAction,
                    onResetAction: model.resetCafeAction,
                    onCafeSettingsCommit: setCafeSettings
                )
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

#Preview {
    NavigationStack {
        BaOverviewView()
    }
    .environment(BaAppModel.live())
}
