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

    private var activitySnapshot: BaActivityListSnapshot {
        let now = Date().baTimelineDisplayDate
        let settings = model.settings
        var counts: [BaTimelineStatus: Int] = [:]
        var rows: [BaActivityRowDisplayModel] = []

        for entry in model.activityState.value ?? [] {
            let status = entry.status(at: now)
            counts[status, default: 0] += 1

            guard settings.showEndedActivities || status != .ended else { continue }
            guard statusFilter == nil || statusFilter == status else { continue }

            rows.append(
                BaActivityRowDisplayModel(
                    entry: entry,
                    status: status,
                    kindTitle: BaTimelineLabels.calendarKindTitle(kindId: entry.kindId, fallback: entry.kindName),
                    timelineDetail: BaDisplayFormatters.timelineDetail(start: entry.beginAt, end: entry.endAt, now: now),
                    startText: BaDisplayFormatters.dateTime(entry.beginAt, server: settings.server),
                    endText: BaDisplayFormatters.dateTime(entry.endAt, server: settings.server),
                    progress: status == .running ? entry.progress(at: now) : nil
                )
            )
        }

        return BaActivityListSnapshot(rows: rows, counts: counts)
    }

    var body: some View {
        let snapshot = activitySnapshot

        BaAdaptiveGeometry { metrics in
            List {
                Section {
                    activitySummary(snapshot: snapshot)
                        .baAdaptiveListCardRow(top: 8, bottom: 8)
                }

                Section {
                    if model.activityState.isLoading, snapshot.rows.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if snapshot.rows.isEmpty {
                        ContentUnavailableView(
                            String(localized: "ba.activity.empty.title"),
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text(String(localized: "ba.activity.empty.detail"))
                        )
                    } else {
                        activityRows(snapshot.rows, metrics: metrics)
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
        }
        .task(id: model.settings.server) {
            await model.loadActivitiesIfNeeded()
        }
        .refreshable {
            await model.refreshActivities(force: true)
        }
    }

    private func activityRows(_ rows: [BaActivityRowDisplayModel], metrics: BaAdaptiveMetrics) -> some View {
        ForEach(rows.baChunked(into: metrics.timelineColumnCount), id: \.baActivityChunkID) { chunk in
            HStack(alignment: .top, spacing: metrics.cardSpacing) {
                ForEach(chunk) { row in
                    BaActivityCard(row: row)
                        .equatable()
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                ForEach(0 ..< max(metrics.timelineColumnCount - chunk.count, 0), id: \.self) { _ in
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
            .baAdaptiveListCardRow(top: 7, bottom: 7)
        }
    }

    private func activitySummary(snapshot: BaActivityListSnapshot) -> some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(alignment: .leading, spacing: 12) {
                BaSectionHeader(
                    title: String(localized: "ba.activity.summary.title"),
                    asset: .guideMission
                )

                HStack(alignment: .top, spacing: 10) {
                    BaSummaryMetric(
                        title: String(localized: "ba.status.running"),
                        value: "\(snapshot.count(for: .running))",
                        tint: BaDesign.green
                    )
                    BaSummaryMetric(
                        title: String(localized: "ba.status.upcoming"),
                        value: "\(snapshot.count(for: .upcoming))",
                        tint: BaDesign.blue
                    )
                    BaSummaryMetric(
                        title: String(localized: "ba.status.ended"),
                        value: "\(snapshot.count(for: .ended))",
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

private struct BaActivityListSnapshot {
    let rows: [BaActivityRowDisplayModel]
    let counts: [BaTimelineStatus: Int]

    func count(for status: BaTimelineStatus) -> Int {
        counts[status] ?? 0
    }
}

private struct BaActivityRowDisplayModel: Identifiable, Equatable {
    let entry: BaActivityEntry
    let status: BaTimelineStatus
    let kindTitle: String
    let timelineDetail: String
    let startText: String
    let endText: String
    let progress: Double?

    var id: BaActivityEntry.ID {
        entry.id
    }

    var fallbackSystemImage: String {
        status == .running ? "flag.checkered" : "calendar"
    }
}

private struct BaActivityCard: View, Equatable {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let row: BaActivityRowDisplayModel

    static func == (lhs: BaActivityCard, rhs: BaActivityCard) -> Bool {
        lhs.row == rhs.row
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(row.status.tint.opacity(0.78))
                .frame(width: 4)
                .padding(.vertical, 7)

            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    BaTimelineStatusPill(title: row.status.title, tint: row.status.tint)

                    Spacer(minLength: 8)

                    Text(row.timelineDetail)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(row.status.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.kindTitle)
                        .font(BaTextToken.rowCaption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(row.entry.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BaRemoteImageSurface(
                    url: row.entry.imageURL,
                    fallbackSystemImage: row.fallbackSystemImage,
                    tint: row.status.tint,
                    width: nil,
                    height: metrics.timelineCardImageHeight,
                    cornerRadius: 18,
                    contentMode: .fit,
                    usesImageBackdrop: metrics.usesTimelineImageBackdrop,
                    fallbackFont: .system(size: 40, weight: .semibold),
                    maxPixelDimension: metrics.timelineImageMaxPixelDimension
                )

                BaTimelineDatePair(
                    start: row.startText,
                    end: row.endText,
                    detail: "",
                    tint: row.status.tint,
                    progress: row.progress
                )
            }
        }
        .padding(.horizontal, metrics.timelineCardHorizontalPadding)
        .padding(.vertical, metrics.timelineCardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baTimelineScrollCardSurface(tint: row.status.tint)
    }
}

private extension Array where Element == BaActivityRowDisplayModel {
    var baActivityChunkID: String {
        map { "\($0.id)" }.joined(separator: "-")
    }
}

#Preview {
    NavigationStack {
        BaActivityView()
            .navigationTitle(AppTab.activity.title)
    }
    .environment(BaAppModel.live())
}
