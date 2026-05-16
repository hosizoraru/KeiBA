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
        BaAdaptiveGeometry { _ in
            Form {
                serverIdentitySection
                resourcesSection
                activityPoolSection
                notificationSection
                mediaSection
                platformSection
            }
            .baAdaptiveReadableContent(maxWidth: 760)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
        }
    }

    private var serverIdentitySection: some View {
        Section {
            Picker(String(localized: "ba.settings.server.title"), selection: serverBinding) {
                ForEach(BaServer.allCases) { server in
                    Text(server.title)
                        .tag(server)
                }
            }

            Toggle(
                String(localized: "ba.settings.identity.independent.title"),
                isOn: globalBoolBinding(\.identityIndependentByServer)
            )

            TextField(String(localized: "ba.office.nickname.label"), text: profileStringBinding(\.nickname))
            TextField(String(localized: "ba.office.friendCode.label"), text: profileStringBinding(\.friendCode))
            #if os(iOS)
                .textInputAutocapitalization(.characters)
            #endif
        } header: {
            Text(String(localized: "ba.settings.identity.section"))
        } footer: {
            Text(String(localized: "ba.settings.identity.footer"))
        }
    }

    private var resourcesSection: some View {
        Section(String(localized: "ba.settings.resources.section")) {
            LabeledContent(String(localized: "ba.office.ap.limit.title")) {
                TextField(
                    "240",
                    value: profileIntBinding(\.apLimit, range: 0 ... BaTimeMath.apLimitMax),
                    format: .number
                )
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
            }

            Stepper(value: profileIntBinding(\.cafeLevel, range: 1 ... 10), in: 1 ... 10) {
                LabeledContent(String(localized: "ba.cafe.level.title")) {
                    Text("Lv\(model.currentProfile.cafeLevel)")
                }
            }

            LabeledContent(String(localized: "ba.settings.ap.threshold.title")) {
                TextField(
                    "120",
                    value: profileIntBinding(\.apNotifyThreshold, range: 0 ... BaTimeMath.apMax),
                    format: .number
                )
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
            }

            LabeledContent(String(localized: "ba.settings.cafe.threshold.title")) {
                TextField(
                    "120",
                    value: profileIntBinding(\.cafeApNotifyThreshold, range: 0 ... BaTimeMath.apMax),
                    format: .number
                )
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
            }
        }
    }

    private var activityPoolSection: some View {
        Section {
            Toggle(
                String(localized: "ba.settings.activity.showEnded.title"),
                isOn: globalBoolBinding(\.showEndedActivities)
            )
            Toggle(
                String(localized: "ba.settings.pool.showEnded.title"),
                isOn: globalBoolBinding(\.showEndedPools)
            )

            Picker(String(localized: "ba.settings.refresh.title"), selection: refreshIntervalBinding) {
                ForEach(BaRefreshInterval.allCases) { interval in
                    Text(interval.title)
                        .tag(interval)
                }
            }
        } header: {
            Text(String(localized: "ba.settings.activityPool.title"))
        } footer: {
            Text(String(localized: "ba.settings.activityPool.footer"))
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle(
                String(localized: "ba.sheet.notifications.ap.title"),
                isOn: profileBoolBinding(\.apNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.sheet.notifications.cafeAp.title"),
                isOn: profileBoolBinding(\.cafeApNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.sheet.notifications.visit.title"),
                isOn: profileBoolBinding(\.visitNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.settings.arena.notifications.title"),
                isOn: profileBoolBinding(\.arenaRefreshNotificationsEnabled)
            )

            Toggle(
                String(localized: "ba.settings.activity.start.notifications.title"),
                isOn: globalBoolBinding(\.calendarUpcomingNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.settings.activity.end.notifications.title"),
                isOn: globalBoolBinding(\.calendarEndingNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.settings.pool.start.notifications.title"),
                isOn: globalBoolBinding(\.poolUpcomingNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.settings.pool.end.notifications.title"),
                isOn: globalBoolBinding(\.poolEndingNotificationsEnabled)
            )
            Toggle(
                String(localized: "ba.settings.calendarPool.change.notifications.title"),
                isOn: globalBoolBinding(\.calendarPoolChangeNotificationsEnabled)
            )

            Picker(String(localized: "ba.settings.notifyLead.title"), selection: notifyLeadBinding) {
                ForEach(BaCalendarPoolNotifyLead.allCases) { lead in
                    Text(lead.title)
                        .tag(lead)
                }
            }
        } header: {
            Text(String(localized: "ba.settings.notifications.title"))
        } footer: {
            Text(String(localized: "ba.sheet.notifications.footer"))
        }
    }

    private var mediaSection: some View {
        Section {
            Toggle(String(localized: "ba.settings.media.images.title"), isOn: globalBoolBinding(\.showPreviewImages))
            Toggle(
                String(localized: "ba.settings.media.autoplay.title"),
                isOn: globalBoolBinding(\.mediaAutoplayEnabled)
            )
            Toggle(
                String(localized: "ba.settings.media.download.title"),
                isOn: globalBoolBinding(\.mediaDownloadEnabled)
            )
        } header: {
            Text(String(localized: "ba.settings.media.title"))
        } footer: {
            Text(String(localized: "ba.settings.media.footer"))
        }
    }

    private var platformSection: some View {
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

    private var serverBinding: Binding<BaServer> {
        Binding(
            get: { model.settings.server },
            set: { server in
                model.selectServer(server)
                Task {
                    await model.loadActivitiesIfNeeded()
                    await model.loadPoolsIfNeeded()
                }
            }
        )
    }

    private var refreshIntervalBinding: Binding<BaRefreshInterval> {
        Binding(
            get: { model.envelope.globalSettings.refreshInterval },
            set: { interval in
                model.updateGlobalSettings { $0.refreshInterval = interval }
            }
        )
    }

    private var notifyLeadBinding: Binding<BaCalendarPoolNotifyLead> {
        Binding(
            get: { model.envelope.globalSettings.calendarPoolNotifyLead },
            set: { lead in
                model.updateGlobalSettings { $0.calendarPoolNotifyLead = lead }
            }
        )
    }

    private func globalBoolBinding(_ keyPath: WritableKeyPath<BaGlobalSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.envelope.globalSettings[keyPath: keyPath] },
            set: { value in
                model.updateGlobalSettings { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func profileBoolBinding(_ keyPath: WritableKeyPath<BaServerProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.currentProfile[keyPath: keyPath] },
            set: { value in
                model.updateCurrentProfile { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func profileStringBinding(_ keyPath: WritableKeyPath<BaServerProfile, String>) -> Binding<String> {
        Binding(
            get: { model.currentProfile[keyPath: keyPath] },
            set: { value in
                model.updateCurrentProfile { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func profileIntBinding(
        _ keyPath: WritableKeyPath<BaServerProfile, Int>,
        range: ClosedRange<Int>
    ) -> Binding<Int> {
        Binding(
            get: { model.currentProfile[keyPath: keyPath] },
            set: { value in
                model.updateCurrentProfile {
                    $0[keyPath: keyPath] = min(max(value, range.lowerBound), range.upperBound)
                }
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
