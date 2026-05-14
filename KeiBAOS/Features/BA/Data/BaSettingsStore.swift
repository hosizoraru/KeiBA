//
//  BaSettingsStore.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import Foundation

struct BaSettingsStore {
    private let defaults: UserDefaults
    private let key = "ba.app.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> BaAppSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder.ba.decode(BaAppSettings.self, from: data)
        else {
            return .defaults()
        }
        return settings
    }

    func save(_ settings: BaAppSettings) {
        guard let data = try? JSONEncoder.ba.encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
