//
//  BaMusicAccentPalette.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/17.
//

import CoreImage
import SwiftUI

enum BaMusicAccentPalette {
    static let fallback = Color.accentColor

    #if DEBUG
        static func rgbValuesForTesting(from data: Data) async -> [Double]? {
            guard let url = URL(string: "keibaos://music-accent-test/\(data.count)") else { return nil }
            return await BaMusicAvatarAccentSampler.shared.accentColor(for: url, data: data)?.rgbValues
        }
    #endif
}

struct BaMusicAccentReader<Content: View>: View {
    @Environment(BaAppModel.self) private var model

    let track: BaMusicTrack?
    @ViewBuilder var content: (Color) -> Content

    @State private var accent = BaMusicAccentPalette.fallback

    var body: some View {
        content(accent)
            .task(id: taskID) {
                await resolveAccent()
            }
    }

    private var taskID: String {
        track?.artworkURL?.absoluteString ?? "nil"
    }

    @MainActor
    private func resolveAccent() async {
        guard let url = track?.artworkURL else {
            accent = BaMusicAccentPalette.fallback
            return
        }
        do {
            let data = try await model.imageData(for: url)
            guard Task.isCancelled == false else { return }
            let sampled = await BaMusicAvatarAccentSampler.shared.accentColor(for: url, data: data)
            guard Task.isCancelled == false else { return }
            accent = sampled?.color ?? BaMusicAccentPalette.fallback
        } catch {
            guard Task.isCancelled == false else { return }
            accent = BaMusicAccentPalette.fallback
        }
    }
}

private actor BaMusicAvatarAccentSampler {
    static let shared = BaMusicAvatarAccentSampler()

    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
    ])
    private var cache: [URL: BaMusicAccentRGBA] = [:]

    func accentColor(for url: URL, data: Data) -> BaMusicAccentRGBA? {
        if let cached = cache[url] {
            return cached
        }
        guard let image = CIImage(data: data) else { return nil }
        let color = dominantColor(in: image) ?? averageColor(in: image)
        let adjusted = color?.adjustedForMusicControls()
        if let adjusted {
            cache[url] = adjusted
        }
        return adjusted
    }

    private func dominantColor(in image: CIImage) -> BaMusicAccentRGBA? {
        let extent = image.extent.integral
        guard extent.width > 0, extent.height > 0 else { return nil }

        let sampleSize = 18
        let scale = CGFloat(sampleSize) / max(extent.width, extent.height)
        let transformed = image
            .clampedToExtent()
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .cropped(to: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        context.render(
            transformed,
            toBitmap: &pixels,
            rowBytes: sampleSize * 4,
            bounds: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize),
            format: .RGBA8,
            colorSpace: colorSpace
        )

        var buckets: [Int: BaMusicAccentBucket] = [:]
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha > 0.72 else { continue }
            let color = BaMusicAccentRGBA(
                red: Double(pixels[index]) / 255,
                green: Double(pixels[index + 1]) / 255,
                blue: Double(pixels[index + 2]) / 255
            )
            let hsv = color.hsv
            guard hsv.saturation > 0.16,
                  hsv.value > 0.18,
                  hsv.value < 0.96
            else {
                continue
            }
            let hueBucket = Int((hsv.hue * 24).rounded(.down))
            let saturationBucket = min(Int((hsv.saturation * 4).rounded(.down)), 3)
            let valueBucket = min(Int((hsv.value * 4).rounded(.down)), 3)
            let key = hueBucket * 100 + saturationBucket * 10 + valueBucket
            buckets[key, default: BaMusicAccentBucket()].add(color)
        }

        return buckets.values.max { lhs, rhs in
            lhs.score < rhs.score
        }?.color
    }

    private func averageColor(in image: CIImage) -> BaMusicAccentRGBA? {
        let extent = image.extent.integral
        guard extent.width > 0, extent.height > 0 else { return nil }
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let outputImage = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: colorSpace
        )
        return BaMusicAccentRGBA(
            red: Double(pixel[0]) / 255,
            green: Double(pixel[1]) / 255,
            blue: Double(pixel[2]) / 255
        )
    }
}

nonisolated private struct BaMusicAccentBucket {
    private(set) var red = 0.0
    private(set) var green = 0.0
    private(set) var blue = 0.0
    private(set) var count = 0
    private(set) var saturation = 0.0

    var color: BaMusicAccentRGBA {
        guard count > 0 else { return .fallback }
        return BaMusicAccentRGBA(
            red: red / Double(count),
            green: green / Double(count),
            blue: blue / Double(count)
        )
    }

    var score: Double {
        Double(count) * (0.55 + min(saturation / max(Double(count), 1), 1))
    }

    mutating func add(_ color: BaMusicAccentRGBA) {
        red += color.red
        green += color.green
        blue += color.blue
        saturation += color.hsv.saturation
        count += 1
    }
}

nonisolated private struct BaMusicAccentRGBA: Hashable, Sendable {
    static let fallback = BaMusicAccentRGBA(red: 0.0, green: 0.478, blue: 1.0)

    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var rgbValues: [Double] {
        [red, green, blue]
    }

    var hsv: BaMusicAccentHSV {
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let delta = maxValue - minValue
        let hue: Double
        if delta == 0 {
            hue = 0
        } else if maxValue == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6) / 6
        } else if maxValue == green {
            hue = ((blue - red) / delta + 2) / 6
        } else {
            hue = ((red - green) / delta + 4) / 6
        }
        return BaMusicAccentHSV(
            hue: hue < 0 ? hue + 1 : hue,
            saturation: maxValue == 0 ? 0 : delta / maxValue,
            value: maxValue
        )
    }

    func adjustedForMusicControls() -> BaMusicAccentRGBA {
        let hsv = hsv
        let saturation = max(hsv.saturation, 0.52)
        let value = min(max(hsv.value, 0.52), 0.82)
        return BaMusicAccentRGBA(hue: hsv.hue, saturation: saturation, value: value)
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    init(hue: Double, saturation: Double, value: Double) {
        let normalizedHue = hue.truncatingRemainder(dividingBy: 1)
        let chroma = value * saturation
        let sector = normalizedHue * 6
        let x = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let match = value - chroma
        let components: (Double, Double, Double)
        switch sector {
        case 0 ..< 1:
            components = (chroma, x, 0)
        case 1 ..< 2:
            components = (x, chroma, 0)
        case 2 ..< 3:
            components = (0, chroma, x)
        case 3 ..< 4:
            components = (0, x, chroma)
        case 4 ..< 5:
            components = (x, 0, chroma)
        default:
            components = (chroma, 0, x)
        }
        self.init(
            red: components.0 + match,
            green: components.1 + match,
            blue: components.2 + match
        )
    }
}

nonisolated private struct BaMusicAccentHSV: Hashable, Sendable {
    let hue: Double
    let saturation: Double
    let value: Double
}
