# Pull Request

## What Changed

-

## Why

-

## Verification

- [ ] `git diff --check`
- [ ] Documentation/community-file render check, if this is docs-only
- [ ] `jq empty KeiBA/Localizable.xcstrings`, if localized strings changed
- [ ] iOS simulator build, if app code or assets changed
- [ ] iOS simulator unit tests, if app behavior changed
- [ ] macOS build and unit tests, if app behavior changed
- [ ] watchOS simulator build, if watch targets changed
- [ ] Manual UI check, if visible UI changed

Docs-only changes may leave app build and test boxes unchecked when no source,
asset, project, dependency, script, or workflow behavior changed.

## Screenshots Or Recordings

Add iPhone, iPad, macOS, or Live Activity captures when the change affects UI.

## Risk

Call out data-source assumptions, platform-specific behavior, notification
behavior, or media playback impact.
