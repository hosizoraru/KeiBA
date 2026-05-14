# KeiBAOS

KeiBAOS is a SwiftUI companion app for Blue Archive players on Apple platforms. It focuses on AP tracking, cafe AP, activity schedules, recruitment pools, student guide data, and voice/media browsing with a Liquid Glass inspired interface.

## Platform

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+
- visionOS 26.0+

The app target uses SwiftUI, Swift Concurrency, Swift Package Manager dependencies, and Xcode generated Info.plist settings.

## Features

- Overview dashboard for BA status and reminders
- Activity and recruitment pool timelines
- Student catalog and student detail pages
- GameKee-backed guide data parsing
- Remote image and audio caching
- OGG/Vorbis voice playback support through packaged SwiftPM dependencies
- Local BA settings for AP, cafe AP, visit, and activity reminder preferences

## Dependencies

Swift Package Manager resolves these packages through the Xcode project:

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework](https://github.com/sbooth/vorbis-binary-xcframework)

`KeiBAOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` is committed so app builds resolve the same dependency revisions.

## Build

1. Open `KeiBAOS.xcodeproj` in Xcode 26 or newer.
2. Select the `KeiBAOS` scheme.
3. Build and run on an iOS 26, macOS 26, or visionOS 26 target.

Command-line build example:

```sh
xcodebuild -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'generic/platform=iOS Simulator' build
```

## Tests

Run the unit test target from Xcode, or use:

```sh
xcodebuild test -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Data And Assets

KeiBAOS fetches public Blue Archive guide data from GameKee pages and APIs. Blue Archive names, artwork, and related game assets belong to their respective rights holders.

## License

License selection is pending.
