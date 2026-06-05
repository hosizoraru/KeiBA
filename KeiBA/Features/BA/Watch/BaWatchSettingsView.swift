//
//  BaWatchSettingsView.swift
//  KeiBA
//
//  Created by Codex on 2026/05/19.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

struct BaWatchSettingsView: View {
    @Environment(BaAppModel.self) private var model
    @State private var refreshID = UUID()

    var body: some View {
        Form {
            connectionSection
            contentSection
            actionsSection
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .task {
            model.refreshWatchSyncState()
            refreshID = UUID()
        }
    }

    private var state: BaWatchSyncState {
        _ = refreshID
        return model.watchSyncState
    }

    private var snapshot: BaWatchDashboardSnapshot {
        model.currentWatchDashboardSnapshot
    }

    private var connectionSection: some View {
        Section {
            LabeledContent(BaL10n.string("ba.settings.watch.connection.title")) {
                Label(
                    BaWatchSyncStatusPresenter.title(for: state),
                    systemImage: BaWatchSyncStatusPresenter.systemImage(for: state)
                )
                .foregroundStyle(BaWatchSyncStatusPresenter.foregroundStyle(for: state))
            }

            LabeledContent(BaL10n.string("ba.settings.watch.lastSent.title")) {
                Text(watchSyncDateText(state.lastApplicationContextSentAt))
                    .foregroundStyle(.secondary)
            }

            if let queuedAt = state.lastGuaranteedTransferQueuedAt {
                LabeledContent(BaL10n.string("ba.settings.watch.queued.title")) {
                    Text(watchSyncDateText(queuedAt))
                        .foregroundStyle(.secondary)
                }
            }

            if let error = state.lastErrorDescription {
                LabeledContent(BaL10n.string("ba.settings.watch.error.title")) {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.trailing)
                }
            }
        } header: {
            Text(BaL10n.string("ba.settings.watch.connection.section"))
        } footer: {
            Text(BaL10n.string("ba.settings.watch.connection.footer"))
        }
    }

    private var contentSection: some View {
        Section {
            LabeledContent(BaL10n.string("ba.settings.watch.dutyAvatar.title")) {
                Text(watchDutyAvatarStatus(snapshot: snapshot))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            BaWatchSyncedContentRow()

            LabeledContent(BaL10n.string("ba.settings.watch.timeline.title")) {
                Text(watchTimelineStatus(snapshot.timeline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text(BaL10n.string("ba.settings.watch.content.section"))
        } footer: {
            Text(BaL10n.string("ba.settings.watch.footer"))
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                model.requestWatchSnapshotSync()
                refreshID = UUID()
            } label: {
                Label(BaL10n.string("ba.settings.watch.syncNow.title"), systemImage: "applewatch.radiowaves.left.and.right")
            }

            Button {
                model.refreshWatchSyncState()
                refreshID = UUID()
            } label: {
                Label(BaL10n.string("ba.settings.watch.recheck.title"), systemImage: "arrow.clockwise")
            }

            #if os(iOS)
            Button {
                openAppNotificationSettings()
            } label: {
                Label(BaL10n.string("ba.settings.watch.openNotificationSettings.title"), systemImage: "bell.badge")
            }
            #endif
        } header: {
            Text(BaL10n.string("ba.settings.watch.actions.section"))
        } footer: {
            Text(BaL10n.string("ba.settings.watch.actions.footer"))
        }
    }

    private func watchDutyAvatarStatus(snapshot: BaWatchDashboardSnapshot) -> String {
        guard let dutyStudentName = snapshot.dutyStudentName, dutyStudentName.isEmpty == false else {
            return BaL10n.string("ba.settings.watch.dutyAvatar.missing")
        }
        if snapshot.dutyStudentAvatarImageData?.isEmpty == false ||
            snapshot.dutyStudentAvatarURLString?.isEmpty == false
        {
            return String(format: BaL10n.string("ba.settings.watch.dutyAvatar.ready"), dutyStudentName)
        }
        return String(format: BaL10n.string("ba.settings.watch.dutyAvatar.noImage"), dutyStudentName)
    }

    private func watchTimelineStatus(_ timeline: BaTimelineGlanceSnapshot) -> String {
        String(
            format: BaL10n.string("ba.settings.watch.timeline.summary.format"),
            timeline.activities.runningCount,
            timeline.activities.upcomingCount,
            timeline.pools.runningCount,
            timeline.pools.upcomingCount
        )
    }

    private func watchSyncDateText(_ date: Date?) -> String {
        guard let date else {
            return BaL10n.string("ba.settings.watch.never")
        }
        return date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour().minute().second())
    }

    #if os(iOS)
    private func openAppNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    #endif
}

private struct BaWatchSyncedContentRow: View {
    private let items = [
        "ba.settings.watch.content.office",
        "ba.settings.watch.content.ap",
        "ba.settings.watch.content.cafe",
        "ba.settings.watch.content.activities",
        "ba.settings.watch.content.pools",
        "ba.settings.watch.content.notifications",
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 124), spacing: 8, alignment: .leading),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(BaL10n.string("ba.settings.watch.content.title"))
                .font(.body)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(BaL10n.string(item))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}

enum BaWatchSyncStatusPresenter {
    static func title(for state: BaWatchSyncState) -> String {
        switch state.availability {
        case .unavailable:
            BaL10n.string("ba.settings.watch.connection.unavailable")
        case .activating:
            BaL10n.string("ba.settings.watch.connection.activating")
        case .confirmingInstall:
            BaL10n.string("ba.settings.watch.connection.confirmingInstall")
        case .notPaired:
            BaL10n.string("ba.settings.watch.connection.notPaired")
        case .appNotInstalled:
            BaL10n.string("ba.settings.watch.connection.notInstalled")
        case .reachable:
            BaL10n.string("ba.settings.watch.connection.reachable")
        case .background:
            BaL10n.string("ba.settings.watch.connection.background")
        case .error:
            BaL10n.string("ba.settings.watch.connection.error")
        }
    }

    static func compactTitle(for state: BaWatchSyncState) -> String {
        switch state.availability {
        case .reachable:
            BaL10n.string("ba.overview.watch.connected")
        case .background:
            BaL10n.string("ba.overview.watch.background")
        case .confirmingInstall, .activating:
            BaL10n.string("ba.overview.watch.checking")
        case .appNotInstalled:
            BaL10n.string("ba.overview.watch.notInstalled")
        case .notPaired:
            BaL10n.string("ba.overview.watch.notPaired")
        case .unavailable:
            BaL10n.string("ba.overview.watch.unavailable")
        case .error:
            BaL10n.string("ba.overview.watch.error")
        }
    }

    static func systemImage(for state: BaWatchSyncState) -> String {
        switch state.availability {
        case .reachable:
            "applewatch.radiowaves.left.and.right"
        case .background:
            "applewatch"
        case .activating, .confirmingInstall:
            "arrow.triangle.2.circlepath"
        case .notPaired, .appNotInstalled, .unavailable:
            "applewatch.slash"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    static func foregroundStyle(for state: BaWatchSyncState) -> Color {
        switch state.availability {
        case .reachable:
            BaDesign.green
        case .background:
            BaDesign.blue
        case .error:
            .red
        default:
            .secondary
        }
    }
}
