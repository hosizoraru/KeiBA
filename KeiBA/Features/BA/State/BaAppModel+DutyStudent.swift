//
//  BaAppModel+DutyStudent.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import Foundation

extension BaAppModel {
    func canSetDutyStudent(_ entry: BaGuideCatalogEntry) -> Bool {
        entry.contentId > 0
    }

    func isDutyStudent(_ entry: BaGuideCatalogEntry) -> Bool {
        guard let dutyStudent = settings.dutyStudent else { return false }
        return dutyIdentityKeys(for: entry).contains(dutyStudent.contentId)
    }

    func currentDutyStudentIdentityKeys() -> Set<Int64> {
        guard let dutyStudent = settings.dutyStudent else { return [] }
        var keys: Set<Int64> = [dutyStudent.contentId]
        if let match = catalogState.value?.entries.first(where: { $0.identityKeys.contains(dutyStudent.contentId) }) {
            keys.formUnion(match.identityKeys)
        }
        for (requestedContentID, state) in studentDetailStates {
            guard let info = state.value, info.contentId == dutyStudent.contentId else { continue }
            keys.insert(requestedContentID)
            keys.insert(info.contentId)
        }
        return keys
    }

    func toggleDutyStudent(_ entry: BaGuideCatalogEntry) async {
        guard canSetDutyStudent(entry) else { return }
        if isDutyStudent(entry) {
            clearDutyStudent()
        } else {
            await setDutyStudent(entry)
        }
    }

    func clearDutyStudent() {
        updateGlobalSettings { settings in
            settings.dutyStudent = nil
        }
    }

    func setDutyStudent(_ entry: BaGuideCatalogEntry) async {
        guard canSetDutyStudent(entry) else { return }
        let fallbackStudent = dutyStudent(from: entry)
        updateGlobalSettings { settings in
            settings.dutyStudent = fallbackStudent
        }

        if studentDetailStates[entry.contentId]?.value == nil {
            await loadStudentDetail(entry: entry)
        }

        guard isDutyStudent(entry) else { return }
        let resolvedStudent = dutyStudent(from: entry)
        guard settings.dutyStudent != resolvedStudent else { return }
        updateGlobalSettings { settings in
            settings.dutyStudent = resolvedStudent
        }
    }

    private func dutyStudent(from entry: BaGuideCatalogEntry) -> BaDutyStudent {
        let info = studentDetailStates[entry.contentId]?.value
        let catalogEntry = canonicalDutyEntry(for: entry)
        let imageURL = info?.preferredPortraitURL(fallback: catalogEntry?.iconURL ?? entry.iconURL) ??
            catalogEntry?.iconURL ??
            entry.iconURL
        return BaDutyStudent(
            contentId: info?.contentId ?? catalogEntry?.contentId ?? entry.contentId,
            name: info?.title ?? catalogEntry?.name ?? entry.name,
            avatarURL: imageURL
        )
    }

    private func canonicalDutyEntry(for entry: BaGuideCatalogEntry) -> BaGuideCatalogEntry? {
        if let match = catalogState.value?.entries.first(where: { sharesFavoriteIdentity($0, entry) }) {
            return match
        }
        return settings.favoriteCatalogEntries.first { sharesFavoriteIdentity($0, entry) }
    }

    private func dutyIdentityKeys(for entry: BaGuideCatalogEntry) -> Set<Int64> {
        var keys = favoriteIdentityKeys(for: entry)
        if let catalogEntry = canonicalDutyEntry(for: entry) {
            keys.formUnion(favoriteIdentityKeys(for: catalogEntry))
        }
        if let info = studentDetailStates[entry.contentId]?.value, info.contentId > 0 {
            keys.insert(info.contentId)
        }
        return keys
    }
}
