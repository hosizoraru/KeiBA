# KeiBA Agent Notes

## Project Identity

- The app is named `KeiBA`.
- Prefer user-visible product naming as `KeiBA`; do not reintroduce `KeiBAOS` or legacy bundle/app-group compatibility unless the user explicitly asks.
- This is an Apple-platform app. Prefer AppKit/UIKit-backed hot paths where they are already established or clearly beneficial, with SwiftUI used as support and composition glue.

## Simulator Review In Codex

Prefer the Build iOS Apps plugin's in-browser simulator loop for interactive review. This keeps validation inside Codex while still using a real Apple Simulator.

### Browser Mirror Workflow

1. Check the active XcodeBuildMCP defaults before building or launching:

   ```bash
   # Via Build iOS Apps plugin:
   # session_show_defaults
   ```

2. Build, install, and launch the app on an isolated simulator for this project. For this checkout, the usual defaults are:

   - project: `KeiBA.xcodeproj`
   - scheme: `KeiBA`
   - bundle id: `os.kei.KeiBA`
   - simulator: `iPhone 17 Pro`

3. Start `serve-sim` scoped to the simulator UDID. Always kill only the same UDID, never use an unscoped kill because another Codex thread or project may be using a different simulator.

   ```bash
   SIM="<simulator-udid>"
   cleanup_serve_sim() {
     npx --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
   }
   trap cleanup_serve_sim EXIT INT TERM HUP
   cleanup_serve_sim
   npx --yes serve-sim@latest "$SIM"
   ```

4. Open the exact local URL printed by `serve-sim`, normally `http://localhost:3200`, in the Codex in-app browser.

5. Verify a real app frame, not just the loaded preview shell. A useful proof screenshot should show:

   - the simulator device chrome, such as `iPhone 17 Pro iOS ...`
   - the app's current screen
   - the green `live` status from `serve-sim`

6. When interactive QA is needed, click or scroll through the browser mirror and capture another screenshot after a state change. Browser interaction should be treated as real simulator interaction.

7. Clean up when done:

   ```bash
   npx --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
   ```

   Also stop the launched app and shut down only the simulator used for this project. Do not disturb other booted simulators.

### SwiftUI Preview Hot Reload Boundary

The official Codex preview hot-reload path is meant for Swift Package-backed SwiftUI previews. This repo currently uses an Xcode project without a `Package.swift`, so do not force preview support by editing `.xcodeproj`, schemes, or build settings.

If the user wants preview hot reload in the future, first propose extracting a small, importable Swift Package target for stable UI surfaces such as BA overview, account cards, or settings. Then use the Build iOS Apps plugin's SwiftUI preview launcher against that package target.

### Open Source Components

- `serve-sim` powers the browser-streamed simulator: https://github.com/EvanBacon/serve-sim
- `SnapshotPreviews` is relevant for extracting SwiftUI previews and snapshot-style preview workflows: https://github.com/getsentry/SnapshotPreviews
