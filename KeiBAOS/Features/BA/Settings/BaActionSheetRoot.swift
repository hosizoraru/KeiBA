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
    @State private var testStatus: String?

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Text(BaPresentedSheet.notifications.title)
                    .font(.title3.weight(.semibold))

                Spacer()

                Button(String(localized: "ba.common.done")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            macNotificationSettingsContent
        }
        .frame(minWidth: 680, minHeight: 660)
        .task {
            await prepareNotificationSettings()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await refreshAuthorizationStatus()
                await model.requestNotificationAuthorizationAndRefreshSchedule()
            }
        }
        #else
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
                    notificationFooterText("ba.sheet.notifications.footer")
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
                    notificationFooterText("ba.sheet.notifications.resources.footer")
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
                    notificationFooterText("ba.sheet.notifications.activityPool.footer")
                }

                testActionsSection
            }
            .navigationTitle(BaPresentedSheet.notifications.title)
            .task {
                await prepareNotificationSettings()
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
        #endif
    }

    #if os(macOS)
    private var macNotificationSettingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                macSettingsGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            authorizationStatus.title,
                            systemImage: authorizationStatus.systemImage
                        )
                        .foregroundStyle(authorizationStatus.foregroundStyle)
                        .font(.headline)

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

                        notificationFooterText("ba.sheet.notifications.footer")
                    }
                }

                macSettingsGroup(String(localized: "ba.settings.resources.section")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(String(localized: "ba.sheet.notifications.ap.title"), isOn: profileBinding(\.apNotificationsEnabled))
                        Toggle(String(localized: "ba.sheet.notifications.cafeAp.title"), isOn: profileBinding(\.cafeApNotificationsEnabled))
                        Toggle(String(localized: "ba.sheet.notifications.visit.title"), isOn: profileBinding(\.visitNotificationsEnabled))
                        Toggle(
                            String(localized: "ba.settings.arena.notifications.title"),
                            isOn: profileBinding(\.arenaRefreshNotificationsEnabled)
                        )
                        notificationFooterText("ba.sheet.notifications.resources.footer")
                    }
                }

                macSettingsGroup(String(localized: "ba.settings.activityPool.title")) {
                    VStack(alignment: .leading, spacing: 10) {
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

                        HStack {
                            Text(String(localized: "ba.settings.notifyLead.title"))
                            Spacer()
                            Picker(String(localized: "ba.settings.notifyLead.title"), selection: notifyLeadBinding) {
                                ForEach(BaCalendarPoolNotifyLead.allCases) { lead in
                                    Text(lead.title)
                                        .tag(lead)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }

                        notificationFooterText("ba.sheet.notifications.activityPool.footer")
                    }
                }

                macSettingsGroup(String(localized: "ba.sheet.notifications.test.title")) {
                    VStack(alignment: .leading, spacing: 10) {
                        testActionButtons
                        testStatusText
                        notificationFooterText("ba.sheet.notifications.test.footer")
                    }
                }
            }
            .padding(24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macSettingsGroup<Content: View>(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    #endif

    private var testActionsSection: some View {
        Section {
            testActionButtons
            testStatusText
        } header: {
            Text(String(localized: "ba.sheet.notifications.test.title"))
        } footer: {
            notificationFooterText("ba.sheet.notifications.test.footer")
        }
    }

    @ViewBuilder
    private var testActionButtons: some View {
        Button {
            Task {
                await sendTestNotification()
            }
        } label: {
            Label(String(localized: "ba.sheet.notifications.test.local"), systemImage: "bell.badge")
        }

        #if os(iOS)
        Button {
            Task {
                await startTestLiveActivity()
            }
        } label: {
            Label(String(localized: "ba.sheet.notifications.test.live"), systemImage: "timer")
        }

        Button(role: .destructive) {
            Task {
                await endTestLiveActivities()
            }
        } label: {
            Label(String(localized: "ba.sheet.notifications.test.live.end"), systemImage: "xmark.circle")
        }
        #else
        Text(String(localized: "ba.sheet.notifications.test.live.unavailable"))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        #endif
    }

    @ViewBuilder
    private var testStatusText: some View {
        if let testStatus {
            Text(testStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func notificationFooterText(_ key: LocalizedStringResource) -> some View {
        Text(String(localized: key))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
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

    private func prepareNotificationSettings() async {
        await refreshAuthorizationStatus()
        if authorizationStatus.canRequestAuthorization {
            await requestAuthorizationAndRefresh()
        } else {
            await model.requestNotificationAuthorizationAndRefreshSchedule()
            await refreshAuthorizationStatus()
        }
    }

    private func sendTestNotification() async {
        await model.sendTestNotification()
        await refreshAuthorizationStatus()
        testStatus = authorizationStatus.allowsDelivery
            ? String(localized: "ba.sheet.notifications.test.local.sent")
            : String(localized: "ba.sheet.notifications.test.permissionNeeded")
    }

    private func startTestLiveActivity() async {
        let started = await model.startTestLiveActivity()
        testStatus = started
            ? String(localized: "ba.sheet.notifications.test.live.started")
            : String(localized: "ba.sheet.notifications.test.live.permissionNeeded")
    }

    private func endTestLiveActivities() async {
        await model.endTestLiveActivities()
        testStatus = String(localized: "ba.sheet.notifications.test.live.ended")
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

    var allowsDelivery: Bool {
        switch self {
        case .allowed, .provisional:
            true
        case .checking, .denied, .notDetermined, .unknown:
            false
        }
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
    func baActionSheetPresentation(for sheet: BaPresentedSheet) -> some View {
        #if os(iOS)
            presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        #else
            frame(
                minWidth: sheet.macMinimumSheetWidth,
                minHeight: sheet.macMinimumSheetHeight
            )
        #endif
    }
}

#if os(macOS)
private extension BaPresentedSheet {
    var macMinimumSheetWidth: CGFloat {
        switch self {
        case .notifications:
            680
        case .editOffice, .debugTools:
            520
        }
    }

    var macMinimumSheetHeight: CGFloat {
        switch self {
        case .notifications:
            660
        case .editOffice, .debugTools:
            360
        }
    }
}
#endif
