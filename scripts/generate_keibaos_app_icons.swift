#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO

private struct RGBA {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat

    init(_ hex: UInt32, alpha: CGFloat = 1) {
        r = CGFloat((hex >> 16) & 0xff) / 255
        g = CGFloat((hex >> 8) & 0xff) / 255
        b = CGFloat(hex & 0xff) / 255
        a = alpha
    }

    var cgColor: CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }
}

private struct IconTheme {
    let backgroundTop: RGBA
    let backgroundBottom: RGBA
    let glassTop: RGBA
    let glassBottom: RGBA
    let glowPrimary: RGBA
    let glowSecondary: RGBA
    let logoTop: RGBA
    let logoBottom: RGBA
    let logoEdge: RGBA
    let logoShadow: RGBA
    let offsetAccent: RGBA
}

private enum Appearance {
    case light
    case dark
    case tinted

    var theme: IconTheme {
        switch self {
        case .light:
            return IconTheme(
                backgroundTop: RGBA(0xfff7fb),
                backgroundBottom: RGBA(0xffb6d1),
                glassTop: RGBA(0xffffff, alpha: 0.58),
                glassBottom: RGBA(0xffc5dd, alpha: 0.22),
                glowPrimary: RGBA(0xff4f92, alpha: 0.26),
                glowSecondary: RGBA(0x8ff2df, alpha: 0.34),
                logoTop: RGBA(0xffdeeb),
                logoBottom: RGBA(0xff4f92),
                logoEdge: RGBA(0xde1875, alpha: 0.64),
                logoShadow: RGBA(0x6f1a48, alpha: 0.20),
                offsetAccent: RGBA(0x86f0df, alpha: 0.58)
            )
        case .dark:
            return IconTheme(
                backgroundTop: RGBA(0x191322),
                backgroundBottom: RGBA(0x2e1232),
                glassTop: RGBA(0xffffff, alpha: 0.16),
                glassBottom: RGBA(0xff7aaf, alpha: 0.12),
                glowPrimary: RGBA(0xff5b9a, alpha: 0.32),
                glowSecondary: RGBA(0x80eadb, alpha: 0.24),
                logoTop: RGBA(0xffd8e7),
                logoBottom: RGBA(0xff4f92),
                logoEdge: RGBA(0xffa6cb, alpha: 0.58),
                logoShadow: RGBA(0x000000, alpha: 0.34),
                offsetAccent: RGBA(0x8ff2df, alpha: 0.42)
            )
        case .tinted:
            return IconTheme(
                backgroundTop: RGBA(0xf8f8fb),
                backgroundBottom: RGBA(0xbfc4cf),
                glassTop: RGBA(0xffffff, alpha: 0.48),
                glassBottom: RGBA(0xd9dce4, alpha: 0.18),
                glowPrimary: RGBA(0x303440, alpha: 0.10),
                glowSecondary: RGBA(0xffffff, alpha: 0.24),
                logoTop: RGBA(0x4b505c),
                logoBottom: RGBA(0x11151f),
                logoEdge: RGBA(0x080a10, alpha: 0.52),
                logoShadow: RGBA(0x000000, alpha: 0.18),
                offsetAccent: RGBA(0xffffff, alpha: 0.40)
            )
        }
    }
}

private let iconSetURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("KeiBAOS/Assets.xcassets/AppIcon.appiconset")

private func makeContext(width: Int, height: Int? = nil) -> CGContext {
    let resolvedHeight = height ?? width
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: nil,
        width: width,
        height: resolvedHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    return context
}

private func linearGradient(_ colors: [RGBA]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: colors.map(\.cgColor) as CFArray,
        locations: nil
    )!
}

private func drawLinearGradient(
    _ context: CGContext,
    colors: [RGBA],
    from start: CGPoint,
    to end: CGPoint
) {
    context.drawLinearGradient(
        linearGradient(colors),
        start: start,
        end: end,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

private func drawRadialGlow(
    _ context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    color: RGBA
) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [
            color.cgColor,
            RGBA(0xffffff, alpha: 0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: [.drawsAfterEndLocation]
    )
}

private func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )
}

private func drawGlassBackground(_ context: CGContext, size: CGFloat, theme: IconTheme) {
    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    context.saveGState()
    context.setFillColor(theme.backgroundTop.cgColor)
    context.fill(canvas)
    context.addRect(canvas)
    context.clip()
    drawLinearGradient(
        context,
        colors: [theme.backgroundTop, theme.backgroundBottom],
        from: CGPoint(x: size * 0.18, y: 0),
        to: CGPoint(x: size * 0.82, y: size)
    )
    drawRadialGlow(
        context,
        center: CGPoint(x: size * 0.20, y: size * 0.18),
        radius: size * 0.56,
        color: RGBA(0xffffff, alpha: 0.52)
    )
    drawRadialGlow(
        context,
        center: CGPoint(x: size * 0.80, y: size * 0.30),
        radius: size * 0.46,
        color: theme.glowSecondary
    )
    drawRadialGlow(
        context,
        center: CGPoint(x: size * 0.58, y: size * 0.86),
        radius: size * 0.58,
        color: theme.glowPrimary
    )
    context.restoreGState()

    let plate = CGRect(
        x: size * 0.094,
        y: size * 0.082,
        width: size * 0.812,
        height: size * 0.836
    )
    context.saveGState()
    context.addPath(roundedRectPath(plate, radius: size * 0.22))
    context.clip()
    drawLinearGradient(
        context,
        colors: [theme.glassTop, theme.glassBottom],
        from: CGPoint(x: plate.minX, y: plate.minY),
        to: CGPoint(x: plate.maxX, y: plate.maxY)
    )
    context.restoreGState()

    context.saveGState()
    context.addPath(roundedRectPath(plate.insetBy(dx: size * 0.012, dy: size * 0.012), radius: size * 0.20))
    context.setStrokeColor(RGBA(0xffffff, alpha: 0.36).cgColor)
    context.setLineWidth(size * 0.010)
    context.strokePath()
    context.restoreGState()
}

private func drawLogoShape(
    _ context: CGContext,
    size: CGFloat,
    theme: IconTheme,
    rect: CGRect,
    hole: CGRect?,
    corner: CGFloat,
    holeCorner: CGFloat
) {
    let path = CGMutablePath()
    path.addPath(roundedRectPath(rect, radius: corner))
    if let hole {
        path.addPath(roundedRectPath(hole, radius: holeCorner))
    }

    context.saveGState()
    context.addPath(path)
    context.clip(using: .evenOdd)
    drawLinearGradient(
        context,
        colors: [theme.logoTop, theme.logoBottom],
        from: CGPoint(x: size * 0.28, y: size * 0.18),
        to: CGPoint(x: size * 0.72, y: size * 0.88)
    )
    context.restoreGState()

    context.saveGState()
    context.addPath(roundedRectPath(rect, radius: corner))
    context.setStrokeColor(theme.logoEdge.cgColor)
    context.setLineWidth(max(1.2, size * 0.011))
    context.strokePath()
    if let hole {
        context.addPath(roundedRectPath(hole, radius: holeCorner))
        context.setStrokeColor(RGBA(0xffffff, alpha: 0.32).cgColor)
        context.setLineWidth(max(1, size * 0.006))
        context.strokePath()
    }
    context.restoreGState()
}

private func drawLogo(_ context: CGContext, size: CGFloat, appearance: Appearance) {
    let theme = appearance.theme
    let s = size / 1024
    let logoRects = [
        (
            CGRect(x: 202, y: 220, width: 480, height: 480),
            CGRect(x: 286, y: 304, width: 312, height: 312),
            CGFloat(42),
            CGFloat(20)
        ),
        (
            CGRect(x: 463, y: 350, width: 360, height: 326),
            CGRect(x: 548, y: 434, width: 190, height: 158),
            CGFloat(40),
            CGFloat(18)
        ),
        (
            CGRect(x: 310, y: 585, width: 262, height: 238),
            CGRect(x: 370, y: 643, width: 142, height: 122),
            CGFloat(34),
            CGFloat(16)
        ),
        (
            CGRect(x: 658, y: 252, width: 172, height: 86),
            CGRect(x: 700, y: 286, width: 80, height: 22),
            CGFloat(26),
            CGFloat(10)
        )
    ]

    let filledBars = [
        CGRect(x: 402, y: 282, width: 190, height: 52),
        CGRect(x: 370, y: 548, width: 198, height: 42),
        CGRect(x: 515, y: 360, width: 64, height: 210)
    ]

    context.saveGState()
    context.translateBy(x: 0, y: 0)

    for (dx, dy, color, blur) in [
        (CGFloat(30) * s, CGFloat(24) * s, theme.logoShadow, CGFloat(0)),
        (CGFloat(22) * s, CGFloat(18) * s, theme.offsetAccent, CGFloat(0))
    ] {
        context.saveGState()
        context.translateBy(x: dx, y: dy)
        context.setFillColor(color.cgColor)
        for (rect, hole, corner, holeCorner) in logoRects {
            let path = CGMutablePath()
            path.addPath(roundedRectPath(rect.applying(CGAffineTransform(scaleX: s, y: s)), radius: corner * s))
            path.addPath(roundedRectPath(hole.applying(CGAffineTransform(scaleX: s, y: s)), radius: holeCorner * s))
            context.addPath(path)
            context.fillPath(using: .evenOdd)
        }
        for bar in filledBars {
            context.addPath(roundedRectPath(bar.applying(CGAffineTransform(scaleX: s, y: s)), radius: 16 * s))
            context.fillPath()
        }
        _ = blur
        context.restoreGState()
    }

    for (rect, hole, corner, holeCorner) in logoRects {
        drawLogoShape(
            context,
            size: size,
            theme: theme,
            rect: rect.applying(CGAffineTransform(scaleX: s, y: s)),
            hole: hole.applying(CGAffineTransform(scaleX: s, y: s)),
            corner: corner * s,
            holeCorner: holeCorner * s
        )
    }

    for bar in filledBars {
        let rect = bar.applying(CGAffineTransform(scaleX: s, y: s))
        context.saveGState()
        context.addPath(roundedRectPath(rect, radius: 16 * s))
        context.clip()
        drawLinearGradient(
            context,
            colors: [theme.logoTop, theme.logoBottom],
            from: CGPoint(x: size * 0.28, y: size * 0.18),
            to: CGPoint(x: size * 0.72, y: size * 0.88)
        )
        context.restoreGState()

        context.saveGState()
        context.addPath(roundedRectPath(rect, radius: 16 * s))
        context.setStrokeColor(theme.logoEdge.cgColor)
        context.setLineWidth(max(1.2, size * 0.010))
        context.strokePath()
        context.restoreGState()
    }

    context.saveGState()
    let shine = CGRect(x: 246, y: 216, width: 408, height: 94).applying(CGAffineTransform(scaleX: s, y: s))
    context.addPath(roundedRectPath(shine, radius: 44 * s))
    context.clip()
    drawLinearGradient(
        context,
        colors: [RGBA(0xffffff, alpha: appearance == .dark ? 0.26 : 0.46), RGBA(0xffffff, alpha: 0)],
        from: CGPoint(x: shine.minX, y: shine.minY),
        to: CGPoint(x: shine.maxX, y: shine.maxY)
    )
    context.restoreGState()

    context.restoreGState()
}

private func renderIcon(size: Int, appearance: Appearance) -> CGImage {
    let context = makeContext(width: size)
    let canvasSize = CGFloat(size)
    drawGlassBackground(context, size: canvasSize, theme: appearance.theme)
    drawLogo(context, size: canvasSize, appearance: appearance)
    return context.makeImage()!
}

private func writePNG(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        "public.png" as CFString,
        1,
        nil
    )!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Failed to write \(url.path)")
    }
}

private func resize(_ image: CGImage, size: Int) -> CGImage {
    let context = makeContext(width: size)
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    return context.makeImage()!
}

private func renderContactSheet(light: CGImage, dark: CGImage, tinted: CGImage) {
    let cell = 288
    let padding = 36
    let width = cell * 3 + padding * 4
    let height = cell + padding * 2
    let context = makeContext(width: width, height: height)
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(RGBA(0xf5f5f7).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    for (index, image) in [light, dark, tinted].enumerated() {
        let x = padding + index * (cell + padding)
        context.draw(image, in: CGRect(x: x, y: padding, width: cell, height: cell))
    }
    let sheet = context.makeImage()!
    writePNG(sheet, to: URL(fileURLWithPath: "/tmp/keibaos-icon-preview.png"))
}

let light = renderIcon(size: 1024, appearance: .light)
let dark = renderIcon(size: 1024, appearance: .dark)
let tinted = renderIcon(size: 1024, appearance: .tinted)

writePNG(light, to: iconSetURL.appendingPathComponent("AppIcon-Light.png"))
writePNG(dark, to: iconSetURL.appendingPathComponent("AppIcon-Dark.png"))
writePNG(tinted, to: iconSetURL.appendingPathComponent("AppIcon-Tinted.png"))

let macSizes: [(String, Int)] = [
    ("AppIcon-mac-16-1x.png", 16),
    ("AppIcon-mac-16-2x.png", 32),
    ("AppIcon-mac-32-1x.png", 32),
    ("AppIcon-mac-32-2x.png", 64),
    ("AppIcon-mac-128-1x.png", 128),
    ("AppIcon-mac-128-2x.png", 256),
    ("AppIcon-mac-256-1x.png", 256),
    ("AppIcon-mac-256-2x.png", 512),
    ("AppIcon-mac-512-1x.png", 512),
    ("AppIcon-mac-512-2x.png", 1024)
]

for (filename, size) in macSizes {
    writePNG(resize(light, size: size), to: iconSetURL.appendingPathComponent(filename))
}

renderContactSheet(light: light, dark: dark, tinted: tinted)
print("Generated KeiBAOS app icons in \(iconSetURL.path)")
print("Preview: /tmp/keibaos-icon-preview.png")
