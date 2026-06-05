# KeiBA

[![CI][ci-badge]][ci-workflow]

KeiBA is a native SwiftUI companion app for Blue Archive players on
Apple platforms. It focuses on AP tracking, cafe AP, activity schedules,
recruitment pools, student guide data, Live Activities, and memory-lobby
music in an Apple-native interface.

## Status

KeiBA is in active development. The current app target supports iOS,
iPadOS, and macOS 26. A watchOS 26 companion app and WidgetKit glance
surfaces are in development and are already part of the local build and CI
verification path. The data model is being shaped with future iCloud sync and
lightweight cross-device surfaces in mind.

## Platform Baseline

Deployment targets:

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+
- watchOS 26.0+ companion target

Build baseline for the current project:

- Local Xcode: 26.5 (`17F42`)
- SDKs: iOS 26.5, iOS Simulator 26.5, macOS 26.5, watchOS 26.5
- Xcode Project Format: Xcode 26.3
- Project `objectVersion`: 100
- SwiftUI, Swift Concurrency, Observation, Swift Package Manager

## Features

- Office overview for AP, cafe AP, daily reset timing, and player identity.
- Activity and recruitment-pool timelines with local notifications and
  Live Activities.
- WidgetKit widgets for office resources, activities, and recruitment pools.
- Apple Watch companion app in development for office identity, AP, cafe AP,
  Smart Stack widgets, timeline highlights, notification status, connection
  state, and synced duty avatar.
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
KeiBA/                App source, feature modules, localization, app assets
KeiBALiveActivities/  Widget extension for widgets, Live Activities,
                        and Dynamic Island
KeiBAShared/          Types shared by the app and extension
KeiBAWatch/           watchOS companion app source and watch assets
KeiBAWatchShared/     Codable snapshot models shared by iPhone and Watch
KeiBAWatchWidgets/    watchOS WidgetKit extension for Smart Stack surfaces
KeiBAiOSWidgets/      iOS WidgetKit extension for Dashboard widgets
KeiBATests/           Unit tests for parsing, settings, notifications,
                        media, and layout
Docs/                   Project notes and feature coverage
scripts/                Local maintenance scripts
```

## Apple Watch Companion

The watchOS app is a lightweight companion surface for quick checks during the
day. It currently focuses on:

- Teacher identity, server-aware office naming, friend code, and duty student.
- AP and cafe AP values with local full-time calculation on the Watch.
- Activity and recruitment-pool glance summaries synced from the iPhone app.
- Smart Stack widgets for AP, cafe AP, activity, and recruitment highlights.
- Notification preference status and iPhone-Watch connection state.
- Duty-student avatar thumbnail sync through the shared dashboard snapshot.

The iPhone app owns the main settings and sends a compact Watch dashboard
snapshot through WatchConnectivity. The Watch app keeps the last received
snapshot locally and shares it with the watchOS widget extension through App
Groups, so recent AP and timeline data remain readable between syncs.

## Widgets

The WidgetKit extension currently provides:

- Office Resources: AP, cafe AP, full-time hints, and compact Lock Screen or
  Smart Stack accessory variants.
- Events & Recruitment: featured activity and recruitment-pool highlights with
  running/upcoming counts.

The app writes the same lightweight dashboard snapshot to the App Group used
by the iOS widget extension and the watchOS widget extension. Widget timelines
refresh around AP regeneration, cafe AP hourly changes, and timeline boundary
dates, while app-side data changes request targeted WidgetKit reloads.

## Dependencies

Swift Package Manager resolves packages through the Xcode project:

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework][vorbis-binary-xcframework]

`Package.resolved` is committed so local builds and CI use the same dependency
revisions.

## Build

Open `KeiBA.xcodeproj` in Xcode 26.5 or newer, select the `KeiBA` scheme,
then build for an iOS 26 simulator, iPadOS 26 simulator, macOS 26, or an
iOS 26 device. Select the `KeiBAWatch` scheme to build the watchOS companion
for a watchOS 26 simulator.

Release install on a connected iPhone or iPad from Xcode:

1. Select the `KeiBA` scheme and the physical device in the destination menu.
2. Open `Product > Scheme > Edit Scheme...`.
3. Select `Run > Info`, set `Build Configuration` to `Release`, then close the sheet.
4. Confirm `Signing & Capabilities` has the Apple team selected for the app,
   Widget/Live Activities extension, Watch companion, and Watch widget
   extension.
5. Use `Product > Run` to build, sign, install, and launch the Release build on
   the device.

For a distributable build, select `Any iOS Device (arm64)`, use
`Product > Archive`, then distribute from the Organizer with the appropriate
Apple signing method.

Command-line build examples:

```sh
xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=iOS Simulator'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=macOS'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBAWatch \
  -destination 'generic/platform=watchOS Simulator'
```

## Tests

Run the full unit test target from Xcode, or use macOS for a fast parser and
domain-logic pass:

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS'
```

Focused catalog-filter tests:

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS' \
  -only-testing:KeiBATests/BaCatalogFilterTests
```

## CI

GitHub Actions runs localization validation, iOS simulator build, watchOS
simulator build, macOS build, macOS unit tests, focused Watch snapshot tests,
widget snapshot-sharing tests, and user-data sync tests on `macos-26`.
See [.github/workflows/ci.yml](.github/workflows/ci.yml).

Pushes to `main` and manual workflow runs also upload side-load test artifacts:

- `KeiBA-iOS-<version>-unsigned.ipa` is an unsigned iOS device payload with
  the embedded Watch app content. It needs re-signing with a valid Apple
  certificate and provisioning profile before installation on a physical device.
- `KeiBA-macOS-<version>-unsigned.dmg` is an unsigned, unnotarized
  macOS build for local smoke testing.

The IPA and DMG are uploaded as separate workflow artifacts so testers can
download only the platform package they need.

## Versioning

KeiBA keeps Apple bundle versions and CI artifact names separate:

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

KeiBA fetches public Blue Archive guide data from GameKee pages and APIs.
Blue Archive names, artwork, music, voice lines, and related game assets
belong to their respective rights holders.

## Privacy

The app stores user preferences locally today, including office settings,
favorites, cached media metadata, Watch dashboard snapshots, synced duty-avatar
thumbnails, widget dashboard snapshots, and notification preferences. Future
iCloud sync work should keep account-level preferences portable across Apple
devices.

## License

License selection is pending. Until a license is added, all rights are
reserved by the repository owner.

[ci-badge]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml
[vorbis-binary-xcframework]: https://github.com/sbooth/vorbis-binary-xcframework
