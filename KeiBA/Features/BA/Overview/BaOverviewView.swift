//
//  BaOverviewView.swift
//  KeiBA
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaOverviewView: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baAdaptiveMetrics) private var metrics

    var onOpenTab: (AppTab) -> Void = { _ in }
    var onOpenSheet: (BaPresentedSheet) -> Void = { _ in }

    var body: some View {
        BaScreenScaffold {
            TimelineView(.periodic(from: .now, by: metrics.overviewDashboardRefreshInterval)) { context in
                let office = model.officeSnapshot(now: context.date)
                let summary = BaOverviewTimelineSummary(
                    activities: model.activityState.value ?? [],
                    pools: model.poolState.value ?? [],
                    now: context.date
                )

                BaOverviewAdaptiveCards {
                    BaOverviewIdentityCard(
                        settings: model.settings,
                        account: model.currentAccount,
                        accounts: model.switchableAccounts,
                        watchSyncState: model.watchSyncState,
                        onAccountSelected: selectAccount,
                        onManageAccounts: { onOpenSheet(.editOffice) },
                        onOpenWatchSettings: { onOpenSheet(.watch) }
                    )
                } ap: {
                    BaOverviewAPCard(
                        office: office,
                        settings: model.settings,
                        onCommit: model.setAPEditorValues
                    )
                } cafe: {
                    BaOverviewCafeCard(
                        office: office,
                        settings: model.settings,
                        onClaimCafeAP: model.claimCafeAP,
                        onPerformAction: model.performCafeAction,
                        onResetAction: model.resetCafeAction,
                        onCafeSettingsCommit: setCafeSettings
                    )
                } timeline: {
                    BaOverviewTimelineSummaryCard(
                        summary: summary,
                        activitySyncAt: model.activityState.lastSyncAt,
                        poolSyncAt: model.poolState.lastSyncAt,
                        onOpenTab: onOpenTab
                    )
                }
            }
        }
        .task(id: model.settings.server) {
            model.refreshOfficeSnapshot()
            model.refreshWatchSyncState()
            await Task.yield()
            let cacheSignpost = BaStartupInstrumentation.begin("Overview Startup Cache")
            await model.loadTimelineCachesIfNeeded()
            BaStartupInstrumentation.end("Overview Startup Cache", cacheSignpost)
            try? await Task.sleep(for: BaPlatformPerformanceProfile.overviewStartupNetworkDelay)
            guard Task.isCancelled == false else { return }
            let refreshSignpost = BaStartupInstrumentation.begin("Overview Startup Refresh")
            await model.refreshTimelineIfNeeded()
            BaStartupInstrumentation.end("Overview Startup Refresh", refreshSignpost)
        }
    }

    private func selectAccount(_ accountID: BaAccountID) {
        model.selectAccount(accountID)
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
