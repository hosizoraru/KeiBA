//
//  BaActivityView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaActivityView: View {
    @Environment(BaAppModel.self) private var model

    @Binding private var statusFilter: BaTimelineStatus?

    init(
        statusFilter: Binding<BaTimelineStatus?> = .constant(nil)
    ) {
        _statusFilter = statusFilter
    }

    private var filteredEntries: [BaActivityEntry] {
        let now = Date()
        let source = (model.activityState.value ?? []).filter { entry in
            model.settings.showEndedActivities || entry.status(at: now) != .ended
        }
        guard let statusFilter else { return source }
        return source.filter { $0.status(at: now) == statusFilter }
    }

    var body: some View {
        List {
            Section {
                activitySummary
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                if model.activityState.isLoading, filteredEntries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        String(localized: "ba.activity.empty.title"),
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(String(localized: "ba.activity.empty.detail"))
                    )
                } else {
                    ForEach(filteredEntries) { entry in
                        BaActivityRow(entry: entry, server: model.settings.server)
                    }
                }
            } header: {
                Text(currentFilterTitle)
            } footer: {
                Text(footerText)
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .task(id: model.settings.server) {
            await model.loadActivitiesIfNeeded()
        }
        .refreshable {
            await model.refreshActivities(force: true)
        }
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

                Label(summarySyncText, systemImage: "clock.arrow.circlepath")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentFilterTitle: String {
        statusFilter?.title ?? String(localized: "ba.filter.all")
    }

    private func count(for status: BaTimelineStatus) -> Int {
        let now = Date()
        return (model.activityState.value ?? []).filter { $0.status(at: now) == status }.count
    }

    private var summarySyncText: String {
        guard let lastSyncAt = model.activityState.lastSyncAt else {
            return String(localized: "ba.state.notSynced")
        }
        if model.activityState.isShowingCache {
            return String(
                format: String(localized: "ba.state.cachedAt.format"),
                BaDisplayFormatters.syncTime(lastSyncAt)
            )
        }
        return String(
            format: String(localized: "ba.state.syncedAt.format"),
            BaDisplayFormatters.syncTime(lastSyncAt)
        )
    }

    private var footerText: String {
        if let error = model.activityState.errorMessage, error.isEmpty == false {
            return String(format: String(localized: "ba.state.error.format"), error)
        }
        return String(localized: "ba.activity.footer.live")
    }
}

private struct BaActivityRow: View {
    let entry: BaActivityEntry
    let server: BaServer

    var body: some View {
        let now = Date()
        let status = entry.status(at: now)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                BaRowThumbnail(
                    url: entry.imageURL,
                    fallbackSystemImage: status == .running ? "flag.checkered" : "calendar",
                    tint: status.tint,
                    size: 52
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(BaTextToken.rowTitle)
                        .foregroundStyle(.primary)

                    Text(BaTimelineLabels.calendarKindTitle(kindId: entry.kindId, fallback: entry.kindName))
                        .font(BaTextToken.rowSubtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                BaStatusBadge(title: status.title, tint: status.tint)
            }

            BaTimelineDatePair(
                start: BaDisplayFormatters.dateTime(entry.beginAt, server: server),
                end: BaDisplayFormatters.dateTime(entry.endAt, server: server),
                detail: BaDisplayFormatters.timelineDetail(start: entry.beginAt, end: entry.endAt, now: now),
                tint: status.tint,
                progress: status == .running ? entry.progress(at: now) : nil
            )
            BaDivider()
            Label(entry.linkURL?.host ?? String(localized: "ba.activity.link.gamekee"), systemImage: "link")
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
    .environment(BaAppModel.live())
}
