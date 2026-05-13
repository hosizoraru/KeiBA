//
//  BaOverviewView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaOverviewView: View {
    private let office = BaOfficeSnapshot.preview
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BaScreenIntro(
                    eyebrow: String(localized: "ba.overview.eyebrow"),
                    title: String(localized: "ba.overview.title"),
                    detail: String(localized: "ba.overview.detail"),
                    systemImage: "building.2.crop.circle.fill",
                    tint: BaDesign.blue
                )

                officeCard
                cafePreviewCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 20)
        }
        .background(AppBackground())
    }

    private var officeCard: some View {
        LiquidGlassSurface(cornerRadius: 32, tint: BaDesign.blue.opacity(0.11)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "ba.office.overview.title"))
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                BaInfoPanel(tint: BaDesign.blue) {
                    VStack(spacing: 12) {
                        BaValueRow(
                            title: String(localized: "ba.office.nickname.label"),
                            value: office.nickname,
                            suffix: office.teacherSuffix,
                            systemImage: "person.crop.square.fill",
                            tint: BaDesign.blue
                        )

                        BaValueRow(
                            title: String(localized: "ba.office.friendCode.label"),
                            value: office.friendCode,
                            systemImage: "number.square.fill",
                            tint: BaDesign.blue
                        )
                    }
                }

                BaInfoPanel(tint: BaDesign.violet) {
                    VStack(spacing: 12) {
                        BaValueRow(
                            title: String(localized: "ba.office.catalog.label"),
                            value: String(localized: "ba.office.catalog.value"),
                            systemImage: "rectangle.stack.person.crop.fill",
                            tint: BaDesign.violet
                        )

                        BaValueRow(
                            title: String(localized: "ba.office.server.label"),
                            value: office.server,
                            systemImage: "server.rack",
                            tint: BaDesign.violet
                        )
                    }
                }

                apPanel

                LazyVGrid(columns: columns, spacing: 12) {
                    BaMetricTile(
                        title: String(localized: "ba.office.ap.sync.label"),
                        value: office.apSyncAt,
                        systemImage: "calendar.badge.clock",
                        tint: BaDesign.blue
                    )

                    BaMetricTile(
                        title: String(localized: "ba.office.ap.full.label"),
                        value: office.apFullAt,
                        systemImage: "calendar.badge.checkmark",
                        tint: BaDesign.cyan
                    )
                }
            }
        }
    }

    private var apPanel: some View {
        BaInfoPanel(tint: BaDesign.green) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Label(String(localized: "ba.office.ap.label"), systemImage: "bolt.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BaDesign.green)

                    Spacer(minLength: 12)

                    HStack(spacing: 7) {
                        LiquidGlassPill(tint: BaDesign.green, horizontalPadding: 18) {
                            Text(office.apCurrent)
                                .font(.title3.monospacedDigit().bold())
                                .foregroundStyle(BaDesign.green)
                        }

                        Text("/")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        LiquidGlassPill(tint: BaDesign.green, horizontalPadding: 18) {
                            Text(office.apLimit)
                                .font(.title3.monospacedDigit().bold())
                                .foregroundStyle(BaDesign.green)
                        }
                    }
                }

                Text(apStatusText)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(BaDesign.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
    }

    private var cafePreviewCard: some View {
        LiquidGlassSurface(cornerRadius: 30, tint: BaDesign.green.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Label(String(localized: "ba.office.cafeAp.title"), systemImage: "cup.and.saucer.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 12)

                    LiquidGlassPill(tint: BaDesign.green, horizontalPadding: 16) {
                        Text("\(office.cafeApCurrent)/\(office.cafeApLimit)")
                            .font(.headline.monospacedDigit().weight(.bold))
                            .foregroundStyle(BaDesign.green)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    BaMetricTile(
                        title: String(localized: "ba.cafe.metric.visit"),
                        value: office.cafeVisitRefresh,
                        systemImage: "person.crop.circle.badge.clock",
                        tint: BaDesign.pink
                    )

                    BaMetricTile(
                        title: String(localized: "ba.cafe.metric.tactical"),
                        value: office.tacticalRefresh,
                        systemImage: "scope",
                        tint: BaDesign.amber
                    )
                }
            }
        }
    }

    private var apStatusText: String {
        String(
            format: String(localized: "ba.office.ap.status.format"),
            office.apNext,
            office.apFullRemain
        )
    }
}

#Preview {
    NavigationStack {
        BaOverviewView()
    }
}
