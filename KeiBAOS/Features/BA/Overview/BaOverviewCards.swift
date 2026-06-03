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
    @Environment(\.baAdaptiveMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let settings: BaAppSettings
    let account: BaAccountProfile
    let accounts: [BaAccountProfile]
    let watchSyncState: BaWatchSyncState
    let onAccountSelected: (BaAccountID) -> Void
    let onManageAccounts: () -> Void
    let onOpenWatchSettings: () -> Void

    @State private var copiedFriendCode = false

    var body: some View {
        BaGlassCard(tint: BaDesign.blue) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                identityHeader

                if metrics.usesCompactOverviewIdentityLayout {
                    compactIdentityContent
                } else {
                    regularIdentityContent
                }
            }
        }
    }

    private var displayName: String {
        "\(settings.nickname) \(BaL10n.string("ba.office.nickname.suffix"))"
    }

    private var identityHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            BaOverviewSectionTitle(title: BaOfficeTerminology.overviewTitle(for: settings), asset: .schale)
                .layoutPriority(1)

            Spacer(minLength: 4)

            watchStatusButton
        }
    }

    private var regularIdentityContent: some View {
        HStack(alignment: .top, spacing: 14) {
            BaOverviewIdentityAvatar(dutyStudent: settings.dutyStudent)

            VStack(alignment: .leading, spacing: 8) {
                identityName
                accountSummary

                BaFriendCodeCopyLine(
                    friendCode: settings.friendCode,
                    isCopied: copiedFriendCode,
                    onCopy: copyFriendCode
                )
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            accountMenu
        }
    }

    private var compactIdentityContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                BaOverviewIdentityAvatar(dutyStudent: settings.dutyStudent)

                identityName
                    .layoutPriority(1)

                Spacer(minLength: 6)

                accountMenu
            }

            accountSummary
            BaFriendCodeCopyPill(
                friendCode: settings.friendCode,
                isCopied: copiedFriendCode,
                onCopy: copyFriendCode
            )
        }
    }

    private var identityName: some View {
        Text(displayName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }

    private var accountSummary: some View {
        Text(account.detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
    }

    private var accountMenu: some View {
        Menu {
            Picker(BaL10n.string("ba.account.switch.title"), selection: accountBinding) {
                ForEach(accounts) { account in
                    Label {
                        Text(account.title)
                    } icon: {
                        Image(systemName: account.isEnabled ? "person.crop.circle" : "person.crop.circle.badge.xmark")
                    }
                    .tag(account.id)
                }
            }
            Divider()
            Button(action: onManageAccounts) {
                Label(BaL10n.string("ba.account.manage.title"), systemImage: "person.crop.circle.badge.plus")
            }
        } label: {
            Label {
                Text(account.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            } icon: {
                Image(systemName: "person.crop.circle")
            }
        }
        .buttonStyle(.glass)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(Text(BaL10n.string("ba.account.switch.title")))
    }

    @ViewBuilder
    private var watchStatusButton: some View {
        #if os(iOS)
        Button(action: onOpenWatchSettings) {
            HStack(spacing: 6) {
                Image(systemName: BaWatchSyncStatusPresenter.systemImage(for: watchSyncState))
                    .font(.caption.weight(.semibold))
                    .frame(width: 16)
                    .baSymbolBounce(value: watchSyncState)

                Text(BaL10n.string("ba.overview.watch.title"))
                    .foregroundStyle(.secondary)

                Text(BaWatchSyncStatusPresenter.compactTitle(for: watchSyncState))
                    .foregroundStyle(BaWatchSyncStatusPresenter.foregroundStyle(for: watchSyncState))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .contentShape(Capsule())
        }
        .buttonStyle(BaPressButtonStyle(scale: 0.96))
        .baMotion(BaMotion.quick, value: watchSyncState)
        .liquidGlassSurface(cornerRadius: 14, tint: BaDesign.blue.opacity(0.045), isInteractive: true)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(
            Text(
                String(
                    format: BaL10n.string("ba.overview.watch.accessibility.format"),
                    BaWatchSyncStatusPresenter.compactTitle(for: watchSyncState)
                )
            )
        )
        #endif
    }

    private var accountBinding: Binding<BaAccountID> {
        Binding(
            get: { account.id },
            set: onAccountSelected
        )
    }

    private func copyFriendCode() {
        BaPasteboard.copy(settings.friendCode)
        withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
            copiedFriendCode = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard Task.isCancelled == false else { return }
            withAnimation(BaMotion.resolved(BaMotion.quick, reduceMotion: reduceMotion)) {
                copiedFriendCode = false
            }
        }
    }
}

private struct BaFriendCodeCopyLine: View {
    let friendCode: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            BaFriendCodeInlineText(friendCode: friendCode)

            Button(action: onCopy) {
                Label(copyTitle, systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .baSymbolBounce(value: isCopied)
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .foregroundStyle(isCopied ? BaDesign.green : BaDesign.blue)
            .accessibilityLabel(Text(copyTitle))
        }
    }

    private var copyTitle: String {
        isCopied
            ? BaL10n.string("ba.office.friendCode.copied")
            : BaL10n.string("ba.office.friendCode.copy")
    }
}

private struct BaFriendCodeCopyPill: View {
    let friendCode: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            BaFriendCodeInlineText(friendCode: friendCode)
                .layoutPriority(1)

            Spacer(minLength: 8)

            Button(action: onCopy) {
                Label(copyTitle, systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .labelStyle(.iconOnly)
                    .baSymbolBounce(value: isCopied)
            }
            .buttonStyle(.glass)
            .foregroundStyle(isCopied ? BaDesign.green : BaDesign.blue)
            .accessibilityLabel(Text(copyTitle))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlassSurface(cornerRadius: 18, tint: BaDesign.blue.opacity(0.045), isInteractive: false)
    }

    private var copyTitle: String {
        isCopied
            ? BaL10n.string("ba.office.friendCode.copied")
            : BaL10n.string("ba.office.friendCode.copy")
    }
}

private struct BaFriendCodeInlineText: View {
    let friendCode: String

    var body: some View {
        HStack(spacing: 5) {
            Text(prefix)
                .layoutPriority(0)

            Text(friendCode)
                .font(BaOverviewTextToken.number)
                .monospaced()
                .layoutPriority(2)
        }
        .font(BaOverviewTextToken.number)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }

    private var prefix: String {
        String(format: BaL10n.string("ba.office.friendCode.display.format"), "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
                Text(String(format: BaL10n.string("ba.office.dutyStudent.avatar.accessibility"), dutyStudent.name))
            )
        } else {
            BaGameAssetIcon(.schale, size: 44)
                .frame(width: 50, height: 50)
                .liquidGlassSurface(cornerRadius: 18, tint: BaDesign.blue.opacity(0.06), isInteractive: false)
                .accessibilityLabel(Text(BaL10n.string("ba.office.identity.avatar.accessibility")))
        }
    }
}

struct BaOverviewAPCard: View {
    @Environment(\.baAdaptiveMetrics) private var metrics

    let office: BaOfficeSnapshot
    let settings: BaAppSettings
    let onCommit: (Int, Int, Int) -> Void

    @State private var isEditorPresented = false

    var body: some View {
        BaGlassCard(tint: BaDesign.green) {
            VStack(alignment: .leading, spacing: BaOverviewMetricStyle.cardSpacing) {
                BaOverviewSectionTitle(title: BaL10n.string("ba.office.ap.label"), asset: .actionPoint)

                BaOverviewResourceReadout(
                    title: BaL10n.string("ba.office.ap.current.title"),
                    value: office.apCurrentLimit,
                    detail: office.apRemaining,
                    asset: .actionPoint,
                    tint: BaDesign.green
                ) {
                    BaOverviewIconGlassButton(
                        title: BaL10n.string("ba.overview.ap.edit.title"),
                        systemImage: "pencil",
                        action: presentEditor
                    )
                }

                BaOverviewFixedGrid(
                    items: apMetricTiles,
                    columnCount: metrics.overviewInnerGridColumnCount
                ) { tile in
                    if tile.isAction {
                        Button {
                            presentEditor()
                    } label: {
                        metricTile(tile)
                    }
                        .buttonStyle(BaPressButtonStyle())
                        .accessibilityLabel(BaL10n.string("ba.overview.ap.edit.title"))
                    } else {
                        metricTile(tile)
                    }
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

    private var apMetricTiles: [BaOverviewMetricTileModel] {
        [
            BaOverviewMetricTileModel(
                id: "next",
                title: BaL10n.string("ba.office.ap.next.title"),
                value: office.apNext,
                detail: BaL10n.string("ba.office.ap.next.detail"),
                asset: .actionPointTight,
                tint: BaDesign.green
            ),
            BaOverviewMetricTileModel(
                id: "full",
                title: BaL10n.string("ba.office.ap.full.label"),
                value: office.apFullAt,
                detail: office.apFullRemain,
                systemImage: "calendar.badge.checkmark",
                tint: BaDesign.cyan
            ),
            BaOverviewMetricTileModel(
                id: "sync",
                title: BaL10n.string("ba.office.ap.sync.label"),
                value: office.apSyncAt,
                detail: BaL10n.string("ba.overview.sync.detail"),
                systemImage: "clock.arrow.circlepath",
                tint: BaDesign.blue
            ),
            BaOverviewMetricTileModel(
                id: "threshold",
                title: BaL10n.string("ba.settings.ap.threshold.title"),
                value: "\(settings.apNotifyThreshold)",
                detail: BaL10n.string("ba.settings.threshold.edit.detail"),
                systemImage: "bell.badge",
                tint: BaDesign.amber,
                isAction: true
            ),
        ]
    }

    private func metricTile(_ tile: BaOverviewMetricTileModel) -> some View {
        BaOverviewMetricTile(
            title: tile.title,
            value: tile.value,
            detail: tile.detail,
            asset: tile.asset,
            systemImage: tile.systemImage,
            tint: tile.tint
        )
    }
}

private struct BaOverviewMetricTileModel: Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    var asset: BaGameAsset?
    var systemImage: String?
    let tint: Color
    var isAction = false
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
                BaOverviewSectionTitle(title: BaL10n.string("ba.cafe.title"), asset: .cafeAP)

                BaOverviewResourceReadout(
                    title: BaL10n.string("ba.cafe.storage.title"),
                    value: "\(office.cafeApCurrent)/\(office.cafeApLimit)",
                    detail: cafeStorageDetail,
                    asset: .cafeAP,
                    tint: BaDesign.pink
                ) {
                    HStack(spacing: 8) {
                        BaOverviewIconGlassButton(
                            title: BaL10n.string("ba.overview.cafe.edit.title"),
                            systemImage: "slider.horizontal.3",
                            action: presentEditor
                        )

                        BaOverviewIconGlassButton(
                            title: BaL10n.string("ba.cafe.action.claimAp"),
                            systemImage: "tray.and.arrow.down.fill",
                            action: onClaimCafeAP
                        )
                    }
                }

                BaOverviewFixedGrid(
                    items: office.cafeVisitSlots,
                    columnCount: metrics.overviewInnerGridColumnCount
                ) { slot in
                    BaOverviewMetricTile(
                        title: slot.title,
                        value: slot.value,
                        detail: slot.detail,
                        asset: .lobbyWork,
                        tint: BaDesign.pink
                    )
                }

                BaOverviewFixedGrid(
                    items: tacticalAndHeadpatItems,
                    columnCount: metrics.overviewInnerGridColumnCount
                ) { item in
                    switch item {
                    case .tactical:
                        BaOverviewMetricTile(
                            title: BaL10n.string("ba.cafe.metric.tactical"),
                            value: office.tacticalRefresh,
                            detail: office.tacticalRefreshDetail,
                            asset: .arenaCoin,
                            tint: BaDesign.amber
                        )
                    case .headpat(let headpatAction):
                        BaOverviewActionTile(
                            action: headpatAction,
                            onTap: { onPerformAction(headpatAction.kind) },
                            onReset: { onResetAction(headpatAction.kind) }
                        )
                    }
                }

                BaOverviewFixedGrid(
                    items: inviteActions,
                    columnCount: metrics.overviewInnerGridColumnCount
                ) { action in
                    BaOverviewActionTile(
                        action: action,
                        onTap: { onPerformAction(action.kind) },
                        onReset: { onResetAction(action.kind) }
                    )
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

    private var tacticalAndHeadpatItems: [BaOverviewCafeSecondaryItem] {
        if let headpatAction {
            return [.tactical, .headpat(headpatAction)]
        }
        return [.tactical]
    }

    private var cafeStorageDetail: String {
        String.localizedStringWithFormat(
            BaL10n.string("ba.overview.cafe.storage.detail.format"),
            BaL10n.string("ba.overview.cafe.shared.detail"),
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

private enum BaOverviewCafeSecondaryItem: Identifiable {
    case tactical
    case headpat(BaCafeActionSnapshot)

    var id: String {
        switch self {
        case .tactical:
            "tactical"
        case .headpat(let action):
            action.id.rawValue
        }
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
        titles.first ?? BaL10n.string("ba.overview.timeline.empty")
    }

    var extraTitleText: String? {
        let extraCount = titles.count - 1
        guard extraCount > 0 else {
            return nil
        }
        return String.localizedStringWithFormat(
            BaL10n.string("ba.overview.timeline.moreItems.format"),
            extraCount
        )
    }

    var endLineText: String? {
        guard let endText else {
            return nil
        }
        return String.localizedStringWithFormat(
            BaL10n.string("ba.overview.timeline.endsAt.format"),
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
            remainingText: BaL10n.string("ba.state.notSynced"),
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
                BaOverviewSectionTitle(title: BaL10n.string("ba.overview.timeline.title"), asset: .guideMission)

                BaOverviewFixedGrid(
                    items: BaOverviewTimelineDestination.allCases,
                    columnCount: metrics.overviewSummaryGridColumnCount
                ) { destination in
                    Button {
                        onOpenTab(destination.tab)
                    } label: {
                        timelineTile(for: destination)
                    }
                    .buttonStyle(BaPressButtonStyle())
                    .accessibilityLabel(destination.accessibilityLabel)
                }
            }
        }
    }

    private func timelineTile(for destination: BaOverviewTimelineDestination) -> some View {
        BaOverviewTimelineTile(
            title: destination.title,
            item: destination.item(in: summary),
            syncAt: destination.syncAt(activitySyncAt: activitySyncAt, poolSyncAt: poolSyncAt),
            systemImage: destination.systemImage,
            tint: destination.tint
        )
    }
}

private enum BaOverviewTimelineDestination: CaseIterable, Identifiable {
    case activity
    case pool

    var id: AppTab { tab }

    var tab: AppTab {
        switch self {
        case .activity:
            .activity
        case .pool:
            .pool
        }
    }

    var title: String {
        switch self {
        case .activity:
            BaL10n.string("ba.tab.activity")
        case .pool:
            BaL10n.string("ba.tab.pool")
        }
    }

    var systemImage: String {
        switch self {
        case .activity:
            "calendar"
        case .pool:
            "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .activity:
            BaDesign.blue
        case .pool:
            BaDesign.violet
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .activity:
            BaL10n.string("ba.overview.timeline.openActivity")
        case .pool:
            BaL10n.string("ba.overview.timeline.openPool")
        }
    }

    func item(in summary: BaOverviewTimelineSummary) -> BaOverviewTimelineSummaryItem {
        switch self {
        case .activity:
            summary.activity
        case .pool:
            summary.pool
        }
    }

    func syncAt(activitySyncAt: Date?, poolSyncAt: Date?) -> Date? {
        switch self {
        case .activity:
            activitySyncAt
        case .pool:
            poolSyncAt
        }
    }
}
