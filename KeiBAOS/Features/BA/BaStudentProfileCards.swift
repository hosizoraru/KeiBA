//
//  BaStudentProfileCards.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI
import UniformTypeIdentifiers

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
        case .chocolate:
            BaStudentProfileRowsView(rows: section.rows, tint: tint)
            BaStudentProfileGalleryList(items: section.galleryItems, tint: tint)
        case .furniture:
            BaStudentProfileRowsView(rows: section.rows, tint: tint)
            BaStudentProfileFurnitureGalleryList(items: section.galleryItems, tint: tint)
        case .names, .info, .hobby:
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
    @Environment(BaAppModel.self) private var model

    let item: BaStudentProfileSameNameRoleItem
    let tint: Color

    var body: some View {
        if let entry = model.studentCatalogEntry(forSameNameRole: item) {
            NavigationLink {
                BaStudentDetailView(entry: entry)
            } label: {
                rowContent(accessory: .detail)
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityHint(String(localized: "ba.student.detail.profile.sameName.openDetail"))
        } else {
            rowContent(accessory: .none)
        }
    }

    private func rowContent(accessory: BaStudentSameNameRoleAccessory) -> some View {
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

                if accessory == .none {
                    Text(String(localized: "ba.student.detail.profile.sameName.linkUnavailable"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            accessoryView(accessory)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func accessoryView(_ accessory: BaStudentSameNameRoleAccessory) -> some View {
        switch accessory {
        case .detail:
            HStack(spacing: 5) {
                Text(String(localized: "ba.activity.link.archive"))
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .liquidGlassSurface(cornerRadius: 17, tint: tint.opacity(0.08), isInteractive: true)
        case .none:
            EmptyView()
        }
    }
}

private enum BaStudentSameNameRoleAccessory {
    case detail
    case none
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

private struct BaStudentProfileFurnitureGalleryList: View {
    let items: [BaGuideGalleryItem]
    let tint: Color

    @State private var selectedItem: BaGuideGalleryItem?

    var body: some View {
        if items.isEmpty == false {
            VStack(spacing: 12) {
                ForEach(items.prefix(8)) { item in
                    BaStudentProfileFurnitureMediaCard(
                        item: item,
                        tint: tint,
                        onPreview: { selectedItem = item }
                    )
                }
            }
            .sheet(item: $selectedItem) { item in
                BaStudentProfileFurniturePreviewSheet(item: item, tint: tint)
            }
        }
    }
}

private struct BaStudentProfileFurnitureMediaCard: View {
    let item: BaGuideGalleryItem
    let tint: Color
    let onPreview: () -> Void

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    private var previewURL: URL? {
        item.furniturePreviewURL
    }

    private var saveURL: URL? {
        item.furnitureSaveURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if item.detail.isBlank == false, item.detail != kind.title {
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)

                BaGuideMediaSaveButton(url: saveURL, title: item.title, tint: tint)
            }

            Button(action: onPreview) {
                BaStudentProfileFurnitureMediaSurface(url: previewURL, kind: kind, tint: tint, height: 218)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.title)
            .accessibilityHint(String(localized: "ba.student.detail.media.preview"))
        }
        .padding(10)
        .background(tint.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BaStudentProfileFurnitureMediaSurface: View {
    let url: URL?
    let kind: BaGuideMediaKind
    let tint: Color
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.04))

            BaRemoteAnimatedImageSurface(
                url: url,
                fallbackSystemImage: kind.systemImage,
                tint: tint,
                width: nil,
                height: height,
                cornerRadius: 14
            )
        }
        .frame(maxWidth: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct BaStudentProfileFurniturePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: BaGuideGalleryItem
    let tint: Color

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    BaStudentProfileFurnitureMediaSurface(
                        url: item.furniturePreviewURL,
                        kind: kind,
                        tint: tint,
                        height: 420
                    )

                    if item.note?.isBlank == false {
                        Text(item.note ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    BaGuideMediaSaveButton(url: item.furnitureSaveURL, title: item.title, tint: tint)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct BaGuideMediaSaveButton: View {
    @Environment(BaAppModel.self) private var model

    let url: URL?
    let title: String
    let tint: Color

    @State private var exportDocument = BaGuideMediaExportDocument()
    @State private var exportType: UTType = .data
    @State private var exportFilename = "BA_media.bin"
    @State private var isExporterPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            Task { await prepareExport() }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .font(.headline.weight(.semibold))
                }
            }
            .foregroundStyle(tint)
            .frame(width: 36, height: 34)
            .liquidGlassSurface(cornerRadius: 17, tint: tint.opacity(0.08), isInteractive: true)
        }
        .buttonStyle(.plain)
        .disabled(url == nil || isLoading)
        .accessibilityLabel(String(localized: "ba.action.save"))
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentType: exportType,
            defaultFilename: exportFilename
        ) { result in
            if case let .failure(error) = result {
                errorMessage = error.localizedDescription
            }
        }
        .alert(
            String(localized: "ba.student.detail.media.saveFailed"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "ba.common.done")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func prepareExport() async {
        guard let url else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await model.imageData(for: url)
            let metadata = BaGuideMediaExportBuilder.metadata(for: url, title: title)
            exportDocument = BaGuideMediaExportDocument(data: data)
            exportType = metadata.contentType
            exportFilename = metadata.fileName
            isExporterPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BaStudentProfileGalleryRow: View {
    let item: BaGuideGalleryItem
    let tint: Color

    private var kind: BaGuideMediaKind {
        item.mediaKind ?? .image
    }

    private var previewURL: URL? {
        item.imageURL ?? item.mediaURL
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            preview

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

    @ViewBuilder
    private var preview: some View {
        if previewURL?.baIsAnimatedImageURL == true {
            BaRemoteAnimatedImageSurface(
                url: previewURL,
                fallbackSystemImage: kind.systemImage,
                tint: tint,
                width: 72,
                height: 58,
                cornerRadius: 10
            )
        } else {
            BaRemoteIconSurface(
                url: previewURL,
                fallbackSystemImage: kind.systemImage,
                tint: tint,
                size: 58,
                width: 72,
                fallbackFont: .title3.weight(.semibold)
            )
        }
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

private extension BaGuideGalleryItem {
    var furniturePreviewURL: URL? {
        if mediaURL?.baIsAnimatedImageURL == true {
            return mediaURL
        }
        return imageURL ?? mediaURL
    }

    var furnitureSaveURL: URL? {
        if mediaURL?.baIsAnimatedImageURL == true {
            return mediaURL
        }
        return mediaURL ?? imageURL
    }
}

private extension URL {
    var baIsAnimatedImageURL: Bool {
        let lower = absoluteString.lowercased()
        return lower.range(of: #"\.gif(?:[?#].*)?$"#, options: .regularExpression) != nil ||
            lower.contains("format=gif") ||
            lower.contains("image/gif")
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
