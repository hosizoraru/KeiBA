//
//  BaPoolView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaPoolView: View {
    @Binding private var statusFilter: BaTimelineStatus?
    @Binding private var refreshStamp: String

    private let pools = BaPoolEntry.preview

    init(
        statusFilter: Binding<BaTimelineStatus?> = .constant(nil),
        refreshStamp: Binding<String> = .constant(String(localized: "ba.pool.refresh.preview"))
    ) {
        _statusFilter = statusFilter
        _refreshStamp = refreshStamp
    }

    private var filteredPools: [BaPoolEntry] {
        guard let statusFilter else { return pools }
        return pools.filter { $0.status == statusFilter }
    }

    var body: some View {
        List {
            Section {
                poolSummary
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(filteredPools) { pool in
                    NavigationLink {
                        BaStudentDetailView(student: pool.linkedStudent)
                    } label: {
                        BaPoolRow(pool: pool)
                    }
                }
            } header: {
                Text(currentFilterTitle)
            } footer: {
                Text(String(localized: "ba.pool.footer"))
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    private var poolSummary: some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: 14) {
                BaSectionHeader(
                    title: String(localized: "ba.pool.summary.title"),
                    systemImage: "rectangle.stack.badge.person.crop"
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
        pools.filter { $0.status == status }.count
    }
}

private struct BaPoolRow: View {
    let pool: BaPoolEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BaSymbolTile(systemImage: pool.systemImage, tint: pool.status.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pool.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(pool.tag)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                BaStatusBadge(title: pool.status.title, tint: pool.status.tint)
            }

            BaDivider()

            BaMetricRow(
                title: String(localized: "ba.timeline.start"),
                value: pool.startTime,
                systemImage: "calendar.badge.clock"
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.timeline.end"),
                value: pool.endTime,
                detail: pool.remaining,
                systemImage: "calendar.badge.checkmark",
                valueColor: pool.status.tint
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.pool.linkedStudent.title"),
                value: pool.linkedStudent.name,
                detail: pool.linkedStudent.role,
                systemImage: "person.crop.circle",
                valueColor: pool.linkedStudent.tint
            )
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        BaPoolView()
            .navigationTitle(AppTab.pool.title)
    }
}
