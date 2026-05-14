//
//  BaStudentDetailContentCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaStudentProfileCardsSection: View {
    let info: BaStudentGuideInfo
    let tint: Color

    private var sections: [BaStudentProfileSection] {
        info.profileSections
    }

    var body: some View {
        if sections.isEmpty {
            Section {
                BaStudentDetailEmptyRow(section: .profile)
                    .baStudentDetailListCardRow()
            }
        } else {
            Section {
                ForEach(sections) { section in
                    BaStudentProfileSectionCard(section: section, tint: tint)
                        .baStudentDetailListCardRow()
                }
            } header: {
                BaStudentDetailSectionHeader(
                    title: String(localized: "ba.student.detail.archive.title"),
                    systemImage: BaStudentDetailSection.profile.systemImage,
                    tint: tint
                )
            }
        }
    }
}

struct BaStudentSkillCardsSection: View {
    let rows: [BaGuideRow]
    let tint: Color

    private var cards: [BaStudentSkillDisplayModel] {
        BaStudentSkillDisplayModel.cards(from: rows)
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
            BaStudentDetailSectionHeader(
                title: BaStudentDetailSection.skills.title,
                systemImage: BaStudentDetailSection.skills.systemImage,
                tint: tint
            )
        }
    }
}

struct BaStudentDetailRowsCardsSection: View {
    let section: BaStudentDetailSection
    let rows: [BaGuideRow]
    let tint: Color

    var body: some View {
        Section {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: section)
                    .baStudentDetailListCardRow()
            } else {
                ForEach(rows.prefix(18)) { row in
                    BaStudentGuideInfoCard(row: row, section: section, tint: tint)
                        .baStudentDetailListCardRow()
                }
            }
        } header: {
            BaStudentDetailSectionHeader(title: section.title, systemImage: section.systemImage, tint: tint)
        }
    }
}

struct BaStudentGalleryCardsSection: View {
    let items: [BaGuideGalleryItem]

    var body: some View {
        Section {
            if items.isEmpty {
                BaStudentDetailEmptyRow(section: .gallery)
                    .baStudentDetailListCardRow()
            } else {
                ForEach(items.prefix(18)) { item in
                    BaStudentGalleryCard(item: item)
                        .baStudentDetailListCardRow()
                }
            }
        } header: {
            BaStudentDetailSectionHeader(
                title: BaStudentDetailSection.gallery.title,
                systemImage: BaStudentDetailSection.gallery.systemImage,
                tint: BaDesign.pink
            )
        }
    }
}

struct BaStudentSimulationCardsSection: View {
    let rows: [BaGuideRow]
    let tint: Color

    @State private var mode: BaStudentSimulationMode = .maximum

    private var displayedRows: [BaGuideRow] {
        let filtered = rows.filter { mode.matches($0) }
        return filtered.isEmpty ? rows : filtered
    }

    var body: some View {
        Section {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: .simulate)
                    .baStudentDetailListCardRow()
            } else {
                BaStudentSimulationAbilityCard(rows: Array(displayedRows.prefix(24)), mode: $mode, tint: tint)
                    .baStudentDetailListCardRow()
            }
        } header: {
            BaStudentDetailSectionHeader(
                title: BaStudentDetailSection.simulate.title,
                systemImage: BaStudentDetailSection.simulate.systemImage,
                tint: tint
            )
        }
    }
}

private struct BaStudentDetailSectionHeader: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .textCase(nil)
    }
}

private struct BaStudentProfileSectionCard: View {
    let section: BaStudentProfileSection
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                Text(section.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                VStack(spacing: 12) {
                    ForEach(section.rows) { row in
                        BaStudentProfilePillRow(row: row, tint: tint)
                    }
                }
            }
        }
    }
}

private struct BaStudentProfilePillRow: View {
    let row: BaGuideRow
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(row.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: 126, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if BaStudentDetailContentFormatter.prefersChip(row.value) {
                BaStudentDetailTextChip(title: row.value.ifBlank(String(localized: "ba.common.none")), tint: tint)
            } else {
                Text(row.value.ifBlank(String(localized: "ba.common.none")))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct BaStudentSkillCard: View {
    let card: BaStudentSkillDisplayModel
    let tint: Color

    private var chips: [BaStudentDetailChipData] {
        BaStudentDetailContentFormatter.skillChips(card: card, tint: tint)
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            HStack(alignment: .top, spacing: 14) {
                BaRemoteImageSurface(
                    url: card.iconURL,
                    fallbackSystemImage: BaStudentDetailSection.skills.systemImage,
                    tint: tint,
                    width: 44,
                    height: 44,
                    cornerRadius: 14,
                    fallbackFont: .headline.weight(.semibold)
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Text(card.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 7) {
                            ForEach(chips.prefix(4)) { chip in
                                BaStudentDetailTextChip(title: chip.title, tint: chip.tint, filled: chip.isFilled)
                            }
                        }
                    }

                    BaStudentHighlightedText(card.detail.ifBlank(String(localized: "ba.common.none")))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if card.mediaCount > 1 {
                        Label(
                            String(format: String(localized: "ba.student.detail.imageCount.format"), card.mediaCount),
                            systemImage: "photo.stack"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct BaStudentGuideInfoCard: View {
    let row: BaGuideRow
    let section: BaStudentDetailSection
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            HStack(alignment: .top, spacing: 14) {
                BaRemoteImageSurface(
                    url: row.imageURL,
                    fallbackSystemImage: section.systemImage,
                    tint: tint,
                    width: 44,
                    height: 44,
                    cornerRadius: 14,
                    fallbackFont: .headline.weight(.semibold)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(row.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    BaStudentHighlightedText(row.value.ifBlank(String(localized: "ba.common.none")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let count = row.imageURLs?.count, count > 1 {
                        Text(String(format: String(localized: "ba.student.detail.imageCount.format"), count))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

private struct BaStudentGalleryCard: View {
    let item: BaGuideGalleryItem

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(galleryDetail)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    if let mediaURL = item.mediaURL {
                        Menu {
                            ShareLink(item: mediaURL) {
                                Label(String(localized: "ba.action.share"), systemImage: "square.and.arrow.up")
                            }
                            Link(destination: mediaURL) {
                                Label(
                                    String(localized: "ba.student.detail.media.openSource"),
                                    systemImage: "safari"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.headline.weight(.semibold))
                                .frame(width: 44, height: 38)
                                .liquidGlassSurface(
                                    cornerRadius: 18,
                                    tint: BaDesign.pink.opacity(0.10),
                                    isInteractive: true
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                BaRemoteImageSurface(
                    url: item.imageURL,
                    fallbackSystemImage: kind.systemImage,
                    tint: BaDesign.pink,
                    width: nil,
                    height: mediaHeight,
                    cornerRadius: 22,
                    contentMode: .fit,
                    usesImageBackdrop: kind == .image || kind == .live2d,
                    fallbackFont: .system(size: 50, weight: .semibold)
                )

                HStack(spacing: 8) {
                    BaStudentDetailTextChip(title: kind.title, tint: BaDesign.pink)
                    if let unlock = item.memoryUnlockLevel, unlock.isEmpty == false {
                        BaStudentDetailTextChip(
                            title: String(format: String(localized: "ba.student.detail.memory.unlock.format"), unlock),
                            tint: BaDesign.blue
                        )
                    }
                }
            }
        }
    }

    private var mediaHeight: CGFloat {
        switch kind {
        case .image, .live2d:
            430
        case .video:
            220
        case .audio, .unknown:
            160
        }
    }

    private var galleryDetail: String {
        var parts = [kind.title]
        if isMeaningfulDetail(item.detail) {
            parts.append(item.detail)
        }
        if let note = item.note, isMeaningfulDetail(note), parts.contains(note) == false {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }

    private func isMeaningfulDetail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, trimmed != kind.title else { return false }
        if trimmed.localizedCaseInsensitiveContains("gamekee.com") {
            return false
        }
        return true
    }
}

private struct BaStudentSimulationAbilityCard: View {
    let rows: [BaGuideRow]
    @Binding var mode: BaStudentSimulationMode
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Text(String(localized: "ba.student.detail.simulate.ability.title"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Picker(String(localized: "ba.student.detail.page.simulate"), selection: $mode) {
                        ForEach(BaStudentSimulationMode.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 240)
                }

                VStack(spacing: 13) {
                    ForEach(rows) { row in
                        BaStudentSimulationStatRow(row: row, tint: tint)
                    }
                }
            }
        }
    }
}

private struct BaStudentSimulationStatRow: View {
    let row: BaGuideRow
    let tint: Color

    private var valueParts: (base: String, bonus: String?) {
        BaStudentDetailContentFormatter.splitStatValue(row.value.ifBlank(String(localized: "ba.common.none")))
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: BaStudentDetailContentFormatter.statSystemImage(for: row.title))
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 26)

            Text(row.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Text(valueParts.base)
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                if let bonus = valueParts.bonus {
                    Text(bonus)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(BaDesign.amber)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
    }
}

private struct BaStudentDetailTextChip: View {
    let title: String
    let tint: Color
    var filled = false

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(filled ? .white : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(filled ? tint.opacity(0.82) : tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.24), lineWidth: 1)
            }
    }
}

private struct BaStudentHighlightedText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(BaStudentDetailContentFormatter.highlightedAttributedString(in: text))
    }
}

private struct BaStudentDetailChipData: Identifiable {
    let title: String
    let tint: Color
    var isFilled = false

    var id: String {
        "\(title)-\(isFilled)"
    }
}

private struct BaStudentSkillDisplayModel: Identifiable {
    let id: String
    let title: String
    let detail: String
    let iconURL: URL?
    let type: String?
    let level: String?
    let cost: String?
    let mediaCount: Int

    static func cards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        let normalizedRows = rows.prefix(30)
        var cards: [BaStudentSkillDisplayModel] = []
        var builder = Builder()

        for row in normalizedRows {
            if builder.shouldSplit(before: row) {
                if let card = builder.makeCard(index: cards.count) {
                    cards.append(card)
                }
                builder = Builder()
            }
            builder.ingest(row)
        }
        if let card = builder.makeCard(index: cards.count) {
            cards.append(card)
        }
        return cards.isEmpty ? fallbackCards(from: rows) : cards
    }

    private static func fallbackCards(from rows: [BaGuideRow]) -> [BaStudentSkillDisplayModel] {
        rows.prefix(16).enumerated().map { index, row in
            BaStudentSkillDisplayModel(
                id: row.id,
                title: BaStudentDetailContentFormatter.skillTitle(row: row, index: index),
                detail: row.value,
                iconURL: row.imageURL,
                type: nil,
                level: nil,
                cost: nil,
                mediaCount: row.imageURLs?.count ?? (row.imageURL == nil ? 0 : 1)
            )
        }
    }

    private struct Builder {
        var rows: [BaGuideRow] = []
        var title: String?
        var detailParts: [String] = []
        var iconURL: URL?
        var type: String?
        var level: String?
        var cost: String?

        var hasMeaningfulContent: Bool {
            title != nil || detailParts.isEmpty == false || iconURL != nil || type != nil || level != nil || cost != nil
        }

        func shouldSplit(before row: BaGuideRow) -> Bool {
            guard hasMeaningfulContent else { return false }
            let key = normalized(row.title)
            if isSkillTypeKey(key) {
                return true
            }
            if key.contains("技能名称"), title != nil {
                return true
            }
            if key.contains("技能描述"), detailParts.isEmpty == false {
                return true
            }
            if key == "技能", isSkillSignal(row.value) == false, title != nil {
                return true
            }
            return false
        }

        mutating func ingest(_ row: BaGuideRow) {
            rows.append(row)
            let key = normalized(row.title)
            let value = normalized(row.value)

            if key.contains("技能图标"), iconURL == nil {
                iconURL = row.imageURL
            } else if key.contains("技能名称"), value.isEmpty == false {
                title = value
            } else if key.contains("技能类型"), value.isEmpty == false {
                type = value
            } else if key.contains("技能描述"), value.isEmpty == false {
                detailParts.append(value)
            } else if key.localizedCaseInsensitiveContains("等级"), value.isEmpty == false {
                level = value
            } else if key.localizedCaseInsensitiveContains("cost"), value.isEmpty == false {
                cost = value
            } else if key == "技能", isSkillSignal(value) == false {
                if value.isEmpty == false, value != "无" {
                    detailParts.append(value)
                }
            } else if row.imageURL != nil, iconURL == nil {
                iconURL = row.imageURL
            } else if value.isEmpty == false, value != "无" {
                detailParts.append(value)
            }
        }

        func makeCard(index: Int) -> BaStudentSkillDisplayModel? {
            guard hasMeaningfulContent else { return nil }
            let cleanDetail = detailParts
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false && $0 != "无" }
                .joined(separator: "\n")
            let fallbackTitle = title ?? type ?? String(format: String(localized: "ba.student.detail.row.format"), index + 1)
            return BaStudentSkillDisplayModel(
                id: rows.map(\.id).joined(separator: "|"),
                title: fallbackTitle,
                detail: cleanDetail,
                iconURL: iconURL,
                type: type,
                level: level,
                cost: cost,
                mediaCount: rows.reduce(into: 0) { count, row in
                    count += row.imageURLs?.count ?? (row.imageURL == nil ? 0 : 1)
                }
            )
        }

        private func normalized(_ value: String) -> String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private func isSkillTypeKey(_ key: String) -> Bool {
            key.contains("技能类型")
        }

        private func isSkillSignal(_ value: String) -> Bool {
            ["EX", "普通", "被动", "辅助"].contains { value.localizedCaseInsensitiveContains($0) }
        }
    }
}

private enum BaStudentSimulationMode: String, CaseIterable, Identifiable {
    case initial
    case maximum

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .initial:
            String(localized: "ba.student.detail.simulate.initial")
        case .maximum:
            String(localized: "ba.student.detail.simulate.maximum")
        }
    }

    func matches(_ row: BaGuideRow) -> Bool {
        let text = "\(row.title) \(row.value)"
        switch self {
        case .initial:
            return Self.containsAny(text, tokens: ["初始", "基础", "Lv1", "1星", "默认"])
        case .maximum:
            return Self.containsAny(text, tokens: ["最大", "顶级", "满", "Lv90", "5星", "固有"])
        }
    }

    private static func containsAny(_ value: String, tokens: [String]) -> Bool {
        tokens.contains { value.localizedCaseInsensitiveContains($0) }
    }
}

private enum BaStudentDetailContentFormatter {
    static func prefersChip(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 18 && trimmed.contains("\n") == false
    }

    static func skillTitle(row: BaGuideRow, index: Int) -> String {
        let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty == false {
            return title
        }
        return String(format: String(localized: "ba.student.detail.row.format"), index + 1)
    }

    static func skillChips(row: BaGuideRow, tint: Color) -> [BaStudentDetailChipData] {
        skillChips(
            type: nil,
            level: nil,
            cost: nil,
            title: row.title,
            value: row.value,
            tint: tint
        )
    }

    static func skillChips(card: BaStudentSkillDisplayModel, tint: Color) -> [BaStudentDetailChipData] {
        skillChips(
            type: card.type,
            level: card.level,
            cost: card.cost,
            title: card.title,
            value: card.detail,
            tint: tint
        )
    }

    private static func skillChips(
        type: String?,
        level: String?,
        cost: String?,
        title: String,
        value: String,
        tint: Color
    ) -> [BaStudentDetailChipData] {
        let merged = "\(title) \(value) \(type ?? "") \(level ?? "") \(cost ?? "")"
        var chips: [BaStudentDetailChipData] = []
        if let type {
            let typeTitle: String
            if type.localizedCaseInsensitiveContains("EX") {
                typeTitle = "EX"
            } else if type.localizedCaseInsensitiveContains("普通") {
                typeTitle = String(localized: "ba.student.detail.skill.normal")
            } else if type.localizedCaseInsensitiveContains("被动") {
                typeTitle = String(localized: "ba.student.detail.skill.passive")
            } else if type.localizedCaseInsensitiveContains("辅助") {
                typeTitle = String(localized: "ba.student.detail.skill.sub")
            } else {
                typeTitle = type
            }
            chips.append(BaStudentDetailChipData(title: typeTitle, tint: tint, isFilled: true))
        } else if containsAny(merged, tokens: ["EX", "Ex", "ex"]) {
            chips.append(BaStudentDetailChipData(title: "EX", tint: tint, isFilled: true))
        } else if containsAny(merged, tokens: ["普通技能"]) {
            chips.append(BaStudentDetailChipData(title: String(localized: "ba.student.detail.skill.normal"), tint: tint))
        } else if containsAny(merged, tokens: ["被动技能"]) {
            chips.append(BaStudentDetailChipData(title: String(localized: "ba.student.detail.skill.passive"), tint: tint))
        } else if containsAny(merged, tokens: ["辅助技能"]) {
            chips.append(BaStudentDetailChipData(title: String(localized: "ba.student.detail.skill.sub"), tint: tint))
        } else if containsAny(merged, tokens: ["技能"]) {
            chips.append(BaStudentDetailChipData(title: BaStudentDetailSection.skills.title, tint: tint))
        }

        if let level {
            chips.append(BaStudentDetailChipData(title: level, tint: BaDesign.blue, isFilled: true))
        } else if let levelMatch = firstMatch(in: merged, pattern: #"Lv\.?\s*\d+|LV\.?\s*\d+|等级\s*\d+"#) {
            chips.append(BaStudentDetailChipData(title: levelMatch, tint: BaDesign.blue, isFilled: true))
        }
        if let cost {
            chips.append(BaStudentDetailChipData(title: cost, tint: BaDesign.cyan))
        } else if let costMatch = firstMatch(in: merged, pattern: #"COST[:：]?\s*\d+|Cost[:：]?\s*\d+|技能COST[:：]?\s*\d+"#) {
            chips.append(BaStudentDetailChipData(title: costMatch, tint: BaDesign.cyan))
        }
        return chips.isEmpty ? [BaStudentDetailChipData(title: BaStudentDetailSection.skills.title, tint: tint)] : chips
    }

    static func highlightedAttributedString(in text: String) -> AttributedString {
        var attributed = AttributedString(text)
        guard let regex = try? NSRegularExpression(
            pattern: #"\d+(?:\.\d+)?\s*(?:%|％|秒|s|S|倍)|COST[:：]?\s*\d+|Lv\.?\s*\d+"#,
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
            let attributedRange = lower ..< upper
            attributed[attributedRange].foregroundColor = BaDesign.pink
            attributed[attributedRange].inlinePresentationIntent = .stronglyEmphasized
        }
        return attributed
    }

    static func splitStatValue(_ value: String) -> (base: String, bonus: String?) {
        let normalized = value.replacingOccurrences(of: "（", with: "(").replacingOccurrences(of: "）", with: ")")
        guard let range = normalized.range(of: #"\(\+\s*[^)]+\)"#, options: .regularExpression) else {
            return (normalized, nil)
        }
        let base = normalized[..<range.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bonus = normalized[range]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (String(base).ifBlank(normalized), String(bonus))
    }

    static func statSystemImage(for title: String) -> String {
        if containsAny(title, tokens: ["攻击"]) { return "asterisk" }
        if containsAny(title, tokens: ["防御"]) { return "shield.lefthalf.filled" }
        if containsAny(title, tokens: ["生命", "HP"]) { return "heart.fill" }
        if containsAny(title, tokens: ["治疗"]) { return "cross.fill" }
        if containsAny(title, tokens: ["命中"]) { return "target" }
        if containsAny(title, tokens: ["闪避"]) { return "circle.dotted" }
        if containsAny(title, tokens: ["暴击"]) { return "sparkle" }
        if containsAny(title, tokens: ["稳定"]) { return "alternatingcurrent" }
        if containsAny(title, tokens: ["射程"]) { return "arrow.up.right" }
        if containsAny(title, tokens: ["COST", "Cost"]) { return "hourglass" }
        return "diamond.fill"
    }

    private static func firstMatch(in value: String, pattern: String) -> String? {
        guard let range = value.range(of: pattern, options: .regularExpression) else { return nil }
        return String(value[range]).replacingOccurrences(of: " ", with: "")
    }

    private static func containsAny(_ value: String, tokens: [String]) -> Bool {
        tokens.contains { value.localizedCaseInsensitiveContains($0) }
    }
}

private extension View {
    func baStudentDetailListCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
