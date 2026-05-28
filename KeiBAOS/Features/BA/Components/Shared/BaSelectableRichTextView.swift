//
//  BaSelectableRichTextView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/29.
//

import Foundation
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct BaSelectableRichTextView: View {
    @Environment(BaAppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let segments: [BaRichTextSegment]
    private let plainText: String
    private let tint: Color
    private let baseWeight: BaRichTextWeight
    private let alignment: TextAlignment
    private let lineSpacing: CGFloat
    private let iconSize: CGFloat

    @State private var iconDataByURL: [URL: Data] = [:]

    init(
        text: String,
        tint: Color,
        baseWeight: BaRichTextWeight = .regular,
        alignment: TextAlignment = .leading,
        lineSpacing: CGFloat = 4,
        iconSize: CGFloat = 16
    ) {
        self.segments = [.text(text)]
        self.plainText = text
        self.tint = tint
        self.baseWeight = baseWeight
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.iconSize = iconSize
    }

    init(
        segments: [BaRichTextSegment],
        plainText: String,
        tint: Color,
        baseWeight: BaRichTextWeight = .regular,
        alignment: TextAlignment = .leading,
        lineSpacing: CGFloat = 4,
        iconSize: CGFloat = 16
    ) {
        self.segments = segments
        self.plainText = plainText
        self.tint = tint
        self.baseWeight = baseWeight
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.iconSize = iconSize
    }

    private var iconURLs: [URL] {
        segments.reduce(into: []) { result, segment in
            guard case let .icon(url) = segment, result.contains(url) == false else { return }
            result.append(url)
        }
    }

    private var iconTaskID: String {
        iconURLs.map(\.absoluteString).joined(separator: "|")
    }

    private var attributedText: NSAttributedString {
        BaRichTextAttributedStringBuilder.make(
            segments: segments,
            tint: tint,
            baseWeight: baseWeight,
            alignment: alignment,
            lineSpacing: lineSpacing,
            iconSize: iconSize,
            iconDataByURL: iconDataByURL
        )
    }

    var body: some View {
        Group {
            #if canImport(UIKit) && !os(watchOS)
                BaPlatformSelectableRichTextView(
                    attributedText: attributedText,
                    plainText: plainText,
                    tint: tint
                )
            #elseif canImport(AppKit)
                BaPlatformSelectableRichTextView(
                    attributedText: attributedText,
                    plainText: plainText,
                    tint: tint
                )
            #else
                Text(plainText)
                    .textSelection(.enabled)
            #endif
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(plainText))
        .fixedSize(horizontal: false, vertical: true)
        .task(id: iconTaskID) {
            await loadIconData()
        }
        .id("\(colorScheme)-\(dynamicTypeSize)")
    }

    private func loadIconData() async {
        let urls = iconURLs
        guard urls.isEmpty == false else {
            if iconDataByURL.isEmpty == false {
                iconDataByURL = [:]
            }
            return
        }

        var nextData = iconDataByURL.filter { urls.contains($0.key) }
        for url in urls where nextData[url] == nil {
            guard Task.isCancelled == false else { return }
            if let data = try? await model.imageData(for: url) {
                nextData[url] = data
            }
        }
        guard Task.isCancelled == false else { return }
        iconDataByURL = nextData
    }
}

enum BaRichTextSegment: Hashable {
    case text(String)
    case emphasized(String)
    case tinted(String)
    case secondary(String)
    case icon(URL)
}

enum BaRichTextWeight: Hashable {
    case regular
    case semibold
}

private enum BaRichTextAttributedStringBuilder {
    static func make(
        segments: [BaRichTextSegment],
        tint: Color,
        baseWeight: BaRichTextWeight,
        alignment: TextAlignment,
        lineSpacing: CGFloat,
        iconSize: CGFloat,
        iconDataByURL: [URL: Data]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for segment in segments {
            switch segment {
            case let .text(value):
                result.append(text(value, color: primaryColor, weight: baseWeight, tint: tint))
            case let .emphasized(value):
                result.append(text(value, color: primaryColor, weight: .semibold, tint: tint))
            case let .tinted(value):
                result.append(text(value, color: platformColor(tint), weight: .semibold, tint: tint))
            case let .secondary(value):
                result.append(text(value, color: secondaryColor, weight: baseWeight, tint: tint))
            case let .icon(url):
                result.append(icon(data: iconDataByURL[url], tint: tint, size: iconSize))
            }
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = nsAlignment(for: alignment)
        paragraph.lineSpacing = lineSpacing
        paragraph.lineBreakMode = .byWordWrapping
        result.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: result.length))
        return result
    }

    private static func text(
        _ value: String,
        color: Any,
        weight: BaRichTextWeight,
        tint: Color
    ) -> NSAttributedString {
        NSAttributedString(
            string: value,
            attributes: [
                .font: font(weight: weight),
                .foregroundColor: color,
                .underlineColor: platformColor(tint),
            ]
        )
    }

    private static func icon(data: Data?, tint: Color, size: CGFloat) -> NSAttributedString {
        #if canImport(UIKit) && !os(watchOS)
            let attachment = NSTextAttachment()
            attachment.image = image(data: data, tint: tint)
            attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)
            return NSAttributedString(attachment: attachment)
        #elseif canImport(AppKit)
            let attachment = NSTextAttachment()
            attachment.image = image(data: data, tint: tint)
            attachment.bounds = CGRect(x: 0, y: -2, width: size, height: size)
            return NSAttributedString(attachment: attachment)
        #else
            return text("◆", color: platformColor(tint), weight: .semibold, tint: tint)
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
        private static var primaryColor: UIColor { .label }
        private static var secondaryColor: UIColor { .secondaryLabel }

        private static func platformColor(_ color: Color) -> UIColor {
            UIColor(color)
        }

        private static func font(weight: BaRichTextWeight) -> UIFont {
            let textStyle = UIFont.TextStyle.body
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
            let base = UIFont.systemFont(ofSize: descriptor.pointSize, weight: uiWeight(weight))
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
        }

        private static func uiWeight(_ weight: BaRichTextWeight) -> UIFont.Weight {
            switch weight {
            case .regular:
                return .regular
            case .semibold:
                return .semibold
            }
        }

        private static func image(data: Data?, tint: Color) -> UIImage? {
            if let data, let image = UIImage(data: data) {
                return image
            }
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            return UIImage(systemName: "seal.fill", withConfiguration: config)?
                .withTintColor(platformColor(tint), renderingMode: .alwaysOriginal)
        }
    #elseif canImport(AppKit)
        private static var primaryColor: NSColor { .labelColor }
        private static var secondaryColor: NSColor { .secondaryLabelColor }

        private static func platformColor(_ color: Color) -> NSColor {
            NSColor(color)
        }

        private static func font(weight: BaRichTextWeight) -> NSFont {
            NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: nsWeight(weight))
        }

        private static func nsWeight(_ weight: BaRichTextWeight) -> NSFont.Weight {
            switch weight {
            case .regular:
                return .regular
            case .semibold:
                return .semibold
            }
        }

        private static func image(data: Data?, tint: Color) -> NSImage? {
            if let data, let image = NSImage(data: data) {
                return image
            }
            let image = NSImage(systemSymbolName: "seal.fill", accessibilityDescription: nil)
            image?.isTemplate = true
            return image
        }
    #else
        private static var primaryColor: Any { Color.primary }
        private static var secondaryColor: Any { Color.secondary }

        private static func platformColor(_ color: Color) -> Any {
            color
        }

        private static func font(weight: BaRichTextWeight) -> Any {
            weight
        }
    #endif

    private static func nsAlignment(for alignment: TextAlignment) -> NSTextAlignment {
        switch alignment {
        case .center:
            return .center
        case .trailing:
            return .right
        default:
            return .natural
        }
    }
}

#if canImport(UIKit) && !os(watchOS)
    private struct BaPlatformSelectableRichTextView: UIViewRepresentable {
        let attributedText: NSAttributedString
        let plainText: String
        let tint: Color

        func makeUIView(context: Context) -> UITextView {
            let textView = UITextView()
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.setContentCompressionResistancePriority(.required, for: .vertical)
            textView.setContentHuggingPriority(.required, for: .vertical)
            textView.accessibilityTraits.insert(.staticText)
            return textView
        }

        func updateUIView(_ textView: UITextView, context: Context) {
            if textView.attributedText.isEqual(to: attributedText) == false {
                textView.attributedText = attributedText
            }
            textView.tintColor = UIColor(tint)
            textView.accessibilityLabel = plainText
        }

        func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
            let width = max(proposal.width ?? uiView.bounds.width, 1)
            let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            return CGSize(width: width, height: ceil(size.height))
        }
    }
#elseif canImport(AppKit)
    private struct BaPlatformSelectableRichTextView: NSViewRepresentable {
        let attributedText: NSAttributedString
        let plainText: String
        let tint: Color

        func makeNSView(context: Context) -> NSTextView {
            let textView = NSTextView(frame: .zero)
            textView.drawsBackground = false
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = true
            textView.importsGraphics = true
            textView.textContainerInset = .zero
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.autoresizingMask = [.width]
            textView.setContentCompressionResistancePriority(.required, for: .vertical)
            textView.setContentHuggingPriority(.required, for: .vertical)
            textView.setAccessibilityRole(.staticText)
            return textView
        }

        func updateNSView(_ textView: NSTextView, context: Context) {
            if textView.attributedString().isEqual(to: attributedText) == false {
                textView.textStorage?.setAttributedString(attributedText)
            }
            textView.insertionPointColor = NSColor(tint)
            textView.setAccessibilityLabel(plainText)
        }

        func sizeThatFits(_ proposal: ProposedViewSize, nsView textView: NSTextView, context: Context) -> CGSize? {
            let width = max(proposal.width ?? textView.bounds.width, 1)
            textView.frame.size.width = width
            guard let container = textView.textContainer,
                  let layoutManager = textView.layoutManager
            else {
                return CGSize(width: width, height: 1)
            }
            container.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
            layoutManager.ensureLayout(for: container)
            let usedRect = layoutManager.usedRect(for: container)
            let height = ceil(usedRect.height + textView.textContainerInset.height * 2)
            return CGSize(width: width, height: max(height, 1))
        }
    }
#endif
