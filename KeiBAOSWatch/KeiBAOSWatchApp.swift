//
//  KeiBAOSWatchApp.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

@main
struct KeiBAOSWatchApp: App {
    @State private var snapshotStore = BaWatchSnapshotStore.shared

    var body: some Scene {
        WindowGroup {
            BaWatchDashboardView(store: snapshotStore)
                .task {
                    snapshotStore.activateConnectivity()
                }
        }
    }
}
