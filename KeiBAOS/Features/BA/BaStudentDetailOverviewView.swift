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
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            BaStudentCombatMetaCard(items: BaStudentGuideMeta.combatMetaItems(from: info))
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                    width: 108,
                    height: 144,
                    cornerRadius: 20,
                    contentMode: .fit,
                    usesImageBackdrop: true,
                    fallbackFont: .system(size: 42, weight: .semibold)
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(info.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(BaStudentGuideMeta.profileMetaItems(from: info)) { item in
                            BaStudentMetaLine(item: item, tint: tint)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .topLeading)
            }
        }
    }
}

private struct BaStudentCombatMetaCard: View {
    let items: [BaGuideMetaItem]

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(spacing: 6) {
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

            BaStudentMetaImages(item: item, tint: tint, size: 18, width: 18)

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
        Group {
            if isTacticalPosition {
                BaStudentTacticalPositionLines(item: item)
            } else {
                BaStudentCombatMetaLine(item: item)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var isTacticalPosition: Bool {
        item.title == String(localized: "ba.student.detail.meta.tacticalPosition")
    }
}

private struct BaStudentTacticalPositionLines: View {
    let item: BaGuideMetaItem

    var body: some View {
        VStack(spacing: 6) {
            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: String(localized: "ba.student.detail.meta.tacticalRole"),
                    value: item.value,
                    imageURL: item.imageURL
                ),
                iconWidth: 34
            )

            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: String(localized: "ba.student.detail.meta.position"),
                    value: item.extraImageURL == nil ? String(localized: "ba.common.none") : "",
                    imageURL: item.extraImageURL
                ),
                iconWidth: 34
            )
        }
    }
}

private struct BaStudentCombatMetaLine: View {
    let item: BaGuideMetaItem
    var iconWidth: CGFloat = 28

    var body: some View {
        HStack(spacing: 9) {
            Text(item.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 82, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if item.value.isEmpty == false {
                Text(item.value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .layoutPriority(1)
            }

            Spacer(minLength: 6)

            BaStudentMetaImages(item: item, tint: BaDesign.blue, size: 22, width: iconWidth)
        }
    }
}

private struct BaStudentMetaImages: View {
    let item: BaGuideMetaItem
    let tint: Color
    let size: CGFloat
    var width: CGFloat? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { _, imageURL in
                BaRemoteImageSurface(
                    url: imageURL,
                    fallbackSystemImage: "square.grid.2x2",
                    tint: tint,
                    width: width ?? size,
                    height: size,
                    cornerRadius: 6,
                    contentMode: .fit,
                    fallbackFont: .caption.weight(.semibold)
                )
            }
        }
    }

    private var imageURLs: [URL] {
        guard let imageURL = item.imageURL else { return [] }
        var urls = Array(repeating: imageURL, count: max(item.imageRepeatCount, 1))
        if let extraImageURL = item.extraImageURL {
            urls.append(extraImageURL)
        }
        return urls
    }
}
