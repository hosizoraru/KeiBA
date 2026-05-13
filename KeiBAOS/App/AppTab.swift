//
//  AppTab.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case overview
    case catalog
    case cafe
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .overview:
            String(localized: "ba.tab.overview")
        case .catalog:
            String(localized: "ba.tab.catalog")
        case .cafe:
            String(localized: "ba.tab.cafe")
        case .settings:
            String(localized: "ba.tab.settings")
        }
    }

    var navigationTitle: String {
        title
    }

    var systemImage: String {
        switch self {
        case .overview:
            "sparkles"
        case .catalog:
            "person.3.fill"
        case .cafe:
            "cup.and.saucer.fill"
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
        case .overview:
            BaOverviewView()
        case .catalog:
            BaCatalogView()
        case .cafe:
            BaCafeView()
        case .settings:
            BaSettingsView()
        }
    }
}
