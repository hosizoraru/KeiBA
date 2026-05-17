//
//  BaStudentDetailProfileSections.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated enum BaStudentProfileSectionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case names
    case info
    case hobby
    case gifts
    case sameName
    case chocolate
    case furniture
    case other

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .names:
            BaL10n.string("ba.student.detail.profile.names.title")
        case .info:
            BaL10n.string("ba.student.detail.profile.info.title")
        case .hobby:
            BaL10n.string("ba.student.detail.profile.hobby.title")
        case .gifts:
            BaL10n.string("ba.student.detail.profile.gifts.title")
        case .sameName:
            BaL10n.string("ba.student.detail.profile.sameName.title")
        case .chocolate:
            BaL10n.string("ba.student.detail.profile.chocolate.title")
        case .furniture:
            BaL10n.string("ba.student.detail.profile.furniture.title")
        case .other:
            BaL10n.string("ba.student.detail.profile.other.title")
        }
    }

    var systemImage: String {
        switch self {
        case .names:
            "person.text.rectangle"
        case .info:
            "info.circle"
        case .hobby:
            "quote.bubble"
        case .gifts:
            "gift"
        case .sameName:
            "person.2"
        case .chocolate:
            "heart.square"
        case .furniture:
            "sofa"
        case .other:
            "text.alignleft"
        }
    }
}

nonisolated enum BaStudentProfileRoleRelationKind: Hashable {
    case sameName
    case related

    var title: String {
        switch self {
        case .sameName:
            BaL10n.string("ba.student.detail.profile.sameName.title")
        case .related:
            BaL10n.string("ba.student.detail.profile.relatedRoles.title")
        }
    }

    var emptyText: String {
        switch self {
        case .sameName:
            BaL10n.string("ba.student.detail.profile.sameName.empty")
        case .related:
            BaL10n.string("ba.student.detail.profile.relatedRoles.empty")
        }
    }

    var fallbackItemTitle: String {
        switch self {
        case .sameName:
            BaL10n.string("ba.student.detail.profile.sameName.item")
        case .related:
            BaL10n.string("ba.student.detail.profile.relatedRoles.item")
        }
    }

    var openDetailHint: String {
        switch self {
        case .sameName:
            BaL10n.string("ba.student.detail.profile.sameName.openDetail")
        case .related:
            BaL10n.string("ba.student.detail.profile.relatedRoles.openDetail")
        }
    }
}

nonisolated struct BaStudentProfileFieldRow: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let imageURL: URL?
    let imageURLs: [URL]
    let externalURL: URL?
    let prefersCapsule: Bool
}

nonisolated struct BaStudentProfileGiftItem: Identifiable, Hashable {
    let id: String
    let label: String
    let giftImageURL: URL
    let emojiImageURL: URL?
}

nonisolated struct BaStudentProfileSameNameRoleItem: Identifiable, Hashable {
    let id: String
    let name: String
    let guideURL: URL?
    let imageURL: URL?

    var catalogEntry: BaGuideCatalogEntry? {
        guard let guideURL,
              let contentId = BaSameNameStudentGuideLinkResolver.contentID(from: guideURL)
        else {
            return nil
        }
        return BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: 0,
            contentId: contentId,
            name: name,
            alias: "",
            aliasDisplay: "",
            iconURL: imageURL,
            type: 3,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: guideURL,
            category: .students
        )
    }
}

nonisolated struct BaStudentProfileSection: Identifiable, Hashable {
    let kind: BaStudentProfileSectionKind
    var rows: [BaStudentProfileFieldRow] = []
    var giftItems: [BaStudentProfileGiftItem] = []
    var sameNameRoleItems: [BaStudentProfileSameNameRoleItem] = []
    var sameNameRoleHint: String = ""
    var roleRelationKind: BaStudentProfileRoleRelationKind = .sameName
    var galleryItems: [BaGuideGalleryItem] = []

    var id: BaStudentProfileSectionKind {
        kind
    }

    var title: String {
        if kind == .sameName {
            return roleRelationKind.title
        }
        return kind.title
    }

    var isEmpty: Bool {
        rows.isEmpty &&
            giftItems.isEmpty &&
            sameNameRoleItems.isEmpty &&
            sameNameRoleHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            galleryItems.isEmpty
    }
}

nonisolated struct BaStudentProfileDisplayModel: Hashable {
    let sections: [BaStudentProfileSection]

    init(info: BaStudentGuideInfo, includesOtherRows: Bool = false) {
        sections = Self.sections(from: info, includesOtherRows: includesOtherRows)
    }

    static func sections(from info: BaStudentGuideInfo, includesOtherRows: Bool = false) -> [BaStudentProfileSection] {
        let profileRowsBase = info.profileDisplayRows
            .filter { BaStudentGuideMeta.shouldHideMovedHeaderRow($0) == false }
            .filter { isGrowthTitleVoiceRow($0) == false }
            .filter { isVoicePlaceholderRow($0) == false }
            .filter { isProfileSectionHeaderRow($0) == false }
            .filter { isGalleryRelatedProfileLinkRow($0) == false }

        let sameNameRoleRows = profileRowsBase.filter(isSameNameRoleRow)
        let sameNameRoleItems = buildSameNameRoleItems(from: sameNameRoleRows)
        let sameNameRoleHint = sameNameRoleRows.compactMap(extractSameNameRoleHint).first ?? ""
        let roleRelationKind = relationKind(for: sameNameRoleRows)

        let hasTopDataHeader = profileRowsBase.contains {
            normalizeProfileFieldKey($0.title) == normalizeProfileFieldKey("顶级数据")
        }
        let hasInitialDataHeader = profileRowsBase.contains {
            normalizeProfileFieldKey($0.title) == normalizeProfileFieldKey("初始数据")
        }

        let allProfileRows = profileRowsBase.filter { row in
            isSkillMigratedProfileRow(
                row,
                hasTopDataHeader: hasTopDataHeader,
                hasInitialDataHeader: hasInitialDataHeader
            ) == false && isSameNameRoleRow(row) == false
        }

        let nicknameRows = buildProfileCardRows(rows: allProfileRows, specs: nicknameFieldSpecs, section: .names)
        let studentInfoRows = buildProfileCardRows(rows: allProfileRows, specs: studentInfoFieldSpecs, section: .info)
        let hobbyRows = buildProfileCardRows(rows: allProfileRows, specs: hobbyFieldSpecs, section: .hobby)

        let giftRows = allProfileRows
            .filter(isGiftPreferenceProfileRow)
            .sortedByKeyNumbers()
        let giftItems = buildGiftPreferenceItems(from: giftRows)

        let chocolateInfoRows = allProfileRows
            .filter { $0.title.localizedCaseInsensitiveContains("巧克力") }
            .sortedByKeyNumbers()
            .compactMap { visibleProfileRow($0, section: .chocolate, prefersCapsule: true) }
        let furnitureInfoRows = allProfileRows
            .filter { $0.title.localizedCaseInsensitiveContains("互动家具") }
            .sortedByKeyNumbers()
            .compactMap { visibleProfileRow($0, section: .furniture, prefersCapsule: false) }
        let otherInfoRows = allProfileRows.filter { row in
            let title = row.title.baProfileTrimmed
            return title.localizedCaseInsensitiveContains("巧克力") == false &&
                title.localizedCaseInsensitiveContains("互动家具") == false &&
                isGiftPreferenceProfileRow(row) == false &&
                isStructuredProfileCardRow(row) == false
        }
        .sortedByKeyNumbers()
        .compactMap { visibleProfileRow($0, section: .other, prefersCapsule: false) }

        let chocolateGalleryItems = info.galleryItems
            .filter(isChocolateGalleryItem)
            .filter(hasRenderableGalleryMedia)
            .distinctByMedia()
            .sortedByTitleNumbers()
        let furnitureGalleryItems = info.galleryItems
            .filter(isInteractiveFurnitureGalleryItem)
            .filter(hasRenderableGalleryMedia)
            .distinctByMedia()
            .sortedByTitleNumbers()

        var sections: [BaStudentProfileSection] = []
        appendSection(.names, rows: nicknameRows, to: &sections)
        appendSection(.info, rows: studentInfoRows, to: &sections)
        appendSection(.hobby, rows: hobbyRows, to: &sections)
        if includesOtherRows {
            appendSection(.other, rows: otherInfoRows, to: &sections)
        }
        if giftItems.isEmpty == false {
            sections.append(BaStudentProfileSection(kind: .gifts, giftItems: giftItems))
        }
        let sameNameSection = BaStudentProfileSection(
            kind: .sameName,
            sameNameRoleItems: sameNameRoleItems,
            sameNameRoleHint: sameNameRoleHint,
            roleRelationKind: roleRelationKind
        )
        if sameNameSection.isEmpty == false {
            sections.append(sameNameSection)
        }
        if chocolateInfoRows.isEmpty == false || chocolateGalleryItems.isEmpty == false {
            sections.append(
                BaStudentProfileSection(
                    kind: .chocolate,
                    rows: chocolateInfoRows,
                    galleryItems: chocolateGalleryItems
                )
            )
        }
        if furnitureInfoRows.isEmpty == false || furnitureGalleryItems.isEmpty == false {
            sections.append(
                BaStudentProfileSection(
                    kind: .furniture,
                    rows: furnitureInfoRows,
                    galleryItems: furnitureGalleryItems
                )
            )
        }
        return sections
    }

    private static func appendSection(
        _ kind: BaStudentProfileSectionKind,
        rows: [BaStudentProfileFieldRow],
        to sections: inout [BaStudentProfileSection]
    ) {
        guard rows.isEmpty == false else { return }
        sections.append(BaStudentProfileSection(kind: kind, rows: rows))
    }
}

extension BaStudentGuideInfo {
    nonisolated var profileSections: [BaStudentProfileSection] {
        BaStudentProfileDisplayModel(info: self).sections
    }

    nonisolated func profileSections(for category: BaCatalogCategory) -> [BaStudentProfileSection] {
        BaStudentProfileDisplayModel(
            info: self,
            includesOtherRows: category == .npcSatellite
        ).sections
    }
}
