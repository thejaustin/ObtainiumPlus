## [Upcoming]

<!-- Add upcoming user-facing release notes here. When empty, CI automatically generates clean release notes from commit logs. -->

---

## [1.7.3-p13] — 2026-11-03

### 🎨 Material 3 Expressive UI & Gestures
- **Settings Architecture & Fluid Navigation Overhaul (M3E)**:
  - **Single Authoritative Domain Architecture**: Deduplicated settings across screens under the "Single Authoritative Home" rule. Re-categorized `removeOnExternalUninstall` into Tab 3 (App Behavior) under a unified "Library & Storage Management" group, decoupled battery optimizations into dedicated connected action cards, and cross-referenced features via lightweight connected pills instead of duplicating controls.
  - **In-Place Seamless Sibling Switching**: Overhauled `SettingsSubpage` sibling tab navigation. Switching between sibling sections (e.g., in Appearance Hub: Themes & Colors ↔ App Tile Styling ↔ Layout & Navigation ↔ Motion & Physics) now executes in-place via an emphasized horizontal `AnimatedSwitcher` without rebuilding the route scaffold, unmounting the app bar, or flickering.
  - **Eliminated Tab Switching Layout Jumpiness**: Configured top-anchored layout builders (`Alignment.topCenter`) and smooth scroll handling in `SettingsPage`, eliminating vertical jumps and conflicting scroll animations when switching between categories of varying height.
  - **M3E Design Documentation**: Documented the complete Material 3 Expressive settings design specification, typography tokens, haptics hierarchy, and spatial transition models in `docs/designs/m3e_settings_architecture.md`.
- **Settings Redesign & Hero Overview**: Redesigned the top of the Settings view with an interactive `SettingsHeroOverview` dashboard featuring live installer mode pills (`Shizuku`, `Root`, `System`), background update intervals, and 1-tap device optimization shortcuts. Added horizontal quick-topic search filter chips (`Themes`, `Shizuku`, `Swipe`, `Usage Access`, `Backups`, `Safety`) under the search bar for instant 1-tap filter navigation with tactile haptics.
- **Stability, Leak Prevention & Crash Hardening**: Audited and resolved potential resource leaks and runtime break points:
  - **Native Pipe Descriptor Leaks**: Explicitly closed `outputStream`, `inputStream`, and `errorStream` on spawned Shizuku and root shell processes in `MainActivity.kt`, ensuring file descriptors and buffer pipes are freed immediately upon task completion.
  - **Unbounded Memory Cache Protection**: Applied bounded size limits and LRU eviction to `OnlineAppDatabaseService` (200 entries) and `GitHubEtagCache` (250 entries), preventing background sync from continuously expanding heap usage.
  - **Crash-Proof JSON Deserialization**: Hardened `InstallHistoryEntry.fromJson` and `App.fromJson` to safely parse polymorphic `timestamp` fields (handling both microsecond and millisecond timestamps and `num`/`double` representations) and wrapped nested lists to prevent unhandled `TypeError` crashes.
  - **Safe URI Parsing**: Replaced unsafe `Uri.parse()` calls with `Uri.tryParse()` in the embedded WebView controller and open registry query services, preventing fatal `FormatException` crashes on malformed URLs.
  - **Widget Lifecycle & Listener Cleanup**: Added strict `mounted` guards in `UsageAccessCard` to prevent post-dispose `setState` calls during background lifecycle resumes, and explicitly removed animation controllers' listeners in `SwipePreviewWidget.dispose()`.
- **Startup Time & Update/Install Acceleration (4x Target)**:
  - **Fast App Index Cache (`apps_cache.json`)**: Consolidated app library loading into a single unified JSON index cache. Cold start now loads the entire app library in one ~5-10ms snapshot read instead of performing dozens to hundreds of separate file reads and JSON parses. The index automatically and atomically updates whenever apps are saved, updated, or removed, with automatic fallback if missing.
  - **Multi-Tier Caching Pipeline**:
    - **L1 In-Memory ETag Cache**: Upgraded `GitHubEtagCache` with a zero-latency in-memory L1 cache (`_l1MemoryCache`), eliminating repetitive disk reads and gzip decompression for hot update checks and release lookups.
    - **In-Memory App Icon Cache**: Added bounded L1 memory caching for decoded app icon bytes in `AppsProvider`, preventing redundant filesystem `stat()` and `readAsBytes()` calls when scrolling or opening app details.
    - **PackageManager Query Caching & Deduplication**: Added a memoized 10-second cache with in-flight deduplication to `AppInstallService.getAllInstalledInfo()` and in-memory package lookups to `getInstalledInfo()`, eliminating 200–500ms binder IPC round-trips across sheets, tabs, and diagnostic utilities.
  - **Deduplicated System & File IPC**: Memoized in-flight `DeviceUtils.getAndroidInfo()` and `AppFileService.initAppDirectories()` so concurrent providers share a single platform channel invocation instead of issuing duplicate IPC queries.
  - **Eliminated Startup Directory Scan**: Replaced the blocking disk scan of the entire icons directory in `_loadAppsPhase1()` with targeted checks for the initial 12 viewport tiles, keeping remaining tiles lazy.
  - **Doubled Update Check Concurrency**: Increased default concurrent update checks from 3 to 6 (slider steps: `[1, 2, 4, 6, 8, 12]`) and bumped per-host check concurrency from 3 to 4, significantly accelerating batch update checks.
  - **Progressive Shizuku Install Polling**: Replaced fixed 350ms install polling with progressive polling (120ms intervals for the first 1.2s, 300ms, then backoff), detecting landed package manager installs up to 230ms faster.
  - **Zero-Latency Press-Down Feedback**: Removed artificial 35ms press delays in `ScaleTouchWrapper` so tactile haptic feedback (`tapDown`) fires instantly upon touch contact. Added `AnimatedScale` spring pop (1.05×) and cubic easing to all settings feature toggles.
  - Removed redundant `_handleFirstRun` execution from the root build frame loop.
- **In-App Usage Access Tracking & 1-Tap Shizuku Grant**: Obtainium+ can now monitor app launch recency and foreground screen time using Android's `PACKAGE_USAGE_STATS` (`AppOpsManager`). You can grant Usage Access in 1-tap directly within Obtainium+ using **Shizuku** / privileged shell without navigating through Android Settings, or use the standard Android Settings fallback. Once granted, Obtainium+ displays live "Last Used" and "Screen Time" badges on app cards and allows sorting the entire apps library by **"Last Used"** to quickly identify abandonware and prioritize active apps. Includes a dedicated `UsageAccessCard` in Developer Settings and the Device Optimization Sheet with live app tracking metrics and real-time permission status.
- **Install & Update History Tracking**: Obtainium+ now tracks and records the exact timestamp an app was first installed and every subsequent update performed. Automatically synchronizes with Android's system `firstInstallTime` and `lastUpdateTime`, tracks the installer method (Obtainium+, Shizuku, Root, System), records version transitions, and displays the full timeline in the app overview. Apps can now also be sorted by `First Installed Date`, `Last Updated Date`, `Source`, and `Date Added` in the main list.
- **App Description Card & Pop-Up Overhaul with Multi-Style Switching**: Completely redesigned the app description card on the app detail page and in its modal popup with live one-tap style switching between:
  - 🚀 **Obtainium+ App Info**: Technical specifications dashboard with source provider pill, package and variant links, track-only flags, APK asset details, and rich description text.
  - 🐙 **GitHub README**: Repository banner header, branch pill, GitHub Flavored Markdown with monospaced code blocks, tables, and anchor links.
  - 🛍️ **Play Store**: Play Protect verification, package metrics, release chips, feature highlights, and clean store typography.
  - 🌐 **Live Webpage**: Interactive embedded browser view with reload, SSL domain badge, and external browser shortcuts directly in the card or modal sheet.
  - 📝 **Raw Markdown / Text**: Formatted monospaced view with live word & character counts and quick copy.
  The legacy binary "Show Webpage in App View" toggle has been upgraded in Settings → Appearance to a segmented **"Default App Details Tab"** selector so you can choose which style opens by default. Includes theme-adaptive glassmorphism transparency, smooth spring transitions, haptic feedback on style switching, collapsible preview controls, and full-screen modal sheet with downward dismiss.
- **ShizukuPlus-Style Swipe Gestures & Settings Sandbox**: Swiping app rows in the management list now features an exact 38% trigger threshold, 3-stage haptic feedback (threshold activate, release tick, and success confirmation), progressive icon scaling (75% to 100%), spring-animated badge pop (1.15×), and Material 3 container colors. In Settings → App Behavior, a new interactive preview sandbox lets you test swipe gestures in real time alongside an auto-animating demo row.
- **Local App Installation & Variant Detection Hub**: When an app is installed under an alternate package name (such as ShizukuPlus drop-in `moe.shizuku.privileged.api` vs standalone `org.thejaustin.shizuku`, F-Droid, or debug variants), Obtainium+ now automatically detects the local installation on load and properly offers "Update" or "Open" instead of getting stuck on "Install". A new "Local Installation & Variants" menu allows viewing all installed builds on the device, one-tap active variant switching, and browsing all system apps to link custom installations.
- **Parallel Apps, Insular & Dual Messenger Detection**: Local detection now inspects Android's multi-user profiles, discovering clone and parallel installations across Work Profiles (Insular, Shelter, Island), Samsung Dual Messenger, and Parallel Space (Xiaomi/OnePlus Dual Apps) alongside the main profile.
- **Galaxy Store & Google Play Store Integration**: Added Galaxy Store (`com.sec.android.app.samsungapps`) and Google Play Store (`com.android.vending`) directly to the store chooser and automatic origin detection, showing which store an app was originally installed from.
- **Google Play & Network Diagnostics Suite**: Added a comprehensive diagnostic tool to Developer Settings to verify microG availability, VPN IP leak protection, Aurora AAS dispenser latency and rate limits, and live FDFE endpoint handshakes.
- **Play Store FDFE Inspector & Live Sandbox**: Interactive developer tool in Developer Settings to test and inspect any package against Google Play's protobuf endpoints, resolving version metadata, developer info, and split APK delivery URLs live with one-tap JSON export.
- **Multi-User Environment Diagnostic Tool**: Added an on-device environment inspector in Developer Settings to view all detected user profiles (User 0 Personal, User 10 Work Profile, User 95 Dual Messenger) and package sources with one-click markdown report generation for GitHub issues.
- **Quota-Free Online Database Queries**: Added `OnlineAppDatabaseService` and a developer toggle to query unmetered open app registries (F-Droid and IzzyOnDroid open APIs) and GitHub Atom feeds directly, avoiding exhausting GitHub's 60 req/hr unauthenticated API limit when checking for app details and releases.
- **Swipe-Dismissible Modal Sheets & Dialogs**: App description sheets, installation conflict popups, and homescreen context submenus can now be effortlessly swiped or flicked away downwards. Added visible Material 3 drag handles, top close buttons in modal views, and barrier dismissal to avoid blocking underlying navigation.
- **Smooth Indeterminate Progress Waves & Compact Spinners**: Fixed the wavy progress indicator to animate in a continuous, fluid cyclic loop without pausing, freezing, or jumping at the end of each cycle. Small in-button spinners now use an adaptive radius-scaled wave count to eliminate jagged vibration and flickering.
- **Expressive Homescreen Submenus & Toggles**: Submenus and action sheets now feature Material 3 Expressive spring physics, tactile press-down scale feedback (`ScaleTouchWrapper`), and responsive haptics on toggles and menu selections.

### ⚡ Update Checks
- **Asks When Another Version Is Installed**: Before installing a build of an app that's already on your phone under another package name, Obtainium+ now asks instead of quietly adding a second copy. Examples are Shizuku+ and its drop-in "Shizuku" build, or an app's F-Droid and GitHub builds. You can replace the installed build (it's uninstalled only after the new one installs), keep the installed build and pick its file from the release, or keep both. "Don't ask again" remembers Keep both for that app. Background updates no longer install a second copy without asking; they wait and tell you to choose. You can turn the question off or forget your choices in Settings → Updates & Install.
- **Smoother Scrolling in the Apps List**: App rows no longer fade in again every time they scroll back into view (rows near the top could sit blank for up to a third of a second). The fade now plays once, when the list first opens. When an install finishes and an app moves in the list, its row moves with it instead of flashing in again, and the progress banner stays put in the short gap between one app's install and the next download instead of collapsing and reopening.
- **Faster, More Compatible Network Requests**: Update checks now go through Android's own network stack (embedded Cronet, no Google Play Services needed). Connections are reused across a check instead of reopened for every request, Android proxy settings apply, and certificates you've installed on the device (for a self-hosted or company server) are trusted. App downloads themselves still use the previous network code for now.
- **Cleaner Finish to Installs**: When an install finishes, the progress text on the app row fades out before the menu button fades in, instead of the two overlapping. The progress banner keeps saying "Installing" as it slides away instead of flipping to "Please wait".
- **Smoother End of Update Checks**: The progress banner no longer vanishes in a single frame when a check finishes right after finding updates. It fills its bar and slides away.
- **Faster "Update All"**: Each app now installs as soon as its own download finishes, while the others keep downloading. Before, nothing installed until every download was done. Obtainium+ itself and Shizuku providers still install last.
- **Much Less Data for GitHub Checks**: GitHub apps are now checked with conditional requests, so a repo with no new release answers with an empty "not modified" reply instead of resending its whole release list (often hundreds of KB per app). With a GitHub token set, these replies also don't count against your rate limit.

### 🛡️ Fixes
- **Dhizuku No Longer Mistaken for Shizuku+**: Dhizuku was treated as another version of Shizuku+, so Shizuku+ could show as installed when only Dhizuku was, and a Dhizuku download could be accepted as a Shizuku+ update. They're now kept apart.
- **Shizuku+ Updates No Longer Fail With "App not found"**: When a Shizuku+ update's APK used the other Shizuku+ package name (its drop-in build shares stock Shizuku's), the update stopped with "App not found" after downloading. It now installs. This affected any app whose download turned out to have a related package name.
- **Settings Redesign Pass**: Every section and card now uses one header style, one text size for settings and one icon style, so the tabs look like one app instead of several. The card repeating the tab name at the top of each tab is now a short line of text. Descriptions that were cut off after one line now show in full. Option tiles no longer cut off their labels, no longer jump when tapped, and a lone last tile fills the row. On the Advanced tab, the Obtainium+ switch and layout picker no longer sit as boxes inside a box. The update interval slider now shows its value right away instead of a blank bubble, "Use a foreground service…" is now "Reliable background checks" with the details underneath, the footer links line up, and compact mode now applies to every row the same way.
- **Cleaner Settings**: Setting titles now share one size and tighter spacing, so they wrap less and no longer outweigh their section headers. Sections no longer repeat their own name ("Device options", "Notifications", "Automatic update rules" and "Update scheduling" each appeared twice). The concurrency sliders' descriptions moved under their titles, and "Device options" and "Update options" got their own short summaries instead of repeating a setting's text. "Related Settings" no longer links to cards already on the same page, its descriptions can now be translated, and the app is now called Obtainium+ and Shizuku+ throughout instead of "ObtainiumPlus" and "ShizukuPlus".
- **Release Dates Settle Unclear Updates**: When version numbers can't say which release is newer (for example `1.4.0-rc1` vs `1.4.0`, or an app that switched from date-style versions like `2024.10.5` to `3.2.0`), Obtainium+ now checks when each version came out. Newer releases are offered and older ones are hidden. The app log notes what decided each hidden update.
- **APK Architecture Labels**: When an F-Droid repo release has several APKs, the APK picker now shows which architecture each one is for, or marks it as universal.
- **Detection Date Fix**: With "use detection date as release date" on, the first check after adding an app no longer invents a release date for a version that was already out.
- **Silent Updates via Shizuku on Android 14+**: Apps first installed through Shizuku now claim update ownership, so later updates can install without a prompt.
- **Fewer Fake "Updates" That Are Really Downgrades**: When an app's installed version has an extra label that its releases don't (for example `1.4.0-gplay`, `2.0.1 (201)` or `1.2.3-fdroid` against a `1.3.9` release), Obtainium+ couldn't tell which was newer and listed the older release as an update. It now compares the version numbers and stops offering older releases, and update notifications and background auto-updates skip them too.
- **Removing an HTML Source Step or Header No Longer Breaks the Form**: Deleting an intermediate link step or a request header from an HTML-source app (Add App or app options) could replace that part of the form with an error box. It now removes just that entry, and the entries after it keep their own values.
- **Fixed Error Pop-Ups After Failed Updates**: When an update or install started from the apps list failed, a second hidden error could follow the error message. It's gone.
- **Backups No Longer Include Per-App Tokens Unless Asked**: Exports, including auto-exports, made without the "include credentials" option no longer contain access tokens saved on individual apps (for example, a token for a self-hosted GitHub or GitLab).
- **Updated App Icons Show Up**: If an app's icon changes in an update, including updates made outside Obtainium+, the new icon is now loaded instead of the old cached one.
- **No More Duplicates in the Search Sheet**: An app that's downloading or has an update is now listed once in the search sheet, instead of again under "Updates" and "Recently added". The sheet's update list also uses the same downgrade check as the apps list, so it no longer offers older releases as updates. Searching online also no longer lists apps you've already added a second time under "Discover".

---

## [1.7.3-p11] — 2026-10-30

### ⚡ Update Checks
- **Faster, Lighter Checks for Large App Lists**: Checks are now spread across sources, so a long run of GitHub apps no longer holds up apps from other sites, and no single site gets more than 3 update checks at once. Results are saved in batches instead of once per app, and APKMirror data is fetched once per check.
- **Fewer Wasted GitHub Requests**: Once GitHub's API rate limit is reached, the remaining GitHub apps go straight to the releases feed until the limit resets, instead of each one failing against the API first.
- **Excluded Categories & Disabled Apps Are Skipped**: Batch update checks now skip apps in categories you excluded from checks, and apps with checking disabled. Before this fix, both were still checked.
- **Failing Apps Back Off**: An app whose check fails, or that hits a rate limit, waits one full update interval before it's checked again, instead of being retried on every background run. Connection drops don't count, so those apps are retried as usual. Repeated failures now count toward Update Health's failed-checks warning, which previously never triggered.
- **Smoother Update Progress**: The update-check bar and counter glide between steps instead of jumping, a live "N updates found" pill appears as updates turn up, and the progress strips on app tiles fade in and out. The bulk download bar also eases between steps.

### 🎨 Polish
- **App Font Everywhere**: Buttons, chips, segmented buttons, dialogs, snackbars, tooltips, badges, input labels, the slider value bubble and the navigation bar now use the app's font (or your chosen system font). Before this fix, they used Android's default font, so they didn't match the rest of the app.
- **Matching Shapes in Dialogs**: The time pickers in the update schedule and quiet hours dialogs, and the GitHub token check result, now follow your corner-radius setting and Material 3 Expressive shapes.
- **Changelog Page Width**: On tablets and unfolded foldables, the changelog page now uses the same width as Settings.
- **Translatable Plus Features Sheet**: The Shizuku, binder benchmark, OEM guide and battery optimization rows in the Plus Features sheet can now be translated.
- **No More Cut-Off Theme Labels**: The theme picker's first option now reads "System" instead of a truncated "Follow …", and the design style switch shows "Obtainium+" and "M3 Expressive" on one line (long-press for the full name).
- **Translatable GitHub Token Check**: The Verify Token button and its result messages can now be translated.

---

## [1.7.3-p1] — 2026-10-27

### 🔄 Upstream 1.7.2 & 1.7.3 Full Feature Parity
- **Complete Upstream Integration** — Audited, ported, and verified all upstream features and bugfixes across commits through `v1.7.3` (`fcd1807c`).
- **Shizuku Android 14+ Update Ownership** — Set update ownership exclusively during initial installs (`appEntry.installedInfo == null`) to avoid update failures and silent package manager rejections on Android 14+. Pinned `shizuku_apk_installer` ref `447d88a`.
- **Global Version Trimming RegEx** — Configure a global fallback regular expression (`globalVersionExtractionRegEx` & `globalMatchGroupToUse`) in Settings to extract clean version strings across all sources without needing per-app configuration.
- **Icon Cache Directory Resilience** — Ensured the app icon cache directory is created safely on disk, with resilient image loading and decoding fallbacks against corrupt or missing icon files.
- **Store Source Overhauls (Samsung, Vivo, Huawei, Tencent)** — Ported metadata parsing, rate-limiting, and regional China ODS configurations across major store sources.
- **Single-ABI F-Droid Filter** — Improved ABI filtering for F-Droid repositories with single native architecture assets.
- **GitHub Draft Releases & RuStore Fixes** — Fixed handling of GitHub draft releases, Uptodown locale date parsing, and RuStore package downloads.
- **App Market Discovery Intent** — Registered Android launcher market intent filters (`market://details?id=`, `market://search?q=`) for handling store URLs.
- **Greek (el) Localization** — Added full Greek translation strings.

### 🎨 Material 3 Expressive (M3E) & UX Enhancements
- **Settings Fluid Transitions & Hero Mastheads** — Added organic M3 emphasized easing curves, subtle spatial scale transitions, and expressive header masthead cards across all settings subpages.
- **Home & App Tile Polish** — Unified app tile typography, ensured badges, author names, and version badges never overlap, and smoothed out omnibar progress indicators.
- **Tag Management & Modal Fixes** — Added tag editing to app context menus and the Add/Edit App flow (#340), and fixed null-safety crash during dialog dismissals (#338, #330).

---

## [1.7.1-p4] — 2026-10-19

### 🔄 Upstream 1.7.0 & 1.7.1 Full Feature Parity
- **Complete Upstream Integration** — Merged and verified all upstream features and bugfixes across 148 commits between v1.6.17 and v1.7.1.
- **Update Health Dashboard** — Dedicated Update Health page tracking stale or broken sources, consecutive check failures, and per-app health alerts.
- **Disable Apps Without Removing** — Toggle to disable specific apps without deleting them, keeping their records and settings while skipping updates.
- **Category Exclusions** — Exclude chosen categories from manual and background update checks.
- **Offline Placeholder App Support** — Ability to save apps even when initial network checks fail, verifying and completing metadata later.
- **Tri-State Background Guards** — Fine-grained independent toggles for update checks and background installs on Wi-Fi and while charging.
- **Samsung Galaxy Store Complete Overhaul** — Official endpoints, regional ODS downloads, China CSC MCC/MNC network-code derivation, and rate limit bounds.
- **APKMirror Batched Checks & Scoped Scraping** — Batched API checks and scoped scraping to drastically reduce request volume.
- **F-Droid Nativecode Architecture Filtering** — Multi-architecture support using page nativecode metadata with device ABI preference ordering and universal fallbacks.
- **HTML Release Date Extraction** — Scoped HTML release-date extraction to the selected APK container block.
- **Shizuku / Dhizuku Backend Selection** — Added backend selection (`auto`, `shizuku`, `dhizuku`), transient binder retries, and bounded install timeouts to prevent batch update hangs.
- **MediaStore TV Storage & Exports** — Added MediaStore-backed `Downloads/Obtainium/` destination for TVs without document pickers, import conflict warnings, and primary-volume external cache selection.
- **Accessibility & Translations** — TalkBack accessibility semantics, added Bengali (bn) translation, and updated English strings across all 32 locales.

---

## [1.7.1-p2] — 2026-10-18

### 🛡️ Stability, Security & Robustness Pass
- **Zero App Deletion on Broken Source** — Apps whose sources cannot be matched or temporarily fail (e.g. Google Play Native without a token) are preserved along with their APKs rather than being accidentally deleted.
- **Export & Settings NaN Crash Guard** — Added complete validation guards against NaN and Infinity across all JSON serialization, export, and settings storage paths to eliminate startup and export crashes.
- **Hardened File Sharing & PMS Install Locks** — FileProvider authorities and installation commit locks now enforce timeouts and session abandonment to eliminate installation lockups and conflicts.
- **Authenticated Backup Encryption** — Credentials are fully excluded from standard backups, Forgejo tokens are secured, and backup encryption utilizes authenticated keystore hashing.
- **Faster Background Update Checks** — Shared F-Droid repository indexes across checks rather than re-downloading per app; eliminated synchronous APK disk reads; enforced a 90-second timeout per source so stalled sources never hang the background worker.
- **Method Channel & Sentry Reporting** — Android method-channel handlers guarantee a reply to avoid silent IPC hangs, and async background exceptions are properly captured and reported.

### 📱 Restored Expressive Features
- **Expressive App List with Swipe Gestures** — Restored the expressive app row layout with customizable swipe-left/right actions and drag-to-reorder for pinned apps.
- **Native Google Play Source (Opt-in)** — Download apps directly from Google Play when configured with an Aurora dispenser or personal token, with automatic mirror fallback.
- **System Updates Page** — Restored the dedicated System Updates scanner page to audit device packages against available source releases.
- **Material You Dynamic Palette Synchronization** — Surface and tonal color mappings now derive straight from Android's active system wallpaper palette.
- **App Long-Press Launch** — Quickly launch installed apps directly from the Obtainium+ context menu.
- **Undo App Removal** — Tapping remove displays a timed undo action in an M3 snackbar to instantly restore the app.
- **M3E Sort & Filter Sheet** — Restored full modal filter sheet with categories, tags, author, and multi-criteria sorting.
- **Guided Onboarding & Crash Recovery** — Re-enabled first-run guided onboarding and graceful startup crash recovery dialog with triage reporting options.
- **Notification Quiet Hours** — Configured quiet hours now properly silence notification sounds and vibrations.

---

## [1.7.1-p1] — 2026-10-18

### 🎨 Material 3 Expressive & Vivid Primary Theming
- **Vivid Primary Color System** — Navigation indicators, version badges, update pills, active tags, filter chips, and dialog accents now use vibrant primary and primaryContainer tones instead of muted secondary tones.
- **Material 3 Expressive Theme Engine** — Modernized sliders with thick tracks and squircle drag bubbles, squircle corner geometry across cards, bottom sheets, and dialogs.
- **Expanded Palette Presets** — Added Coral, Cosmic, Sakura, Aurora, and Solar curated vibrant color presets across Light, Dark, and AMOLED modes.
- **Shape-Morphing Loading Spinner** — Implemented the Material 3 Expressive morphing progress indicator across all loading states.

### 🌊 Spring Motion & Instant Contact Haptics
- **Physical Spring Motion** — All buttons, chips, and interactive cards bounce on press-release with authentic spring physics and overshoot (Cubic(0.34, 1.56, 0.64, 1.0)).
- **Instant Contact Haptics** — Every interactive tile and button fires a light haptic sensation on initial pointer-down contact rather than waiting for tap completion.
- **Asymmetric Grid Compression** — Grid tiles compress fast (80ms) and spring back smoothly (320ms), giving physical tactile feedback.
- **Double-Tap Bug Fix Sweep** — Eliminated double-action ghost triggers across all toolbar buttons, selection actions, chips, and list tiles.
- **System Accessibility Support** — Fully honors Android's "Remove animations" system setting while preserving tactile haptics.

### 🎛️ Settings Redesign & Usability
- **Settings Density Modes** — Added Comfortable (spacious cards with explanatory subtitles) and Compact (dense 3-column layout) settings density options.
- **Unified Installer Picker** — Replaced fragmented installer toggles with a single radio selector for System, Shizuku, and Root with live status and inline diagnostics.
- **Guided Tab Navigation** — Every settings tab opens with an informative banner and contextual section connectors linking related settings.
- **Permanent Setting Descriptions** — Replaced cryptic long-press tooltips with clear, permanent one-line explanations under all per-app and global settings.
- **Interactive Slider Controls & Morph Badges** — Animated sliders with live shape-morphing badges and notch ticks for intervals, corner radii, and concurrency settings.
- **Floating Island Navigation Dock** — Redesigned floating pill navigation dock with layered frosted glass, ambient depth shadows, and elastic tab switching.

---

## [1.6.17-p11] — 2026-10-08

### ⚡ Bulk Updates, Download Cache & Installer Safety
- **Bulk Update Summary with Cancel All** — Added an active operations summary for batch updates with a one-tap "Cancel All" option.
- **Versioned Download Cache** — APK downloads now use version-aware cache naming to prevent stale file conflicts and ensure split APK integrity.
- **Clearer Root & Installer Diagnostics** — Detailed error reporting for root installer failures with automatic fallback to standard installation prompts.
- **Installer Conflict Prevention** — Improved detection and reporting of package signature and architecture conflicts during installs.
- **State Preservation on Refresh** — Refreshing app lists preserves installed tags, pinned states, and scroll positions.

---

## [1.6.17-p10] — 2026-10-07

### 🐛 Animation Lifecycle Fix
- **Animation Controller Synchronization** — Fixed an issue where repeating AnimationController instances failed to resync correctly in didChangeDependencies, preventing visual glitches during theme switches.

---

## [1.6.17-p9] — 2026-10-06

### 🔧 State Management, Persistence & Light Mode Contrast
- **Provider Rebuild Reliability** — Fixed missed rebuilds across settings components, Discover, Statistics, and App detail views.
- **Provider Initialization** — Ensured AuthProvider, SourceConfigProvider, and PluginProvider are properly initialized with SharedPreferences before app launch so plugin configs persist across restarts.
- **Mounted Guards** — Added safety guards on async context operations and dialog result handlers to prevent framework crashes.
- **Light Mode Surface Contrast** — Standardized inline cards and settings containers on surfaceContainerLow in light mode so content clearly stands out from the page background.
- **Scroll State Preservation** — Added PageStorageKey to all unkeyed ExpansionTile widgets to eliminate scroll position loss and NaN measurement bugs.

---

## [1.6.17-p8] — 2026-10-06

### 🐛 Bug Fixes & Visual Polish
- **Settings Card Contrast** — Improved contrast of settings groups and cards in light mode so they stand out clearly against the page surface.
- **Neutral Update Shadows** — Replaced colored glow halos on pending-update app tiles with subtle, neutral depth shadows.
- **Startup Notification De-duplication** — Fixed startup race condition causing both the What's New sheet and a secondary dialog to appear simultaneously.
- **Changelog Loading Spinner** — Constrained the changelog loading indicator to a balanced size rather than expanding across the modal.
- **Background Check Responsiveness** — Update checks yield briefly between app queries so the UI remains fluid even with large app catalogs.

---

## [1.6.17-p7] — 2026-10-05

### 📄 Metadata & Badge Polish
- **Repository Documentation** — Added live release status, download counters, and star badges to repository documentation.

## [1.6.17-p6] — 2026-10-05

### 🔔 Active Operations Feedback

#### 📊 Progress While Checking for Updates
- The background update-check notification now shows a live counter and progress bar: **"12 / 48 apps checked"** instead of a static "Checking for updates".
- The in-app banner also shows the same counter while a check is running.

#### 📥 More Info While Downloading
- Download notifications now show **download speed** and **time remaining** alongside the progress percentage — e.g. `68% · 3.1 MB/s · 14s left`.
- Install notifications show the **file size** of what was just downloaded.

#### ⏳ Slow Source? You'll Know
- Added a **"Please wait…"** hint under the spinner when adding a new app and the source is slow to respond.

#### 🐛 Bug Fixes
- Fixed shadow effects on app cards bleeding slightly outside rounded corners.
- Corrected blur intensity mismatch making some cards look hazier than intended.
- Install action buttons now clearly distinguish a fresh install from an update.
- Fixed a rendering glitch where the progress counter could show a stale number briefly.

#### 🔧 Reliability
- **Deleted apps are now properly forgotten** from the background retry queue.
- **Rate-limited sources fail faster** — immediate notification instead of silent retries.
- **Background check errors are now logged** instead of silently dropped.
- **Version comparison cache** retains recent entries instead of clearing all at once when full.

---

## [1.6.17-p5] — 2026-10-05

### 🐛 Bug Fixes
- **Card shadow bleeding** — Fixed shadow effects on app cards that were slightly visible outside their rounded corners in certain themes.
- **Blur intensity** — Corrected a sigma mismatch that made some glassmorphic cards look hazier than intended.
- **Install / Update labels** — Action buttons now clearly distinguish a fresh install from an update.

### ⚡ Performance
- **Category & stats widgets** — Reduced unnecessary provider rebuilds when browsing categories or the statistics screen.

---

## [1.6.17-p4] — 2026-10-05

### ⚡ Performance
- **Provider rebuild reduction** — Category filter and statistics widgets no longer trigger full app-list rebuilds on unrelated state changes, improving scroll responsiveness.

---

## [1.6.17-p3] — 2026-10-05

### 🐛 Bug Fixes
- **Crash hardening** — Fixed a rare crash when settings contained NaN-typed values from certain backup-restore import scenarios.
- **Settings persistence** — Closed a gap in safe SharedPreferences reads that could produce a blank settings page after restoring a backup.
- **Icon loading race** — Fixed a rare race condition where icon loading could conflict with concurrent app-list state changes.

---

## [1.6.17-p2] — 2026-10-05

### 🐛 Bug Fixes
- **Settings navigation bar** — Fixed a missing background color on the Settings tab bar that caused transparency glitches in some themes.

---

## [1.6.17-p1] — 2026-10-05

### 🐛 Bug Fixes
- **Locale initialization crash** — Fixed a crash on startup when Material localizations weren't fully initialized on certain device configurations.

---

## [1.6.10-r1 — Major Release] — 2026-10-01

> **Major release.** This milestone brings a complete interface overhaul — Material 3 Expressive theming, one-handed reachability, a floating navigation dock, granular tile customization, and a new Shizuku Turbo installer engine.

### 📱 OneUI Reachability Header
- **Fluid Pull-Down Reachability** — Pull down on your app list to smoothly shift the title into the center and bring interactive content within easy thumb reach.
- **Contextual Status Subtitle** — Live `"18 apps · 3 updates"` status text that fades gracefully with header expansion.

### 🎨 Material 3 Expressive Theming
- **Dynamic Scheme Variants** — Android 16/M3 Expressive color schemes: Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome.
- **Curated Palette Presets & Scale Transitions** — Handcrafted themes designed for high-contrast OLED dark modes with fluid spring curves.

### 🏝️ Floating Navigation Dock & Action Capsule
- **Floating Island Dock** — Optional frosted pill-shaped navigation dock with rounded corners and ambient shadow.
- **Floating Action Capsule** — Frosted install and update capsule that stays accessible on App Detail pages.

### ✨ Granular Card & Tile Styling
- **Pinned App Highlight Borders** — Distinctive accented borders for pinned apps.
- **Category Accent Ribbons** — Vertical color ribbons indicating assigned categories.
- **Expressive Version Pills** — Tonal version pills (`↓ 2.4.0`) replacing classic download buttons.
- **Icon Rim Borders** — Outlines ensuring transparent or white icons remain crisp on all backgrounds.
- **Stadium Pill Filter Chips** — Fully rounded chips on tag and category filter bars.

### ⚡ Shizuku / ShizukuPlus Turbo Engine
- **Fast IPC & Auto Fallback** — High-throughput binder buffering for unattended installs with graceful fallback to the package installer.
- **Device Tuning Hub** — Built-in optimization shortcuts for Samsung, Xiaomi, OnePlus, Vivo, Huawei, Nothing OS, and Transsion.

### 🛡️ Bug Fixes & Stability
- Fixed PageStorage type collision crash in Settings Apps section.
- Fixed back-press null assertion crash in navigation handler.
- Fixed a latent infinite loop in tab switching.
- Restored repository moved warnings in modern tiles.
- Fixed GitHub source badge visibility on dark theme cards.
- Eliminated icon cache thrashing and controller memory leaks.
