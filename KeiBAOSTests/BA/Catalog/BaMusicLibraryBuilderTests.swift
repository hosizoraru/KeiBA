//
//  BaMusicLibraryBuilderTests.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/17.
//

import Foundation
@testable import KeiBAOS
import XCTest

final class BaMusicLibraryBuilderTests: XCTestCase {
    func testFavoriteStudentsResolveMemorialLobbyBGMTracks() throws {
        let student = catalogEntry(contentId: 101, name: "Hoshino", category: .students)
        let npc = catalogEntry(contentId: 202, name: "Sensei", category: .npcSatellite)
        let bgmURL = try XCTUnwrap(URL(string: "https://static.example.com/hoshino-bgm.mp3"))
        let info = guideInfo(
            contentId: 101,
            title: "Hoshino",
            galleryItems: [
                BaGuideGalleryItem(
                    id: "image",
                    title: "立绘",
                    detail: "",
                    imageURL: URL(string: "https://static.example.com/hoshino.png"),
                    mediaURL: URL(string: "https://static.example.com/hoshino.png"),
                    mediaKind: .image
                ),
                BaGuideGalleryItem(
                    id: "bgm",
                    title: "BGM",
                    detail: "",
                    imageURL: nil,
                    mediaURL: bgmURL,
                    mediaKind: .audio
                ),
            ]
        )

        let snapshot = BaMusicLibraryBuilder.snapshot(
            favoriteEntries: [student, npc],
            detailStates: [101: BaLoadableState(value: info)],
            query: "bgm"
        )

        XCTAssertEqual(snapshot.tracks.map(\.id), [101])
        XCTAssertEqual(snapshot.visibleTracks.first?.audioURL, bgmURL)
        XCTAssertEqual(snapshot.playableTracks.count, 1)
    }

    func testMissingDetailAndMissingBGMStayDistinct() {
        let needsDetail = catalogEntry(contentId: 303, name: "Serika", category: .students)
        let missingBGM = catalogEntry(contentId: 404, name: "Ayane", category: .students)
        let info = guideInfo(contentId: 404, title: "Ayane", galleryItems: [])

        let snapshot = BaMusicLibraryBuilder.snapshot(
            favoriteEntries: [needsDetail, missingBGM],
            detailStates: [404: BaLoadableState(value: info)],
            query: ""
        )

        XCTAssertEqual(snapshot.tracks.count, 2)
        XCTAssertEqual(snapshot.tracks[0].availability, .needsDetail)
        XCTAssertEqual(snapshot.tracks[1].availability, .missing)
        XCTAssertTrue(snapshot.playableTracks.isEmpty)
    }

    private func catalogEntry(
        contentId: Int64,
        name: String,
        category: BaCatalogCategory
    ) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: category.gameKeePID,
            contentId: contentId,
            name: name,
            alias: "",
            aliasDisplay: "",
            iconURL: URL(string: "https://static.example.com/\(contentId).png"),
            type: 0,
            order: Int(contentId),
            createdAt: nil,
            releaseDate: nil,
            detailURL: URL(string: "https://www.gamekee.com/ba/\(contentId).html"),
            category: category
        )
    }

    private func guideInfo(
        contentId: Int64,
        title: String,
        galleryItems: [BaGuideGalleryItem]
    ) -> BaStudentGuideInfo {
        BaStudentGuideInfo(
            contentId: contentId,
            sourceURL: URL(string: "https://www.gamekee.com/ba/\(contentId).html"),
            title: title,
            subtitle: "",
            summary: "",
            imageURL: URL(string: "https://static.example.com/\(contentId)-portrait.png"),
            stats: [],
            profileRows: [],
            skillRows: [],
            voiceRows: [],
            galleryItems: galleryItems,
            growthRows: [],
            simulateRows: [],
            contentSource: "",
            syncedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
