//
//  SettingsView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LiquidGlassSurface(cornerRadius: 32, tint: .orange.opacity(0.12)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "settings.hero.title"))
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Text(String(localized: "settings.hero.subtitle"))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(AppPlatformBaseline.allCases) { baseline in
                        SettingsInfoRow(
                            title: baseline.displayName,
                            value: baseline.minimumVersion,
                            systemImage: baseline.systemImage
                        )
                    }
                }

                LiquidGlassSurface(tint: .teal.opacity(0.10)) {
                    SettingsInfoRow(
                        title: String(localized: "settings.watch.rule.title"),
                        value: AppPlatformBaseline.watchRule,
                        systemImage: "applewatch"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 92)
        }
        .background(AppBackground())
        .navigationTitle(String(localized: "tab.settings"))
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        LiquidGlassSurface(cornerRadius: 24, padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16), tint: .gray.opacity(0.08)) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Text(value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
