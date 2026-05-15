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
    @State private var selectedSameNameEntry: BaGuideCatalogEntry?
    @State private var selectedGalleryPreview: BaStudentGalleryPreviewItem?

    private var state: BaLoadableState<BaStudentGuideInfo> {
        model.studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
    }

    private var info: BaStudentGuideInfo? {
        state.value
    }

    var body: some View {
        detailList
            .navigationDestination(item: $selectedSameNameEntry) { entry in
                BaStudentDetailView(entry: entry)
            }
            .sheet(item: $selectedGalleryPreview) { item in
                BaStudentGalleryPreviewSheet(item: item)
            }
    }

    private var detailList: some View {
        List {
            BaStudentDetailPageRailSection(selection: $selectedPage, tint: headerTint)

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
        .baStudentDetailSectionSpacing()
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
            BaStudentWeaponCardsSection(info: info, tint: headerTint)
        case .profile:
            if let info {
                BaStudentProfileCardsSection(
                    info: info,
                    tint: headerTint,
                    onOpenSameNameEntry: { selectedSameNameEntry = $0 }
                )
            } else if state.isLoading == false {
                emptyDetailSection
            }
        case .voice:
            BaStudentVoiceSection(
                rows: info?.voiceRows ?? [],
                voiceLanguageHeaders: info?.voiceLanguageHeaders ?? [],
                searchText: $voiceSearchText
            )
        case .gallery:
            BaStudentGalleryCardsSection(info: info) { item in
                selectedGalleryPreview = item
            }
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

private extension View {
    @ViewBuilder
    func baStudentDetailSectionSpacing() -> some View {
        #if os(iOS)
            listSectionSpacing(.compact)
        #else
            self
        #endif
    }
}

private struct BaStudentDetailPageRailSection: View {
    @Binding var selection: BaStudentDetailPage
    let tint: Color

    var body: some View {
        BaStudentDetailPageRail(selection: $selection, tint: tint)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 5, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

private struct BaStudentDetailPageRail: View {
    @Binding var selection: BaStudentDetailPage
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(BaStudentDetailPage.allCases) { page in
                            Button {
                                selection = page
                            } label: {
                                BaStudentDetailPageRailItem(
                                    title: page.title,
                                    isSelected: selection == page,
                                    tint: tint
                                )
                            }
                            .buttonStyle(.plain)
                            .id(page)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear {
                    proxy.scrollTo(selection, anchor: .center)
                }
                .onChange(of: selection) { _, page in
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(page, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct BaStudentDetailPageRailItem: View {
    let title: String
    let isSelected: Bool
    let tint: Color

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .primary : .secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 40)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.clear)
                        .liquidGlassSurface(cornerRadius: 16, tint: tint.opacity(0.10), isInteractive: true)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.05))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(isSelected ? 0.20 : 0.10), lineWidth: 1)
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                name: "日奈(礼服)",
                alias: "日奈",
                aliasDisplay: "日奈",
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
