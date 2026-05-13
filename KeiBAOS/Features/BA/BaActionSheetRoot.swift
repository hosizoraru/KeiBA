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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(String(localized: "ba.sheet.notifications.ap.title"), isOn: .constant(true))
                    Toggle(String(localized: "ba.sheet.notifications.cafeAp.title"), isOn: .constant(true))
                    Toggle(String(localized: "ba.sheet.notifications.visit.title"), isOn: .constant(false))
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
}

private struct BaEditOfficeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = BaOfficeSnapshot.preview.nickname
    @State private var friendCode = BaOfficeSnapshot.preview.friendCode
    @State private var apLimit = BaOfficeSnapshot.preview.apLimit
    @State private var cafeLevel = BaOfficeSnapshot.preview.cafeLevel

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "ba.sheet.edit.identity.title")) {
                    TextField(String(localized: "ba.office.nickname.label"), text: $nickname)
                    TextField(String(localized: "ba.office.friendCode.label"), text: $friendCode)
                    LabeledContent(String(localized: "ba.office.server.label")) {
                        Text(String(localized: "ba.office.server.value"))
                    }
                }

                Section(String(localized: "ba.sheet.edit.resources.title")) {
                    TextField(String(localized: "ba.office.ap.limit.title"), text: $apLimit)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                    TextField(String(localized: "ba.cafe.level.title"), text: $cafeLevel)
                }
            }
            .navigationTitle(BaPresentedSheet.editOffice.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BaDebugToolsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "ba.sheet.debug.state.title")) {
                    LabeledContent(String(localized: "ba.sheet.debug.build.title")) {
                        Text(AppPlatformBaseline.summary)
                    }
                    LabeledContent(String(localized: "ba.sheet.debug.data.title")) {
                        Text(String(localized: "ba.sheet.debug.data.value"))
                    }
                }

                Section {
                    Button {
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
