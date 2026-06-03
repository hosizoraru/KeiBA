//
//  BaPlatformMediaPreview.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/28.
//

import SwiftUI

#if canImport(QuickLook)
    import QuickLook
#endif

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    #if canImport(QuickLookUI)
        import QuickLookUI
    #endif
#endif

struct BaPlatformMediaPreviewRequest: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let sourceURL: URL?
    let kind: BaGuideMediaKind

    init(
        id: String,
        title: String,
        detail: String = "",
        sourceURL: URL?,
        kind: BaGuideMediaKind
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.sourceURL = sourceURL
        self.kind = kind
    }
}

enum BaPlatformMediaPreviewRenderer: Hashable {
    case quickLook
    case zoomableImage
    case iconFallback
}

enum BaPlatformMediaPreviewPolicy {
    nonisolated static func renderer(
        for kind: BaGuideMediaKind,
        fileURL: URL,
        isQuickLookAvailable: Bool
    ) -> BaPlatformMediaPreviewRenderer {
        if isQuickLookAvailable {
            return .quickLook
        }

        if kind == .image || fileURL.baPlatformPreviewIsImageLike {
            return .zoomableImage
        }

        return .iconFallback
    }
}

struct BaPlatformMediaPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let request: BaPlatformMediaPreviewRequest

    @State private var localURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                previewContent

                if request.detail.baGalleryIsBlank == false {
                    mediaDetailBar
                }
            }
            .background(AppBackground())
            .navigationTitle(request.title)
            .platformInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BaL10n.string("ba.common.done")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    if let shareURL = localURL ?? request.sourceURL {
                        ShareLink(item: shareURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(BaL10n.string("ba.action.share"))
                    }

                    BaPlatformMediaSaveButton(url: request.sourceURL, title: request.title)
                }
            }
        }
        #if os(iOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
        #endif
        .task(id: request.id) {
            await loadPreviewFile()
        }
    }

    private var mediaDetailBar: some View {
        Text(request.detail)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .liquidGlassSurface(cornerRadius: 18, tint: .white.opacity(0.055), isInteractive: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    @ViewBuilder
    private var previewContent: some View {
        if let localURL {
            BaPlatformMediaPreviewContent(
                fileURL: localURL,
                title: request.title,
                kind: request.kind
            )
        } else if isLoading {
            ProgressView()
                .accessibilityLabel(BaL10n.string("ba.student.detail.media.previewLoading"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                BaL10n.string("ba.student.detail.media.previewFailed"),
                systemImage: "photo.badge.exclamationmark",
                description: Text(errorMessage ?? "")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @MainActor
    private func loadPreviewFile() async {
        localURL = nil
        errorMessage = nil
        guard let sourceURL = request.sourceURL else {
            errorMessage = BaL10n.string("ba.student.detail.media.previewFailed")
            return
        }

        if sourceURL.isFileURL {
            localURL = sourceURL
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            localURL = try await BaGuideMediaCache.shared.localURL(for: sourceURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BaPlatformMediaPreviewContent: View {
    let fileURL: URL
    let title: String
    let kind: BaGuideMediaKind

    var body: some View {
        switch BaPlatformMediaPreviewPolicy.renderer(
            for: kind,
            fileURL: fileURL,
            isQuickLookAvailable: Self.isQuickLookAvailable
        ) {
        case .quickLook:
            #if canImport(UIKit) || canImport(QuickLookUI)
                BaPlatformQuickLookPreview(fileURL: fileURL, title: title)
                    .ignoresSafeArea(edges: .bottom)
            #else
                BaZoomableLocalMediaView(fileURL: fileURL, kind: kind)
            #endif
        case .zoomableImage:
            BaZoomableLocalMediaView(fileURL: fileURL, kind: kind)
        case .iconFallback:
            Image(systemName: kind.systemImage)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text(kind.title))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private static var isQuickLookAvailable: Bool {
        #if canImport(UIKit) || canImport(QuickLookUI)
            true
        #else
            false
        #endif
    }
}

private struct BaPlatformMediaSaveButton: View {
    let url: URL?
    let title: String

    var body: some View {
        BaGuideMediaSaveAction(url: url, title: title) { isLoading, _ in
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "square.and.arrow.down")
            }
        }
    }
}

#if canImport(QuickLook)
    private final class BaQuickLookPreviewItem: NSObject, QLPreviewItem {
        let fileURL: URL
        let title: String

        init(fileURL: URL, title: String) {
            self.fileURL = fileURL
            self.title = title
        }

        var previewItemURL: URL? {
            fileURL
        }

        var previewItemTitle: String? {
            title
        }
    }
#endif

#if canImport(UIKit)
    private struct BaPlatformQuickLookPreview: UIViewControllerRepresentable {
        let fileURL: URL
        let title: String

        func makeCoordinator() -> Coordinator {
            Coordinator(fileURL: fileURL, title: title)
        }

        func makeUIViewController(context: Context) -> QLPreviewController {
            let controller = QLPreviewController()
            controller.dataSource = context.coordinator
            controller.currentPreviewItemIndex = 0
            return controller
        }

        func updateUIViewController(_ controller: QLPreviewController, context: Context) {
            context.coordinator.update(fileURL: fileURL, title: title)
            controller.reloadData()
        }

        static func dismantleUIViewController(_ controller: QLPreviewController, coordinator: Coordinator) {
            controller.dataSource = nil
        }

        final class Coordinator: NSObject, QLPreviewControllerDataSource {
            private var item: BaQuickLookPreviewItem

            init(fileURL: URL, title: String) {
                item = BaQuickLookPreviewItem(fileURL: fileURL, title: title)
            }

            func update(fileURL: URL, title: String) {
                guard item.fileURL != fileURL || item.title != title else { return }
                item = BaQuickLookPreviewItem(fileURL: fileURL, title: title)
            }

            func numberOfPreviewItems(in _: QLPreviewController) -> Int {
                1
            }

            func previewController(_: QLPreviewController, previewItemAt _: Int) -> any QLPreviewItem {
                item
            }
        }
    }
#elseif canImport(AppKit) && canImport(QuickLookUI)
    private struct BaPlatformQuickLookPreview: NSViewRepresentable {
        let fileURL: URL
        let title: String

        func makeNSView(context _: Context) -> QLPreviewView {
            let view = QLPreviewView(frame: .zero, style: .normal)!
            view.autostarts = true
            view.previewItem = BaQuickLookPreviewItem(fileURL: fileURL, title: title)
            return view
        }

        func updateNSView(_ nsView: QLPreviewView, context _: Context) {
            nsView.previewItem = BaQuickLookPreviewItem(fileURL: fileURL, title: title)
            nsView.refreshPreviewItem()
        }

        static func dismantleNSView(_ nsView: QLPreviewView, coordinator: Coordinator) {
            nsView.previewItem = nil
        }
    }
#endif

private struct BaZoomableLocalMediaView: View {
    let fileURL: URL
    let kind: BaGuideMediaKind

    @State private var image: BaPlatformPreviewImage?

    var body: some View {
        Group {
            if let image {
                BaPlatformZoomableImageView(image: image)
                    .accessibilityLabel(Text(kind.title))
                    .accessibilityHint(Text("ba.media.zoomable.hint"))
            } else {
                Image(systemName: kind.systemImage)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text(kind.title))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: fileURL) {
            image = await BaPlatformPreviewImageLoader.image(from: fileURL)
        }
    }
}

#if canImport(UIKit)
    private typealias BaPlatformPreviewImage = UIImage

    private struct BaPlatformZoomableImageView: UIViewRepresentable {
        let image: UIImage

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 5
            scrollView.bouncesZoom = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false

            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(imageView)
            context.coordinator.imageView = imageView

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            ])

            let doubleTap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleDoubleTap(_:))
            )
            doubleTap.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTap)
            context.coordinator.scrollView = scrollView

            return scrollView
        }

        func updateUIView(_ scrollView: UIScrollView, context: Context) {
            context.coordinator.imageView?.image = image
            context.coordinator.scrollView = scrollView
            scrollView.zoomScale = max(scrollView.minimumZoomScale, min(scrollView.zoomScale, scrollView.maximumZoomScale))
        }

        static func dismantleUIView(_ scrollView: UIScrollView, coordinator: Coordinator) {
            scrollView.delegate = nil
            coordinator.imageView?.image = nil
        }

        final class Coordinator: NSObject, UIScrollViewDelegate {
            weak var imageView: UIImageView?
            weak var scrollView: UIScrollView?

            func viewForZooming(in _: UIScrollView) -> UIView? {
                imageView
            }

            @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
                guard let scrollView else { return }
                if scrollView.zoomScale > scrollView.minimumZoomScale {
                    scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                    return
                }

                let point = recognizer.location(in: imageView)
                let targetScale = min(scrollView.maximumZoomScale, max(2.5, scrollView.minimumZoomScale * 2.5))
                let width = scrollView.bounds.width / targetScale
                let height = scrollView.bounds.height / targetScale
                let rect = CGRect(
                    x: point.x - width / 2,
                    y: point.y - height / 2,
                    width: width,
                    height: height
                )
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
#elseif canImport(AppKit)
    private typealias BaPlatformPreviewImage = NSImage

    private struct BaPlatformZoomableImageView: NSViewRepresentable {
        let image: NSImage

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.allowsMagnification = true
            scrollView.minMagnification = 1
            scrollView.maxMagnification = 5
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = true

            let imageView = NSImageView()
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.image = image
            scrollView.documentView = imageView
            context.coordinator.scrollView = scrollView

            let doubleClick = NSClickGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleDoubleClick(_:))
            )
            doubleClick.numberOfClicksRequired = 2
            imageView.addGestureRecognizer(doubleClick)
            return scrollView
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.scrollView = nsView
            (nsView.documentView as? NSImageView)?.image = image
        }

        static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
            (nsView.documentView as? NSImageView)?.image = nil
        }

        final class Coordinator: NSObject {
            weak var scrollView: NSScrollView?

            @objc func handleDoubleClick(_: NSClickGestureRecognizer) {
                guard let scrollView else { return }
                let target = scrollView.magnification > scrollView.minMagnification
                    ? scrollView.minMagnification
                    : min(scrollView.maxMagnification, max(2.5, scrollView.minMagnification * 2.5))
                scrollView.animator().setMagnification(target, centeredAt: scrollView.contentView.bounds.center)
            }
        }
    }
#endif

private enum BaPlatformPreviewImageLoader {
    nonisolated static func image(from url: URL) async -> BaPlatformPreviewImage? {
        await Task.detached(priority: .utility) {
            #if canImport(UIKit)
                return UIImage(contentsOfFile: url.path)
            #elseif canImport(AppKit)
                return NSImage(contentsOf: url)
            #else
                return nil
            #endif
        }.value
    }
}

private extension URL {
    nonisolated var baPlatformPreviewIsImageLike: Bool {
        let value = pathExtension.lowercased()
        return ["apng", "gif", "heic", "heif", "jpeg", "jpg", "png", "tiff", "webp"].contains(value)
    }
}

#if canImport(AppKit)
    private extension CGRect {
        var center: CGPoint {
            CGPoint(x: midX, y: midY)
        }
    }
#endif
