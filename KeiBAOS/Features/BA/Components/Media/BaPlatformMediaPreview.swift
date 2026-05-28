//
//  BaPlatformMediaPreview.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/28.
//

import SwiftUI
import UniformTypeIdentifiers

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
                    Text(request.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                }
            }
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
        #endif
        .task(id: request.id) {
            await loadPreviewFile()
        }
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
        #if canImport(UIKit) || canImport(QuickLookUI)
            BaPlatformQuickLookPreview(fileURL: fileURL, title: title)
                .ignoresSafeArea(edges: .bottom)
        #else
            BaZoomableLocalMediaView(fileURL: fileURL, kind: kind)
        #endif
    }
}

private struct BaPlatformMediaSaveButton: View {
    let url: URL?
    let title: String

    @State private var exportDocument = BaGuideMediaExportDocument()
    @State private var exportType = UTType.data
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
                Image(systemName: "square.and.arrow.down")
            }
        }
        .disabled(url == nil || isLoading)
        .accessibilityLabel(BaL10n.string("ba.action.save"))
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
            BaL10n.string("ba.student.detail.media.saveFailed"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )
        ) {
            Button(BaL10n.string("ba.common.done")) {
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
            let data = try await BaGuideMediaCache.shared.data(for: url)
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
            } else {
                Image(systemName: kind.systemImage)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.secondary)
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

            return scrollView
        }

        func updateUIView(_ scrollView: UIScrollView, context: Context) {
            context.coordinator.imageView?.image = image
            scrollView.zoomScale = max(scrollView.minimumZoomScale, min(scrollView.zoomScale, scrollView.maximumZoomScale))
        }

        final class Coordinator: NSObject, UIScrollViewDelegate {
            weak var imageView: UIImageView?

            func viewForZooming(in _: UIScrollView) -> UIView? {
                imageView
            }
        }
    }
#elseif canImport(AppKit)
    private typealias BaPlatformPreviewImage = NSImage

    private struct BaPlatformZoomableImageView: NSViewRepresentable {
        let image: NSImage

        func makeNSView(context _: Context) -> NSScrollView {
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
            return scrollView
        }

        func updateNSView(_ nsView: NSScrollView, context _: Context) {
            (nsView.documentView as? NSImageView)?.image = image
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
