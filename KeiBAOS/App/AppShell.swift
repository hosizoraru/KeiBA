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
                BaNavigationRoot(tab: tab) { selectedTab = $0 }
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
                    .accessibilityIdentifier(tab.accessibilityIdentifier)
            }
        }
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
        case .overview, .catalog, .library:
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
            pageFilterMenu

            Button {
                presentedSheet = .editOffice
            } label: {
                Label(BaPresentedSheet.editOffice.menuTitle, systemImage: BaPresentedSheet.editOffice.systemImage)
            }

            Divider()

            Button {
                presentedSheet = .debugTools
            } label: {
                Label(BaPresentedSheet.debugTools.menuTitle, systemImage: BaPresentedSheet.debugTools.systemImage)
            }
        } label: {
            Label(String(localized: "ba.action.more.title"), systemImage: "ellipsis.circle")
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel(Text(String(localized: "ba.action.more.title")))
    }

    @ViewBuilder
    private var pageFilterMenu: some View {
        switch tab {
        case .activity:
            Section(String(localized: "ba.activity.action.filter")) {
                timelineFilterButton(title: String(localized: "ba.filter.all"), selected: activityFilter == nil) {
                    activityFilter = nil
                }

                ForEach(BaTimelineStatus.allCases) { status in
                    timelineFilterButton(title: status.title, selected: activityFilter == status) {
                        activityFilter = status
                    }
                }
            }
            Section(String(localized: "ba.settings.preferences.title")) {
                Toggle(
                    String(localized: "ba.settings.activity.showEnded.title"),
                    isOn: globalBoolBinding(\.showEndedActivities)
                )
                refreshIntervalPicker
            }
            Divider()
        case .pool:
            Section(String(localized: "ba.pool.action.filter")) {
                timelineFilterButton(title: String(localized: "ba.filter.all"), selected: poolFilter == nil) {
                    poolFilter = nil
                }

                ForEach(BaTimelineStatus.allCases) { status in
                    timelineFilterButton(title: status.title, selected: poolFilter == status) {
                        poolFilter = status
                    }
                }
            }
            Section(String(localized: "ba.settings.preferences.title")) {
                Toggle(
                    String(localized: "ba.settings.pool.showEnded.title"),
                    isOn: globalBoolBinding(\.showEndedPools)
                )
                refreshIntervalPicker
            }
            Divider()
        case .overview, .catalog, .library:
            EmptyView()
        }
    }

    private var refreshIntervalPicker: some View {
        Picker(String(localized: "ba.settings.refresh.title"), selection: refreshIntervalBinding) {
            ForEach(BaRefreshInterval.allCases) { interval in
                Text(interval.title)
                    .tag(interval)
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

    private func timelineFilterButton(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: selected ? "checkmark" : "circle")
        }
    }
}

#Preview {
    AppShell()
        .environment(BaAppModel.live())
}
