//
//  BaModels.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

enum BaDesign {
    static let blue = Color.blue
    static let green = Color.green
    static let pink = Color.pink
    static let violet = Color.purple
    static let amber = Color.orange
    static let cyan = Color.cyan
}

enum BaPresentedSheet: String, Identifiable {
    case notifications
    case editOffice
    case debugTools

    var id: Self { self }

    var title: String {
        switch self {
        case .notifications:
            String(localized: "ba.action.notifications.title")
        case .editOffice:
            String(localized: "ba.action.edit.title")
        case .debugTools:
            String(localized: "ba.action.debug.title")
        }
    }

    var menuTitle: String {
        switch self {
        case .notifications:
            title
        case .editOffice:
            String(localized: "ba.action.edit.menuTitle")
        case .debugTools:
            String(localized: "ba.action.debug.menuTitle")
        }
    }

    var systemImage: String {
        switch self {
        case .notifications:
            "bell"
        case .editOffice:
            "square.and.pencil"
        case .debugTools:
            "flask"
        }
    }
}
