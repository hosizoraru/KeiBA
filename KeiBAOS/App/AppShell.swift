//
//  AppShell.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct AppShell: View {
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.titleResource, systemImage: tab.systemImage, value: tab) {
                    BaNavigationRoot(tab: tab) { selectedTab = $0 }
                        .accessibilityIdentifier(tab.accessibilityIdentifier)
                }
            }
        }
        .platformAdaptiveTabViewStyle()
    }
}

private struct BaNavigationRoot: View {
    @Environment(BaAppModel.self) private var model

    let tab: AppTab
    let onSelectTab: (AppTab) -> Void
    @State private var presentedSheet: BaPresentedSheet?
    @State private var activityFilter: BaTimelineStatus?
    @State private var poolFilter: BaTimelineStatus?

    var body: some View {
        NavigationStack {
            rootContent
                .navigationTitle(tab.navigationTitle)
                .platformLargeNavigationTitle()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        pageRefreshButton
                        notificationButton
                        moreMenu
                    }
                }
                .sheet(item: $presentedSheet) { sheet in
                    BaActionSheetRoot(sheet: sheet)
                        .baActionSheetPresentation()
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch tab {
        case .overview:
            BaOverviewView(onOpenTab: onSelectTab)
                .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
        case .activity:
            BaActivityView(statusFilter: $activityFilter)
                .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
        case .pool:
            BaPoolView(statusFilter: $poolFilter)
                .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
        case .catalog:
            BaCatalogView()
                .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
        case .library:
            BaLibraryView()
                .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
        }
    }

    @ViewBuilder
    private var pageRefreshButton: some View {
        switch tab {
        case .activity:
            Button {
                Task { await model.refreshActivities(force: true) }
            } label: {
                Label(String(localized: "ba.activity.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.activityState.isLoading)
        case .pool:
            Button {
                Task { await model.refreshPools(force: true) }
            } label: {
                Label(String(localized: "ba.pool.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.poolState.isLoading)
        case .catalog:
            Button {
                Task { await model.refreshCatalog(force: true) }
            } label: {
                Label(String(localized: "ba.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.catalogState.isLoading)
        case .overview, .library:
            EmptyView()
        }
    }

    private var notificationButton: some View {
        Button {
            presentedSheet = .notifications
        } label: {
            Label(BaPresentedSheet.notifications.title, systemImage: BaPresentedSheet.notifications.systemImage)
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel(Text(BaPresentedSheet.notifications.title))
    }

    private var moreMenu: some View {
        Menu {
            timelineOptionsMenu
            officeActionsMenu
        } label: {
            Label(String(localized: "ba.action.more.title"), systemImage: "ellipsis.circle")
        }
        .labelStyle(.iconOnly)
        .menuOrder(.fixed)
        .accessibilityLabel(Text(String(localized: "ba.action.more.title")))
    }

    @ViewBuilder
    private var timelineOptionsMenu: some View {
        switch tab {
        case .activity:
            BaTimelineOptionsMenu(
                scope: .activity,
                statusFilter: $activityFilter,
                showsEnded: globalBoolBinding(\.showEndedActivities),
                refreshInterval: refreshIntervalBinding
            )
            Divider()
        case .pool:
            BaTimelineOptionsMenu(
                scope: .pool,
                statusFilter: $poolFilter,
                showsEnded: globalBoolBinding(\.showEndedPools),
                refreshInterval: refreshIntervalBinding
            )
            Divider()
        case .overview, .catalog, .library:
            EmptyView()
        }
    }

    @ViewBuilder
    private var officeActionsMenu: some View {
        Section {
            Button {
                presentedSheet = .editOffice
            } label: {
                Label(BaPresentedSheet.editOffice.menuTitle, systemImage: BaPresentedSheet.editOffice.systemImage)
            }

            Button {
                presentedSheet = .debugTools
            } label: {
                Label(BaPresentedSheet.debugTools.menuTitle, systemImage: BaPresentedSheet.debugTools.systemImage)
            }
        }
    }

    private var refreshIntervalBinding: Binding<BaRefreshInterval> {
        Binding(
            get: { model.envelope.globalSettings.refreshInterval },
            set: { interval in
                model.updateGlobalSettings { $0.refreshInterval = interval }
            }
        )
    }

    private func globalBoolBinding(_ keyPath: WritableKeyPath<BaGlobalSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.envelope.globalSettings[keyPath: keyPath] },
            set: { value in
                model.updateGlobalSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

#Preview {
    AppShell()
        .environment(BaAppModel.live())
}
