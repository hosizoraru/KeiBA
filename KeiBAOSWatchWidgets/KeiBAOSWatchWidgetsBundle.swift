//
//  KeiBAOSWatchWidgetsBundle.swift
//  KeiBAOSWatchWidgets
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

@main
struct KeiBAOSWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BaDashboardResourcesWidget()
        BaDashboardTimelineWidget()
    }
}
