//
//  BaWatchDashboardView.swift
//  KeiBAOSWatch
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BaWatchDashboardView: View {
    let store: BaWatchSnapshotStore

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = store.snapshot {
                    BaWatchDashboardContent(
                        snapshot: snapshot,
                        phoneConnectionStatus: store.phoneConnectionStatus
                    )
                } else {
                    BaWatchEmptyState(error: store.lastSyncError)
                }
            }
            .navigationTitle(store.snapshot?.officeShortName ?? String(localized: "ba.watch.title"))
        }
    }
}

private struct BaWatchDashboardContent: View {
    let snapshot: BaWatchDashboardSnapshot
    let phoneConnectionStatus: BaWatchPhoneConnectionStatus

    var body: some View {
        List {
            Section {
                BaWatchTeacherHeader(snapshot: snapshot)
            }
            .listRowBackground(Color.clear)

            Section {
                BaWatchLiveAPRow(snapshot: snapshot)
                BaWatchLiveCafeAPRow(snapshot: snapshot)
            } header: {
                Text("ba.watch.section.resources")
            }

            Section {
                BaWatchTimelineGlanceRow(
                    title: Text("ba.watch.timeline.activity"),
                    section: snapshot.timeline.activities,
                    systemImage: "calendar.badge.clock",
                    color: .blue
                )

                BaWatchTimelineGlanceRow(
                    title: Text("ba.watch.timeline.pool"),
                    section: snapshot.timeline.pools,
                    systemImage: "sparkles",
                    color: .purple
                )
            } header: {
                Text("ba.watch.section.timeline")
            }

            Section {
                BaWatchCooldownRow(
                    title: Text("ba.watch.cafe.headpat"),
                    date: snapshot.nextHeadpatAvailableAt,
                    systemImage: "hand.tap.fill"
                )

                BaWatchCooldownRow(
                    title: Text("ba.watch.cafe.inviteTicket1"),
                    date: snapshot.nextInviteTicket1AvailableAt,
                    systemImage: "ticket.fill"
                )

                BaWatchCooldownRow(
                    title: Text("ba.watch.cafe.inviteTicket2"),
                    date: snapshot.nextInviteTicket2AvailableAt,
                    systemImage: "ticket.fill"
                )
            } header: {
                Text("ba.watch.section.cafe")
            }

            Section {
                BaWatchStatusRow(
                    title: Text("ba.watch.favorites.title"),
                    value: "\(snapshot.favoriteStudentCount)",
                    systemImage: "star.fill"
                )

                BaWatchStatusRow(
                    title: Text("ba.watch.notifications.ap"),
                    value: snapshot.apNotificationsEnabled ? String(localized: "ba.watch.status.on") : String(localized: "ba.watch.status.off"),
                    systemImage: "bell.badge.fill"
                )

                BaWatchStatusRow(
                    title: Text("ba.watch.notifications.timeline"),
                    value: timelineNotificationStatus,
                    systemImage: "calendar.badge.clock"
                )
            } header: {
                Text("ba.watch.section.summary")
            }

            Section {
                BaWatchStatusRow(
                    title: Text("ba.watch.connection.title"),
                    value: phoneConnectionStatus.localizedValue,
                    systemImage: phoneConnectionStatus.systemImage
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("ba.watch.sync.updatedAt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(snapshot.generatedAt, format: .dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("ba.watch.section.sync")
            }
        }
    }

    private var timelineNotificationStatus: String {
        if snapshot.activityNotificationsEnabled, snapshot.poolNotificationsEnabled {
            return String(localized: "ba.watch.notifications.timeline.all")
        }
        if snapshot.activityNotificationsEnabled {
            return String(localized: "ba.watch.notifications.timeline.activity")
        }
        if snapshot.poolNotificationsEnabled {
            return String(localized: "ba.watch.notifications.timeline.pool")
        }
        return String(localized: "ba.watch.status.off")
    }

}

private struct BaWatchTeacherHeader: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        HStack(spacing: 10) {
            BaWatchDutyAvatar(snapshot: snapshot)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: String(localized: "ba.watch.teacher.format"), snapshot.teacherName))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(snapshot.serverName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(String(format: String(localized: "ba.watch.friendCode.format"), snapshot.friendCode))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct BaWatchDutyAvatar: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        ZStack {
            Circle()
                .fill(.tint.opacity(0.22))

            if let image = syncedAvatarImage {
                image
                    .resizable()
                    .scaledToFill()
            } else if let urlString = snapshot.dutyStudentAvatarURLString,
               let url = URL(string: urlString)
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var syncedAvatarImage: Image? {
        guard let data = snapshot.dutyStudentAvatarImageData else { return nil }
        #if canImport(UIKit)
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
        #else
            return nil
        #endif
    }

    private var fallback: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.title2)
            .foregroundStyle(.tint)
    }
}

private struct BaWatchLiveAPRow: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            BaWatchGaugeRow(
                title: Text("ba.watch.ap.title"),
                value: "\(snapshot.currentAP(at: timeline.date)) / \(snapshot.apLimit)",
                status: BaWatchRelativeStatusText(until: snapshot.apFullAt(from: timeline.date), now: timeline.date),
                systemImage: "bolt.fill",
                color: .green
            )
        }
    }
}

private struct BaWatchLiveCafeAPRow: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            BaWatchGaugeRow(
                title: Text("ba.watch.cafeAP.title"),
                value: "\(snapshot.currentCafeAP(at: timeline.date)) / \(snapshot.cafeAPCapacity)",
                status: BaWatchRelativeStatusText(until: snapshot.cafeAPFullAt(from: timeline.date), now: timeline.date),
                systemImage: "cup.and.saucer.fill",
                color: .pink
            )
        }
    }
}

private struct BaWatchRelativeStatusText: View {
    let date: Date?
    let now: Date

    init(until date: Date?, now: Date) {
        self.date = date
        self.now = now
    }

    var body: some View {
        if let date, date > now {
            Text(date, style: .relative)
        } else {
            Text("ba.watch.status.full")
        }
    }
}

private struct BaWatchGaugeRow: View {
    let title: Text
    let value: String
    let status: BaWatchRelativeStatusText
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                status
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct BaWatchCooldownRow: View {
    let title: Text
    let date: Date?
    let systemImage: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            BaWatchStatusRow(
                title: title,
                value: cooldownText(now: timeline.date),
                systemImage: systemImage
            )
        }
    }

    private func cooldownText(now: Date) -> String {
        guard let date, date > now else {
            return String(localized: "ba.watch.status.ready")
        }
        return date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))
    }
}

private struct BaWatchTimelineGlanceRow: View {
    let title: Text
    let section: BaTimelineGlanceSection
    let systemImage: String
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        title
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 2)

                        Text(countsText)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    if let item = section.featuredItem {
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Text(item.status.watchTitle)
                            Text(targetDate(for: item), style: .relative)
                            if item.relatedItemCount > 0 {
                                Text(String(format: String(localized: "ba.watch.timeline.more.format"), item.relatedItemCount))
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                        if item.status == .running {
                            ProgressView(value: item.progress(at: timeline.date))
                                .tint(color)
                                .controlSize(.mini)
                        }
                    } else {
                        Text("ba.watch.timeline.empty")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var countsText: String {
        String(
            format: String(localized: "ba.watch.timeline.counts.format"),
            section.runningCount,
            section.upcomingCount
        )
    }

    private func targetDate(for item: BaTimelineGlanceItem) -> Date {
        item.status == .upcoming ? item.startAt : item.endAt
    }
}

private struct BaWatchStatusRow: View {
    let title: Text
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            title
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }
}

private extension BaTimelineGlanceStatus {
    var watchTitle: LocalizedStringResource {
        switch self {
        case .running:
            "ba.watch.timeline.status.running"
        case .upcoming:
            "ba.watch.timeline.status.upcoming"
        case .ended:
            "ba.watch.timeline.status.ended"
        }
    }
}

private struct BaWatchEmptyState: View {
    let error: String?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "applewatch")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("ba.watch.empty.title")
                .font(.headline)

            Text(error ?? String(localized: "ba.watch.empty.message"))
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BaWatchDashboardView(store: .preview)
}

private extension BaWatchSnapshotStore {
    static var preview: BaWatchSnapshotStore {
        let store = BaWatchSnapshotStore(defaults: UserDefaults(suiteName: "KeiBAOSWatchPreview") ?? .standard)
        store.snapshot = BaWatchDashboardSnapshot(
            sourceUpdatedAt: .now,
            officeName: "沙勒办公室",
            serverName: "国服",
            teacherName: "Kei",
            friendCode: "ARISUKEI",
            dutyStudentName: "爱丽丝",
            apBaseValue: 126,
            apLimit: 240,
            apRegenBaseAt: .now,
            apNotificationsEnabled: true,
            apNotifyThreshold: 120,
            cafeLevel: 10,
            cafeAPBaseValue: 420,
            cafeStorageBaseAt: .now,
            cafeAPNotificationsEnabled: true,
            cafeAPNotifyThreshold: 120,
            activityNotificationsEnabled: true,
            poolNotificationsEnabled: false,
            favoriteStudentCount: 12,
            timeline: BaTimelineGlanceSnapshot(
                generatedAt: .now,
                activities: BaTimelineGlanceSection(
                    runningCount: 2,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "沙勒总决算",
                        status: .running,
                        startAt: .now.addingTimeInterval(-3_600),
                        endAt: .now.addingTimeInterval(7_200),
                        relatedItemCount: 1
                    ),
                    lastSyncAt: .now
                ),
                pools: BaTimelineGlanceSection(
                    runningCount: 1,
                    upcomingCount: 1,
                    featuredItem: BaTimelineGlanceItem(
                        title: "FES 招募",
                        status: .running,
                        startAt: .now.addingTimeInterval(-1_800),
                        endAt: .now.addingTimeInterval(18_000)
                    ),
                    lastSyncAt: .now
                )
            )
        )
        store.phoneConnectionStatus = .connected
        return store
    }
}
