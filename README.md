# KeiBA

[![CI][ci-badge]][ci-workflow] ![Platforms][platforms-badge] ![Swift][swift-badge]

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

KeiBA is a native Apple-platform companion app for Blue Archive players. It
brings daily resource tracking, event timelines, student guide data, music,
notifications, widgets, Live Activities, and Apple Watch glances into one
Apple-native app for iPhone, iPad, Mac, and Apple Watch.

Blue Archive is often shortened to BA in global community discussion, while
Japanese players commonly say "Blue Archive" or "Buruaka" (`ブルアカ`). The
localized READMEs keep those regional naming habits in mind instead of treating
the project as a literal translation exercise.

The project is in active development and is aimed at modern Apple operating
systems. The main app targets iOS, iPadOS, and macOS 26. The watchOS companion,
WidgetKit surfaces, and Live Activities are kept in the same repository and are
part of the normal local and CI verification path.

## Highlights

- Track AP, Cafe AP, daily reset timing, cafe visits, headpat and invite
  cooldowns, Tactical Challenge timing, teacher identity, and per-server office
  profiles.
- Browse current and upcoming activities and recruitment pools from public Blue
  Archive guide data.
- Search and inspect student, NPC, and satellite guide entries, including
  profiles, skills, weapon data, gallery media, and voice lines.
- Play favorite memory-lobby music with local audio caching and system media
  controls.
- Schedule local reminders and expose relevant progress through Live Activities
  and Dynamic Island.
- Use iOS and watchOS widgets for quick AP, Cafe AP, activity, and recruitment
  glances.
- Sync compact dashboard snapshots from iPhone to Apple Watch through
  WatchConnectivity.
- Keep English, Japanese, and Simplified Chinese UI/localization surfaces close
  to Blue Archive terminology.

## Platform Coverage

| Surface | Status | Notes |
| --- | --- | --- |
| iPhone | Active | Primary daily-use surface for overview, catalog, music, notifications, widgets, and Live Activities. |
| iPad | Active | Shares the main app target with layouts adapted for larger windows and pointer or keyboard workflows. |
| Mac | Active | Built from the main app target with macOS toolbar, sidebar, keyboard, pointer, and window behavior in mind. |
| Apple Watch | In development | Companion dashboard, Smart Stack widgets, notification status, and compact AP/timeline glances. |
| Widgets | Active | iOS dashboard widgets and watchOS Smart Stack widgets read a shared dashboard snapshot. |
| Live Activities | Active | Reminder progress appears on the Lock Screen and Dynamic Island where supported. |

## Repository Layout

| Path | Purpose |
| --- | --- |
| `KeiBA/` | Main app source, BA feature modules, shared UI, app assets, localization, and support code. |
| `KeiBAShared/` | Types shared by the app and Live Activities extension. |
| `KeiBALiveActivities/` | Widget extension for Live Activities, Lock Screen, and Dynamic Island presentation. |
| `KeiBAiOSWidgets/` | iOS WidgetKit dashboard widgets. |
| `KeiBAWatch/` | watchOS companion app. |
| `KeiBAWatchShared/` | Codable dashboard snapshot models shared by iPhone, Watch, and widgets. |
| `KeiBAWatchWidgets/` | watchOS WidgetKit / Smart Stack extension. |
| `KeiBATests/` | Parser, settings, notification, media, widget, watch snapshot, and layout unit tests. |
| `Docs/` | Feature coverage, platform roadmap, interop notes, widget setup, and performance baselines. |
| `scripts/` | Local and CI maintenance scripts. |

## Requirements

| Tool or platform | Baseline |
| --- | --- |
| Xcode | Xcode 26.5 or newer for local development. |
| SDKs | iOS 26.5, iOS Simulator 26.5, macOS 26.5, and watchOS 26.5. |
| Deployment targets | iOS 26.0+, iPadOS 26.0+, macOS 26.0+, watchOS 26.0+. |
| Project format | Xcode 26.3 project format, `objectVersion` 100. |
| Language stack | Swift, SwiftUI, Swift Concurrency, Observation, WidgetKit, ActivityKit, App Intents, WatchConnectivity, and Swift Package Manager. |

Swift package dependencies are resolved through the Xcode project and pinned in
`Package.resolved`:

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework][vorbis-binary-xcframework]

## Build Locally

Open `KeiBA.xcodeproj` in Xcode 26.5 or newer, select the `KeiBA` scheme, and
run on an iOS 26 simulator, iPadOS 26 simulator, macOS 26, or a signed physical
iOS/iPadOS device. Select `KeiBAWatch` to build the watchOS companion.

Command-line examples:

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

Release install on a connected iPhone or iPad from Xcode:

1. Select the `KeiBA` scheme and the physical device.
2. Open `Product > Scheme > Edit Scheme...`.
3. Select `Run > Info`, set `Build Configuration` to `Release`, then close the
   sheet.
4. Confirm `Signing & Capabilities` has the Apple team selected for the app,
   Widget/Live Activities extension, Watch companion, and Watch widget
   extension.
5. Use `Product > Run` to build, sign, install, and launch the Release build.

For a distributable build, select `Any iOS Device (arm64)`, use
`Product > Archive`, then distribute from Organizer with the appropriate Apple
signing method.

## Test And Validate

Fast local checks:

```sh
jq empty KeiBA/Localizable.xcstrings
jq empty KeiBALiveActivities/Localizable.xcstrings
jq empty KeiBAWatch/Localizable.xcstrings
jq empty KeiBAWatchWidgets/Localizable.xcstrings
git diff --check
```

Unit test pass:

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

For visible UI changes, verify on the relevant simulator or device and attach
screenshots or recordings to the pull request. The local agent workflow for this
checkout uses the Build iOS Apps simulator browser mirror with:

- project: `KeiBA.xcodeproj`
- scheme: `KeiBA`
- bundle id: `os.kei.KeiBA`
- simulator: `iPhone 17 Pro`

## Continuous Integration

GitHub Actions runs localization validation, iOS simulator build and tests,
watchOS simulator builds, macOS build and tests, focused Watch/widget snapshot
tests, user-data sync tests, and unsigned packaging jobs on `macos-26`.

Pushes to `main` and manual workflow runs upload side-load test artifacts:

- `KeiBA-iOS-<version>-unsigned.ipa`
- `KeiBA-macOS-<version>-unsigned.dmg`

These artifacts are unsigned and intended for local smoke testing or later
re-signing. They are not notarized, TestFlight-ready, or App Store-ready
deliverables.

Documentation-only and GitHub community-file changes are path-filtered so they
do not spend CI minutes on app builds.

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

## Data And Privacy

KeiBA reads public Blue Archive guide data from GameKee pages and APIs. Blue
Archive names, artwork, music, voice lines, and related game assets belong to
their respective rights holders.

The app stores user preferences locally today, including office settings,
favorites, cached media metadata, Watch dashboard snapshots, synced duty-avatar
thumbnails, widget dashboard snapshots, and notification preferences. Future
iCloud sync work should keep account-level preferences portable, narrow, and
user-resettable across Apple devices.

See [SECURITY.md](SECURITY.md) for vulnerability reporting and
[SUPPORT.md](SUPPORT.md) for useful issue-reporting details.

## Contributing

Contributions should stay small, platform-aware, and easy to review. Start with
[CONTRIBUTING.md](CONTRIBUTING.md), include the exact validation commands you
ran, and attach simulator or device captures for visible UI changes.

Useful project notes:

- [BA feature coverage](Docs/BAFeatureCoverage.md)
- [Platform features roadmap](Docs/Platform-Features-Roadmap.md)
- [SwiftUI / UIKit / AppKit interop plan](Docs/SwiftUI-UIKit-AppKit-Interop-Plan.md)
- [Widget extension setup](Docs/Widget-Extension-Setup.md)
- [Performance baselines](Docs/Performance-Baselines.md)

## License

License selection is pending. Until a license is added, all rights are reserved
by the repository owner.

[ci-badge]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml
[platforms-badge]: https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-0a7ea4
[swift-badge]: https://img.shields.io/badge/Swift-6-orange
[vorbis-binary-xcframework]: https://github.com/sbooth/vorbis-binary-xcframework
