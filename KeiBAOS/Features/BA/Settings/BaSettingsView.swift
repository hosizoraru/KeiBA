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
        #if os(macOS)
            macSettingsBody
        #else
            touchSettingsBody
        #endif
    }

    private var touchSettingsBody: some View {
        BaAdaptiveGeometry { _ in
            Form {
                appPreferencesSection
                serverIdentitySection
                resourcesSection
                activityPoolSection
                notificationSection
                mediaSection
            }
            .baAdaptiveReadableContent(maxWidth: 760)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
        }
    }

    #if os(macOS)
    private var macSettingsBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                macSettingsGroup(
                    title: BaL10n.string("ba.settings.app.section"),
                    footer: BaL10n.string("ba.settings.app.footer")
                ) {
                    macSettingsRow(BaL10n.string("ba.settings.language.title")) {
                        Picker(BaL10n.string("ba.settings.language.title"), selection: appLanguageBinding) {
                            ForEach(BaAppLanguage.allCases) { language in
                                Text(language.titleResource)
                                    .tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 180, alignment: .leading)
                    }

                    macSettingsRow(BaL10n.string("ba.settings.appearance.title")) {
                        Picker(BaL10n.string("ba.settings.appearance.title"), selection: appAppearanceBinding) {
                            ForEach(BaAppAppearance.allCases) { appearance in
                                Text(appearance.titleResource)
                                    .tag(appearance)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 180, alignment: .leading)
                    }
                }

                macSettingsGroup(
                    title: BaL10n.string("ba.settings.identity.section"),
                    footer: BaL10n.string("ba.settings.identity.footer")
                ) {
                    macSettingsRow(BaL10n.string("ba.account.switch.title")) {
                        Picker(BaL10n.string("ba.account.switch.title"), selection: accountBinding) {
                            ForEach(model.accounts) { account in
                                Text(account.title)
                                    .tag(account.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220, alignment: .leading)
                    }

                    macSettingsRow(BaL10n.string("ba.office.nickname.label")) {
                        BaDeferredTextField(
                            title: BaL10n.string("ba.office.nickname.label"),
                            value: model.currentProfile.nickname,
                            prompt: BaL10n.string("ba.office.nickname.prompt")
                        ) { value in
                            model.updateCurrentProfile { $0.nickname = value }
                        }
                        .baNicknameTextInput()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                    }

                    macSettingsRow(BaL10n.string("ba.office.friendCode.label")) {
                        BaDeferredTextField(
                            title: BaL10n.string("ba.office.friendCode.label"),
                            value: model.currentProfile.friendCode,
                            prompt: BaL10n.string("ba.office.friendCode.prompt"),
                            sanitizeDraft: BaFriendCodeFormat.sanitizedDraft,
                            normalizeCommit: BaFriendCodeFormat.normalized
                        ) { value in
                            model.updateCurrentProfile { $0.friendCode = value }
                        }
                        .textFieldStyle(.roundedBorder)
                        .baFriendCodeTextInput()
                        .frame(width: 180)
                    }
                }

                macSettingsGroup(
                    title: BaL10n.string("ba.settings.resources.section"),
                    footer: BaL10n.string("ba.settings.resources.footer")
                ) {
                    macNumberRow(
                        BaL10n.string("ba.office.ap.limit.title"),
                        value: model.currentProfile.apLimit,
                        prompt: "240",
                        range: 0 ... BaTimeMath.apLimitMax
                    ) { value in
                        model.setAPLimit(value)
                    }

                    macSettingsRow(BaL10n.string("ba.cafe.level.title")) {
                        Stepper(value: profileIntBinding(\.cafeLevel, range: 1 ... 10), in: 1 ... 10) {
                            Text("Lv\(model.currentProfile.cafeLevel)")
                                .monospacedDigit()
                                .frame(width: 52, alignment: .leading)
                        }
                        .frame(width: 150, alignment: .leading)
                    }

                    macNumberRow(
                        BaL10n.string("ba.settings.ap.threshold.title"),
                        value: model.currentProfile.apNotifyThreshold,
                        prompt: "120",
                        range: 0 ... BaTimeMath.apMax
                    ) { value in
                        model.setAPNotifyThreshold(value)
                    }

                    macNumberRow(
                        BaL10n.string("ba.settings.cafe.threshold.title"),
                        value: model.currentProfile.cafeApNotifyThreshold,
                        prompt: "120",
                        range: 0 ... BaTimeMath.apMax
                    ) { value in
                        model.setCafeAPNotifyThreshold(value)
                    }
                }

                macSettingsGroup(
                    title: BaL10n.string("ba.settings.activityPool.title"),
                    footer: BaL10n.string("ba.settings.activityPool.footer")
                ) {
                    macToggleRow {
                        Toggle(
                            BaL10n.string("ba.settings.activity.showEnded.title"),
                            isOn: globalBoolBinding(\.showEndedActivities)
                        )
                    }

                    macToggleRow {
                        Toggle(
                            BaL10n.string("ba.settings.pool.showEnded.title"),
                            isOn: globalBoolBinding(\.showEndedPools)
                        )
                    }

                    macSettingsRow(BaL10n.string("ba.settings.refresh.title")) {
                        Picker(BaL10n.string("ba.settings.refresh.title"), selection: refreshIntervalBinding) {
                            ForEach(BaRefreshInterval.allCases) { interval in
                                Text(interval.title)
                                    .tag(interval)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 150, alignment: .leading)
                    }
                }

                macSettingsGroup(
                    title: BaL10n.string("ba.settings.notifications.title"),
                    footer: BaL10n.string("ba.sheet.notifications.footer")
                ) {
                    macToggleRow {
                        Toggle(BaL10n.string("ba.sheet.notifications.ap.title"), isOn: profileBoolBinding(\.apNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.sheet.notifications.cafeAp.title"), isOn: profileBoolBinding(\.cafeApNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.sheet.notifications.visit.title"), isOn: profileBoolBinding(\.visitNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.arena.notifications.title"), isOn: profileBoolBinding(\.arenaRefreshNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.activity.start.notifications.title"), isOn: globalBoolBinding(\.calendarUpcomingNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.activity.end.notifications.title"), isOn: globalBoolBinding(\.calendarEndingNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.pool.start.notifications.title"), isOn: globalBoolBinding(\.poolUpcomingNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.pool.end.notifications.title"), isOn: globalBoolBinding(\.poolEndingNotificationsEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.calendarPool.change.notifications.title"), isOn: globalBoolBinding(\.calendarPoolChangeNotificationsEnabled))
                    }
                    macSettingsRow(BaL10n.string("ba.settings.notifyLead.title")) {
                        Picker(BaL10n.string("ba.settings.notifyLead.title"), selection: notifyLeadBinding) {
                            ForEach(BaCalendarPoolNotifyLead.allCases) { lead in
                                Text(lead.title)
                                    .tag(lead)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 150, alignment: .leading)
                    }
                }

                macSettingsGroup(
                    title: BaL10n.string("ba.settings.media.title"),
                    footer: BaL10n.string("ba.settings.media.footer")
                ) {
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.media.images.title"), isOn: globalBoolBinding(\.showPreviewImages))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.media.autoplay.title"), isOn: globalBoolBinding(\.mediaAutoplayEnabled))
                    }
                    macToggleRow {
                        Toggle(BaL10n.string("ba.settings.media.download.title"), isOn: globalBoolBinding(\.mediaDownloadEnabled))
                    }
                }

            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 88)
            .frame(maxWidth: 780)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppBackground())
    }

    private func macSettingsGroup<Content: View>(
        title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func macSettingsRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 132, alignment: .trailing)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macToggleRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Spacer()
                .frame(width: 132)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macNumberRow(
        _ title: String,
        value: Int,
        prompt: String,
        range: ClosedRange<Int>,
        onCommit: @escaping (Int) -> Void
    ) -> some View {
        macSettingsRow(title) {
            BaDeferredIntField(
                title: title,
                value: value,
                prompt: prompt,
                range: range,
                onCommit: onCommit
            )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .baNumberTextInput()
                .frame(width: 96)
        }
    }

    private func macReadOnlyRow(_ title: String, value: String) -> some View {
        macSettingsRow(title) {
            Text(value)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    #endif

    private var serverIdentitySection: some View {
        Section {
            Picker(BaL10n.string("ba.account.switch.title"), selection: accountBinding) {
                ForEach(model.accounts) { account in
                    Text(account.title)
                        .tag(account.id)
                }
            }

            BaDeferredTextField(
                title: BaL10n.string("ba.office.nickname.label"),
                value: model.currentProfile.nickname,
                prompt: BaL10n.string("ba.office.nickname.prompt")
            ) { value in
                model.updateCurrentProfile { $0.nickname = value }
            }
            .baNicknameTextInput()

            BaDeferredTextField(
                title: BaL10n.string("ba.office.friendCode.label"),
                value: model.currentProfile.friendCode,
                prompt: BaL10n.string("ba.office.friendCode.prompt"),
                sanitizeDraft: BaFriendCodeFormat.sanitizedDraft,
                normalizeCommit: BaFriendCodeFormat.normalized
            ) { value in
                model.updateCurrentProfile { $0.friendCode = value }
            }
            .baFriendCodeTextInput()
        } header: {
            Text(BaL10n.string("ba.settings.identity.section"))
        } footer: {
            Text(BaL10n.string("ba.settings.identity.footer"))
        }
    }

    private var resourcesSection: some View {
        Section {
            LabeledContent(BaL10n.string("ba.office.ap.limit.title")) {
                BaDeferredIntField(
                    title: BaL10n.string("ba.office.ap.limit.title"),
                    value: model.currentProfile.apLimit,
                    prompt: "240",
                    range: 0 ... BaTimeMath.apLimitMax
                ) { value in
                    model.setAPLimit(value)
                }
                .multilineTextAlignment(.trailing)
                .baNumberTextInput()
            }

            Stepper(value: profileIntBinding(\.cafeLevel, range: 1 ... 10), in: 1 ... 10) {
                LabeledContent(BaL10n.string("ba.cafe.level.title")) {
                    Text("Lv\(model.currentProfile.cafeLevel)")
                }
            }

            LabeledContent(BaL10n.string("ba.settings.ap.threshold.title")) {
                BaDeferredIntField(
                    title: BaL10n.string("ba.settings.ap.threshold.title"),
                    value: model.currentProfile.apNotifyThreshold,
                    prompt: "120",
                    range: 0 ... BaTimeMath.apMax
                ) { value in
                    model.setAPNotifyThreshold(value)
                }
                .multilineTextAlignment(.trailing)
                .baNumberTextInput()
            }

            LabeledContent(BaL10n.string("ba.settings.cafe.threshold.title")) {
                BaDeferredIntField(
                    title: BaL10n.string("ba.settings.cafe.threshold.title"),
                    value: model.currentProfile.cafeApNotifyThreshold,
                    prompt: "120",
                    range: 0 ... BaTimeMath.apMax
                ) { value in
                    model.setCafeAPNotifyThreshold(value)
                }
                .multilineTextAlignment(.trailing)
                .baNumberTextInput()
            }
        } header: {
            Text(BaL10n.string("ba.settings.resources.section"))
        } footer: {
            Text(BaL10n.string("ba.settings.resources.footer"))
        }
    }

    private var activityPoolSection: some View {
        Section {
            Toggle(
                BaL10n.string("ba.settings.activity.showEnded.title"),
                isOn: globalBoolBinding(\.showEndedActivities)
            )
            Toggle(
                BaL10n.string("ba.settings.pool.showEnded.title"),
                isOn: globalBoolBinding(\.showEndedPools)
            )

            Picker(BaL10n.string("ba.settings.refresh.title"), selection: refreshIntervalBinding) {
                ForEach(BaRefreshInterval.allCases) { interval in
                    Text(interval.title)
                        .tag(interval)
                }
            }
        } header: {
            Text(BaL10n.string("ba.settings.activityPool.title"))
        } footer: {
            Text(BaL10n.string("ba.settings.activityPool.footer"))
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle(
                BaL10n.string("ba.sheet.notifications.ap.title"),
                isOn: profileBoolBinding(\.apNotificationsEnabled)
            )
            Toggle(
                BaL10n.string("ba.sheet.notifications.cafeAp.title"),
                isOn: profileBoolBinding(\.cafeApNotificationsEnabled)
            )
            Toggle(
                BaL10n.string("ba.sheet.notifications.visit.title"),
                isOn: profileBoolBinding(\.visitNotificationsEnabled)
            )
            Toggle(
                BaL10n.string("ba.settings.arena.notifications.title"),
                isOn: profileBoolBinding(\.arenaRefreshNotificationsEnabled)
            )

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
            Text(BaL10n.string("ba.settings.notifications.title"))
        } footer: {
            Text(BaL10n.string("ba.sheet.notifications.footer"))
        }
    }

    private var mediaSection: some View {
        Section {
            Toggle(BaL10n.string("ba.settings.media.images.title"), isOn: globalBoolBinding(\.showPreviewImages))
            Toggle(
                BaL10n.string("ba.settings.media.autoplay.title"),
                isOn: globalBoolBinding(\.mediaAutoplayEnabled)
            )
            Toggle(
                BaL10n.string("ba.settings.media.download.title"),
                isOn: globalBoolBinding(\.mediaDownloadEnabled)
            )
        } header: {
            Text(BaL10n.string("ba.settings.media.title"))
        } footer: {
            Text(BaL10n.string("ba.settings.media.footer"))
        }
    }

    private var appPreferencesSection: some View {
        Section {
            Picker(BaL10n.string("ba.settings.language.title"), selection: appLanguageBinding) {
                ForEach(BaAppLanguage.allCases) { language in
                    Text(language.titleResource)
                        .tag(language)
                }
            }

            Picker(BaL10n.string("ba.settings.appearance.title"), selection: appAppearanceBinding) {
                ForEach(BaAppAppearance.allCases) { appearance in
                    Text(appearance.titleResource)
                        .tag(appearance)
                }
            }
            #if os(macOS)
                .pickerStyle(.menu)
            #endif

            #if os(iOS)
                Picker(BaL10n.string("ba.settings.appIcon.title"), selection: appIconBinding) {
                    ForEach(BaAppIconChoice.allCases) { choice in
                        Text(choice.titleResource)
                            .tag(choice)
                    }
                }
            #endif
        } header: {
            Text(BaL10n.string("ba.settings.app.section"))
        } footer: {
            #if os(iOS)
                Text(BaL10n.string("ba.settings.app.footer.touch"))
            #else
                Text(BaL10n.string("ba.settings.app.footer"))
            #endif
        }
    }

    private var accountBinding: Binding<BaAccountID> {
        Binding(
            get: { model.currentAccount.id },
            set: { accountID in
                model.selectAccount(accountID)
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

    private var appLanguageBinding: Binding<BaAppLanguage> {
        Binding(
            get: { model.envelope.globalSettings.appLanguage },
            set: { language in
                model.updateGlobalSettings { $0.appLanguage = language }
            }
        )
    }

    private var appAppearanceBinding: Binding<BaAppAppearance> {
        Binding(
            get: { model.envelope.globalSettings.appAppearance },
            set: { appearance in
                model.updateGlobalSettings { $0.appAppearance = appearance }
            }
        )
    }

    private var appIconBinding: Binding<BaAppIconChoice> {
        Binding(
            get: { model.envelope.globalSettings.appIcon },
            set: { choice in
                model.setAppIconChoice(choice)
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
