//
//  BaStudentVoiceSection.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentVoiceSection: View {
    let rows: [BaGuideVoiceEntry]
    @Binding var searchText: String

    @State private var selectedLanguage = ""
    @State private var sectionFilter = BaVoiceSectionFilter.all
    @State private var playback = BaVoicePlaybackController()

    private var rowIDs: [String] {
        rows.map(\.id)
    }

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

    private var sectionFilters: [BaVoiceSectionFilter] {
        BaVoiceSectionFilter.filters(for: rows)
    }

    private var activeLanguage: String {
        if languagePickerHeaders.contains(selectedLanguage) {
            return selectedLanguage
        }
        return playbackHeaders.first ?? languagePickerHeaders.first ?? ""
    }

    private var filteredRows: [BaGuideVoiceEntry] {
        BaVoiceDisplayModel.filteredEntries(
            rows,
            filter: sectionFilter,
            query: searchText,
            fallbackHeaders: displayHeaders
        )
    }

    private var nowPlayingEntry: BaGuideVoiceEntry? {
        BaVoiceDisplayModel.nowPlayingEntry(entries: rows, currentURL: playback.currentRemoteURL)
    }

    var body: some View {
        Section {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: .voice)
            } else {
                BaVoiceControlPanel(
                    selectedLanguage: $selectedLanguage,
                    sectionFilter: $sectionFilter,
                    languages: languagePickerHeaders,
                    filters: sectionFilters,
                    visibleCount: filteredRows.count,
                    totalCount: rows.count
                )

                if let nowPlayingEntry {
                    BaVoiceNowPlayingRow(
                        entry: nowPlayingEntry,
                        fallbackHeaders: displayHeaders,
                        selectedLanguage: activeLanguage,
                        playback: playback
                    )
                }

                if let error = playback.errorMessage {
                    BaVoicePlaybackErrorRow(error: error)
                }

                if filteredRows.isEmpty {
                    BaVoiceEmptyFilteredRow()
                } else {
                    ForEach(filteredRows) { row in
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
        } footer: {
            if rows.isEmpty == false {
                Text(String(format: String(localized: "ba.student.detail.voice.footer.format"), rows.count))
            }
        }
        .onAppear(perform: refreshSelections)
        .onChange(of: rowIDs) { _, _ in
            refreshSelections()
        }
        .onDisappear {
            playback.stop()
        }
    }

    private func refreshSelections() {
        if selectedLanguage.isEmpty || languagePickerHeaders.contains(selectedLanguage) == false {
            selectedLanguage = playbackHeaders.first ?? languagePickerHeaders.first ?? ""
        }
        if sectionFilters.contains(sectionFilter) == false {
            sectionFilter = .all
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
