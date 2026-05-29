//
//  BaAPActivity.swift
//  KeiBAOSWidget
//
//  Created by Codex on 2026/05/29.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BaAPActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var apCurrent: String
        var apLimit: String
        var nextRecovery: String
    }

    var apLimit: String
}

struct BaAPActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BaAPActivityAttributes.self) { context in
            // Lock Screen / Dynamic Island compact
            BaAPActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.apCurrent)
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.apCurrent) / \(context.attributes.apLimit) AP")
                        .font(.subheadline.monospacedDigit())
                    if !context.state.nextRecovery.isEmpty {
                        Text("Next: \(context.state.nextRecovery)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct BaAPActivityLockScreenView: View {
    let context: ActivityViewContext<BaAPActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("AP Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(context.state.apCurrent) / \(context.attributes.apLimit)")
                    .font(.body.bold().monospacedDigit())
            }

            Spacer()

            if !context.state.nextRecovery.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next Recovery")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(context.state.nextRecovery)
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
