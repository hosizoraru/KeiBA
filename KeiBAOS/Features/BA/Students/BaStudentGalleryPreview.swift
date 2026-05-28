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
    let item: BaStudentGalleryPreviewItem

    var body: some View {
        BaPlatformMediaPreviewSheet(
            request: BaPlatformMediaPreviewRequest(
                id: item.id,
                title: item.title,
                detail: item.detail,
                sourceURL: item.mediaURL ?? item.previewURL,
                kind: item.kind
            )
        )
    }
}
