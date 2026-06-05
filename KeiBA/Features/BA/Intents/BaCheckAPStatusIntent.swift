//
//  BaCheckAPStatusIntent.swift
//  KeiBA
//
//  Created by Codex on 2026/05/29.
//

import AppIntents

struct BaCheckAPStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check AP Status"
    static var description = IntentDescription("Shows a reminder to check your AP status in KeiBA.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Open KeiBA to check your AP status and café status.")
    }
}
