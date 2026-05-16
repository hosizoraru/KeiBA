//
//  BaOverviewAPEditorSheet.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaOverviewAPEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentAP: String
    let apThreshold: String
    let apLimit: String
    let onSave: (Int, Int, Int) -> Void

    @State private var currentText = ""
    @State private var thresholdText = ""
    @State private var limitText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    numberField(
                        title: String(localized: "ba.office.ap.current.title"),
                        text: $currentText,
                        fallback: currentAP
                    )
                } footer: {
                    Text(String(localized: "ba.overview.ap.editor.current.footer"))
                }

                Section {
                    numberField(
                        title: String(localized: "ba.settings.ap.threshold.title"),
                        text: $thresholdText,
                        fallback: apThreshold
                    )
                    numberField(
                        title: String(localized: "ba.office.ap.limit.title"),
                        text: $limitText,
                        fallback: apLimit
                    )
                } footer: {
                    Text(String(localized: "ba.overview.ap.editor.rules.footer"))
                }
            }
            .navigationTitle(String(localized: "ba.overview.ap.editor.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "ba.common.done"), action: save)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.height(380), .medium])
        .presentationDragIndicator(.visible)
        #else
        .frame(minWidth: 360, minHeight: 300)
        #endif
        .onAppear(perform: syncDraft)
        .onChange(of: currentAP) { _, _ in syncDraft() }
        .onChange(of: apThreshold) { _, _ in syncDraft() }
        .onChange(of: apLimit) { _, _ in syncDraft() }
    }

    private func numberField(
        title: String,
        text: Binding<String>,
        fallback: String
    ) -> some View {
        LabeledContent(title) {
            TextField(fallback, text: text)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .onChange(of: text.wrappedValue) { _, value in
                    let filtered = value.filter(\.isNumber).prefix(3)
                    let next = String(filtered)
                    if next != value {
                        text.wrappedValue = next
                    }
                }
            #if os(iOS)
                .keyboardType(.numberPad)
            #endif
        }
    }

    private func syncDraft() {
        currentText = currentAP
        thresholdText = apThreshold
        limitText = apLimit
    }

    private func save() {
        let current = Int(currentText) ?? Int(currentAP) ?? 0
        let threshold = Int(thresholdText) ?? Int(apThreshold) ?? 0
        let limit = Int(limitText) ?? Int(apLimit) ?? 0
        onSave(current, limit, threshold)
        dismiss()
    }
}
