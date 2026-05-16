//
//  BaCatalogEntryRow.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaCatalogEntryRowDisplayModel: Identifiable, Equatable {
    let entry: BaGuideCatalogEntry
    let isFavorite: Bool
    let subtitle: String
    let detail: String

    init(entry: BaGuideCatalogEntry, isFavorite: Bool) {
        self.entry = entry
        self.isFavorite = isFavorite
        subtitle = Self.subtitle(for: entry)
        detail = Self.detail(for: entry)
    }

    var id: BaGuideCatalogEntry.ID {
        entry.id
    }

    var tint: Color {
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

    private static func subtitle(for entry: BaGuideCatalogEntry) -> String {
        if entry.aliasDisplay.isEmpty {
            return String(format: String(localized: "ba.catalog.contentId.format"), entry.contentId)
        }
        return entry.aliasDisplay
    }

    private static func detail(for entry: BaGuideCatalogEntry) -> String {
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
}

struct BaCatalogEntryRow: View, Equatable {
    let row: BaCatalogEntryRowDisplayModel
    var thumbnailMaxPixelDimension = 900
    var usesThumbnailGlassSurface = true

    init(entry: BaGuideCatalogEntry, isFavorite: Bool) {
        row = BaCatalogEntryRowDisplayModel(entry: entry, isFavorite: isFavorite)
    }

    init(
        row: BaCatalogEntryRowDisplayModel,
        thumbnailMaxPixelDimension: Int = 900,
        usesThumbnailGlassSurface: Bool = true
    ) {
        self.row = row
        self.thumbnailMaxPixelDimension = thumbnailMaxPixelDimension
        self.usesThumbnailGlassSurface = usesThumbnailGlassSurface
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BaRowThumbnail(
                url: row.entry.iconURL,
                fallbackSystemImage: row.entry.category == .studentBgm ? "music.note" : "person.crop.circle",
                tint: row.tint,
                maxPixelDimension: thumbnailMaxPixelDimension,
                usesGlassSurface: usesThumbnailGlassSurface
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
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
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
