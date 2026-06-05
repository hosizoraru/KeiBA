//
//  BaAppModel+StudentDetails.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func loadStudentDetail(entry: BaGuideCatalogEntry, force: Bool = false) async {
        if force == false, studentDetailStates[entry.contentId]?.value != nil {
            return
        }
        if force == false, let request = studentDetailRequests[entry.contentId] {
            await finishStudentDetailRequest(request, entry: entry)
            return
        }
        if force {
            studentDetailRequests[entry.contentId]?.task.cancel()
            studentDetailRequests[entry.contentId] = nil
        } else if let cached = await cacheStore.load(BaStudentGuideInfo.self, for: .studentDetail(entry.contentId)) {
            studentDetailStates[entry.contentId] = BaLoadableState(
                value: cached.value,
                isLoading: false,
                errorMessage: nil,
                lastSyncAt: cached.syncedAt,
                isShowingCache: true
            )
        }
        var state = studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
        state.isLoading = true
        state.errorMessage = nil
        studentDetailStates[entry.contentId] = state
        let request = StudentDetailRequest(
            token: UUID(),
            task: Task.detached(priority: .userInitiated) { [studentRepository] in
                try await studentRepository.fetchStudentDetail(entry: entry)
            }
        )
        studentDetailRequests[entry.contentId] = request
        await finishStudentDetailRequest(request, entry: entry)
    }

    func loadStudentDetails(
        entries: [BaGuideCatalogEntry],
        force: Bool = false,
        limit: Int? = nil,
        concurrency: Int = BaPlatformPerformanceProfile.musicDetailPrefetchConcurrency
    ) async {
        let uniqueEntries = Self.uniqueStudentDetailEntries(entries, limit: limit)
        await BaBoundedTaskGroup.run(
            uniqueEntries,
            maxConcurrentTasks: concurrency,
            priority: .userInitiated
        ) { [weak self] entry in
            await self?.loadStudentDetail(entry: entry, force: force)
        }
    }

    func imageData(for url: URL, refererPath: String = "/ba") async throws -> Data {
        try await imageCache.data(for: url, refererPath: refererPath)
    }

    func imageCacheSummary() async -> String {
        await imageCache.summary()
    }

    private func finishStudentDetailRequest(_ request: StudentDetailRequest, entry: BaGuideCatalogEntry) async {
        do {
            let snapshot = try await request.task.value
            guard studentDetailRequests[entry.contentId]?.token == request.token else { return }
            studentDetailRequests[entry.contentId] = nil
            await applyStudentDetailSnapshot(snapshot, entry: entry)
        } catch {
            guard studentDetailRequests[entry.contentId]?.token == request.token else { return }
            studentDetailRequests[entry.contentId] = nil
            guard Self.isCancellation(error) == false else {
                var cancelled = studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
                cancelled.isLoading = false
                studentDetailStates[entry.contentId] = cancelled
                return
            }
            var failed = studentDetailStates[entry.contentId] ?? BaLoadableState<BaStudentGuideInfo>()
            failed.isLoading = false
            failed.errorMessage = error.localizedDescription
            studentDetailStates[entry.contentId] = failed
        }
    }

    private func applyStudentDetailSnapshot(
        _ snapshot: BaRepositorySnapshot<BaStudentGuideInfo>,
        entry: BaGuideCatalogEntry
    ) async {
        let loadedState = BaLoadableState(
            value: snapshot.value,
            isLoading: false,
            errorMessage: BaDataErrorPresenter.studentDetailMessage(for: snapshot.sourceErrors.first),
            lastSyncAt: snapshot.syncedAt,
            isShowingCache: false
        )
        studentDetailStates[entry.contentId] = loadedState
        if snapshot.value.contentId != entry.contentId {
            studentDetailStates[snapshot.value.contentId] = loadedState
        }
        await cacheStore.save(
            snapshot.value,
            for: .studentDetail(entry.contentId),
            schemaVersion: 3,
            syncedAt: snapshot.syncedAt
        )
        if snapshot.value.contentId != entry.contentId {
            await cacheStore.save(
                snapshot.value,
                for: .studentDetail(snapshot.value.contentId),
                schemaVersion: 3,
                syncedAt: snapshot.syncedAt
            )
        }
    }

    private nonisolated static func uniqueStudentDetailEntries(
        _ entries: [BaGuideCatalogEntry],
        limit: Int?
    ) -> [BaGuideCatalogEntry] {
        var seen = Set<Int64>()
        var uniqueEntries: [BaGuideCatalogEntry] = []
        for entry in entries where entry.contentId > 0 {
            guard seen.insert(entry.contentId).inserted else { continue }
            uniqueEntries.append(entry)
            if let limit, uniqueEntries.count >= limit {
                break
            }
        }
        return uniqueEntries
    }
}

struct StudentDetailRequest {
    let token: UUID
    let task: Task<BaRepositorySnapshot<BaStudentGuideInfo>, Error>
}
