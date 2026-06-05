//
//  KeiBAWatchApp.swift
//  KeiBAWatch
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

@main
struct KeiBAWatchApp: App {
    @State private var snapshotStore = BaWatchSnapshotStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BaWatchDashboardView(store: snapshotStore)
                .task {
                    snapshotStore.activateConnectivity()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    snapshotStore.activateConnectivity()
                }
        }
    }
}
