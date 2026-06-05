//
//  BaRemoteAnimatedImageSurface.swift
//  KeiBA
//
//  Created by Codex on 2026/05/15.
//

import ImageIO
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct BaRemoteAnimatedImageSurface: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.baShowPreviewImages) private var showPreviewImages

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat
    var maxPixelDimension = 900

    @State private var phase: BaRemoteAnimatedImagePhase = .placeholder

    var body: some View {
        ZStack {
            switch phase {
            case let .success(image):
                BaPlatformAnimatedImageView(image: image)
            case .loading:
                ZStack {
                    fallbackIcon(systemImage: fallbackSystemImage, tint: tint.opacity(0.55))
                    ProgressView()
                        .controlSize(.small)
                }
            case .failed:
                fallbackIcon(systemImage: "photo.badge.exclamationmark", tint: .secondary)
            case .hidden:
                fallbackIcon(systemImage: fallbackSystemImage, tint: .secondary)
            case .placeholder:
                fallbackIcon(systemImage: fallbackSystemImage, tint: tint)
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
        .task(id: cacheTaskID) {
            await loadImage()
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(showPreviewImages)-\(maxPixelDimension)"
    }

    private func loadImage() async {
        guard showPreviewImages, let url else {
            phase = showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        do {
            let data = try await model.imageData(for: url)
            guard Task.isCancelled == false else { return }
            guard let image = await BaAnimatedImageDecodeWorker.decode(
                data: data,
                maxPixelDimension: maxPixelDimension
            ) else {
                if Task.isCancelled == false {
                    phase = .failed
                }
                return
            }
            guard Task.isCancelled == false else { return }
            phase = .success(image)
        } catch {
            if Task.isCancelled == false {
                phase = .failed
            }
        }
    }

    private func fallbackIcon(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(tint)
    }
}

#if canImport(UIKit)
    private typealias BaPlatformAnimatedImage = UIImage

    private final class BaFittingAnimatedImageView: UIImageView {
        override var intrinsicContentSize: CGSize {
            .zero
        }
    }

    private struct BaPlatformAnimatedImageView: UIViewRepresentable {
        let image: UIImage

        func makeUIView(context: Context) -> UIImageView {
            let view = BaFittingAnimatedImageView()
            view.contentMode = .scaleAspectFit
            view.clipsToBounds = true
            view.isUserInteractionEnabled = false
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentHuggingPriority(.defaultLow, for: .vertical)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            return view
        }

        func updateUIView(_ uiView: UIImageView, context: Context) {
            if uiView.image !== image {
                uiView.image = image
            }
            if image.images?.isEmpty == false {
                if uiView.isAnimating == false {
                    uiView.startAnimating()
                }
            } else {
                uiView.stopAnimating()
            }
        }

        static func dismantleUIView(_ uiView: UIImageView, coordinator: ()) {
            uiView.stopAnimating()
            uiView.image = nil
        }
    }
#elseif canImport(AppKit)
    private typealias BaPlatformAnimatedImage = NSImage

    private final class BaFittingAnimatedImageView: NSImageView {
        override var intrinsicContentSize: NSSize {
            .zero
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }

    private struct BaPlatformAnimatedImageView: NSViewRepresentable {
        let image: NSImage

        func makeNSView(context: Context) -> NSImageView {
            let view = BaFittingAnimatedImageView()
            view.imageScaling = .scaleProportionallyUpOrDown
            view.animates = true
            return view
        }

        func updateNSView(_ nsView: NSImageView, context: Context) {
            if nsView.image !== image {
                nsView.image = image
            }
        }

        static func dismantleNSView(_ nsView: NSImageView, coordinator: ()) {
            nsView.animates = false
            nsView.image = nil
        }
    }
#endif

private enum BaRemoteAnimatedImagePhase {
    case placeholder
    case loading
    case failed
    case hidden
    case success(BaPlatformAnimatedImage)
}

private enum BaAnimatedImageDecodeWorker {
    nonisolated static func decode(data: Data, maxPixelDimension: Int) async -> BaPlatformAnimatedImage? {
        await Task.detached(priority: .utility) {
            BaAnimatedImageDecoder.platformImage(
                from: data,
                maxPixelDimension: max(maxPixelDimension, 1)
            )
        }.value
    }
}

private enum BaAnimatedImageDecoder {
    nonisolated static func platformImage(from data: Data, maxPixelDimension: Int) -> BaPlatformAnimatedImage? {
        #if canImport(UIKit)
            if let animated = animatedUIImage(from: data, maxPixelDimension: maxPixelDimension) {
                return animated
            }
            return staticUIImage(from: data, maxPixelDimension: maxPixelDimension)
        #elseif canImport(AppKit)
            return staticNSImage(from: data, maxPixelDimension: maxPixelDimension)
        #else
            return nil
        #endif
    }

    #if canImport(UIKit)
        nonisolated private static func animatedUIImage(from data: Data, maxPixelDimension: Int) -> UIImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return nil
            }
            let count = CGImageSourceGetCount(source)
            guard count > 1 else { return nil }

            var frames: [UIImage] = []
            var duration: TimeInterval = 0
            for index in 0 ..< count {
                guard let cgImage = thumbnailImage(
                    at: index,
                    source: source,
                    maxPixelDimension: maxPixelDimension
                ) else {
                    continue
                }
                frames.append(UIImage(cgImage: cgImage))
                duration += frameDuration(at: index, source: source)
            }
            guard frames.isEmpty == false else { return nil }
            return UIImage.animatedImage(with: frames, duration: max(duration, 0.1))
        }

        nonisolated private static func staticUIImage(from data: Data, maxPixelDimension: Int) -> UIImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = thumbnailImage(at: 0, source: source, maxPixelDimension: maxPixelDimension)
            else {
                return UIImage(data: data)
            }
            return UIImage(cgImage: cgImage)
        }

        nonisolated private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
                  let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            else {
                return 0.1
            }
            let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
            let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber
            let delay = unclamped?.doubleValue ?? clamped?.doubleValue ?? 0.1
            return delay < 0.02 ? 0.1 : delay
        }
    #elseif canImport(AppKit)
        nonisolated private static func staticNSImage(from data: Data, maxPixelDimension: Int) -> NSImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = thumbnailImage(at: 0, source: source, maxPixelDimension: maxPixelDimension)
            else {
                return NSImage(data: data)
            }
            return NSImage(cgImage: cgImage, size: .zero)
        }
    #endif

    nonisolated private static func thumbnailImage(
        at index: Int,
        source: CGImageSource,
        maxPixelDimension: Int
    ) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, index, nil)
    }
}
