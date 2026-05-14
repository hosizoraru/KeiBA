//
//  GameKeeJSON.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

typealias BaJSONObject = [String: Any]

enum GameKeeJSON {
    nonisolated static func rootObject(from data: Data) throws -> BaJSONObject {
        guard let object = try JSONSerialization.jsonObject(with: data) as? BaJSONObject else {
            throw GameKeeError.invalidResponse("root")
        }
        if let code = object.int("code"), code != 0 {
            throw GameKeeError.apiCode(code)
        }
        return object
    }

    nonisolated static func dataArray(from data: Data) throws -> [BaJSONObject] {
        let root = try rootObject(from: data)
        return root["data"] as? [BaJSONObject] ?? []
    }

    nonisolated static func dataObject(from data: Data) throws -> BaJSONObject {
        let root = try rootObject(from: data)
        guard let object = root["data"] as? BaJSONObject else {
            throw GameKeeError.invalidResponse("data")
        }
        return object
    }

    nonisolated static func normalizeGameKeeLink(_ raw: String, fallback: String = "https://www.gamekee.com/ba") -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return URL(string: fallback) }
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
        return URL(string: "https://www.gamekee.com/\(value)")
    }

    nonisolated static func normalizeImageURL(_ raw: String) -> URL? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return nil }
        if value.hasPrefix("file://") {
            return URL(string: value)
        }
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
        return URL(string: "https://www.gamekee.com/\(value)")
    }

    nonisolated static func findImageURL(in any: Any?, depth: Int = 0) -> URL? {
        guard depth <= 4, let any else { return nil }
        if let string = any as? String {
            guard let url = normalizeImageURL(string), looksLikeImageURL(url.absoluteString) else {
                return nil
            }
            return url
        }
        if let object = any as? BaJSONObject {
            for key in imageDirectKeys {
                if let raw = object.string(key), let url = normalizeImageURL(raw), looksLikeImageURL(url.absoluteString) {
                    return url
                }
            }
            for value in object.values {
                if let found = findImageURL(in: value, depth: depth + 1) {
                    return found
                }
            }
        }
        if let array = any as? [Any] {
            for value in array {
                if let found = findImageURL(in: value, depth: depth + 1) {
                    return found
                }
            }
        }
        return nil
    }

    nonisolated static func findURLs(in any: Any?, depth: Int = 0, matching predicate: (String) -> Bool) -> [URL] {
        guard depth <= 8, let any else { return [] }
        if let string = any as? String {
            return extractURLs(from: string).filter { predicate($0.absoluteString) }
        }
        if let object = any as? BaJSONObject {
            return object.values.flatMap { findURLs(in: $0, depth: depth + 1, matching: predicate) }
        }
        if let array = any as? [Any] {
            return array.flatMap { findURLs(in: $0, depth: depth + 1, matching: predicate) }
        }
        return []
    }

    nonisolated static func extractTextPairs(in any: Any?, limit: Int = 120) -> [(String, String)] {
        var rows: [(String, String)] = []
        collectTextPairs(in: any, rows: &rows, depth: 0, limit: limit)
        return rows
    }

    nonisolated static func extractPlainText(from raw: String) -> String {
        raw
            .replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }

    nonisolated private static let imageDirectKeys = [
        "image_url", "img_url", "cover_url", "cover", "cover_img", "cover_image",
        "topic_img", "topic_image", "title_img", "main_img", "list_img", "small_img",
        "image", "img", "picture", "big_picture", "pic_url", "pic", "thumb",
        "thumb_image", "thumbnail", "avatar", "banner", "icon", "logo"
    ]

    nonisolated private static func looksLikeImageURL(_ raw: String) -> Bool {
        guard let url = normalizeImageURL(raw) else { return false }
        let value = url.absoluteString.lowercased()
        let pathExtension = url.pathExtension.lowercased()
        if ["json", "mp4", "mov", "m3u8", "mp3", "m4a", "wav", "aac"].contains(pathExtension) {
            return false
        }
        guard value.hasPrefix("http") || value.hasPrefix("//") || value.hasPrefix("/") else {
            return false
        }
        if ["jpg", "jpeg", "png", "webp", "gif", "svg"].contains(pathExtension) {
            return true
        }
        let host = url.host?.lowercased() ?? ""
        return host.contains("cdnimg") ||
            value.contains("image") ||
            value.contains("img") ||
            value.contains("upload")
    }

    nonisolated private static func extractURLs(from raw: String) -> [URL] {
        let pattern = #"((?:https?:)?//[^\s"'<>\\]+|/[A-Za-z0-9_\-./%]+(?:\?[^\s"'<>\\]+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        return regex.matches(in: raw, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: raw) else { return nil }
            return normalizeImageURL(String(raw[range]))
        }
    }

    nonisolated private static func collectTextPairs(
        in any: Any?,
        rows: inout [(String, String)],
        depth: Int,
        limit: Int
    ) {
        guard rows.count < limit, depth <= 8, let any else { return }
        if let object = any as? BaJSONObject {
            if let key = object.preferredText(keys: ["key", "name", "title", "label", "header", "left"]),
               let value = object.preferredText(keys: ["value", "text", "content", "desc", "description", "right"]),
               key != value {
                rows.append((key, value))
            }
            for value in object.values {
                collectTextPairs(in: value, rows: &rows, depth: depth + 1, limit: limit)
            }
            return
        }
        if let array = any as? [Any] {
            for value in array {
                collectTextPairs(in: value, rows: &rows, depth: depth + 1, limit: limit)
            }
        }
    }
}

extension BaJSONObject {
    nonisolated func string(_ key: String) -> String? {
        if let string = self[key] as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = self[key] as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    nonisolated func int(_ key: String) -> Int? {
        if let value = self[key] as? Int {
            return value
        }
        if let value = self[key] as? NSNumber {
            return value.intValue
        }
        if let value = string(key) {
            return Int(value)
        }
        return nil
    }

    nonisolated func int64(_ key: String) -> Int64? {
        if let value = self[key] as? Int64 {
            return value
        }
        if let value = self[key] as? Int {
            return Int64(value)
        }
        if let value = self[key] as? NSNumber {
            return value.int64Value
        }
        if let value = string(key) {
            return Int64(value)
        }
        return nil
    }

    nonisolated func dateFromSeconds(_ key: String) -> Date? {
        guard let seconds = int64(key), seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    nonisolated func object(_ key: String) -> BaJSONObject? {
        self[key] as? BaJSONObject
    }

    nonisolated func preferredText(keys: [String]) -> String? {
        for key in keys {
            if let value = string(key) {
                let plain = GameKeeJSON.extractPlainText(from: value)
                if plain.isEmpty == false {
                    return plain
                }
            }
        }
        return nil
    }
}
