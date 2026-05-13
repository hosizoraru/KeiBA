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
    private let columns = [
        GridItem(.adaptive(minimum: 170), spacing: 12)
    ]

    private var filteredEntries: [BaCatalogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return entries }

        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            entry.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BaScreenIntro(
                    eyebrow: String(localized: "ba.catalog.eyebrow"),
                    title: String(localized: "ba.catalog.title"),
                    detail: String(localized: "ba.catalog.detail"),
                    systemImage: "person.text.rectangle.fill",
                    tint: BaDesign.violet
                )

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        CatalogEntryCard(entry: entry)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 20)
        }
        .background(AppBackground())
        .searchable(text: $searchText, prompt: Text(String(localized: "ba.catalog.search.prompt")))
    }
}

private struct CatalogEntryCard: View {
    let entry: BaCatalogEntry

    var body: some View {
        LiquidGlassSurface(
            cornerRadius: 26,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            tint: entry.tint.opacity(0.11),
            isInteractive: true
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: entry.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(entry.tint)

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(entry.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
        }
    }
}

#Preview {
    NavigationStack {
        BaCatalogView()
    }
}
