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
        BaSelectableRichTextView(
            segments: segments.map(\.baRichTextSegment),
            plainText: description,
            tint: tint,
            lineSpacing: 5
        )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(description))
    }
}

private extension BaStudentSkillDescriptionSegment {
    var baRichTextSegment: BaRichTextSegment {
        switch self {
        case let .text(value):
            return .text(value)
        case let .highlightedText(value):
            return .tinted(value)
        case let .term(value):
            return .emphasized(value)
        case let .icon(url):
            return .icon(url)
        }
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
