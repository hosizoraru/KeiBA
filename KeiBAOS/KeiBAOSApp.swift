//
//  KeiBAOSApp.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

@main
struct KeiBAOSApp: App {
    @State private var baModel: BaAppModel?

    var body: some Scene {
        WindowGroup {
            if let baModel {
                AppShell()
                    .environment(baModel)
            } else {
                BaAppLoadingView()
                    .task {
                        await prepareAppModel()
                    }
            }
        }
    }

    @MainActor
    private func prepareAppModel() async {
        guard baModel == nil else { return }
        await Task.yield()
        baModel = BaAppModel.live()
    }
}

private struct BaAppLoadingView: View {
    var body: some View {
        ZStack {
            AppBackground()

            ProgressView()
                .controlSize(.regular)
        }
    }
}
