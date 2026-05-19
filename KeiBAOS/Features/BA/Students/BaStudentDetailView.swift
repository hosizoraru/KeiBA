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
    @State private var selectedGalleryVideoPreview: BaStudentGalleryPreviewItem?

    private var state: BaLoadableState<BaStudentGuideInfo> {
        model.studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
    }

    private var info: BaStudentGuideInfo? {
        state.value
    }

    private var availablePages: [BaStudentDetailPage] {
        BaStudentDetailPageAvailability.pages(category: entry.category, info: info)
    }

    private var activePage: BaStudentDetailPage {
        availablePages.contains(selectedPage) ? selectedPage : availablePages.first ?? .overviewProfile
    }

    var body: some View {
        detailList
            .navigationDestination(item: $selectedSameNameEntry) { entry in
                BaStudentDetailView(entry: entry)
            }
            .sheet(item: $selectedGalleryPreview) { item in
                BaStudentGalleryPreviewSheet(item: item)
            }
            #if os(macOS)
                .sheet(item: $selectedGalleryVideoPreview) { item in
                    BaStudentGalleryVideoPlayerScreen(item: item)
                        .frame(minWidth: 820, minHeight: 560)
                }
            #else
            .fullScreenCover(item: $selectedGalleryVideoPreview) { item in
                BaStudentGalleryVideoPlayerScreen(item: item)
            }
            #endif
    }

    private var detailList: some View {
        BaAdaptiveGeometry { _ in
            List {
                BaStudentDetailPageRailSection(
                    selection: $selectedPage,
                    pages: availablePages,
                    tint: headerTint
                )

                if state.isLoading, info == nil {
                    loadingSection
                }

                if let error = state.errorMessage, error.isEmpty == false {
                    errorSection(error)
                }

                activePageSections
            }
            .platformInsetGroupedListStyle()
            .baStudentDetailSectionSpacing()
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .baMotion(BaMotion.standard, value: activePage)
        }
        .navigationTitle(info?.title ?? entry.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let shareURL = info?.sourceURL ?? entry.detailURL {
                    ShareLink(item: shareURL) {
                        Label(BaL10n.string("ba.action.share"), systemImage: "square.and.arrow.up")
                    }
                    .labelStyle(.iconOnly)
                }

                Button {
                    Task {
                        await model.loadStudentDetail(entry: entry, force: true)
                    }
                } label: {
                    Label(BaL10n.string("ba.action.refresh"), systemImage: "arrow.clockwise")
                }
                .labelStyle(.iconOnly)
                .disabled(state.isLoading)

                Menu {
                    BaMenuActionButton(
                        title: favoriteTitle,
                        systemImage: model.isFavorite(entry) ? "star.slash" : "star"
                    ) {
                        model.toggleFavorite(entry)
                    }

                    if model.canSetDutyStudent(entry) {
                        BaMenuActionButton(
                            title: dutyStudentTitle,
                            systemImage: dutyStudentSystemImage
                        ) {
                            toggleDutyStudent()
                        }
                    }
                } label: {
                    Label(BaL10n.string("ba.action.more"), systemImage: "ellipsis.circle")
                }
                .labelStyle(.iconOnly)
                .menuOrder(.fixed)
            }
        }
        .modifier(BaStudentVoiceSearchModifier(isActive: activePage == .voice, text: $voiceSearchText))
        .task(id: entry.contentId) {
            await model.loadStudentDetail(entry: entry)
        }
        .refreshable {
            await model.loadStudentDetail(entry: entry, force: true)
        }
        .onAppear {
            clampSelectedPage(to: availablePages)
        }
        .onChange(of: availablePages) { _, pages in
            clampSelectedPage(to: pages)
        }
        .onChange(of: selectedPage) { _, page in
            if page != .voice {
                voiceSearchText = ""
            }
        }
    }

    @ViewBuilder
    private var activePageSections: some View {
        switch activePage {
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
                    category: entry.category,
                    tint: headerTint,
                    sameNameEntryResolver: { model.studentCatalogEntry(forSameNameRole: $0) },
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
                openGalleryPreview(item)
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
            Text(BaL10n.string("ba.student.detail.cached.footer"))
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

    private func openGalleryPreview(_ item: BaStudentGalleryPreviewItem) {
        if item.kind == .video {
            selectedGalleryVideoPreview = item
        } else {
            selectedGalleryPreview = item
        }
    }

    private func clampSelectedPage(to pages: [BaStudentDetailPage]) {
        guard pages.contains(selectedPage) == false, let firstPage = pages.first else { return }
        selectedPage = firstPage
    }

    private var favoriteTitle: String {
        model.isFavorite(entry)
            ? BaL10n.string("ba.catalog.favorite.remove")
            : BaL10n.string("ba.catalog.favorite.add")
    }

    private var dutyStudentTitle: String {
        model.isDutyStudent(entry)
            ? BaL10n.string("ba.catalog.dutyStudent.clear")
            : BaL10n.string("ba.catalog.dutyStudent.set")
    }

    private var dutyStudentSystemImage: String {
        model.isDutyStudent(entry)
            ? "person.crop.circle.badge.xmark"
            : "person.crop.circle.badge.checkmark"
    }

    private func toggleDutyStudent() {
        Task {
            await model.toggleDutyStudent(entry)
        }
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
    let pages: [BaStudentDetailPage]
    let tint: Color

    var body: some View {
        BaStudentDetailPageRail(selection: $selection, pages: pages, tint: tint)
            .baAdaptiveListCardRow(top: 10, bottom: 5)
    }
}

private struct BaStudentDetailPageRail: View {
    @Environment(\.baAdaptiveMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selection: BaStudentDetailPage
    let pages: [BaStudentDetailPage]
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            if metrics.usesFullWidthPageRail {
                HStack(spacing: 8) {
                    pageButtons(expandsItems: true)
                }
                .padding(.vertical, 2)
            } else {
                scrollablePageRail
            }
        }
    }

    private var scrollablePageRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    pageButtons(expandsItems: false)
                }
                .padding(.vertical, 2)
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, page in
                withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                    proxy.scrollTo(page, anchor: .center)
                }
            }
        }
    }

    private func pageButtons(expandsItems: Bool) -> some View {
        ForEach(pages) { page in
            Button {
                withAnimation(BaMotion.resolved(BaMotion.standard, reduceMotion: reduceMotion)) {
                    selection = page
                }
            } label: {
                BaStudentDetailPageRailItem(
                    title: page.title,
                    isSelected: selection == page,
                    tint: tint
                )
                .frame(maxWidth: expandsItems ? .infinity : nil)
            }
            .buttonStyle(.plain)
            .id(page)
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
            .baMotion(BaMotion.quick, value: isSelected)
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
                prompt: Text(BaL10n.string("ba.student.detail.voice.search.placeholder"))
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
