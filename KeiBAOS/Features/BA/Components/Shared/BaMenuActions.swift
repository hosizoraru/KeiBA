//
//  BaMenuActions.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

// Stored only to defer Menu mutations until dismissal finishes; execution remains on MainActor.
struct BaDelayedMenuAction: @unchecked Sendable {
    private let run: @MainActor () -> Void

    init(_ run: @escaping @MainActor () -> Void) {
        self.run = run
    }

    @MainActor
    func callAsFunction() {
        run()
    }
}

@MainActor
enum BaMenuActionDispatcher {
    static func perform(_ action: @escaping @MainActor () -> Void) {
        perform(BaDelayedMenuAction(action))
    }

    static func perform(_ action: BaDelayedMenuAction) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            action()
        }
    }
}

struct BaMenuActionButton: View {
    let title: String
    let systemImage: String
    let action: BaDelayedMenuAction

    init(
        title: String,
        systemImage: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = BaDelayedMenuAction(action)
    }

    var body: some View {
        Button {
            BaMenuActionDispatcher.perform(action)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

struct BaMenuToggleButton: View {
    let title: String
    let isOn: Bool
    let action: BaDelayedMenuAction

    init(
        title: String,
        isOn: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.isOn = isOn
        self.action = BaDelayedMenuAction(action)
    }

    var body: some View {
        Button {
            BaMenuActionDispatcher.perform(action)
        } label: {
            Label(title, systemImage: isOn ? "checkmark" : "circle")
        }
    }
}

struct BaMenuIconButton: View {
    let systemImage: String
    let dimension: CGFloat
    let font: Font

    init(
        systemImage: String = "ellipsis.circle",
        dimension: CGFloat = 36,
        font: Font = .body.weight(.semibold)
    ) {
        self.systemImage = systemImage
        self.dimension = dimension
        self.font = font
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(font)
            .foregroundStyle(.secondary)
            .frame(width: dimension, height: dimension)
            .contentShape(Circle())
    }
}

struct BaMenuPickerLabel: View {
    let title: String
    let tint: Color
    let minWidth: CGFloat
    let maxWidth: CGFloat?
    let height: CGFloat
    let horizontalPadding: CGFloat
    let font: Font
    let iconSystemName: String
    let iconFont: Font
    let usesGlassSurface: Bool

    init(
        title: String,
        tint: Color,
        minWidth: CGFloat = 52,
        maxWidth: CGFloat? = nil,
        height: CGFloat = 34,
        horizontalPadding: CGFloat = 10,
        font: Font = .subheadline.weight(.semibold),
        iconSystemName: String = "chevron.up.chevron.down",
        iconFont: Font = .caption2.weight(.bold),
        usesGlassSurface: Bool = false
    ) {
        self.title = title
        self.tint = tint
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.font = font
        self.iconSystemName = iconSystemName
        self.iconFont = iconFont
        self.usesGlassSurface = usesGlassSurface
    }

    var body: some View {
        if usesGlassSurface {
            labelContent
                .foregroundStyle(tint)
                .padding(.horizontal, horizontalPadding)
                .frame(height: height)
                .contentShape(Capsule())
                .liquidGlassSurface(cornerRadius: height / 2, tint: tint.opacity(0.10), isInteractive: true)
        } else {
            labelContent
                .foregroundStyle(tint)
                .padding(.horizontal, horizontalPadding)
                .frame(height: height)
                .contentShape(Capsule())
                .background(tint.opacity(0.08), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(tint.opacity(0.16), lineWidth: 0.8)
                }
        }
    }

    private var labelContent: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(font)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .leading)

            Image(systemName: iconSystemName)
                .font(iconFont)
        }
    }
}
