//
//  AppTab.swift
//  KeiBA
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case overview
    case activity
    case pool
    case catalog
    case library

    var id: Self {
        self
    }

    var titleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: localizationKey)
    }

    var localizationKey: String {
        switch self {
        case .overview:
            "ba.tab.overview"
        case .activity:
            "ba.tab.activity"
        case .pool:
            "ba.tab.pool"
        case .catalog:
            "ba.tab.catalog"
        case .library:
            "ba.tab.library"
        }
    }

    var title: String {
        BaL10n.string(localizationKey)
    }

    var navigationTitle: String {
        title
    }

    var systemImage: String {
        switch self {
        case .overview:
            "sparkles"
        case .activity:
            "calendar"
        case .pool:
            "rectangle.stack"
        case .catalog:
            "person.2"
        case .library:
            "music.note"
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
        case .activity:
            BaActivityView()
        case .pool:
            BaPoolView()
        case .catalog:
            BaCatalogView()
        case .library:
            BaLibraryView()
        }
    }
}
