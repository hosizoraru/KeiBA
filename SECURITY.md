# Security Policy

## Reporting

Report security issues through GitHub private vulnerability reporting:

[Open a private vulnerability report][private-report].

If private reporting is unavailable, open a minimal issue that asks for a
private contact path and keep exploit details out of public discussion.

## Scope

Security-sensitive areas include:

- Local settings and future synced user data.
- Notification and Live Activity payloads.
- Media cache paths and downloaded content handling.
- External URLs opened from GameKee-backed data.
- Build, signing, and dependency configuration.

## Dependency Policy

Dependencies are resolved through Swift Package Manager and pinned in
`Package.resolved`. Keep dependency updates small, review upstream release
notes, and run the build and test commands from `CONTRIBUTING.md` after
updates.

## User Data

KeiBAOS stores local gameplay companion settings and cached public guide data.
Future iCloud sync work should keep synced payloads narrow, documented, and
compatible with user-initiated reset or export flows.

[private-report]: https://github.com/hosizoraru/KeiBAOS/security/advisories/new
