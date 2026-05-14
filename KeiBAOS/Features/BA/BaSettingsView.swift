//
//  BaSettingsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaSettingsView: View {
    @Environment(BaAppModel.self) private var model

    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "ba.settings.server.title")) {
                    Picker(String(localized: "ba.settings.server.title"), selection: serverBinding) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                    .labelsHidden()
                }

                Picker(String(localized: "ba.settings.refresh.title"), selection: refreshIntervalBinding) {
                    ForEach(BaRefreshInterval.allCases) { interval in
                        Text(interval.title)
                            .tag(interval)
                    }
                }
            } header: {
                Text(String(localized: "ba.settings.preferences.title"))
            } footer: {
                Text(String(localized: "ba.settings.detail"))
            }

            Section(String(localized: "ba.settings.activityPool.title")) {
                Toggle(String(localized: "ba.settings.activity.showEnded.title"), isOn: boolBinding(\.showEndedActivities))
                Toggle(String(localized: "ba.settings.pool.showEnded.title"), isOn: boolBinding(\.showEndedPools))
                Toggle(String(localized: "ba.settings.activity.notifications.title"), isOn: boolBinding(\.activityNotificationsEnabled))
                Toggle(String(localized: "ba.settings.pool.notifications.title"), isOn: boolBinding(\.poolNotificationsEnabled))
            }

            Section {
                Toggle(String(localized: "ba.settings.media.images.title"), isOn: boolBinding(\.showPreviewImages))
                Toggle(String(localized: "ba.settings.media.autoplay.title"), isOn: boolBinding(\.mediaAutoplayEnabled))
                Toggle(String(localized: "ba.settings.media.download.title"), isOn: boolBinding(\.mediaDownloadEnabled))
            } header: {
                Text(String(localized: "ba.settings.media.title"))
            } footer: {
                Text(String(localized: "ba.settings.media.footer"))
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

    private var serverBinding: Binding<BaServer> {
        Binding(
            get: { model.settings.server },
            set: { server in
                model.updateSettings { $0.server = server }
                Task {
                    await model.refreshActivities(force: true)
                    await model.refreshPools(force: true)
                }
            }
        )
    }

    private var refreshIntervalBinding: Binding<BaRefreshInterval> {
        Binding(
            get: { model.settings.refreshInterval },
            set: { interval in
                model.updateSettings { $0.refreshInterval = interval }
            }
        )
    }

    private func boolBinding(_ keyPath: WritableKeyPath<BaAppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { value in
                model.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

#Preview {
    NavigationStack {
        BaSettingsView()
    }
    .environment(BaAppModel.live())
}
