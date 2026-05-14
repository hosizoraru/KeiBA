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
                    asset: .weaponStarBadge
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BaRemoteImageSurface(
                    url: pool.imageURL,
                    fallbackSystemImage: status == .running ? "sparkles" : "calendar",
                    tint: status.tint,
                    width: 96,
                    height: 128,
                    cornerRadius: 18,
                    contentMode: .fit,
                    fallbackFont: .system(size: 34, weight: .semibold)
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        BaStatusBadge(title: status.title, tint: status.tint)
                        Spacer(minLength: 8)
                    }

                    Text(BaTimelineLabels.poolTagTitle(tagId: pool.tagId, fallback: pool.tagName))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(pool.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(pool.alias.isEmpty ? String(localized: "ba.pool.linkedStudent.detail") : pool.alias)
                        .font(BaTextToken.rowCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    VStack(alignment: .leading, spacing: 3) {
                        Label(
                            BaDisplayFormatters.dateTime(pool.startAt, server: server),
                            systemImage: "calendar.badge.clock"
                        )
                        Label(
                            BaDisplayFormatters.dateTime(pool.endAt, server: server),
                            systemImage: "calendar.badge.checkmark"
                        )
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)

                    Text(BaDisplayFormatters.timelineDetail(start: pool.startAt, end: pool.endAt, now: now))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(status.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }

            ProgressView(value: pool.progress(at: now))
                .tint(status.tint)
                .controlSize(.small)
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
