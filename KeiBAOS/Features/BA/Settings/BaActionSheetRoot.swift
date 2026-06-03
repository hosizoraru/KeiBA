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
        case .watch:
            BaWatchSettingsSheet()
        case .about:
            BaAboutSheet()
        case .editOffice:
            BaEditOfficeSheet()
        case .debugTools:
            BaDebugToolsSheet()
        }
    }
}

private struct BaWatchSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BaWatchSettingsView()
                .navigationTitle(BaPresentedSheet.watch.title)
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
            .scrollContentBackground(.hidden)
            .background(AppBackground())
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
    @State private var editorDraft: BaAccountEditorDraft?
    @State private var pendingDeleteAccountID: BaAccountID?

    var body: some View {
        content
            .sheet(item: $editorDraft) { draft in
                BaAccountEditorSheet(initialDraft: draft) { savedDraft in
                    save(savedDraft)
                }
            }
            .confirmationDialog(
                BaL10n.string("ba.account.delete.title"),
                isPresented: deleteConfirmationBinding,
                titleVisibility: .visible
            ) {
                Button(BaL10n.string("ba.account.delete.confirm"), role: .destructive) {
                    if let pendingDeleteAccountID {
                        model.deleteAccount(id: pendingDeleteAccountID)
                    }
                    pendingDeleteAccountID = nil
                }
                Button(BaL10n.string("ba.common.cancel"), role: .cancel) {
                    pendingDeleteAccountID = nil
                }
            } message: {
                if let pendingDeleteAccount {
                    Text(String(format: BaL10n.string("ba.account.delete.message.format"), pendingDeleteAccount.title))
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
                        title: BaL10n.string("ba.account.management.section"),
                        footer: BaL10n.string("ba.account.management.footer")
                    ) {
                        Button {
                            startAddAccount()
                        } label: {
                            Label(BaL10n.string("ba.account.add.title"), systemImage: "person.crop.circle.badge.plus")
                        }
                    }

                    ForEach(accountListItems) { item in
                        accountManagementRow(item)
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
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 680, height: 640)
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
    #endif

    private var touchContent: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        startAddAccount()
                    } label: {
                        Label(BaL10n.string("ba.account.add.title"), systemImage: "person.crop.circle.badge.plus")
                    }
                } header: {
                    Text(BaL10n.string("ba.account.management.section"))
                } footer: {
                    Text(BaL10n.string("ba.account.management.footer"))
                }

                Section {
                    ForEach(accountListItems) { item in
                        accountManagementRow(item)
                    }
                } header: {
                    Text(BaL10n.string("ba.account.list.title"))
                }
            }
            .navigationTitle(BaPresentedSheet.editOffice.title)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BaL10n.string("ba.common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(BaL10n.string("ba.common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var accountListItems: [BaAccountListItem] {
        let accounts = model.accounts
        return accounts.enumerated().map { index, account in
            BaAccountListItem(
                index: index,
                account: account,
                totalCount: accounts.count
            )
        }
    }

    private func accountManagementRow(_ item: BaAccountListItem) -> some View {
        BaAccountManagementRow(
            account: item.account,
            isActive: item.account.id == model.currentAccount.id,
            canDelete: item.totalCount > 1,
            canMoveUp: item.index > 0,
            canMoveDown: item.index < item.totalCount - 1,
            onSelect: { model.selectAccount(item.account.id) },
            onEdit: { editorDraft = BaAccountEditorDraft(account: item.account) },
            onEnabledChange: { model.setAccountEnabled(id: item.account.id, isEnabled: $0) },
            onMove: { model.moveAccount(id: item.account.id, offset: $0) },
            onDelete: { pendingDeleteAccountID = item.account.id }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteAccountID != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDeleteAccountID = nil
                }
            }
        )
    }

    private var pendingDeleteAccount: BaAccountProfile? {
        guard let pendingDeleteAccountID else { return nil }
        return model.accounts.first { $0.id == pendingDeleteAccountID }
    }

    private func startAddAccount() {
        editorDraft = BaAccountEditorDraft.new(defaultServer: model.currentAccount.server)
    }

    private func save(_ draft: BaAccountEditorDraft) {
        if let editingAccountID = draft.editingAccountID {
            model.updateAccount(
                id: editingAccountID,
                displayName: draft.displayName,
                server: draft.server,
                nickname: draft.nickname,
                friendCode: draft.friendCode,
                isEnabled: draft.isEnabled,
                apNotificationsEnabled: draft.apNotificationsEnabled,
                cafeApNotificationsEnabled: draft.cafeApNotificationsEnabled,
                visitNotificationsEnabled: draft.visitNotificationsEnabled,
                arenaRefreshNotificationsEnabled: draft.arenaRefreshNotificationsEnabled,
                apNotifyThreshold: draft.apNotifyThreshold,
                cafeApNotifyThreshold: draft.cafeApNotifyThreshold
            )
        } else {
            model.addAccount(
                displayName: draft.displayName,
                server: draft.server,
                nickname: draft.nickname,
                friendCode: draft.friendCode,
                apNotificationsEnabled: draft.apNotificationsEnabled,
                cafeApNotificationsEnabled: draft.cafeApNotificationsEnabled,
                visitNotificationsEnabled: draft.visitNotificationsEnabled,
                arenaRefreshNotificationsEnabled: draft.arenaRefreshNotificationsEnabled,
                apNotifyThreshold: draft.apNotifyThreshold,
                cafeApNotifyThreshold: draft.cafeApNotifyThreshold
            )
        }
    }
}

private struct BaAccountListItem: Identifiable {
    let index: Int
    let account: BaAccountProfile
    let totalCount: Int

    var id: BaAccountID {
        account.id
    }
}

private struct BaAccountEditorDraft: Identifiable {
    var editingAccountID: BaAccountID?
    var displayName: String
    var server: BaServer
    var nickname: String
    var friendCode: String
    var isEnabled: Bool
    var apNotificationsEnabled: Bool
    var cafeApNotificationsEnabled: Bool
    var visitNotificationsEnabled: Bool
    var arenaRefreshNotificationsEnabled: Bool
    var apNotifyThreshold: Int
    var cafeApNotifyThreshold: Int

    var id: String {
        editingAccountID ?? "new-\(server.rawValue)"
    }

    static func new(defaultServer: BaServer) -> BaAccountEditorDraft {
        let defaults = BaServerProfile.defaults()
        return BaAccountEditorDraft(
            editingAccountID: nil,
            displayName: BaL10n.string("ba.account.new.defaultName"),
            server: defaultServer,
            nickname: defaults.nickname,
            friendCode: defaults.friendCode,
            isEnabled: true,
            apNotificationsEnabled: defaults.apNotificationsEnabled,
            cafeApNotificationsEnabled: defaults.cafeApNotificationsEnabled,
            visitNotificationsEnabled: defaults.visitNotificationsEnabled,
            arenaRefreshNotificationsEnabled: defaults.arenaRefreshNotificationsEnabled,
            apNotifyThreshold: defaults.apNotifyThreshold,
            cafeApNotifyThreshold: defaults.cafeApNotifyThreshold
        )
    }

    init(account: BaAccountProfile) {
        editingAccountID = account.id
        displayName = account.displayName
        server = account.server
        nickname = account.profile.nickname
        friendCode = account.profile.friendCode
        isEnabled = account.isEnabled
        apNotificationsEnabled = account.profile.apNotificationsEnabled
        cafeApNotificationsEnabled = account.profile.cafeApNotificationsEnabled
        visitNotificationsEnabled = account.profile.visitNotificationsEnabled
        arenaRefreshNotificationsEnabled = account.profile.arenaRefreshNotificationsEnabled
        apNotifyThreshold = account.profile.apNotifyThreshold
        cafeApNotifyThreshold = account.profile.cafeApNotifyThreshold
    }

    private init(
        editingAccountID: BaAccountID?,
        displayName: String,
        server: BaServer,
        nickname: String,
        friendCode: String,
        isEnabled: Bool,
        apNotificationsEnabled: Bool,
        cafeApNotificationsEnabled: Bool,
        visitNotificationsEnabled: Bool,
        arenaRefreshNotificationsEnabled: Bool,
        apNotifyThreshold: Int,
        cafeApNotifyThreshold: Int
    ) {
        self.editingAccountID = editingAccountID
        self.displayName = displayName
        self.server = server
        self.nickname = nickname
        self.friendCode = friendCode
        self.isEnabled = isEnabled
        self.apNotificationsEnabled = apNotificationsEnabled
        self.cafeApNotificationsEnabled = cafeApNotificationsEnabled
        self.visitNotificationsEnabled = visitNotificationsEnabled
        self.arenaRefreshNotificationsEnabled = arenaRefreshNotificationsEnabled
        self.apNotifyThreshold = apNotifyThreshold
        self.cafeApNotifyThreshold = cafeApNotifyThreshold
    }

    mutating func normalizeForSave() {
        friendCode = BaFriendCodeFormat.normalized(friendCode)
        apNotifyThreshold = min(max(apNotifyThreshold, 0), BaTimeMath.apMax)
        cafeApNotifyThreshold = min(max(cafeApNotifyThreshold, 0), BaTimeMath.apMax)
    }
}

private struct BaAccountEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BaAccountEditorDraft

    let onSave: (BaAccountEditorDraft) -> Void

    init(initialDraft: BaAccountEditorDraft, onSave: @escaping (BaAccountEditorDraft) -> Void) {
        _draft = State(initialValue: initialDraft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BaAccountEditorSummaryRow(
                        title: previewTitle,
                        detail: previewDetail,
                        isEnabled: draft.isEnabled
                    )
                }

                Section {
                    LabeledContent(BaL10n.string("ba.account.displayName.title")) {
                        TextField(
                            BaL10n.string("ba.account.displayName.title"),
                            text: $draft.displayName,
                            prompt: Text(BaL10n.string("ba.account.displayName.prompt"))
                        )
                        .multilineTextAlignment(.trailing)
                        .baAccountDisplayNameTextInput()
                    }

                    LabeledContent(BaL10n.string("ba.office.nickname.label")) {
                        TextField(
                            BaL10n.string("ba.office.nickname.label"),
                            text: $draft.nickname,
                            prompt: Text(BaL10n.string("ba.office.nickname.prompt"))
                        )
                        .multilineTextAlignment(.trailing)
                        .baNicknameTextInput()
                    }

                    LabeledContent(BaL10n.string("ba.office.friendCode.label")) {
                        TextField(
                            BaL10n.string("ba.office.friendCode.label"),
                            text: $draft.friendCode,
                            prompt: Text(BaL10n.string("ba.office.friendCode.prompt"))
                        )
                        .multilineTextAlignment(.trailing)
                        .baFriendCodeTextInput()
                        .onChange(of: draft.friendCode) { _, value in
                            let sanitized = BaFriendCodeFormat.sanitizedDraft(value)
                            if sanitized != value {
                                draft.friendCode = sanitized
                            }
                        }
                    }

                    Picker(BaL10n.string("ba.office.server.label"), selection: $draft.server) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }

                    Toggle(BaL10n.string("ba.account.enabled.title"), isOn: $draft.isEnabled)
                } footer: {
                    Text(BaL10n.string("ba.account.editor.footer"))
                }

                Section {
                    Toggle(BaL10n.string("ba.sheet.notifications.ap.title"), isOn: $draft.apNotificationsEnabled)

                    Stepper(
                        value: intBinding(\.apNotifyThreshold, range: 0 ... BaTimeMath.apMax),
                        in: 0 ... BaTimeMath.apMax
                    ) {
                        LabeledContent(BaL10n.string("ba.settings.ap.threshold.title")) {
                            Text("\(draft.apNotifyThreshold)")
                                .monospacedDigit()
                        }
                    }
                    .disabled(draft.apNotificationsEnabled == false)

                    Toggle(BaL10n.string("ba.sheet.notifications.cafeAp.title"), isOn: $draft.cafeApNotificationsEnabled)

                    Stepper(
                        value: intBinding(\.cafeApNotifyThreshold, range: 0 ... BaTimeMath.apMax),
                        in: 0 ... BaTimeMath.apMax
                    ) {
                        LabeledContent(BaL10n.string("ba.settings.cafe.threshold.title")) {
                            Text("\(draft.cafeApNotifyThreshold)")
                                .monospacedDigit()
                        }
                    }
                    .disabled(draft.cafeApNotificationsEnabled == false)

                    Toggle(BaL10n.string("ba.sheet.notifications.visit.title"), isOn: $draft.visitNotificationsEnabled)
                    Toggle(
                        BaL10n.string("ba.settings.arena.notifications.title"),
                        isOn: $draft.arenaRefreshNotificationsEnabled
                    )
                } header: {
                    Text(BaL10n.string("ba.settings.resources.section"))
                } footer: {
                    Text(BaL10n.string("ba.sheet.notifications.resources.footer"))
                }
            }
            .navigationTitle(editorTitle)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BaL10n.string("ba.common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(BaL10n.string("ba.common.done")) {
                        var saved = draft
                        saved.normalizeForSave()
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(canSave == false)
                }
            }
        }
        #if os(iOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
        #else
            .frame(minWidth: 520, minHeight: 560)
        #endif
    }

    private var editorTitle: String {
        draft.editingAccountID == nil
            ? BaL10n.string("ba.account.add.title")
            : BaL10n.string("ba.account.edit.title")
    }

    private var previewTitle: String {
        let displayName = draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if displayName.isEmpty == false {
            return displayName
        }

        let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return nickname.isEmpty ? BaL10n.string("ba.account.new.defaultName") : nickname
    }

    private var previewDetail: String {
        String(
            format: BaL10n.string("ba.account.summary.format"),
            draft.server.title,
            previewNickname,
            previewFriendCode
        )
    }

    private var previewNickname: String {
        let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return nickname.isEmpty ? BaL10n.string("ba.common.none") : nickname
    }

    private var previewFriendCode: String {
        let friendCode = BaFriendCodeFormat.sanitizedDraft(draft.friendCode)
        return friendCode.isEmpty ? BaL10n.string("ba.common.none") : "# \(friendCode)"
    }

    private var canSave: Bool {
        let displayName = draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return displayName.isEmpty == false || nickname.isEmpty == false
    }

    private func intBinding(
        _ keyPath: WritableKeyPath<BaAccountEditorDraft, Int>,
        range: ClosedRange<Int>
    ) -> Binding<Int> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { value in
                draft[keyPath: keyPath] = min(max(value, range.lowerBound), range.upperBound)
            }
        )
    }
}

private struct BaAccountEditorSummaryRow: View {
    let title: String
    let detail: String
    let isEnabled: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isEnabled ? "person.crop.circle.fill" : "person.crop.circle.badge.xmark")
                .font(.title2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isEnabled ? BaDesign.blue : .secondary)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct BaAccountManagementRow: View {
    let account: BaAccountProfile
    let isActive: Bool
    let canDelete: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onEnabledChange: (Bool) -> Void
    let onMove: (Int) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: leadingSystemImage)
                        .font(.title3.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isActive ? BaDesign.blue : .secondary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(account.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)

                            if isActive {
                                BaAccountStatusChip(
                                    title: BaL10n.string("ba.account.active.badge"),
                                    tint: BaDesign.blue
                                )
                            }
                        }

                        Text(compactDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isActive || account.isEnabled == false)
            .opacity(account.isEnabled ? 1 : 0.58)
            .accessibilityLabel(Text(account.detail))

            Toggle(BaL10n.string("ba.account.enabled.title"), isOn: enabledBinding)
                .labelsHidden()

            actionsMenu
        }
        .padding(.vertical, 8)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { account.isEnabled },
            set: onEnabledChange
        )
    }

    private var leadingSystemImage: String {
        if account.isEnabled == false {
            return "person.crop.circle.badge.xmark"
        }
        return isActive ? "checkmark.circle.fill" : "person.crop.circle"
    }

    private var compactDetail: String {
        BaAccountDisplayText.compactDetail(for: account)
    }

    private var actionsMenu: some View {
        Menu {
            Button {
                onSelect()
            } label: {
                Label(
                    isActive ? BaL10n.string("ba.account.active.action") : BaL10n.string("ba.account.use.action"),
                    systemImage: isActive ? "checkmark.circle.fill" : "person.crop.circle.badge.checkmark"
                )
            }
            .disabled(isActive || account.isEnabled == false)

            Button {
                onEdit()
            } label: {
                Label(BaL10n.string("ba.account.edit.title"), systemImage: "pencil")
            }

            Divider()

            Button {
                onMove(-1)
            } label: {
                Label(BaL10n.string("ba.account.moveUp.title"), systemImage: "arrow.up")
            }
            .disabled(canMoveUp == false)

            Button {
                onMove(1)
            } label: {
                Label(BaL10n.string("ba.account.moveDown.title"), systemImage: "arrow.down")
            }
            .disabled(canMoveDown == false)

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(BaL10n.string("ba.account.delete.title"), systemImage: "trash")
            }
            .disabled(canDelete == false)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .menuOrder(.fixed)
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(BaL10n.string("ba.action.more.title")))
    }
}

private struct BaAccountStatusChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.10), in: Capsule())
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
            .scrollContentBackground(.hidden)
            .background(AppBackground())
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
                .presentationContentInteraction(.scrolls)
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
        case .settings, .editOffice, .about:
            [.large]
        case .notifications, .watch, .debugTools:
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
        case .watch:
            620
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
        case .watch:
            560
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
