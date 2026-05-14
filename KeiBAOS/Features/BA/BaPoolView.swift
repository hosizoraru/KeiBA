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

    private var filteredPools: [BaPoolEntry] {
        let now = Date()
        let source = (model.poolState.value ?? []).filter { pool in
            model.settings.showEndedPools || pool.status(at: now) != .ended
        }
        guard let statusFilter else { return source }
        return source.filter { $0.status(at: now) == statusFilter }
    }

    var body: some View {
        List {
            Section {
                poolSummary
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                if model.poolState.isLoading, filteredPools.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if filteredPools.isEmpty {
                    ContentUnavailableView(
                        String(localized: "ba.pool.empty.title"),
                        systemImage: "rectangle.stack.badge.person.crop",
                        description: Text(String(localized: "ba.pool.empty.detail"))
                    )
                } else {
                    ForEach(filteredPools) { pool in
                        NavigationLink {
                            if let entry = model.linkedCatalogEntry(for: pool) {
                                BaStudentDetailView(entry: entry)
                            } else {
                                BaPoolSourceDetailView(pool: pool, server: model.settings.server)
                            }
                        } label: {
                            BaPoolRow(pool: pool, server: model.settings.server)
                        }
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
        return (model.poolState.value ?? []).filter { $0.status(at: now) == status }.count
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

private struct BaPoolRow: View {
    let pool: BaPoolEntry
    let server: BaServer

    var body: some View {
        let now = Date()
        let status = pool.status(at: now)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                BaRowThumbnail(
                    url: pool.imageURL,
                    fallbackSystemImage: status == .running ? "sparkles" : "calendar",
                    tint: status.tint,
                    size: 52
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(pool.name)
                        .font(BaTextToken.rowTitle)
                        .foregroundStyle(.primary)

                    Text(BaTimelineLabels.poolTagTitle(tagId: pool.tagId, fallback: pool.tagName))
                        .font(BaTextToken.rowSubtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                BaStatusBadge(title: status.title, tint: status.tint)
            }

            BaTimelineDatePair(
                start: BaDisplayFormatters.dateTime(pool.startAt, server: server),
                end: BaDisplayFormatters.dateTime(pool.endAt, server: server),
                detail: BaDisplayFormatters.timelineDetail(start: pool.startAt, end: pool.endAt, now: now),
                tint: status.tint,
                progress: status == .running ? pool.progress(at: now) : nil
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.pool.linkedStudent.title"),
                value: pool.name,
                detail: pool.alias.isEmpty ? String(localized: "ba.pool.linkedStudent.detail") : pool.alias,
                systemImage: "person.crop.circle",
                valueColor: BaDesign.violet
            )
        }
        .padding(.vertical, 6)
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
