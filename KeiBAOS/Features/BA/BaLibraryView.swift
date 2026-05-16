//
//  BaLibraryView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaLibraryView: View {
    @Environment(BaAppModel.self) private var model

    @State private var selectedCategory: BaCatalogCategory = .studentBgm
    @State private var searchText = ""

    private var snapshot: BaLibraryViewSnapshot {
        let favoriteIDs = model.settings.favoriteContentIDs
        let rows = model.entries(for: selectedCategory, query: searchText).map { entry in
            BaCatalogEntryRowDisplayModel(entry: entry, isFavorite: favoriteIDs.contains(entry.contentId))
        }
        return BaLibraryViewSnapshot(rows: rows)
    }

    var body: some View {
        let snapshot = snapshot

        BaAdaptiveGeometry { _ in
            List {
                Section {
                    Picker(String(localized: "ba.library.category.picker"), selection: $selectedCategory) {
                        ForEach(BaCatalogCategory.libraryCases) { category in
                            Text(category.title)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                    .baAdaptiveReadableContent()
                }

                Section {
                    libraryContent(snapshot: snapshot)
                } header: {
                    Text(selectedCategory.title)
                } footer: {
                    Text(footerText)
                }

                Section {
                    Toggle(String(localized: "ba.settings.media.images.title"), isOn: globalBoolBinding(\.showPreviewImages))
                    Toggle(String(localized: "ba.settings.media.autoplay.title"), isOn: globalBoolBinding(\.mediaAutoplayEnabled))
                    Toggle(String(localized: "ba.settings.media.download.title"), isOn: globalBoolBinding(\.mediaDownloadEnabled))
                } header: {
                    Text(String(localized: "ba.settings.media.title"))
                } footer: {
                    Text(String(localized: "ba.settings.media.footer"))
                }
            }
            .platformInsetGroupedListStyle()
            .scrollContentBackground(.hidden)
            .background(AppBackground())
        }
        .searchable(text: $searchText, prompt: Text(selectedCategory.searchPrompt))
        .task {
            await model.loadCatalogIfNeeded()
        }
        .refreshable {
            await model.refreshCatalog(force: true)
        }
    }

    @ViewBuilder
    private func libraryContent(snapshot: BaLibraryViewSnapshot) -> some View {
        if model.catalogState.isLoading, snapshot.rows.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
        } else if snapshot.rows.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: selectedCategory == .favorites ? "star" : "music.note",
                description: Text(emptyDetail)
            )
        } else {
            ForEach(snapshot.rows) { row in
                NavigationLink {
                    BaStudentDetailView(entry: row.entry)
                } label: {
                    BaCatalogEntryRow(row: row)
                        .equatable()
                        .baAdaptiveReadableContent()
                }
                .swipeActions(edge: .trailing) {
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
        case .studentBgm:
            String(localized: "ba.catalog.footer.bgm")
        case .favorites:
            String(localized: "ba.catalog.footer.favorites.live")
        case .students, .npcSatellite:
            String(localized: "ba.catalog.placeholder.footer")
        }
    }

    private var emptyDetail: String {
        if selectedCategory == .favorites {
            return String(localized: "ba.catalog.empty.favorites.detail")
        }
        return String(localized: "ba.catalog.empty.detail")
    }

    private func favoriteActionTitle(isFavorite: Bool) -> String {
        isFavorite
            ? String(localized: "ba.catalog.favorite.remove")
            : String(localized: "ba.catalog.favorite.add")
    }

    private func globalBoolBinding(_ keyPath: WritableKeyPath<BaGlobalSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.envelope.globalSettings[keyPath: keyPath] },
            set: { value in
                model.updateGlobalSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

private struct BaLibraryViewSnapshot {
    let rows: [BaCatalogEntryRowDisplayModel]
}

#Preview {
    NavigationStack {
        BaLibraryView()
            .navigationTitle(AppTab.library.title)
    }
    .environment(BaAppModel.live())
}
