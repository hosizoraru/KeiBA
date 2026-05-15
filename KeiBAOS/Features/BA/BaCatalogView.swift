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
    @State private var searchText = ""

    private var entries: [BaGuideCatalogEntry] {
        model.entries(for: selectedCategory, query: searchText)
    }

    var body: some View {
        List {
            Section {
                Picker(String(localized: "ba.catalog.category.picker"), selection: $selectedCategory) {
                    ForEach(BaCatalogCategory.catalogCases) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }

            Section {
                catalogContent
            } footer: {
                Text(footerText)
            }
        }
        .platformInsetGroupedListStyle()
        .baCatalogSectionSpacing()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .searchable(text: $searchText, prompt: Text(selectedCategory.searchPrompt))
        .task {
            await model.loadCatalogIfNeeded()
        }
        .refreshable {
            await model.refreshCatalog(force: true)
        }
    }

    @ViewBuilder
    private var catalogContent: some View {
        if model.catalogState.isLoading, entries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        } else if entries.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(emptyDetail)
            )
        } else {
            ForEach(entries) { entry in
                NavigationLink {
                    BaStudentDetailView(entry: entry)
                } label: {
                    BaCatalogEntryRow(entry: entry, isFavorite: model.isFavorite(entry))
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        model.toggleFavorite(entry)
                    } label: {
                        Label(favoriteActionTitle(for: entry), systemImage: model.isFavorite(entry) ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
            }
        }
    }

    private var footerText: String {
        if let error = model.catalogState.errorMessage, error.isEmpty == false {
            return String(format: String(localized: "ba.state.error.format"), error)
        }
        if let lastSyncAt = model.catalogState.lastSyncAt {
            let syncText = model.catalogState.isShowingCache
                ? String(format: String(localized: "ba.state.cachedAt.format"), BaDisplayFormatters.syncTime(lastSyncAt))
                : String(format: String(localized: "ba.state.syncedAt.format"), BaDisplayFormatters.syncTime(lastSyncAt))
            return "\(categoryFooter) \(syncText)"
        }
        return categoryFooter
    }

    private var categoryFooter: String {
        switch selectedCategory {
        case .students:
            String(localized: "ba.catalog.footer.students.live")
        case .npcSatellite:
            String(localized: "ba.catalog.footer.npc.live")
        case .studentBgm, .favorites:
            String(localized: "ba.catalog.placeholder.footer")
        }
    }

    private var emptyDetail: String {
        if selectedCategory == .favorites {
            return String(localized: "ba.catalog.empty.favorites.detail")
        }
        return String(localized: "ba.catalog.empty.detail")
    }

    private func favoriteActionTitle(for entry: BaGuideCatalogEntry) -> String {
        model.isFavorite(entry)
            ? String(localized: "ba.catalog.favorite.remove")
            : String(localized: "ba.catalog.favorite.add")
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
