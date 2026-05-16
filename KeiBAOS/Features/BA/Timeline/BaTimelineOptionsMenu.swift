//
//  BaTimelineOptionsMenu.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/16.
//

import SwiftUI

enum BaTimelineOptionsScope {
    case activity
    case pool

    var filterTitle: String {
        switch self {
        case .activity:
            String(localized: "ba.activity.action.filter")
        case .pool:
            String(localized: "ba.pool.action.filter")
        }
    }

    var showEndedTitle: String {
        switch self {
        case .activity:
            String(localized: "ba.settings.activity.showEnded.title")
        case .pool:
            String(localized: "ba.settings.pool.showEnded.title")
        }
    }
}

struct BaTimelineOptionsMenu: View {
    let scope: BaTimelineOptionsScope
    @Binding var statusFilter: BaTimelineStatus?
    @Binding var showsEnded: Bool
    @Binding var refreshInterval: BaRefreshInterval

    var body: some View {
        Section(scope.filterTitle) {
            BaMenuSelectionButton(
                title: String(localized: "ba.filter.all"),
                isSelected: statusFilter == nil
            ) {
                statusFilter = nil
            }

            ForEach(BaTimelineStatus.allCases) { status in
                BaMenuSelectionButton(
                    title: status.title,
                    isSelected: statusFilter == status
                ) {
                    statusFilter = status
                }
            }
        }

        Section(String(localized: "ba.settings.preferences.title")) {
            Toggle(scope.showEndedTitle, isOn: $showsEnded)
        }

        Section(String(localized: "ba.settings.refresh.title")) {
            ForEach(BaRefreshInterval.allCases) { interval in
                BaMenuSelectionButton(
                    title: interval.title,
                    isSelected: refreshInterval == interval
                ) {
                    refreshInterval = interval
                }
            }
        }
    }
}

private struct BaMenuSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: isSelected ? "checkmark" : "circle")
        }
    }
}
