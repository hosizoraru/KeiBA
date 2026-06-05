//
//  BaSettingsStore.swift
//  KeiBA
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaSettingsStore {
    private let defaults: UserDefaults
    private let envelopeKey = "ba.app.settings.v2"
    private let userDataUpdatedAtKey = "ba.app.userData.updatedAt.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadEnvelope() -> BaSettingsEnvelope {
        if let data = defaults.data(forKey: envelopeKey),
           let envelope = try? JSONDecoder.ba.decode(BaSettingsEnvelope.self, from: data)
        {
            return envelope.normalized()
        }
        return .defaults()
    }

    func load() -> BaAppSettings {
        loadEnvelope().flattenedSettings()
    }

    func saveEnvelope(_ envelope: BaSettingsEnvelope, updatedAt: Date = Date()) {
        guard let data = try? JSONEncoder.ba.encode(envelope.normalized()) else { return }
        defaults.set(data, forKey: envelopeKey)
        defaults.set(updatedAt, forKey: userDataUpdatedAtKey)
    }

    func loadUserData(updatedAt fallbackUpdatedAt: Date = .distantPast) -> BaUserDataEnvelope {
        loadEnvelope().userData(updatedAt: userDataUpdatedAt(fallback: fallbackUpdatedAt))
    }

    func userDataUpdatedAt(fallback: Date = .distantPast) -> Date {
        defaults.object(forKey: userDataUpdatedAtKey) as? Date ?? fallback
    }

    func saveUserData(_ userData: BaUserDataEnvelope) {
        let normalized = userData.normalized()
        saveEnvelope(normalized.settingsEnvelope(), updatedAt: normalized.updatedAt)
    }

    func exportUserData(updatedAt: Date = Date()) throws -> Data {
        try JSONEncoder.ba.encode(loadUserData(updatedAt: updatedAt).normalized(updatedAt: updatedAt))
    }

    @discardableResult
    func importUserData(from data: Data) throws -> BaUserDataEnvelope {
        let userData = try JSONDecoder.ba.decode(BaUserDataEnvelope.self, from: data).normalized()
        saveUserData(userData)
        return userData
    }

}
