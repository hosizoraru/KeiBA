//
//  BaActivityView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaActivityView: View {
    @Binding private var statusFilter: BaTimelineStatus?
    @Binding private var refreshStamp: String

    private let entries = BaActivityEntry.preview

    init(
        statusFilter: Binding<BaTimelineStatus?> = .constant(nil),
        refreshStamp: Binding<String> = .constant(String(localized: "ba.activity.refresh.preview"))
    ) {
        _statusFilter = statusFilter
        _refreshStamp = refreshStamp
    }

    private var filteredEntries: [BaActivityEntry] {
        guard let statusFilter else { return entries }
        return entries.filter { $0.status == statusFilter }
    }

    var body: some View {
        List {
            Section {
                activitySummary
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(filteredEntries) { entry in
                    BaActivityRow(entry: entry)
                }
            } header: {
                Text(currentFilterTitle)
            } footer: {
                Text(String(localized: "ba.activity.footer"))
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    private var activitySummary: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(alignment: .leading, spacing: 14) {
                BaSectionHeader(
                    title: String(localized: "ba.activity.summary.title"),
                    systemImage: "calendar"
                )

                HStack(spacing: 12) {
                    BaSummaryMetric(
                        title: String(localized: "ba.status.running"),
                        value: "\(count(for: .running))",
                        tint: BaDesign.green
                    )
                    BaSummaryMetric(
                        title: String(localized: "ba.status.upcoming"),
                        value: "\(count(for: .upcoming))",
                        tint: BaDesign.blue
                    )
                    BaSummaryMetric(
                        title: String(localized: "ba.status.ended"),
                        value: "\(count(for: .ended))",
                        tint: .secondary
                    )
                }

                Label(refreshStamp, systemImage: "clock.arrow.circlepath")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentFilterTitle: String {
        statusFilter?.title ?? String(localized: "ba.filter.all")
    }

    private func count(for status: BaTimelineStatus) -> Int {
        entries.filter { $0.status == status }.count
    }
}

private struct BaActivityRow: View {
    let entry: BaActivityEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BaSymbolTile(systemImage: entry.systemImage, tint: entry.status.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(entry.kind)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                BaStatusBadge(title: entry.status.title, tint: entry.status.tint)
            }

            BaDivider()

            BaMetricRow(
                title: String(localized: "ba.timeline.start"),
                value: entry.startTime,
                systemImage: "calendar.badge.clock"
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.timeline.end"),
                value: entry.endTime,
                detail: entry.remaining,
                systemImage: "calendar.badge.checkmark",
                valueColor: entry.status.tint
            )
            BaDivider()
            Label(entry.linkLabel, systemImage: "link")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        BaActivityView()
            .navigationTitle(AppTab.activity.title)
    }
}
