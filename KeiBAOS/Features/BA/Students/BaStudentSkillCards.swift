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
        card.description(for: displayLevel).ifBlank(BaL10n.string("ba.common.none"))
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
                                BaMenuActionDispatcher.perform {
                                    selectedLevel = level
                                }
                            } label: {
                                if level == displayLevel {
                                    Label(level, systemImage: "checkmark")
                                } else {
                                    Text(level)
                                }
                            }
                        }
                    } label: {
                        BaMenuPickerLabel(
                            title: displayLevel,
                            tint: tint,
                            minWidth: 44,
                            font: .callout.monospacedDigit().weight(.semibold),
                            iconSystemName: "chevron.down",
                            iconFont: .caption.weight(.bold),
                            usesGlassSurface: true
                        )
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
    let tint: Color
    private let description: String
    private let segments: [BaStudentSkillDescriptionSegment]

    init(description: String, glossaryIcons: [String: URL], descriptionIcons: [URL], tint: Color) {
        self.tint = tint
        self.description = description
        self.segments = BaStudentSkillTextNormalizer.richTextSegments(
            description: description,
            glossaryIcons: glossaryIcons,
            leadingIcons: descriptionIcons
        )
    }

    var body: some View {
        BaStudentSkillInlineTextFlow(segments: segments, tint: tint)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(description))
    }
}

private struct BaStudentSkillInlineTextFlow: View {
    let segments: [BaStudentSkillDescriptionSegment]
    let tint: Color

    private var renderItems: [BaStudentSkillInlineTextItem] {
        Self.renderItems(from: segments)
    }

    var body: some View {
        FlowLayout(spacing: 0, lineSpacing: 5) {
            ForEach(Array(renderItems.enumerated()), id: \.offset) { _, item in
                switch item {
                case let .icon(url):
                    BaRemoteIconSurface(
                        url: url,
                        fallbackSystemImage: "seal",
                        tint: tint,
                        size: 16,
                        fallbackFont: .caption2.weight(.semibold)
                    )
                    .padding(.horizontal, 1.5)
                case let .text(value, highlighted):
                    Text(value)
                        .font(.body)
                        .fontWeight(highlighted ? .semibold : .regular)
                        .foregroundStyle(highlighted ? tint : Color.primary)
                        .lineLimit(1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func renderItems(from segments: [BaStudentSkillDescriptionSegment]) -> [BaStudentSkillInlineTextItem] {
        segments.flatMap { segment in
            switch segment {
            case let .icon(url):
                return [BaStudentSkillInlineTextItem.icon(url)]
            case let .term(value):
                return [BaStudentSkillInlineTextItem.text(value, highlighted: false)]
            case let .highlightedText(value):
                return [BaStudentSkillInlineTextItem.text(value, highlighted: true)]
            case let .text(value):
                return textFragments(value).map { BaStudentSkillInlineTextItem.text($0, highlighted: false) }
            }
        }
    }

    private static func textFragments(_ value: String) -> [String] {
        var fragments: [String] = []
        var latinBuffer = ""

        func flushLatinBuffer() {
            if latinBuffer.isEmpty == false {
                fragments.append(latinBuffer)
                latinBuffer = ""
            }
        }

        for scalar in value.unicodeScalars {
            let character = String(scalar)
            if scalar.isASCIILetterOrDigit || scalar.value == 95 {
                latinBuffer.append(character)
            } else {
                flushLatinBuffer()
                fragments.append(character)
            }
        }
        flushLatinBuffer()
        return fragments.filter { $0.isEmpty == false }
    }
}

private enum BaStudentSkillInlineTextItem: Hashable {
    case text(String, highlighted: Bool)
    case icon(URL)
}

private extension Unicode.Scalar {
    var isASCIILetterOrDigit: Bool {
        (65 ... 90).contains(value) ||
            (97 ... 122).contains(value) ||
            (48 ... 57).contains(value)
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
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
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
        baAdaptiveListCardRow(top: 8, bottom: 10)
    }
}
