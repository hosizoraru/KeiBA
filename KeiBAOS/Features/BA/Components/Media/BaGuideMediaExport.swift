//
//  BaGuideMediaExport.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/15.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
    import AppKit
#endif

struct BaGuideMediaExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.data]
    }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BaGuideMediaSaveAction<Label: View>: View {
    let url: URL?
    let title: String
    let prefix: String
    private let dataLoader: @MainActor (URL) async throws -> Data
    private let label: (Bool, Bool) -> Label

    @State private var exportDocument = BaGuideMediaExportDocument()
    @State private var exportType: UTType = .data
    @State private var exportFilename = "BA_media.bin"
    @State private var isExporterPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    #if os(macOS)
        @State private var hostWindow: NSWindow?
        @State private var isSavePanelPresented = false
    #endif

    init(
        url: URL?,
        title: String,
        prefix: String = "",
        dataLoader: @MainActor @escaping (URL) async throws -> Data = { url in
            try await BaGuideMediaCache.shared.data(for: url)
        },
        @ViewBuilder label: @escaping (Bool, Bool) -> Label
    ) {
        self.url = url
        self.title = title
        self.prefix = prefix
        self.dataLoader = dataLoader
        self.label = label
    }

    var body: some View {
        Button {
            Task { await prepareExport() }
        } label: {
            label(isLoading, isButtonEnabled)
        }
        .disabled(isButtonEnabled == false)
        .accessibilityLabel(BaL10n.string("ba.action.save"))
        #if os(macOS)
            .background(BaMediaExportWindowAccessor(window: $hostWindow).frame(width: 0, height: 0))
        #else
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
        #endif
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

    private var isButtonEnabled: Bool {
        #if os(macOS)
            url != nil && isLoading == false && isSavePanelPresented == false
        #else
            url != nil && isLoading == false
        #endif
    }

    @MainActor
    private func prepareExport() async {
        guard let url else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await dataLoader(url)
            let metadata = BaGuideMediaExportBuilder.metadata(for: url, title: title, prefix: prefix)
            #if os(macOS)
                presentAppKitSavePanel(data: data, metadata: metadata)
            #else
                exportDocument = BaGuideMediaExportDocument(data: data)
                exportType = metadata.contentType
                exportFilename = metadata.fileName
                isExporterPresented = true
            #endif
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    #if os(macOS)
        @MainActor
        private func presentAppKitSavePanel(data: Data, metadata: BaGuideMediaExportMetadata) {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = metadata.fileName
            panel.allowedContentTypes = [metadata.contentType]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            isSavePanelPresented = true

            if let hostWindow {
                panel.beginSheetModal(for: hostWindow) { response in
                    Task { @MainActor in
                        finishAppKitSavePanel(response: response, panel: panel, data: data)
                    }
                }
            } else {
                finishAppKitSavePanel(response: panel.runModal(), panel: panel, data: data)
            }
        }

        @MainActor
        private func finishAppKitSavePanel(
            response: NSApplication.ModalResponse,
            panel: NSSavePanel,
            data: Data
        ) {
            isSavePanelPresented = false
            guard response == .OK, let destinationURL = panel.url else { return }
            Task(priority: .utility) {
                do {
                    try data.write(to: destinationURL, options: [.atomic])
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    #endif
}

nonisolated struct BaGuideMediaExportMetadata: Hashable {
    let fileName: String
    let contentType: UTType
}

nonisolated enum BaGuideMediaExportBuilder {
    // Compiled-once regex caches. Filename sanitization runs once per
    // export request, but exports are often issued in bulk (gallery
    // multi-save) so caching avoids per-item regex compilation.
    fileprivate nonisolated static let forbiddenCharRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"[\\/:*?"<>|]"#)
    }()
    fileprivate nonisolated static let whitespaceRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\s+"#)
    }()

    static func metadata(for url: URL, title: String, prefix: String = "") -> BaGuideMediaExportMetadata {
        let ext = mediaExtension(for: url, title: title)
        let baseTitle = sanitizeTitle(title).ifBlank("BA_media")
        let cleanPrefix = sanitizeToken(prefix)
        let combinedTitle: String
        if cleanPrefix.isEmpty || cleanPrefix == "学生图鉴" {
            combinedTitle = baseTitle
        } else if baseTitle.hasPrefix(cleanPrefix) {
            combinedTitle = baseTitle
        } else {
            combinedTitle = sanitizeTitle("\(cleanPrefix)_\(baseTitle)")
        }
        let fileName = combinedTitle.lowercased().hasSuffix(".\(ext)") ? combinedTitle : "\(combinedTitle).\(ext)"
        return BaGuideMediaExportMetadata(
            fileName: fileName,
            contentType: UTType(filenameExtension: ext) ?? .data
        )
    }

    private static func mediaExtension(for url: URL, title: String) -> String {
        let ext = url.pathExtension.lowercased()
        if knownMediaExtensions.contains(ext) {
            return ext
        }
        let source = url.absoluteString.lowercased()
        let title = title.lowercased()
        if source.contains("image/gif") || source.contains("format=gif") {
            return "gif"
        }
        if source.contains("audio") || title.contains("bgm") || title.contains("音频") {
            return "ogg"
        }
        if source.contains("video") || title.contains("视频") {
            return "mp4"
        }
        return "bin"
    }

    private static func sanitizeTitle(_ raw: String) -> String {
        sanitize(raw, prefixLimit: 96)
    }

    private static func sanitizeToken(_ raw: String) -> String {
        sanitize(raw, prefixLimit: 48)
    }

    private static func sanitize(_ raw: String, prefixLimit: Int) -> String {
        let stripped: String
        if let regex = forbiddenCharRegex {
            let range = NSRange(raw.startIndex ..< raw.endIndex, in: raw)
            stripped = regex.stringByReplacingMatches(in: raw, range: range, withTemplate: " ")
        } else {
            stripped = raw.replacingOccurrences(of: #"[\\/:*?"<>|]"#, with: " ", options: .regularExpression)
        }
        let collapsed: String
        if let regex = whitespaceRegex {
            let range = NSRange(stripped.startIndex ..< stripped.endIndex, in: stripped)
            collapsed = regex.stringByReplacingMatches(in: stripped, range: range, withTemplate: " ")
        } else {
            collapsed = stripped.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }
        return collapsed
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(prefixLimit)
            .description
    }

    private static let knownMediaExtensions = Set([
        "jpg", "jpeg", "png", "webp", "gif", "bmp",
        "mp4", "webm", "mkv", "mov", "m3u8",
        "ogg", "mp3", "wav", "flac", "aac", "m4a",
    ])
}

private extension String {
    nonisolated func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

#if os(macOS)
    private struct BaMediaExportWindowAccessor: NSViewRepresentable {
        @Binding var window: NSWindow?

        func makeNSView(context _: Context) -> NSView {
            let view = NSView(frame: .zero)
            updateWindow(from: view)
            return view
        }

        func updateNSView(_ nsView: NSView, context _: Context) {
            updateWindow(from: nsView)
        }

        private func updateWindow(from view: NSView) {
            DispatchQueue.main.async {
                window = view.window
            }
        }
    }
#endif
