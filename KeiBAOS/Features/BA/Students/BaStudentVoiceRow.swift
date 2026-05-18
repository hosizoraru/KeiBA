//
//  BaStudentVoiceRow.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct BaStudentVoiceRow: View {
    @Environment(\.openURL) private var openURL

    let row: BaGuideVoiceEntry
    let displayHeaders: [String]
    let playbackHeaders: [String]
    let selectedLanguage: String
    let playback: BaVoicePlaybackController

    private var playbackURL: URL? {
        BaVoiceLanguageResolver.playbackURL(
            for: row,
            headers: playbackHeaders,
            selectedHeader: selectedLanguage
        )
    }

    private var selectedLine: BaVoiceLinePair? {
        BaVoiceDisplayModel.selectedLine(
            for: row,
            fallbackHeaders: displayHeaders,
            selectedLanguage: selectedLanguage
        )
    }

    private var officialLine: BaVoiceLinePair? {
        BaVoiceDisplayModel.officialLine(for: row, fallbackHeaders: displayHeaders)
    }

    private var secondaryLines: [BaVoiceLinePair] {
        BaVoiceDisplayModel.secondaryLines(
            for: row,
            fallbackHeaders: displayHeaders,
            selectedLanguage: selectedLanguage
        )
    }

    private var isCurrent: Bool {
        guard let playbackURL else { return false }
        return playback.currentRemoteURL == playbackURL
    }

    private var copySelectedText: String {
        BaVoiceDisplayModel.copySelectedText(
            for: row,
            fallbackHeaders: displayHeaders,
            selectedLanguage: selectedLanguage
        )
    }

    private var copyAllText: String {
        BaVoiceDisplayModel.copyAllText(for: row, fallbackHeaders: displayHeaders)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: BaStudentDetailSection.voice.systemImage)
                .foregroundStyle(isCurrent ? BaDesign.cyan : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 9) {
                header

                if let selectedLine {
                    BaVoiceLineBlock(
                        pair: selectedLine,
                        isPrimary: true,
                        selectedLanguage: selectedLanguage
                    )
                }

                if let officialLine {
                    BaVoiceLineBlock(
                        pair: officialLine,
                        isPrimary: false,
                        selectedLanguage: selectedLanguage
                    )
                }

                if secondaryLines.isEmpty == false {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(secondaryLines) { pair in
                                BaVoiceLineBlock(pair: pair, isPrimary: false, selectedLanguage: selectedLanguage)
                            }
                        }
                        .padding(.top, 6)
                    } label: {
                        Label(BaL10n.string("ba.student.detail.voice.moreLines"), systemImage: "text.bubble")
                            .font(BaTextToken.rowCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                BaVoicePasteboard.copy(copySelectedText)
            } label: {
                Label(BaL10n.string("ba.action.copy"), systemImage: "doc.on.doc")
            }
            .tint(BaDesign.blue)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    if let section = row.section, section.isEmpty == false {
                        BaVoiceBadge(title: section, tint: BaDesign.cyan)
                    }
                    if let format = BaVoiceDisplayModel.audioFormatTitle(for: playbackURL) {
                        BaVoiceBadge(title: format, tint: BaDesign.blue)
                    } else {
                        BaVoiceBadge(
                            title: BaL10n.string("ba.student.detail.voice.textOnly"),
                            tint: Color.secondary,
                            isMuted: true
                        )
                    }
                    if BaVoiceDisplayModel.audioCount(for: row) > 1 {
                        BaVoiceBadge(
                            title: audioCountTitle,
                            tint: BaDesign.violet
                        )
                    }
                }

                Text(BaVoiceLabelFormatter.entryTitle(row.title))
                    .font(BaTextToken.rowTitle)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 8)

            playbackButton
            rowMenu
        }
    }

    private var audioCountTitle: String {
        String(
            format: BaL10n.string("ba.student.detail.voice.audioCount.short.format"),
            BaVoiceDisplayModel.audioCount(for: row)
        )
    }

    @ViewBuilder
    private var playbackButton: some View {
        if let playbackURL {
            if BaVoicePlaybackController.supportsPlayback(playbackURL) {
                Button {
                    playback.toggle(remoteURL: playbackURL)
                } label: {
                    BaVoicePlaybackButtonContent(
                        isCurrent: isCurrent,
                        isLoading: playback.isLoading,
                        isPlaying: playback.isPlaying,
                        progress: playback.progress
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playbackAccessibilityLabel)
            } else {
                Image(systemName: "waveform.badge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel(BaL10n.string("ba.student.detail.voice.error.unsupported"))
            }
        }
    }

    private var playbackAccessibilityLabel: String {
        isCurrent && playback.isPlaying
            ? BaL10n.string("ba.student.detail.voice.pause")
            : BaL10n.string("ba.student.detail.voice.play")
    }

    private var rowMenu: some View {
        Menu {
            copyActions

            if let playbackURL {
                BaMenuActionButton(
                    title: BaL10n.string("ba.student.detail.voice.openAudio"),
                    systemImage: "safari"
                ) {
                    openURL(playbackURL)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BaL10n.string("ba.action.more"))
    }

    @ViewBuilder
    private var copyActions: some View {
        BaMenuActionButton(
            title: BaL10n.string("ba.student.detail.voice.copySelected"),
            systemImage: "doc.on.doc"
        ) {
            BaVoicePasteboard.copy(copySelectedText)
        }

        BaMenuActionButton(
            title: BaL10n.string("ba.student.detail.voice.copyAll"),
            systemImage: "list.clipboard"
        ) {
            BaVoicePasteboard.copy(copyAllText)
        }
    }
}

private struct BaVoicePlaybackButtonContent: View {
    let isCurrent: Bool
    let isLoading: Bool
    let isPlaying: Bool
    let progress: Double

    var body: some View {
        ZStack {
            if isCurrent, isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: isCurrent && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3.weight(.semibold))
            }
        }
        .foregroundStyle(BaDesign.blue)
        .frame(width: 34, height: 34)
        .overlay(alignment: .bottom) {
            if isCurrent, progress > 0 {
                ProgressView(value: progress)
                    .tint(BaDesign.blue)
                    .controlSize(.mini)
                    .frame(width: 22)
                    .offset(y: 4)
            }
        }
    }
}

private struct BaVoiceLineBlock: View {
    let pair: BaVoiceLinePair
    let isPrimary: Bool
    let selectedLanguage: String

    private var isSelectedLanguage: Bool {
        BaVoiceLanguageResolver.canonicalLanguageLabel(pair.language) ==
            BaVoiceLanguageResolver.canonicalLanguageLabel(selectedLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(BaVoiceLabelFormatter.languageTitle(pair.language))
                .font(.caption.weight(.semibold))
                .foregroundStyle(labelColor)

            Text(pair.text)
                .font(isPrimary ? BaTextToken.rowSubtitle : BaTextToken.rowCaption)
                .foregroundStyle(isPrimary ? .primary : .secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 10 : 0)
        .modifier(BaPrimaryVoiceLineSurface(isPrimary: isPrimary, tint: labelColor))
    }

    private var labelColor: Color {
        if BaVoiceDisplayModel.isOfficialTranslation(pair.language) {
            return BaDesign.green
        }
        return isSelectedLanguage ? BaDesign.blue : .secondary
    }
}

private struct BaPrimaryVoiceLineSurface: ViewModifier {
    let isPrimary: Bool
    let tint: Color

    func body(content: Content) -> some View {
        if isPrimary {
            content
                .liquidGlassSurface(cornerRadius: 14, tint: tint.opacity(0.055), isInteractive: false)
        } else {
            content
        }
    }
}

private struct BaVoiceBadge: View {
    let title: String
    let tint: Color
    var isMuted = false

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isMuted ? Color.secondary : tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(badgeFill, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(badgeStroke, lineWidth: 0.8)
            }
    }

    private var badgeFill: Color {
        tint.opacity(isMuted ? 0.04 : 0.09)
    }

    private var badgeStroke: Color {
        tint.opacity(isMuted ? 0.10 : 0.18)
    }
}

private enum BaVoicePasteboard {
    static func copy(_ text: String) {
        BaPasteboard.copy(text)
    }
}
