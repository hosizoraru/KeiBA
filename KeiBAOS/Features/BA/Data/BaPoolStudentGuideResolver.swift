//
//  BaPoolStudentGuideResolver.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated struct BaPoolStudentGuideResolver {
    private let detailURLByNameKey: [String: URL]
    private let detailURLByAliasKey: [String: URL]

    static let empty = BaPoolStudentGuideResolver(catalogEntries: [])

    init(catalogEntries: [BaGuideCatalogEntry]) {
        var nameMap: [String: URL] = [:]
        var aliasMap: [String: URL] = [:]

        for entry in catalogEntries {
            guard let detailURL = Self.canonicalStudentGuideURL(from: entry.detailURL) ?? entry.detailURL else {
                continue
            }
            let nameKey = Self.lookupKey(entry.name)
            if nameKey.isEmpty == false {
                nameMap[nameKey] = nameMap[nameKey] ?? detailURL
            }
            for aliasKey in Self.aliasLookupKeys(entry.alias) + Self.aliasLookupKeys(entry.aliasDisplay) {
                aliasMap[aliasKey] = aliasMap[aliasKey] ?? detailURL
            }
        }

        detailURLByNameKey = nameMap
        detailURLByAliasKey = aliasMap
    }

    func resolve(_ pool: BaPoolEntry) -> BaPoolEntry {
        let resolvedURL = pool.studentGuideOpenURL ?? resolve(name: pool.name, linkURL: pool.linkURL)
        guard resolvedURL != pool.studentGuideURL else { return pool }
        return pool.withStudentGuideURL(resolvedURL)
    }

    func resolve(name: String, linkURL: URL?) -> URL? {
        if let directURL = Self.canonicalStudentGuideURL(from: linkURL) {
            return directURL
        }
        let key = Self.lookupKey(name)
        guard key.isEmpty == false else { return nil }
        return detailURLByNameKey[key] ?? detailURLByAliasKey[key]
    }

    static func canonicalStudentGuideURL(from url: URL?) -> URL? {
        guard let url else { return nil }
        return canonicalStudentGuideURL(from: url.absoluteString)
    }

    static func canonicalStudentGuideURL(from rawURL: String) -> URL? {
        guard let normalizedURL = GameKeeJSON.normalizeGameKeeLink(rawURL, fallback: "") else {
            return nil
        }
        let host = normalizedURL.host?.lowercased() ?? ""
        guard host == "www.gamekee.com" || host == "gamekee.com" else { return nil }

        let path = normalizedURL.path
        for regex in explicitGuidePathRegexes {
            guard let regex else { continue }
            let range = NSRange(path.startIndex ..< path.endIndex, in: path)
            guard let match = regex.firstMatch(in: path, range: range),
                  let contentRange = Range(match.range(at: 1), in: path),
                  let contentId = Int64(path[contentRange]),
                  contentId > 0
            else {
                continue
            }
            return URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html")
        }
        return nil
    }

    static func contentID(from url: URL?) -> Int64? {
        guard let canonicalURL = canonicalStudentGuideURL(from: url) else { return nil }
        let path = canonicalURL.path
        guard let regex = canonicalContentIDRegex else { return nil }
        let range = NSRange(path.startIndex ..< path.endIndex, in: path)
        guard let match = regex.firstMatch(in: path, range: range),
              let contentRange = Range(match.range(at: 1), in: path)
        else {
            return nil
        }
        return Int64(path[contentRange])
    }

    private static func aliasLookupKeys(_ raw: String) -> [String] {
        raw
            .components(separatedBy: aliasSeparators)
            .map(lookupKey)
            .filter { $0.isEmpty == false }
    }

    private static func lookupKey(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "　", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }

    private static let explicitGuidePathPatterns = [
        #"/ba/tj/(\d+)(?:\.html)?$"#,
        #"/v1/content/detail/(\d+)$"#,
    ]

    // Compiled once. Hit per pool entry resolution; without caching every
    // resolve() walked the pattern list and recompiled each pattern.
    private nonisolated static let explicitGuidePathRegexes: [NSRegularExpression?] = explicitGuidePathPatterns.map {
        try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
    }

    private nonisolated static let canonicalContentIDRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"/ba/tj/(\d+)(?:\.html)?$"#)
    }()

    private static let aliasSeparators = CharacterSet(charactersIn: ",，、/|｜;；·")
}

extension BaPoolEntry {
    nonisolated var studentGuideOpenURL: URL? {
        BaPoolStudentGuideResolver.canonicalStudentGuideURL(from: studentGuideURL) ??
            BaPoolStudentGuideResolver.canonicalStudentGuideURL(from: linkURL)
    }
}
