//
//  BaCatalogFilterModels.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated enum BaCatalogFilterKind: String, CaseIterable, Codable, Hashable, Sendable {
    case rarity
    case availability
    case attackType
    case defenseType
    case squadPosition
    case combatRole
    case rangePosition
    case weaponType
    case terrainStreet
    case terrainOutdoor
    case terrainIndoor
    case coverInteraction
    case school
    case club
    case globalRating
    case cnRating

    init?(groupID: Int, title: String) {
        switch groupID {
        case 68:
            self = .rarity
        case 508:
            self = .availability
        case 72:
            self = .attackType
        case 1608:
            self = .defenseType
        case 167:
            self = .squadPosition
        case 177:
            self = .combatRole
        case 183:
            self = .rangePosition
        case 188:
            self = .weaponType
        case 199:
            self = .terrainStreet
        case 204:
            self = .terrainOutdoor
        case 212:
            self = .terrainIndoor
        case 11520:
            self = .coverInteraction
        case 218:
            self = .school
        case 514:
            self = .club
        case 11543:
            self = .globalRating
        case 13045:
            self = .cnRating
        default:
            let key = BaCatalogFilterMatcher.normalized(title)
            switch key {
            case let value where value.contains("星级"):
                self = .rarity
            case let value where value.contains("限定") || value.contains("常驻"):
                self = .availability
            case let value where value.contains("攻击类型"):
                self = .attackType
            case let value where value.contains("防御类型"):
                self = .defenseType
            case let value where value.contains("编队位置"):
                self = .squadPosition
            case let value where value.contains("战斗职责"):
                self = .combatRole
            case let value where value.contains("站位前后"):
                self = .rangePosition
            case let value where value.contains("武器"):
                self = .weaponType
            case let value where value.contains("市街"):
                self = .terrainStreet
            case let value where value.contains("室外") || value.contains("屋外"):
                self = .terrainOutdoor
            case let value where value.contains("室内") || value.contains("屋内"):
                self = .terrainIndoor
            case let value where value.contains("掩体"):
                self = .coverInteraction
            case let value where value.contains("学校") || value.contains("学院") || value.contains("学园"):
                self = .school
            case let value where value.contains("社团"):
                self = .club
            case let value where value.contains("外服"):
                self = .globalRating
            case let value where value.contains("国服"):
                self = .cnRating
            default:
                return nil
            }
        }
    }
}

nonisolated struct BaCatalogFilterOption: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String
    let iconURL: URL?
}

nonisolated struct BaCatalogFilterGroup: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String
    let kind: BaCatalogFilterKind
    let options: [BaCatalogFilterOption]
}

nonisolated struct BaGuideCatalogMetadata: Codable, Hashable, Sendable {
    var rarity: String? = nil
    var availability: String? = nil
    var attackType: String? = nil
    var defenseType: String? = nil
    var squadPosition: String? = nil
    var combatRole: String? = nil
    var rangePosition: String? = nil
    var weaponType: String? = nil
    var terrainStreet: String? = nil
    var terrainOutdoor: String? = nil
    var terrainIndoor: String? = nil
    var coverInteraction: String? = nil
    var school: String? = nil
    var club: String? = nil
    var globalRating: String? = nil
    var cnRating: String? = nil
    var filterOptionIDsByKind: [BaCatalogFilterKind: Set<Int>] = [:]

    var needsDetailHydration: Bool {
        attackType == nil ||
            defenseType == nil ||
            squadPosition == nil ||
            rangePosition == nil ||
            school == nil ||
            club == nil
    }

    func value(for kind: BaCatalogFilterKind) -> String? {
        switch kind {
        case .rarity:
            rarity
        case .availability:
            availability
        case .attackType:
            attackType
        case .defenseType:
            defenseType
        case .squadPosition:
            squadPosition
        case .combatRole:
            combatRole
        case .rangePosition:
            rangePosition
        case .weaponType:
            weaponType
        case .terrainStreet:
            terrainStreet
        case .terrainOutdoor:
            terrainOutdoor
        case .terrainIndoor:
            terrainIndoor
        case .coverInteraction:
            coverInteraction
        case .school:
            school
        case .club:
            club
        case .globalRating:
            globalRating
        case .cnRating:
            cnRating
        }
    }

    func matches(option: BaCatalogFilterOption, kind: BaCatalogFilterKind) -> Bool {
        if let optionIDs = filterOptionIDsByKind[kind], optionIDs.isEmpty == false {
            return optionIDs.contains(option.id)
        }
        guard let value = value(for: kind) else { return false }
        return BaCatalogFilterMatcher.matches(value: value, optionTitle: option.title, kind: kind)
    }

    func mergingMissingFields(with patch: BaGuideCatalogMetadata) -> BaGuideCatalogMetadata {
        BaGuideCatalogMetadata(
            rarity: rarity ?? patch.rarity,
            availability: availability ?? patch.availability,
            attackType: attackType ?? patch.attackType,
            defenseType: defenseType ?? patch.defenseType,
            squadPosition: squadPosition ?? patch.squadPosition,
            combatRole: combatRole ?? patch.combatRole,
            rangePosition: rangePosition ?? patch.rangePosition,
            weaponType: weaponType ?? patch.weaponType,
            terrainStreet: terrainStreet ?? patch.terrainStreet,
            terrainOutdoor: terrainOutdoor ?? patch.terrainOutdoor,
            terrainIndoor: terrainIndoor ?? patch.terrainIndoor,
            coverInteraction: coverInteraction ?? patch.coverInteraction,
            school: school ?? patch.school,
            club: club ?? patch.club,
            globalRating: globalRating ?? patch.globalRating,
            cnRating: cnRating ?? patch.cnRating,
            filterOptionIDsByKind: filterOptionIDsByKind.mergingOptionIDs(with: patch.filterOptionIDsByKind)
        )
    }
}

private extension Dictionary where Key == BaCatalogFilterKind, Value == Set<Int> {
    nonisolated func mergingOptionIDs(with patch: [BaCatalogFilterKind: Set<Int>]) -> [BaCatalogFilterKind: Set<Int>] {
        var result = self
        for (kind, optionIDs) in patch where optionIDs.isEmpty == false {
            result[kind, default: []].formUnion(optionIDs)
        }
        return result
    }
}

nonisolated struct BaCatalogFilterSelection: Hashable, Sendable {
    var selectedOptionIDsByKind: [BaCatalogFilterKind: Set<Int>]

    init(selectedOptionIDsByKind: [BaCatalogFilterKind: Set<Int>] = [:]) {
        self.selectedOptionIDsByKind = selectedOptionIDsByKind.filter { $0.value.isEmpty == false }
    }

    static let empty = BaCatalogFilterSelection()

    var isEmpty: Bool {
        selectedOptionIDsByKind.values.allSatisfy(\.isEmpty)
    }

    var activeFilterCount: Int {
        selectedOptionIDsByKind.values.reduce(0) { $0 + $1.count }
    }

    mutating func clear() {
        selectedOptionIDsByKind.removeAll()
    }

    mutating func toggle(_ option: BaCatalogFilterOption, in group: BaCatalogFilterGroup) {
        var optionIDs = selectedOptionIDsByKind[group.kind, default: []]
        if optionIDs.contains(option.id) {
            optionIDs.remove(option.id)
        } else {
            optionIDs.insert(option.id)
        }
        if optionIDs.isEmpty {
            selectedOptionIDsByKind.removeValue(forKey: group.kind)
        } else {
            selectedOptionIDsByKind[group.kind] = optionIDs
        }
    }

    func isSelected(_ option: BaCatalogFilterOption, in group: BaCatalogFilterGroup) -> Bool {
        selectedOptionIDsByKind[group.kind]?.contains(option.id) == true
    }

    func selectedOptions(in group: BaCatalogFilterGroup) -> [BaCatalogFilterOption] {
        guard let optionIDs = selectedOptionIDsByKind[group.kind], optionIDs.isEmpty == false else {
            return []
        }
        return group.options.filter { optionIDs.contains($0.id) }
    }

    func matches(_ entry: BaGuideCatalogEntry, groups: [BaCatalogFilterGroup]) -> Bool {
        BaCatalogFilterPlan(selection: self, groups: groups).matches(entry)
    }
}

nonisolated struct BaCatalogFilterPlan: Hashable, Sendable {
    private let selectedOptionsByKind: [BaCatalogFilterKind: [BaCatalogFilterOption]]
    private let rejectsAllEntries: Bool

    init(selection: BaCatalogFilterSelection, groups: [BaCatalogFilterGroup]) {
        guard selection.isEmpty == false else {
            selectedOptionsByKind = [:]
            rejectsAllEntries = false
            return
        }

        var groupsByKind: [BaCatalogFilterKind: BaCatalogFilterGroup] = [:]
        groupsByKind.reserveCapacity(groups.count)
        for group in groups where groupsByKind[group.kind] == nil {
            groupsByKind[group.kind] = group
        }

        var nextSelectedOptions: [BaCatalogFilterKind: [BaCatalogFilterOption]] = [:]
        nextSelectedOptions.reserveCapacity(selection.selectedOptionIDsByKind.count)
        var foundInvalidSelection = false
        for (kind, optionIDs) in selection.selectedOptionIDsByKind where optionIDs.isEmpty == false {
            guard let group = groupsByKind[kind] else {
                foundInvalidSelection = true
                continue
            }
            let selectedOptions = group.options.filter { optionIDs.contains($0.id) }
            guard selectedOptions.isEmpty == false else {
                foundInvalidSelection = true
                continue
            }
            nextSelectedOptions[kind] = selectedOptions
        }
        selectedOptionsByKind = nextSelectedOptions
        rejectsAllEntries = foundInvalidSelection
    }

    var isEmpty: Bool {
        rejectsAllEntries == false && selectedOptionsByKind.isEmpty
    }

    func matches(_ entry: BaGuideCatalogEntry) -> Bool {
        guard isEmpty == false else { return true }
        guard rejectsAllEntries == false else { return false }
        guard let metadata = entry.metadata else { return false }
        for (kind, selectedOptions) in selectedOptionsByKind {
            guard selectedOptions.contains(where: { metadata.matches(option: $0, kind: kind) }) else {
                return false
            }
        }
        return true
    }
}

enum BaCatalogFilterMatcher {
    nonisolated static func matches(
        value: String,
        optionTitle: String,
        kind: BaCatalogFilterKind
    ) -> Bool {
        let valueKey = normalized(value)
        let optionKey = normalized(optionTitle)
        guard valueKey.isEmpty == false, optionKey.isEmpty == false else { return false }

        if valueKey == optionKey || valueKey.contains(optionKey) || optionKey.contains(valueKey) {
            return true
        }

        switch kind {
        case .rarity:
            return rarityRank(valueKey) == rarityRank(optionKey)
        case .weaponType:
            guard let weaponCode = weaponCode(from: optionKey) else { return false }
            return valueKey == weaponCode || valueKey.contains(weaponCode)
        case .terrainStreet, .terrainOutdoor, .terrainIndoor:
            return terrainGrade(valueKey) == terrainGrade(optionKey)
        case .globalRating, .cnRating:
            return ratingToken(valueKey) == ratingToken(optionKey)
        default:
            return false
        }
    }

    nonisolated static func normalized(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "+", with: "plus")
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .joined()
            .lowercased()
    }

    private nonisolated static func rarityRank(_ value: String) -> Int? {
        if value.contains("三星") || value.contains("3星") { return 3 }
        if value.contains("二星") || value.contains("2星") { return 2 }
        if value.contains("一星") || value.contains("1星") { return 1 }
        return nil
    }

    private nonisolated static func weaponCode(from optionKey: String) -> String? {
        let codes = ["dualsg", "smg", "ar", "gl", "hg", "rl", "sr", "rg", "mg", "mt", "sg", "ft"]
        return codes.first { optionKey.hasSuffix($0) || optionKey.contains($0) }
    }

    private nonisolated static func terrainGrade(_ value: String) -> String? {
        ["ss", "s", "a", "b", "c", "d"].first { value == $0 || value.hasPrefix($0) }
    }

    private nonisolated static func ratingToken(_ value: String) -> String? {
        let key = value.replacingOccurrences(of: "plus", with: "+")
        if key.contains("100") { return "ss" }
        if key.contains("90+") { return "s" }
        if key.contains("80+") { return "a" }
        if key.contains("70+") { return "b" }
        if key.contains("60+") { return "c" }
        if key.contains("50+") { return "d" }
        if key.contains("40+") { return "e" }
        if key.contains("20+") { return "f" }
        return ["ss", "s", "a", "b", "c", "d", "e", "f"].first { key == $0 || key.contains($0) }
    }
}
