//
//  BaDashboardWidgets.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI
import WidgetKit

struct BaDashboardResourcesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: BaDashboardWidgetKind.resources,
            provider: BaDashboardWidgetProvider()
        ) { entry in
            BaDashboardResourcesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ba.widget.resources.name")
        .description("ba.widget.resources.description")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        #endif
    }
}

struct BaDashboardTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: BaDashboardWidgetKind.timeline,
            provider: BaDashboardWidgetProvider()
        ) { entry in
            BaDashboardTimelineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ba.widget.timeline.name")
        .description("ba.widget.timeline.description")
        #if os(watchOS)
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
