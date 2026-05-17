//
//  BaStudentProfileCollectionExtensions.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension Array where Element == BaGuideRow {
    nonisolated func sortedByKeyNumbers() -> [BaGuideRow] {
        sorted {
            let lhs = sortKeyNumbers($0.title)
            let rhs = sortKeyNumbers($1.title)
            if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return normalizeProfileFieldKey($0.title) < normalizeProfileFieldKey($1.title)
        }
    }
}

extension Array where Element == BaGuideGalleryItem {
    nonisolated func distinctByMedia() -> [BaGuideGalleryItem] {
        var seen = Set<String>()
        return filter { item in
            let media = item.mediaURL ?? item.imageURL
            let key = "\(item.mediaKind?.rawValue ?? "")|\(media?.absoluteString ?? item.id)"
            return seen.insert(key).inserted
        }
    }

    nonisolated func sortedByTitleNumbers() -> [BaGuideGalleryItem] {
        sorted {
            let lhs = sortKeyNumbers($0.title)
            let rhs = sortKeyNumbers($1.title)
            if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return $0.title < $1.title
        }
    }
}

extension Array where Element == URL {
    nonisolated func dedupedByAbsoluteString() -> [URL] {
        var seen = Set<String>()
        return filter { seen.insert($0.absoluteString).inserted }
    }
}

extension Array where Element == String {
    nonisolated func deduped() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

extension String {
    nonisolated var baProfileTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var baProfileIsBlank: Bool {
        baProfileTrimmed.isEmpty
    }

    nonisolated var baProfileIsNotBlank: Bool {
        baProfileIsBlank == false
    }

    nonisolated var baProfileNonEmptyUnlessPlaceholder: String? {
        let value = baProfileTrimmed
        guard value.baProfileIsNotBlank, isProfileValuePlaceholder(value) == false else { return nil }
        return value
    }

    nonisolated func baProfileIfBlank(_ fallback: String) -> String {
        baProfileIsBlank ? fallback : self
    }

    nonisolated func baProfileSubstringBefore(_ delimiter: String) -> String {
        guard let range = range(of: delimiter) else { return self }
        return String(self[..<range.lowerBound])
    }
}
