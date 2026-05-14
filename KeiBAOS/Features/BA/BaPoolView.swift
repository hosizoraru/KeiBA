//
//  BaPoolView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaPoolView: View {
    @Environment(BaAppModel.self) private var model

    @Binding private var statusFilter: BaTimelineStatus?

    init(
        statusFilter: Binding<BaTimelineStatus?> = .constant(nil)
    ) {
        _statusFilter = statusFilter
    }

    private var poolSnapshot: BaPoolListSnapshot {
        let now = Date().baPoolTimelineDisplayDate
        let settings = model.settings
        var counts: [BaTimelineStatus: Int] = [:]
        var rows: [BaPoolRowDisplayModel] = []

        for pool in model.poolState.value ?? [] {
            let status = pool.status(at: now)
            counts[status, default: 0] += 1

            guard settings.showEndedPools || status != .ended else { continue }
            guard statusFilter == nil || statusFilter == status else { continue }

            rows.append(
                BaPoolRowDisplayModel(
                    pool: pool,
                    status: status,
                    tagTitle: BaTimelineLabels.poolTagTitle(tagId: pool.tagId, fallback: pool.tagName),
                    subtitle: pool.alias.isEmpty ? String(localized: "ba.pool.linkedStudent.detail") : pool.alias,
                    timelineDetail: BaDisplayFormatters.timelineDetail(start: pool.startAt, end: pool.endAt, now: now),
                    startText: BaDisplayFormatters.dateTime(pool.startAt, server: settings.server),
                    endText: BaDisplayFormatters.dateTime(pool.endAt, server: settings.server),
                    progress: status == .running ? pool.progress(at: now) : nil
                )
            )
        }

        return BaPoolListSnapshot(rows: rows, counts: counts)
    }

    var body: some View {
        let snapshot = poolSnapshot

        List {
            Section {
                poolSummary(snapshot: snapshot)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                if model.poolState.isLoading, snapshot.rows.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if snapshot.rows.isEmpty {
                    ContentUnavailableView(
                        String(localized: "ba.pool.empty.title"),
                        systemImage: "rectangle.stack.badge.person.crop",
                        description: Text(String(localized: "ba.pool.empty.detail"))
                    )
                } else {
                    ForEach(snapshot.rows) { row in
                        NavigationLink {
                            if let entry = model.studentCatalogEntry(for: row.pool) {
                                BaStudentDetailView(entry: entry)
                            } else {
                                BaPoolSourceDetailView(pool: row.pool, server: model.settings.server)
                            }
                        } label: {
                            BaPoolNavigationCard(row: row)
                                .equatable()
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
            await model.loadPoolsIfNeeded()
            await model.loadCatalogIfNeeded()
        }
        .refreshable {
            await model.refreshPools(force: true)
        }
    }

    private func poolSummary(snapshot: BaPoolListSnapshot) -> some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: 12) {
                BaSectionHeader(
                    title: String(localized: "ba.pool.summary.title"),
                    asset: .weaponStarBadge
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
        guard let lastSyncAt = model.poolState.lastSyncAt else {
            return String(localized: "ba.state.notSynced")
        }
        if model.poolState.isShowingCache {
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
        if let error = model.poolState.errorMessage, error.isEmpty == false {
            return String(format: String(localized: "ba.state.error.format"), error)
        }
        return String(localized: "ba.pool.footer.live")
    }
}

private struct BaPoolListSnapshot {
    let rows: [BaPoolRowDisplayModel]
    let counts: [BaTimelineStatus: Int]

    func count(for status: BaTimelineStatus) -> Int {
        counts[status] ?? 0
    }
}

private struct BaPoolRowDisplayModel: Identifiable, Equatable {
    let pool: BaPoolEntry
    let status: BaTimelineStatus
    let tagTitle: String
    let subtitle: String
    let timelineDetail: String
    let startText: String
    let endText: String
    let progress: Double?

    var id: BaPoolEntry.ID {
        pool.id
    }

    var fallbackSystemImage: String {
        status == .running ? "sparkles" : "calendar"
    }
}

private struct BaPoolNavigationCard: View, Equatable {
    let row: BaPoolRowDisplayModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(row.status.tint.opacity(0.78))
                .frame(width: 4)
                .padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    BaPoolStatusPill(title: row.status.title, tint: row.status.tint)

                    Spacer(minLength: 8)

                    Text(row.timelineDetail)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(row.status.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                HStack(alignment: .top, spacing: 13) {
                    BaRemoteImageSurface(
                        url: row.pool.imageURL,
                        fallbackSystemImage: row.fallbackSystemImage,
                        tint: row.status.tint,
                        width: 92,
                        height: 118,
                        cornerRadius: 20,
                        contentMode: .fit,
                        fallbackFont: .system(size: 33, weight: .semibold)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.tagTitle)
                            .font(BaTextToken.rowCaption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(row.pool.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(row.subtitle)
                            .font(BaTextToken.rowCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                BaTimelineDatePair(
                    start: row.startText,
                    end: row.endText,
                    detail: "",
                    tint: row.status.tint,
                    progress: row.progress
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baPoolScrollCardSurface(tint: row.status.tint)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private extension View {
    func baPoolScrollCardSurface(tint: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        return background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.fill(tint.opacity(0.045))
            }
            .overlay {
                shape.strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

private extension Date {
    var baPoolTimelineDisplayDate: Date {
        Date(timeIntervalSince1970: floor(timeIntervalSince1970 / 60) * 60)
    }
}

private struct BaPoolStatusPill: View {
    let title: String
    var tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

private struct BaPoolSourceDetailView: View {
    let pool: BaPoolEntry
    let server: BaServer

    var body: some View {
        List {
            Section {
                BaDetailRemoteImage(url: pool.imageURL, fallbackSystemImage: "sparkles", tint: pool.status().tint)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section(String(localized: "ba.pool.detail.section.title")) {
                LabeledContent(String(localized: "ba.pool.detail.name.title")) {
                    Text(pool.name)
                }
                LabeledContent(String(localized: "ba.pool.detail.tag.title")) {
                    Text(BaTimelineLabels.poolTagTitle(tagId: pool.tagId, fallback: pool.tagName))
                }
                LabeledContent(String(localized: "ba.timeline.start")) {
                    Text(BaDisplayFormatters.dateTime(pool.startAt, server: server))
                }
                LabeledContent(String(localized: "ba.timeline.end")) {
                    Text(BaDisplayFormatters.dateTime(pool.endAt, server: server))
                }
            }
        }
        .navigationTitle(pool.name)
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }
}

#Preview {
    NavigationStack {
        BaPoolView()
            .navigationTitle(AppTab.pool.title)
    }
    .environment(BaAppModel.live())
}
