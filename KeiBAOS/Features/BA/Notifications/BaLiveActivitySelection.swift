//
//  BaLiveActivitySelection.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated enum BaLiveActivitySelection {
    static let maximumVisibleActivities = 1

    static func selectedCandidates(from candidates: [BaLiveActivityCandidate]) -> [BaLiveActivityCandidate] {
        Array(
            candidates
                .sorted { lhs, rhs in
                    if lhs.relevance != rhs.relevance {
                        return lhs.relevance > rhs.relevance
                    }

                    if lhs.endDate != rhs.endDate {
                        return lhs.endDate < rhs.endDate
                    }

                    return lhs.id < rhs.id
                }
                .prefix(maximumVisibleActivities)
        )
    }
}
