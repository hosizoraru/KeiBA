//
//  BaGuideCatalogRepository.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaGuideCatalogRepository {
    private let client: GameKeeClient

    init(client: GameKeeClient) {
        self.client = client
    }

    func fetchCatalog(now: Date = Date()) async throws -> BaRepositorySnapshot<BaGuideCatalogBundle> {
        async let students = fetchEntries(pid: BaCatalogCategory.students.gameKeePID, category: .students)
        async let npcSatellite = fetchEntries(pid: BaCatalogCategory.npcSatellite.gameKeePID, category: .npcSatellite)
        let (studentEntries, npcSatelliteEntries) = try await (students, npcSatellite)
        let entries = (studentEntries + npcSatelliteEntries)
            .sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category.rawValue < rhs.category.rawValue
                }
                return lhs.order < rhs.order
            }
        return BaRepositorySnapshot(
            value: BaGuideCatalogBundle(entries: entries, syncedAt: now),
            syncedAt: now,
            sourceErrors: []
        )
    }

    func fetchStudentCatalog(now: Date = Date()) async throws -> BaRepositorySnapshot<[BaGuideCatalogEntry]> {
        let entries = try await fetchEntries(pid: BaCatalogCategory.students.gameKeePID, category: .students)
        return BaRepositorySnapshot(value: entries, syncedAt: now, sourceErrors: [])
    }

    private func fetchEntries(pid: Int, category: BaCatalogCategory) async throws -> [BaGuideCatalogEntry] {
        let data = try await client.fetchJSONData(
            GameKeeRequest(
                pathOrURL: "/v1/entry/treesByPid?pid=\(pid)",
                refererPath: "/ba/second/\(BaCatalogCategory.gameKeeSecondPageID)",
                extraHeaders: GameKeeClient.baHeaders
            )
        )
        return try parseEntries(data: data, pid: pid, category: category)
    }

    func parseEntries(data: Data, pid: Int, category: BaCatalogCategory) throws -> [BaGuideCatalogEntry] {
        let rows = try GameKeeJSON.dataArray(from: data)
        return rows.enumerated().compactMap { index, item in
            guard let contentId = item.int64("content_id"), contentId > 0 else { return nil }
            let name = (item.string("name") ?? item.string("title") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.isEmpty == false else { return nil }
            let alias = item.string("name_alias") ?? ""
            return BaGuideCatalogEntry(
                entryId: item.int("id") ?? index,
                pid: item.int("pid") ?? pid,
                contentId: contentId,
                name: name,
                alias: alias,
                aliasDisplay: Self.formatAliasDisplay(alias),
                iconURL: GameKeeJSON.normalizeImageURL(item.string("icon") ?? ""),
                type: item.int("type") ?? 0,
                order: index,
                createdAt: item.dateFromSeconds("created_at"),
                releaseDate: nil,
                detailURL: URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html"),
                category: category
            )
        }
    }

    private static func formatAliasDisplay(_ alias: String) -> String {
        alias
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " · ")
    }
}
