//
//  BaSameNameStudentGuideLinkResolver.swift
//  KeiBA
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated enum BaSameNameStudentGuideLinkResolver {
    static func canonicalURL(from raw: String) -> URL? {
        let candidates = candidateLinks(from: raw)
        for candidate in candidates {
            if let explicit = BaPoolStudentGuideResolver.canonicalStudentGuideURL(from: candidate) {
                return explicit
            }
            guard let normalized = GameKeeJSON.normalizeGameKeeLink(candidate, fallback: "") else {
                continue
            }
            guard acceptsGameKeeHost(normalized),
                  let contentId = contentID(from: normalized)
            else {
                continue
            }
            return URL(string: "https://www.gamekee.com/ba/tj/\(contentId).html")
        }
        return nil
    }

    static func contentID(from url: URL?) -> Int64? {
        guard let url,
              let canonicalURL = canonicalURL(from: url.absoluteString)
        else {
            return nil
        }
        return BaPoolStudentGuideResolver.contentID(from: canonicalURL)
    }

    private static func candidateLinks(from raw: String) -> [String] {
        let source = sanitize(raw)
        guard source.isEmpty == false else { return [] }
        var candidates: [String] = []

        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            candidates.append(source)
        } else if source.hasPrefix("www.") {
            candidates.append("https://\(source)")
        } else if matchesNumericID(source) {
            candidates.append("https://www.gamekee.com/ba/tj/\(source).html")
        } else if source.hasPrefix("/") {
            candidates.append(GameKeeJSON.normalizeGameKeeLink(source, fallback: "")?.absoluteString ?? source)
        }

        let embedded = regexMatches(in: source, regex: embeddedLinkRegex, fallbackPattern: embeddedLinkPattern)
            .map(sanitize)
            .map { candidate in
                if candidate.hasPrefix("/") {
                    return GameKeeJSON.normalizeGameKeeLink(candidate, fallback: "")?.absoluteString ?? candidate
                }
                return candidate
            }
        return dedupe(candidates + embedded)
    }

    private static func contentID(from url: URL) -> Int64? {
        let path = url.path
        for regex in contentIDRegexes {
            guard let regex else { continue }
            let range = NSRange(path.startIndex ..< path.endIndex, in: path)
            guard let match = regex.firstMatch(in: path, range: range),
                  let idRange = Range(match.range(at: 1), in: path),
                  let contentID = Int64(path[idRange]),
                  contentID > 0
            else {
                continue
            }
            return contentID
        }
        return nil
    }

    private static func acceptsGameKeeHost(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host == "www.gamekee.com" || host == "gamekee.com"
    }

    private static func sanitize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ")]},。 ，,;；"))
    }

    private static func matchesNumericID(_ raw: String) -> Bool {
        if let regex = numericIDRegex {
            let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
            return regex.firstMatch(in: raw, range: range) != nil
        }
        return raw.range(of: #"^\d{4,}$"#, options: .regularExpression) != nil
    }

    private static func regexMatches(in raw: String, regex: NSRegularExpression?, fallbackPattern: String) -> [String] {
        let resolved: NSRegularExpression
        if let regex {
            resolved = regex
        } else if let built = try? NSRegularExpression(pattern: fallbackPattern, options: [.caseInsensitive]) {
            resolved = built
        } else {
            return []
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        return resolved.matches(in: raw, range: range).compactMap { match in
            Range(match.range, in: raw).map { String(raw[$0]) }
        }
    }

    private static func dedupe(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static let contentIDPathPatterns = [
        #"/ba/tj/(\d+)(?:\.html)?$"#,
        #"/ba/(\d+)(?:\.html)?$"#,
        #"/v1/content/detail/(\d+)$"#,
    ]

    // Compiled once. Hit per resolution attempt (often per same-name role row in
    // a student detail body). Fallback to per-call compile only if the static
    // initializer threw.
    private nonisolated static let contentIDRegexes: [NSRegularExpression?] = contentIDPathPatterns.map {
        try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
    }

    private static let embeddedLinkPattern = #"https?://[^\s]+|/(?:ba/tj/\d+(?:\.html)?|ba/\d+(?:\.html)?|v1/content/detail/\d+)"#
    private nonisolated static let embeddedLinkRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: embeddedLinkPattern, options: [.caseInsensitive])
    }()

    private nonisolated static let numericIDRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^\d{4,}$"#)
    }()
}
