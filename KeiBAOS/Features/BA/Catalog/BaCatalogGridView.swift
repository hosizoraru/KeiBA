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
    let onOpenEntry: (BaGuideCatalogEntry) -> Void
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
                    ZStack(alignment: .topTrailing) {
                        Button {
                            onOpenEntry(row.entry)
                        } label: {
                            BaCatalogEntryGridCard(row: row)
                                .equatable()
                        }
                        .buttonStyle(BaPressButtonStyle())

                        BaCatalogGridActionMenu(
                            row: row,
                            favoriteActionTitle: favoriteActionTitle,
                            dutyStudentActionTitle: dutyStudentActionTitle,
                            canSetDutyStudent: canSetDutyStudent,
                            onToggleFavorite: onToggleFavorite,
                            onToggleDutyStudent: onToggleDutyStudent
                        )
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                    }
                    .transition(BaMotion.subtleTransition)
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

private struct BaCatalogGridActionMenu: View {
    let row: BaCatalogEntryRowDisplayModel
    let favoriteActionTitle: (Bool) -> String
    let dutyStudentActionTitle: (Bool) -> String
    let canSetDutyStudent: (BaGuideCatalogEntry) -> Bool
    let onToggleFavorite: (BaGuideCatalogEntry) -> Void
    let onToggleDutyStudent: (BaGuideCatalogEntry) -> Void

    var body: some View {
        Menu {
            if canSetDutyStudent(row.entry) {
                BaMenuActionButton(
                    title: dutyStudentActionTitle(row.isDutyStudent),
                    systemImage: row.isDutyStudent ? "person.crop.circle.badge.xmark" : "person.crop.circle.badge.checkmark"
                ) {
                    onToggleDutyStudent(row.entry)
                }
            }

            BaMenuActionButton(
                title: favoriteActionTitle(row.isFavorite),
                systemImage: row.isFavorite ? "star.slash" : "star"
            ) {
                onToggleFavorite(row.entry)
            }
        } label: {
            BaMenuIconButton(dimension: 36, isActive: row.isFavorite || row.isDutyStudent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BaL10n.string("ba.action.more"))
    }
}

private struct BaCatalogEntryGridCard: View, Equatable {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let row: BaCatalogEntryRowDisplayModel
    private let actionReserveWidth: CGFloat = 38

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
                            .baSymbolBounce(value: row.isFavorite)
                    }

                    if row.isDutyStudent {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BaDesign.blue)
                            .baSymbolBounce(value: row.isDutyStudent)
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
            .padding(.trailing, actionReserveWidth)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, metrics.catalogCardHorizontalPadding)
        .padding(.vertical, metrics.catalogCardVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: metrics.catalogCardMinHeight, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: metrics.catalogCardCornerRadius, style: .continuous))
        .liquidGlassSurface(cornerRadius: metrics.catalogCardCornerRadius, tint: row.tint.opacity(0.035), isInteractive: true)
        .baMotion(BaMotion.quick, value: row.isFavorite)
        .baMotion(BaMotion.quick, value: row.isDutyStudent)
    }
}
