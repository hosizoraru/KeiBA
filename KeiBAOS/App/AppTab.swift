//
//  AppTab.swift
//  KeiBAOS
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

    var title: String {
        switch self {
        case .overview:
            String(localized: "ba.tab.overview")
        case .activity:
            String(localized: "ba.tab.activity")
        case .pool:
            String(localized: "ba.tab.pool")
        case .catalog:
            String(localized: "ba.tab.catalog")
        case .library:
            String(localized: "ba.tab.library")
        }
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
            "rectangle.stack.badge.person.crop"
        case .catalog:
            "person.3.fill"
        case .library:
            "music.note.list"
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
