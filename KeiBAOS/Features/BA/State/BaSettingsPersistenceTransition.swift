//
//  BaSettingsPersistenceTransition.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import Foundation

nonisolated struct BaSettingsPersistenceOutcome {
    let envelope: BaSettingsEnvelope
    let settings: BaAppSettings
    let shouldResetServerScopedTimelineState: Bool
    let shouldRequestNotificationAuthorization: Bool
}

nonisolated enum BaSettingsPersistenceTransition {
    static func outcome(
        envelope: BaSettingsEnvelope,
        previousServer: BaServer,
        previousEnvelope: BaSettingsEnvelope?
    ) -> BaSettingsPersistenceOutcome {
        let normalizedEnvelope = envelope.normalized()
        let settings = normalizedEnvelope.flattenedSettings()
        let shouldRequestAuthorization = previousEnvelope.map {
            BaNotificationPreferenceSnapshot(envelope: normalizedEnvelope)
                .becameEnabled(from: BaNotificationPreferenceSnapshot(envelope: $0))
        } ?? false

        return BaSettingsPersistenceOutcome(
            envelope: normalizedEnvelope,
            settings: settings,
            shouldResetServerScopedTimelineState: previousServer != settings.server,
            shouldRequestNotificationAuthorization: shouldRequestAuthorization
        )
    }
}
