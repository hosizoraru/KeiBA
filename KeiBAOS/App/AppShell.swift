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
    @State private var presentedAction: BaQuickAction?

    var body: some View {
        NavigationStack {
            tab.rootView
                .navigationTitle(tab.navigationTitle)
                .platformInlineNavigationTitle()
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        BaTopActionBar { action in
                            presentedAction = action
                        }
                    }
                }
                .alert(item: $presentedAction) { action in
                    Alert(
                        title: Text(action.title),
                        message: Text(action.message),
                        dismissButton: .default(Text(String(localized: "ba.action.dismiss")))
                    )
                }
        }
    }
}

#Preview {
    AppShell()
}
