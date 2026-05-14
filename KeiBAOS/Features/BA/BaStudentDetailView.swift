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

    @State private var selectedPage: BaStudentDetailPage = .overviewProfile
    @State private var voiceSearchText = ""

    private var state: BaLoadableState<BaStudentGuideInfo> {
        model.studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
    }

    private var info: BaStudentGuideInfo? {
        state.value
    }

    var body: some View {
        List {
            BaStudentDetailPagePicker(selection: $selectedPage)

            if state.isLoading, info == nil {
                loadingSection
            }

            if let error = state.errorMessage, error.isEmpty == false {
                errorSection(error)
            }

            activePageSections
        }
        .navigationTitle(info?.title ?? entry.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let shareURL = info?.sourceURL ?? entry.detailURL {
                    ShareLink(item: shareURL) {
                        Label(String(localized: "ba.action.share"), systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.iconOnly)
                }

                Button {
                    Task {
                        await model.loadStudentDetail(entry: entry, force: true)
                    }
                } label: {
                    Label(String(localized: "ba.action.refresh"), systemImage: "arrow.clockwise")
                }
                .labelStyle(.iconOnly)
                .disabled(state.isLoading)

                Button {
                    model.toggleFavorite(entry)
                } label: {
                    Label(
                        favoriteTitle,
                        systemImage: model.isFavorite(entry) ? "star.fill" : "star"
                    )
                }
                .labelStyle(.iconOnly)
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .modifier(BaStudentVoiceSearchModifier(isActive: selectedPage == .voice, text: $voiceSearchText))
        .task(id: entry.contentId) {
            await model.loadStudentDetail(entry: entry)
        }
        .refreshable {
            await model.loadStudentDetail(entry: entry, force: true)
        }
        .onChange(of: selectedPage) { _, page in
            if page != .voice {
                voiceSearchText = ""
            }
        }
    }

    @ViewBuilder
    private var activePageSections: some View {
        switch selectedPage {
        case .overviewProfile:
            if let info {
                BaStudentDetailOverviewSections(info: info, entry: entry, tint: headerTint)
            } else if state.isLoading == false {
                emptyDetailSection
            }
        case .skills:
            BaStudentSkillCardsSection(rows: info?.skillDisplayRows ?? [], tint: headerTint)
            if let growthRows = info?.growthDisplayRows, growthRows.isEmpty == false {
                BaStudentDetailRowsCardsSection(section: .growth, rows: growthRows, tint: BaDesign.green)
            }
        case .voice:
            BaStudentVoiceSection(rows: info?.voiceRows ?? [], searchText: $voiceSearchText)
        case .gallery:
            BaStudentGalleryCardsSection(items: info?.galleryItems ?? [])
        case .simulate:
            BaStudentSimulationCardsSection(rows: simulationRows, tint: BaDesign.violet)
        }
    }

    private var simulationRows: [BaGuideRow] {
        guard let info else { return [] }
        if info.simulateRows.isEmpty == false {
            return info.simulateRows
        }
        return info.growthDisplayRows
    }

    private var loadingSection: some View {
        Section {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        }
    }

    private func errorSection(_ error: String) -> some View {
        Section {
            Label(error, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        } footer: {
            Text(String(localized: "ba.student.detail.cached.footer"))
        }
    }

    private var emptyDetailSection: some View {
        Section {
            BaStudentDetailEmptyRow(section: .profile)
        }
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

    private var favoriteTitle: String {
        model.isFavorite(entry)
            ? String(localized: "ba.catalog.favorite.remove")
            : String(localized: "ba.catalog.favorite.add")
    }
}

private struct BaStudentDetailPagePicker: View {
    @Binding var selection: BaStudentDetailPage

    var body: some View {
        Section {
            Picker(String(localized: "ba.student.detail.page.picker"), selection: $selection) {
                ForEach(BaStudentDetailPage.allCases) { page in
                    Text(page.title)
                        .tag(page)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}

private struct BaStudentVoiceSearchModifier: ViewModifier {
    let isActive: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if isActive {
            content.searchable(
                text: $text,
                prompt: Text(String(localized: "ba.student.detail.voice.search.placeholder"))
            )
        } else {
            content
        }
    }
}

#Preview {
    NavigationStack {
        BaStudentDetailView(
            entry: BaGuideCatalogEntry(
                entryId: 1,
                pid: 49443,
                contentId: 609_145,
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
