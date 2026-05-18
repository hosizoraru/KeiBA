//
//  BaCatalogView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaCatalogView: View {
    @Environment(BaAppModel.self) private var model

    @State private var selectedCategory: BaCatalogCategory = .students
    @State private var sortMode: BaCatalogSortMode = .defaultOrder
    @State private var filterSelection = BaCatalogFilterSelection()
    @State private var searchText = ""
    @State private var isOptionsPanelPresented = false
    @State private var selectedDetailEntry: BaGuideCatalogEntry?

    private func snapshot(filterGroups: [BaCatalogFilterGroup]) -> BaCatalogViewSnapshot {
        let favoriteIDs = model.settings.favoriteContentIDs
        let dutyIdentityKeys = model.currentDutyStudentIdentityKeys()
        let rows = model.entries(
            for: selectedCategory,
            query: searchText,
            sortMode: sortMode,
            filterSelection: filterGroups.isEmpty ? .empty : filterSelection,
            filterGroups: filterGroups
        ).map { entry in
            BaCatalogEntryRowDisplayModel(
                entry: entry,
                isFavorite: favoriteIDs.contains(entry.contentId),
                isDutyStudent: entry.identityKeys.isDisjoint(with: dutyIdentityKeys) == false
            )
        }
        return BaCatalogViewSnapshot(rows: rows)
    }

    var body: some View {
        let filterGroups = currentFilterGroups
        let snapshot = snapshot(filterGroups: filterGroups)

        BaAdaptiveGeometry { metrics in
            catalogLayout(snapshot: snapshot, metrics: metrics)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        BaCatalogViewOptionsControl(
                            selectedCategory: $selectedCategory,
                            sortMode: $sortMode,
                            filterSelection: $filterSelection,
                            isPanelPresented: $isOptionsPanelPresented,
                            filterGroups: filterGroups,
                            usesSheetPresentation: usesOptionsSheet(for: metrics)
                        )
                    }
                }
        }
        .searchable(text: $searchText, prompt: Text(selectedCategory.searchPrompt))
        .searchScopes($selectedCategory, activation: .automatic) {
            ForEach(BaCatalogCategory.catalogCases) { category in
                Text(category.title)
                    .tag(category)
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            filterSelection.clear()
        }
        .task {
            await model.loadCatalogIfNeeded()
        }
        .refreshable {
            await model.refreshCatalog(force: true)
        }
        .navigationDestination(item: $selectedDetailEntry) { entry in
            BaStudentDetailView(entry: entry)
        }
    }

    @ViewBuilder
    private func catalogLayout(snapshot: BaCatalogViewSnapshot, metrics: BaAdaptiveMetrics) -> some View {
        switch metrics.widthClass {
        case .compact:
            compactCatalogList(snapshot: snapshot, metrics: metrics)
        case .regular, .expanded:
            BaCatalogGridView(
                rows: snapshot.rows,
                metrics: metrics,
                isLoading: model.catalogState.isLoading,
                emptyDetail: emptyDetail,
                footerText: footerText,
                favoriteActionTitle: favoriteActionTitle(isFavorite:),
                dutyStudentActionTitle: dutyStudentActionTitle(isDutyStudent:),
                canSetDutyStudent: model.canSetDutyStudent,
                onOpenEntry: openDetail,
                onToggleFavorite: { model.toggleFavorite($0) },
                onToggleDutyStudent: toggleDutyStudent
            )
            .background(AppBackground())
        }
    }

    private func compactCatalogList(snapshot: BaCatalogViewSnapshot, metrics: BaAdaptiveMetrics) -> some View {
        List {
            Section {
                compactCatalogContent(snapshot: snapshot, metrics: metrics)
            } footer: {
                Text(footerText)
            }
        }
        .platformInsetGroupedListStyle()
        .baCatalogSectionSpacing()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    @ViewBuilder
    private func compactCatalogContent(snapshot: BaCatalogViewSnapshot, metrics: BaAdaptiveMetrics) -> some View {
        if model.catalogState.isLoading, snapshot.rows.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        } else if snapshot.rows.isEmpty {
            ContentUnavailableView(
                BaL10n.string("ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(emptyDetail)
            )
        } else {
            ForEach(snapshot.rows) { row in
                Button {
                    openDetail(row.entry)
                } label: {
                    BaCatalogEntryRow(
                        row: row,
                        thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
                        usesThumbnailGlassSurface: false
                    )
                    .equatable()
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if model.canSetDutyStudent(row.entry) {
                        Button {
                            toggleDutyStudent(row.entry)
                        } label: {
                            Label(
                                dutyStudentActionTitle(isDutyStudent: row.isDutyStudent),
                                systemImage: row.isDutyStudent ? "person.crop.circle.badge.xmark" : "person.crop.circle.badge.checkmark"
                            )
                        }
                        .tint(.blue)
                    }

                    Button {
                        model.toggleFavorite(row.entry)
                    } label: {
                        Label(favoriteActionTitle(isFavorite: row.isFavorite), systemImage: row.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
            }
        }
    }

    private var footerText: String {
        if let error = model.catalogState.errorMessage, error.isEmpty == false {
            return String(format: BaL10n.string("ba.state.error.format"), error)
        }
        if let lastSyncAt = model.catalogState.lastSyncAt {
            let syncText = model.catalogState.isShowingCache
                ? String(format: BaL10n.string("ba.state.cachedAt.format"), BaDisplayFormatters.syncTime(lastSyncAt))
                : String(format: BaL10n.string("ba.state.syncedAt.format"), BaDisplayFormatters.syncTime(lastSyncAt))
            return "\(categoryFooter) \(syncText)"
        }
        return categoryFooter
    }

    private var categoryFooter: String {
        switch selectedCategory {
        case .students:
            BaL10n.string("ba.catalog.footer.students.live")
        case .npcSatellite:
            BaL10n.string("ba.catalog.footer.npc.live")
        case .studentBgm, .favorites:
            BaL10n.string("ba.catalog.placeholder.footer")
        }
    }

    private var currentFilterGroups: [BaCatalogFilterGroup] {
        model.catalogState.value?.filterGroups(for: selectedCategory) ?? []
    }

    private var emptyDetail: String {
        if selectedCategory == .favorites {
            return BaL10n.string("ba.catalog.empty.favorites.detail")
        }
        return BaL10n.string("ba.catalog.empty.detail")
    }

    private func favoriteActionTitle(isFavorite: Bool) -> String {
        isFavorite
            ? BaL10n.string("ba.catalog.favorite.remove")
            : BaL10n.string("ba.catalog.favorite.add")
    }

    private func dutyStudentActionTitle(isDutyStudent: Bool) -> String {
        isDutyStudent
            ? BaL10n.string("ba.catalog.dutyStudent.clear")
            : BaL10n.string("ba.catalog.dutyStudent.set")
    }

    private func toggleDutyStudent(_ entry: BaGuideCatalogEntry) {
        Task {
            await model.toggleDutyStudent(entry)
        }
    }

    private func openDetail(_ entry: BaGuideCatalogEntry) {
        selectedDetailEntry = entry
    }

    private func usesOptionsSheet(for metrics: BaAdaptiveMetrics) -> Bool {
        #if os(iOS)
            metrics.containerWidth < 860
        #else
            false
        #endif
    }
}

private struct BaCatalogViewSnapshot {
    let rows: [BaCatalogEntryRowDisplayModel]
}

private struct BaCatalogViewOptionsControl: View {
    @Binding var selectedCategory: BaCatalogCategory
    @Binding var sortMode: BaCatalogSortMode
    @Binding var filterSelection: BaCatalogFilterSelection
    @Binding var isPanelPresented: Bool

    let filterGroups: [BaCatalogFilterGroup]
    let usesSheetPresentation: Bool

    var body: some View {
        panelButton
    }

    @ViewBuilder
    private var panelButton: some View {
        #if os(macOS)
            panelButtonBase
                .popover(isPresented: $isPanelPresented, arrowEdge: .top) {
                    popoverPanel
                }
        #else
            if usesSheetPresentation {
                panelButtonBase
                    .sheet(isPresented: $isPanelPresented) {
                        sheetPanel
                    }
            } else {
                panelButtonBase
                    .popover(isPresented: $isPanelPresented, arrowEdge: .top) {
                        popoverPanel
                    }
            }
        #endif
    }

    @ViewBuilder
    private var sheetPanel: some View {
        #if os(iOS)
            optionsPanel
                .baCatalogOptionsPanelLayout()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        #else
            optionsPanel
                .baCatalogOptionsPanelLayout()
        #endif
    }

    private var popoverPanel: some View {
        optionsPanel
            .baCatalogOptionsPopoverLayout()
    }

    private var optionsPanel: some View {
        BaCatalogViewOptionsPanel(
            selectedCategory: $selectedCategory,
            sortMode: $sortMode,
            filterSelection: $filterSelection,
            filterGroups: filterGroups
        )
    }

    private var panelButtonBase: some View {
        Button {
            isPanelPresented = true
        } label: {
            viewOptionsLabel
        }
        .accessibilityLabel(Text(BaL10n.string("ba.catalog.action.viewOptions")))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    private var viewOptionsLabel: some View {
        Label(
            BaL10n.string("ba.catalog.action.viewOptions"),
            systemImage: filterSelection.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
        )
    }

    private var accessibilityValue: String {
        BaCatalogViewOptionsSummary.accessibilityValue(
            selectedCategory: selectedCategory,
            sortMode: sortMode,
            filterSelection: filterSelection
        )
    }
}

private struct BaCatalogViewOptionsPanel: View {
    @Binding var selectedCategory: BaCatalogCategory
    @Binding var sortMode: BaCatalogSortMode
    @Binding var filterSelection: BaCatalogFilterSelection

    let filterGroups: [BaCatalogFilterGroup]

    var body: some View {
        Form {
            Section(BaL10n.string("ba.catalog.category.picker")) {
                Picker(BaL10n.string("ba.catalog.category.picker"), selection: $selectedCategory) {
                    ForEach(BaCatalogCategory.catalogCases) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
            }

            Section(BaL10n.string("ba.catalog.action.sort")) {
                Picker(BaL10n.string("ba.catalog.action.sort"), selection: $sortMode) {
                    ForEach(BaCatalogSortMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.inline)
            }

            if filterGroups.isEmpty == false {
                Section(BaL10n.string("ba.catalog.action.filter")) {
                    Button {
                        filterSelection.clear()
                    } label: {
                        Label(BaL10n.string("ba.catalog.filter.clear"), systemImage: "xmark.circle")
                    }
                    .disabled(filterSelection.isEmpty)

                    ForEach(filterGroups) { group in
                        DisclosureGroup {
                            ForEach(group.options) { option in
                                Toggle(
                                    option.title,
                                    isOn: filterBinding(for: option, in: group)
                                )
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.title)

                                Text(selectedFilterText(for: group) ?? BaL10n.string("ba.catalog.filter.notSelected"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .accessibilityLabel(Text(BaL10n.string("ba.catalog.action.viewOptions")))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    private func filterBinding(for option: BaCatalogFilterOption, in group: BaCatalogFilterGroup) -> Binding<Bool> {
        Binding(
            get: {
                filterSelection.isSelected(option, in: group)
            },
            set: { isOn in
                let isSelected = filterSelection.isSelected(option, in: group)
                if isOn != isSelected {
                    filterSelection.toggle(option, in: group)
                }
            }
        )
    }

    private var accessibilityValue: String {
        BaCatalogViewOptionsSummary.accessibilityValue(
            selectedCategory: selectedCategory,
            sortMode: sortMode,
            filterSelection: filterSelection
        )
    }

    private func selectedFilterText(for group: BaCatalogFilterGroup) -> String? {
        let selectedOptions = filterSelection.selectedOptions(in: group)
        guard selectedOptions.isEmpty == false else { return nil }
        return selectedOptions.map(\.title).joined(separator: " / ")
    }
}

private enum BaCatalogViewOptionsSummary {
    static func accessibilityValue(
        selectedCategory: BaCatalogCategory,
        sortMode: BaCatalogSortMode,
        filterSelection: BaCatalogFilterSelection
    ) -> String {
        guard filterSelection.isEmpty == false else {
            return "\(selectedCategory.title), \(sortMode.title)"
        }
        let filterText = String(
            format: BaL10n.string("ba.catalog.filter.active.count.format"),
            Int64(filterSelection.activeFilterCount)
        )
        return "\(selectedCategory.title), \(sortMode.title), \(filterText)"
    }
}

private extension View {
    @ViewBuilder
    func baCatalogSectionSpacing() -> some View {
        #if os(iOS)
            listSectionSpacing(.compact)
        #else
            self
        #endif
    }

    func baCatalogOptionsPanelLayout() -> some View {
        frame(minWidth: 320, idealWidth: 380, maxWidth: 460)
            .frame(minHeight: 360, idealHeight: 560, maxHeight: 680)
    }

    func baCatalogOptionsPopoverLayout() -> some View {
        baCatalogOptionsPanelLayout()
            .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    NavigationStack {
        BaCatalogView()
            .navigationTitle(AppTab.catalog.title)
    }
    .environment(BaAppModel.live())
}
