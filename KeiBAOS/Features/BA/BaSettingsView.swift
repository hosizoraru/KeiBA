//
//  BaSettingsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaSettingsView: View {
    @State private var showEndedActivities = true
    @State private var showEndedPools = true
    @State private var showImages = true
    @State private var activityNotifications = true
    @State private var poolNotifications = false
    @State private var refreshInterval = BaRefreshInterval.fifteenMinutes

    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "ba.settings.server.title")) {
                    Text(String(localized: "ba.office.server.value"))
                }

                Picker(String(localized: "ba.settings.refresh.title"), selection: $refreshInterval) {
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
                Toggle(String(localized: "ba.settings.activity.showEnded.title"), isOn: $showEndedActivities)
                Toggle(String(localized: "ba.settings.pool.showEnded.title"), isOn: $showEndedPools)
                Toggle(String(localized: "ba.settings.activity.notifications.title"), isOn: $activityNotifications)
                Toggle(String(localized: "ba.settings.pool.notifications.title"), isOn: $poolNotifications)
            }

            Section {
                Toggle(String(localized: "ba.settings.media.images.title"), isOn: $showImages)
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
}

private enum BaRefreshInterval: String, CaseIterable, Identifiable {
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes

    var id: Self { self }

    var title: String {
        switch self {
        case .fiveMinutes:
            String(localized: "ba.settings.refresh.interval.5m")
        case .fifteenMinutes:
            String(localized: "ba.settings.refresh.interval.15m")
        case .thirtyMinutes:
            String(localized: "ba.settings.refresh.interval.30m")
        }
    }
}

#Preview {
    NavigationStack {
        BaSettingsView()
    }
}
