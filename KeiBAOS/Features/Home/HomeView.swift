//
//  HomeView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct HomeView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LiquidGlassSurface(cornerRadius: 28, tint: .cyan.opacity(0.16)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.cyan)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "home.hero.title"))
                                .font(.title.bold())
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text(String(localized: "home.hero.subtitle"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    HomeMetricTile(
                        title: String(localized: "home.metric.platform.title"),
                        value: AppPlatformBaseline.summary,
                        systemImage: "iphone.and.arrow.forward"
                    )
                    HomeMetricTile(
                        title: String(localized: "home.metric.shell.title"),
                        value: String(localized: "home.metric.shell.value"),
                        systemImage: "square.grid.2x2.fill"
                    )
                    HomeMetricTile(
                        title: String(localized: "home.metric.data.title"),
                        value: String(localized: "home.metric.data.value"),
                        systemImage: "externaldrive.fill"
                    )
                    HomeMetricTile(
                        title: String(localized: "home.metric.watch.title"),
                        value: AppPlatformBaseline.watchRule,
                        systemImage: "applewatch"
                    )
                }

                LiquidGlassSurface(tint: .mint.opacity(0.12)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(String(localized: "home.foundation.title"), systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(String(localized: "home.foundation.detail"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 92)
        }
        .background(AppBackground())
        .navigationTitle(String(localized: "tab.home"))
        .platformInlineNavigationTitle()
    }
}

private struct HomeMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        LiquidGlassSurface(cornerRadius: 22, padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14), tint: .blue.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .lineLimit(1)

                    Text(value)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
