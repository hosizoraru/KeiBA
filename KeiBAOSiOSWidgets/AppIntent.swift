//
//  AppIntent.swift
//  KeiBAOSiOSWidgets
//
//  Created by Voyager on 2026/05/29.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Dashboard Configuration" }
    static var description: IntentDescription { "Configure your KeiBAOS dashboard widget." }
}
