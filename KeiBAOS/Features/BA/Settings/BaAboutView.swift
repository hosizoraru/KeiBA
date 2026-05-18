//
//  BaAboutView.swift
//  KeiBAOS
//
//  Created by Codex on 2026/05/18.
//

import SwiftUI

struct BaAboutView: View {
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
            BaGameAssetIcon(.schale, size: 64)
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("KeiBAOS")
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
        ForEach(AppPlatformBaseline.allCases) { baseline in
            Label {
                LabeledContent(baseline.displayName) {
                    Text(baseline.minimumVersion)
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: baseline.systemImage)
                    .foregroundStyle(.tint)
            }
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
            url: URL(string: "https://github.com/hosizoraru/KeiBAOS")
        )

        BaAboutLinkRow(
            title: BaL10n.string("ba.about.data.releases.title"),
            detail: BaL10n.string("ba.about.data.releases.detail"),
            url: URL(string: "https://github.com/hosizoraru/KeiBAOS/releases")
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
}
