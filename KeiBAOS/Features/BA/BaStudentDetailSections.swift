//
//  BaStudentDetailSections.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentGuideRowsSection: View {
    let section: BaStudentDetailSection
    let rows: [BaGuideRow]
    let tint: Color

    var body: some View {
        Section(section.title) {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: section)
            } else {
                ForEach(rows.prefix(22)) { row in
                    BaStudentGuideRow(row: row, systemImage: section.systemImage, tint: tint)
                }
            }
        }
    }
}

struct BaStudentVoiceSection: View {
    let rows: [BaGuideVoiceEntry]

    @State private var selectedLanguage = ""
    @State private var playback = BaVoicePlaybackController()

    private var displayHeaders: [String] {
        BaVoiceLanguageResolver.displayHeaders(for: rows)
    }

    private var playbackHeaders: [String] {
        BaVoiceLanguageResolver.playbackHeaders(for: rows)
    }

    private var languagePickerHeaders: [String] {
        displayHeaders.filter {
            BaVoiceLanguageResolver.canonicalLanguageLabel($0) != "官翻"
        }
    }

    private var activeLanguage: String {
        if languagePickerHeaders.contains(selectedLanguage) {
            return selectedLanguage
        }
        return playbackHeaders.first ?? languagePickerHeaders.first ?? ""
    }

    var body: some View {
        Section(BaStudentDetailSection.voice.title) {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: .voice)
            } else {
                if languagePickerHeaders.count > 1 {
                    Picker(String(localized: "ba.student.detail.voice.language.picker"), selection: $selectedLanguage) {
                        ForEach(languagePickerHeaders, id: \.self) { header in
                            Text(BaVoiceLabelFormatter.languageTitle(header))
                                .tag(header)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                if let error = playback.errorMessage {
                    Label {
                        Text(error)
                            .font(BaTextToken.rowCaption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(BaDesign.amber)
                    }
                }

                ForEach(rows) { row in
                    BaStudentVoiceRow(
                        row: row,
                        displayHeaders: displayHeaders,
                        playbackHeaders: displayHeaders,
                        selectedLanguage: activeLanguage,
                        playback: playback
                    )
                }
            }
        }
        .onAppear(perform: updateSelectedLanguage)
        .onChange(of: playbackHeaders) { _, _ in
            updateSelectedLanguage()
        }
        .onDisappear {
            playback.stop()
        }
    }

    private func updateSelectedLanguage() {
        guard selectedLanguage.isEmpty || languagePickerHeaders.contains(selectedLanguage) == false else { return }
        selectedLanguage = playbackHeaders.first ?? languagePickerHeaders.first ?? ""
    }
}

private struct BaStudentVoiceRow: View {
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

    private var isCurrent: Bool {
        guard let playbackURL else { return false }
        return playback.currentRemoteURL == playbackURL
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: BaStudentDetailSection.voice.systemImage)
                .foregroundStyle(BaDesign.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(BaVoiceLabelFormatter.entryTitle(row.title))
                            .font(BaTextToken.rowTitle)
                        if let section = row.section, section.isEmpty == false {
                            Text(section)
                                .font(BaTextToken.rowCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    playbackButton
                }

                let visiblePairs = BaVoiceLanguageResolver
                    .linePairs(for: row, fallbackHeaders: displayHeaders)
                    .prefix(4)
                ForEach(visiblePairs) { pair in
                    HStack(alignment: .top, spacing: 8) {
                        Text(BaVoiceLabelFormatter.languageTitle(pair.language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(pair.language == selectedLanguage ? BaDesign.blue : .secondary)
                            .frame(minWidth: 38, alignment: .leading)
                        Text(pair.text)
                            .font(BaTextToken.rowCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var playbackButton: some View {
        if let playbackURL {
            if BaVoicePlaybackController.supportsNativePlayback(playbackURL) {
                Button {
                    playback.toggle(remoteURL: playbackURL)
                } label: {
                    ZStack {
                        if isCurrent, playback.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: isCurrent && playback.isPlaying ? "pause.fill" : "play.fill")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .foregroundStyle(BaDesign.blue)
                    .frame(width: 34, height: 34)
                    .liquidGlassSurface(cornerRadius: 17, tint: BaDesign.blue.opacity(0.08), isInteractive: true)
                    .overlay(alignment: .bottom) {
                        if isCurrent, playback.progress > 0 {
                            ProgressView(value: playback.progress)
                                .tint(BaDesign.blue)
                                .controlSize(.mini)
                                .frame(width: 22)
                                .offset(y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isCurrent && playback.isPlaying
                        ? String(localized: "ba.student.detail.voice.pause")
                        : String(localized: "ba.student.detail.voice.play")
                )
            } else {
                Image(systemName: "waveform.badge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel(String(localized: "ba.student.detail.voice.error.unsupported"))
            }
        } else {
            Image(systemName: "speaker.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 34, height: 34)
                .accessibilityLabel(String(localized: "ba.student.detail.voice.noAudio"))
        }
    }
}

struct BaStudentGallerySection: View {
    let items: [BaGuideGalleryItem]

    var body: some View {
        Section(BaStudentDetailSection.gallery.title) {
            if items.isEmpty {
                BaStudentDetailEmptyRow(section: .gallery)
            } else {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        let kind = item.mediaKind ?? .image
                        BaRowThumbnail(url: item.imageURL, fallbackSystemImage: kind.systemImage, tint: BaDesign.pink)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(BaTextToken.rowTitle)
                            Text(galleryDetail(item))
                                .font(BaTextToken.rowCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            if let mediaURL = item.mediaURL {
                                Text(mediaURL.host ?? mediaURL.lastPathComponent)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func galleryDetail(_ item: BaGuideGalleryItem) -> String {
        let kind = item.mediaKind ?? .image
        var parts = [kind.title]
        if item.detail.isEmpty == false, item.detail != kind.title {
            parts.append(item.detail)
        }
        if let unlock = item.memoryUnlockLevel, unlock.isEmpty == false {
            parts.append(String(format: String(localized: "ba.student.detail.memory.unlock.format"), unlock))
        }
        if let note = item.note, note.isEmpty == false, parts.contains(note) == false {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }
}

struct BaStudentGuideRow: View {
    let row: BaGuideRow
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if row.imageURL != nil {
                BaRowThumbnail(url: row.imageURL, fallbackSystemImage: systemImage, tint: tint, size: 44)
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(BaTextToken.rowTitle)
                Text(row.value.isEmpty ? String(localized: "ba.common.none") : row.value)
                    .font(BaTextToken.rowCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                if let count = row.imageURLs?.count, count > 1 {
                    Text(String(format: String(localized: "ba.student.detail.imageCount.format"), count))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct BaStudentDetailEmptyRow: View {
    let section: BaStudentDetailSection

    var body: some View {
        Label {
            Text(String(localized: "ba.student.detail.section.empty"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: section.systemImage)
                .foregroundStyle(.secondary)
        }
    }
}
