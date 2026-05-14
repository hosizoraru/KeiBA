//
//  BaActionSheetRoot.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(String(localized: "ba.sheet.notifications.ap.title"), isOn: binding(\.apNotificationsEnabled))
                    Toggle(String(localized: "ba.sheet.notifications.cafeAp.title"), isOn: binding(\.cafeApNotificationsEnabled))
                    Toggle(String(localized: "ba.sheet.notifications.visit.title"), isOn: binding(\.visitNotificationsEnabled))
                } footer: {
                    Text(String(localized: "ba.sheet.notifications.footer"))
                }
            }
            .navigationTitle(BaPresentedSheet.notifications.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<BaAppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { value in
                model.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

private struct BaEditOfficeSheet: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = BaAppSettings.defaults()

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "ba.sheet.edit.identity.title")) {
                    TextField(String(localized: "ba.office.nickname.label"), text: $draft.nickname)
                    TextField(String(localized: "ba.office.friendCode.label"), text: $draft.friendCode)
                    Picker(String(localized: "ba.office.server.label"), selection: $draft.server) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                }

                Section(String(localized: "ba.sheet.edit.resources.title")) {
                    TextField(String(localized: "ba.office.ap.limit.title"), value: $draft.apLimit, format: .number)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                    Stepper(value: $draft.cafeLevel, in: 1...10) {
                        LabeledContent(String(localized: "ba.cafe.level.title")) {
                            Text("Lv\(draft.cafeLevel)")
                        }
                    }
                }
            }
            .navigationTitle(BaPresentedSheet.editOffice.title)
            .onAppear {
                draft = model.settings
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
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
#else
        self
            .frame(minWidth: 420, minHeight: 360)
#endif
    }
}
