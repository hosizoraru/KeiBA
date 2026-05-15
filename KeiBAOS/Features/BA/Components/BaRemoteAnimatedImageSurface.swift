//
//  BaRemoteAnimatedImageSurface.swift
//  KeiBAOS
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

    let url: URL?
    var fallbackSystemImage: String
    var tint: Color
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat

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
        .task(id: cacheTaskID) {
            await loadImage()
        }
        .onChange(of: model.settings.showPreviewImages) { _, _ in
            Task { await loadImage() }
        }
    }

    private var cacheTaskID: String {
        "\(url?.absoluteString ?? "nil")-\(model.settings.showPreviewImages)"
    }

    private func loadImage() async {
        guard model.settings.showPreviewImages, let url else {
            phase = model.settings.showPreviewImages ? .placeholder : .hidden
            return
        }
        phase = .loading
        guard let data = try? await model.imageData(for: url),
              let image = BaAnimatedImageDecoder.platformImage(from: data)
        else {
            phase = .failed
            return
        }
        phase = .success(image)
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
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentHuggingPriority(.defaultLow, for: .vertical)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            return view
        }

        func updateUIView(_ uiView: UIImageView, context: Context) {
            uiView.image = image
            if image.images?.isEmpty == false {
                uiView.startAnimating()
            }
        }
    }
#elseif canImport(AppKit)
    private typealias BaPlatformAnimatedImage = NSImage

    private final class BaFittingAnimatedImageView: NSImageView {
        override var intrinsicContentSize: NSSize {
            .zero
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
            nsView.image = image
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

private enum BaAnimatedImageDecoder {
    static func platformImage(from data: Data) -> BaPlatformAnimatedImage? {
        #if canImport(UIKit)
            if let animated = animatedUIImage(from: data) {
                return animated
            }
            return UIImage(data: data)
        #elseif canImport(AppKit)
            return NSImage(data: data)
        #else
            return nil
        #endif
    }

    #if canImport(UIKit)
        private static func animatedUIImage(from data: Data) -> UIImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return nil
            }
            let count = CGImageSourceGetCount(source)
            guard count > 1 else { return nil }

            var frames: [UIImage] = []
            var duration: TimeInterval = 0
            for index in 0 ..< count {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                    continue
                }
                frames.append(UIImage(cgImage: cgImage))
                duration += frameDuration(at: index, source: source)
            }
            guard frames.isEmpty == false else { return nil }
            return UIImage.animatedImage(with: frames, duration: max(duration, 0.1))
        }

        private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
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
    #endif
}
