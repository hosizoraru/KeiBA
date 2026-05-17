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
    let dutyStudentActionTitle: (Bool) -> String
    let canSetDutyStudent: (BaGuideCatalogEntry) -> Bool
    let onToggleFavorite: (BaGuideCatalogEntry) -> Void
    let onToggleDutyStudent: (BaGuideCatalogEntry) -> Void

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
                BaL10n.string("ba.catalog.empty.title"),
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
                        if canSetDutyStudent(row.entry) {
                            Button {
                                onToggleDutyStudent(row.entry)
                            } label: {
                                Label(
                                    dutyStudentActionTitle(row.isDutyStudent),
                                    systemImage: row.isDutyStudent ? "person.crop.circle.badge.xmark" : "person.crop.circle.badge.checkmark"
                                )
                            }
                        }

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
            repeating: GridItem(.flexible(minimum: metrics.catalogColumnMinWidth), spacing: metrics.catalogGridSpacing, alignment: .top),
            count: metrics.catalogColumnCount
        )
    }

    private var contentMaxWidth: CGFloat {
        metrics.catalogContentMaxWidth
    }
}

private struct BaCatalogEntryGridCard: View, Equatable {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let row: BaCatalogEntryRowDisplayModel

    static func == (lhs: BaCatalogEntryGridCard, rhs: BaCatalogEntryGridCard) -> Bool {
        lhs.row == rhs.row
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BaRowThumbnail(
                url: row.entry.iconURL,
                fallbackSystemImage: row.entry.category == .studentBgm ? "music.note" : "person.crop.circle",
                tint: row.tint,
                size: metrics.catalogThumbnailSize,
                maxPixelDimension: metrics.catalogThumbnailMaxPixelDimension,
                usesGlassSurface: false
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

                    if row.isDutyStudent {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BaDesign.blue)
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
        .padding(.horizontal, metrics.catalogCardHorizontalPadding)
        .padding(.vertical, metrics.catalogCardVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: metrics.catalogCardMinHeight, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: metrics.catalogCardCornerRadius, style: .continuous))
        .liquidGlassSurface(cornerRadius: metrics.catalogCardCornerRadius, tint: row.tint.opacity(0.035), isInteractive: true)
    }
}
