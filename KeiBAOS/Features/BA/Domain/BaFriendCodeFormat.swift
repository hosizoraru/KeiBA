//
//  BaFriendCodeFormat.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaFriendCodeFormat {
    static let length = 8
    static let fallback = "ARISUKEI"

    private static let allowedScalars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    static func sanitizedDraft(_ value: String) -> String {
        String(normalizedScalars(in: value).prefix(length))
    }

    static func normalized(_ value: String) -> String {
        let sanitized = sanitizedDraft(value)
        return sanitized.count == length ? sanitized : fallback
    }

    private static func normalizedScalars(in value: String) -> String {
        value.uppercased().unicodeScalars.reduce(into: "") { output, scalar in
            guard allowedScalars.contains(scalar) else { return }
            output.unicodeScalars.append(scalar)
        }
    }
}
