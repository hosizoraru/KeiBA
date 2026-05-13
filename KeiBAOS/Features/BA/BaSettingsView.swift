//
//  BaSettingsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaSettingsView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "ba.settings.server.title")) {
                    Text(String(localized: "ba.office.server.value"))
                }

                LabeledContent(String(localized: "ba.settings.notifications.title")) {
                    Text(String(localized: "ba.settings.notifications.value"))
                }

                LabeledContent(String(localized: "ba.settings.refresh.title")) {
                    Text(String(localized: "ba.settings.refresh.value"))
                }
            } header: {
                Text(String(localized: "ba.settings.preferences.title"))
            } footer: {
                Text(String(localized: "ba.settings.detail"))
            }

            Section(String(localized: "ba.settings.platform.title")) {
                ForEach(AppPlatformBaseline.allCases) { baseline in
                    LabeledContent(baseline.displayName) {
                        Text(baseline.minimumVersion)
                    }
                }

                LabeledContent(String(localized: "ba.settings.watch.rule.title")) {
                    Text(AppPlatformBaseline.watchRule)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }
}

#Preview {
    NavigationStack {
        BaSettingsView()
    }
}
