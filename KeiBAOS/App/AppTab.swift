//
//  AppTab.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case students
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            String(localized: "tab.home")
        case .students:
            String(localized: "tab.students")
        case .settings:
            String(localized: "tab.settings")
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "sparkles"
        case .students:
            "person.3.sequence.fill"
        case .settings:
            "gearshape.fill"
        }
    }

    var accessibilityIdentifier: String {
        "tab-\(rawValue)"
    }

    @ViewBuilder
    var rootView: some View {
        switch self {
        case .home:
            HomeView()
        case .students:
            StudentsView()
        case .settings:
            SettingsView()
        }
    }
}
