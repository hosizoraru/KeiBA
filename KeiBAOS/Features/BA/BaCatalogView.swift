//
//  BaCatalogView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaCatalogView: View {
    @State private var searchText = ""
    private let entries = BaCatalogEntry.preview

    private var filteredEntries: [BaCatalogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return entries }

        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            entry.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredEntries) { entry in
                    NavigationLink {
                        CatalogDetailPlaceholder(entry: entry)
                    } label: {
                        CatalogEntryRow(entry: entry)
                    }
                }
            } header: {
                Text(String(localized: "ba.catalog.title"))
            } footer: {
                Text(String(localized: "ba.catalog.detail"))
            }
        }
        .platformInsetGroupedListStyle()
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .searchable(text: $searchText, prompt: Text(String(localized: "ba.catalog.search.prompt")))
    }
}

private struct CatalogEntryRow: View {
    let entry: BaCatalogEntry

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: entry.systemImage)
                .foregroundStyle(entry.tint)
        }
        .padding(.vertical, 4)
    }
}

private struct CatalogDetailPlaceholder: View {
    let entry: BaCatalogEntry

    var body: some View {
        BaScreenScaffold {
            BaScreenHeader(title: entry.title, detail: entry.detail)
        }
        .navigationTitle(entry.title)
        .platformLargeNavigationTitle()
    }
}

#Preview {
    NavigationStack {
        BaCatalogView()
    }
}
