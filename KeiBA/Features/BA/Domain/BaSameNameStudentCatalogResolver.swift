//
//  BaSameNameStudentCatalogResolver.swift
//  KeiBA
//
//  Created by Codex on 2026/05/15.
//

import Foundation

nonisolated enum BaSameNameStudentCatalogResolver {
    static func catalogEntry(
        for item: BaStudentProfileSameNameRoleItem,
        catalogEntries: [BaGuideCatalogEntry]
    ) -> BaGuideCatalogEntry? {
        Index(catalogEntries: catalogEntries).resolve(for: item) ?? item.catalogEntry
    }

    // Build an index once and resolve many items against it. The student detail
    // view passes a closure that calls catalogEntry(forSameNameRole:) once per
    // role row at section-init time; without an index, every call recomputed
    // normalizedSameNameLookupTokens for every catalog entry — N × M heavy
    // string work on each detail open.
    static func resolveAll(
        items: [BaStudentProfileSameNameRoleItem],
        catalogEntries: [BaGuideCatalogEntry]
    ) -> [String: BaGuideCatalogEntry] {
        guard items.isEmpty == false else { return [:] }
        let index = Index(catalogEntries: catalogEntries)
        var result: [String: BaGuideCatalogEntry] = [:]
        result.reserveCapacity(items.count)
        for item in items {
            if let resolved = index.resolve(for: item) {
                result[item.id] = resolved
            }
        }
        return result
    }

    fileprivate struct Index {
        private let entryByContentID: [Int64: BaGuideCatalogEntry]
        // Map normalized name token → first catalog entry that owns it. Built
        // once per index; lookups are O(item-tokens) instead of O(catalog).
        private let entryByNameToken: [String: BaGuideCatalogEntry]

        init(catalogEntries: [BaGuideCatalogEntry]) {
            var byContentID: [Int64: BaGuideCatalogEntry] = [:]
            byContentID.reserveCapacity(catalogEntries.count)
            var byNameToken: [String: BaGuideCatalogEntry] = [:]
            byNameToken.reserveCapacity(catalogEntries.count * 3)
            for entry in catalogEntries {
                if entry.contentId > 0 {
                    byContentID[entry.contentId] = entry
                }
                for token in entry.normalizedSameNameLookupTokens {
                    if byNameToken[token] == nil {
                        byNameToken[token] = entry
                    }
                }
            }
            entryByContentID = byContentID
            entryByNameToken = byNameToken
        }

        func resolve(for item: BaStudentProfileSameNameRoleItem) -> BaGuideCatalogEntry? {
            if let contentId = item.guideURL.flatMap(BaSameNameStudentGuideLinkResolver.contentID(from:)),
               let entry = entryByContentID[contentId]
            {
                return entry
            }
            let lookupNames = normalizedLookupNames(from: item.name)
            for name in lookupNames {
                if let entry = entryByNameToken[name] {
                    return entry
                }
            }
            return nil
        }
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
    private nonisolated static let displayPrefixRegex: NSRegularExpression? = {
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
