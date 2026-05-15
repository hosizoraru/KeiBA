//
//  BaStudentSkillCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaStudentSkillCardsSection: View {
    let rows: [BaGuideRow]
    let tint: Color
    private let cards: [BaStudentSkillDisplayModel]

    init(rows: [BaGuideRow], tint: Color) {
        self.rows = rows
        self.tint = tint
        self.cards = BaStudentSkillDisplayModel.cards(from: rows)
    }

    var body: some View {
        Section {
            if cards.isEmpty {
                BaStudentDetailEmptyRow(section: .skills)
                    .baStudentDetailListCardRow()
            } else {
                ForEach(cards.prefix(16)) { card in
                    BaStudentSkillCard(card: card, tint: tint)
                        .baStudentDetailListCardRow()
                }
            }
        }
    }
}

private struct BaStudentSkillCard: View {
    let card: BaStudentSkillDisplayModel
    let tint: Color

    @State private var selectedLevel: String

    init(card: BaStudentSkillDisplayModel, tint: Color) {
        self.card = card
        self.tint = tint
        _selectedLevel = State(initialValue: card.defaultLevel)
    }

    private var displayLevel: String {
        card.levelOptions.contains(selectedLevel) ? selectedLevel : card.defaultLevel
    }

    private var cost: String {
        card.cost(for: displayLevel)
    }

    private var description: String {
        card.description(for: displayLevel).ifBlank(String(localized: "ba.common.none"))
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                header
                BaStudentSkillDescriptionView(
                    description: description,
                    glossaryIcons: card.glossaryIcons,
                    descriptionIcons: card.descriptionIcons(for: displayLevel),
                    tint: tint
                )
            }
        }
        .onChange(of: card.id) { _, _ in
            selectedLevel = card.defaultLevel
        }
        .onChange(of: card.defaultLevel) { _, newValue in
            if card.levelOptions.contains(selectedLevel) == false {
                selectedLevel = newValue
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            BaRemoteIconSurface(
                url: card.iconURL,
                fallbackSystemImage: BaStudentDetailSection.skills.systemImage,
                tint: tint,
                size: 42,
                fallbackFont: .title3.weight(.semibold)
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(card.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                BaStudentSkillMetaFlow(
                    type: card.localizedType,
                    stateTags: card.typeStateTags,
                    variantBadge: card.typeVariantBadge,
                    tint: tint
                )
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                if card.levelOptions.isEmpty == false {
                    Menu {
                        ForEach(card.levelOptions, id: \.self) { level in
                            Button {
                                selectedLevel = level
                            } label: {
                                if level == displayLevel {
                                    Label(level, systemImage: "checkmark")
                                } else {
                                    Text(level)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(displayLevel)
                                .font(.callout.monospacedDigit().weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .liquidGlassSurface(cornerRadius: 16, tint: tint.opacity(0.10), isInteractive: true)
                    }
                    .buttonStyle(.plain)
                }

                if cost.isEmpty == false {
                    BaStudentSkillCostPill(cost: cost, tint: tint)
                }
            }
        }
    }
}

private struct BaStudentSkillMetaFlow: View {
    let type: String
    let stateTags: [String]
    let variantBadge: String?
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            if type.isEmpty == false {
                BaStudentSkillPill(title: type, tint: tint, filled: true)
            }
            if let variantBadge {
                BaStudentSkillPill(title: variantBadge, tint: tint)
            }
            ForEach(stateTags.prefix(2), id: \.self) { tag in
                BaStudentSkillPill(title: tag, tint: BaDesign.blue)
            }
        }
        .lineLimit(1)
    }
}

private struct BaStudentSkillPill: View {
    let title: String
    let tint: Color
    var filled = false

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? .white : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(filled ? tint.opacity(0.82) : tint.opacity(0.09), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.22), lineWidth: 1)
            }
    }
}

private struct BaStudentSkillCostPill: View {
    let cost: String
    let tint: Color

    private var displayCost: String {
        if cost.localizedCaseInsensitiveContains("COST") {
            return cost.replacingOccurrences(of: "：", with: ":")
        }
        return "COST:\(cost)"
    }

    var body: some View {
        Text(displayCost)
            .font(.callout.monospacedDigit().weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.09), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 1)
            }
    }
}

struct BaStudentSkillDescriptionView: View {
    let descriptionIcons: [URL]
    let tint: Color
    private let highlightedDescription: AttributedString
    private let matchedGlossary: [(label: String, url: URL)]

    init(description: String, glossaryIcons: [String: URL], descriptionIcons: [URL], tint: Color) {
        self.descriptionIcons = descriptionIcons
        self.tint = tint
        self.highlightedDescription = BaStudentSkillTextNormalizer.highlightedAttributedString(in: description, tint: tint)
        let normalizedDescription = BaStudentSkillTextNormalizer.normalizeGlossaryToken(description)
        self.matchedGlossary = glossaryIcons
            .filter { label, _ in
                description.contains(label) ||
                    normalizedDescription.contains(BaStudentSkillTextNormalizer.normalizeGlossaryToken(label))
            }
            .sorted { lhs, rhs in
                if lhs.key.count == rhs.key.count {
                    return lhs.key < rhs.key
                }
                return lhs.key.count > rhs.key.count
            }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 7) {
                ForEach(Array(descriptionIcons.prefix(6).enumerated()), id: \.offset) { _, url in
                    BaRemoteIconSurface(
                        url: url,
                        fallbackSystemImage: "seal",
                        tint: tint,
                        size: 18,
                        fallbackFont: .caption.weight(.semibold)
                    )
                }

                Text(highlightedDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if matchedGlossary.isEmpty == false {
                SkillGlossaryIconFlow(items: matchedGlossary, tint: tint)
            }
        }
    }
}

private struct SkillGlossaryIconFlow: View {
    let items: [(label: String, url: URL)]
    let tint: Color

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(Array(items.prefix(8).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    BaRemoteIconSurface(
                        url: item.url,
                        fallbackSystemImage: "seal",
                        tint: tint,
                        size: 15,
                        fallbackFont: .caption2.weight(.semibold)
                    )
                    Text(item.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.quaternary.opacity(0.35), in: Capsule())
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? 0, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(in: bounds.width, subviews: subviews).rows
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, rows: [Row]) {
        var rows: [Row] = []
        var current = Row()
        let maxWidth = width > 0 ? width : .greatestFiniteMagnitude

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let itemWidth = min(size.width, maxWidth)
            let item = Item(subview: subview, size: CGSize(width: itemWidth, height: size.height))
            let nextWidth = current.items.isEmpty ? itemWidth : current.width + spacing + itemWidth
            if nextWidth > maxWidth, current.items.isEmpty == false {
                rows.append(current)
                current = Row()
            }
            current.add(item, spacing: spacing)
        }
        if current.items.isEmpty == false {
            rows.append(current)
        }
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height
        } + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        let resolvedWidth = width > 0 ? width : rows.map(\.width).max() ?? 0
        return (CGSize(width: resolvedWidth, height: height), rows)
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

        mutating func add(_ item: Item, spacing: CGFloat) {
            width += items.isEmpty ? item.size.width : spacing + item.size.width
            height = max(height, item.size.height)
            items.append(item)
        }
    }

    private struct Item {
        let subview: LayoutSubview
        let size: CGSize
    }
}


private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

private extension View {
    func baStudentDetailListCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
