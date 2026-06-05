//
//  KeiBAWatchWidgetsBundle.swift
//  KeiBAWatchWidgets
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

@main
struct KeiBAWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BaDashboardResourcesWidget()
        BaDashboardTimelineWidget()
    }
}
