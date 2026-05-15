//
//  BaStudentProfileCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI

struct BaStudentProfileCardsSection: View {
    let tint: Color
    private let sections: [BaStudentProfileSection]

    init(info: BaStudentGuideInfo, tint: Color) {
        self.tint = tint
        sections = info.profileSections
    }

    private var displaySections: [BaStudentProfileSection] {
        let hasContent = sections.contains { $0.isEmpty == false }
        return hasContent ? sections : []
    }

    var body: some View {
        Section {
            if displaySections.isEmpty {
                BaStudentDetailEmptyRow(section: .profile)
                    .baStudentDetailListCardRow()
            } else {
                ForEach(displaySections) { section in
                    BaStudentProfileSectionCard(section: section, tint: tint)
                        .baStudentDetailListCardRow()
                }
            }
        } header: {
            BaStudentProfileSectionHeader(tint: tint)
        }
    }
}

private struct BaStudentProfileSectionHeader: View {
    let tint: Color

    var body: some View {
        Label {
            Text(String(localized: "ba.student.detail.archive.title"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: BaStudentDetailSection.profile.systemImage)
                .foregroundStyle(tint)
        }
        .textCase(nil)
    }
}

private struct BaStudentProfileSectionCard: View {
    let section: BaStudentProfileSection
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentProfileCardTitle(section: section, tint: tint)
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section.kind {
        case .gifts:
            BaStudentProfileGiftGrid(items: section.giftItems, tint: tint)
        case .sameName:
            BaStudentSameNameRoleList(section: section, tint: tint)
        case .chocolate, .furniture:
            BaStudentProfileRowsView(rows: section.rows, tint: tint)
            BaStudentProfileGalleryList(items: section.galleryItems, tint: tint)
        case .names, .info, .hobby, .other:
            BaStudentProfileRowsView(rows: section.rows, tint: tint)
        }
    }
}

private struct BaStudentProfileCardTitle: View {
    let section: BaStudentProfileSection
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: section.kind.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 22)

            Text(section.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }
}

private struct BaStudentProfileRowsView: View {
    let rows: [BaStudentProfileFieldRow]
    let tint: Color

    var body: some View {
        VStack(spacing: 11) {
            ForEach(rows.prefix(120)) { row in
                BaStudentProfileFieldRowView(row: row, tint: tint)
            }
        }
    }
}

private struct BaStudentProfileFieldRowView: View {
    let row: BaStudentProfileFieldRow
    let tint: Color

    private var displayValue: String {
        row.value.ifBlank(String(localized: "ba.common.none"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(row.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 132, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                valueView
            }

            if let imageURL = row.imageURL {
                BaStudentProfileInlineImage(url: imageURL, tint: tint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var valueView: some View {
        if let externalURL = row.externalURL {
            Link(destination: externalURL) {
                HStack(spacing: 5) {
                    Text(displayValue)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
            }
        } else if row.prefersCapsule {
            BaStudentProfileValueChip(title: displayValue, tint: tint)
        } else {
            Text(displayValue)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BaStudentProfileInlineImage: View {
    let url: URL
    let tint: Color

    var body: some View {
        BaRemoteIconSurface(
            url: url,
            fallbackSystemImage: "photo",
            tint: tint,
            size: 74,
            width: 118,
            fallbackFont: .title3.weight(.semibold)
        )
        .accessibilityHidden(true)
    }
}

private struct BaStudentProfileValueChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 1)
            }
    }
}

private struct BaStudentProfileGiftGrid: View {
    let items: [BaStudentProfileGiftItem]
    let tint: Color

    private let columns = [
        GridItem(.adaptive(minimum: 82, maximum: 118), spacing: 8, alignment: .top),
    ]

    var body: some View {
        if items.isEmpty {
            Text(String(localized: "ba.student.detail.profile.gifts.empty"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 9) {
                ForEach(items.prefix(24)) { item in
                    BaStudentProfileGiftCell(item: item, tint: tint)
                }
            }
        }
    }
}

private struct BaStudentProfileGiftCell: View {
    let item: BaStudentProfileGiftItem
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.055))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(tint.opacity(0.12), lineWidth: 1)
                    }

                BaRemoteIconSurface(
                    url: item.giftImageURL,
                    fallbackSystemImage: "gift",
                    tint: tint,
                    size: 62,
                    width: 86,
                    fallbackFont: .title3.weight(.semibold)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                if let emojiImageURL = item.emojiImageURL {
                    BaRemoteIconSurface(
                        url: emojiImageURL,
                        fallbackSystemImage: "heart",
                        tint: BaDesign.pink,
                        size: 18,
                        fallbackFont: .caption.weight(.semibold)
                    )
                    .padding(5)
                    .background(.regularMaterial, in: Capsule())
                    .padding(5)
                }
            }
            .frame(height: 70)

            Text(item.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BaStudentSameNameRoleList: View {
    let section: BaStudentProfileSection
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if section.sameNameRoleHint.isBlank == false {
                Text(section.sameNameRoleHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if section.sameNameRoleItems.isEmpty {
                Text(String(localized: "ba.student.detail.profile.sameName.empty"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(section.sameNameRoleItems.prefix(12)) { item in
                    BaStudentSameNameRoleRow(item: item, tint: tint)
                }
            }
        }
    }
}

private struct BaStudentSameNameRoleRow: View {
    let item: BaStudentProfileSameNameRoleItem
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            BaRemoteIconSurface(
                url: item.imageURL,
                fallbackSystemImage: "person.crop.square",
                tint: tint,
                size: 58,
                fallbackFont: .title3.weight(.semibold)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if item.guideURL == nil {
                    Text(String(localized: "ba.student.detail.profile.sameName.linkUnavailable"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            action
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var action: some View {
        if let guideURL = item.guideURL,
           let contentId = BaPoolStudentGuideResolver.contentID(from: guideURL)
        {
            NavigationLink {
                BaStudentDetailView(entry: entry(contentId: contentId, guideURL: guideURL))
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 34)
                    .liquidGlassSurface(cornerRadius: 17, tint: tint.opacity(0.08), isInteractive: true)
            }
            .buttonStyle(.plain)
        } else if let guideURL = item.guideURL {
            Link(destination: guideURL) {
                Image(systemName: "arrow.up.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 34)
                    .liquidGlassSurface(cornerRadius: 17, tint: tint.opacity(0.08), isInteractive: true)
            }
        }
    }

    private func entry(contentId: Int64, guideURL: URL) -> BaGuideCatalogEntry {
        BaGuideCatalogEntry(
            entryId: Int(contentId),
            pid: 0,
            contentId: contentId,
            name: item.name,
            alias: "",
            aliasDisplay: "",
            iconURL: item.imageURL,
            type: 3,
            order: 0,
            createdAt: nil,
            releaseDate: nil,
            detailURL: guideURL,
            category: .students
        )
    }
}

private struct BaStudentProfileGalleryList: View {
    let items: [BaGuideGalleryItem]
    let tint: Color

    var body: some View {
        if items.isEmpty == false {
            VStack(spacing: 10) {
                ForEach(items.prefix(8)) { item in
                    BaStudentProfileGalleryRow(item: item, tint: tint)
                }
            }
        }
    }
}

private struct BaStudentProfileGalleryRow: View {
    let item: BaGuideGalleryItem
    let tint: Color

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            BaRemoteIconSurface(
                url: item.imageURL ?? item.mediaURL,
                fallbackSystemImage: kind.systemImage,
                tint: tint,
                size: 58,
                width: 72,
                fallbackFont: .title3.weight(.semibold)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(galleryDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let mediaURL = item.mediaURL {
                Link(destination: mediaURL) {
                    Image(systemName: "arrow.up.right")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 36, height: 34)
                        .liquidGlassSurface(cornerRadius: 17, tint: tint.opacity(0.08), isInteractive: true)
                }
            }
        }
        .padding(9)
        .background(tint.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var galleryDetail: String {
        var parts = [kind.title]
        if item.detail.isBlank == false, item.detail != kind.title {
            parts.append(item.detail)
        }
        if let unlock = item.memoryUnlockLevel, unlock.isBlank == false {
            parts.append(String(format: String(localized: "ba.student.detail.memory.unlock.format"), unlock))
        }
        if let note = item.note, note.isBlank == false, parts.contains(note) == false {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }
}

private extension View {
    func baStudentDetailListCardRow() -> some View {
        listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func ifBlank(_ fallback: String) -> String {
        isBlank ? fallback : self
    }
}
