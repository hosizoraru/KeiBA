//
//  BaCafeView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaCafeView: View {
    private let office = BaOfficeSnapshot.preview
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BaScreenIntro(
                    eyebrow: String(localized: "ba.cafe.eyebrow"),
                    title: String(localized: "ba.cafe.title"),
                    detail: String(localized: "ba.cafe.detail"),
                    systemImage: "cup.and.saucer.fill",
                    tint: BaDesign.pink
                )

                cafeStorageCard
                cafeActionCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .safeAreaPadding(.bottom, 20)
        }
        .background(AppBackground())
    }

    private var cafeStorageCard: some View {
        LiquidGlassSurface(cornerRadius: 32, tint: BaDesign.pink.opacity(0.11)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(String(localized: "ba.cafe.storage.title"))
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Spacer(minLength: 12)

                    LiquidGlassPill(tint: BaDesign.pink) {
                        Text(office.cafeLevel)
                            .font(.headline.monospacedDigit().bold())
                            .foregroundStyle(BaDesign.pink)
                    }
                }

                BaInfoPanel(tint: BaDesign.green) {
                    HStack(spacing: 12) {
                        Label(String(localized: "ba.office.cafeAp.title"), systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundStyle(BaDesign.green)

                        Spacer(minLength: 12)

                        Text("\(office.cafeApCurrent)/\(office.cafeApLimit)")
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(BaDesign.green)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    BaMetricTile(
                        title: String(localized: "ba.cafe.metric.visit"),
                        value: office.cafeVisitRefresh,
                        systemImage: "person.2.badge.clock.fill",
                        tint: BaDesign.pink
                    )

                    BaMetricTile(
                        title: String(localized: "ba.cafe.metric.tactical"),
                        value: office.tacticalRefresh,
                        systemImage: "target",
                        tint: BaDesign.amber
                    )
                }
            }
        }
    }

    private var cafeActionCard: some View {
        LiquidGlassSurface(cornerRadius: 30, tint: BaDesign.violet.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "ba.cafe.actions.title"))
                    .font(.headline)
                    .foregroundStyle(.primary)

                CafeActionRow(
                    title: String(localized: "ba.cafe.action.headpat"),
                    value: "0s",
                    detail: String(localized: "ba.cafe.action.ready"),
                    systemImage: "hand.tap.fill",
                    tint: BaDesign.pink
                )

                CafeActionRow(
                    title: String(localized: "ba.cafe.action.invite1"),
                    value: String(localized: "ba.cafe.action.invite.cooldown.value"),
                    detail: String(localized: "ba.cafe.action.availableAt.value"),
                    systemImage: "ticket.fill",
                    tint: BaDesign.violet
                )

                CafeActionRow(
                    title: String(localized: "ba.cafe.action.invite2"),
                    value: "0s",
                    detail: String(localized: "ba.cafe.action.ready"),
                    systemImage: "ticket.fill",
                    tint: BaDesign.cyan
                )
            }
        }
    }
}

private struct CafeActionRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        BaInfoPanel(tint: tint) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Text(value)
                    .font(.headline.monospacedDigit().bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BaCafeView()
    }
}
