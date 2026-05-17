//
//  KeiBAOSApp.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

@main
struct KeiBAOSApp: App {
    @State private var baModel: BaAppModel

    init() {
        _baModel = State(initialValue: BaAppModel.live())
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            AppShell()
                .environment(baModel)
        }
            .defaultSize(width: 1_120, height: 760)

        Settings {
            NavigationStack {
                BaSettingsView()
                    .navigationTitle(BaL10n.string("ba.settings.title"))
            }
            .environment(baModel)
            .environment(\.locale, baModel.envelope.globalSettings.appLanguage.locale)
            .preferredColorScheme(baModel.envelope.globalSettings.appAppearance.preferredColorScheme)
            .frame(minWidth: 640, minHeight: 680)
        }
        #else
        WindowGroup {
            AppShell()
                .environment(baModel)
        }
        #endif
    }
}
