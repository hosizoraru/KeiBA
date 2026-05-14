//
//  BaStudentDetailView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaStudentDetailView: View {
    @Environment(BaAppModel.self) private var model

    let entry: BaGuideCatalogEntry

    private var state: BaLoadableState<BaStudentGuideInfo> {
        model.studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
    }

    private var info: BaStudentGuideInfo? {
        state.value
    }

    var body: some View {
        List {
            Section {
                detailHeader
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if state.isLoading, info == nil {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                }
            }

            if let error = state.errorMessage, error.isEmpty == false {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } footer: {
                    Text(String(localized: "ba.student.detail.cached.footer"))
                }
            }

            overviewSection
            profileSection
            skillsSection
            voiceSection
            gallerySection
            simulateSection
        }
        .navigationTitle(info?.title ?? entry.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.toggleFavorite(entry)
                } label: {
                    Label(
                        model.isFavorite(entry) ? String(localized: "ba.catalog.favorite.remove") : String(localized: "ba.catalog.favorite.add"),
                        systemImage: model.isFavorite(entry) ? "star.fill" : "star"
                    )
                }
                .labelStyle(.iconOnly)
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .task(id: entry.contentId) {
            await model.loadStudentDetail(entry: entry)
        }
        .refreshable {
            await model.loadStudentDetail(entry: entry, force: true)
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            BaDetailRemoteImage(
                url: info?.imageURL ?? entry.iconURL,
                fallbackSystemImage: entry.category == .studentBgm ? "music.note" : "person.crop.circle",
                tint: headerTint
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(info?.title ?? entry.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(headerSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var overviewSection: some View {
        Section(String(localized: "ba.student.detail.overview.title")) {
            LabeledContent(String(localized: "ba.student.detail.contentId.title")) {
                Text("\(entry.contentId)")
            }

            if let info {
                LabeledContent(String(localized: "ba.student.detail.source.title")) {
                    Text(info.contentSource)
                }
                LabeledContent(String(localized: "ba.student.detail.syncedAt.title")) {
                    Text(BaDisplayFormatters.syncTime(info.syncedAt))
                }
            }

            ForEach((info?.stats ?? []).prefix(4)) { row in
                LabeledContent(row.title) {
                    Text(row.value)
                }
            }
        }
    }

    private var profileSection: some View {
        guideRowSection(section: .profile, rows: info?.profileRows ?? [])
    }

    private var skillsSection: some View {
        guideRowSection(section: .skills, rows: info?.skillRows ?? [])
    }

    private var simulateSection: some View {
        guideRowSection(section: .simulate, rows: info?.simulateRows ?? [])
    }

    private var voiceSection: some View {
        Section(BaStudentDetailSection.voice.title) {
            let rows = info?.voiceRows ?? []
            if rows.isEmpty {
                emptySectionRow(.voice)
            } else {
                ForEach(rows) { row in
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(BaTextToken.rowTitle)
                            if row.subtitle.isEmpty == false {
                                Text(row.subtitle)
                                    .font(BaTextToken.rowCaption)
                                    .foregroundStyle(.secondary)
                            }
                            if row.transcript.isEmpty == false {
                                Text(row.transcript)
                                    .font(BaTextToken.rowCaption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    } icon: {
                        Image(systemName: BaStudentDetailSection.voice.systemImage)
                            .foregroundStyle(BaDesign.cyan)
                    }
                }
            }
        }
    }

    private var gallerySection: some View {
        Section(BaStudentDetailSection.gallery.title) {
            let items = info?.galleryItems ?? []
            if items.isEmpty {
                emptySectionRow(.gallery)
            } else {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        BaRowThumbnail(url: item.imageURL, fallbackSystemImage: "photo", tint: BaDesign.pink)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(BaTextToken.rowTitle)
                            Text(item.detail)
                                .font(BaTextToken.rowCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func guideRowSection(section: BaStudentDetailSection, rows: [BaGuideRow]) -> some View {
        Section(section.title) {
            if rows.isEmpty {
                emptySectionRow(section)
            } else {
                ForEach(rows.prefix(18)) { row in
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(BaTextToken.rowTitle)
                            Text(row.value)
                                .font(BaTextToken.rowCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                    } icon: {
                        Image(systemName: section.systemImage)
                            .foregroundStyle(headerTint)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private func emptySectionRow(_ section: BaStudentDetailSection) -> some View {
        Label {
            Text(String(localized: "ba.student.detail.section.empty"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: section.systemImage)
                .foregroundStyle(.secondary)
        }
    }

    private var headerSummary: String {
        if let summary = info?.summary, summary.isEmpty == false {
            return summary
        }
        if entry.aliasDisplay.isEmpty == false {
            return entry.aliasDisplay
        }
        return String(format: String(localized: "ba.catalog.contentId.format"), entry.contentId)
    }

    private var headerTint: Color {
        switch entry.category {
        case .students:
            BaDesign.blue
        case .npcSatellite:
            BaDesign.violet
        case .studentBgm:
            BaDesign.amber
        case .favorites:
            BaDesign.green
        }
    }
}

#Preview {
    NavigationStack {
        BaStudentDetailView(
            entry: BaGuideCatalogEntry(
                entryId: 1,
                pid: 49443,
                contentId: 609145,
                name: "小玉（野营）",
                alias: "小玉",
                aliasDisplay: "小玉",
                iconURL: nil,
                type: 3,
                order: 0,
                createdAt: nil,
                releaseDate: nil,
                detailURL: URL(string: "https://www.gamekee.com/ba/tj/609145.html"),
                category: .students
            )
        )
    }
    .environment(BaAppModel.live())
}
