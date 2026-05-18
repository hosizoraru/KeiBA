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
        case .settings:
            BaSettingsSheet()
        case .about:
            BaAboutSheet()
        case .editOffice:
            BaEditOfficeSheet()
        case .debugTools:
            BaDebugToolsSheet()
        }
    }
}

private struct BaAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BaAboutView()
                .navigationTitle(BaPresentedSheet.about.title)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(BaL10n.string("ba.common.done")) {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct BaSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BaSettingsView()
                .navigationTitle(BaL10n.string("ba.settings.title"))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(BaL10n.string("ba.common.done")) {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct BaNotificationSettingsSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
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

                Button(BaL10n.string("ba.common.done")) {
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
                        Button(BaL10n.string("ba.sheet.notifications.permission.request")) {
                            Task {
                                await requestAuthorizationAndRefresh(forceRequest: true)
                            }
                        }
                    } else if authorizationStatus.canOpenSystemSettings {
                        Button(BaL10n.string("ba.sheet.notifications.permission.openSettings")) {
                            openSystemNotificationSettings()
                        }
                    }
                } footer: {
                    notificationFooterText("ba.sheet.notifications.footer")
                }

                Section {
                    Toggle(BaL10n.string("ba.sheet.notifications.ap.title"), isOn: profileBinding(\.apNotificationsEnabled))
                    Toggle(BaL10n.string("ba.sheet.notifications.cafeAp.title"), isOn: profileBinding(\.cafeApNotificationsEnabled))
                    Toggle(BaL10n.string("ba.sheet.notifications.visit.title"), isOn: profileBinding(\.visitNotificationsEnabled))
                    Toggle(
                        BaL10n.string("ba.settings.arena.notifications.title"),
                        isOn: profileBinding(\.arenaRefreshNotificationsEnabled)
                    )
                } header: {
                    Text(BaL10n.string("ba.settings.resources.section"))
                } footer: {
                    notificationFooterText("ba.sheet.notifications.resources.footer")
                }

                Section {
                    Toggle(
                        BaL10n.string("ba.settings.activity.start.notifications.title"),
                        isOn: globalBoolBinding(\.calendarUpcomingNotificationsEnabled)
                    )
                    Toggle(
                        BaL10n.string("ba.settings.activity.end.notifications.title"),
                        isOn: globalBoolBinding(\.calendarEndingNotificationsEnabled)
                    )
                    Toggle(
                        BaL10n.string("ba.settings.pool.start.notifications.title"),
                        isOn: globalBoolBinding(\.poolUpcomingNotificationsEnabled)
                    )
                    Toggle(
                        BaL10n.string("ba.settings.pool.end.notifications.title"),
                        isOn: globalBoolBinding(\.poolEndingNotificationsEnabled)
                    )
                    Toggle(
                        BaL10n.string("ba.settings.calendarPool.change.notifications.title"),
                        isOn: globalBoolBinding(\.calendarPoolChangeNotificationsEnabled)
                    )
                    Picker(BaL10n.string("ba.settings.notifyLead.title"), selection: notifyLeadBinding) {
                        ForEach(BaCalendarPoolNotifyLead.allCases) { lead in
                            Text(lead.title)
                                .tag(lead)
                        }
                    }
                } header: {
                    Text(BaL10n.string("ba.settings.activityPool.title"))
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
                    Button(BaL10n.string("ba.common.done")) {
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
                            Button(BaL10n.string("ba.sheet.notifications.permission.request")) {
                                Task {
                                    await requestAuthorizationAndRefresh(forceRequest: true)
                                }
                            }
                        } else if authorizationStatus.canOpenSystemSettings {
                            Button(BaL10n.string("ba.sheet.notifications.permission.openSettings")) {
                                openSystemNotificationSettings()
                            }
                        }

                        notificationFooterText("ba.sheet.notifications.footer")
                    }
                }

                macSettingsGroup(BaL10n.string("ba.settings.resources.section")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(BaL10n.string("ba.sheet.notifications.ap.title"), isOn: profileBinding(\.apNotificationsEnabled))
                        Toggle(BaL10n.string("ba.sheet.notifications.cafeAp.title"), isOn: profileBinding(\.cafeApNotificationsEnabled))
                        Toggle(BaL10n.string("ba.sheet.notifications.visit.title"), isOn: profileBinding(\.visitNotificationsEnabled))
                        Toggle(
                            BaL10n.string("ba.settings.arena.notifications.title"),
                            isOn: profileBinding(\.arenaRefreshNotificationsEnabled)
                        )
                        notificationFooterText("ba.sheet.notifications.resources.footer")
                    }
                }

                macSettingsGroup(BaL10n.string("ba.settings.activityPool.title")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(
                            BaL10n.string("ba.settings.activity.start.notifications.title"),
                            isOn: globalBoolBinding(\.calendarUpcomingNotificationsEnabled)
                        )
                        Toggle(
                            BaL10n.string("ba.settings.activity.end.notifications.title"),
                            isOn: globalBoolBinding(\.calendarEndingNotificationsEnabled)
                        )
                        Toggle(
                            BaL10n.string("ba.settings.pool.start.notifications.title"),
                            isOn: globalBoolBinding(\.poolUpcomingNotificationsEnabled)
                        )
                        Toggle(
                            BaL10n.string("ba.settings.pool.end.notifications.title"),
                            isOn: globalBoolBinding(\.poolEndingNotificationsEnabled)
                        )
                        Toggle(
                            BaL10n.string("ba.settings.calendarPool.change.notifications.title"),
                            isOn: globalBoolBinding(\.calendarPoolChangeNotificationsEnabled)
                        )

                        HStack {
                            Text(BaL10n.string("ba.settings.notifyLead.title"))
                            Spacer()
                            Picker(BaL10n.string("ba.settings.notifyLead.title"), selection: notifyLeadBinding) {
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

                macSettingsGroup(BaL10n.string("ba.sheet.notifications.test.title")) {
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
            Text(BaL10n.string("ba.sheet.notifications.test.title"))
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
            Label(BaL10n.string("ba.sheet.notifications.test.local"), systemImage: "bell.badge")
        }

        #if os(iOS)
        Button {
            Task {
                await startTestLiveActivity(.resource)
            }
        } label: {
            Label(BaL10n.string("ba.sheet.notifications.test.live.resource"), systemImage: "bolt.fill")
        }

        Button {
            Task {
                await startTestLiveActivity(.activity)
            }
        } label: {
            Label(BaL10n.string("ba.sheet.notifications.test.live.activity"), systemImage: "calendar.badge.clock")
        }

        Button {
            Task {
                await startTestLiveActivity(.pool)
            }
        } label: {
            Label(BaL10n.string("ba.sheet.notifications.test.live.pool"), systemImage: "sparkles")
        }

        Button(role: .destructive) {
            Task {
                await endTestLiveActivities()
            }
        } label: {
            Label(BaL10n.string("ba.sheet.notifications.test.live.end"), systemImage: "xmark.circle")
                .foregroundStyle(.red)
        }
        .tint(.red)
        #else
        Text(BaL10n.string("ba.sheet.notifications.test.live.unavailable"))
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

    private func notificationFooterText(_ key: String) -> some View {
        Text(BaL10n.string(key))
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
            ? BaL10n.string("ba.sheet.notifications.test.local.sent")
            : BaL10n.string("ba.sheet.notifications.test.permissionNeeded")
    }

    private func startTestLiveActivity(_ kind: BaDebugLiveActivityKind) async {
        let started = await model.startTestLiveActivity(kind: kind)
        testStatus = started
            ? BaL10n.string("ba.sheet.notifications.test.live.started")
            : BaL10n.string("ba.sheet.notifications.test.live.permissionNeeded")
    }

    private func endTestLiveActivities() async {
        await model.endTestLiveActivities()
        testStatus = BaL10n.string("ba.sheet.notifications.test.live.ended")
    }

    private func openSystemNotificationSettings() {
        #if os(iOS) && canImport(UIKit)
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
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
            BaL10n.string("ba.sheet.notifications.permission.checking")
        case .allowed:
            BaL10n.string("ba.sheet.notifications.permission.allowed")
        case .provisional:
            BaL10n.string("ba.sheet.notifications.permission.provisional")
        case .denied:
            BaL10n.string("ba.sheet.notifications.permission.denied")
        case .notDetermined:
            BaL10n.string("ba.sheet.notifications.permission.notDetermined")
        case .unknown:
            BaL10n.string("ba.sheet.notifications.permission.unknown")
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
        content
            .onAppear {
                draft = model.settings
            }
            .onChange(of: draft.friendCode) { _, value in
                let sanitized = BaFriendCodeFormat.sanitizedDraft(value)
                if sanitized != value {
                    draft.friendCode = sanitized
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
            macContent
        #else
            touchContent
        #endif
    }

    #if os(macOS)
    private var macContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(BaPresentedSheet.editOffice.title)
                    .font(.title3.weight(.semibold))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    macEditGroup(
                        title: BaL10n.string("ba.sheet.edit.identity.title"),
                        footer: BaL10n.string("ba.sheet.edit.identity.footer")
                    ) {
                        macToggleRow {
                            Toggle(
                                BaL10n.string("ba.settings.identity.independent.title"),
                                isOn: $draft.identityIndependentByServer
                            )
                        }

                        macEditRow(BaL10n.string("ba.office.nickname.label")) {
                            TextField(
                                BaL10n.string("ba.office.nickname.label"),
                                text: $draft.nickname,
                                prompt: Text(BaL10n.string("ba.office.nickname.prompt"))
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                        }

                        macEditRow(BaL10n.string("ba.office.friendCode.label")) {
                            TextField(
                                BaL10n.string("ba.office.friendCode.label"),
                                text: $draft.friendCode,
                                prompt: Text(BaL10n.string("ba.office.friendCode.prompt"))
                            )
                            .textFieldStyle(.roundedBorder)
                            .baFriendCodeTextInput()
                            .frame(width: 180)
                        }

                        macEditRow(BaL10n.string("ba.office.server.label")) {
                            Picker(BaL10n.string("ba.office.server.label"), selection: $draft.server) {
                                ForEach(BaServer.allCases) { server in
                                    Text(server.title)
                                        .tag(server)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 140, alignment: .leading)
                        }
                    }

                    macEditGroup(
                        title: BaL10n.string("ba.sheet.edit.resources.title"),
                        footer: BaL10n.string("ba.sheet.edit.resources.footer")
                    ) {
                        macEditRow(BaL10n.string("ba.office.ap.limit.title")) {
                            TextField("240", value: $draft.apLimit, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .baNumberTextInput()
                                .frame(width: 96)
                        }

                        macEditRow(BaL10n.string("ba.cafe.level.title")) {
                            Stepper(value: $draft.cafeLevel, in: 1 ... 10) {
                                Text("Lv\(draft.cafeLevel)")
                                    .monospacedDigit()
                                    .frame(width: 48, alignment: .leading)
                            }
                            .frame(width: 150, alignment: .leading)
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            HStack {
                Spacer()
                Button(BaL10n.string("ba.common.cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(BaL10n.string("ba.common.done")) {
                    saveAndDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 640, height: 520)
    }

    private func macEditGroup<Content: View>(
        title: String,
        footer: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }

            Text(footer)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func macEditRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .trailing)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macToggleRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Spacer()
                .frame(width: 96)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    #endif

    private var touchContent: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(
                        BaL10n.string("ba.settings.identity.independent.title"),
                        isOn: $draft.identityIndependentByServer
                    )
                    TextField(
                        BaL10n.string("ba.office.nickname.label"),
                        text: $draft.nickname,
                        prompt: Text(BaL10n.string("ba.office.nickname.prompt"))
                    )
                    TextField(
                        BaL10n.string("ba.office.friendCode.label"),
                        text: $draft.friendCode,
                        prompt: Text(BaL10n.string("ba.office.friendCode.prompt"))
                    )
                    .baFriendCodeTextInput()
                    Picker(BaL10n.string("ba.office.server.label"), selection: $draft.server) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                } header: {
                    Text(BaL10n.string("ba.sheet.edit.identity.title"))
                } footer: {
                    Text(BaL10n.string("ba.sheet.edit.identity.footer"))
                }

                Section {
                    LabeledContent(BaL10n.string("ba.office.ap.limit.title")) {
                        TextField("240", value: $draft.apLimit, format: .number)
                            .multilineTextAlignment(.trailing)
                            .baNumberTextInput()
                    }
                    Stepper(value: $draft.cafeLevel, in: 1 ... 10) {
                        LabeledContent(BaL10n.string("ba.cafe.level.title")) {
                            Text("Lv\(draft.cafeLevel)")
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text(BaL10n.string("ba.sheet.edit.resources.title"))
                } footer: {
                    Text(BaL10n.string("ba.sheet.edit.resources.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.editOffice.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BaL10n.string("ba.common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(BaL10n.string("ba.common.done")) {
                        saveAndDismiss()
                    }
                }
            }
        }
    }

    private func saveAndDismiss() {
        model.updateSettings { settings in
            settings = draft
            settings.friendCode = BaFriendCodeFormat.normalized(settings.friendCode)
            settings.apLimit = min(max(settings.apLimit, 0), BaTimeMath.apLimitMax)
            settings.cafeLevel = min(max(settings.cafeLevel, 1), 10)
        }
        dismiss()
    }
}

private struct BaDebugToolsSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(BaL10n.string("ba.sheet.debug.state.title")) {
                    LabeledContent(BaL10n.string("ba.sheet.debug.data.title")) {
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
                        Label(BaL10n.string("ba.sheet.debug.refresh.title"), systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glass)
                } footer: {
                    Text(BaL10n.string("ba.sheet.debug.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.debugTools.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BaL10n.string("ba.common.done")) {
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
            format: BaL10n.string("ba.sheet.debug.data.format"),
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
            presentationDetents(sheet.presentationDetents)
                .presentationDragIndicator(.visible)
        #else
            frame(
                minWidth: sheet.macMinimumSheetWidth,
                minHeight: sheet.macMinimumSheetHeight
            )
        #endif
    }
}

#if os(iOS)
private extension BaPresentedSheet {
    var presentationDetents: Set<PresentationDetent> {
        switch self {
        case .settings, .about:
            [.large]
        case .notifications, .editOffice, .debugTools:
            [.medium, .large]
        }
    }
}
#endif

#if os(macOS)
private extension BaPresentedSheet {
    var macMinimumSheetWidth: CGFloat {
        switch self {
        case .notifications:
            680
        case .settings:
            760
        case .about:
            680
        case .editOffice:
            640
        case .debugTools:
            520
        }
    }

    var macMinimumSheetHeight: CGFloat {
        switch self {
        case .notifications:
            660
        case .settings:
            720
        case .about:
            680
        case .editOffice:
            520
        case .debugTools:
            360
        }
    }
}
#endif
