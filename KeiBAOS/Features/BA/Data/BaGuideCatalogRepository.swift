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
        async let studentFilterPayloadResult = fetchFilterPayload(for: .students)
        async let npcSatelliteFilterPayloadResult = fetchFilterPayload(for: .npcSatellite)
        async let metadataDataResult = fetchStudentMetadataData()
        let (studentEntries, npcSatelliteEntries) = try await (students, npcSatellite)
        let studentFilterPayload = await studentFilterPayloadResult
        let npcSatelliteFilterPayload = await npcSatelliteFilterPayloadResult
        let metadataData = await metadataDataResult
        let studentMetadata = metadataData.value.flatMap { data in
            try? parseStudentMetadata(data: data, filterGroups: studentFilterPayload.value.groups)
        } ?? [:]
        let enrichedStudentEntries = studentEntries.map { entry in
            entry.withMetadata(
                mergedMetadata(
                    bulkMetadata: studentMetadata[entry.contentId],
                    filterMetadata: studentFilterPayload.value.metadataByEntryID[entry.entryId]
                )
            )
        }
        let enrichedNPCSatelliteEntries = npcSatelliteEntries.map { entry in
            entry.withMetadata(npcSatelliteFilterPayload.value.metadataByEntryID[entry.entryId])
        }
        let entries = (enrichedStudentEntries + enrichedNPCSatelliteEntries)
            .sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category.rawValue < rhs.category.rawValue
                }
                return lhs.order < rhs.order
            }
        return BaRepositorySnapshot(
            value: BaGuideCatalogBundle(
                entries: entries,
                syncedAt: now,
                studentFilterGroups: studentFilterPayload.value.groups,
                npcSatelliteFilterGroups: npcSatelliteFilterPayload.value.groups
            ),
            syncedAt: now,
            sourceErrors: [studentFilterPayload.error, npcSatelliteFilterPayload.error, metadataData.error].compactMap { $0 }
        )
    }

    func fetchStudentCatalog(now: Date = Date()) async throws -> BaRepositorySnapshot<[BaGuideCatalogEntry]> {
        async let entries = fetchEntries(pid: BaCatalogCategory.students.gameKeePID, category: .students)
        async let filterPayloadResult = fetchFilterPayload(for: .students)
        async let metadataDataResult = fetchStudentMetadataData()
        let (studentEntries, filterPayload, metadataData) = try await (entries, filterPayloadResult, metadataDataResult)
        let studentMetadata = metadataData.value.flatMap { data in
            try? parseStudentMetadata(data: data, filterGroups: filterPayload.value.groups)
        } ?? [:]
        let enrichedEntries = studentEntries.map { entry in
            entry.withMetadata(
                mergedMetadata(
                    bulkMetadata: studentMetadata[entry.contentId],
                    filterMetadata: filterPayload.value.metadataByEntryID[entry.entryId]
                )
            )
        }
        return BaRepositorySnapshot(
            value: enrichedEntries,
            syncedAt: now,
            sourceErrors: [filterPayload.error, metadataData.error].compactMap { $0 }
        )
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

    func parseFilterGroups(data: Data) throws -> [BaCatalogFilterGroup] {
        try BaCatalogMetadataParser.parseFilterGroups(data: data)
    }

    func parseFilterAttributeMetadata(
        data: Data,
        filterGroups: [BaCatalogFilterGroup]
    ) throws -> [Int: BaGuideCatalogMetadata] {
        try BaCatalogMetadataParser.parseFilterAttributeMetadata(data: data, filterGroups: filterGroups)
    }

    func parseStudentMetadata(
        data: Data,
        filterGroups: [BaCatalogFilterGroup]
    ) throws -> [Int64: BaGuideCatalogMetadata] {
        try BaCatalogMetadataParser.parseStudentMetadata(data: data, filterGroups: filterGroups)
    }

    private func fetchFilterPayload(for category: BaCatalogCategory) async -> CatalogPartial<CatalogFilterPayload> {
        do {
            let data = try await client.fetchJSONData(
                GameKeeRequest(
                    pathOrURL: "/v1/entryFilter/getEntryFilter?entry_id=\(category.gameKeePID)",
                    refererPath: "/ba/second/\(BaCatalogCategory.gameKeeSecondPageID)",
                    extraHeaders: GameKeeClient.baHeaders
                )
            )
            let groups = try parseFilterGroups(data: data)
            let metadataByEntryID = try parseFilterAttributeMetadata(data: data, filterGroups: groups)
            return CatalogPartial(
                value: CatalogFilterPayload(groups: groups, metadataByEntryID: metadataByEntryID),
                error: nil
            )
        } catch {
            return CatalogPartial(value: CatalogFilterPayload(), error: "catalog-filter-\(category.rawValue):\(error.localizedDescription)")
        }
    }

    private func fetchStudentMetadataData() async -> CatalogPartial<Data?> {
        do {
            let data = try await client.fetchJSONData(
                GameKeeRequest(
                    pathOrURL: "/v1/entry/tj-list?entry_id=\(BaCatalogCategory.students.gameKeePID)",
                    refererPath: "/ba/second/\(BaCatalogCategory.gameKeeSecondPageID)",
                    extraHeaders: GameKeeClient.baHeaders
                )
            )
            return CatalogPartial(value: data, error: nil)
        } catch {
            return CatalogPartial(value: nil, error: "catalog-metadata:\(error.localizedDescription)")
        }
    }

    private static func formatAliasDisplay(_ alias: String) -> String {
        alias
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " · ")
    }

    private func mergedMetadata(
        bulkMetadata: BaGuideCatalogMetadata?,
        filterMetadata: BaGuideCatalogMetadata?
    ) -> BaGuideCatalogMetadata? {
        if let bulkMetadata, let filterMetadata {
            return bulkMetadata.mergingMissingFields(with: filterMetadata)
        }
        return bulkMetadata ?? filterMetadata
    }
}

private struct CatalogPartial<Value> {
    let value: Value
    let error: String?
}

private struct CatalogFilterPayload {
    var groups: [BaCatalogFilterGroup] = []
    var metadataByEntryID: [Int: BaGuideCatalogMetadata] = [:]
}
