//
//  BaActionSheetRoot.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

struct BaActionSheetRoot: View {
    let sheet: BaPresentedSheet

    var body: some View {
        switch sheet {
        case .notifications:
            BaNotificationSettingsSheet()
        case .editOffice:
            BaEditOfficeSheet()
        case .debugTools:
            BaDebugToolsSheet()
        }
    }
}

private struct BaNotificationSettingsSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationStatus = BaNotificationAuthorizationStatus.checking

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(
                        authorizationStatus.title,
                        systemImage: authorizationStatus.systemImage
                    )
                    .foregroundStyle(authorizationStatus.foregroundStyle)

                    if authorizationStatus.canRequestAuthorization {
                        Button(String(localized: "ba.sheet.notifications.permission.request")) {
                            Task {
                                await requestAuthorizationAndRefresh(forceRequest: true)
                            }
                        }
                    } else if authorizationStatus.canOpenSystemSettings {
                        Button(String(localized: "ba.sheet.notifications.permission.openSettings")) {
                            openSystemNotificationSettings()
                        }
                    }
                } footer: {
                    Text(String(localized: "ba.sheet.notifications.footer"))
                }

                Section {
                    Toggle(String(localized: "ba.sheet.notifications.ap.title"), isOn: profileBinding(\.apNotificationsEnabled))
                    Toggle(String(localized: "ba.sheet.notifications.cafeAp.title"), isOn: profileBinding(\.cafeApNotificationsEnabled))
                    Toggle(String(localized: "ba.sheet.notifications.visit.title"), isOn: profileBinding(\.visitNotificationsEnabled))
                    Toggle(
                        String(localized: "ba.settings.arena.notifications.title"),
                        isOn: profileBinding(\.arenaRefreshNotificationsEnabled)
                    )
                } header: {
                    Text(String(localized: "ba.settings.resources.section"))
                } footer: {
                    Text(String(localized: "ba.sheet.notifications.resources.footer"))
                }

                Section {
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
                    Text(String(localized: "ba.settings.activityPool.title"))
                } footer: {
                    Text(String(localized: "ba.sheet.notifications.activityPool.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.notifications.title)
            .task {
                await refreshAuthorizationStatus()
                if authorizationStatus.canRequestAuthorization {
                    await requestAuthorizationAndRefresh()
                } else {
                    await model.requestNotificationAuthorizationAndRefreshSchedule()
                    await refreshAuthorizationStatus()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await refreshAuthorizationStatus()
                    await model.requestNotificationAuthorizationAndRefreshSchedule()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
            }
        }
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
                Task {
                    if value {
                        await model.requestNotificationAuthorizationAndRefreshSchedule()
                    }
                    await refreshAuthorizationStatus()
                }
            }
        )
    }

    private func profileBinding(_ keyPath: WritableKeyPath<BaServerProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.currentProfile[keyPath: keyPath] },
            set: { value in
                model.updateCurrentProfile { $0[keyPath: keyPath] = value }
                Task {
                    if value {
                        await model.requestNotificationAuthorizationAndRefreshSchedule()
                    }
                    await refreshAuthorizationStatus()
                }
            }
        )
    }

    private func refreshAuthorizationStatus() async {
        #if canImport(UserNotifications)
        let status = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
        authorizationStatus = BaNotificationAuthorizationStatus(status)
        #else
        authorizationStatus = .allowed
        #endif
    }

    private func requestAuthorizationAndRefresh(forceRequest: Bool = false) async {
        await model.requestNotificationAuthorizationAndRefreshSchedule(forceRequest: forceRequest)
        await refreshAuthorizationStatus()
    }

    private func openSystemNotificationSettings() {
        #if os(iOS) && canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #elseif os(macOS) && canImport(AppKit)
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        #endif
    }
}

private enum BaNotificationAuthorizationStatus: Equatable {
    case checking
    case allowed
    case provisional
    case denied
    case notDetermined
    case unknown

    #if canImport(UserNotifications)
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized:
            self = .allowed
        case .provisional, .ephemeral:
            self = .provisional
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .unknown
        }
    }
    #endif

    var title: String {
        switch self {
        case .checking:
            String(localized: "ba.sheet.notifications.permission.checking")
        case .allowed:
            String(localized: "ba.sheet.notifications.permission.allowed")
        case .provisional:
            String(localized: "ba.sheet.notifications.permission.provisional")
        case .denied:
            String(localized: "ba.sheet.notifications.permission.denied")
        case .notDetermined:
            String(localized: "ba.sheet.notifications.permission.notDetermined")
        case .unknown:
            String(localized: "ba.sheet.notifications.permission.unknown")
        }
    }

    var systemImage: String {
        switch self {
        case .allowed, .provisional:
            "bell.badge.fill"
        case .denied:
            "bell.slash.fill"
        case .checking, .notDetermined, .unknown:
            "bell.badge"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .allowed, .provisional:
            .green
        case .denied:
            .red
        case .checking, .notDetermined, .unknown:
            .secondary
        }
    }

    var canRequestAuthorization: Bool {
        switch self {
        case .checking, .notDetermined:
            true
        case .allowed, .provisional, .denied, .unknown:
            false
        }
    }

    var canOpenSystemSettings: Bool {
        self == .denied
    }
}

private struct BaEditOfficeSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = BaAppSettings.defaults()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(
                        String(localized: "ba.settings.identity.independent.title"),
                        isOn: $draft.identityIndependentByServer
                    )
                    TextField(
                        String(localized: "ba.office.nickname.label"),
                        text: $draft.nickname,
                        prompt: Text(String(localized: "ba.office.nickname.prompt"))
                    )
                    TextField(
                        String(localized: "ba.office.friendCode.label"),
                        text: $draft.friendCode,
                        prompt: Text(String(localized: "ba.office.friendCode.prompt"))
                    )
                    .monospaced()
                    .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.characters)
                    #endif
                    Picker(String(localized: "ba.office.server.label"), selection: $draft.server) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                } header: {
                    Text(String(localized: "ba.sheet.edit.identity.title"))
                } footer: {
                    Text(String(localized: "ba.sheet.edit.identity.footer"))
                }

                Section {
                    LabeledContent(String(localized: "ba.office.ap.limit.title")) {
                        TextField("240", value: $draft.apLimit, format: .number)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                    Stepper(value: $draft.cafeLevel, in: 1 ... 10) {
                        LabeledContent(String(localized: "ba.cafe.level.title")) {
                            Text("Lv\(draft.cafeLevel)")
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text(String(localized: "ba.sheet.edit.resources.title"))
                } footer: {
                    Text(String(localized: "ba.sheet.edit.resources.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.editOffice.title)
            .onAppear {
                draft = model.settings
            }
            .onChange(of: draft.friendCode) { _, value in
                let sanitized = BaFriendCodeFormat.sanitizedDraft(value)
                if sanitized != value {
                    draft.friendCode = sanitized
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done")) {
                        model.updateSettings { settings in
                            settings = draft
                            settings.friendCode = BaFriendCodeFormat.normalized(settings.friendCode)
                            settings.apLimit = min(max(settings.apLimit, 0), BaTimeMath.apLimitMax)
                            settings.cafeLevel = min(max(settings.cafeLevel, 1), 10)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BaDebugToolsSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "ba.sheet.debug.state.title")) {
                    LabeledContent(String(localized: "ba.sheet.debug.build.title")) {
                        Text(AppPlatformBaseline.summary)
                    }
                    ForEach(AppPlatformBaseline.allCases) { baseline in
                        LabeledContent(baseline.displayName) {
                            Text(baseline.minimumVersion)
                        }
                    }
                    LabeledContent(String(localized: "ba.settings.watch.rule.title")) {
                        Text(AppPlatformBaseline.watchRule)
                    }
                    LabeledContent(String(localized: "ba.sheet.debug.data.title")) {
                        Text(debugDataText)
                    }
                }

                Section {
                    Button {
                        Task {
                            await model.refreshActivities(force: true)
                            await model.refreshPools(force: true)
                            await model.refreshCatalog(force: true)
                        }
                    } label: {
                        Label(String(localized: "ba.sheet.debug.refresh.title"), systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glass)
                } footer: {
                    Text(String(localized: "ba.sheet.debug.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.debugTools.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var debugDataText: String {
        let activityCount = model.activityState.value?.count ?? 0
        let poolCount = model.poolState.value?.count ?? 0
        let catalogCount = model.catalogState.value?.entries.count ?? 0
        return String(
            format: String(localized: "ba.sheet.debug.data.format"),
            activityCount,
            poolCount,
            catalogCount
        )
    }
}

extension View {
    @ViewBuilder
    func baActionSheetPresentation() -> some View {
        #if os(iOS)
            presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        #else
            frame(minWidth: 420, minHeight: 360)
        #endif
    }
}
