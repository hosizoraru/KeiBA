//
//  BaCards.swift
//  KeiBAOS
//
//  Created by Voyager on 2026/05/14.
//

import SwiftUI

struct BaScreenIntro: View {
    let eyebrow: String
    let title: String
    let detail: String
    let systemImage: String
    var tint: Color = BaDesign.blue

    var body: some View {
        LiquidGlassSurface(cornerRadius: 30, tint: tint.opacity(0.12)) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 7) {
                    Text(eyebrow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .textCase(.uppercase)

                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct BaInfoPanel<Content: View>: View {
    var tint: Color = BaDesign.blue
    let content: Content

    init(tint: Color = BaDesign.blue, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassSurface(cornerRadius: 22, tint: tint.opacity(0.10), isInteractive: false)
    }
}

struct BaValueRow: View {
    let title: String
    let value: String
    var suffix: String?
    var systemImage: String?
    var tint: Color = BaDesign.blue

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                LiquidGlassPill(tint: tint) {
                    Text(value)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if let suffix {
                    Text(suffix)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
        }
    }
}

struct BaMetricTile: View {
    let title: String
    let value: String
    var detail: String?
    var systemImage: String
    var tint: Color = BaDesign.blue

    var body: some View {
        LiquidGlassSurface(
            cornerRadius: 24,
            padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14),
            tint: tint.opacity(0.10)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(value)
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(tint)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        }
    }
}
