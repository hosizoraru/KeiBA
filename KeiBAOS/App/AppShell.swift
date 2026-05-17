//
//  AppShell.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct AppShell: View {
    @SceneStorage("AppShell.selectedTab") private var selectedTabRawValue = AppTab.overview.rawValue
    @State private var musicPlaybackSession: BaMusicPlaybackSession?

    var body: some View {
        shellContent
            .sheet(isPresented: musicNowPlayingExpandedBinding) {
                if let musicPlaybackSession {
                    BaMusicNowPlayingSheet(session: musicPlaybackSession)
                }
            }
            .onChange(of: selectedTab, initial: true) { _, tab in
                if tab == .library {
                    prepareMusicPlaybackSession()
                }
            }
    }

    @ViewBuilder
    private var shellContent: some View {
        #if os(macOS)
            macShell
        #else
            touchShell
                .baMusicMiniPlayerAccessory(session: musicPlaybackSession, selectedTab: selectedTab)
        #endif
    }

    private var touchShell: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.titleResource, systemImage: tab.systemImage, value: tab) {
                    BaNavigationRoot(
                        tab: tab,
                        musicPlaybackSession: musicPlaybackSession,
                        onPrepareMusicPlaybackSession: prepareMusicPlaybackSession
                    ) { selectedTab = $0 }
                    .accessibilityIdentifier(tab.accessibilityIdentifier)
                }
            }
        }
        .platformAdaptiveTabViewStyle()
    }

    #if os(macOS)
        private var macShell: some View {
            NavigationSplitView {
                List(selection: selectedTabBinding) {
                    ForEach(AppTab.allCases) { tab in
                        Label {
                            Text(tab.titleResource)
                        } icon: {
                            Image(systemName: tab.systemImage)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                        }
                        .tag(tab)
                        .accessibilityIdentifier(tab.accessibilityIdentifier)
                    }
                }
                .navigationTitle("KeiBAOS")
                .listStyle(.sidebar)
                .frame(minWidth: 180)
            } detail: {
                BaNavigationRoot(
                    tab: selectedTab,
                    musicPlaybackSession: musicPlaybackSession,
                    onPrepareMusicPlaybackSession: prepareMusicPlaybackSession
                ) { selectedTab = $0 }
                .accessibilityIdentifier(selectedTab.accessibilityIdentifier)
                .baMusicMiniPlayerAccessory(session: musicPlaybackSession, selectedTab: selectedTab)
            }
            .navigationSplitViewStyle(.balanced)
        }
    #endif

    private var musicNowPlayingExpandedBinding: Binding<Bool> {
        Binding(
            get: { musicPlaybackSession?.isExpanded ?? false },
            set: { musicPlaybackSession?.isExpanded = $0 }
        )
    }

    @discardableResult
    private func prepareMusicPlaybackSession() -> BaMusicPlaybackSession {
        if let musicPlaybackSession {
            return musicPlaybackSession
        }
        let session = BaMusicPlaybackSession()
        musicPlaybackSession = session
        return session
    }

    private var selectedTab: AppTab {
        get {
            AppTab(rawValue: selectedTabRawValue) ?? .overview
        }
        nonmutating set {
            selectedTabRawValue = newValue.rawValue
        }
    }

    private var selectedTabBinding: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { selectedTab = $0 }
        )
    }
}

private struct BaNavigationRoot: View {
    @Environment(BaAppModel.self) private var model

    let tab: AppTab
    let musicPlaybackSession: BaMusicPlaybackSession?
    let onPrepareMusicPlaybackSession: () -> BaMusicPlaybackSession
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
            if let musicPlaybackSession {
                BaLibraryView(playbackSession: musicPlaybackSession)
                    .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        _ = onPrepareMusicPlaybackSession()
                    }
            }
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
        case .library:
            Button {
                Task { await model.refreshCatalog(force: true) }
            } label: {
                Label(String(localized: "ba.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.catalogState.isLoading)
        case .overview:
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

private extension View {
    @ViewBuilder
    func baMusicMiniPlayerAccessory(session: BaMusicPlaybackSession?, selectedTab: AppTab) -> some View {
        #if os(iOS)
            if let session, session.hasCurrentTrack {
                tabViewBottomAccessory {
                    BaMusicMiniNowPlayingBar(
                        session: session,
                        prefersExpanded: selectedTab == .library
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
                .tabBarMinimizeBehavior(.onScrollDown)
            } else {
                tabBarMinimizeBehavior(.onScrollDown)
            }
        #elseif os(macOS)
            if let session, session.hasCurrentTrack, selectedTab != .library {
                safeAreaInset(edge: .bottom, spacing: 0) {
                    HStack {
                        BaMusicMiniNowPlayingBar(session: session, prefersExpanded: false)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: 460)
                            .liquidGlassSurface(
                                cornerRadius: 24,
                                tint: Color.white.opacity(0.035),
                                isInteractive: false
                            )

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
            } else {
                self
            }
        #else
            self
        #endif
    }
}

#Preview {
    AppShell()
        .environment(BaAppModel.live())
}
