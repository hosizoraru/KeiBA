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
    @State private var selectedPool: BaPoolEntry?
    @State private var collectionHeight: CGFloat = 1

    init(
        statusFilter: Binding<BaTimelineStatus?> = .constant(nil)
    ) {
        _statusFilter = statusFilter
    }

    private var poolSnapshot: BaPoolListSnapshot {
        let now = Date().baTimelineDisplayDate
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
                    subtitle: pool.alias.isEmpty ? BaL10n.string("ba.pool.linkedStudent.detail") : pool.alias,
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

        BaAdaptiveGeometry { metrics in
            List {
                Section {
                    poolSummary(snapshot: snapshot)
                        .baAdaptiveListCardRow(top: 8, bottom: 8)
                }

                Section {
                    if model.poolState.isLoading, snapshot.rows.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if snapshot.rows.isEmpty {
                        ContentUnavailableView(
                            BaL10n.string("ba.pool.empty.title"),
                            systemImage: "rectangle.stack.badge.person.crop",
                            description: Text(BaL10n.string("ba.pool.empty.detail"))
                        )
                    } else {
                        poolRows(snapshot.rows, metrics: metrics)
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
            .baMotion(BaMotion.standard, value: snapshot.motionKey)
        }
        .task(id: model.settings.server) {
            await model.loadPoolsIfNeeded()
            await model.loadCatalogIfNeeded()
        }
        .refreshable {
            await model.refreshPools(force: true)
        }
        .navigationDestination(item: $selectedPool) { pool in
            poolDestination(for: pool)
        }
    }

    @ViewBuilder
    private func poolRows(_ rows: [BaPoolRowDisplayModel], metrics: BaAdaptiveMetrics) -> some View {
        #if os(iOS)
            if metrics.usesTimelineCollectionLayout {
                BaTimelineCollectionContainer(
                    items: rows,
                    columnCount: metrics.timelineCollectionColumnCount,
                    spacing: metrics.cardSpacing,
                    height: $collectionHeight
                ) { row in
                    poolButton(row: row)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(height: max(collectionHeight, 1))
                .baAdaptiveListCardRow(top: 7, bottom: 7)
            } else {
                poolListRows(rows, metrics: metrics)
            }
        #else
            poolListRows(rows, metrics: metrics)
        #endif
    }

    @ViewBuilder
    private func poolListRows(_ rows: [BaPoolRowDisplayModel], metrics: BaAdaptiveMetrics) -> some View {
        ForEach(rows.baChunked(into: metrics.timelineColumnCount), id: \.baPoolChunkID) { chunk in
            HStack(alignment: .top, spacing: metrics.cardSpacing) {
                ForEach(chunk) { row in
                    poolButton(row: row)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .transition(BaMotion.subtleTransition)
                }
                ForEach(0 ..< max(metrics.timelineColumnCount - chunk.count, 0), id: \.self) { _ in
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
            .baAdaptiveListCardRow(top: 7, bottom: 7)
        }
    }

    private func poolButton(row: BaPoolRowDisplayModel) -> some View {
        Button {
            selectedPool = row.pool
        } label: {
            BaPoolNavigationCard(row: row)
                .equatable()
        }
        .buttonStyle(BaPressButtonStyle(scale: 0.985))
    }

    @ViewBuilder
    private func poolDestination(for pool: BaPoolEntry) -> some View {
        if let entry = model.studentCatalogEntry(for: pool) {
            BaStudentDetailView(entry: entry)
        } else {
            BaPoolSourceDetailView(pool: pool, server: model.settings.server)
        }
    }

    private func poolSummary(snapshot: BaPoolListSnapshot) -> some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: 12) {
                BaSectionHeader(
                    title: BaL10n.string("ba.pool.summary.title"),
                    asset: .weaponStarBadge
                )

                HStack(alignment: .top, spacing: 10) {
                    BaSummaryMetric(
                        title: BaL10n.string("ba.status.running"),
                        value: "\(snapshot.count(for: .running))",
                        tint: BaDesign.green
                    )
                    BaSummaryMetric(
                        title: BaL10n.string("ba.status.upcoming"),
                        value: "\(snapshot.count(for: .upcoming))",
                        tint: BaDesign.blue
                    )
                    BaSummaryMetric(
                        title: BaL10n.string("ba.status.ended"),
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
        statusFilter?.title ?? BaL10n.string("ba.filter.all")
    }

    private var summarySyncText: String {
        guard let lastSyncAt = model.poolState.lastSyncAt else {
            return BaL10n.string("ba.state.notSynced")
        }
        if model.poolState.isShowingCache {
            return String(
                format: BaL10n.string("ba.state.cachedAt.format"),
                BaDisplayFormatters.syncTime(lastSyncAt)
            )
        }
        return String(
            format: BaL10n.string("ba.state.syncedAt.format"),
            BaDisplayFormatters.syncTime(lastSyncAt)
        )
    }

    private var footerText: String {
        if let error = model.poolState.errorMessage, error.isEmpty == false {
            return String(format: BaL10n.string("ba.state.error.format"), error)
        }
        return BaL10n.string("ba.pool.footer.live")
    }
}

private struct BaPoolListSnapshot {
    let rows: [BaPoolRowDisplayModel]
    let counts: [BaTimelineStatus: Int]

    var motionKey: [BaPoolEntry.ID] {
        rows.map(\.id)
    }

    func count(for status: BaTimelineStatus) -> Int {
        counts[status] ?? 0
    }
}

private struct BaPoolRowDisplayModel: Identifiable, Equatable, Hashable {
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
    @Environment(\.baAdaptiveMetrics) private var metrics

    let row: BaPoolRowDisplayModel

    static func == (lhs: BaPoolNavigationCard, rhs: BaPoolNavigationCard) -> Bool {
        lhs.row == rhs.row
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                BaTimelineStatusPill(title: row.status.title, tint: row.status.tint)

                Text(row.tagTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                Text(row.timelineDetail)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(row.status.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .layoutPriority(1)
            }

            HStack(alignment: .top, spacing: 13) {
                BaRemoteImageSurface(
                    url: row.pool.imageURL,
                    fallbackSystemImage: row.fallbackSystemImage,
                    tint: row.status.tint,
                    width: metrics.poolCardThumbnailSize,
                    height: metrics.poolCardThumbnailSize,
                    cornerRadius: metrics.poolCardThumbnailCornerRadius,
                    contentMode: .fill,
                    usesImageBackdrop: false,
                    fallbackFont: .system(size: 30, weight: .semibold),
                    maxPixelDimension: metrics.poolCardThumbnailMaxPixelDimension,
                    usesGlassSurface: false
                )
                .background(
                    row.status.tint.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: metrics.poolCardThumbnailCornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: metrics.poolCardThumbnailCornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(row.pool.name)
                        .font(.headline.weight(.semibold))
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
                .layoutPriority(1)
            }

            BaTimelineDatePair(
                start: row.startText,
                end: row.endText,
                detail: "",
                tint: row.status.tint,
                progress: row.progress
            )
        }
        .padding(.leading, 20)
        .padding(.trailing, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .baTimelineScrollCardSurface(tint: row.status.tint)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(row.status.tint.opacity(0.78))
                .frame(width: 4)
                .padding(.leading, 9)
                .padding(.vertical, 18)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contextMenu {
            Button {
                #if canImport(UIKit)
                    UIPasteboard.general.string = row.pool.name
                #elseif canImport(AppKit)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(row.pool.name, forType: .string)
                #endif
            } label: {
                Label(BaL10n.string("ba.action.copy"), systemImage: "doc.on.doc")
            }
        }
    }
}

private extension Array where Element == BaPoolRowDisplayModel {
    var baPoolChunkID: String {
        map { "\($0.id)" }.joined(separator: "-")
    }
}

private struct BaPoolSourceDetailView: View {
    let pool: BaPoolEntry
    let server: BaServer

    var body: some View {
        BaAdaptiveGeometry { _ in
            List {
                Section {
                    BaDetailRemoteImage(url: pool.imageURL, fallbackSystemImage: "sparkles", tint: pool.status().tint)
                        .baAdaptiveListCardRow(top: 10, bottom: 10)
                }

                Section(BaL10n.string("ba.pool.detail.section.title")) {
                    LabeledContent(BaL10n.string("ba.pool.detail.name.title")) {
                        Text(pool.name)
                    }
                    LabeledContent(BaL10n.string("ba.pool.detail.tag.title")) {
                        Text(BaTimelineLabels.poolTagTitle(tagId: pool.tagId, fallback: pool.tagName))
                    }
                    LabeledContent(BaL10n.string("ba.timeline.start")) {
                        Text(BaDisplayFormatters.dateTime(pool.startAt, server: server))
                    }
                    LabeledContent(BaL10n.string("ba.timeline.end")) {
                        Text(BaDisplayFormatters.dateTime(pool.endAt, server: server))
                    }
                }
            }
            .platformInsetGroupedListStyle()
            .scrollContentBackground(.hidden)
            .background(AppBackground())
        }
        .navigationTitle(pool.name)
    }
}

#Preview {
    NavigationStack {
        BaPoolView()
            .navigationTitle(AppTab.pool.title)
    }
    .environment(BaAppModel.live())
}
