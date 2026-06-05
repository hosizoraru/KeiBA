//
//  BaUserDataMergePolicy.swift
//  KeiBA
//
//  Created by Codex on 2026/05/17.
//

import Foundation

nonisolated enum BaUserDataMergeDecision: Equatable, Sendable {
    case keepLocal
    case uploadLocal
    case applyRemote
}

nonisolated enum BaUserDataMergePolicy {
    static func decision(
        local: BaUserDataEnvelope,
        remote: BaUserDataEnvelope?
    ) -> BaUserDataMergeDecision {
        guard let remote else {
            return .uploadLocal
        }
        let normalizedLocal = local.normalized()
        let normalizedRemote = remote.normalized()
        if normalizedRemote.updatedAt > normalizedLocal.updatedAt {
            return .applyRemote
        }
        if normalizedLocal.updatedAt > normalizedRemote.updatedAt {
            return .uploadLocal
        }
        return normalizedLocal == normalizedRemote ? .keepLocal : .uploadLocal
    }
}
