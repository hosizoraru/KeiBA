//
//  BaRepositoryModels.swift
//  KeiBAOS
//
//  Split from BaDomainModels.swift by Codex on 2026/05/16.
//

import Foundation

struct BaLoadableState<Value> {
    var value: Value?
    var isLoading: Bool
    var errorMessage: String?
    var lastSyncAt: Date?
    var isShowingCache: Bool

    init(
        value: Value? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        lastSyncAt: Date? = nil,
        isShowingCache: Bool = false
    ) {
        self.value = value
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.lastSyncAt = lastSyncAt
        self.isShowingCache = isShowingCache
    }
}

nonisolated struct BaCacheEnvelope<Value: Codable>: Codable {
    let schemaVersion: Int
    let syncedAt: Date
    let value: Value
}
