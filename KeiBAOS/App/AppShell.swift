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
                BaNavigationRoot(tab: tab)
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
    let tab: AppTab
    @State private var presentedSheet: BaPresentedSheet?

    var body: some View {
        NavigationStack {
            tab.rootView
                .navigationTitle(tab.navigationTitle)
                .platformLargeNavigationTitle()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        BaTopActionBar { sheet in
                            presentedSheet = sheet
                        }
                    }
                }
                .sheet(item: $presentedSheet) { sheet in
                    BaActionSheetRoot(sheet: sheet)
                        .baActionSheetPresentation()
                }
        }
    }
}

#Preview {
    AppShell()
}
