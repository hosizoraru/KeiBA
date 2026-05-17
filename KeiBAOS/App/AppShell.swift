//
//  AppShell.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct AppShell: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @SceneStorage("AppShell.selectedTab") private var selectedTabRawValue = AppTab.overview.rawValue
    @State private var musicPlaybackSession: BaMusicPlaybackSession?

    var body: some View {
        shellContent
            .environment(\.locale, model.envelope.globalSettings.appLanguage.locale)
            .environment(\.baShowPreviewImages, model.settings.showPreviewImages)
            .preferredColorScheme(model.envelope.globalSettings.appAppearance.preferredColorScheme)
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
            .task {
                await model.applyPreferredAppIcon()
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    model.scheduleNotificationRefresh(delay: BaPlatformPerformanceProfile.notificationStartupRefreshDelay)
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
                .navigationTitle(tab.titleResource)
                .platformLargeNavigationTitle()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        pageRefreshButton
                        moreMenu
                    }
                }
                .sheet(item: $presentedSheet) { sheet in
                    BaActionSheetRoot(sheet: sheet)
                        .baActionSheetPresentation(for: sheet)
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch tab {
        case .overview:
            BaOverviewView(onOpenTab: onSelectTab)
        case .activity:
            BaActivityView(statusFilter: $activityFilter)
        case .pool:
            BaPoolView(statusFilter: $poolFilter)
        case .catalog:
            BaCatalogView()
        case .library:
            if let musicPlaybackSession {
                BaLibraryView(playbackSession: musicPlaybackSession)
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
                Label(BaL10n.string("ba.activity.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.activityState.isLoading)
        case .pool:
            Button {
                Task { await model.refreshPools(force: true) }
            } label: {
                Label(BaL10n.string("ba.pool.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.poolState.isLoading)
        case .catalog:
            Button {
                Task { await model.refreshCatalog(force: true) }
            } label: {
                Label(BaL10n.string("ba.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.catalogState.isLoading)
        case .library:
            Button {
                Task { await model.refreshCatalog(force: true) }
            } label: {
                Label(BaL10n.string("ba.action.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.iconOnly)
            .disabled(model.catalogState.isLoading)
        case .overview:
            EmptyView()
        }
    }

    private var moreMenu: some View {
        Menu {
            appSettingsMenuItem
            pageSettingsMenu
        } label: {
            Label(BaL10n.string("ba.action.more.title"), systemImage: "ellipsis.circle")
        }
        .labelStyle(.iconOnly)
        .menuOrder(.fixed)
        .accessibilityLabel(Text(BaL10n.string("ba.action.more.title")))
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
        case .pool:
            BaTimelineOptionsMenu(
                scope: .pool,
                statusFilter: $poolFilter,
                showsEnded: globalBoolBinding(\.showEndedPools),
                refreshInterval: refreshIntervalBinding
            )
        case .overview, .catalog, .library:
            EmptyView()
        }
    }

    @ViewBuilder
    private var appSettingsMenuItem: some View {
        Section {
            Button {
                presentedSheet = .settings
            } label: {
                Label(BaPresentedSheet.settings.title, systemImage: BaPresentedSheet.settings.systemImage)
            }
        }
    }

    @ViewBuilder
    private var pageSettingsMenu: some View {
        switch tab {
        case .overview:
            Section {
                Button {
                    presentedSheet = .editOffice
                } label: {
                    Label(BaPresentedSheet.editOffice.menuTitle, systemImage: BaPresentedSheet.editOffice.systemImage)
                }

                Button {
                    presentedSheet = .notifications
                } label: {
                    Label(BaPresentedSheet.notifications.title, systemImage: BaPresentedSheet.notifications.systemImage)
                }

                Button {
                    presentedSheet = .debugTools
                } label: {
                    Label(BaPresentedSheet.debugTools.menuTitle, systemImage: BaPresentedSheet.debugTools.systemImage)
                }
            }
        case .activity:
            timelineOptionsMenu
            Section {
                Button {
                    presentedSheet = .notifications
                } label: {
                    Label(BaPresentedSheet.notifications.title, systemImage: BaPresentedSheet.notifications.systemImage)
                }
            }
        case .pool:
            timelineOptionsMenu
            Section {
                Button {
                    presentedSheet = .notifications
                } label: {
                    Label(BaPresentedSheet.notifications.title, systemImage: BaPresentedSheet.notifications.systemImage)
                }
            }
        case .catalog:
            Section(BaL10n.string("ba.settings.media.title")) {
                Toggle(
                    BaL10n.string("ba.settings.media.images.title"),
                    isOn: globalBoolBinding(\.showPreviewImages)
                )
            }
        case .library:
            Section(BaL10n.string("ba.settings.media.title")) {
                Toggle(
                    BaL10n.string("ba.settings.media.autoplay.title"),
                    isOn: globalBoolBinding(\.mediaAutoplayEnabled)
                )

                Toggle(
                    BaL10n.string("ba.settings.media.download.title"),
                    isOn: globalBoolBinding(\.mediaDownloadEnabled)
                )
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
