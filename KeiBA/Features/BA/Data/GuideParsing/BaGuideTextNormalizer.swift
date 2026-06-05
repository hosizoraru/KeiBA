//
//  BaGuideTextNormalizer.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

enum BaGuideTextNormalizer {
    // Compiled-once regex caches. Every JSON row ingest funnels through
    // clean()/cleanDisplayText()/normalizeMediaURL(), so recompiling these
    // patterns from string literals on each call shows up as a meaningful
    // allocation hotspot during initial guide loads and search updates.
    fileprivate nonisolated static let stripHTMLRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"<[^>]+>"#)
    }()
    fileprivate nonisolated static let displayMediaRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"((?:https?:)?//[^\s"'<>\\]+|/[A-Za-z0-9_\-./%]+\.(?:png|jpe?g|webp|gif|mp3|m4a|wav|aac|ogg|oga|opus|flac|mp4|mov|m3u8)(?:\?[^\s"'<>\\]+)?)"#,
            options: [.caseInsensitive]
        )
    }()
    fileprivate nonisolated static let trailingSlashRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\s*/\s*$"#)
    }()
    fileprivate nonisolated static let collapsedSpaceRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\s{2,}"#)
    }()
    fileprivate nonisolated static let digitOnlyRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^\d+$"#)
    }()
    fileprivate nonisolated static let dateRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d{4}[-/.]\d{1,2}[-/.]\d{1,2}"#)
    }()
    fileprivate nonisolated static let extractURLsRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"((?:https?:)?//[^\s"'<>\\]+|/[A-Za-z0-9_\-./%]+(?:\?[^\s"'<>\\]+)?|[A-Za-z0-9_\-./%]+\.(?:png|jpe?g|webp|gif|mp3|m4a|wav|aac|ogg|oga|opus|flac|mp4|mov|m3u8)(?:\?[^\s"'<>\\]+)?)"#,
            options: [.caseInsensitive]
        )
    }()
    fileprivate nonisolated static let imgTagRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"<img\b[^>]*>"#, options: [.caseInsensitive, .dotMatchesLineSeparators])
    }()
    fileprivate nonisolated static let imgClassRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\bclass\s*=\s*["']([^"']+)["']"#, options: [.caseInsensitive])
    }()
    fileprivate nonisolated static let imgSrcRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\bsrc\s*=\s*["']([^"']+)["']"#, options: [.caseInsensitive])
    }()

    nonisolated static func clean(_ raw: String) -> String {
        stripHTML(raw)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func cleanDisplayText(_ raw: String) -> String {
        let cleaned = clean(raw)
        let stripped: String
        if let regex = displayMediaRegex {
            let range = NSRange(cleaned.startIndex ..< cleaned.endIndex, in: cleaned)
            stripped = regex.stringByReplacingMatches(in: cleaned, range: range, withTemplate: "")
        } else {
            let mediaPattern = #"((?:https?:)?//[^\s"'<>\\]+|/[A-Za-z0-9_\-./%]+\.(?:png|jpe?g|webp|gif|mp3|m4a|wav|aac|ogg|oga|opus|flac|mp4|mov|m3u8)(?:\?[^\s"'<>\\]+)?)"#
            stripped = cleaned.replacingOccurrences(of: mediaPattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
        let withoutTrailingSlash: String
        if let regex = trailingSlashRegex {
            let range = NSRange(stripped.startIndex ..< stripped.endIndex, in: stripped)
            withoutTrailingSlash = regex.stringByReplacingMatches(in: stripped, range: range, withTemplate: "")
        } else {
            withoutTrailingSlash = stripped.replacingOccurrences(of: #"\s*/\s*$"#, with: "", options: .regularExpression)
        }
        let collapsed: String
        if let regex = collapsedSpaceRegex {
            let range = NSRange(withoutTrailingSlash.startIndex ..< withoutTrailingSlash.endIndex, in: withoutTrailingSlash)
            collapsed = regex.stringByReplacingMatches(in: withoutTrailingSlash, range: range, withTemplate: " ")
        } else {
            collapsed = withoutTrailingSlash.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        }
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func normalizedKey(_ raw: String) -> String {
        clean(raw)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .lowercased()
    }

    nonisolated static func containsAny(_ raw: String, tokens: [String]) -> Bool {
        tokens.contains { raw.localizedCaseInsensitiveContains($0) }
    }

    nonisolated static func normalizeMediaURL(_ raw: String, sourceURL: URL?) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false, isPlaceholderMediaToken(value) == false else { return nil }
        if value.hasPrefix("http://") {
            return URL(string: value.replacingOccurrences(of: "http://", with: "https://", options: [.anchored, .caseInsensitive]))
        }
        if value.hasPrefix("https://") {
            return URL(string: value)
        }
        if value.hasPrefix("//") {
            return URL(string: "https:\(value)")
        }
        if value.hasPrefix("/") {
            return URL(string: "https://www.gamekee.com\(value)")
        }
        if let sourceURL {
            return URL(string: value, relativeTo: sourceURL)?.absoluteURL
        }
        return URL(string: "https://www.gamekee.com/\(value)")
    }

    nonisolated static func looksLikeImageURL(_ url: URL) -> Bool {
        let value = url.absoluteString.lowercased()
        let pathExtension = url.pathExtension.lowercased()
        if ["json", "mp4", "mov", "m3u8", "mp3", "m4a", "wav", "aac", "ogg", "oga", "opus", "flac"].contains(pathExtension) {
            return false
        }
        if hasInvalidGameKeeMediaTail(url) {
            return false
        }
        if ["jpg", "jpeg", "png", "webp", "gif", "bmp", "svg", "avif"].contains(pathExtension) {
            return true
        }
        let host = url.host?.lowercased() ?? ""
        return host.contains("cdnimg") ||
            value.contains("image") ||
            value.contains("img") ||
            value.contains("upload")
    }

    nonisolated static func looksLikeVideoURL(_ url: URL) -> Bool {
        let value = url.absoluteString.lowercased()
        if hasInvalidGameKeeMediaTail(url) {
            return false
        }
        return value.hasSuffix(".mp4") ||
            value.hasSuffix(".webm") ||
            value.hasSuffix(".mov") ||
            value.hasSuffix(".m3u8") ||
            value.contains(".mp4?") ||
            value.contains(".webm?") ||
            value.contains(".mov?") ||
            value.contains(".m3u8?") ||
            value.contains("video")
    }

    nonisolated static func looksLikeAudioURL(_ url: URL) -> Bool {
        let value = url.absoluteString.lowercased()
        if hasInvalidGameKeeMediaTail(url) {
            return false
        }
        return value.hasSuffix(".mp3") ||
            value.hasSuffix(".m4a") ||
            value.hasSuffix(".wav") ||
            value.hasSuffix(".aac") ||
            value.hasSuffix(".ogg") ||
            value.hasSuffix(".oga") ||
            value.hasSuffix(".opus") ||
            value.hasSuffix(".flac") ||
            value.contains(".mp3?") ||
            value.contains(".m4a?") ||
            value.contains(".wav?") ||
            value.contains(".aac?") ||
            value.contains(".ogg?") ||
            value.contains(".oga?") ||
            value.contains(".opus?") ||
            value.contains(".flac?") ||
            value.contains("audio")
    }

    nonisolated static func isPlaceholderMediaToken(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty ||
            value == "n" ||
            value == "null" ||
            value == "undefined" ||
            value == "nan" ||
            value == "-" ||
            value == "[]" {
            return true
        }
        if let regex = digitOnlyRegex {
            let range = NSRange(value.startIndex ..< value.endIndex, in: value)
            return regex.firstMatch(in: value, range: range) != nil
        }
        return value.range(of: #"^\d+$"#, options: .regularExpression) != nil
    }

    nonisolated static func imageURLs(in any: Any?, sourceURL: URL?, depth: Int = 0) -> [URL] {
        urls(in: any, sourceURL: sourceURL, depth: depth) { looksLikeImageURL($0) }
    }

    nonisolated static func videoURLs(in any: Any?, sourceURL: URL?, depth: Int = 0) -> [URL] {
        urls(in: any, sourceURL: sourceURL, depth: depth) { looksLikeVideoURL($0) }
    }

    nonisolated static func audioURLs(in any: Any?, sourceURL: URL?, depth: Int = 0) -> [URL] {
        urls(in: any, sourceURL: sourceURL, depth: depth) { looksLikeAudioURL($0) }
    }

    nonisolated static func imageURLsFromHTML(_ raw: String, sourceURL: URL?) -> [URL] {
        extractAttributeURLs(raw, attribute: "src", sourceURL: sourceURL)
            .filter(looksLikeImageURL)
    }

    nonisolated static func imageURLsFromHTMLClasses(_ raw: String, classKeywords: [String], sourceURL: URL?) -> [URL] {
        guard raw.isEmpty == false,
              let tagRegex = imgTagRegex,
              let classRegex = imgClassRegex,
              let srcRegex = imgSrcRegex
        else {
            return []
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        var out: [URL] = []
        for match in tagRegex.matches(in: raw, range: range) {
            guard let tagRange = Range(match.range, in: raw) else { continue }
            let tag = String(raw[tagRange])
            let tagNSRange = NSRange(tag.startIndex ..< tag.endIndex, in: tag)
            guard let classMatch = classRegex.firstMatch(in: tag, range: tagNSRange),
                  let classRange = Range(classMatch.range(at: 1), in: tag),
                  classKeywords.contains(where: { String(tag[classRange]).localizedCaseInsensitiveContains($0) }),
                  let srcMatch = srcRegex.firstMatch(in: tag, range: tagNSRange),
                  let srcRange = Range(srcMatch.range(at: 1), in: tag),
                  let url = normalizeMediaURL(String(tag[srcRange]), sourceURL: sourceURL),
                  looksLikeImageURL(url)
            else {
                continue
            }
            out.append(url)
        }
        return dedupe(out)
    }

    nonisolated static func extractDate(from raw: String, calendar: Calendar = .current) -> Date? {
        let normalized = raw
            .replacingOccurrences(of: "年", with: "-")
            .replacingOccurrences(of: "月", with: "-")
            .replacingOccurrences(of: "日", with: "")
        let foundRange: Range<String.Index>?
        if let regex = dateRegex {
            let range = NSRange(normalized.startIndex ..< normalized.endIndex, in: normalized)
            foundRange = regex.firstMatch(in: normalized, range: range).flatMap { Range($0.range, in: normalized) }
        } else {
            foundRange = normalized.range(of: #"\d{4}[-/.]\d{1,2}[-/.]\d{1,2}"#, options: .regularExpression)
        }
        guard let match = foundRange else {
            return nil
        }
        let parts = normalized[match]
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
            .split(separator: "-")
            .compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    nonisolated static func dedupe(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { seen.insert($0.absoluteString).inserted }
    }

    private nonisolated static func stripHTML(_ raw: String) -> String {
        if let regex = stripHTMLRegex {
            let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
            return regex.stringByReplacingMatches(in: raw, range: range, withTemplate: " ")
        }
        return raw.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
    }

    private nonisolated static func urls(
        in any: Any?,
        sourceURL: URL?,
        depth: Int,
        matching predicate: (URL) -> Bool
    ) -> [URL] {
        guard depth <= 8, let any else { return [] }
        if let string = any as? String {
            return extractURLs(string, sourceURL: sourceURL).filter(predicate)
        }
        if let object = any as? BaJSONObject {
            return object.values.flatMap { urls(in: $0, sourceURL: sourceURL, depth: depth + 1, matching: predicate) }
        }
        if let array = any as? [Any] {
            return array.flatMap { urls(in: $0, sourceURL: sourceURL, depth: depth + 1, matching: predicate) }
        }
        return []
    }

    private nonisolated static func extractURLs(_ raw: String, sourceURL: URL?) -> [URL] {
        guard let regex = extractURLsRegex else { return [] }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        let urls = regex.matches(in: raw, range: range).compactMap { match -> URL? in
            guard let range = Range(match.range(at: 1), in: raw) else { return nil }
            return normalizeMediaURL(String(raw[range]), sourceURL: sourceURL)
        }
        return dedupe(urls)
    }

    private nonisolated static func extractAttributeURLs(_ raw: String, attribute: String, sourceURL: URL?) -> [URL] {
        // The attribute name is dynamic (passed as a parameter), so this
        // regex stays inline. In practice it is only ever called with
        // attribute == "src" from imageURLsFromHTML, but keep the dynamic
        // shape so callers retain the flexibility.
        guard let regex = try? NSRegularExpression(pattern: #"\b\#(attribute)\s*=\s*["']([^"']+)["']"#, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
        let urls = regex.matches(in: raw, range: range).compactMap { match -> URL? in
            guard let range = Range(match.range(at: 1), in: raw) else { return nil }
            return normalizeMediaURL(String(raw[range]), sourceURL: sourceURL)
        }
        return dedupe(urls)
    }

    private nonisolated static func hasInvalidGameKeeMediaTail(_ url: URL) -> Bool {
        guard url.host?.lowercased().hasSuffix("gamekee.com") == true else {
            return false
        }
        let segments = url.pathComponents.filter { $0 != "/" && $0.isEmpty == false }
        guard segments.count == 1 else { return false }
        return isPlaceholderMediaToken(segments[0])
    }
}
