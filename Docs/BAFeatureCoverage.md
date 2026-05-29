# BA Feature Coverage

更新日期：2026-05-29

This document tracks the BA-only migration from the KeiOS Android BA module into the native SwiftUI app. It keeps the current iOS surface honest before the iPadOS and macOS layout pass.

## References

- Apple design baseline: native `TabView`, `NavigationStack`, `toolbar`, sheets, menus, lists, forms, and restrained Liquid Glass content surfaces.
- Game reference: Blue Archive Cafe guides document passive AP, cafe rank capacity, 04:00/16:00 cafe visits, 3h affection taps, and 20h cafe invitation cadence.
- Android source baseline: `/Users/voyager/voyager space/androidGit/KeiOS/app/src/main/java/os/kei/ui/page/main/ba` and `/Users/voyager/voyager space/androidGit/KeiOS/app/src/main/java/os/kei/ui/page/main/student`.

## Coverage Matrix

| Feature | KeiOS Android baseline | Swift model/service | Swift UI entry | Persistence | Test coverage | Status |
| --- | --- | --- | --- | --- | --- | --- |
| AP current/limit | `BaPageMath`, `BASettingsStore`, `BaOverviewCard` | `BaAppSettings`, `BaServerProfile`, `BaTimeMath.currentAP` | Overview AP card, Settings resources | `BaSettingsEnvelope.serverProfiles` per server | `testAPMathUsesSixMinuteRecovery`, settings round trip | Migrated |
| AP threshold | `KEY_AP_NOTIFY_THRESHOLD`, notification settings sheet | `BaServerProfile.apNotifyThreshold` | Overview AP tile, Settings resources | Per-server profile | settings round trip | Migrated preference |
| Cafe AP storage | `KEY_CAFE_STORED_AP`, `KEY_CAFE_LAST_HOUR_MS`, `BaCafeCard` | `BaServerProfile.cafeApCurrent`, `cafeStorageBaseAt`, `BaTimeMath.currentCafeAP` | Overview Cafe card | Per-server profile; one shared Cafe AP bucket per server | `testCafeAPStorageUsesSingleSharedCafeBucket` | Migrated |
| Cafe rank | `KEY_CAFE_LEVEL`, cafe level popup | `BaServerProfile.cafeLevel` | Overview Cafe card, Settings stepper | Per-server profile | settings migration and round trip | Migrated |
| Student visit | `nextCafeStudentRefreshMs`, cafe visit notification | `BaTimeMath.nextCafeStudentRefresh` | Overview Cafe metric | Per-server notification state | `testHeadpatCooldownRespectsCafeStudentRefreshBoundary` | Migrated display/preference |
| Headpat | `KEY_COFFEE_HEADPAT_MS`, `calculateHeadpatAvailableMs` | `BaServerProfile.lastHeadpatAt`, `BaCafeActionKind.headpat` | Overview BA action tile | Per-server profile | headpat boundary test | Migrated |
| Invite ticket 1 | `KEY_COFFEE_INVITE1_USED_MS` | `BaServerProfile.lastInviteTicket1At` | Overview BA action tile | Per-server profile | invite cooldown test, v1 migration | Migrated |
| Invite ticket 2 | `KEY_COFFEE_INVITE2_USED_MS` | `BaServerProfile.lastInviteTicket2At` | Overview BA action tile | Per-server profile; v1 defaults ready | invite cooldown test, v1 migration | Migrated |
| Tactical Challenge | `nextArenaRefreshMs`, arena notification | `BaTimeMath.nextArenaRefresh`, `arenaRefreshNotificationsEnabled` | Overview Cafe metric, Settings notifications | Per-server profile | settings round trip | Migrated display/preference |
| Server identity | `BaIdSettingsAccessor`, `id_independent_by_server` | `BaGlobalSettings.identityIndependentByServer`, `BaServerProfile.nickname/friendCode` | Overview identity card, Settings identity | Shared or per-server via envelope normalization | migration and per-server profile tests | Migrated |
| Activity calendar | `BaCalendarPoolRepository`, `/v1/activity/page-list` | `BaActivityPoolRepository`, `BaActivityEntry` | Activity tab, Overview summary tile | Codable cache per app data; global display prefs | parser tests | Migrated shell/data |
| Recruitment pools | `BaCalendarPoolRepository`, `/v1/cardPool/query-list` | `BaActivityPoolRepository`, `BaPoolEntry` | Pool tab, Overview summary tile | Codable cache per app data; global display prefs | parser and resolver tests | Migrated shell/data |
| Catalog | `BaGuideCatalogRepository`, trees by pid | `BaGuideCatalogRepository`, `BaGuideCatalogBundle` | Catalog tab | Codable cache, favorites set | catalog parser tests | Migrated shell/data |
| Student detail | `BaStudentGuideRepository`, `GuideFetchContentParser` | `BaStudentGuideRepository`, guide parsers | Student detail route | Codable detail cache | parser tests | Migrated shell/data |
| Voice | `GuideSectionVoice`, voice playback state | `BaGuideVoiceEntry`, `BaVoicePlaybackController` | Student detail Voice section | Audio cache | voice parser/playback tests | Migrated playback path |
| Media/gallery | `GuideFetchGallery`, gallery renderers, media save settings | `BaGuideGalleryItem`, media parsers | Student detail Gallery section | Detail/image/audio cache; media prefs | gallery parser tests | Migrated (preview, player, export complete) |
| Favorites | `BaGuideFavoriteBgm*`, catalog favorites | `BaGlobalSettings.favoriteContentIDs` | Catalog favorites category | Global settings | cache/settings tests through Codable | Partial, import/export later |
| Notification settings | BA notification dispatchers and settings sheet | `BaGlobalSettings`, `BaServerProfile` flags | Settings notification section | Envelope global/profile fields | settings round trip | Preference migrated; system scheduling later |

## Current iOS Priority

- Overview is the canonical iPhone BA home surface.
- Current server owns the visible state; switching server refreshes activity and pool state.
- Cafe AP is one bucket; invitation ticket 1 and ticket 2 are independent cooldowns.
- iPadOS and macOS reuse the responsive iPhone layout until the dedicated large-screen pass.
