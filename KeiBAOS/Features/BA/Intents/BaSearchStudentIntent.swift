//
//  BaSearchStudentIntent.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/29.
//

import AppIntents

struct BaSearchStudentIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Student"
    static var description = IntentDescription("Opens KeiBAOS to search for a student.")

    @Parameter(title: "Student Name")
    var studentName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return .result(dialog: "Please say a student name to search.")
        }
        return .result(dialog: "Open KeiBAOS to search for \(name).")
    }
}
