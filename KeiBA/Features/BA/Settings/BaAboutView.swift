//
//  BaAboutView.swift
//  KeiBA
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct BaAboutView: View {
    @Environment(BaAppModel.self) private var model

    private let acknowledgements = BaAboutAcknowledgement.defaultItems

    var body: some View {
        #if os(macOS)
            macAboutBody
        #else
            touchAboutBody
        #endif
    }

    private var touchAboutBody: some View {
        Form {
            heroSection
            versionSection
            platformSection
            dataSection
            acknowledgementSection
        }
        .baAdaptiveReadableContent(maxWidth: 760)
        .scrollContentBackground(.hidden)
        .background(AppBackground())
    }

    #if os(macOS)
    private var macAboutBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                macAboutGroup(BaL10n.string("ba.about.version.section")) {
                    versionRows
                }

                macAboutGroup(
                    BaL10n.string("ba.settings.platform.title"),
                    footer: BaL10n.string("ba.about.platform.footer")
                ) {
                    platformRows
                }

                macAboutGroup(BaL10n.string("ba.about.data.section")) {
                    dataRows
                }

                macAboutGroup(
                    BaL10n.string("ba.about.acknowledgements.section"),
                    footer: BaL10n.string("ba.about.acknowledgements.footer")
                ) {
                    acknowledgementRows
                }
            }
            .padding(24)
            .padding(.bottom, 32)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppBackground())
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            aboutHero
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func macAboutGroup<Content: View>(
        _ title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    #endif

    private var heroSection: some View {
        Section {
            aboutHero
                .listRowInsets(EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16))
        }
    }

    private var aboutHero: some View {
        HStack(spacing: 16) {
            BaAboutAppIconView(choice: model.envelope.globalSettings.appIcon, size: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text("KeiBA")
                    .font(.title2.weight(.semibold))

                Text(BaL10n.string("ba.about.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var versionSection: some View {
        Section(BaL10n.string("ba.about.version.section")) {
            versionRows
        }
    }

    @ViewBuilder
    private var versionRows: some View {
        LabeledContent(BaL10n.string("ba.about.version.marketing")) {
            Text(BaAppVersionInfo.marketingVersion)
                .monospacedDigit()
        }

        LabeledContent(BaL10n.string("ba.about.version.build")) {
            Text(BaAppVersionInfo.buildVersion)
                .monospacedDigit()
        }

        LabeledContent(BaL10n.string("ba.about.version.configuration")) {
            Text(BaAppVersionInfo.buildConfiguration)
                .font(.callout.monospaced())
        }

        LabeledContent(BaL10n.string("ba.about.version.runtime")) {
            Text(BaAppVersionInfo.runtimeEnvironment)
        }

        LabeledContent(BaL10n.string("ba.about.version.bundle")) {
            Text(BaAppVersionInfo.bundleIdentifier)
                .textSelection(.enabled)
                .font(.callout.monospaced())
        }
    }

    private var platformSection: some View {
        Section {
            platformRows
        } header: {
            Text(BaL10n.string("ba.settings.platform.title"))
        } footer: {
            Text(BaL10n.string("ba.about.platform.footer"))
        }
    }

    @ViewBuilder
    private var platformRows: some View {
        BaAboutSubsectionHeader(title: BaL10n.string("ba.about.platform.deployment"))

        ForEach(AppPlatformBaseline.allCases) { baseline in
            BaAboutBaselineRow(
                title: baseline.displayName,
                value: baseline.minimumVersion,
                systemImage: baseline.systemImage
            )
        }

        Divider()

        BaAboutSubsectionHeader(title: BaL10n.string("ba.about.platform.build"))

        ForEach(AppBuildBaseline.allCases) { baseline in
            BaAboutBaselineRow(
                title: BaL10n.string(baseline.titleKey),
                value: baseline.value,
                systemImage: baseline.systemImage
            )
        }
    }

    private var dataSection: some View {
        Section(BaL10n.string("ba.about.data.section")) {
            dataRows
        }
    }

    @ViewBuilder
    private var dataRows: some View {
        BaAboutLinkRow(
            title: BaL10n.string("ba.about.data.github.title"),
            detail: BaL10n.string("ba.about.data.github.detail"),
            url: URL(string: "https://github.com/hosizoraru/KeiBA")
        )

        BaAboutLinkRow(
            title: BaL10n.string("ba.about.data.releases.title"),
            detail: BaL10n.string("ba.about.data.releases.detail"),
            url: URL(string: "https://github.com/hosizoraru/KeiBA/releases")
        )

        BaAboutLinkRow(
            title: BaL10n.string("ba.about.data.gamekee.title"),
            detail: BaL10n.string("ba.about.data.gamekee.detail"),
            url: URL(string: "https://www.gamekee.com/ba/")
        )

        BaAboutInfoRow(
            title: BaL10n.string("ba.about.data.rights.title"),
            detail: BaL10n.string("ba.about.data.rights.detail")
        )
    }

    private var acknowledgementSection: some View {
        Section {
            acknowledgementRows
        } header: {
            Text(BaL10n.string("ba.about.acknowledgements.section"))
        } footer: {
            Text(BaL10n.string("ba.about.acknowledgements.footer"))
        }
    }

    @ViewBuilder
    private var acknowledgementRows: some View {
        ForEach(acknowledgements) { acknowledgement in
            BaAboutLinkRow(
                title: acknowledgement.title,
                detail: String(
                    format: BaL10n.string("ba.about.acknowledgement.detail.format"),
                    acknowledgement.version,
                    acknowledgement.license
                ),
                url: acknowledgement.url
            )
        }
    }
}

private struct BaAboutAppIconView: View {
    let choice: BaAppIconChoice
    let size: CGFloat

    var body: some View {
        Group {
            if let image = appIconImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityHidden(true)
    }

    private var appIconImage: Image? {
        #if os(iOS)
            guard let uiImage = UIImage(named: choice.previewAssetName) else { return nil }
            return Image(uiImage: uiImage)
        #elseif os(macOS)
            if let nsImage = NSImage(named: choice.previewAssetName) {
                return Image(nsImage: nsImage)
            }
            guard let appIcon = NSApp.applicationIconImage, appIcon.isValid else { return nil }
            return Image(nsImage: appIcon)
        #else
            return nil
        #endif
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        switch choice {
        case .modern:
            BaModernAppIconFallback()
        case .classic:
            BaGameAssetIcon(.schale, size: size * 0.54)
                .frame(width: size, height: size)
                .background(.thinMaterial)
        }
    }
}

private extension BaAppIconChoice {
    var previewAssetName: String {
        switch self {
        case .modern:
            "keiba"
        case .classic:
            "AppIcon"
        }
    }
}

private struct BaModernAppIconFallback: View {
    var body: some View {
        GeometryReader { geometry in
            let length = min(geometry.size.width, geometry.size.height)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.97),
                        Color(red: 1.0, green: 0.82, blue: 0.89)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                BaModernAppIconMotif()
                    .frame(width: length, height: length)
            }
            .frame(width: length, height: length)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct BaModernAppIconMotif: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 340
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let color = GraphicsContext.Shading.color(BaDesign.pink)

            var strokedSquare = Path()
            strokedSquare.addRect(CGRect(x: 62, y: 68, width: 150, height: 150))
            context.stroke(
                strokedSquare.applying(transform),
                with: color,
                lineWidth: 22 * scale
            )

            fillCutoutRect(
                outer: CGRect(x: 164, y: 106, width: 140, height: 147),
                inner: CGRect(x: 183, y: 125, width: 102, height: 109),
                transform: transform,
                context: &context,
                color: color
            )
            fillCutoutRect(
                outer: CGRect(x: 90, y: 187, width: 104, height: 109),
                inner: CGRect(x: 109, y: 206, width: 66, height: 71),
                transform: transform,
                context: &context,
                color: color
            )
            fillCutoutRect(
                outer: CGRect(x: 236, y: 66, width: 57, height: 34),
                inner: CGRect(x: 249, y: 79, width: 31, height: 8),
                transform: transform,
                context: &context,
                color: color
            )

            var topBar = Path()
            topBar.addRect(CGRect(x: 137, y: 69, width: 46, height: 18))
            context.fill(topBar.applying(transform), with: color)
        }
    }

    private func fillCutoutRect(
        outer: CGRect,
        inner: CGRect,
        transform: CGAffineTransform,
        context: inout GraphicsContext,
        color: GraphicsContext.Shading
    ) {
        var path = Path()
        path.addRect(outer)
        path.addRect(inner)
        context.fill(path.applying(transform), with: color, style: FillStyle(eoFill: true))
    }
}

private struct BaAboutSubsectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

private struct BaAboutBaselineRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            LabeledContent(title) {
                Text(value)
                    .monospacedDigit()
                    .textSelection(.enabled)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
    }
}

private struct BaAboutInfoRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BaAboutLinkRow: View {
    let title: String
    let detail: String
    let url: URL?

    var body: some View {
        if let url {
            Link(destination: url) {
                rowContent
            }
            .foregroundStyle(.primary)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if url != nil {
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct BaAboutAcknowledgement: Identifiable {
    let id: String
    let title: String
    let version: String
    let license: String
    let url: URL?

    static let defaultItems: [Self] = [
        Self(
            id: "audio-streaming",
            title: "AudioStreaming",
            version: "1.4.4",
            license: "MIT",
            url: URL(string: "https://github.com/dimitris-c/AudioStreaming")
        ),
        Self(
            id: "ogg-binary-xcframework",
            title: "ogg-binary-xcframework",
            version: "0.1.2",
            license: "BSD-3-Clause",
            url: URL(string: "https://github.com/sbooth/ogg-binary-xcframework")
        ),
        Self(
            id: "vorbis-binary-xcframework",
            title: "vorbis-binary-xcframework",
            version: "0.1.2",
            license: "BSD-3-Clause",
            url: URL(string: "https://github.com/sbooth/vorbis-binary-xcframework")
        )
    ]
}

private enum BaAppVersionInfo {
    static var marketingVersion: String {
        infoString("CFBundleShortVersionString")
    }

    static var buildVersion: String {
        infoString("CFBundleVersion")
    }

    static var buildConfiguration: String {
        #if DEBUG
            BaL10n.string("ba.about.version.configuration.debug")
        #else
            BaL10n.string("ba.about.version.configuration.release")
        #endif
    }

    static var runtimeEnvironment: String {
        #if os(macOS)
            BaL10n.string("ba.about.version.runtime.mac")
        #elseif targetEnvironment(simulator)
            BaL10n.string("ba.about.version.runtime.simulator")
        #else
            BaL10n.string("ba.about.version.runtime.device")
        #endif
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? BaL10n.string("ba.about.version.unknown")
    }

    private static func infoString(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
            ?? BaL10n.string("ba.about.version.unknown")
    }
}

#Preview {
    NavigationStack {
        BaAboutView()
            .navigationTitle(BaPresentedSheet.about.title)
    }
    .environment(BaAppModel.live())
}
