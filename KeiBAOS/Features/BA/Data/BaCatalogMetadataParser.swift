//
//  BaCatalogMetadataParser.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

enum BaCatalogMetadataParser {
    nonisolated static func parseFilterGroups(data: Data) throws -> [BaCatalogFilterGroup] {
        let dataObject = try GameKeeJSON.dataObject(from: data)
        let rows = dataObject["entry_filter"] as? [BaJSONObject] ?? []
        return rows.compactMap { row in
            guard let id = row.int("id"),
                  let title = clean(row.string("name") ?? row.string("title")),
                  let kind = BaCatalogFilterKind(groupID: id, title: title)
            else {
                return nil
            }
            let options = optionRows(from: row).compactMap { option -> BaCatalogFilterOption? in
                guard let optionID = option.int("id"),
                      let optionTitle = clean(option.string("name") ?? option.string("title"))
                else {
                    return nil
                }
                return BaCatalogFilterOption(
                    id: optionID,
                    title: optionTitle,
                    iconURL: GameKeeJSON.normalizeImageURL(option.string("icon") ?? "")
                )
            }
            guard options.isEmpty == false else { return nil }
            return BaCatalogFilterGroup(id: id, title: title, kind: kind, options: options)
        }
    }

    nonisolated static func parseStudentMetadata(
        data: Data,
        filterGroups: [BaCatalogFilterGroup]
    ) throws -> [Int64: BaGuideCatalogMetadata] {
        let rows = try GameKeeJSON.dataArray(from: data)
        var result: [Int64: BaGuideCatalogMetadata] = [:]
        result.reserveCapacity(rows.count)
        for row in rows {
            guard let item = row.object("ba"),
                  let contentID = item.int64("content_id"),
                  let metadata = metadata(from: item, filterGroups: filterGroups)
            else {
                continue
            }
            result[contentID] = metadata
        }
        return result
    }

    nonisolated static func metadata(from info: BaStudentGuideInfo) -> BaGuideCatalogMetadata? {
        var metadata = BaGuideCatalogMetadata()
        for row in info.profileRows + info.stats {
            apply(row: row, to: &metadata)
        }
        return metadata.isEffectivelyEmpty ? nil : metadata
    }

    private nonisolated static func metadata(
        from item: BaJSONObject,
        filterGroups: [BaCatalogFilterGroup]
    ) -> BaGuideCatalogMetadata? {
        let metadata = BaGuideCatalogMetadata(
            rarity: clean(item.string("level")),
            availability: clean(item.string("is_limit")),
            attackType: value(from: item.string("gj"), kind: .attackType, filterGroups: filterGroups),
            defenseType: value(from: item.string("fy"), kind: .defenseType, filterGroups: filterGroups),
            squadPosition: value(from: item.string("zszy"), kind: .squadPosition, filterGroups: filterGroups),
            combatRole: clean(item.string("zy")),
            rangePosition: value(from: item.string("wz"), kind: .rangePosition, filterGroups: filterGroups),
            weaponType: clean(item.string("wq")),
            terrainStreet: clean(item.string("sj")),
            terrainOutdoor: clean(item.string("sw")),
            terrainIndoor: clean(item.string("sn")),
            coverInteraction: clean(item.string("cover") ?? item.string("yt") ?? item.string("cover_interaction")),
            school: clean(item.string("xy")),
            club: cleanClub(item.string("st")),
            globalRating: clean(item.string("zbw")),
            cnRating: clean(item.string("jspf"))
        )
        return metadata.isEffectivelyEmpty ? nil : metadata
    }

    private nonisolated static func apply(row: BaGuideRow, to metadata: inout BaGuideCatalogMetadata) {
        let key = BaCatalogFilterMatcher.normalized(row.title)
        let value = clean(row.value)
        guard let value else { return }

        if key.contains("稀有度") || key.contains("星级") {
            fill(\.rarity, with: value, in: &metadata)
        } else if key.contains("限定") || key.contains("常驻") {
            fill(\.availability, with: value, in: &metadata)
        } else if key.contains("攻击类型") {
            fill(\.attackType, with: value, in: &metadata)
        } else if key.contains("防御类型") {
            fill(\.defenseType, with: value, in: &metadata)
        } else if key.contains("战术位置") || key.contains("编队位置") {
            applyTacticalValue(value, to: &metadata)
        } else if key.contains("战斗职责") || key.contains("战术作用") || key == "作用" {
            fill(\.combatRole, with: value, in: &metadata)
        } else if key.contains("站位") || key.contains("前后") {
            fill(\.rangePosition, with: value, in: &metadata)
        } else if key.contains("武器") {
            fill(\.weaponType, with: value, in: &metadata)
        } else if key.contains("市街") {
            fill(\.terrainStreet, with: value, in: &metadata)
        } else if key.contains("室外") || key.contains("屋外") {
            fill(\.terrainOutdoor, with: value, in: &metadata)
        } else if key.contains("室内") || key.contains("屋内") {
            fill(\.terrainIndoor, with: value, in: &metadata)
        } else if key.contains("掩体") {
            fill(\.coverInteraction, with: value, in: &metadata)
        } else if key.contains("社团") {
            fill(\.club, with: cleanClub(value), in: &metadata)
        } else if key.contains("学校") || key.contains("学院") || key.contains("学园") {
            fill(\.school, with: value, in: &metadata)
        } else if key.contains("外服") || key.contains("日服") || key.contains("国际服") {
            fill(\.globalRating, with: value, in: &metadata)
        } else if key.contains("国服") {
            fill(\.cnRating, with: value, in: &metadata)
        }
    }

    private nonisolated static func applyTacticalValue(_ value: String, to metadata: inout BaGuideCatalogMetadata) {
        let key = BaCatalogFilterMatcher.normalized(value)
        if key.contains("striker") || key.contains("突击") {
            fill(\.squadPosition, with: "Striker（突击）", in: &metadata)
        } else if key.contains("special") || key.contains("支援") {
            fill(\.squadPosition, with: "Special（支援）", in: &metadata)
        }

        if key.contains("front") || key.contains("前排") {
            fill(\.rangePosition, with: "Front（前排）", in: &metadata)
        } else if key.contains("middle") || key.contains("中坚") {
            fill(\.rangePosition, with: "Middle（中坚）", in: &metadata)
        } else if key.contains("back") || key.contains("后排") {
            fill(\.rangePosition, with: "Back（后排）", in: &metadata)
        }

        for role in ["输出", "坦克", "治疗", "辅助", "T.S"] where key.contains(BaCatalogFilterMatcher.normalized(role)) {
            fill(\.combatRole, with: role, in: &metadata)
        }
    }

    private nonisolated static func value(
        from raw: String?,
        kind: BaCatalogFilterKind,
        filterGroups: [BaCatalogFilterGroup]
    ) -> String? {
        guard let raw = clean(raw) else { return nil }
        guard let url = GameKeeJSON.normalizeImageURL(raw), raw.contains("/") else {
            return raw
        }
        guard let group = filterGroups.first(where: { $0.kind == kind }) else {
            return nil
        }
        let urlKey = imageURLKey(url)
        return group.options.first { option in
            guard let iconURL = option.iconURL else { return false }
            return imageURLKey(iconURL) == urlKey
        }?.title
    }

    private nonisolated static func optionRows(from row: BaJSONObject) -> [BaJSONObject] {
        if let rows = row["children"] as? [BaJSONObject], rows.isEmpty == false { return rows }
        if let rows = row["child"] as? [BaJSONObject], rows.isEmpty == false { return rows }
        if let rows = row["values"] as? [BaJSONObject], rows.isEmpty == false { return rows }
        if let rows = row["options"] as? [BaJSONObject], rows.isEmpty == false { return rows }
        return []
    }

    private nonisolated static func fill(
        _ keyPath: WritableKeyPath<BaGuideCatalogMetadata, String?>,
        with value: String?,
        in metadata: inout BaGuideCatalogMetadata
    ) {
        guard metadata[keyPath: keyPath] == nil, let value else { return }
        metadata[keyPath: keyPath] = value
    }

    private nonisolated static func cleanClub(_ raw: String?) -> String? {
        guard let value = clean(raw) else { return nil }
        let key = BaCatalogFilterMatcher.normalized(value)
        guard key != "社团", key.contains("占位符") == false else { return nil }
        return value
    }

    private nonisolated static func clean(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = GameKeeJSON.extractPlainText(from: raw)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return nil }
        let key = BaCatalogFilterMatcher.normalized(value)
        guard key.isEmpty == false, key.contains("占位符") == false else { return nil }
        return value
    }

    private nonisolated static func imageURLKey(_ url: URL) -> String {
        url.lastPathComponent.lowercased()
    }
}

private extension BaGuideCatalogMetadata {
    nonisolated var isEffectivelyEmpty: Bool {
        [
            rarity,
            availability,
            attackType,
            defenseType,
            squadPosition,
            combatRole,
            rangePosition,
            weaponType,
            terrainStreet,
            terrainOutdoor,
            terrainIndoor,
            coverInteraction,
            school,
            club,
            globalRating,
            cnRating,
        ].allSatisfy { $0 == nil }
    }
}
