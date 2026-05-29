//
//  BaAPStatusWidget.swift
//  KeiBAOSWidget
//
//  Created by Codex on 2026/05/29.
//

import WidgetKit
import SwiftUI

struct BaAPStatusProvider: TimelineProvider {
    func placeholder(in _: Context) -> BaAPStatusEntry {
        BaAPStatusEntry(date: Date(), apCurrent: "240", apLimit: "240", cafeAp: "677", cafeApLimit: "740")
    }

    func getSnapshot(in _: Context, completion: @escaping (BaAPStatusEntry) -> Void) {
        let entry = BaAPStatusEntry(date: Date(), apCurrent: "240", apLimit: "240", cafeAp: "677", cafeApLimit: "740")
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<BaAPStatusEntry>) -> Void) {
        let entry = BaAPStatusEntry(date: Date(), apCurrent: "240", apLimit: "240", cafeAp: "677", cafeApLimit: "740")
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct BaAPStatusEntry: TimelineEntry {
    let date: Date
    let apCurrent: String
    let apLimit: String
    let cafeAp: String
    let cafeApLimit: String
}

struct BaAPStatusWidgetEntryView: View {
    var entry: BaAPStatusProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.green)
                Text("AP")
                    .font(.headline)
                Spacer()
            }
            Text("\(entry.apCurrent) / \(entry.apLimit)")
                .font(.title2.bold())
                .monospacedDigit()
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.green)
                    Text("AP")
                        .font(.headline)
                }
                Text("\(entry.apCurrent) / \(entry.apLimit)")
                    .font(.title.bold())
                    .monospacedDigit()
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(.blue)
                    Text("Café")
                        .font(.headline)
                }
                Text("\(entry.cafeAp) / \(entry.cafeApLimit)")
                    .font(.title.bold())
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding()
    }
}

struct BaAPStatusWidget: Widget {
    let kind: String = "BaAPStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BaAPStatusProvider()) { entry in
            BaAPStatusWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AP Status")
        .description("Shows your current AP and Café AP status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if os(iOS)
    @main
    struct KeiBAOSWidgetBundle: WidgetBundle {
        var body: some Widget {
            BaAPStatusWidget()
        }
    }
#else
    @main
    struct KeiBAOSWidgetBundle: WidgetBundle {
        var body: some Widget {
            BaAPStatusWidget()
        }
    }
#endif
