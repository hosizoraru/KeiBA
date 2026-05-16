//
//  BaCatalogGridView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

struct BaCatalogGridView: View {
    let rows: [BaCatalogEntryRowDisplayModel]
    let metrics: BaAdaptiveMetrics
    let isLoading: Bool
    let emptyDetail: String
    let footerText: String
    let favoriteActionTitle: (Bool) -> String
    let onToggleFavorite: (BaGuideCatalogEntry) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                catalogContent

                Text(footerText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, metrics.screenHorizontalPadding)
            .padding(.vertical, metrics.screenVerticalPadding)
            .safeAreaPadding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var catalogContent: some View {
        if isLoading, rows.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 44)
                .liquidGlassSurface(cornerRadius: 24, tint: BaDesign.blue.opacity(0.035), isInteractive: false)
        } else if rows.isEmpty {
            ContentUnavailableView(
                String(localized: "ba.catalog.empty.title"),
                systemImage: "magnifyingglass",
                description: Text(emptyDetail)
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 36)
            .liquidGlassSurface(cornerRadius: 24, tint: BaDesign.blue.opacity(0.035), isInteractive: false)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(rows) { row in
                    NavigationLink {
                        BaStudentDetailView(entry: row.entry)
                    } label: {
                        BaCatalogEntryGridCard(row: row)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onToggleFavorite(row.entry)
                        } label: {
                            Label(
                                favoriteActionTitle(row.isFavorite),
                                systemImage: row.isFavorite ? "star.slash" : "star"
                            )
                        }
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 280), spacing: 14, alignment: .top),
            count: columnCount
        )
    }

    private var columnCount: Int {
        if metrics.containerWidth >= 1180 {
            return 3
        }
        return 2
    }

    private var contentMaxWidth: CGFloat {
        columnCount == 3 ? 1180 : 880
    }
}

private struct BaCatalogEntryGridCard: View, Equatable {
    let row: BaCatalogEntryRowDisplayModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BaRowThumbnail(
                url: row.entry.iconURL,
                fallbackSystemImage: row.entry.category == .studentBgm ? "music.note" : "person.crop.circle",
                tint: row.tint,
                size: 54
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(row.entry.name)
                        .font(BaTextToken.rowTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if row.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                    }
                }

                Text(row.subtitle)
                    .font(BaTextToken.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(row.detail)
                    .font(BaTextToken.rowCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .liquidGlassSurface(cornerRadius: 20, tint: row.tint.opacity(0.035), isInteractive: true)
    }
}
