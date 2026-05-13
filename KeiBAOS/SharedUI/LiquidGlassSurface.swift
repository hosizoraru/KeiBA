//
//  LiquidGlassSurface.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct LiquidGlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets
    private let tint: Color
    private let isInteractive: Bool
    private let content: Content

    init(
        cornerRadius: CGFloat = 26,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        tint: Color = .white.opacity(0.08),
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tint = tint
        self.isInteractive = isInteractive
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(cornerRadius: cornerRadius, tint: tint, isInteractive: isInteractive)
    }
}

private extension View {
    @ViewBuilder
    func liquidGlassSurface(cornerRadius: CGFloat, tint: Color, isInteractive: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            if isInteractive {
                self
                    .background(.clear, in: shape)
                    .glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self
                    .background(.clear, in: shape)
                    .glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(0.14), lineWidth: 1)
                }
        }
    }
}
