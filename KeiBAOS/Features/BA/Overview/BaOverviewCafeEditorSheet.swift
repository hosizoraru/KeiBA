//
//  BaOverviewCafeEditorSheet.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaOverviewCafeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let cafeLevel: Int
    let cafeThreshold: Int
    let onSave: (Int, Int) -> Void

    @State private var level = 1
    @State private var thresholdText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $level, in: 1 ... 10) {
                        LabeledContent(String(localized: "ba.cafe.level.title")) {
                            Text("Lv\(level)")
                                .monospacedDigit()
                        }
                    }
                } footer: {
                    Text(String(localized: "ba.overview.cafe.editor.level.footer"))
                }

                Section {
                    LabeledContent(String(localized: "ba.settings.cafe.threshold.title")) {
                        TextField("\(cafeThreshold)", text: $thresholdText)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .onChange(of: thresholdText) { _, value in
                                let filtered = value.filter(\.isNumber).prefix(3)
                                let next = String(filtered)
                                if next != value {
                                    thresholdText = next
                                }
                            }
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                } footer: {
                    Text(String(localized: "ba.overview.cafe.editor.threshold.footer"))
                }
            }
            .navigationTitle(String(localized: "ba.overview.cafe.editor.title"))
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
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
        #else
            .frame(minWidth: 360, minHeight: 280)
        #endif
        .onAppear(perform: syncDraft)
        .onChange(of: cafeLevel) { _, _ in syncDraft() }
        .onChange(of: cafeThreshold) { _, _ in syncDraft() }
    }

    private func syncDraft() {
        level = min(max(cafeLevel, 1), 10)
        thresholdText = "\(cafeThreshold)"
    }

    private func save() {
        let threshold = Int(thresholdText) ?? cafeThreshold
        onSave(level, threshold)
        dismiss()
    }
}
