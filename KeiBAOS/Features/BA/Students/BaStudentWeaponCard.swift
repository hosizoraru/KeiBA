//
//  BaStudentWeaponCard.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaStudentWeaponCardsSection: View {
    let tint: Color
    private let card: BaStudentWeaponDisplayModel?

    init(info: BaStudentGuideInfo?, tint: Color) {
        self.tint = tint
        self.card = info.flatMap(BaStudentWeaponDisplayModel.card)
    }

    var body: some View {
        if let card {
            Section {
                BaStudentWeaponCard(card: card, tint: tint)
                    .baStudentWeaponListCardRow()
            }
        }
    }
}

private struct BaStudentWeaponCard: View {
    let card: BaStudentWeaponDisplayModel
    let tint: Color

    @State private var selectedStatLevel: String

    init(card: BaStudentWeaponDisplayModel, tint: Color) {
        self.card = card
        self.tint = tint
        _selectedStatLevel = State(initialValue: card.statHeaders.last ?? "")
    }

    private var statLevel: String {
        card.statHeaders.contains(selectedStatLevel) ? selectedStatLevel : card.statHeaders.last ?? ""
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 12) {
                header

                Text(card.description.ifBlank(String(localized: "ba.student.detail.weapon.description.empty")))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if card.imageURL != nil {
                    BaPlainRemoteImage(
                        url: card.imageURL,
                        fallbackSystemImage: "scope",
                        tint: tint,
                        height: 116
                    )
                    .padding(.top, 2)
                }

                if card.statRows.isEmpty == false {
                    statBlock
                        .padding(.top, 2)
                }

                if card.starEffects.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(card.starEffects) { effect in
                            BaStudentWeaponStarEffectCard(
                                effect: effect,
                                glossaryIcons: card.glossaryIcons,
                                tint: tint
                            )
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .onChange(of: card.id) { _, _ in
            selectedStatLevel = card.statHeaders.last ?? ""
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(card.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 8)

            Text(String(localized: "ba.student.detail.weapon.short"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(tint.opacity(0.09), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 1)
                }
        }
    }

    private var statBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(String(localized: "ba.student.detail.weapon.stats"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if card.statHeaders.isEmpty == false {
                    Menu {
                        ForEach(card.statHeaders, id: \.self) { level in
                            Button {
                                selectedStatLevel = level
                            } label: {
                                if level == statLevel {
                                    Label(level, systemImage: "checkmark")
                                } else {
                                    Text(level)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(statLevel)
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
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(card.statRows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(row.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer(minLength: 12)
                        Text(value(for: row))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
            }
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18, tint: tint.opacity(0.045), isInteractive: false)
    }

    private func value(for row: BaStudentWeaponStatRow) -> String {
        guard row.values.isEmpty == false else {
            return "-"
        }
        guard card.statHeaders.isEmpty == false else {
            return row.values.joined(separator: " / ")
        }
        let index = max(card.statHeaders.firstIndex(of: statLevel) ?? 0, 0)
        return row.values.indices.contains(index) ? row.values[index] : row.values.last ?? "-"
    }
}

private struct BaStudentWeaponStarEffectCard: View {
    let effect: BaStudentWeaponStarEffect
    let glossaryIcons: [String: URL]
    let tint: Color

    @State private var selectedLevel: String

    init(effect: BaStudentWeaponStarEffect, glossaryIcons: [String: URL], tint: Color) {
        self.effect = effect
        self.glossaryIcons = glossaryIcons
        self.tint = tint
        _selectedLevel = State(initialValue: effect.defaultLevel)
    }

    private var displayLevel: String {
        effect.levelOptions.contains(selectedLevel) ? selectedLevel : effect.defaultLevel
    }

    private var description: String {
        effect.description(for: displayLevel).ifBlank(String(localized: "ba.student.detail.weapon.effect.empty"))
    }

    private var hasDescription: Bool {
        effect.description(for: displayLevel).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                BaWeaponStarBadgeRow(starLabel: effect.starLabel, iconSize: 18)

                if let iconURL = effect.iconURL {
                    BaRemoteIconSurface(
                        url: iconURL,
                        fallbackSystemImage: BaStudentDetailSection.skills.systemImage,
                        tint: tint,
                        size: 28,
                        fallbackFont: .caption.weight(.semibold)
                    )
                }

                Text(effect.name.ifBlank(String(localized: "ba.student.detail.weapon.effect")))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)
            }

            if hasDescription || effect.roleTag.isEmpty == false || effect.levelOptions.isEmpty == false {
                HStack(alignment: .top, spacing: 8) {
                    if hasDescription {
                        BaStudentSkillDescriptionView(
                            description: description,
                            glossaryIcons: glossaryIcons,
                            descriptionIcons: effect.descriptionIcons(for: displayLevel),
                            tint: tint
                        )
                    }

                    VStack(alignment: .trailing, spacing: 7) {
                        if effect.roleTag.isEmpty == false {
                            Text(effect.roleTag)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(tint)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(tint.opacity(0.09), in: Capsule())
                                .overlay {
                                    Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 1)
                                }
                        }

                        if effect.levelOptions.isEmpty == false {
                            Menu {
                                ForEach(effect.levelOptions, id: \.self) { level in
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
                    }
                }
            }
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18, tint: tint.opacity(0.045), isInteractive: false)
        .onChange(of: effect.id) { _, _ in
            selectedLevel = effect.defaultLevel
        }
    }
}

private struct BaWeaponStarBadgeRow: View {
    let starLabel: String
    let iconSize: CGFloat

    private var count: Int {
        guard let range = starLabel.range(of: #"\d{1,2}"#, options: .regularExpression) else {
            return 0
        }
        return Int(starLabel[range]) ?? 0
    }

    var body: some View {
        HStack(spacing: 2) {
            if count > 0 {
                ForEach(0 ..< min(count, 5), id: \.self) { _ in
                    BaGameAssetIcon(.weaponStarBadge, size: iconSize)
                }
            } else {
                Text(starLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BaDesign.pink)
            }
        }
        .accessibilityLabel(starLabel)
    }
}

private struct BaPlainRemoteImage: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baShowPreviewImages) private var showPreviewImages

    let url: URL?
    let fallbackSystemImage: String
    let tint: Color
    let height: CGFloat

    @State private var phase: Phase = .placeholder

    var body: some View {
        ZStack {
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: height)
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, minHeight: height)
            case .failed:
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: height)
            case .hidden, .placeholder:
                Image(systemName: fallbackSystemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, minHeight: height)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height)
        .task(id: cacheTaskID) {
            await loadImage()
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(showPreviewImages)"
    }

    private func loadImage() async {
        guard showPreviewImages, let url else {
            phase = showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        guard let data = try? await model.imageData(for: url) else {
            if Task.isCancelled == false {
                phase = .failed
            }
            return
        }
        guard Task.isCancelled == false else { return }
        let image = await Task.detached(priority: .utility) {
            BaRemoteImageSurface.image(from: data, maxPixelDimension: 720)
        }.value
        guard Task.isCancelled == false else { return }
        guard let image else {
            phase = .failed
            return
        }
        phase = .success(image)
    }

    private enum Phase {
        case placeholder
        case loading
        case success(Image)
        case failed
        case hidden
    }
}

private extension View {
    func baStudentWeaponListCardRow() -> some View {
        baAdaptiveListCardRow(top: 8, bottom: 10)
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
