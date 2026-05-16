//
//  BaOverviewCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

enum BaOverviewTextToken {
    static let sectionTitle = Font.headline
    static let rowTitle = Font.subheadline.weight(.semibold)
    static let caption = Font.caption
    static let timeValue = Font.body.monospacedDigit().weight(.semibold)
    static let timeDetail = Font.caption
    static let primaryNumber = Font.title3.monospacedDigit().weight(.semibold)
    static let number = Font.body.monospacedDigit().weight(.semibold)
}

enum BaOverviewMetricStyle {
    static let cardSpacing: CGFloat = 14
    static let rowSpacing: CGFloat = 10
    static let sectionIconSlot: CGFloat = 26
    static let rowIconSlot: CGFloat = 26
    static let mainIconSlot: CGFloat = 40
    static let mainIcon: CGFloat = 32
    static let rowIcon: CGFloat = 24
    static let symbolIcon: CGFloat = 15
    static let badgeIconSlot: CGFloat = 18
    static let badgeIcon: CGFloat = 16
    static let compactTilePadding: CGFloat = 10
    static let compactTileSpacing: CGFloat = 6
    static let compactHeaderHeight: CGFloat = 28
    static let compactValueHeight: CGFloat = 22
    static let compactDetailHeight: CGFloat = 28
    static let metricTileHeight: CGFloat = 100
    static let actionMinHeight: CGFloat = 100
    static let timelineTileHeight: CGFloat = 138
}

struct BaOverviewIdentityCard: View {
    let settings: BaAppSettings
    let onServerSelected: (BaServer) -> Void

    @State private var copiedFriendCode = false

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.office.overview.title"), asset: .schale)

                HStack(alignment: .top, spacing: 14) {
                    BaOverviewIdentityAvatar(dutyStudent: settings.dutyStudent)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(settings.nickname) \(String(localized: "ba.office.nickname.suffix"))")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        BaFriendCodeCopyLine(
                            friendCode: settings.friendCode,
                            isCopied: copiedFriendCode,
                            onCopy: copyFriendCode
                        )
                    }

                    Spacer(minLength: 8)

                    Picker(String(localized: "ba.settings.server.title"), selection: serverBinding) {
                        ForEach(BaServer.allCases) { server in
                            Text(server.title)
                                .tag(server)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var serverBinding: Binding<BaServer> {
        Binding(
            get: { settings.server },
            set: onServerSelected
        )
    }

    private func copyFriendCode() {
        BaPasteboard.copy(settings.friendCode)
        copiedFriendCode = true
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard Task.isCancelled == false else { return }
            copiedFriendCode = false
        }
    }
}

private struct BaFriendCodeCopyLine: View {
    let friendCode: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(String(format: String(localized: "ba.office.friendCode.display.format"), friendCode))
                .font(BaOverviewTextToken.number)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Button(action: onCopy) {
                Label(copyTitle, systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .foregroundStyle(isCopied ? BaDesign.green : BaDesign.blue)
            .accessibilityLabel(Text(copyTitle))
        }
    }

    private var copyTitle: String {
        isCopied
            ? String(localized: "ba.office.friendCode.copied")
            : String(localized: "ba.office.friendCode.copy")
    }
}

private struct BaOverviewIdentityAvatar: View {
    let dutyStudent: BaDutyStudent?

    var body: some View {
        if let dutyStudent {
            BaRemoteImageSurface(
                url: dutyStudent.avatarURL,
                fallbackSystemImage: "person.crop.circle",
                tint: BaDesign.blue,
                width: 50,
                height: 50,
                cornerRadius: 18,
                maxPixelDimension: 180
            )
            .accessibilityLabel(
                Text(String(format: String(localized: "ba.office.dutyStudent.avatar.accessibility"), dutyStudent.name))
            )
        } else {
            BaGameAssetIcon(.schale, size: 44)
                .frame(width: 50, height: 50)
                .liquidGlassSurface(cornerRadius: 18, tint: BaDesign.blue.opacity(0.06), isInteractive: false)
                .accessibilityLabel(Text(String(localized: "ba.office.identity.avatar.accessibility")))
        }
    }
}

struct BaOverviewAPCard: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let office: BaOfficeAPSnapshot
    let settings: BaAppSettings
    let onCommit: (Int, Int, Int) -> Void

    @State private var isEditorPresented = false

    var body: some View {
        BaGlassCard(tint: BaDesign.green) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.office.ap.label"), asset: .actionPoint)

                BaOverviewResourceReadout(
                    title: String(localized: "ba.office.ap.current.title"),
                    value: office.apCurrentLimit,
                    detail: office.apRemaining,
                    asset: .actionPoint,
                    tint: BaDesign.green
                ) {
                    BaOverviewIconGlassButton(
                        title: String(localized: "ba.overview.ap.edit.title"),
                        systemImage: "pencil",
                        action: presentEditor
                    )
                }

                LazyVGrid(columns: metrics.overviewInnerGridColumns, spacing: 10) {
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.next.title"),
                        value: office.apNext,
                        detail: String(localized: "ba.office.ap.next.detail"),
                        asset: .actionPointTight,
                        tint: BaDesign.green
                    )
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.full.label"),
                        value: office.apFullAt,
                        detail: office.apFullRemain,
                        systemImage: "calendar.badge.checkmark",
                        tint: BaDesign.cyan
                    )
                    BaOverviewMetricTile(
                        title: String(localized: "ba.office.ap.sync.label"),
                        value: office.apSyncAt,
                        detail: String(localized: "ba.overview.sync.detail"),
                        systemImage: "clock.arrow.circlepath",
                        tint: BaDesign.blue
                    )
                    Button {
                        presentEditor()
                    } label: {
                        BaOverviewMetricTile(
                            title: String(localized: "ba.settings.ap.threshold.title"),
                            value: "\(settings.apNotifyThreshold)",
                            detail: String(localized: "ba.settings.threshold.edit.detail"),
                            systemImage: "bell.badge",
                            tint: BaDesign.amber
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.ap.edit.title"))
                }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            BaOverviewAPEditorSheet(
                currentAP: office.apCurrent,
                apThreshold: "\(settings.apNotifyThreshold)",
                apLimit: office.apLimit
            ) { currentAP, apLimit, threshold in
                onCommit(currentAP, apLimit, threshold)
            }
        }
    }

    private func presentEditor() {
        isEditorPresented = true
    }
}

struct BaOverviewCafeCard: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let office: BaOfficeSnapshot
    let settings: BaAppSettings
    let onClaimCafeAP: () -> Void
    let onPerformAction: (BaCafeActionKind) -> Void
    let onResetAction: (BaCafeActionKind) -> Void
    let onCafeSettingsCommit: (Int, Int) -> Void

    @State private var isEditorPresented = false

    var body: some View {
        BaGlassCard(tint: BaDesign.pink) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.cafe.title"), asset: .cafeAP)

                BaOverviewResourceReadout(
                    title: String(localized: "ba.cafe.storage.title"),
                    value: "\(office.cafeApCurrent)/\(office.cafeApLimit)",
                    detail: cafeStorageDetail,
                    asset: .cafeAP,
                    tint: BaDesign.pink
                ) {
                    HStack(spacing: 8) {
                        BaOverviewIconGlassButton(
                            title: String(localized: "ba.overview.cafe.edit.title"),
                            systemImage: "slider.horizontal.3",
                            action: presentEditor
                        )

                        BaOverviewIconGlassButton(
                            title: String(localized: "ba.cafe.action.claimAp"),
                            systemImage: "tray.and.arrow.down.fill",
                            action: onClaimCafeAP
                        )
                    }
                }

                LazyVGrid(columns: metrics.overviewInnerGridColumns, spacing: 10) {
                    ForEach(office.cafeVisitSlots) { slot in
                        BaOverviewMetricTile(
                            title: slot.title,
                            value: slot.value,
                            detail: slot.detail,
                            asset: .lobbyWork,
                            tint: BaDesign.pink
                        )
                    }
                }

                LazyVGrid(columns: metrics.overviewInnerGridColumns, spacing: 10) {
                    BaOverviewMetricTile(
                        title: String(localized: "ba.cafe.metric.tactical"),
                        value: office.tacticalRefresh,
                        detail: office.tacticalRefreshDetail,
                        asset: .arenaCoin,
                        tint: BaDesign.amber
                    )

                    if let headpatAction {
                        BaOverviewActionTile(
                            action: headpatAction,
                            onTap: { onPerformAction(headpatAction.kind) },
                            onReset: { onResetAction(headpatAction.kind) }
                        )
                    }
                }

                LazyVGrid(columns: metrics.overviewInnerGridColumns, spacing: 10) {
                    ForEach(inviteActions) { action in
                        BaOverviewActionTile(
                            action: action,
                            onTap: { onPerformAction(action.kind) },
                            onReset: { onResetAction(action.kind) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            BaOverviewCafeEditorSheet(
                cafeLevel: settings.cafeLevel,
                cafeThreshold: settings.cafeApNotifyThreshold,
                onSave: onCafeSettingsCommit
            )
        }
    }

    private var headpatAction: BaCafeActionSnapshot? {
        office.cafeActions.first { $0.kind == .headpat }
    }

    private var cafeStorageDetail: String {
        String.localizedStringWithFormat(
            String(localized: "ba.overview.cafe.storage.detail.format"),
            String(localized: "ba.overview.cafe.shared.detail"),
            office.cafeLevel
        )
    }

    private var inviteActions: [BaCafeActionSnapshot] {
        [.inviteTicket1, .inviteTicket2].compactMap { kind in
            office.cafeActions.first { $0.kind == kind }
        }
    }

    private func presentEditor() {
        isEditorPresented = true
    }
}

struct BaOverviewTimelineSummary: Equatable {
    let activity: BaOverviewTimelineSummaryItem
    let pool: BaOverviewTimelineSummaryItem

    init(activities: [BaActivityEntry], pools: [BaPoolEntry], now: Date) {
        activity = Self.earliestEndingItem(
            entries: activities,
            now: now,
            title: \.title,
            start: \.beginAt,
            end: \.endAt
        )
        pool = Self.earliestEndingItem(
            entries: pools,
            now: now,
            title: \.name,
            start: \.startAt,
            end: \.endAt
        )
    }

    static func earliestEndingItem<Entry>(
        entries: [Entry],
        now: Date,
        title titleKeyPath: KeyPath<Entry, String>,
        start startKeyPath: KeyPath<Entry, Date>,
        end endKeyPath: KeyPath<Entry, Date>
    ) -> BaOverviewTimelineSummaryItem {
        var earliestEnd: Date?
        var earliestStart = now
        var titles: [String] = []

        for entry in entries {
            let end = entry[keyPath: endKeyPath]
            guard end > now else { continue }
            let title = entry[keyPath: titleKeyPath]
            let start = entry[keyPath: startKeyPath]

            guard let currentEarliestEnd = earliestEnd else {
                earliestEnd = end
                earliestStart = start
                titles = [title]
                continue
            }

            if end < currentEarliestEnd {
                earliestEnd = end
                earliestStart = start
                titles = [title]
            } else if end == currentEarliestEnd {
                earliestStart = min(earliestStart, start)
                titles.append(title)
            }
        }

        guard let earliestEnd else {
            return .empty
        }

        return BaOverviewTimelineSummaryItem(
            titles: titles,
            remainingText: BaDisplayFormatters.timelineDetail(
                start: earliestStart,
                end: earliestEnd,
                now: now,
                includingSeconds: false
            ),
            endText: BaDisplayFormatters.dateTime(earliestEnd),
            endAt: earliestEnd
        )
    }
}

struct BaOverviewTimelineSummaryItem: Equatable {
    let titles: [String]
    let remainingText: String
    let endText: String?
    let endAt: Date?

    var primaryTitle: String {
        titles.first ?? String(localized: "ba.overview.timeline.empty")
    }

    var extraTitleText: String? {
        let extraCount = titles.count - 1
        guard extraCount > 0 else {
            return nil
        }
        return String.localizedStringWithFormat(
            String(localized: "ba.overview.timeline.moreItems.format"),
            extraCount
        )
    }

    var endLineText: String? {
        guard let endText else {
            return nil
        }
        return String.localizedStringWithFormat(
            String(localized: "ba.overview.timeline.endsAt.format"),
            endText
        )
    }

    var accessibilityTitle: String {
        guard let extraTitleText else {
            return primaryTitle
        }
        return "\(primaryTitle), \(extraTitleText)"
    }

    static var empty: BaOverviewTimelineSummaryItem {
        BaOverviewTimelineSummaryItem(
            titles: [],
            remainingText: String(localized: "ba.state.notSynced"),
            endText: nil,
            endAt: nil
        )
    }
}

struct BaOverviewTimelineSummaryCard: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let summary: BaOverviewTimelineSummary
    let activitySyncAt: Date?
    let poolSyncAt: Date?
    let onOpenTab: (AppTab) -> Void

    var body: some View {
        BaGlassCard(tint: BaDesign.violet) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: String(localized: "ba.overview.timeline.title"), asset: .guideMission)

                LazyVGrid(columns: metrics.overviewSummaryGridColumns, spacing: 10) {
                    Button {
                        onOpenTab(.activity)
                    } label: {
                        BaOverviewTimelineTile(
                            title: String(localized: "ba.tab.activity"),
                            item: summary.activity,
                            syncAt: activitySyncAt,
                            systemImage: "calendar",
                            tint: BaDesign.blue
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.timeline.openActivity"))

                    Button {
                        onOpenTab(.pool)
                    } label: {
                        BaOverviewTimelineTile(
                            title: String(localized: "ba.tab.pool"),
                            item: summary.pool,
                            syncAt: poolSyncAt,
                            systemImage: "sparkles",
                            tint: BaDesign.violet
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "ba.overview.timeline.openPool"))
                }
            }
        }
    }
}
