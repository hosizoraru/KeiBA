//
//  BaSettingsStore.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaSettingsStore {
    private let defaults: UserDefaults
    private let legacyKey = "ba.app.settings.v1"
    private let envelopeKey = "ba.app.settings.v2"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadEnvelope() -> BaSettingsEnvelope {
        if let data = defaults.data(forKey: envelopeKey),
           let envelope = try? JSONDecoder.ba.decode(BaSettingsEnvelope.self, from: data)
        {
            return envelope.normalized()
        }
        guard let data = defaults.data(forKey: legacyKey),
              let settings = try? JSONDecoder.ba.decode(BaAppSettings.self, from: data)
        else {
            return .defaults()
        }
        let envelope = BaSettingsEnvelope.migrated(from: settings).normalized()
        saveEnvelope(envelope)
        return envelope
    }

    func load() -> BaAppSettings {
        loadEnvelope().flattenedSettings()
    }

    func save(_ settings: BaAppSettings) {
        saveEnvelope(BaSettingsEnvelope.migrated(from: settings))
    }

    func saveEnvelope(_ envelope: BaSettingsEnvelope) {
        guard let data = try? JSONEncoder.ba.encode(envelope.normalized()) else { return }
        defaults.set(data, forKey: envelopeKey)
    }
}

nonisolated extension BaSettingsEnvelope {
    func normalized() -> BaSettingsEnvelope {
        var copy = self
        copy.schemaVersion = Self.currentSchemaVersion
        if BaServer.allCases.contains(copy.selectedServer) == false {
            copy.selectedServer = .cn
        }
        for server in BaServer.allCases where copy.serverProfiles[server] == nil {
            copy.serverProfiles[server] = .defaults()
        }
        for server in BaServer.allCases {
            copy.serverProfiles[server] = copy.serverProfiles[server]?.normalized()
        }
        if copy.globalSettings.identityIndependentByServer == false {
            let shared = copy.profile(for: copy.selectedServer)
            for server in BaServer.allCases {
                copy.serverProfiles[server]?.nickname = shared.nickname
                copy.serverProfiles[server]?.friendCode = shared.friendCode
            }
        }
        return copy
    }
}
