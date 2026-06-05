//
//  BaStudentDetailOverviewView.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentDetailOverviewSections: View {
    let info: BaStudentGuideInfo
    let entry: BaGuideCatalogEntry
    let tint: Color
    private let portraitURL: URL?
    private let combatItems: [BaGuideMetaItem]

    init(info: BaStudentGuideInfo, entry: BaGuideCatalogEntry, tint: Color) {
        self.info = info
        self.entry = entry
        self.tint = tint
        portraitURL = info.preferredPortraitURL(fallback: entry.iconURL)
        combatItems = Self.combatItems(from: info, category: entry.category)
    }

    var body: some View {
        BaStudentPortraitMetaCard(
            info: info,
            category: entry.category,
            portraitURL: portraitURL,
            tint: tint
        )
        .baAdaptiveListCardRow(top: 5, bottom: 4)

        if combatItems.isEmpty == false {
            BaStudentCombatMetaCard(items: combatItems)
                .baAdaptiveListCardRow(top: 4, bottom: 8)
        }
    }

    private static func combatItems(from info: BaStudentGuideInfo, category: BaCatalogCategory) -> [BaGuideMetaItem] {
        let sourceItems = BaStudentGuideMeta.combatMetaItems(from: info)
        let items = category == .npcSatellite
            ? sourceItems.filter(\.hasRenderableMetaContent)
            : sourceItems
        guard let tactical = items.first(where: { $0.isTacticalPositionItem }) else {
            return items
        }
        let tactic = BaGuideMetaItem(
            title: BaL10n.string("ba.student.detail.meta.tactic"),
            value: "",
            imageURL: tactical.imageURL
        )
        let position = BaGuideMetaItem(
            title: BaL10n.string("ba.student.detail.meta.position"),
            value: tactical.extraValue ?? "",
            imageURL: tactical.extraImageURL
        )
        return [tactic, position] + items.filter { $0.isTacticalPositionItem == false }
    }
}

private struct BaStudentPortraitMetaCard: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let info: BaStudentGuideInfo
    let category: BaCatalogCategory
    let portraitURL: URL?
    let tint: Color
    private let profileItems: [BaGuideMetaItem]

    init(info: BaStudentGuideInfo, category: BaCatalogCategory, portraitURL: URL?, tint: Color) {
        self.info = info
        self.category = category
        self.portraitURL = portraitURL
        self.tint = tint
        profileItems = Self.profileItems(from: info, category: category)
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            let size = portraitSize
            HStack(alignment: .top, spacing: 12) {
                BaRemoteImageSurface(
                    url: portraitURL,
                    fallbackSystemImage: "person.crop.square",
                    tint: tint,
                    width: size.width,
                    height: size.height,
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
                .frame(maxWidth: .infinity, minHeight: size.height, alignment: .topLeading)
            }
        }
    }

    private var portraitSize: CGSize {
        metrics.widthClass == .compact
            ? CGSize(width: 96, height: 128)
            : CGSize(width: 108, height: 144)
    }

    private static func profileItems(from info: BaStudentGuideInfo, category: BaCatalogCategory) -> [BaGuideMetaItem] {
        var items = BaStudentGuideMeta.profileMetaItems(from: info, category: category)
        if let tactical = BaStudentGuideMeta.combatMetaItems(from: info).first(where: { $0.isTacticalPositionItem }) {
            items.append(
                BaGuideMetaItem(
                    title: BaL10n.string("ba.student.detail.meta.role"),
                    value: tactical.value,
                    imageURL: nil
                )
            )
        }
        if category == .npcSatellite {
            return items.filter(\.hasRenderableMetaContent)
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
    @Environment(\.baAdaptiveMetrics) private var metrics

    let item: BaGuideMetaItem
    let tint: Color

    var body: some View {
        Group {
            if usesStackedValueLayout {
                stackedLayout
            } else {
                inlineLayout
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineLayout: some View {
        HStack(spacing: 8) {
            metaTitle

            metaImages

            metaValue(lineLimit: 1, alignment: .trailing)
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                metaTitle
                metaImages
                Spacer(minLength: 0)
            }

            metaValue(lineLimit: stackedValueLineLimit, alignment: .leading, textAlignment: .leading)
        }
    }

    private var metaTitle: some View {
        BaStudentMetaTitle(item: item, tint: tint)
            .frame(width: usesStackedValueLayout ? nil : 92, alignment: .leading)
    }

    @ViewBuilder
    private var metaImages: some View {
        if item.isAcademyItem == false {
            BaStudentMetaImages(item: item, tint: tint, size: 16)
        }
    }

    private func metaValue(
        lineLimit: Int?,
        alignment: Alignment,
        textAlignment: TextAlignment = .trailing
    ) -> some View {
        Text(item.value)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.82)
            .multilineTextAlignment(textAlignment)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var usesStackedValueLayout: Bool {
        if item.isAffiliationItem {
            return item.value.count >= 7
        }
        switch metrics.widthClass {
        case .compact:
            return item.value.count >= 9
        case .regular:
            return item.value.count >= 18
        case .expanded:
            return item.value.count >= 28
        }
    }

    private var stackedValueLineLimit: Int? {
        item.isAffiliationItem ? nil : 3
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
        item.title == BaL10n.string("ba.student.detail.meta.tacticalPosition")
    }
}

private struct BaStudentTacticalPositionLines: View {
    let item: BaGuideMetaItem

    var body: some View {
        VStack(spacing: 4) {
            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: BaL10n.string("ba.student.detail.meta.tacticalRole"),
                    value: item.value,
                    imageURL: item.imageURL
                ),
                iconSize: 18
            )

            BaStudentCombatMetaLine(
                item: BaGuideMetaItem(
                    title: BaL10n.string("ba.student.detail.meta.position"),
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
    private let iconURLs: [URL]
    private let iconWidth: CGFloat

    init(item: BaGuideMetaItem, tint: Color, size: CGFloat) {
        self.item = item
        self.tint = tint
        self.size = size
        var urls: [URL] = []
        if let imageURL = item.imageURL {
            urls.append(imageURL)
        }
        if let extraImageURL = item.extraImageURL {
            urls.append(extraImageURL)
        }
        iconURLs = urls
        iconWidth = Self.iconWidth(for: item, iconCount: urls.count, size: size)
    }

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

    private static func iconWidth(for item: BaGuideMetaItem, iconCount: Int, size: CGFloat) -> CGFloat {
        switch iconCount {
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
    var isAffiliationItem: Bool {
        title == BaL10n.string("ba.student.detail.meta.belongs")
    }

    var isAcademyItem: Bool {
        title == BaL10n.string("ba.student.detail.meta.academy")
    }

    var isTacticalPositionItem: Bool {
        title == BaL10n.string("ba.student.detail.meta.tacticalPosition")
    }

    var hasRenderableMetaContent: Bool {
        value.hasMeaningfulMetaValue ||
            extraValue?.hasMeaningfulMetaValue == true ||
            imageURL != nil ||
            extraImageURL != nil
    }
}

private extension String {
    var hasMeaningfulMetaValue: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = normalized
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .lowercased()
        guard normalized.isEmpty == false else { return false }
        return normalized != BaL10n.string("ba.common.none") &&
            normalized != "-" &&
            normalized != "—" &&
            normalized != "--" &&
            normalized != "暂无" &&
            normalized != "无" &&
            compact != "n" &&
            compact != "none" &&
            compact != "null" &&
            compact != "undefined" &&
            compact != "nan"
    }
}
