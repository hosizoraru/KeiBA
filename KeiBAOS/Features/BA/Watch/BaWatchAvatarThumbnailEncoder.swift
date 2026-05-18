//
//  BaWatchAvatarThumbnailEncoder.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/19.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BaWatchAvatarThumbnailEncoder {
    nonisolated static let maxPixelDimension = 96
    nonisolated static let maxPayloadBytes = 24 * 1024

    nonisolated static func encodedThumbnailData(from data: Data) async -> Data? {
        await Task.detached(priority: .utility) {
            guard let cgImage = thumbnailImage(from: data, maxPixelDimension: maxPixelDimension) else {
                return nil
            }
            return jpegData(from: cgImage, compressionQuality: 0.72)
        }.value
    }

    private nonisolated static func thumbnailImage(from data: Data, maxPixelDimension: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private nonisolated static func jpegData(from image: CGImage, compressionQuality: Double) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        let data = output as Data
        return data.count <= maxPayloadBytes ? data : nil
    }
}
