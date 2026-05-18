# Contributing

Thanks for helping improve KeiBAOS. This project aims for a native
Apple-platform experience for Blue Archive companion workflows.

## Development Principles

- Follow Apple Human Interface Guidelines and Apple Developer Documentation
  for UI, platform behavior, concurrency, notifications, widgets, and
  Live Activities.
- Prefer SwiftUI-native APIs, Swift Concurrency, Observation, and small
  value-oriented models.
- Keep iOS, iPadOS, and macOS behavior intentional. Desktop flows should
  support toolbar, sidebar, keyboard, pointer, window resizing, and
  context menus.
- Keep changes scoped and easy to review. Split large UI or data changes into
  focused commits.
- Put user-facing strings in `KeiBAOS/Localizable.xcstrings`.
- Keep Blue Archive terms consistent across Simplified Chinese, Japanese, and
  English where localized UI exists.

## Local Setup

1. Install Xcode 26 or newer.
2. Open `KeiBAOS.xcodeproj`.
3. Select the `KeiBAOS` scheme.
4. Build for iOS Simulator, iPadOS Simulator, or macOS.

Command-line checks:

```sh
jq empty KeiBAOS/Localizable.xcstrings
git diff --check
xcodebuild build \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'generic/platform=iOS Simulator'

xcodebuild build \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'generic/platform=macOS'

xcodebuild test \
  -project KeiBAOS.xcodeproj \
  -scheme KeiBAOS \
  -destination 'platform=macOS'
```

## Pull Requests

Include:

- What changed and why.
- Screenshots or screen recordings for visible UI changes on the relevant
  platforms.
- The exact build and test commands you ran.
- Any remaining risk, manual QA gap, or data-source assumption.

## Data Source Work

Parser changes should include examples from real GameKee payloads when
practical, plus focused unit tests for edge cases. Keep fetch logic, parsing
logic, and display models separated so future iCloud and watchOS work can
reuse stable data.

## Notification And Live Activity Work

Keep notification categories, Live Activity attributes, App Intents, and widget
payloads aligned. Add debug paths only when they are clearly marked as test
tools and can be removed or hidden before release.
