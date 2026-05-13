//
//  BaCafeView.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaCafeView: View {
    private let office = BaOfficeSnapshot.preview

    var body: some View {
        BaScreenScaffold {
            BaScreenHeader(
                title: String(localized: "ba.cafe.title"),
                detail: String(localized: "ba.cafe.detail")
            )

            storageSection
            refreshSection
            cooldownSection
        }
    }

    private var storageSection: some View {
        BaMetricGroup(
            title: String(localized: "ba.cafe.storage.title"),
            systemImage: "cup.and.saucer"
        ) {
            BaMetricRow(
                title: String(localized: "ba.office.cafeAp.title"),
                value: "\(office.cafeApCurrent)/\(office.cafeApLimit)",
                detail: office.cafeLevel,
                systemImage: "leaf",
                valueColor: BaDesign.pink
            )
        }
    }

    private var refreshSection: some View {
        BaMetricGroup(
            title: String(localized: "ba.cafe.refresh.title"),
            systemImage: "clock"
        ) {
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

    private var cooldownSection: some View {
        BaMetricGroup(
            title: String(localized: "ba.cafe.actions.title"),
            systemImage: "ticket"
        ) {
            BaMetricRow(
                title: String(localized: "ba.cafe.action.headpat"),
                value: String(localized: "ba.cafe.action.ready.value"),
                detail: String(localized: "ba.cafe.action.ready"),
                systemImage: "hand.tap",
                valueColor: BaDesign.green
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.cafe.action.invite1"),
                value: String(localized: "ba.cafe.action.invite.cooldown.value"),
                detail: String(localized: "ba.cafe.action.availableAt.value"),
                systemImage: "ticket",
                valueColor: BaDesign.violet
            )
            BaDivider()
            BaMetricRow(
                title: String(localized: "ba.cafe.action.invite2"),
                value: String(localized: "ba.cafe.action.ready.value"),
                detail: String(localized: "ba.cafe.action.ready"),
                systemImage: "ticket",
                valueColor: BaDesign.green
            )
        }
    }
}

#Preview {
    NavigationStack {
        BaCafeView()
    }
}
