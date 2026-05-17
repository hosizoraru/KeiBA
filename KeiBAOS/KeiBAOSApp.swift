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
        WindowGroup {
            AppShell()
                .environment(baModel)
        }
        #if os(macOS)
            .defaultSize(width: 1_120, height: 760)
        #endif
    }
}
