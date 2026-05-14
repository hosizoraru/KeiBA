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

    var body: some View {
        Section(BaStudentDetailSection.voice.title) {
            if rows.isEmpty {
                BaStudentDetailEmptyRow(section: .voice)
            } else {
                ForEach(rows) { row in
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(BaTextToken.rowTitle)
                            if let section = row.section, section.isEmpty == false {
                                Text(section)
                                    .font(BaTextToken.rowCaption)
                                    .foregroundStyle(.secondary)
                            }
                            let pairedLines = Array(zip(row.lineHeaders ?? [], row.lines ?? []))
                            if pairedLines.isEmpty == false {
                                ForEach(pairedLines.prefix(4), id: \.0) { label, line in
                                    Text("\(label): \(line)")
                                        .font(BaTextToken.rowCaption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            } else if row.transcript.isEmpty == false {
                                Text(row.transcript)
                                    .font(BaTextToken.rowCaption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            if let audioCount = row.audioURLs?.count, audioCount > 0 {
                                let audioText = String(
                                    format: String(localized: "ba.student.detail.voice.audioCount.format"),
                                    audioCount
                                )
                                Text(audioText)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } icon: {
                        Image(systemName: BaStudentDetailSection.voice.systemImage)
                            .foregroundStyle(BaDesign.cyan)
                    }
                }
            }
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
