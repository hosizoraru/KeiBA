//
//  BaSettingsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BaScreenIntro(
                    eyebrow: String(localized: "ba.settings.eyebrow"),
                    title: String(localized: "ba.settings.title"),
                    detail: String(localized: "ba.settings.detail"),
                    systemImage: "gearshape.2.fill",
                    tint: BaDesign.amber
                )

                settingsCard
                baselineCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 20)
        }
        .background(AppBackground())
    }

    private var settingsCard: some View {
        LiquidGlassSurface(cornerRadius: 30, tint: BaDesign.amber.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "ba.settings.preferences.title"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                SettingsActionRow(
                    title: String(localized: "ba.settings.server.title"),
                    value: String(localized: "ba.office.server.value"),
                    systemImage: "server.rack",
                    tint: BaDesign.violet
                )

                SettingsActionRow(
                    title: String(localized: "ba.settings.notifications.title"),
                    value: String(localized: "ba.settings.notifications.value"),
                    systemImage: "bell.badge.fill",
                    tint: BaDesign.blue
                )

                SettingsActionRow(
                    title: String(localized: "ba.settings.refresh.title"),
                    value: String(localized: "ba.settings.refresh.value"),
                    systemImage: "arrow.clockwise.circle.fill",
                    tint: BaDesign.green
                )
            }
        }
    }

    private var baselineCard: some View {
        LiquidGlassSurface(cornerRadius: 30, tint: BaDesign.cyan.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "ba.settings.platform.title"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                ForEach(AppPlatformBaseline.allCases) { baseline in
                    SettingsActionRow(
                        title: baseline.displayName,
                        value: baseline.minimumVersion,
                        systemImage: baseline.systemImage,
                        tint: BaDesign.cyan
                    )
                }

                SettingsActionRow(
                    title: String(localized: "ba.settings.watch.rule.title"),
                    value: AppPlatformBaseline.watchRule,
                    systemImage: "applewatch",
                    tint: BaDesign.pink
                )
            }
        }
    }
}

private struct SettingsActionRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        BaInfoPanel(tint: tint) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 28)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BaSettingsView()
    }
}
