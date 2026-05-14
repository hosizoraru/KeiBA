//
//  BaCatalogEntryRow.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaCatalogEntryRow: View {
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
