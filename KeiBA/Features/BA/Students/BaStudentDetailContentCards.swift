//
//  BaStudentDetailContentCards.swift
//  KeiBA
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

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

                    BaStudentHighlightedText(row.value.ifBlank(BaL10n.string("ba.common.none")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let count = row.imageURLs?.count, count > 1 {
                        Text(String(format: BaL10n.string("ba.student.detail.imageCount.format"), count))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
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
        return String(format: BaL10n.string("ba.student.detail.row.format"), index + 1)
    }

    // Highlighted attributed strings render in every skill/profile row body
    // recompose. Compile this regex once instead of building it per call.
    private nonisolated static let highlightRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"\d+(?:\.\d+)?\s*(?:%|％|秒|s|S|倍)|COST[:：]?\s*\d+|Lv\.?\s*\d+"#,
            options: []
        )
    }()

    static func highlightedAttributedString(in text: String) -> AttributedString {
        var attributed = AttributedString(text)
        guard let regex = highlightRegex else {
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

    // Cached so the per-row stat parser doesn't recompile its regex literal
    // on every body recompose of the stat panel.
    private nonisolated static let bonusValueRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\(\+\s*[^)]+\)"#)
    }()

    static func splitStatValue(_ value: String) -> (base: String, bonus: String?) {
        let normalized = value.replacingOccurrences(of: "（", with: "(").replacingOccurrences(of: "）", with: ")")
        let foundRange: Range<String.Index>?
        if let regex = bonusValueRegex {
            let range = NSRange(normalized.startIndex ..< normalized.endIndex, in: normalized)
            foundRange = regex.firstMatch(in: normalized, range: range).flatMap { Range($0.range, in: normalized) }
        } else {
            foundRange = normalized.range(of: #"\(\+\s*[^)]+\)"#, options: .regularExpression)
        }
        guard let range = foundRange else {
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
        baAdaptiveListCardRow(top: 8, bottom: 10)
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
