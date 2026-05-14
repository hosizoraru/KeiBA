//
//  KeiBAOSApp.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

@main
struct KeiBAOSApp: App {
    @State private var baModel = BaAppModel.live()

    var body: some Scene {
        WindowGroup {
            AppShell()
                .environment(baModel)
        }
    }
}
