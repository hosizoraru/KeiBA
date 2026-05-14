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
            BaOverviewAPCard(
                office: model.officeSnapshot,
                settings: model.settings,
                onCurrentAPCommit: model.setCurrentAP,
                onLimitCommit: model.setAPLimit
            )
            BaOverviewCafeCard(
                office: model.officeSnapshot,
                onClaimCafeAP: model.claimCafeAP,
                onPerformAction: model.performCafeAction,
                onResetAction: model.resetCafeAction
            )
            BaOverviewTimelineSummaryCard(
                activities: model.activityState.value ?? [],
                pools: model.poolState.value ?? [],
                activitySyncAt: model.activityState.lastSyncAt,
                poolSyncAt: model.poolState.lastSyncAt,
                server: model.settings.server,
                onOpenTab: onOpenTab
            )
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
}

#Preview {
    NavigationStack {
        BaOverviewView()
    }
    .environment(BaAppModel.live())
}
