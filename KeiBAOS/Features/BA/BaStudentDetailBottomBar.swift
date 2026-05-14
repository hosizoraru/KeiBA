//
//  BaStudentDetailBottomBar.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/14.
//

import SwiftUI

struct BaStudentDetailBottomBar: View {
    @Binding var selection: BaStudentDetailPage

    var body: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                GlassEffectContainer(spacing: 8) {
                    content
                }
            } else {
                content
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var content: some View {
        HStack(spacing: 4) {
            ForEach(BaStudentDetailPage.allCases) { page in
                BaStudentDetailBottomTabButton(
                    page: page,
                    isSelected: selection == page
                ) {
                    withAnimation(.snappy(duration: 0.24, extraBounce: 0.08)) {
                        selection = page
                    }
                }
            }
        }
        .padding(7)
        .liquidGlassSurface(cornerRadius: 30, tint: BaDesign.blue.opacity(0.035), isInteractive: false)
    }
}

private struct BaStudentDetailBottomTabButton: View {
    let page: BaStudentDetailPage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: page.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(height: 20)

                Text(page.title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .foregroundStyle(isSelected ? BaDesign.blue : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .modifier(BaSelectedBottomTabSurface(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(page.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct BaSelectedBottomTabSurface: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .liquidGlassSurface(cornerRadius: 23, tint: BaDesign.blue.opacity(0.12), isInteractive: true)
        } else {
            content
        }
    }
}
