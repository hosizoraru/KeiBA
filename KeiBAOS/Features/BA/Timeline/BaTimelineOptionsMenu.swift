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
            BaL10n.string("ba.activity.action.filter")
        case .pool:
            BaL10n.string("ba.pool.action.filter")
        }
    }

    var showEndedTitle: String {
        switch self {
        case .activity:
            BaL10n.string("ba.settings.activity.showEnded.title")
        case .pool:
            BaL10n.string("ba.settings.pool.showEnded.title")
        }
    }

    var showEndedMenuTitle: String {
        BaL10n.string("ba.timeline.options.showEnded.title")
    }
}

struct BaTimelineOptionsMenu: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let scope: BaTimelineOptionsScope
    @Binding var statusFilter: BaTimelineStatus?
    @Binding var showsEnded: Bool
    @Binding var refreshInterval: BaRefreshInterval

    var body: some View {
        Section(scope.filterTitle) {
            BaMenuSelectionButton(
                title: BaL10n.string("ba.filter.all"),
                isSelected: statusFilter == nil
            ) {
                withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                    statusFilter = nil
                }
            }

            ForEach(BaTimelineStatus.allCases) { status in
                BaMenuSelectionButton(
                    title: status.title,
                isSelected: statusFilter == status
                ) {
                    withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                        statusFilter = status
                    }
                }
            }
        }

        Section(BaL10n.string("ba.timeline.options.visibility.title")) {
            BaMenuToggleButton(
                title: scope.showEndedMenuTitle,
                isOn: showsEnded
            ) {
                withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                    showsEnded.toggle()
                }
            }
            .accessibilityLabel(Text(scope.showEndedTitle))
        }

        Section(BaL10n.string("ba.settings.refresh.title")) {
            ForEach(BaRefreshInterval.allCases) { interval in
                BaMenuSelectionButton(
                    title: interval.title,
                isSelected: refreshInterval == interval
                ) {
                    withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                        refreshInterval = interval
                    }
                }
            }
        }
    }
}

private struct BaMenuSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: BaDelayedMenuAction

    init(
        title: String,
        isSelected: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = BaDelayedMenuAction(action)
    }

    var body: some View {
        Button {
            BaMenuActionDispatcher.perform(action)
        } label: {
            Label(title, systemImage: isSelected ? "checkmark" : "circle")
        }
    }
}
