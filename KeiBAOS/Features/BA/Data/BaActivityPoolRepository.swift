//
//  BaActivityPoolRepository.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

nonisolated struct BaRepositorySnapshot<Value> {
    let value: Value
    let syncedAt: Date
    let sourceErrors: [String]
}

struct BaActivityPoolRepository {
    private let client: GameKeeClient

    init(client: GameKeeClient) {
        self.client = client
    }

    func fetchActivities(server: BaServer, now: Date = Date()) async throws -> BaRepositorySnapshot<[BaActivityEntry]> {
        let path = "/v1/activity/page-list?importance=0&sort=-1&keyword=&limit=999&page_no=1&serverId=\(server.gameKeeServerId)&status=0"
        let data = try await client.fetchJSONData(
            GameKeeRequest(
                pathOrURL: path,
                refererPath: "/ba/huodong/\(server.gameKeeServerId)",
                extraHeaders: GameKeeClient.baHeaders
            )
        )
        let entries = try parseActivities(data: data, now: now)
        return BaRepositorySnapshot(value: entries, syncedAt: now, sourceErrors: [])
    }

    func fetchPools(server: BaServer, now: Date = Date()) async throws -> BaRepositorySnapshot<[BaPoolEntry]> {
        let path = "/v1/cardPool/query-list?order_by=-1&card_tag_id=&keyword=&kind_id=6&status=0&serverId=\(server.gameKeeServerId)"
        let data = try await client.fetchJSONData(
            GameKeeRequest(
                pathOrURL: path,
                refererPath: "/ba/kachi/\(server.gameKeeServerId)",
                extraHeaders: GameKeeClient.baHeaders
            )
        )
        let entries = try parsePools(data: data, now: now)
        return BaRepositorySnapshot(value: entries, syncedAt: now, sourceErrors: [])
    }

    func parseActivities(data: Data, now: Date = Date()) throws -> [BaActivityEntry] {
        let rows = try GameKeeJSON.dataArray(from: data)
        let parsed = rows.compactMap { item -> BaActivityEntry? in
            guard let title = item.string("title"),
                  let beginAt = item.dateFromSeconds("begin_at"),
                  let endAt = item.dateFromSeconds("end_at"),
                  endAt >= beginAt
            else {
                return nil
            }
            return BaActivityEntry(
                id: item.int("id") ?? title.hashValue,
                title: title,
                kindId: item.int("activity_kind_id") ?? 31,
                kindName: normalizeCalendarKind(item.string("activity_kind_name") ?? ""),
                beginAt: beginAt,
                endAt: endAt,
                linkURL: GameKeeJSON.normalizeGameKeeLink(item.string("link_url") ?? "", fallback: "https://www.gamekee.com/ba/huodong"),
                imageURL: GameKeeJSON.findImageURL(in: item)
            )
        }
        return normalizeActivities(parsed, now: now)
    }

    func parsePools(data: Data, now: Date = Date()) throws -> [BaPoolEntry] {
        let rows = try GameKeeJSON.dataArray(from: data)
        let parsed = rows.compactMap { item -> BaPoolEntry? in
            guard let name = item.string("name"),
                  let startAt = item.dateFromSeconds("start_at"),
                  let endAt = item.dateFromSeconds("end_at"),
                  endAt >= startAt
            else {
                return nil
            }
            let status = poolStatus(startAt: startAt, endAt: endAt, now: now)
            let knownTagId = parsePoolTagIDs(item.string("tag_id") ?? "")
                .first { Self.poolTagIDs.contains($0) }
            let tagId = knownTagId ?? (status == .ended ? nil : Self.fallbackActivePoolTagID)
            guard let tagId else { return nil }
            let rawTagName = normalizePoolTag(item.string("tag") ?? item.string("tagName") ?? "")
            let contentId = item.int64("content_id").flatMap { $0 > 0 ? $0 : nil }
            let linkURL = GameKeeJSON.normalizeGameKeeLink(item.string("link_url") ?? "", fallback: "https://www.gamekee.com/ba/kachi")
            return BaPoolEntry(
                id: item.int("id") ?? name.hashValue,
                name: name,
                tagId: tagId,
                tagName: rawTagName,
                alias: item.string("name_alias") ?? "",
                startAt: startAt,
                endAt: endAt,
                linkURL: linkURL,
                imageURL: GameKeeJSON.findImageURL(in: item),
                contentId: contentId,
                studentGuideURL: BaPoolStudentGuideResolver.canonicalStudentGuideURL(from: linkURL)
            )
        }
        return normalizePools(parsed, now: now)
    }

    private func normalizeActivities(_ entries: [BaActivityEntry], now: Date) -> [BaActivityEntry] {
        let normalized = entries.filter { $0.title.isEmpty == false }
        guard normalized.isEmpty == false else { return [] }

        let activeOrUpcoming = normalized.filter { $0.endAt > now }
        let activeKindIDs = Set(activeOrUpcoming.map(\.kindId))
        let fallbackMissingKinds = Dictionary(grouping: normalized, by: \.kindId)
            .filter { activeKindIDs.contains($0.key) == false }
            .compactMap { _, entries in
                entries.max {
                    if $0.endAt == $1.endAt {
                        return $0.beginAt < $1.beginAt
                    }
                    return $0.endAt < $1.endAt
                }
            }

        var merged = activeOrUpcoming
        for entry in fallbackMissingKinds where merged.contains(where: { $0.id == entry.id }) == false {
            merged.append(entry)
        }

        return merged
            .sorted { lhs, rhs in
                sortKey(for: lhs.status(at: now), start: lhs.beginAt, end: lhs.endAt, id: lhs.kindId) <
                    sortKey(for: rhs.status(at: now), start: rhs.beginAt, end: rhs.endAt, id: rhs.kindId)
            }
            .prefix(Self.maxItems)
            .map { $0 }
    }

    private func normalizePools(_ entries: [BaPoolEntry], now: Date) -> [BaPoolEntry] {
        let normalized = entries.filter { $0.name.isEmpty == false }
        guard normalized.isEmpty == false else { return [] }

        let activeOrUpcoming = normalized.filter { $0.endAt > now }
        let activeTagIDs = Set(activeOrUpcoming.map(\.tagId))
        let fallbackMissingTags = Self.poolTagIDs
            .filter { activeTagIDs.contains($0) == false }
            .compactMap { tagId in
                normalized
                    .filter { $0.tagId == tagId }
                    .max {
                        if $0.endAt == $1.endAt {
                            return $0.startAt < $1.startAt
                        }
                        return $0.endAt < $1.endAt
                    }
            }

        var merged = activeOrUpcoming
        for entry in fallbackMissingTags where merged.contains(where: { $0.id == entry.id }) == false {
            merged.append(entry)
        }

        return merged
            .sorted { lhs, rhs in
                sortKey(for: lhs.status(at: now), start: lhs.startAt, end: lhs.endAt, id: lhs.tagId) <
                    sortKey(for: rhs.status(at: now), start: rhs.startAt, end: rhs.endAt, id: rhs.tagId)
            }
            .prefix(Self.maxItems)
            .map { $0 }
    }

    private func sortKey(for status: BaTimelineStatus, start: Date, end: Date, id: Int) -> BaTimelineSortKey {
        let rank: Int
        let time: TimeInterval
        switch status {
        case .running:
            rank = 0
            time = end.timeIntervalSince1970
        case .upcoming:
            rank = 1
            time = start.timeIntervalSince1970
        case .ended:
            rank = 2
            time = -end.timeIntervalSince1970
        }
        return BaTimelineSortKey(rank: rank, time: time, id: id)
    }

    private func poolStatus(startAt: Date, endAt: Date, now: Date) -> BaTimelineStatus {
        if now >= startAt && now < endAt { return .running }
        if now < startAt { return .upcoming }
        return .ended
    }

    private nonisolated static let poolTagDigitRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d+"#)
    }()

    private func parsePoolTagIDs(_ raw: String) -> [Int] {
        guard let regex = Self.poolTagDigitRegex else { return [] }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        return regex.matches(in: raw, range: range).compactMap { match in
            guard let range = Range(match.range, in: raw) else { return nil }
            return Int(raw[range])
        }
    }

    private func normalizeCalendarKind(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines) == "其他" ? "" : raw
    }

    private func normalizePoolTag(_ raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.legacyPoolTagLabels.contains(value) ? "" : value
    }

    private static let maxItems = 10
    private static let fallbackActivePoolTagID = 6
    private static let poolTagIDs = [5, 6, 7, 8, 9, 92]
    private static let legacyPoolTagLabels: Set<String> = [
        "常驻", "限定", "FES限定", "FES 限定", "联动", "复刻", "回忆招募", "卡池", "其他",
    ]
}

private struct BaTimelineSortKey: Comparable {
    let rank: Int
    let time: TimeInterval
    let id: Int

    static func < (lhs: BaTimelineSortKey, rhs: BaTimelineSortKey) -> Bool {
        if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
        if lhs.time != rhs.time { return lhs.time < rhs.time }
        return lhs.id < rhs.id
    }
}
