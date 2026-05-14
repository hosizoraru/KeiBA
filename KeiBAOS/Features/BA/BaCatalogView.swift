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
                    ForEach(BaCatalogCategory.allCases) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }

            Section {
                catalogContent
            } header: {
                Text(selectedCategory.title)
            } footer: {
                Text(footerText)
            }
        }
        .platformInsetGroupedListStyle()
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
        case .studentBgm:
            String(localized: "ba.catalog.footer.bgm")
        case .favorites:
            String(localized: "ba.catalog.footer.favorites.live")
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

private struct BaCatalogEntryRow: View {
    let entry: BaGuideCatalogEntry
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BaRowThumbnail(
                url: entry.iconURL,
                fallbackSystemImage: entry.category == .studentBgm ? "music.note" : "person.crop.circle",
                tint: tint
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(BaTextToken.rowTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }
                }

                Text(subtitle)
                    .font(BaTextToken.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(detail)
                    .font(BaTextToken.rowCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if entry.aliasDisplay.isEmpty {
            return String(format: String(localized: "ba.catalog.contentId.format"), entry.contentId)
        }
        return entry.aliasDisplay
    }

    private var detail: String {
        if entry.category == .studentBgm {
            return String(localized: "ba.catalog.bgm.entry.detail")
        }
        if let releaseDate = entry.releaseDate {
            return String(
                format: String(localized: "ba.catalog.releaseDate.format"),
                BaDisplayFormatters.dateTime(releaseDate)
            )
        }
        if let createdAt = entry.createdAt {
            return String(
                format: String(localized: "ba.catalog.createdAt.format"),
                BaDisplayFormatters.dateTime(createdAt)
            )
        }
        return String(format: String(localized: "ba.catalog.contentId.format"), entry.contentId)
    }

    private var tint: Color {
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
        BaCatalogView()
            .navigationTitle(AppTab.catalog.title)
    }
    .environment(BaAppModel.live())
}
