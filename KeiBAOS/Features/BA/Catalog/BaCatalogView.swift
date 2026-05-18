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

    private var snapshot: BaCatalogViewSnapshot {
        let favoriteIDs = model.settings.favoriteContentIDs
        let filterGroups = currentFilterGroups
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
                isDutyStudent: model.isDutyStudent(entry)
            )
        }
        return BaCatalogViewSnapshot(rows: rows)
    }

    var body: some View {
        let snapshot = snapshot

        BaAdaptiveGeometry { metrics in
            catalogLayout(snapshot: snapshot, metrics: metrics)
        }
        .searchable(text: $searchText, prompt: Text(selectedCategory.searchPrompt))
        .searchScopes($selectedCategory, activation: .automatic) {
            ForEach(BaCatalogCategory.catalogCases) { category in
                Text(category.title)
                    .tag(category)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                BaCatalogViewOptionsMenu(
                    selectedCategory: $selectedCategory,
                    sortMode: $sortMode,
                    filterSelection: $filterSelection,
                    filterGroups: currentFilterGroups
                )
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
                NavigationLink {
                    BaStudentDetailView(entry: row.entry)
                } label: {
                    BaCatalogEntryRow(
                        row: row,
                        thumbnailMaxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
                        usesThumbnailGlassSurface: false
                    )
                        .equatable()
                }
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
}

private struct BaCatalogViewSnapshot {
    let rows: [BaCatalogEntryRowDisplayModel]
}

private struct BaCatalogViewOptionsMenu: View {
    @Binding var selectedCategory: BaCatalogCategory
    @Binding var sortMode: BaCatalogSortMode
    @Binding var filterSelection: BaCatalogFilterSelection

    let filterGroups: [BaCatalogFilterGroup]

    var body: some View {
        Menu {
            Section(BaL10n.string("ba.catalog.category.picker")) {
                ForEach(BaCatalogCategory.catalogCases) { category in
                    BaCatalogMenuSelectionButton(
                        title: category.title,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }

            Section(BaL10n.string("ba.catalog.action.sort")) {
                ForEach(BaCatalogSortMode.allCases) { mode in
                    BaCatalogMenuSelectionButton(
                        title: mode.title,
                        isSelected: sortMode == mode
                    ) {
                        sortMode = mode
                    }
                }
            }

            if filterGroups.isEmpty == false {
                Section(BaL10n.string("ba.catalog.action.filter")) {
                    ForEach(filterGroups) { group in
                        Menu(group.title) {
                            ForEach(group.options) { option in
                                BaCatalogMenuSelectionButton(
                                    title: option.title,
                                    isSelected: filterSelection.isSelected(option, in: group)
                                ) {
                                    filterSelection.toggle(option, in: group)
                                }
                            }
                        }
                    }

                    if filterSelection.isEmpty == false {
                        Button(role: .destructive) {
                            filterSelection.clear()
                        } label: {
                            Label(BaL10n.string("ba.catalog.filter.clear"), systemImage: "xmark.circle")
                        }
                    }
                }
            }
        } label: {
            Label(
                BaL10n.string("ba.catalog.action.viewOptions"),
                systemImage: filterSelection.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .labelStyle(.iconOnly)
        .menuOrder(.fixed)
        .accessibilityLabel(Text(BaL10n.string("ba.catalog.action.viewOptions")))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    private var accessibilityValue: String {
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

private struct BaCatalogMenuSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: isSelected ? "checkmark" : "circle")
        }
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
}

#Preview {
    NavigationStack {
        BaCatalogView()
            .navigationTitle(AppTab.catalog.title)
    }
    .environment(BaAppModel.live())
}
