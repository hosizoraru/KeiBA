//
//  BaWatchDashboardView.swift
//  KeiBAWatch
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
            .baMotion(BaMotion.standard, value: store.snapshot?.generatedAt)
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
                BaWatchGlanceSummaryGrid(snapshot: snapshot)
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

private struct BaWatchGlanceSummaryGrid: View {
    let snapshot: BaWatchDashboardSnapshot

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let summary = snapshot.glanceSummary(at: timeline.date)

            LazyVGrid(columns: columns, spacing: 6) {
                BaWatchGlanceTile(
                    title: Text("ba.watch.ap.title"),
                    value: "\(summary.currentAP)/\(summary.apLimit)",
                    systemImage: "bolt.fill",
                    color: .green
                ) {
                    BaWatchRelativeStatusText(until: summary.apFullAt, now: timeline.date)
                }

                BaWatchGlanceTile(
                    title: Text("ba.watch.cafeAP.title"),
                    shortTitle: Text("ba.watch.cafeAP.shortTitle"),
                    value: "\(summary.currentCafeAP)/\(summary.cafeAPCapacity)",
                    systemImage: "cup.and.saucer.fill",
                    color: .pink
                ) {
                    BaWatchRelativeStatusText(until: summary.cafeAPFullAt, now: timeline.date)
                }

                BaWatchGlanceTile(
                    title: Text("ba.watch.timeline.activity"),
                    value: "\(summary.activityRunningCount)/\(summary.activityUpcomingCount)",
                    systemImage: "calendar.badge.clock",
                    color: .blue
                ) {
                    Text(summary.featuredActivityTitle ?? String(localized: "ba.watch.glance.nowNext"))
                }

                BaWatchGlanceTile(
                    title: Text("ba.watch.timeline.pool"),
                    value: "\(summary.poolRunningCount)/\(summary.poolUpcomingCount)",
                    systemImage: "sparkles",
                    color: .purple
                ) {
                    Text(summary.featuredPoolTitle ?? String(localized: "ba.watch.glance.nowNext"))
                }
            }
            .baMotion(BaMotion.numeric, value: summary)
        }
        .padding(.top, 2)
    }
}

private struct BaWatchGlanceTile<Detail: View>: View {
    let title: Text
    let shortTitle: Text?
    let value: String
    let systemImage: String
    let color: Color
    let detail: Detail

    init(
        title: Text,
        shortTitle: Text? = nil,
        value: String,
        systemImage: String,
        color: Color,
        @ViewBuilder detail: () -> Detail
    ) {
        self.title = title
        self.shortTitle = shortTitle
        self.value = value
        self.systemImage = systemImage
        self.color = color
        self.detail = detail()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 14)

                ViewThatFits(in: .horizontal) {
                    title
                    if let shortTitle {
                        shortTitle
                    }
                }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .baNumericTextTransition(value: value)

            detail
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct BaWatchTeacherHeader: View {
    let snapshot: BaWatchDashboardSnapshot

    var body: some View {
        HStack(spacing: 10) {
            BaWatchDutyAvatar(snapshot: snapshot)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(String(format: String(localized: "ba.watch.teacher.format"), snapshot.teacherName))
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .privacySensitive()

                    BaWatchServerBadge(title: snapshot.serverName)
                }

                BaWatchFriendCodeLine(friendCode: snapshot.friendCode)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .baMotion(BaMotion.standard, value: snapshot.dutyStudentName)
        .accessibilityElement(children: .combine)
    }
}

private struct BaWatchServerBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.thinMaterial, in: Capsule())
    }
}

private struct BaWatchFriendCodeLine: View {
    let friendCode: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.caption2.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 12)

            Text(friendCode)
                .font(.caption2.monospaced().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)
        .privacySensitive()
        .accessibilityLabel(
            Text(String(format: String(localized: "ba.watch.friendCode.format"), friendCode))
        )
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
                value: "\(snapshot.currentAP(at: timeline.date))/\(snapshot.apLimit)",
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
                value: "\(snapshot.currentCafeAP(at: timeline.date))/\(snapshot.cafeAPCapacity)",
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
        if let text = BaWatchCompactDurationFormatter.text(until: date, from: now) {
            Text(text)
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
                    .baNumericTextTransition(value: value)
                status
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .baMotion(BaMotion.numeric, value: value)
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
        return BaWatchCompactDurationFormatter.text(until: date, from: now) ?? String(localized: "ba.watch.status.ready")
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
                            .baNumericTextTransition(value: countsText)
                    }

                    if let item = section.featuredItem {
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 4) {
                            Text(item.status.watchTitle)
                            if let targetText = BaWatchCompactDurationFormatter.text(until: targetDate(for: item), from: timeline.date) {
                                Text(targetText)
                            }
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
                                .baMotion(BaMotion.numeric, value: item.progress(at: timeline.date))
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
                .baNumericTextTransition(value: value)
        }
        .baMotion(BaMotion.quick, value: value)
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
        let store = BaWatchSnapshotStore(defaults: UserDefaults(suiteName: "KeiBAWatchPreview") ?? .standard)
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
