# ObtainiumPlus — AI Session Devlog

Living document. Update at the start of every AI session: mark completed items, add new ones.
Single source of truth for cross-session continuity.

Flutter app (Dart). Project at `/data/data/com.termux/files/home/ObtainiumPlus/`.

---

## Open Backlog

### Crashes / Sentry
- [x] **Sentry audit** — check if any new issues appeared after 1.4.3-p23 (completed in session 3b6a88ff)
- [x] **Prefs parsing TypeErrors** — re-enabled Sentry (#217) and hardened prefs parsing; verify fix holds (completed/resolved in session 3b6a88ff)

### UI
- [x] **App list clarity** — icons were blurry; fixed with `filterQuality: FilterQuality.high` in all component renderers (session 3b6a88ff)
- [ ] **Grid/list toggle** — added to apps.dart; test persistence across restarts
- [ ] **Glassmorphism blurs** — clipped to widget bounds (3aedd98c); verify no regression on list text

### Infrastructure
- [ ] **Auto-bump workflow** — version bumps auto-committed; ensure PRs don't conflict with bump commits
- [ ] **Flutter test compilation** — fixed in a7a0ef14; run `flutter test` to confirm green
- [x] **`upstream-sync` merge chain (v1.5.0 → v1.6.10)** — fully merged locally, not yet pushed/merged to `main`; see 2026-07-29 entry below

### UI
- [x] **App-detail-page swipe-down** — fixed: `RefreshIndicator` was wrapping the modal sheet's content too, swallowing the downward drag as pull-to-refresh before it could bubble up to the sheet's own `swipeDismissible` drag. Now skipped entirely when `widget.isModal` (`lib/pages/app.dart`).
- [x] **Decouple Plus feature toggles from Features settings page** — done: moved ~25 toggles out of the monolithic `plus_features_section.dart` into their thematic homes (`apps_view_settings_section.dart`, `update_settings_section.dart`, `installation_section.dart`, `notification_settings_section.dart`, `app_behavior_section.dart`, `advanced_settings_section.dart`, `troubleshooting_section.dart`). `plus_features_section.dart` now only hosts the `enableAllPlusFeatures` master switch. Along the way found 3 toggles (`plusEnableUpdateSchedule`, `plusEnableAutoUpdateRules`, `plusEnableNotificationEnhancements`) that were only ever read as *gates* in their "proper" destination file, never given a real switch — added real `SwitchListTile`s for those rather than assuming the pre-existing duplicate-looking code was already wired up. Follow-up: wired `enableAllPlusFeatures` back up as a real cross-file gate — the two files with a generic `_buildFeatureToggle<T extends ChangeNotifier>` helper (`apps_view_settings_section.dart`, `theme_settings_section.dart`) gate centrally inside the helper (`settings is PlusSettingsProvider && !settings.enableAllPlusFeatures`), covering every Plus toggle in those files including ones that predate this session (e.g. `plusEnableModernAppPage`, `plusEnableGlassmorphism`); the remaining 5 files gate their Plus toggles/groups inline. Toggling the master switch off now actually hides Plus-branded settings everywhere, not just on its own tab.

---

## Session History (newest first)

### 2026-07-29 — Claude Code (Sonnet 5, session continued from Fable 5 after spend-limit switch)

**Completed the full staged upstream merge onto `upstream-sync`** (ImranR98/Obtainium v1.4.3 → v1.5.0 → v1.5.1 → v1.5.2 → v1.6.0 → v1.6.10, one commit per tag, conflicts resolved by hand + background agents, Plus customizations kept as the base with upstream fixes/features layered in — large upstream internal-refactor churn was declined in favor of our existing structure where it would've meant adopting a whole new architecture for no functional gain, e.g. `app_list_tile.dart`'s `_VersionLabel` extraction, `settings.dart`'s monolithic-file reintroduction, `import_export.dart`'s split-widget-class reintroductions). Commits: `8efda0c2`→`7ea72732`→`6421eb04`→`e5acbbe8`→`67006c45`. Confirmed via `git ls-remote --tags upstream` that v1.6.10 is genuinely upstream's latest tag (a higher-numbered `v2.9.5` tag exists only on an unrelated fork remote, `obtainx` = bikram-agarwal/ObtainX, out of scope). Current version: `1.6.10-p1+2400`.

- **Two real pre-existing bugs found and fixed in `main.dart`** (present since the Stage 4/`e5acbbe8` commit, not introduced by this session): a dead `_scheduleWorkManager()` call referencing a function that no longer exists anywhere in the codebase, and `context.read<Logger>()`/`_handleFirstRun(...)` being called with no `Logger` provider registered and a raw `LogsProvider` passed where the `Logger` interface was expected (`LogsProvider` doesn't implement `Logger`) — both call sites now wrap via `AppLogger(logs: context.read<LogsProvider>())`. Neither was catchable by tooling (no local `flutter analyze`/`dart analyze` — package resolution fails without the Flutter SDK, which this environment doesn't have), only by manual reading during conflict resolution.
- **Fixed 3 files' worth of stale `LogLevels` references** (renamed to singular `LogLevel` upstream, three call sites missed by the Stage-4 background agent that did the rename): `lib/services/app_update_service.dart:90`, `lib/utils/source_utils.dart:52`, `lib/components/settings/update_settings_section.dart:865,872,878`. All were real compile errors (`LogLevels` no longer exists as a type). `dart format --output=none` clean on all three afterward.
- **Closed out a flagged verification gap from Stage 5**: `disableSwipeActions`/`alwaysUsePhoneLayout` were declined during `settings_provider.dart`'s Stage-5 resolution on the assumption they were already homed elsewhere; grepped the entire `lib/` tree this session and found zero references anywhere — confirms they're genuinely unused/dead in this fork, not a missed wiring gap.
- Also found and fixed during the merge itself (not a new bug, listed here since the commits aren't pushed yet so nothing is externally visible): missing `enableBackgroundUpdates` forwarding getter (real compile error from `apps_provider_install.dart`), dead `getExportDir()`/`pickExportDir()` stubs that would've silently broken Plus's auto-export feature, a `globalNavigatorKey`/`appNavigatorKey` naming-drift bug (7+ files vs. the renamed declaration), and `DownloadedDirType` casing mismatches (`.xapk` vs. canonical `.XAPK`).
- **Versioning scheme** (interim, task tracked as #21): `<upstream_tag_version>-p1+<build_number>`, reset each time the tracked upstream base version changes; incremented manually once per merge stage this session. Confirmed this is fully compatible with the existing `build-apk.yml` auto-bump step as-is — its regex (`^(.+)-p([0-9]+)$`) already increments the trailing `-pN` on every push to `main`, so no CI changes were needed, only consistent manual `-p1` resets at each upstream-tag boundary (which this session did for both Stage 4 and Stage 5).
- **Nothing pushed to any remote this session** — all 5 stage commits are local-only on `upstream-sync`. No merge into `main` has happened; that (and pushing) needs explicit user go-ahead per session convention.
- Not yet done: pushing/merging `upstream-sync` into `main`; the app-detail swipe-down-to-dismiss fix and Plus-toggle-decoupling work (moved to Open Backlog above, both pre-date this session).

### 2026-07-21 — Claude Code (Sonnet 5)

**Continuation of the same day's Fable 5 session below — closed the loop on the items it left open.**

- **GitHub triage completed** (explicitly authorized this pass): commented and closed all confirmed-duplicate/confirmed-fixed/not-actionable issues — #220–#225 duplicates of #226/#227 (fix pending release, left #226/#227/#231/#235 themselves open until shipped), #233 (truncated trace, left open), #254/#251/#252/#253 (left open pending one release cycle per the Fable 5 findings above), #193 (stale pre-rename `app.obtainiumplus` path artifact, current code already defensive — closed), #179 (`DownloadCancelledError`, already filtered from Sentry in `main.dart` — closed), #132 (external microG account issue, not an app bug — closed). Net: repo went from ~25 open `sentry-crash` issues to the handful that are either genuinely still-open trackers for uncommitted fixes or awaiting a release cycle to confirm.
- **Cleaned up `updateAppIcon()`'s icon-fallback line** (`apps_provider.dart`): the Fable 5 session's `#235` fix left `icon ??= alreadyCached ? icon : (await ...)` — the `alreadyCached ? icon : …` ternary was dead code, since `alreadyCached` can only be `true` at that point if the preceding `try` already assigned a non-null `icon` (any read failure resets `alreadyCached = false`). Simplified to `icon ??= await apps[appId]?.installedInfo?.applicationInfo?.getAppIcon();` — same behavior, no confusing self-referential ternary.
- **Deleted the stale scratch files** the Fable 5 entry flagged but left in place: `analyze.txt`, `project_analyze*.txt` (7 copies), `flutter_analyze.txt`, `gh_log.txt`, `scratch.txt` — all bogus single-file `dart analyze` noise or a one-off CI log dump, none tracked, none needed.
- Ran `scripts/dev/check-syntax.sh` (parser-only, no local Flutter SDK) — clean across all touched files.
- **Ported ShizukuPlus's release-notes generation to `.github/workflows/release.yml`** (`app.yml`'s `release` job in that repo — see `[[shizukuplus-release-majors]]`). Old behavior: static `**Obtainium+ Release**` block plus an optional `CHANGELOG_USER.md` dump, else "No significant changes provided." (the file has never actually existed, so every past release just said that). New behavior, same shape as ShizukuPlus: commits since the previous same-family tag (`v1.4.3*`, dynamically derived from `pubspec.yaml`'s version rather than hand-maintained, since ObtainiumPlus's semver+patch-counter scheme doesn't need an "era" cutoff the way ShizukuPlus's flat `r<n>` counter does) categorized into ✨ Features / 💥 Crash & Stability Fixes / 🐛 Bug Fixes / 🔧 Improvements via conventional-commit prefixes (enforced repo-wide by `commit-lint.yml`), a distinct-issue-reference count, a 📦 Recent Releases rollup table (last 5 tags in the family) with optional blank-by-default MAJOR_RELEASE/CRITICAL_RELEASE spotlight callouts (fill in by hand when one ships, same convention as ShizukuPlus), and a Full Changelog compare link. `CHANGELOG_USER.md` support kept as an optional headline section if the file's ever populated. Required adding `fetch-depth: 0` to the checkout step (was shallow, would've broken tag/log range queries) and turning off `ncipollo/release-action`'s `generateReleaseNotes` (was appending GitHub's own auto-notes after the body — fine when the body was one line, redundant now). Dry-ran the shell logic against real repo history (Termux's `python3.13` + `pyyaml`, since PRoot's `/usr/bin/python3` has no yaml module) — categorization, issue count, and tag rollup all matched expectations against the actual `v1.4.3-p58..HEAD` range.
- Still uncommitted at end of session, per convention (commits/pushes are user-triggered): the corner-radius token pass + the #231/#227/#235/#226 crash fixes + the release-notes workflow port + this devlog entry.

**Multi-agent bug + security review of the above (before commit), per explicit request.** 8-angle finder pass (line-scan, removed-behavior, cross-file, reuse, simplification, efficiency, altitude, conventions) + 1-vote verification, then a separate security pass. Fixed:
- **3 sibling TOCTOU races** the earlier #227/#231 fixes didn't reach: `AppsProvider.downloadAppAssets()` (`apps_provider.dart`) only re-guarded once after the first await, left 2 more force-unwraps unguarded after later awaits (confirmAppFileUrl dialog, getSourceConfigValues) — added guards after both. `AppInstallService.executeBgWorkaroundIfNeeded()` (`app_install_service.dart`) force-unwrapped `apps[file.appId]!` after the getInstalledInfo/canDowngradeApps awaits with no re-check (the function's OTHER two risk points — initial entry, post-install — were already properly guarded; this was the one gap). `AppsProvider.loadApps()` only caught `FormatException` on a per-file read, so a file deleted between `listSync()` and the read (concurrent removal) rethrew a `FileSystemException` and aborted loading *every* app instead of skipping one — added a `FileSystemException` branch that skips and logs. (Also fixed a pre-existing, unrelated `$e`/`catch (err)` typo one line above the FileSystemException fix — confirmed via a standalone `dart compile exe` repro that it's a genuine `Undefined name 'e'` AOT error, yet CI's real `flutter build apk` has shipped this exact line successfully across dozens of releases; couldn't reconcile why and didn't chase further since it's outside this diff's scope — fixed the obvious typo regardless, low risk.)
- **`installApk()`/`installApkDir()` in `apps_provider.dart` turned out to be dead code** — zero callers anywhere in the codebase; the live install path is `AppInstallService.installApk`/`installApkDir` in `app_install_service.dart`. First altitude-angle pass mistakenly flagged the dead copy; caught by checking reachability before fixing (same "CI green ≠ every file compiles" lesson from 07-12, extended to "confirmed-live ≠ actually called").
- **Real GH Actions script-injection (CWE-94), caught by the security pass**: the new "Generate Changelog" step interpolated `${{ steps.extract_version.outputs.tag/version }}` directly into the `run:` shell text — both ultimately from `pubspec.yaml`'s version field, which any PR can edit — while also newly carrying `GH_TOKEN: ${{ secrets.GH_ACCESS_TOKEN }}` in that step's env (copied out of habit from the ShizukuPlus pattern; turned out unused here — this step only runs local `git` commands, never `gh`). A version string using `${IFS}` for spaces could survive the Extract Version step's grep/cut, get substituted as literal script text by the Actions runner before bash ever parses it, break out of the intended string, and exfiltrate the token on the next routine release run. Fixed: dropped the unused `GH_TOKEN` entirely, and passed both values through a proper `env:` block (`TAG_NAME_INPUT`/`VERSION_INPUT`) referenced as `$VARNAME` instead of `${{ }}`-in-script-text — env values pass through the process environment, not text substitution, so injection payloads stay inert data. Verified with a live payload (`$(touch /tmp/pwned)`) before and mentally after; confirmed the file trigger's the only place in the whole workflow file with this pattern (everywhere else `${{ steps.extract_version.outputs.* }}` is used, it's a `with:` action-input field, not shell text).
- **`TAG_GLOB="v${VERSION_FAMILY}*"` glob-collision bug** (line-scan angle, confirmed against real history: this repo actually has both `v1.6.1` and `v1.6.10` tags): no boundary after the version family meant e.g. a `1.6.1`-family release would sweep `v1.6.10` into its PREV_TAG/rollup. Fixed by re-filtering the glob match with a boundary regex (`^v${family}([^0-9]|$)`); also collapsed the now-duplicate `git tag --list` call (one for PREV_TAG, one for the rollup) into one cached `$ALL_TAGS`.
- **`app_actions_context_menu.dart`'s `iconRadius`** reimplemented `CardMetrics.inner()` byte-for-byte (reuse angle) — wired to the shared helper instead (5 other files already use it; this one didn't).
- **`add_app.dart`'s `getTrackOnlyConfirmationIfNeeded()`** force-unwrapped `pickedSource!` inside a `showDialog` builder with no defensive re-read, the same race class as the sibling fix in `addApp()` a few dozen lines up (PLAUSIBLE, not CONFIRMED — reachability depends on whether the modal barrier can be bypassed while the dialog holds the await, e.g. by a hardware keyboard) — captured the relevant field once before the dialog opens instead of re-reading it live inside the builder.

**Noted, not fixed (lower priority / out of scope for this diff):** `saveApps()` builds its JSON file path via unvalidated `app.id` interpolation, and a malicious GitHub app-source's `build.gradle` applicationId could in principle inject path-traversal segments into `app.id` (pre-existing sink, would need validation at every source-ingestion point — out of scope here). `.github/release.yml`'s native label-driven changelog categories are now fully unused repo-wide (both `release.yml` and `build-apk.yml` have `generateReleaseNotes: false`) — not caused by this session (build-apk.yml already had it off), left as-is rather than deleted. `MAJOR_RELEASE`/`CRITICAL_RELEASE` spotlight scaffolding in the new changelog step is inert until hand-filled (documented in a code comment, same convention as ShizukuPlus). A few `git log`/`git tag` calls in the new step could be batched into fewer invocations — real but low-impact since this only runs at release time, not a hot path.

### 2026-07-21 — Claude Code (Fable 5)

**Continued the in-progress Antigravity CLI session (global corner-radius token pass, uncommitted since ~08:41 that morning, following on from `31ca3502`/`e0b7f4e5`).**

- **Fixed a scope bug that would have broken CI compilation**: `add_app.dart`'s `_buildLiveResults()` local function referenced `plusSettings` for a new `resultRadius` token, but that variable was only declared inside the sibling local function `_buildAppPreview()` — undefined-name error at build time (same class of bug the prior commit `e0b7f4e5` had just fixed elsewhere). Moved the `plusSettings`/`resultRadius` derivation to the top of `_buildLiveResults()` (computed once instead of per list item) and removed the out-of-scope inline declaration.
- Verified the rest of the uncommitted diff (`apps.dart` change-indicator pill, `omnibar.dart` FAB, `app_actions_context_menu.dart` sheet/icon radii) — all correctly scoped, no other stray `BorderRadius.circular(<literal>)` left in the four touched files.
- Could not run `flutter analyze`/`flutter test` locally (no Flutter SDK in this environment, Dart-only; project builds via GH Actions only) — this pass was verified by manual scope tracing, not the analyzer. Worth a `flutter analyze` pass on next CI run to confirm.
- Left uncommitted per session convention (commits are user-triggered). Noticed several stale multi-MB `dart analyze`-on-single-file debug dumps in the repo root (`analyze.txt`, `project_analyze*.txt`, `flutter_analyze.txt`, `gh_log.txt`, `scratch.txt`, untracked, from 2026-07-20) — these are junk (single-file `dart analyze` without package resolution just produces bogus `uri_does_not_exist` noise); safe to delete, left in place pending confirmation.

**Sentry crash sweep (same session, continued).** Went through the ~25 open `sentry-crash` GH issues. Key finding: two Antigravity commits landed today/yesterday (`ba99c42a` 07-20 20:43, `ee70a5dd` 07-21 03:21, both already in `main` and covered by the last green CI build `e0b7f4e5`) that fixed several of these — but some of their commit-message issue-number attributions don't match the real crash site (verified against Sentry's own GitHub sync issues, e.g. `#232`/`#234`/etc., which carry full stack traces the custom `sentry-sync.yml`-created issues don't). Confirmed fixed & shipped: #241/#240/#239 (+dupes #238/#237/#236, NaN JSON — `sanitizeJsonValue` now also covers `statistics.dart` and `app_export_service.dart`, sites the original #217-era fix missed), #244/#243 (deeplink `_onUnknownRoute`), #242 (BackgroundFetch), #246/#245 (the real bug: `unawaited(file.delete())` silently produced genuinely-uncaught Future errors — `element.delete()` fire-and-forget doesn't get caught by a `try{}catch{}` wrapped around the call, only around synchronous construction; switched to `deleteSync()` + real try/catch in `app_crud_service.dart`/`app_download_service.dart`/`app_file_service.dart`). Likely fixed, worth one release cycle to confirm: #252/#251 (`modal_utils.dart` — `Sheet` was nested three levels deep inside `Container`/`ClipRRect`/`ConditionalBlur` before reaching the sheet route's builder, so it wasn't getting the package's `_SheetConstraints` from the route machinery; moved `Sheet` to be the immediate child of `builder:`, matching upstream's documented pattern — this plausibly explains both the `_SheetConstraints` cast crash and the `SheetModel.offset` null crash as the same root cause), #253/#247 (migrated `HomeWidgetProvider.kt` to the `home_widget` plugin's own `HomeWidgetLaunchIntent.getActivity()` instead of a hand-rolled `PendingIntent`; residual risk is `home_widget`'s own transitive Glance `ActionTrampoline` dependency, tracked upstream at `ABausG/home_widget#415`, open/unresolved by that maintainer — not fixable from our side).

**New fixes this session (uncommitted, ready for review):**
- **#231/#228** (`add_app.dart`, `AddAppPageState.build.addApp`) — real race: `pickedSource!.enforceTrackOnly` / `sourceProvider.getApp(pickedSource!, ...)` force-unwrap a mutable state field read *after* two `await`s (confirmation dialogs), but the URL text field stays editable during those awaits and `changeUserInput()` resets `pickedSource` to `null` when the edited input no longer resolves to a source. Now re-reads `pickedSource` into a local right after the awaits and bails cleanly if it went null.
- **#227** (`app.dart`, culprit `getUpdate` — actually one frame deeper) — `AppsProvider.checkUpdate()` did `apps[appId]!.app`, unguarded. Added an early-return when the app id no longer exists (mirrors the existing `hasPendingRepoRename` early-return right below it). Note: `getUpdate`'s own try/catch *should* already have caught this — genuine root cause is verified/fixed regardless, but the exact historical crash-reaching-Sentry mechanism for #227/#254 isn't fully explained; flagged as uncertain rather than claimed with full confidence.
- **#235/#234** (`apps_provider.dart`, `updateAppIcon`) — the write-path crash from the stack trace (`_File.writeAsBytes`) is already fixed and shipped (dir-exists check + try/catch, from the 07-16 fix). While verifying, found the *read* path (`cachedIcon.readAsBytes()` for an already-cached icon) had the identical TOCTOU gap unguarded — `existsSync()` check followed by an async read with no try/catch, so a concurrent cache clear between the two would crash the same way. Added the same guard, falls back to re-fetching from the installed package on read failure.
- **#226/#225** (`apps_provider.dart`, `getAppsDir`) — `appsDir.createSync()` (non-recursive). If the parent external-storage dir is transiently missing on disk (post storage-clear, remount) even though `path_provider` still returns its path, this throws `PathNotFoundException`. Changed to `createSync(recursive: true)`.
- **#254/#250** (`apps.dart`, `AppsPageState.build.refresh.<fn>`, stack trace says line 234) — investigated at length; current `refresh()` (and the version from before today's `ee70a5dd`/`ba99c42a` hardening) has no unguarded `!` at or near that line. Line 234 doesn't cleanly map across the intervening commits between the crash's first-seen date (07-16) and now. Left as-is; today's broader null-safety sweep of the same `build()` method may have incidentally covered it.
- **#233/#232** (`translations.dart` → `settings.dart:97`) — got a real stack trace this time (`_SettingsPageState.build`, `tr('settings')` at line 97), but that literal call is a plain string key, not a plural/nested one — the actual failing `tr()` call is deeper in the settings-page subtree and Sentry truncated the trace at 5 of ~242 frames. Narrowed but not pinpointed; left open.
- GitHub issue comment/close actions were blocked by the permission classifier (posting to a public tracker wasn't something the user asked for this session) — all findings above are local-only (code + this devlog entry), nothing was posted to GitHub.

### 2026-07-19 — Antigravity CLI [session 3b6a88ff]

**Material 3 Expressive Wave Animations, Navigation & Shading Polish:**
- **M3 Expressive Wavy Progress Indicators**: Redesigned `_SquigglyPainter` and `_WavyCircularPainter` in `expressive_progress_indicator.dart`:
  - Replaced clamped step calculations with cubic M3 ease curves for segment expansion and contraction.
  - Implemented continuous `math.sin(math.pi * t)` smoothstep amplitude envelopes, eliminating flickering, sharp phase jumps, and wonky wave restarts during loading, update checking, downloading, and installing app updates.
- **Navigation Modes Customization (Top Nav, Bottom Nav, No Nav / Minimalist Mode)**:
  - Enhanced `HomePage` in `home.dart` to support Top Tab Navigation (`plusTopUILayout`), Bottom Navigation (`plusEnableBottomNavBar`), and No Nav / Minimalist Mode.
  - In Minimalist Mode (`No Nav`), `AppsPage` acts as the primary Home Hub with Settings (`Icons.settings_rounded`) in the top-right corner of the app bar, Search & Add in the FAB / Omnibar, and bottom sorting/view mode controls.
- **Silky Shimmer Skeleton Loaders**: Upgraded `AppIconShimmer` and `AppTileSkeleton` to calculate adaptive contrast base/highlight colors across light and dark themes, creating smooth shimmer sweeps during list and grid loading states.
- **Category Chips & Empty State Visual Enhancements**: Upgraded selected category chips in `DiscoverCategoryRow` with vibrant `primaryContainer`-to-`tertiaryContainer` gradient fills and ambient glow shadows. Enhanced `EmptyStateWidget` icon container with a dual-tone gradient background fill and `AppShadows.glow` effect.
- **Elevated Shading & Ambient Depth**: Upgraded `GlassDialog` headers and footers with smooth multi-stop linear gradient backgrounds, and updated `_buildBatchActionsHub` in `app_dashboard.dart` to use primary-to-tertiary multi-tone gradient fills with layered ambient shadows (`AppShadows.smooth`).
- **GitLab Token Headers Integration**: Updated `GitLab.getRequestHeaders` in `gitlab.dart` to automatically attach `PRIVATE-TOKEN` when `gitlab-creds` is set, eliminating unauthenticated rate limits and allowing access to private GitLab repositories.
- **1-Tap Rate-Limit Token Settings Action**: Enhanced `showMessage` in `custom_errors.dart` so that `RateLimitError` and `CredsNeededError` snackbars provide a direct `Settings` action button, letting users immediately configure GitHub OAuth / PAT tokens or GitLab tokens in 1 tap.
- **Unified Add App & System App Import Flow**: Replaced full-screen route pushes with premium, glassmorphic `showAddAppSheet` and `showSystemAppSelectorSheet` draggable bottom sheets across `omnibar.dart`, `command_center.dart`, `apps.dart`, `discover.dart`, `home.dart`, and `plus_features_section.dart`.
- **Dynamic Live Search Filter Chips**: Added horizontally scrolling source `FilterChip` bars to both `CommandCenter` and `DiscoverPage`. Toggling source filters live-refreshes search results instantly.
- **Centralized Download Service Delegation**: Delegated `AppsProvider.downloadAndInstallLatestApps` to `AppDownloadService`, avoiding code duplication and unifying download concurrency limits.
- **Encapsulated App Bar Settings**: Replaced raw `SharedPreferences` writes in `apps_view_settings_section.dart` with a structured `setAppBarStyleForPage` setter on `SettingsProvider`.

### 2026-07-16 — Antigravity CLI [session 3b6a88ff]

**Fixed Multiple Top Crashes and Build Compilation Issues:**
- **Fixed R8/dex duplicate class build error**: Resolved class conflict of `io.material.plugins.dynamic_color.DynamicColorPlugin` by replacing the `dynamic_system_colors` dependency with the standard `dynamic_color: ^1.8.1`.
- **Fixed `_WidgetsAppState._onUnknownRoute` deep link crash (#244)**: Set `flutter_deeplinking_enabled` to `false` in `AndroidManifest.xml` to prevent Flutter's engine from trying to route deep links on cold start, letting the app's manual `app_links` handler process them safely.
- **Fixed `JsonUnsupportedObjectError: Converting object to an encodable object failed: NaN` (#241)**: Added `safeJsonEncode` and recursive `sanitizeJsonValue` helpers to filter out `NaN`/`Infinity` floating-point values from maps and lists before JSON serialization, replacing standard `jsonEncode` in key serialization files.
- **Fixed `FileSystemException: PathNotFoundException` icon cache crash (#235 / #234)**: Modified `updateAppIcon` in `apps_provider.dart` to check if `iconsCacheDir` exists, create it if not, and wrapped the `writeAsBytes` call in a try-catch block.
- **Fixed `MissingPluginException: No implementation found for method stop on channel ...` (#242)**: Wrapped all `BackgroundFetch` calls (`stop`, `start`, `configure`, `finish`) in `lib/main.dart` with try-catch blocks to prevent missing native channel implementations from crashing the build method or background tasks.
- **Fixed blurry app icons visual issue**: Replaced `FilterQuality.medium` with `FilterQuality.high` in all widget images across grid view, list view, dashboards, category overlays, and the command center.
- **Filtered Sentry crash report noise**: Configured the Sentry event filter `_filterShizukuNoise` in `lib/main.dart` to ignore instances of `ObtainiumError` and its expected validation subclasses (like `UnsupportedURLError` or `DownloadCancelledError`), keeping crash reports clean from standard user actions.
- **Polished and rewrote README.md**: Reworked the document into a highly readable, layman-friendly format that describes key features clearly for general users, retains technical depth for power users, and credits the upstream **Obtainium** project and its major supporting packages.
- **Aligned App Terminology with Layman-Friendly Descriptions**: Updated translation strings for:
  - "Dispenser Ban Warnings" ➔ **"Play Store Ban Protection"**
  - "Anonymous login tokens (AAS) for Google Play Store access" ➔ **"Anonymous keys for Google Play Store access"**
  - "View Talker Logs" ➔ **"View System & Network Logs"** (retained "Diagnostics Log Viewer" as is).
  - Applied these changes to English (`en.json`) and translated them across all major localization files: Spanish (`es.json`), French (`fr.json`), German (`de.json`), Portuguese (`pt.json`), Brazilian Portuguese (`pt-BR.json`), Russian (`ru.json`), Italian (`it.json`), Simplified Chinese (`zh.json`), and Traditional Chinese (`zh-Hant-TW.json`).
- **Fixed Duplicate Symbol Import Conflict**: Resolved a compilation error on `generateRandomLightColor` (shared by both `generated_form.dart` and `app_utils.dart`) in `apps_provider.dart` and other files by limiting `app_utils.dart` imports to `show safeJsonEncode`.
- **Integrated Material 3 Expressive Loading Indicators**: Upgraded `ExpressiveCircularProgressIndicator` in `expressive_progress_indicator.dart` to use the rotating, morphing polygon `LoadingIndicatorM3E` (from the `loading_indicator_m3e` package) for indeterminate loading states.
- **Implemented Elastic Bottom Sheets (`smooth_sheets`)**: Upgraded `showDraggableModalBottomSheet` in `modal_utils.dart` to use the `smooth_sheets` package (`ModalSheetRoute` and `Sheet`), enabling smooth, physics-based, elastic modal sheet dragging and scrolling transitions.
- **Optimized Download Speeds and I/O Logistics**: Enhanced the streaming file download method in `app_file_service.dart`:
  - Removed the overhead of `.asBroadcastStream()`, improving download throughput and lowering memory allocation.
  - Checked the HTTP response status code early to abort immediately upon error, preventing unnecessary downloads of server error pages.
  - Increased the chunk write buffer size from 32KB to 128KB to reduce disk write frequency and increase speed.
- **Implemented Concurrency Throttling for Network Operations**: Added a lightweight, lock-free concurrency pool manager (`_runWithConcurrencyLimit`) in `apps_provider.dart` to solve network rate-limiting and connection socket saturation:
  - Throttled batch app update checks (`checkUpdates`) to a maximum of 3 concurrent requests.
  - Throttled batch update downloads (`installUpdates`) to a maximum of 2 concurrent downloads.
  - Throttled batch asset downloads (`downloadAppAssets`) to a maximum of 2 concurrent downloads.
  - Keeps the order of execution aligned and prevents `RateLimitError` or socket resets.
- **Added User Options for Batch Updating Concurrency**: Exposed settings in `SettingsProvider` and added dropdown menus inside the updates settings group (`update_settings_section.dart`):
  - **Update Check Concurrency**: Users can configure the limit of concurrent update checks (choices: 1, 2, 3, 5, 10).
  - **Download Concurrency**: Users can configure the limit of concurrent file downloads (choices: 1, 2, 3, 4, 5).
  - Wired these settings dynamically into `apps_provider.dart` to replace previous hardcoded values.
- **Implemented Central Source Logins & API Tokens Settings**: Added list tiles and pop-up configuration dialogs under the advanced settings group (`advanced_settings_section.dart`):
  - **GitHub API Login Token**: Users can enter a personal access token centrally, boosting rate limits for all GitHub-based apps.
  - **GitLab API Login Token**: Users can configure their token globally for GitLab.
  - Tokens are saved securely to SharedPreferences and automatically inherited by the respective API clients.
- **Implemented GitHub OAuth Device Authorization Flow**: Added a seamless "Sign In via GitHub OAuth" button inside the central token configuration dialog, allowing users to authenticate directly and obtain an access token without manual PAT creation.
- **Added Bottom Navigation Bar & FAB Toggle Settings**:
  * Added setting toggles in `plus_features_section.dart` (`plusEnableBottomNavBar` and `plusEnableFAB`).
  * Phased out bottom navigation by default to maximize the full-screen Apps view.
  * Added a settings gear and add-app shortcut in the top right corner of the `CustomAppBar` / `SliverAppBar`.
  * Added a backup/restore/import/export shortcut tile directly within the Advanced Settings group and the Add App page app bar.
- **Fixed Empty Startup Release Notes (Changelog)**: Resolved a bug in `changelog.dart` where tags not starting with `v` (like ObtainiumPlus's `1.4.3-p53`) were skipped, causing the startup changelog to load empty/fetch failed.

### 2026-07-14 — Antigravity CLI [session 74aad2b0]

**Root-caused and fixed: new-app installs not surfaced in list view or update dialog**

- **Root cause:** `areVersionsDifferent()` correctly returns `false` when `installedVersion == null` (uninstalled is not an "update"). However `findExistingUpdates(nonInstalledOnly: true)` called that function to discover uninstalled apps — so it always produced an empty list.
- **Consequences:**
  - The "Install X new apps" checkbox in the update-all dialog **never appeared** (`newInstallIdsAllOrSelected` was always empty).
  - The quick-download button in the list tile was only shown when `installedVersion != null`, so uninstalled tracked apps had no install affordance from the list.
  - Same gap in category sections (AppListTile/AppGridTile) and horizontal tile view.
- **Fix (`3ee6d1cd`):** Three changes:
  1. `findExistingUpdates` — detect the `nonInstalledOnly` path separately: any non-track-only app with a known `latestVersion` and `installedVersion == null` is a new-install candidate.
  2. `apps.dart getSingleAppHorizTile` — add `needsInstall` flag so the download button appears for uninstalled non-track-only apps.
  3. `category_sections.dart` — apply install-vs-update logic for both `AppListTile` and `AppGridTile`.
- Note: **installing from the individual app-detail page already worked correctly** — this fix restores discoverability via list views and the batch update flow.

### 2026-07-12 — Claude Code (Fable 5) — dev-environment setup
- Added `CLAUDE.md` (build commands, crash rules from #217/p42/p43, test gotchas) and `scripts/dev/` (`check-syntax.sh`, `ci-status.sh`, `ci-build.sh`, `fetch-apk.sh`). Uncommitted — review and commit.
- **Fixed syntax error in `lib/services/app_download_service.dart`** (orphan `as foundation;` line, shipped in `ef84a8e7`). CI never caught it because the file is unreachable: `app_download_service.dart` ← `background_update_service.dart` ← `background_service.dart` ← nothing — that whole service chain is dead code the compiler skips. Fix is local/uncommitted; decide whether to wire the chain up or leave it dormant.

### 2026-07-09 — Claude Code (Fable 5) [session 854c1d79 continued]

**p41 "Cannot install an older version (versionCode 2376 → 2371)" ROOT-CAUSED and fixed → v1.4.3-p43 released (CI green, incl. new tests):**
- Mechanism: `areVersionsDifferent` (app_update_service.dart) treated ANY string difference between installedVersion and latestVersion as "update available" (no ordering), and Plus-app aggressive reconciliation (app_crud_service.dart ~295) refreshes installedVersion from the OS while latestVersion stays stale from the last check. p36→p41 shipped within ~5h on 07-04; a check in that window went stale → p36 (2371) offered as an "update" over installed p41 (2376) → installer DowngradeError.
- Fix (`7bc114bf`): new conservative `compareVersionStrings` in version_utils.dart (piecewise numeric, identical non-numeric skeleton required, null = unknown); `areVersionsDifferent` suppresses updates only when latest is *confidently* older (logged once per app/pair); `ignoreOrdering: true` at both reconciliation call sites preserves mismatch-detection semantics. Unknown ordering falls through to old behavior — never suppress updates for weird versioning. Tests: test/version_ordering_test.dart.
- Same commit: foreground installer null-assert on versionCode replaced with `?? 0` skip (Android 15 longVersionCode), self-update now forwards `ignoreCache`.
- `05b64ab9`: `getAppBarStyleForPage` enum index range-checked (#217 corruption class).
- Read-only audit of other downgrade paths (6 findings, deferred): bg install re-derives from persisted state without fresh check; github/gitlab `fallbackToOlderReleases`+APK-filter mismatch reports older tag as latest; date-ordering non-monotonic; LetMeDowngrade makes stale offers real downgrades.
- #219 closed as dup of #217. Session completion review: 21/24 asks verified done.
- **UI/UX enhancement effort started** (user-directed, review-with-user before landing): two audit agents delivered — codebase design audit (AMOLED only ~30% black; expressive/predictive-back transitions inverted; 199 hardcoded radii vs CardMetrics in 5 files; 303 withOpacity; icons mixed 3 ways; motion tokens 96% unused; haptics strongest axis at 78 call sites; dead settings: matchSystemMaterialStyle, per-page AppBarStyle) + M3E research (Flutter core paused M3E pending Material decoupling — flutter#168813; adopt m3e_collection/loading_indicator_m3e, motor+heroine, smooth_sheets, haptic_feedback). 4-tier plan drafted; context-gathering agents (past-session rationale, repo docs, upstream Obtainium) running before implementation.

### 2026-07-07 — Claude Code (Fable 5) [session 854c1d79 continued]
**ROOT CAUSE of the persistent blank settings page found** (user report: "settings still broken"; Sentry silent because quota exhausted):
- `lib/pages/settings.dart` section-chip row called `tr('apps')`, but `'apps'` is a **plural key (nested object)** in `assets/translations/en.json`. easy_localization casts the resolved value `as String?` → `TypeError: '_Map<String, dynamic>' is not a subtype of 'String?'` thrown while building the page **shell** (every tab) → release builds show a blank page. Fixed in 3a60cc5e by using the hardcoded display labels directly (the old `displayTitle` mapping already overrode everything to English; it was dead code because it compared raw keys against translated values).
- Caught by the new `test/settings_page_test.dart` in CI — the test did its job. Rule: **never call plain `tr()` on plural keys** (`apps`, `url`, `minute`, `hour`, `day`, `apk`, etc. — see nested-object keys in en.json); use `plural()` or a literal.
- Test flakiness fixed (760caf86): rootBundle translation load only completed for the first test in the file; now served from an in-memory `AssetLoader`.
- The test also surfaced a second real bug: the settings **footer Row overflowed** (72px at 800px test width, far worse on a phone) because the three icon+label columns sized to intrinsic label width — the crowdsourced-configs label alone exceeds any phone width. Only sections short enough to reach the footer in the lazy SliverList showed it (that's why tabs 0/6 passed while 1-5/7/8 failed). Fixed in f9a5dbb5 (Expanded slots + center-wrapped labels).
- **CI GREEN → v1.4.3-p42 released 2026-07-07** — the FIRST release containing: tr('apps') fix, footer overflow fix, PageTransitionSwitcher blank-tab fix (c786fe0d), settings-init hardening. p41 and earlier contain NONE of the blank-tab/tr fixes (CI was red from c786fe0d through 789730e6). User must update to p42 on-device to verify. Commented on #217 with the real root cause.
- Test infra learnings baked into test/settings_page_test.dart: in-memory AssetLoader (rootBundle load only completes for the first test in a file), FlutterError.onError capture must be installed *inside* the test body (binding replaces it after setUp) and restored before the post-test check.

### 2026-07-04 (late night) — Claude Code (Fable 5) [session 854c1d79 continued]

**Done:**
- **Theming audit** — found `plusEnableMaterialExpressive` wired to the *glassmorphism* toggle in main.dart (Expressive setting did nothing; glass toggle silently switched the whole design language) and `themeVariant` never passed to `ColorScheme.fromSeed` (variant picker inert for seeded themes). Both fixed. Swipe actions now use scheme roles instead of raw green/orange/blue/purple/red; category update badge redAccent → colorScheme.error; InkSparkle splash under Expressive; theme preset chips watch corner radius; command-center radii via CardMetrics.
- **Context-across-async-gap sweep COMPLETE** — all 56 remaining `use_build_context_synchronously` analyzer findings fixed (import_export, apps, app, add_app, developer_settings, onboarding, system_updates, microg_hub, logs_page, app_download_service, app_install_service, apps_provider). Analyzer count now **0**. Key patterns: `context.mounted` for captured build contexts (State.mounted doesn't satisfy closures), nullable contexts forwarded to install helpers sanitized to null when unmounted, onboarding captures SettingsProvider pre-await so welcomeShown always persists.
- Lint debt from earlier entry is now closed.

### 2026-07-04 (night) — Claude Code (Fable 5) [session 854c1d79 continued]

**Done:**
- **CardMetrics radius system** (`lib/utils/card_metrics.dart`) — one derivation for all app-compartment cards: `card()` compact outer cards, `inner()` nested icons/buttons, `cardFor()` extent-driven grid tiles. Replaced five divergent factor+clamp combos in app_dashboard (×3), discover, app_list_tile icon; AppGridTile now follows the user corner-radius setting (previously derived from icon size only).
- **Build History dropped from release notes** — removed from the workflow generator and stripped from v1.4.3-p31…p34 bodies via API.
- **Bump-push race fixed** — CI "Commit version bump" now rebases before pushing (a concurrent dev push made run 28708699310 fail at the push step; APK/tests were fine).
- **Backfilled 18 broken release bodies** (v1.4.3-p13…p30) — stale CHANGELOG_USER "What's New" replaced with categorized commits-since-previous-tag via GitHub API PATCH; hand-written Antigravity bodies and the p108 security warning left untouched.
- **Search unification** — new `lib/services/app_search_service.dart`; Discover `runSearch`, Add App `runLiveSearch`, and command center `_runDiscoverSearch` all now share one fan-out/aggregate implementation (deselected sources + per-source query settings respected).
- **Discover enhancements** — descriptions now shown in list tiles and grid cards (were fetched but dropped); clear button on search field; query reactive while typing (chips previously appeared only after unrelated rebuilds); result count row; grid/list toggle persisted as `discoverViewMode` in ViewSettingsProvider.

### 2026-07-04 (evening) — Claude Code (Fable 5) [session 854c1d79 continued]

**Goal:** full settings-crash audit + ShizukuPlus-style release notes.

**Done:**
- **Settings crash audit (p30)** — swept the entire settings build path: all FutureBuilders guarded (`hasData`/`?.` — the one `snapshot.data!` at update_settings_section:135 is hasData-guarded), all jsonDecode getters try/catch-wrapped, forcedLocale validated against supportedLocales, no unguarded list indexing. One remaining hazard fixed: range-bound pref values fed raw into Sliders/BorderRadius — clamped at getters (corner radii 0–40, gridColumnCount 0–6, categoryIconCount 0–20, banWarningThreshold 1–50, playStoreMinDownloads, updateIntervalSliderVal).
- **Release notes (p31)** — replaced stale `CHANGELOG_USER.md` mechanism (same outdated "What's New" + literal `\n` on every release) with ShizukuPlus-style generation in build-apk.yml: commits since last v* tag categorized ✨ feat / 🐛 fix / 🔧 other (auto-bumps excluded), 🏗️ Build History (failed runs between releases via `gh run list`, needs `actions: read`), compare link. Verified rendering on v1.4.3-p31.

### 2026-07-04 (later) — Claude Code (Fable 5) [session 854c1d79 continued]

**Goal:** continue fixes; user reported settings still broken → found definitive #217 root cause.

**Done:**
- **#217 DEFINITIVE root cause** — `importObtainiumData` (apps_provider.dart ~2242) restores settings keys typed by JSON runtime type; type flips (int↔double↔bool↔string) and stale enum indexes then throw TypeError/RangeError during SettingsPage build → whole page = release ErrorWidget (screenshot shows grey body + live bottom nav = exception at top of page build). Fixed in **p28**: safe_prefs extended with `safeString`/`safeStringList`/`safeEnum` (range-checked enum reads); ALL remaining getBool/getString/getStringList reads (164 sites) and all 13 enum-by-index reads converted. Tests extended.
- **SettingsPage.initialTab** — was accepted but never applied; now clamped + used in initState.
- **Cleanup batch (p27)** — 103 unused imports removed (40 files); `test_versions.dart` scratch file deleted; safeInt in crash_analytics/crash_tracker/known_issues_service; mounted-guards for context-across-async in home.dart deep links, installation_section Shizuku callback, logs_dialog.
- **Verified:** grid/list toggle persists via `globalViewMode` pref (backlog item closed).
- **Remaining known lint debt:** ~40 `use_build_context_synchronously` infos in add_app/app/apps/developer_settings/import_export/onboarding/system_updates — real crash class, fix in a future batch.

### 2026-07-04 — Claude Code (Fable 5) [session 854c1d79 continued]

**Goal:** close out GitHub issues #217 and #218 with in-depth fixes; verify Sentry is clean.

**Done:**
- **#218 root cause** — `1.4.3-pNN` matched no standard version regex, so `getCorrectedInstallStatusAppIfPossible` case FOUR auto-disabled version detection and froze `installedVersion` → perpetual update prompt. Fixed with `p[0-9]+` suffix pattern + new FIFTH self-heal case in `apps_provider.dart` (corrects `installedVersion` to `latestVersion` only when the OS versionName reconciles as equal to latest).
- **#217 defense-in-depth** — `safe_prefs.dart` extension (type-tolerant `safeDouble`/`safeInt`/`safeBool`) applied across all 8 providers; release-mode `ErrorWidget.builder` replaced with a labeled error card; Sentry re-enabled in `main.dart` (was dropped in fb5a91c2) with Shizuku-noise `beforeSend` filter.
- **Changelog version constant** — `lib/utils/version_constant.dart` replaces hardcoded `1.4.3-p15` in `home.dart`; CI auto-bump step now seds it alongside pubspec.yaml.
- **Tests** — `test/version_detection_test.dart` (#218 regression) and `test/safe_prefs_test.dart` (#217 regression).
- **Gotcha hit:** `TextDirection.ltr` broke CI — easy_localization re-exports intl's `TextDirection`; must use `ui.TextDirection.ltr` in main.dart.
- **Sentry state:** all `sentry-crash` GH issues closed; sentry-sync runs green with nothing new.

### 2026-06-29 → 2026-07-04 — Claude Code (Sonnet 4.6) [Termux session, 854c1d79]

**Session note:** Ran from Termux environment. Session invisible from PRoot until 2026-07-04 sync.

**Commits:** `009ec11c` through `7f471fd9` (8 commits + 5 auto-bumps)

**Done:**

*Settings menu:*
- **Fixed compilation errors** in settings components (`PlusFeaturesSection`, related widgets)
- **Removed quick actions grid** from `app_dashboard.dart` and `plus_features_section.dart` — was causing crashes and visual clutter
- **Grid/list view toggle** added to `apps.dart` — toggle button in app bar, `getDisplayedList()` updated

*UI:*
- **Blurry icon fix** — wrapped `Image.memory` in `SizedBox` + `filterQuality: FilterQuality.high`
- **Stats hub removed** from dashboard (f6dc0319) — too visually distracting
- **Glassmorphism backdrop blurs** clipped to widget bounds (3aedd98c) — was blurring text below
- **UI polish** — icon blur, settings consistency, crash prevention (009ec11c)

*Crashes / Sentry:*
- **Re-enabled Sentry crash reporting** (7f471fd9, #217) — had been accidentally disabled
- **Hardened prefs parsing** against TypeErrors — strict type coercion → safe null fallback
- **GitHub/Sentry issues** checked; commented on open issues before resolving

**Notes:**
- Auto-bump version tags (`p19`–`p23`) interspersed with fixes; version is now `1.4.3-p23`
- Session hit monthly spend limit and session limit at the end

### 2026-06-26 → 2026-06-29 — Antigravity CLI [session a6590a93, multi-day]

**Topics covered (from history):**
- App update/install detection failures — when links not detected or apps don't install properly
- Update detection for custom GitHub-hosted apps (ShizukuPlus, ObtainiumPlus versioning)
- UI/UX improvements: animations, vibrations, settings, empty states, error states
- Material 3 Expressive design audit (wave animation, Google Play style)
- Settings refactor
- Sentry and GitHub issue review and fixes
- CI builds — multiple checks for successful GH Actions APK
- Android developer knowledge MCP tooling setup

**Notes:** This was a very long multi-day session (Jun 26 09:15 → Jun 29+ based on timestamps). Commits from this period are in the Jun 28 and Jun 29 commit ranges already logged above.

### 2026-06-01 → 2026-06-14 — Gemini CLI [multiple sessions, pre-Claude]

**Sessions:**
- `session-2026-06-01T03-30` (180MB) — capsCase codenames UI fix and extensive feature work
- `session-2026-06-04T09-33` (4.8MB) — GitHub stats graphics (thejaustin profile)
- `session-2026-06-08T02-14` (175KB) — GitHub profile improvements, layout
- `session-2026-06-15T17-54` (105KB) — Claude setup troubleshooting in PRoot context

**Key work from these sessions:**
- CapsCase/codename display issues fixed across app
- Aurora Store connection removed (per Rahul's request — disabled across all versions retroactively)
- Manual APK source addition for users (workaround for Aurora removal)
- GitHub profile stats graphics (thejaustin repo)
- Settings design consistency
- Various Gemini-era crash and UI fixes

**Note:** These sessions ran before Claude was installed (Jun 14). "Continue where Gemini and Antigravity left off" in the first Claude session (Jun 15) refers to this body of work.

### 2026-05-29 → 2026-05-31 — Antigravity CLI [sessions 118dc5d1, d4c4405e, 3605823d]

**Context:** Device was reset — all prior data deleted. Starting fresh rebuild of development environment.

**Key work:**
- Rebuilt development environment post-device-reset
- Glassmorphism onboarding toggle — works without app restart; returns to same onboarding step with new design
- Removed Aurora Store connection (`118dc5d1`) — removed from all versions retroactively
- Manual APK source flow implemented (`118dc5d1`)
- GitHub Dev Knowledge MCP integration explored (`67d4c6db`)
- ShizukuPlus GitHub issue #84 reviewed and addressed (`cae50a77`)
- Naming/structure improvements, visual over textual (`3605823d`)
- Changelogs generated and pushed to repo + GH Actions

### 2026-06-28 — Claude Code (Sonnet 4.6) [Termux session, d66b3105 start + 6cce897a]

**Commits:** `4a243f8e` through `48c2c5c1` (18 commits)

**Done:**

*Features:*
- **Home screen widget** (`2abcc3b0`, #26) — pending updates widget for Android home screen
- **Google Play API protobuf decoding** (`b4fc688c`, #89) — proper protobuf decode for Play API integration
- **Horizontal pill navigation** (`11998a9f`) — settings tabs use pill-style nav
- **GlobalThemeBuilder** (`1ace1916`) — expressive ThemeBuilder hooked up globally; fixes button/component inconsistencies
- **Premium gradients, shadows, haptics** (`644c34dc`) — Android dev tools added
- **Compact layout density** (`68a708d6`) — applied to toggles and checkboxes

*Fixes:*
- **Home_widget version** (`ae30296c`) — bumped to resolve `pub get` failure; updated manifest for 0.9.x API
- **Flutter test compilation** (`a7a0ef14`) — resolved test compile errors
- **Dynamic corner radius** (`75405c37`) — `ChoiceChips` and beta tags use global radius instead of hardcoded values
- **Adding apps from Discovery tab** (`b148da29`, #216) — fixed
- **Sentry background crashes** (`8ff56cc3`, `fc196dbe`, #132, #179, #214)
- **AppFileService import** (`fa9161a1`) — missing import added
- **Wave animation + import** (`38b7ff3a`)
- **ConditionalBlur arguments** (`4a243f8e`) — fixed parenthesis/args in `modal_utils.dart`
- **Glassmorphic dialogs + wave progress** (`133105fb`)
