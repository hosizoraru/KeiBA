//
//  BaStudentSimulationCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

struct BaStudentSimulationCardsSection: View {
    let tint: Color
    private let data: BaStudentSimulationData

    init(rows: [BaGuideRow], tint: Color) {
        self.tint = tint
        self.data = BaStudentSimulationDisplayModel.build(rows: rows)
    }

    var body: some View {
        Section {
            if data.hasRenderableContent == false {
                BaStudentDetailEmptyRow(section: .simulate)
                    .baStudentDetailListCardRow()
            } else {
                BaStudentSimulationAbilityCard(data: data, tint: tint)
                    .baStudentDetailListCardRow()

                BaStudentSimulationWeaponCard(
                    title: BaStudentSimulationSectionName.weapon.rawValue,
                    rows: data.weaponRows,
                    hint: data.weaponHint,
                    tint: tint
                )
                .baStudentDetailListCardRow()

                BaStudentSimulationEquipmentCard(
                    title: BaStudentSimulationSectionName.equipment.rawValue,
                    rows: data.equipmentRows,
                    hint: data.equipmentHint,
                    tint: tint
                )
                .baStudentDetailListCardRow()

                BaStudentSimulationGenericCard(
                    title: BaStudentSimulationSectionName.favorite.rawValue,
                    rows: data.favoriteRows,
                    hint: data.favoriteHint,
                    emptyText: String(localized: "ba.common.none"),
                    tint: tint
                )
                .baStudentDetailListCardRow()

                BaStudentSimulationUnlockCard(
                    title: BaStudentSimulationSectionName.unlock.rawValue,
                    rows: data.unlockRows,
                    hint: data.unlockHint,
                    tint: tint
                )
                .baStudentDetailListCardRow()

                BaStudentSimulationBondCard(
                    title: BaStudentSimulationSectionName.bond.rawValue,
                    rows: data.bondRows,
                    hint: data.bondHint,
                    tint: tint
                )
                .baStudentDetailListCardRow()
            }
        }
    }
}

private struct BaStudentSimulationAbilityCard: View {
    let data: BaStudentSimulationData
    let tint: Color
    private let initialValueByKey: [String: String]

    @State private var mode: BaStudentSimulationAbilityMode = .maximum

    init(data: BaStudentSimulationData, tint: Color) {
        self.data = data
        self.tint = tint
        self.initialValueByKey = Self.initialValuesByKey(from: data.initialRows)
    }

    private var selectedRows: [BaGuideRow] {
        switch mode {
        case .initial:
            data.initialRows
        case .maximum:
            data.maximumRows
        }
    }

    private var selectedHint: String {
        switch mode {
        case .initial:
            data.initialHint
        case .maximum:
            data.maximumHint
        }
    }

    private static func initialValuesByKey(from rows: [BaGuideRow]) -> [String: String] {
        var values: [String: String] = [:]
        for row in rows {
            let key = BaGuideTextNormalizer.normalizedKey(row.title)
            let value = row.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty == false, value.isEmpty == false, values[key] == nil {
                values[key] = value
            }
        }
        return values
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Text(String(localized: "ba.student.detail.simulate.ability.title"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Picker(String(localized: "ba.student.detail.page.simulate"), selection: $mode) {
                        ForEach(BaStudentSimulationAbilityMode.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 260)
                }

                if selectedHint.isEmpty == false {
                    Text(selectedHint)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(tint)
                        .lineLimit(2)
                }

                if selectedRows.isEmpty {
                    Text(String(localized: "ba.common.none"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(selectedRows.prefix(28)) { row in
                            let delta = mode == .maximum
                                ? BaStudentSimulationDisplayModel.maxDeltaText(
                                    maxValue: row.value,
                                    initialValue: initialValueByKey[BaGuideTextNormalizer.normalizedKey(row.title)]
                                )
                                : ""
                            BaStudentSimulationRowItem(row: row, tint: tint, valueDelta: delta)
                        }
                    }
                }
            }
        }
    }
}

private struct BaStudentSimulationWeaponCard: View {
    let title: String
    let rows: [BaGuideRow]
    let hint: String
    let tint: Color

    private var viewData: BaStudentSimulationWeaponViewData {
        BaStudentSimulationDisplayModel.weaponViewData(rows: rows)
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentSimulationCardTitleRow(
                    title: title,
                    capsule: BaStudentSimulationDisplayModel.levelCapsule(from: hint),
                    tint: tint
                )

                if viewData.imageURL != nil || viewData.statRows.isEmpty == false {
                    HStack(alignment: .top, spacing: 12) {
                        if let imageURL = viewData.imageURL {
                            BaRemoteImageSurface(
                                url: imageURL,
                                fallbackSystemImage: "scope",
                                tint: tint,
                                width: 112,
                                height: 76,
                                cornerRadius: 18,
                                contentMode: .fit
                            )
                        }

                        VStack(spacing: 10) {
                            ForEach(viewData.statRows.prefix(18)) { row in
                                BaStudentSimulationRowItem(row: row, tint: tint)
                            }
                        }
                    }
                } else {
                    BaStudentSimulationEmptyText()
                }
            }
        }
    }
}

private struct BaStudentSimulationEquipmentCard: View {
    let title: String
    let rows: [BaGuideRow]
    let hint: String
    let tint: Color

    private var groups: [BaStudentSimulationEquipmentGroup] {
        BaStudentSimulationDisplayModel.equipmentGroups(from: rows)
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentSimulationCardTitleRow(
                    title: title,
                    capsule: BaStudentSimulationDisplayModel.levelCapsule(from: hint),
                    tint: tint
                )

                if groups.isEmpty == false {
                    VStack(spacing: 16) {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    if let iconURL = group.iconURL {
                                        BaRemoteImageSurface(
                                            url: iconURL,
                                            fallbackSystemImage: "shippingbox",
                                            tint: tint,
                                            width: 42,
                                            height: 42,
                                            cornerRadius: 12,
                                            contentMode: .fit
                                        )
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(group.itemName.ifBlank(group.slotLabel))
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)

                                        if group.tierText.isEmpty == false {
                                            Text(group.tierText)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer(minLength: 8)
                                    BaStudentSimulationCapsule(text: group.slotLabel, tint: tint)
                                }

                                ForEach(group.statRows.prefix(8)) { row in
                                    BaStudentSimulationRowItem(row: row, tint: tint)
                                }
                            }
                        }
                    }
                } else if rows.isEmpty == false {
                    VStack(spacing: 10) {
                        ForEach(rows.prefix(18)) { row in
                            BaStudentSimulationRowItem(row: row, tint: tint)
                        }
                    }
                } else {
                    BaStudentSimulationEmptyText()
                }
            }
        }
    }
}

private struct BaStudentSimulationUnlockCard: View {
    let title: String
    let rows: [BaGuideRow]
    let hint: String
    let tint: Color

    private var viewData: BaStudentSimulationUnlockViewData {
        BaStudentSimulationDisplayModel.unlockViewData(rows: rows, hint: hint)
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentSimulationCardTitleRow(title: title, capsule: viewData.levelCapsule, tint: tint)

                if viewData.rows.isEmpty {
                    BaStudentSimulationEmptyText()
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewData.rows.prefix(18)) { row in
                            if let iconURL = BaStudentSimulationDisplayModel.primaryImageURL(row) {
                                HStack(alignment: .center, spacing: 12) {
                                    BaRemoteImageSurface(
                                        url: iconURL,
                                        fallbackSystemImage: "square.grid.2x2",
                                        tint: tint,
                                        width: 78,
                                        height: 62,
                                        cornerRadius: 16,
                                        contentMode: .fit
                                    )
                                    BaStudentSimulationRowItem(row: row.removingSimulationImages(), tint: tint)
                                }
                            } else {
                                BaStudentSimulationRowItem(row: row, tint: tint)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct BaStudentSimulationBondCard: View {
    let title: String
    let rows: [BaGuideRow]
    let hint: String
    let tint: Color

    private var groups: [BaStudentSimulationBondGroup] {
        BaStudentSimulationDisplayModel.bondGroups(from: rows)
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentSimulationCardTitleRow(
                    title: title,
                    capsule: BaStudentSimulationDisplayModel.levelCapsule(from: hint),
                    tint: tint
                )

                if groups.isEmpty {
                    BaStudentSimulationEmptyText()
                } else {
                    VStack(spacing: 16) {
                        ForEach(groups) { group in
                            HStack(alignment: .top, spacing: 12) {
                                if let iconURL = group.iconURL {
                                    BaRemoteImageSurface(
                                        url: iconURL,
                                        fallbackSystemImage: "person.crop.square",
                                        tint: tint,
                                        width: 104,
                                        height: 86,
                                        cornerRadius: 18,
                                        contentMode: .fit
                                    )
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.roleLabel)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    ForEach(group.statRows.prefix(8)) { row in
                                        BaStudentSimulationRowItem(row: row, tint: tint)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct BaStudentSimulationGenericCard: View {
    let title: String
    let rows: [BaGuideRow]
    let hint: String
    let emptyText: String
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentSimulationCardTitleRow(
                    title: title,
                    capsule: BaStudentSimulationDisplayModel.levelCapsule(from: hint),
                    tint: tint
                )

                if rows.isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(rows.prefix(18)) { row in
                            BaStudentSimulationRowItem(row: row, tint: tint)
                        }
                    }
                }
            }
        }
    }
}

private struct BaStudentSimulationCardTitleRow: View {
    let title: String
    let capsule: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            if capsule.isEmpty == false {
                BaStudentSimulationCapsule(text: capsule, tint: tint)
            }
        }
    }
}

private struct BaStudentSimulationCapsule: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .liquidGlassSurface(cornerRadius: 999, tint: tint.opacity(0.1), isInteractive: false)
    }
}

private struct BaStudentSimulationRowItem: View {
    let row: BaGuideRow
    let tint: Color
    var valueDelta = ""

    private var iconURL: URL? {
        BaStudentSimulationDisplayModel.primaryImageURL(row)
    }

    private var value: String {
        row.value.trimmingCharacters(in: .whitespacesAndNewlines).ifBlank(String(localized: "ba.common.none"))
    }

    var body: some View {
        if BaStudentSimulationDisplayModel.isSubHeader(row.title) {
            HStack(spacing: 8) {
                if let iconURL {
                    BaRemoteImageSurface(
                        url: iconURL,
                        fallbackSystemImage: "square.grid.2x2",
                        tint: tint,
                        width: 24,
                        height: 24,
                        cornerRadius: 7,
                        contentMode: .fit
                    )
                }
                BaStudentSimulationCapsule(text: row.title, tint: tint)
                Spacer(minLength: 0)
            }
        } else {
            HStack(alignment: .center, spacing: 10) {
                if let iconURL {
                    BaRemoteImageSurface(
                        url: iconURL,
                        fallbackSystemImage: "square.grid.2x2",
                        tint: tint,
                        width: 24,
                        height: 24,
                        cornerRadius: 7,
                        contentMode: .fit
                    )
                } else {
                    Image(systemName: BaStudentSimulationDisplayModel.statSystemImage(for: row.title))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }

                Text(row.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 10)

                HStack(spacing: 6) {
                    Text(value)
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(valueColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.72)

                    if valueDelta.isEmpty == false {
                        Text(valueDelta)
                            .font(.body.monospacedDigit().weight(.semibold))
                            .foregroundStyle(BaDesign.amber)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var valueColor: Color {
        if value.contains("%") || value.contains("％") { return tint }
        if value.range(of: #"(?i)^T\d+"#, options: .regularExpression) != nil { return tint }
        if value.range(of: #"(?i)^Lv\d+"#, options: .regularExpression) != nil { return tint }
        if row.title.localizedCaseInsensitiveContains("COST") { return tint }
        return .primary
    }
}

private struct BaStudentSimulationEmptyText: View {
    var body: some View {
        Text(String(localized: "ba.common.none"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum BaStudentSimulationAbilityMode: String, CaseIterable, Identifiable {
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

private extension BaGuideRow {
    func removingSimulationImages() -> BaGuideRow {
        BaGuideRow(id: id, title: title, value: value, imageURL: nil, imageURLs: nil)
    }
}
