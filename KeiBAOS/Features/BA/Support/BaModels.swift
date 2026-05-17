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
    case settings
    case editOffice
    case debugTools

    var id: Self {
        self
    }

    var title: String {
        BaL10n.string(titleKey)
    }

    var titleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: titleKey)
    }

    private var titleKey: String {
        switch self {
        case .notifications:
            "ba.action.notifications.title"
        case .settings:
            "ba.settings.title"
        case .editOffice:
            "ba.action.edit.title"
        case .debugTools:
            "ba.action.debug.title"
        }
    }

    var menuTitle: String {
        BaL10n.string(menuTitleKey)
    }

    var menuTitleResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: menuTitleKey)
    }

    private var menuTitleKey: String {
        switch self {
        case .notifications, .settings:
            titleKey
        case .editOffice:
            "ba.action.edit.menuTitle"
        case .debugTools:
            "ba.action.debug.menuTitle"
        }
    }

    var systemImage: String {
        switch self {
        case .notifications:
            "bell"
        case .settings:
            "gearshape"
        case .editOffice:
            "square.and.pencil"
        case .debugTools:
            "flask"
        }
    }
}
