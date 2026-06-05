//
//  BaStudentDetailPageAvailability.swift
//  KeiBA
//
//  Created by Codex on 2026/05/16.
//

import Foundation

nonisolated enum BaStudentDetailPageAvailability {
    static func pages(
        category: BaCatalogCategory,
        info: BaStudentGuideInfo?
    ) -> [BaStudentDetailPage] {
        guard category == .npcSatellite else {
            return BaStudentDetailPage.allCases
        }
        guard let info else {
            return [.overviewProfile, .profile, .gallery]
        }

        var pages: [BaStudentDetailPage] = [.overviewProfile]
        if hasSkillContent(info) {
            pages.append(.skills)
        }
        if hasProfileContent(info, category: category) {
            pages.append(.profile)
        }
        if hasVoiceContent(info) {
            pages.append(.voice)
        }
        if hasGalleryContent(info) {
            pages.append(.gallery)
        }
        if hasSimulationContent(info) {
            pages.append(.simulate)
        }
        return pages.isEmpty ? [.overviewProfile] : pages
    }

    private static func hasSkillContent(_ info: BaStudentGuideInfo) -> Bool {
        let skillRows = info.skillRows
        let weaponCard = BaStudentWeaponDisplayModel.card(growthRows: info.growthRows, skillRows: skillRows)
        return BaStudentSkillDisplayModel.cards(from: skillRows).isEmpty == false ||
            weaponCard != nil
    }

    private static func hasProfileContent(
        _ info: BaStudentGuideInfo,
        category: BaCatalogCategory
    ) -> Bool {
        info.profileSections(for: category).contains { $0.isEmpty == false } ||
            info.overviewProfileRows.contains(where: isMeaningfulRow)
    }

    private static func hasVoiceContent(_ info: BaStudentGuideInfo) -> Bool {
        info.voiceRows.contains { row in
            row.transcript.isNotBlank ||
                row.audioURL != nil ||
                row.audioURLs?.isEmpty == false ||
                row.lines?.contains(where: \.isNotBlank) == true
        }
    }

    private static func hasGalleryContent(_ info: BaStudentGuideInfo) -> Bool {
        BaStudentGalleryDisplayState(info: info).hasRenderableContent
    }

    private static func hasSimulationContent(_ info: BaStudentGuideInfo) -> Bool {
        BaStudentSimulationDisplayModel.build(rows: info.simulateRows).hasRenderableContent
    }

    private static func isMeaningfulRow(_ row: BaGuideRow) -> Bool {
        row.title.isNotBlank &&
            (row.value.isNotBlank || row.imageURL != nil || row.imageURLs?.isEmpty == false)
    }
}

private extension String {
    nonisolated var isNotBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
