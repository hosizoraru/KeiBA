//
//  BaSameNameStudentCatalogResolver.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated enum BaSameNameStudentCatalogResolver {
    static func catalogEntry(
        for item: BaStudentProfileSameNameRoleItem,
        catalogEntries: [BaGuideCatalogEntry]
    ) -> BaGuideCatalogEntry? {
        if let contentId = item.guideURL.flatMap(BaSameNameStudentGuideLinkResolver.contentID(from:)),
           let entry = catalogEntries.first(where: { $0.contentId == contentId })
        {
            return entry
        }

        let lookupNames = normalizedLookupNames(from: item.name)
        guard lookupNames.isEmpty == false else {
            return item.catalogEntry
        }

        if let exact = catalogEntries.first(where: { entry in
            entry.normalizedSameNameLookupTokens.contains { lookupNames.contains($0) }
        }) {
            return exact
        }

        return item.catalogEntry
    }

    static func normalizedLookupNames(from raw: String) -> Set<String> {
        let stripped = stripDisplayPrefix(raw)
        let candidates = [
            stripped,
            stripped
                .replacingOccurrences(of: "（", with: "(")
                .replacingOccurrences(of: "）", with: ")"),
            stripped
                .replacingOccurrences(of: "(", with: "（")
                .replacingOccurrences(of: ")", with: "）"),
        ]
        return Set(candidates.map(normalizeName).filter { $0.isEmpty == false })
    }

    // Compiled once. Hit per same-name role row during student detail recompose;
    // an inline regex compile per call dominated when the body re-evaluated.
    private nonisolated(unsafe) static let displayPrefixRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"^(?:★+\s*\d*|\d+\s*星|NPC|npc)\s*"#)
    }()

    private static func stripDisplayPrefix(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped: String
        if let regex = displayPrefixRegex {
            let range = NSRange(trimmed.startIndex ..< trimmed.endIndex, in: trimmed)
            stripped = regex.stringByReplacingMatches(in: trimmed, range: range, withTemplate: "")
        } else {
            stripped = trimmed.replacingOccurrences(
                of: #"^(?:★+\s*\d*|\d+\s*星|NPC|npc)\s*"#,
                with: "",
                options: .regularExpression
            )
        }
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeName(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private extension BaGuideCatalogEntry {
    nonisolated var normalizedSameNameLookupTokens: Set<String> {
        var tokens = Set<String>()
        for value in [name, alias, aliasDisplay] {
            for token in value.baSameNameAliasTokens {
                tokens.formUnion(BaSameNameStudentCatalogResolver.normalizedLookupNames(from: token))
            }
        }
        return tokens
    }
}

private extension String {
    nonisolated var baSameNameAliasTokens: [String] {
        components(separatedBy: CharacterSet(charactersIn: "/／|｜,，;；\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}
