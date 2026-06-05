//
//  BaMusicAccentPaletteTests.swift
//  KeiBATests
//
//  Created by Codex on 2026/05/17.
//

import CoreGraphics
import Foundation
import ImageIO
@testable import KeiBA
import UniformTypeIdentifiers
import XCTest

final class BaMusicAccentPaletteTests: XCTestCase {
    func testAvatarAccentSamplerKeepsDominantBlueTone() async throws {
        let data = try pngData(red: 0.05, green: 0.38, blue: 0.92)

        let sampledRGB = await BaMusicAccentPalette.rgbValuesForTesting(from: data)
        let rgb = try XCTUnwrap(sampledRGB)

        XCTAssertGreaterThan(rgb[2], rgb[0])
        XCTAssertGreaterThan(rgb[2], rgb[1] * 0.9)
        XCTAssertGreaterThan(rgb.max() ?? 0, 0.5)
    }

    private func pngData(red: CGFloat, green: CGFloat, blue: CGFloat) throws -> Data {
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 4,
            height: 4,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
