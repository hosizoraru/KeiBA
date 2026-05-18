# KeiBAOS

[![CI][ci-badge]][ci-workflow]

KeiBAOS is a native SwiftUI companion app for Blue Archive players on
Apple platforms. It focuses on AP tracking, cafe AP, activity schedules,
recruitment pools, student guide data, Live Activities, and memory-lobby
music in an Apple-native interface.

## Status

KeiBAOS is in active development. The current app target supports iOS,
iPadOS, and macOS 26. The data model is being shaped with future iCloud
sync and a planned watchOS 26 companion surface in mind.

## Platform Baseline

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+
- watchOS 26.0+ planned companion target
- Xcode 26+
- SwiftUI, Swift Concurrency, Observation, Swift Package Manager

## Features

- Office overview for AP, cafe AP, daily reset timing, and player identity.
- Activity and recruitment-pool timelines with local notifications and
  Live Activities.
- Student catalog with search, sorting, implemented-student filters, and
  NPC or satellite filters.
- Student detail pages with profile, skills, weapon data, gallery media, and
  voice lines.
- Music page for favorite students' memory-lobby BGM with cache and system
  media controls.
- Local user data prepared for future multi-device sync.
- English, Japanese, and Simplified Chinese localization surfaces for core UI
  and BA terms.

## Repository Layout

```text
KeiBAOS/                App source, feature modules, localization, app assets
KeiBAOSLiveActivities/  Widget extension for Live Activities and Dynamic Island
KeiBAOSShared/          Types shared by the app and extension
KeiBAOSTests/           Unit tests for parsing, settings, notifications,
                        media, and layout
Docs/                   Project notes and feature coverage
scripts/                Local maintenance scripts
```

## Dependencies

Swift Package Manager resolves packages through the Xcode project:

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework][vorbis-binary-xcframework]

`Package.resolved` is committed so local builds and CI use the same dependency
revisions.

## Build

Open `KeiBAOS.xcodeproj` in Xcode 26 or newer, select the `KeiBAOS` scheme,
then build for an iOS 26 simulator, iPadOS 26 simulator, or macOS 26.

Command-line build examples:

```sh
xcodebuild build \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'generic/platform=iOS Simulator'

xcodebuild build \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'generic/platform=macOS'
```

## Tests

Run the full unit test target from Xcode, or use macOS for a fast parser and
domain-logic pass:

```sh
xcodebuild test \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'platform=macOS'
```

Focused catalog-filter tests:

```sh
xcodebuild test \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'platform=macOS' \
  -only-testing:KeiBAOSTests/BaCatalogFilterTests
```

## CI

GitHub Actions runs localization validation, iOS simulator build, macOS build,
and macOS unit tests on `macos-26`.
See [.github/workflows/ci.yml](.github/workflows/ci.yml).

Pushes to `main` and manual workflow runs also upload side-load test artifacts:

- `KeiBAOS-iOS-<version>-unsigned.ipa` is an unsigned iOS device payload. It needs
  re-signing with a valid Apple certificate and provisioning profile before
  installation on a physical device.
- `KeiBAOS-macOS-<version>-unsigned.dmg` is an unsigned, unnotarized
  macOS build for local smoke testing.

The IPA and DMG are uploaded as separate workflow artifacts so testers can
download only the platform package they need.

## Versioning

KeiBAOS keeps Apple bundle versions and CI artifact names separate:

- `MARKETING_VERSION` / `CFBundleShortVersionString` uses a three-part release
  version such as `1.0.0`.
- `CURRENT_PROJECT_VERSION` / `CFBundleVersion` uses the repository commit count
  as the numeric build version in CI.
- CI artifact names add git metadata for non-tagged builds, for example
  `1.0.1-162.g6d0c346`, while the app bundle keeps Apple-compatible values.

The CI version resolver reads the latest merged semantic tag (`v1.2.3` or
`1.2.3`). Tagged builds use that release version. Builds after a tag use the
next patch version and append the commit distance plus short SHA to the artifact
name.

## Data And Assets

KeiBAOS fetches public Blue Archive guide data from GameKee pages and APIs.
Blue Archive names, artwork, music, voice lines, and related game assets
belong to their respective rights holders.

## Privacy

The app stores user preferences locally today, including office settings,
favorites, cached media metadata, and notification preferences. Future iCloud
sync work should keep account-level preferences portable across Apple devices.

## License

License selection is pending. Until a license is added, all rights are
reserved by the repository owner.

[ci-badge]: https://github.com/hosizoraru/KeiBAOS/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/hosizoraru/KeiBAOS/actions/workflows/ci.yml
[vorbis-binary-xcframework]: https://github.com/sbooth/vorbis-binary-xcframework
