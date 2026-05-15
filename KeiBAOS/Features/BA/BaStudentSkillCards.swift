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
        } header: {
            BaStudentSkillSectionHeader(tint: tint)
        }
    }
}

private struct BaStudentSkillSectionHeader: View {
    let tint: Color

    var body: some View {
        Label {
            Text(BaStudentDetailSection.skills.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: BaStudentDetailSection.skills.systemImage)
                .foregroundStyle(tint)
        }
        .textCase(nil)
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

private struct BaStudentSkillDescriptionView: View {
    let description: String
    let glossaryIcons: [String: URL]
    let descriptionIcons: [URL]
    let tint: Color

    private var matchedGlossary: [(label: String, url: URL)] {
        let normalizedDescription = BaStudentSkillTextNormalizer.normalizeGlossaryToken(description)
        return glossaryIcons
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

                Text(BaStudentSkillTextNormalizer.highlightedAttributedString(in: description, tint: tint))
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

nonisolated struct BaStudentSkillDisplayModel: Identifiable, Hashable {
    let id: String
    let type: String
    let name: String
    let iconURL: URL?
    let descriptionByLevel: [String: String]
    let descriptionIconsByLevel: [String: [URL]]
    let costByLevel: [String: String]
    let glossaryIcons: [String: URL]
    let fallbackDescription: String
    let fallbackDescriptionIcons: [URL]

    var displayName: String {
        name.ifBlank(String(localized: "ba.student.detail.skill.unnamed"))
    }

    var levelOptions: [String] {
        descriptionByLevel.keys.sorted {
            (Self.parseLevelNumber($0) ?? Int.max, $0) < (Self.parseLevelNumber($1) ?? Int.max, $1)
        }
    }

    var defaultLevel: String {
        levelOptions.max {
            (Self.parseLevelNumber($0) ?? Int.min, $0) < (Self.parseLevelNumber($1) ?? Int.min, $1)
        } ?? levelOptions.first ?? "Lv.1"
    }

    var localizedType: String {
        let base = typeMeta.baseType
        if base.localizedCaseInsensitiveContains("EX") {
            return "EX技能"
        }
        if base.localizedCaseInsensitiveContains("普通") {
            return String(localized: "ba.student.detail.skill.normal")
        }
        if base.localizedCaseInsensitiveContains("被动") {
            return String(localized: "ba.student.detail.skill.passive")
        }
        if base.localizedCaseInsensitiveContains("辅助") {
            return String(localized: "ba.student.detail.skill.sub")
        }
        return base.ifBlank(BaStudentDetailSection.skills.title)
    }

    var typeStateTags: [String] {
        typeMeta.stateTags
    }

    var typeVariantBadge: String? {
        typeMeta.variantIndex.flatMap(Self.circledNumber)
    }

    private var typeMeta: BaStudentSkillTypeMeta {
        BaStudentSkillTypeMeta.parse(type)
    }

    func description(for level: String) -> String {
        descriptionByLevel[level]
            ?? descriptionByLevel[defaultLevel]
            ?? fallbackDescription
    }

    func descriptionIcons(for level: String) -> [URL] {
        let levelIcons = descriptionIconsByLevel[level] ?? []
        if levelIcons.isEmpty == false {
            return levelIcons
        }
        let defaultIcons = descriptionIconsByLevel[defaultLevel] ?? []
        return defaultIcons.isEmpty ? fallbackDescriptionIcons : defaultIcons
    }

    func cost(for level: String) -> String {
        costByLevel[level]
            ?? costByLevel[defaultLevel]
            ?? costByLevel.values.first
            ?? ""
    }

    static func cards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        let glossaryIcons = extractSkillGlossaryIcons(from: rows)
        let drafts = parseBaseSkillDrafts(from: rows)
        let cards = drafts.enumerated().compactMap { index, draft -> BaStudentSkillDisplayModel? in
            let hasHead = draft.name.isEmpty == false || draft.iconURL != nil
            let hasDescription = draft.descriptionByLevel.isEmpty == false || draft.fallbackDescription.isEmpty == false
            guard hasHead, hasDescription else { return nil }
            return BaStudentSkillDisplayModel(
                id: "skill-\(index)-\(draft.type)-\(draft.name)",
                type: draft.type,
                name: draft.name,
                iconURL: draft.iconURL,
                descriptionByLevel: draft.descriptionByLevel,
                descriptionIconsByLevel: draft.descriptionIconsByLevel,
                costByLevel: draft.costByLevel,
                glossaryIcons: glossaryIcons,
                fallbackDescription: draft.fallbackDescription,
                fallbackDescriptionIcons: draft.fallbackDescriptionIcons
            )
        }
        return cards.isEmpty ? fallbackCards(from: rows) : cards
    }

    static func parseLevelNumber(_ label: String) -> Int? {
        guard let range = label.range(of: #"\d{1,2}"#, options: .regularExpression) else {
            return nil
        }
        return Int(label[range])
    }

    private static func fallbackCards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        rows.prefix(16).enumerated().map { index, row in
            BaStudentSkillDisplayModel(
                id: row.id,
                type: "",
                name: skillTitle(row: row, index: index),
                iconURL: row.imageURL,
                descriptionByLevel: [:],
                descriptionIconsByLevel: [:],
                costByLevel: [:],
                glossaryIcons: [:],
                fallbackDescription: row.value,
                fallbackDescriptionIcons: rowDescriptionIcons(row)
            )
        }
    }

    private static func skillTitle(row: BaGuideRow, index: Int) -> String {
        let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty == false {
            return title
        }
        return String(format: String(localized: "ba.student.detail.row.format"), index + 1)
    }

    private static func parseBaseSkillDrafts(from rows: [BaGuideRow]) -> [SkillDraft] {
        var result: [SkillDraft] = []
        var draft: SkillDraft?
        var currentLevelKey: String?
        var enteredSkillBlocks = false
        var pendingName = ""
        var pendingIconURL: URL?
        var currentType = ""
        var lastDescribedDraft: SkillDraft?

        func commitDraft() {
            guard var item = draft else { return }
            if item.hasDescription == false,
               let inherited = lastDescribedDraft,
               inherited.type == item.type {
                item.descriptionByLevel = inherited.descriptionByLevel
                item.descriptionIconsByLevel = inherited.descriptionIconsByLevel
                item.costByLevel = inherited.costByLevel
                item.fallbackDescription = inherited.fallbackDescription
                item.fallbackDescriptionIcons = inherited.fallbackDescriptionIcons
            }
            result.append(item)
            if item.hasDescription {
                lastDescribedDraft = item
            }
            draft = nil
            currentLevelKey = nil
        }

        for row in rows.flatMap(expandedSkillRows) {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
            let image = row.imageURL
            let iconCandidates = rowDescriptionIcons(row)

            if key == "专武" || key.contains("技能名词") || key.contains("升级材料") || key == "所需个数" {
                commitDraft()
                if key.contains("技能名词") {
                    enteredSkillBlocks = false
                }
                continue
            }

            if key == "技能类型" {
                guard value.isEmpty == false else { continue }
                enteredSkillBlocks = true
                commitDraft()
                currentType = sanitizeSkillLabel(value)
                draft = SkillDraft(type: currentType)
                if pendingName.isEmpty == false {
                    draft?.name = pendingName
                }
                if let pendingIconURL {
                    draft?.iconURL = pendingIconURL
                }
                pendingName = ""
                pendingIconURL = nil
                currentLevelKey = nil
                continue
            }

            if enteredSkillBlocks == false {
                if key.contains("技能名称"), value.isEmpty == false {
                    pendingName = sanitizeSkillLabel(value)
                } else if key == "技能图标", let image {
                    pendingIconURL = image
                }
                continue
            }

            if key.isEmpty, value.isEmpty, image == nil {
                commitDraft()
                continue
            }

            guard draft != nil else { continue }
            switch true {
            case key.contains("技能名称") && key.contains("★") == false:
                if value.isEmpty == false {
                    if let active = draft, active.name.isEmpty == false {
                        commitDraft()
                        draft = SkillDraft(type: currentType.ifBlank(active.type))
                    } else if draft == nil {
                        draft = SkillDraft(type: currentType)
                    }
                    draft?.name = sanitizeSkillLabel(value)
                }
            case key == "技能图标":
                if let image {
                    draft?.iconURL = image
                }
            case key == "技能等级":
                if let levelLabel = toDisplayLevelLabel(value) {
                    currentLevelKey = levelLabel
                }
            case key == "技能描述":
                if let currentLevelKey {
                    if value.isEmpty == false {
                        draft?.descriptionByLevel[currentLevelKey] = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.descriptionIconsByLevel[currentLevelKey] = iconCandidates
                    }
                } else {
                    if value.isEmpty == false {
                        draft?.fallbackDescription = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.fallbackDescriptionIcons = iconCandidates
                    }
                }
            case key == "技能COST":
                if value.isEmpty == false {
                    if let currentLevelKey {
                        draft?.costByLevel[currentLevelKey] = normalizeCost(value)
                    } else {
                        draft?.costByLevel["base"] = normalizeCost(value)
                    }
                }
            default:
                if let levelLabel = toDisplayLevelLabel(key) {
                    if value.isEmpty == false {
                        draft?.descriptionByLevel[levelLabel] = value
                    }
                    if iconCandidates.isEmpty == false {
                        draft?.descriptionIconsByLevel[levelLabel] = iconCandidates
                    }
                    currentLevelKey = levelLabel
                }
            }
        }
        commitDraft()
        return result
    }

    private static func expandedSkillRows(from row: BaGuideRow) -> [BaGuideRow] {
        let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key == "角色技能", value.contains("技能类型") || value.contains("技能名称") else {
            return [row]
        }
        let parts = value
            .components(separatedBy: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        guard parts.count >= 2 else { return [row] }
        var expanded: [BaGuideRow] = []
        var index = 0
        while index < parts.count {
            let title = parts[index]
            let next = parts.indices.contains(index + 1) ? parts[index + 1] : ""
            if isKnownSkillKey(title) || toDisplayLevelLabel(title) != nil {
                expanded.append(
                    BaGuideRow(
                        id: "\(row.id)-expanded-\(expanded.count)",
                        title: title,
                        value: next,
                        imageURL: nil
                    )
                )
                index += 2
            } else {
                index += 1
            }
        }
        return expanded.isEmpty ? [row] : expanded
    }

    private static func extractSkillGlossaryIcons(from rows: [BaGuideRow]) -> [String: URL] {
        var glossary: [String: URL] = [:]
        var inGlossary = false

        for row in rows {
            let key = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if key == "技能名词" {
                inGlossary = true
                continue
            }
            guard inGlossary else { continue }
            if key.contains("升级材料") || key == "专武" || key.contains("爱用品") {
                inGlossary = false
                continue
            }
            if key == "名词图标" || key == "名词解释" || key.range(of: #"名词\d+"#, options: .regularExpression) != nil {
                continue
            }
            if key.isEmpty == false, let imageURL = row.imageURL {
                glossary[key] = imageURL
            }
        }
        return glossary
    }

    private static func rowDescriptionIcons(_ row: BaGuideRow) -> [URL] {
        let candidates = row.imageURLs ?? row.imageURL.map { [$0] } ?? []
        return Array(
            candidates
                .filter(isLikelyDescriptionIcon)
                .reduce(into: [URL]()) { result, url in
                    if result.contains(url) == false {
                        result.append(url)
                    }
                }
                .prefix(6)
        )
    }

    private static func isLikelyDescriptionIcon(_ url: URL) -> Bool {
        let value = url.absoluteString
        if value.localizedCaseInsensitiveContains("data:image") {
            return true
        }
        guard let match = value.range(of: #"/w_(\d{1,4})/h_(\d{1,4})/"#, options: .regularExpression) else {
            return false
        }
        let matched = String(value[match])
        let numbers = matched
            .split { $0 == "/" || $0 == "_" }
            .compactMap { Int($0) }
        guard numbers.count >= 2 else { return false }
        return numbers[0] <= 96 && numbers[1] <= 96
    }

    private static func toDisplayLevelLabel(_ rawKey: String) -> String? {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        guard let range = key.range(of: #"(?i)^LV\.?\d{1,2}$"#, options: .regularExpression),
              range.lowerBound == key.startIndex,
              range.upperBound == key.endIndex,
              let number = parseLevelNumber(key)
        else {
            return nil
        }
        return "Lv.\(number)"
    }

    private static func sanitizeSkillLabel(_ raw: String) -> String {
        let cleaned = stripInlineNotes(raw)
        guard cleaned.isEmpty == false else { return "" }
        let segments = splitSlashSegments(cleaned)
        guard segments.count > 1 else { return cleaned }
        let tailHasPlaceholder = segments.dropFirst().contains { segment in
            let compact = segment.replacingOccurrences(of: " ", with: "")
            return compact.isEmpty ||
                compact == "..." ||
                compact == "…" ||
                compact.count <= 2 ||
                ["占位", "暂无", "无", "待补", "图片"].contains { compact.contains($0) } ||
                isLikelyNoteSegment(segment)
        }
        return tailHasPlaceholder ? segments[0].trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    private static func stripInlineNotes(_ raw: String) -> String {
        raw.components(separatedBy: "<-").first?
            .components(separatedBy: "←").first?
            .trimmingCharacters(in: CharacterSet(charactersIn: " /／|｜,，;；\n\t"))
            ?? ""
    }

    private static func splitSlashSegments(_ raw: String) -> [String] {
        raw.components(separatedBy: CharacterSet(charactersIn: "/／|｜"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private static func isLikelyNoteSegment(_ raw: String) -> Bool {
        let compact = raw.replacingOccurrences(of: " ", with: "")
        return compact.hasPrefix("注") ||
            compact.localizedCaseInsensitiveContains("todo") ||
            compact.localizedCaseInsensitiveContains("note")
    }

    private static func isKnownSkillKey(_ value: String) -> Bool {
        ["技能名称", "技能类型", "技能图标", "技能等级", "技能描述", "技能COST"].contains(value)
    }

    private static func normalizeCost(_ raw: String) -> String {
        raw.replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: #"(?i)^COST:\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func circledNumber(_ index: Int) -> String? {
        let numbers = [
            "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
            "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
        ]
        return numbers.indices.contains(index - 1) ? numbers[index - 1] : "\(index)"
    }

    private struct SkillDraft {
        var type = ""
        var name = ""
        var iconURL: URL?
        var fallbackDescription = ""
        var fallbackDescriptionIcons: [URL] = []
        var descriptionByLevel: [String: String] = [:]
        var descriptionIconsByLevel: [String: [URL]] = [:]
        var costByLevel: [String: String] = [:]

        var hasDescription: Bool {
            descriptionByLevel.isEmpty == false || fallbackDescription.isEmpty == false
        }
    }
}

private nonisolated struct BaStudentSkillTypeMeta: Hashable {
    var baseType: String
    var variantIndex: Int?
    var stateTags: [String] = []

    static func parse(_ raw: String) -> BaStudentSkillTypeMeta {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else {
            return BaStudentSkillTypeMeta(baseType: "")
        }

        var variantIndex: Int?
        var stateTags: [String] = []
        let bracketPattern = #"[（(【\[]([^()（）【】\[\]]+)[)）】\]]"#
        let bracketMatches = matches(in: cleaned, pattern: bracketPattern)
        for candidate in bracketMatches {
            let tokens = candidate
                .components(separatedBy: CharacterSet(charactersIn: "、,，/／|｜+＋"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
            for token in tokens.isEmpty ? [candidate] : tokens {
                let tokenMeta = parseToken(token)
                variantIndex = variantIndex ?? tokenMeta.variantIndex
                let tag = normalizeStateTag(tokenMeta.base.ifBlank(token))
                if tag.isEmpty == false {
                    stateTags.append(tag)
                }
            }
        }

        let baseCandidate = cleaned
            .replacingOccurrences(of: bracketPattern, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " -_/／|｜"))
        let owned = splitOwnedSkillType(baseCandidate.ifBlank(cleaned))
        let baseToken = owned?.skillType ?? baseCandidate.ifBlank(cleaned)
        let baseMeta = parseToken(baseToken)
        variantIndex = variantIndex ?? baseMeta.variantIndex
        if let ownerTag = owned?.ownerTag, ownerTag.isEmpty == false {
            stateTags.insert(normalizeStateTag(ownerTag), at: 0)
        }

        return BaStudentSkillTypeMeta(
            baseType: baseMeta.base.ifBlank(cleaned),
            variantIndex: variantIndex,
            stateTags: Array(NSOrderedSet(array: stateTags.filter { $0.isEmpty == false })) as? [String] ?? stateTags
        )
    }

    private static func matches(in value: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsValue = value as NSString
        return regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return nsValue.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func splitOwnedSkillType(_ raw: String) -> (ownerTag: String, skillType: String)? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard let range = normalized.range(of: #"^(「[^」]{1,40}」|『[^』]{1,40}』|【[^】]{1,40}】|[A-Za-z0-9\u{4E00}-\u{9FFF}·・\-\s]{1,40})\s*的\s*(.+)$"#, options: .regularExpression) else {
            return nil
        }
        let matched = String(normalized[range])
        let parts = matched.components(separatedBy: "的")
        guard parts.count >= 2 else { return nil }
        let owner = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let skillType = parts.dropFirst().joined(separator: "的").trimmingCharacters(in: .whitespacesAndNewlines)
        guard owner.isEmpty == false, skillType.contains("技能") else { return nil }
        return (owner, skillType)
    }

    private static func parseToken(_ raw: String) -> (base: String, variantIndex: Int?) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return ("", nil) }
        let circledNumbers = [
            "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
            "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
        ]
        if let suffix = circledNumbers.first(where: { cleaned.hasSuffix($0) }),
           let index = circledNumbers.firstIndex(of: suffix) {
            let base = String(cleaned.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            return (base.ifBlank(cleaned), index + 1)
        }
        if let range = cleaned.range(of: #"^(.*?)[\s\-_]*(\d{1,2})$"#, options: .regularExpression) {
            let matched = String(cleaned[range])
            guard let numberRange = matched.range(of: #"\d{1,2}$"#, options: .regularExpression),
                  let index = Int(matched[numberRange]),
                  index > 0
            else {
                return (cleaned, nil)
            }
            let base = matched[..<numberRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            return (String(base).ifBlank(cleaned), index)
        }
        return (cleaned, nil)
    }

    private static func normalizeStateTag(_ raw: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = cleaned.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "　", with: "")
        if compact.hasPrefix("对"), compact.hasSuffix("使用"), compact.count > 3 {
            return String(compact.dropLast(2))
        }
        return cleaned
    }
}

private enum BaStudentSkillTextNormalizer {
    static func highlightedAttributedString(in text: String, tint: Color) -> AttributedString {
        var attributed = AttributedString(text)
        guard let regex = try? NSRegularExpression(
            pattern: #"(?<![A-Za-z])[-+]?\d+(?:\.\d+)?\s*(?:%|％|秒|s|S|倍)?|COST[:：]?\s*\d+|Lv\.?\s*\d+"#,
            options: []
        ) else {
            return attributed
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            guard let stringRange = Range(match.range, in: text),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attributed)
            else {
                continue
            }
            attributed[lower ..< upper].foregroundColor = tint
            attributed[lower ..< upper].inlinePresentationIntent = .stronglyEmphasized
        }
        return attributed
    }

    static func normalizeGlossaryToken(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: #"[\s\u{3000}]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[，。、“”‘’：:；;（）()【】\[\]《》<>·•\-—_+*/\\|!?！？]"#, with: "", options: .regularExpression)
            .lowercased()
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
