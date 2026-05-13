//
//  BaOverviewView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaOverviewView: View {
    private let office = BaOfficeSnapshot.preview

    var body: some View {
        BaScreenScaffold {
            BaScreenHeader(
                title: String(localized: "ba.overview.title"),
                detail: String(localized: "ba.overview.detail")
            )

            identitySection
            apSection
            cafeSection
        }
    }

    private var identitySection: some View {
        BaMetricGroup(
            title: String(localized: "ba.office.overview.title"),
            systemImage: "building.2"
        ) {
            BaMetricRow(
                title: String(localized: "ba.office.nickname.label"),
                value: "\(office.nickname) \(office.teacherSuffix)",
                systemImage: "person.crop.square"
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.office.friendCode.label"),
                value: office.friendCode,
                systemImage: "number.square"
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.office.server.label"),
                value: office.server,
                systemImage: "server.rack"
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.office.catalog.label"),
                value: String(localized: "ba.office.catalog.value"),
                systemImage: "rectangle.stack.person.crop"
            )
        }
    }

    private var apSection: some View {
        BaMetricGroup(
            title: String(localized: "ba.office.ap.label"),
            systemImage: "bolt"
        ) {
            HStack(spacing: 10) {
                Text(String(localized: "ba.office.ap.current.title"))
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    BaValueChip(value: office.apCurrent, tint: BaDesign.green)
                    Text("/")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    BaValueChip(value: office.apLimit, tint: BaDesign.green)
                }
            }
            .padding(.vertical, 8)

            BaDivider()

            BaMetricRow(
                title: String(localized: "ba.office.ap.next.title"),
                value: office.apNext,
                detail: apStatusText,
                systemImage: "clock",
                valueColor: BaDesign.green
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.office.ap.sync.label"),
                value: office.apSyncAt,
                systemImage: "calendar.badge.clock",
                valueColor: BaDesign.blue
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.office.ap.full.label"),
                value: office.apFullAt,
                systemImage: "calendar.badge.checkmark",
                valueColor: BaDesign.cyan
            )
        }
    }

    private var cafeSection: some View {
        BaMetricGroup(
            title: String(localized: "ba.office.cafeAp.title"),
            systemImage: "cup.and.saucer"
        ) {
            BaMetricRow(
                title: String(localized: "ba.cafe.storage.title"),
                value: "\(office.cafeApCurrent)/\(office.cafeApLimit)",
                detail: office.cafeLevel,
                systemImage: "leaf",
                valueColor: BaDesign.pink
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.cafe.metric.visit"),
                value: office.cafeVisitRefresh,
                systemImage: "person.2.badge.clock",
                valueColor: BaDesign.pink
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.cafe.metric.tactical"),
                value: office.tacticalRefresh,
                systemImage: "target",
                valueColor: BaDesign.amber
            )
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
