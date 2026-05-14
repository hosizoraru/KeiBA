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

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .names:
            String(localized: "ba.student.detail.profile.names.title")
        case .info:
            String(localized: "ba.student.detail.profile.info.title")
        case .hobby:
            String(localized: "ba.student.detail.profile.hobby.title")
        }
    }
}

nonisolated struct BaStudentProfileSection: Identifiable, Hashable {
    let kind: BaStudentProfileSectionKind
    let rows: [BaGuideRow]

    var id: BaStudentProfileSectionKind {
        kind
    }

    var title: String {
        kind.title
    }

    static func sections(from rows: [BaGuideRow]) -> [BaStudentProfileSection] {
        let grouped = Dictionary(grouping: rows, by: classify)
        return BaStudentProfileSectionKind.allCases.compactMap { kind in
            guard let rows = grouped[kind], rows.isEmpty == false else { return nil }
            return BaStudentProfileSection(kind: kind, rows: rows)
        }
    }

    private static func classify(_ row: BaGuideRow) -> BaStudentProfileSectionKind {
        let text = "\(row.title) \(row.value)"
        if containsAny(text, tokens: [
            "名称", "全名", "译名", "假名", "注音", "别名", "昵称", "姓名", "角色名", "本名", "中文名", "日文名",
        ]) {
            return .names
        }
        if containsAny(text, tokens: [
            "兴趣", "爱好", "礼物", "偏好", "咖啡厅", "介绍", "简介", "说明", "故事", "设定", "喜欢", "性格",
        ]) {
            return .hobby
        }
        return .info
    }

    private static func containsAny(_ value: String, tokens: [String]) -> Bool {
        tokens.contains { value.localizedCaseInsensitiveContains($0) }
    }
}

extension BaStudentGuideInfo {
    nonisolated var profileSections: [BaStudentProfileSection] {
        BaStudentProfileSection.sections(from: Array(overviewProfileRows.prefix(32)))
    }
}
