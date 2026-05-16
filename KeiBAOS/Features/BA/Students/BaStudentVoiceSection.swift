//
//  BaStudentVoiceSection.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentVoiceSection: View {
    let rows: [BaGuideVoiceEntry]
    let voiceLanguageHeaders: [String]
    @Binding var searchText: String

    @State private var selectedLanguage = ""
    @State private var sectionFilter = BaVoiceSectionFilter.all
    @State private var playback = BaVoicePlaybackController()

    var body: some View {
        let snapshot = BaVoiceSectionSnapshot(
            rows: rows,
            voiceLanguageHeaders: voiceLanguageHeaders,
            selectedLanguage: selectedLanguage,
            sectionFilter: sectionFilter,
            searchText: searchText,
            currentURL: playback.currentRemoteURL
        )

        Section {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: .voice)
            } else {
                BaVoiceControlPanel(
                    selectedLanguage: $selectedLanguage,
                    sectionFilter: $sectionFilter,
                    languages: snapshot.languagePickerHeaders,
                    filters: snapshot.sectionFilters,
                    visibleCount: snapshot.filteredRows.count,
                    totalCount: rows.count
                )

                if let nowPlayingEntry = snapshot.nowPlayingEntry {
                    BaVoiceNowPlayingRow(
                        entry: nowPlayingEntry,
                        fallbackHeaders: snapshot.displayHeaders,
                        selectedLanguage: snapshot.activeLanguage,
                        playback: playback
                    )
                }

                if let error = playback.errorMessage {
                    BaVoicePlaybackErrorRow(error: error)
                }

                if snapshot.filteredRows.isEmpty {
                    BaVoiceEmptyFilteredRow()
                } else {
                    ForEach(snapshot.filteredRows) { row in
                        BaStudentVoiceRow(
                            row: row,
                            displayHeaders: snapshot.displayHeaders,
                            playbackHeaders: snapshot.playbackHeaders,
                            selectedLanguage: snapshot.activeLanguage,
                            playback: playback
                        )
                    }
                }
            }
        } footer: {
            if rows.isEmpty == false {
                Text(String(format: String(localized: "ba.student.detail.voice.footer.format"), rows.count))
            }
        }
        .onAppear(perform: refreshSelections)
        .onChange(of: snapshot.rowIDs) { _, _ in
            refreshSelections()
        }
        .onDisappear {
            playback.stop()
        }
    }

    private func refreshSelections() {
        let displayHeaders = BaVoiceLanguageResolver.displayHeaders(for: rows, preferredHeaders: voiceLanguageHeaders)
        let playbackHeaders = BaVoiceLanguageResolver.playableHeaders(for: rows, preferredHeaders: voiceLanguageHeaders)
        let languagePickerHeaders = BaVoiceSectionSnapshot.languagePickerHeaders(
            displayHeaders: displayHeaders,
            playbackHeaders: playbackHeaders
        )
        let sectionFilters = BaVoiceSectionFilter.filters(for: rows)
        if selectedLanguage.isEmpty || languagePickerHeaders.contains(selectedLanguage) == false {
            selectedLanguage = playbackHeaders.first ?? languagePickerHeaders.first ?? ""
        }
        if sectionFilters.contains(sectionFilter) == false {
            sectionFilter = .all
        }
    }
}

private struct BaVoiceSectionSnapshot {
    let rowIDs: [String]
    let displayHeaders: [String]
    let playbackHeaders: [String]
    let languagePickerHeaders: [String]
    let sectionFilters: [BaVoiceSectionFilter]
    let activeLanguage: String
    let filteredRows: [BaGuideVoiceEntry]
    let nowPlayingEntry: BaGuideVoiceEntry?

    init(
        rows: [BaGuideVoiceEntry],
        voiceLanguageHeaders: [String],
        selectedLanguage: String,
        sectionFilter: BaVoiceSectionFilter,
        searchText: String,
        currentURL: URL?
    ) {
        rowIDs = rows.map(\.id)
        displayHeaders = BaVoiceLanguageResolver.displayHeaders(for: rows, preferredHeaders: voiceLanguageHeaders)
        playbackHeaders = BaVoiceLanguageResolver.playableHeaders(for: rows, preferredHeaders: voiceLanguageHeaders)
        languagePickerHeaders = Self.languagePickerHeaders(
            displayHeaders: displayHeaders,
            playbackHeaders: playbackHeaders
        )
        sectionFilters = BaVoiceSectionFilter.filters(for: rows)
        activeLanguage = languagePickerHeaders.contains(selectedLanguage)
            ? selectedLanguage
            : (playbackHeaders.first ?? languagePickerHeaders.first ?? "")
        filteredRows = BaVoiceDisplayModel.filteredEntries(
            rows,
            filter: sectionFilter,
            query: searchText,
            fallbackHeaders: displayHeaders
        )
        nowPlayingEntry = BaVoiceDisplayModel.nowPlayingEntry(entries: rows, currentURL: currentURL)
    }

    static func languagePickerHeaders(displayHeaders: [String], playbackHeaders: [String]) -> [String] {
        let headers = playbackHeaders.isEmpty ? displayHeaders : playbackHeaders
        return headers.filter {
            BaVoiceLanguageResolver.canonicalLanguageLabel($0) != "官翻"
        }
    }
}

private struct BaVoiceControlPanel: View {
    @Binding var selectedLanguage: String
    @Binding var sectionFilter: BaVoiceSectionFilter

    let languages: [String]
    let filters: [BaVoiceSectionFilter]
    let visibleCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if languages.count > 1 {
                if languages.count <= 3 {
                    Picker(String(localized: "ba.student.detail.voice.language.picker"), selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { header in
                            Text(BaVoiceLabelFormatter.languageTitle(header))
                                .tag(header)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker(String(localized: "ba.student.detail.voice.language.picker"), selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { header in
                            Text(BaVoiceLabelFormatter.languageTitle(header))
                                .tag(header)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            HStack(spacing: 12) {
                Label(String(localized: "ba.student.detail.voice.filter.category"), systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                BaVoiceFilterMenu(selection: $sectionFilter, filters: filters)

                Text(visibleCountTitle)
                    .font(BaTextToken.rowCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var visibleCountTitle: String {
        String(
            format: String(localized: "ba.student.detail.voice.visibleCount.format"),
            visibleCount,
            totalCount
        )
    }
}

private struct BaVoiceFilterMenu: View {
    @Binding var selection: BaVoiceSectionFilter

    let filters: [BaVoiceSectionFilter]

    var body: some View {
        Menu {
            ForEach(filters) { filter in
                Button {
                    selection = filter
                } label: {
                    if filter == selection {
                        Label(filter.title, systemImage: "checkmark")
                    } else {
                        Text(filter.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(selection.title)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(BaDesign.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(BaDesign.blue.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(BaDesign.blue.opacity(0.16), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(String(localized: "ba.student.detail.voice.filter.category"))
        .accessibilityValue(selection.title)
    }
}

private struct BaVoiceNowPlayingRow: View {
    let entry: BaGuideVoiceEntry
    let fallbackHeaders: [String]
    let selectedLanguage: String
    let playback: BaVoicePlaybackController

    private var selectedLine: BaVoiceLinePair? {
        BaVoiceDisplayModel.selectedLine(
            for: entry,
            fallbackHeaders: fallbackHeaders,
            selectedLanguage: selectedLanguage
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: playback.isPlaying ? "waveform" : "waveform.circle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(String(localized: "ba.student.detail.voice.nowPlaying"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(BaVoiceLabelFormatter.entryTitle(entry.title))
                    .font(BaTextToken.rowTitle)
                    .lineLimit(1)
                if let selectedLine {
                    Text("\(BaVoiceLabelFormatter.languageTitle(selectedLine.language)): \(selectedLine.text)")
                        .font(BaTextToken.rowCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                ProgressView(value: playback.progress)
                    .tint(BaDesign.cyan)
                    .controlSize(.small)
            }

            Button {
                playback.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.caption.weight(.semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(String(localized: "ba.student.detail.voice.stop"))
        }
        .padding(.vertical, 4)
    }
}

private struct BaVoicePlaybackErrorRow: View {
    let error: String

    var body: some View {
        Label {
            Text(error)
                .font(BaTextToken.rowCaption)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(BaDesign.amber)
        }
    }
}

private struct BaVoiceEmptyFilteredRow: View {
    var body: some View {
        Label {
            Text(String(localized: "ba.student.detail.voice.empty.filtered"))
                .font(BaTextToken.rowCaption)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(.secondary)
        }
    }
}
