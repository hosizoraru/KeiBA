//
//  BaGuideRichTextExtractor.swift
//  KeiBA
//
//  Created by Codex on 2026/05/16.
//

import Foundation

enum BaGuideRichTextExtractor {
    static func text(from any: Any?, separator: String = " ") -> String {
        lines(from: any).joined(separator: separator)
    }

    static func lines(from any: Any?, sourceURL: URL? = nil) -> [String] {
        extractLines(from: any, sourceURL: sourceURL, depth: 0)
    }

    private static func extractLines(from any: Any?, sourceURL: URL?, depth: Int) -> [String] {
        guard depth <= 12, let any else { return [] }

        if let string = any as? String {
            return cleanLine(string, sourceURL: sourceURL).map { [$0] } ?? []
        }

        if let number = any as? NSNumber {
            return [number.stringValue]
        }

        if let array = any as? [Any] {
            return array.flatMap { extractLines(from: $0, sourceURL: sourceURL, depth: depth + 1) }
        }

        guard let object = any as? BaJSONObject else { return [] }

        if isMediaNode(object) {
            return []
        }

        if let directText = object["text"] {
            let directLines = extractLines(from: directText, sourceURL: sourceURL, depth: depth + 1)
            if directLines.isEmpty == false {
                return directLines
            }
        }

        if let children = object["children"] as? [Any] {
            let inline = children
                .flatMap { extractLines(from: $0, sourceURL: sourceURL, depth: depth + 1) }
                .joined()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if inline.isEmpty == false {
                return [inline]
            }
        }

        var lines: [String] = []
        for key in richTextTraversalKeys where key != "text" && key != "children" {
            lines.append(contentsOf: extractLines(from: object[key], sourceURL: sourceURL, depth: depth + 1))
        }
        return lines
    }

    private static func cleanLine(_ raw: String, sourceURL: URL?) -> String? {
        let value = BaGuideTextNormalizer.cleanDisplayText(raw)
        guard value.isEmpty == false else { return nil }
        if ignoredRichTextTokens.contains(value.lowercased()) {
            return nil
        }
        if looksLikeMediaToken(raw, sourceURL: sourceURL) || looksLikeMediaToken(value, sourceURL: sourceURL) {
            return nil
        }
        return value
    }

    private static func isMediaNode(_ object: BaJSONObject) -> Bool {
        let type = BaGuideTextNormalizer.normalizedKey(object.string("type") ?? "")
        return ["image", "audio", "video"].contains(type)
    }

    private static func looksLikeMediaToken(_ raw: String, sourceURL: URL?) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return false }
        // CharacterSet membership avoids a per-call regex compile and
        // gives the same answer as `\s`. Hit on every rich-text traversal
        // node during student detail ingestion.
        if value.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            return false
        }
        guard let url = BaGuideTextNormalizer.normalizeMediaURL(value, sourceURL: sourceURL) else {
            return false
        }
        return BaGuideTextNormalizer.looksLikeImageURL(url) ||
            BaGuideTextNormalizer.looksLikeAudioURL(url) ||
            BaGuideTextNormalizer.looksLikeVideoURL(url)
    }
}

private let richTextTraversalKeys = [
    "text",
    "children",
    "data",
    "content",
    "title",
    "name",
    "label",
    "desc",
    "description",
    "value",
]

private let ignoredRichTextTokens: Set<String> = [
    "simpleeditor",
    "paragraph",
    "illustrated-book",
    "image",
    "audio",
    "video",
]
