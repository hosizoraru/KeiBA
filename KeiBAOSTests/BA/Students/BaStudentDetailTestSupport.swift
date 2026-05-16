//
//  BaStudentDetailTestSupport.swift
//  KeiBAOSTests
//
//  Split by Codex on 2026/05/16.
//

@testable import KeiBAOS
import Foundation

func makeStudentDetailCatalogEntry() -> BaGuideCatalogEntry {
    makeStudentDetailCatalogEntry(contentId: 609_145, name: "Test", category: .students)
}

func makeStudentDetailCatalogEntry(
    contentId: Int64,
    name: String,
    category: BaCatalogCategory
) -> BaGuideCatalogEntry {
    BaGuideCatalogEntry(
        entryId: Int(contentId),
        pid: 49443,
        contentId: contentId,
        name: name,
        alias: "",
        aliasDisplay: "",
        iconURL: nil,
        type: 0,
        order: 0,
        createdAt: nil,
        releaseDate: nil,
        detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
        category: category
    )
}
