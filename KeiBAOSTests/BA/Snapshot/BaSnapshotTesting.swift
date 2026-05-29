//
//  BaSnapshotTesting.swift
//  KeiBAOSTests
//
//  Created by Codex on 2026/05/29.
//

import XCTest
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

enum BaSnapshotTesting {
    static var baselineDirectory: URL {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Baselines")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func assertSnapshot<V: View>(
        of view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let image = render(view: view)
        let baselineURL = baselineDirectory.appendingPathComponent("\(name).png")
        let isNewBaseline = !FileManager.default.fileExists(atPath: baselineURL.path)

        if isNewBaseline {
            saveImage(image, to: baselineURL)
            XCTFail("New baseline created: \(baselineURL.path). Review and commit.", file: file, line: line)
            return
        }

        guard let baselineImage = loadImage(from: baselineURL) else {
            XCTFail("Could not load baseline: \(baselineURL.path)", file: file, line: line)
            return
        }

        let difference = computeDifference(image, baselineImage)
        if difference > 0.01 {
            saveImage(image, to: baselineURL.deletingLastPathComponent()
                .appendingPathComponent("\(name)-actual.png"))
            XCTFail(
                "Snapshot mismatch for \(name): \(String(format: "%.2f", difference * 100))% different",
                file: file,
                line: line
            )
        }
    }

    #if canImport(UIKit)
        private static func render<V: View>(view: V) -> UIImage {
            let hosting = UIHostingController(rootView: view)
            let size = UIScreen.main.bounds.size
            hosting.view.frame = CGRect(origin: .zero, size: size)
            hosting.view.layoutIfNeeded()

            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                hosting.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
        }

        private static func saveImage(_ image: UIImage, to url: URL) {
            guard let data = image.pngData() else { return }
            try? data.write(to: url)
        }

        private static func loadImage(from url: URL) -> UIImage? {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }

        private static func computeDifference(_ a: UIImage, _ b: UIImage) -> CGFloat {
            guard let dataA = a.pngData(), let dataB = b.pngData() else { return 1 }
            return dataA == dataB ? 0 : 1
        }
    #elseif canImport(AppKit)
        private static func render<V: View>(view: V) -> NSImage {
            let hosting = NSHostingController(rootView: view)
            let size = NSSize(width: 800, height: 600)
            hosting.view.frame = CGRect(origin: .zero, size: size)
            hosting.view.layoutSubtreeIfNeeded()

            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size.width),
                pixelsHigh: Int(size.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                return NSImage(size: size)
            }

            let image = NSImage(size: size)
            image.addRepresentation(bitmap)
            guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return image }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            hosting.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            NSGraphicsContext.restoreGraphicsState()
            return image
        }

        private static func saveImage(_ image: NSImage, to url: URL) {
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:])
            else { return }
            try? pngData.write(to: url)
        }

        private static func loadImage(from url: URL) -> NSImage? {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return NSImage(data: data)
        }

        private static func computeDifference(_ a: NSImage, _ b: NSImage) -> CGFloat {
            guard let dataA = a.tiffRepresentation, let dataB = b.tiffRepresentation else { return 1 }
            return dataA == dataB ? 0 : 1
        }
    #endif
}
