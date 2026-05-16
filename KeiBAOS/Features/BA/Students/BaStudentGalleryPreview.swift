//
//  BaStudentGalleryPreview.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/16.
//

import SwiftUI

struct BaStudentGalleryPreviewItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let previewURL: URL?
    let mediaURL: URL?
    let kind: BaGuideMediaKind

    init(item: BaGuideGalleryItem) {
        kind = item.mediaKind ?? .image
        title = item.title
        detail = item.galleryDisplayDetail
        previewURL = item.imageURL ?? item.mediaURL
        mediaURL = item.mediaURL ?? item.imageURL
        id = "\(kind.rawValue)|\(mediaURL?.absoluteString ?? previewURL?.absoluteString ?? item.id)"
    }

    init(title: String, detail: String, previewURL: URL?, mediaURL: URL?, kind: BaGuideMediaKind) {
        self.title = title
        self.detail = detail
        self.previewURL = previewURL
        self.mediaURL = mediaURL
        self.kind = kind
        id = "\(kind.rawValue)|\(mediaURL?.absoluteString ?? previewURL?.absoluteString ?? title)"
    }
}

struct BaStudentGalleryPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BaStudentGalleryPreviewItem

    var body: some View {
        let galleryItem = BaGuideGalleryItem(
            id: item.id,
            title: item.title,
            detail: item.detail,
            imageURL: item.previewURL,
            mediaURL: item.mediaURL,
            mediaKind: item.kind
        )
        let presentation = BaStudentGalleryCardPresentation(item: galleryItem)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch item.kind {
                    case .video:
                        BaStudentGalleryPreviewMediaSurface(presentation: presentation)
                    case .audio:
                        BaStudentGalleryAudioCard(item: galleryItem)
                    case .image, .live2d, .unknown:
                        BaStudentGalleryPreviewMediaSurface(presentation: presentation)
                    }

                    if item.detail.baGalleryIsBlank == false {
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
            }
            .navigationTitle(item.title)
            .platformInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "ba.common.done")) {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if let shareURL = item.mediaURL ?? item.previewURL {
                        ShareLink(item: shareURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(String(localized: "ba.action.share"))
                    }

                    BaGalleryMediaSaveButton(url: item.mediaURL ?? item.previewURL, title: item.title)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
