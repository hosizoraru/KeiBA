//
//  BaAppIconChoice.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

nonisolated enum BaAppIconChoice: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case modern
    case classic

    var id: Self {
        self
    }

    var titleResource: LocalizedStringResource {
        switch self {
        case .modern:
            "ba.settings.appIcon.modern"
        case .classic:
            "ba.settings.appIcon.classic"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .modern:
            nil
        case .classic:
            "AppIcon"
        }
    }
}
