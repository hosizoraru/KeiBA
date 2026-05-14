//
//  BaStudentDetailOverviewView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentDetailOverviewSections: View {
    let info: BaStudentGuideInfo
    let entry: BaGuideCatalogEntry
    let tint: Color

    private var portraitURL: URL? {
        info.preferredPortraitURL(fallback: entry.iconURL)
    }

    var body: some View {
        Section {
            BaStudentPortraitMetaCard(
                info: info,
                portraitURL: portraitURL,
                tint: tint
            )
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowBackground(Color.clear)
        }

        Section {
            BaStudentCombatMetaCard(items: BaStudentGuideMeta.combatMetaItems(from: info))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
        }

    }
}

private struct BaStudentPortraitMetaCard: View {
    let info: BaStudentGuideInfo
    let portraitURL: URL?
    let tint: Color

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            HStack(alignment: .top, spacing: 14) {
                BaRemoteImageSurface(
                    url: portraitURL,
                    fallbackSystemImage: "person.crop.square",
                    tint: tint,
                    width: 112,
                    height: 152,
                    cornerRadius: 20,
                    contentMode: .fit,
                    usesImageBackdrop: true,
                    fallbackFont: .system(size: 42, weight: .semibold)
                )

                VStack(alignment: .leading, spacing: 13) {
                    Text(info.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(BaStudentGuideMeta.profileMetaItems(from: info)) { item in
                            BaStudentMetaLine(item: item, tint: tint)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 152, alignment: .topLeading)
            }
        }
    }
}

private struct BaStudentCombatMetaCard: View {
    let items: [BaGuideMetaItem]

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(spacing: 8) {
                ForEach(items) { item in
                    BaStudentCombatMetaRow(item: item)
                }
            }
        }
    }
}

private struct BaStudentMetaLine: View {
    let item: BaGuideMetaItem
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Text(item.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            BaStudentMetaImages(item: item, tint: tint, size: 22)

            Text(item.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BaStudentCombatMetaRow: View {
    let item: BaGuideMetaItem

    var body: some View {
        HStack(spacing: 10) {
            Text(item.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(item.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)

            Spacer(minLength: 8)

            BaStudentMetaImages(item: item, tint: BaDesign.blue, size: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BaStudentMetaImages: View {
    let item: BaGuideMetaItem
    let tint: Color
    let size: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            if let imageURL = item.imageURL {
                BaRemoteImageSurface(
                    url: imageURL,
                    fallbackSystemImage: "square.grid.2x2",
                    tint: tint,
                    width: size,
                    height: size,
                    cornerRadius: 6,
                    fallbackFont: .caption.weight(.semibold)
                )
            }
            if let extraImageURL = item.extraImageURL {
                BaRemoteImageSurface(
                    url: extraImageURL,
                    fallbackSystemImage: "square.grid.2x2",
                    tint: tint,
                    width: size,
                    height: size,
                    cornerRadius: 6,
                    fallbackFont: .caption.weight(.semibold)
                )
            }
        }
    }
}
