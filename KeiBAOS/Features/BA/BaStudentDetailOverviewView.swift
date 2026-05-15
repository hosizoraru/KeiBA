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
        BaStudentPortraitMetaCard(
            info: info,
            portraitURL: portraitURL,
            tint: tint
        )
        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)

        BaStudentCombatMetaCard(items: combatItems)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private var combatItems: [BaGuideMetaItem] {
        let items = BaStudentGuideMeta.combatMetaItems(from: info)
        guard let tactical = items.first(where: { $0.isTacticalPositionItem }) else {
            return items
        }
        let tactic = BaGuideMetaItem(
            title: String(localized: "ba.student.detail.meta.tactic"),
            value: "",
            imageURL: tactical.imageURL
        )
        let position = BaGuideMetaItem(
            title: String(localized: "ba.student.detail.meta.position"),
            value: tactical.extraValue ?? "",
            imageURL: tactical.extraImageURL
        )
        return [tactic, position] + items.filter { $0.isTacticalPositionItem == false }
    }
}

private struct BaStudentPortraitMetaCard: View {
    let info: BaStudentGuideInfo
    let portraitURL: URL?
    let tint: Color

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            HStack(alignment: .top, spacing: 12) {
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

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(profileItems) { item in
                            BaStudentMetaLine(item: item, tint: tint)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .topLeading)
            }
        }
    }

    private var profileItems: [BaGuideMetaItem] {
        var items = BaStudentGuideMeta.profileMetaItems(from: info)
        if let tactical = BaStudentGuideMeta.combatMetaItems(from: info).first(where: { $0.isTacticalPositionItem }) {
            items.append(
                BaGuideMetaItem(
                    title: String(localized: "ba.student.detail.meta.role"),
                    value: tactical.value,
                    imageURL: nil
                )
            )
        }
        return items
    }
}

private struct BaStudentCombatMetaCard: View {
    let items: [BaGuideMetaItem]

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(spacing: 4) {
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
        HStack(spacing: 8) {
            BaStudentMetaTitle(item: item, tint: tint)
                .frame(width: 92, alignment: .leading)

            if item.isAcademyItem == false {
                BaStudentMetaImages(item: item, tint: tint, size: 16)
            }

            Text(item.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BaStudentMetaTitle: View {
    let item: BaGuideMetaItem
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(item.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            if item.isAcademyItem {
                BaStudentMetaImages(item: item, tint: tint, size: 16)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
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
        .padding(.vertical, 6)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var isTacticalPosition: Bool {
        item.title == String(localized: "ba.student.detail.meta.tacticalPosition")
    }
}

private struct BaStudentTacticalPositionLines: View {
    let item: BaGuideMetaItem

    var body: some View {
        VStack(spacing: 4) {
            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: String(localized: "ba.student.detail.meta.tacticalRole"),
                    value: item.value,
                    imageURL: item.imageURL
                ),
                iconSize: 18
            )

            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: String(localized: "ba.student.detail.meta.position"),
                    value: item.extraValue ?? "",
                    imageURL: item.extraImageURL
                ),
                iconSize: 18
            )
        }
    }
}

private struct BaStudentCombatMetaLine: View {
    let item: BaGuideMetaItem
    var iconSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            Text(item.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if item.value.isEmpty == false {
                Text(item.value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 8)
            }

            BaStudentMetaImages(item: item, tint: BaDesign.blue, size: iconSize)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BaStudentMetaImages: View {
    let item: BaGuideMetaItem
    let tint: Color
    let size: CGFloat

    @ViewBuilder
    var body: some View {
        if iconURLs.isEmpty == false {
            HStack(spacing: 4) {
                ForEach(Array(iconURLs.enumerated()), id: \.offset) { _, imageURL in
                    BaRemoteIconSurface(
                        url: imageURL,
                        fallbackSystemImage: "square.grid.2x2",
                        tint: tint,
                        size: size,
                        width: iconWidth,
                        fallbackFont: .caption.weight(.semibold)
                    )
                }
            }
            .frame(minWidth: iconWidth, alignment: .leading)
        }
    }

    private var iconURLs: [URL] {
        var urls: [URL] = []
        if let imageURL = item.imageURL {
            urls.append(imageURL)
        }
        if let extraImageURL = item.extraImageURL {
            urls.append(extraImageURL)
        }
        return urls
    }

    private var iconWidth: CGFloat {
        switch iconURLs.count {
        case 0:
            return 0
        case 1:
            return item.isAcademyItem ? size * 1.35 : size * 2.8
        default:
            return size * 1.8
        }
    }
}

private extension BaGuideMetaItem {
    var isAcademyItem: Bool {
        title == String(localized: "ba.student.detail.meta.academy")
    }

    var isTacticalPositionItem: Bool {
        title == String(localized: "ba.student.detail.meta.tacticalPosition")
    }
}
