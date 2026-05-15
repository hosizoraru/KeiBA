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
    private let displaySections: [BaStudentProfileSection]

    init(info: BaStudentGuideInfo, tint: Color) {
        self.tint = tint
        let sections = info.profileSections
        let hasContent = sections.contains { $0.isEmpty == false }
        displaySections = hasContent ? sections : []
    }

    var body: some View {
        Section {
            if displaySections.isEmpty {
                BaStudentDetailEmptyRow(section: .profile)
                    .baStudentDetailListCardRow()
            } else {
                ForEach(displaySections) { section in
                    if section.kind == .furniture {
                        BaStudentProfileFurnitureSectionRows(section: section, tint: tint)
                    } else {
                        BaStudentProfileSectionCard(section: section, tint: tint)
                            .baStudentDetailListCardRow()
                    }
                }
            }
        }
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
    @Environment(BaAppModel.self) private var model

    let section: BaStudentProfileSection
    let tint: Color

    @State private var selectedEntry: BaGuideCatalogEntry?

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
                    BaStudentSameNameRoleRow(
                        item: item,
                        entry: model.studentCatalogEntry(forSameNameRole: item),
                        tint: tint,
                        onOpen: { selectedEntry = $0 }
                    )
                }
            }
        }
        .navigationDestination(item: $selectedEntry) { entry in
            BaStudentDetailView(entry: entry)
        }
    }
}

private struct BaStudentSameNameRoleRow: View {
    let item: BaStudentProfileSameNameRoleItem
    let entry: BaGuideCatalogEntry?
    let tint: Color
    let onOpen: (BaGuideCatalogEntry) -> Void

    var body: some View {
        Group {
            if let entry {
                Button {
                    onOpen(entry)
                } label: {
                    rowContent(isLinked: true)
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "ba.student.detail.profile.sameName.openDetail"))
            } else {
                rowContent(isLinked: false)
            }
        }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func rowContent(isLinked: Bool) -> some View {
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

                if isLinked == false {
                    Text(String(localized: "ba.student.detail.profile.sameName.linkUnavailable"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if isLinked {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 3)
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

private struct BaStudentProfileFurnitureSectionRows: View {
    let section: BaStudentProfileSection
    let tint: Color

    private var furnitureItems: [BaGuideGalleryItem] {
        Array(section.galleryItems.prefix(8))
    }

    var body: some View {
        if section.rows.isEmpty == false {
            BaStudentProfileFurnitureInfoCard(section: section, tint: tint)
                .baStudentDetailListCardRow()
        }

        ForEach(Array(furnitureItems.enumerated()), id: \.element.id) { index, item in
            BaStudentProfileFurnitureRowCard(
                item: item,
                tint: tint,
                showsSectionTitle: index == 0 && section.rows.isEmpty
            )
            .equatable()
            .baStudentDetailListCardRow()
        }
    }
}

private struct BaStudentProfileFurnitureInfoCard: View {
    let section: BaStudentProfileSection
    let tint: Color

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                BaStudentProfileCardTitle(section: section, tint: tint)
                BaStudentProfileRowsView(rows: section.rows, tint: tint)
            }
        }
    }
}

private struct BaStudentProfileFurnitureRowCard: View, Equatable {
    let item: BaGuideGalleryItem
    let tint: Color
    let showsSectionTitle: Bool

    @State private var selectedItem: BaGuideGalleryItem?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item == rhs.item && lhs.showsSectionTitle == rhs.showsSectionTitle
    }

    var body: some View {
        BaGlassCard(tint: tint) {
            VStack(alignment: .leading, spacing: 14) {
                if showsSectionTitle {
                    BaStudentProfileCardTitle(
                        section: BaStudentProfileSection(kind: .furniture),
                        tint: tint
                    )
                }

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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BaStudentProfileFurnitureTitleRow(item: item, kind: kind, tint: tint)

            Button(action: onPreview) {
                BaStudentProfileFurnitureMediaSurface(
                    url: previewURL,
                    kind: kind,
                    tint: tint,
                    height: item.furniturePreviewHeight,
                    showsBackdrop: item.isAnimatedFurniturePreview == false,
                    maxPixelDimension: item.furnitureInlineMaxPixelDimension
                )
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityLabel(item.furnitureDisplayTitle)
            .accessibilityHint(String(localized: "ba.student.detail.media.preview"))
        }
    }
}

private struct BaStudentProfileFurnitureTitleRow: View {
    let item: BaGuideGalleryItem
    let kind: BaGuideMediaKind
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Label(String(localized: "ba.student.detail.profile.furniture.badge"), systemImage: "chair.lounge")
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(tint)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(tint.opacity(0.08), in: Capsule())

            Text(item.furnitureDisplayTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)
        }

        let detailLine = item.furnitureDetailLine(kind: kind)
        if detailLine.isBlank == false {
            Text(detailLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

private struct BaStudentProfileFurnitureMediaSurface: View {
    let url: URL?
    let kind: BaGuideMediaKind
    let tint: Color
    let height: CGFloat
    var showsBackdrop = true
    var maxPixelDimension = 900

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.001))

            if showsBackdrop {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.black.opacity(0.04))
            }

            BaRemoteAnimatedImageSurface(
                url: url,
                fallbackSystemImage: kind.systemImage,
                tint: tint,
                width: nil,
                height: height,
                cornerRadius: 14,
                maxPixelDimension: maxPixelDimension
            )
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .overlay {
            if showsBackdrop {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                        height: 420,
                        showsBackdrop: item.isAnimatedFurniturePreview == false,
                        maxPixelDimension: item.furniturePreviewMaxPixelDimension
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
            .navigationTitle(item.furnitureDisplayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    BaGuideMediaSaveButton(url: item.furnitureSaveURL, title: item.furnitureDisplayTitle)
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
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label(String(localized: "ba.action.save"), systemImage: "square.and.arrow.down")
                    .labelStyle(.iconOnly)
            }
        }
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
    var furnitureDisplayTitle: String {
        Self.furnitureDisplayTitle(from: title)
    }

    var furniturePreviewHeight: CGFloat {
        isAnimatedFurniturePreview ? 206 : 156
    }

    var furnitureInlineMaxPixelDimension: Int {
        isAnimatedFurniturePreview ? 960 : 720
    }

    var furniturePreviewMaxPixelDimension: Int {
        isAnimatedFurniturePreview ? 1400 : 1100
    }

    var furniturePreviewURL: URL? {
        if isAnimatedFurniturePreview, let mediaURL {
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

    var isAnimatedFurniturePreview: Bool {
        if furnitureSaveURL?.baIsAnimatedImageURL == true {
            return true
        }
        let tokens = title.regexNumberTokens
        if tokens.count >= 2 {
            return tokens.last == "2"
        }
        if tokens.count == 1, let token = tokens.first, token.count >= 2 {
            return token.hasSuffix("2")
        }
        return false
    }

    func furnitureDetailLine(kind: BaGuideMediaKind) -> String {
        let value = detail.trimmed
        guard value.isBlank == false else { return "" }
        if value == kind.title || value == title || value == furnitureDisplayTitle {
            return ""
        }
        return value
    }

    private static func furnitureDisplayTitle(from raw: String) -> String {
        let value = raw.trimmed
        if let match = value.firstRegexCaptureGroups(pattern: #"^互动家具\s*(\d)(\d)$"#),
           match.count == 2
        {
            return localizedFurnitureTitle(number: "\(match[0])-\(match[1])")
        }
        if let match = value.firstRegexCaptureGroups(pattern: #"^互动家具\s*(\d+)$"#),
           let number = match.first
        {
            return localizedFurnitureTitle(number: number)
        }
        return value.ifBlank(String(localized: "ba.student.detail.profile.furniture.title"))
    }

    private static func localizedFurnitureTitle(number: String) -> String {
        String(format: String(localized: "ba.student.detail.profile.furniture.item.format"), number)
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
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }

    func ifBlank(_ fallback: String) -> String {
        isBlank ? fallback : self
    }

    var regexNumberTokens: [String] {
        guard let regex = try? NSRegularExpression(pattern: #"\d+"#) else { return [] }
        let range = NSRange(startIndex ..< endIndex, in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }
            return String(self[range])
        }
    }

    func firstRegexCaptureGroups(pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(startIndex ..< endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range), match.numberOfRanges > 1 else { return nil }
        return (1 ..< match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: self) else { return nil }
            return String(self[range])
        }
    }
}
