//
//  KeiBAApp.swift
//  KeiBA
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct KeiBAApp: App {
    @State private var baModel: BaAppModel
    #if os(iOS)
    @UIApplicationDelegateAdaptor(BaIOSAppDelegate.self) private var appDelegate
    #endif

    init() {
        _baModel = State(initialValue: BaLaunchEnvironment.isRunningUnitTests ? .testHost() : .live())
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            AppShell()
                .environment(baModel)
        }
            .defaultSize(width: 1_120, height: 760)
            .commands {
                BaGoCommands()
                BaViewCommands()
            }

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
            if BaLaunchEnvironment.isRunningUnitTests {
                BaXCTestHostView()
                    .environment(baModel)
            } else {
                AppShell()
                    .environment(baModel)
            }
        }
        #endif
    }
}

#if os(iOS)
private struct BaXCTestHostView: View {
    var body: some View {
        Text(verbatim: "KeiBA Tests")
            .accessibilityIdentifier("ba.xctest.host")
    }
}
#endif

#if os(macOS)
private struct BaGoCommands: Commands {
    @FocusedValue(\.baFocusedTab) private var focusedTab

    var body: some Commands {
        CommandMenu("Go") {
            ForEach(AppTab.allCases) { tab in
                Button(tab.title) {
                    // Tab switching is handled by keyboard shortcuts on sidebar items
                }
                .keyboardShortcut(tab.goKeyboardShortcut, modifiers: .command)
                .disabled(focusedTab == tab)
            }
        }
    }
}

private struct BaViewCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Toggle Sidebar") {
                NSApp.keyWindow?.contentViewController?.tryToPerform(
                    #selector(NSSplitViewController.toggleSidebar(_:)),
                    with: nil
                )
            }
            .keyboardShortcut("s", modifiers: [.control, .command])
        }
    }
}
#endif

#if os(iOS)
final class BaIOSAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}
#endif
