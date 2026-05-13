//
//  LiquidGlassControls.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct LiquidGlassIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var tint: Color = .blue
    var size: CGFloat = 38
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.43, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .contentShape(.rect(cornerRadius: size / 2))
        }
        .buttonStyle(.plain)
        .liquidGlassSurface(
            cornerRadius: size / 2,
            tint: tint.opacity(0.12),
            isInteractive: true
        )
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

struct LiquidGlassPill<Content: View>: View {
    var tint: Color = .blue
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 7
    let content: Content

    init(
        tint: Color = .blue,
        horizontalPadding: CGFloat = 14,
        verticalPadding: CGFloat = 7,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .liquidGlassSurface(
                cornerRadius: 999,
                tint: tint.opacity(0.14),
                isInteractive: false
            )
    }
}
