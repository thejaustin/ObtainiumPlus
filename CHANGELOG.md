# Changelog

All notable changes to Obtainium+ are documented in this file.

## [Unreleased]

### 🐛 Bug Fixes & Polish

- **Light Mode Card & Dialog Backgrounds**: Fixed all custom dialogs and bottom sheets that were using the plain page background (`surface`) instead of the proper elevated tones. Dialogs now use `surfaceContainerHigh`; bottom sheets and floating bars use `surfaceContainerLow`. Affected surfaces: generated form, selection, logs, critical issue, force update, import error, tag editor, unsupported source dialogs; sort/filter panel, search command center, appearance hub, Plus features, system app selector, developer settings, modal_utils utility sheets, app detail action bar, and generated form renderer picker.
- **Settings Changes Now Apply Immediately**: Plus settings (glassmorphism, corner radius, expressive progress, contextual tips, etc.) now update live as soon as you change them. Previously, components were listening to the wrong provider and would not rebuild until you navigated away. Additional affected components fixed in this pass: settings group cards, Plus features sheet, search command center.
- **Welcome Dialog Safety**: Added `context.mounted` guard around the first-run welcome dialog to prevent a use-after-disposal crash on devices that destroy the home widget before the first frame completes.
- **Export / Share Crash (NaN)**: Prevented JSON encoding failure when app metadata contained `NaN` or `Infinity` values, which could crash the share/export flow.
- **Version History Crash**: Added `PageStorageKey` to the version history expansion tile to prevent a `bool`/`double` type mismatch crash when scrolling back to a previously-visited app.
- **Update Check Unresponsiveness**: Yielded to the UI thread between each update check to prevent the app from becoming unresponsive during large background scans.
- **Aurora / Play Store Auth Lost on Restart**: `AuthProvider` and `SourceConfigProvider` were never initialized with `SharedPreferences`, so Aurora Store dispensers, auth mode, spoofed Android ID, device profile, and all source config keys (custom API tokens, etc.) were silently discarded on every app restart. All three affected providers (`AuthProvider`, `SourceConfigProvider`, `PluginProvider`) are now properly initialized before the widget tree starts.
- **Installed Plugins Cleared on Restart**: `PluginProvider` was not wired to `SharedPreferences`, so installed plugins were lost between sessions. Also hardened plugin loading against corrupted entries so a single bad record no longer blocks all others.
- **MicroG Hub Stuck After Partial Add**: Deployment progress UI could get stuck indefinitely when selected components were already tracked (resulting in no new downloads). The spinner now resets correctly in this case.
- **Settings Changes Now Apply Immediately (More Fixes)**: Several more build-phase helper methods in the command center, tag editor, and plugin manager were calling `context.read<PlusSettingsProvider>()` instead of `context.watch`, meaning animations and corner-radius changes in those surfaces required an app restart to take effect.
- **App Detail Update Crash**: `getUpdate` (app detail page) called `setState` in both its try-block and `finally` without checking `mounted`, causing a crash if the user navigated away during an update check.
- **Notification Cancel After Dispose**: `context.read<NotificationsProvider>()` was called in `.then()` callbacks in the app list and app detail pages without verifying `context.mounted` first, risking a use-after-disposal assertion error when the widget unmounted while an install/update was in progress.
- **Discover Corner Radius Not Live**: The `_buildListResultTile` helper in Discover used `context.read<PlusSettingsProvider>()` instead of `watch`, so corner-radius changes did not update discover result cards without a restart.
- **Logs Toolbar TV Detection**: `_buildFloatingToolbar` redundantly re-read `isTV` from `context.read<SettingsProvider>()` instead of using the value already computed in `build()`.
- **System App Selector Animation**: The animated container inside the label-editor sheet used `context.read<PlusSettingsProvider>()` in a `ValueListenableBuilder` builder, so enabling/disabling enhanced animations had no effect until the sheet was reopened.
- **Category Sections Selection Not Highlighted**: Tapping to multi-select apps in the "Group by Category" list view did not visually highlight selected tiles. `AppListTile` read selection state from `AppsProvider` while the apps page managed selection locally; the two were never in sync. Fixed by adding an optional `selected` parameter to `AppListTile` and passing the local state through `CategorySections`.
- **App Filter Dialog Crash on Back-Navigate**: Navigating away from the apps list while the filter dialog was open could cause `setState` on a disposed widget. Added `mounted` check before applying filter changes.
- **App Additional Options Track-Only Warning Crash**: Calling `showMessage` with a stale context after `await showAdditionalOptionsDialog()` could crash if the user navigated away before confirming. Replaced the linter suppression comment with an actual `context.mounted` guard.
- **Dispenser Manager Controller Leak**: The token dispenser bottom sheet created a `TextEditingController` but never disposed it, leaking the controller every time the sheet was opened. Added `dispose()` override to `_DispenserManagerSheetState`.
- **Network Offline Pulse Not Responding to Animation Toggle**: The offline status dot's pulse animation was started once at init and never re-evaluated when the enhanced-animations setting changed. Toggling animations on while already offline would leave the pulse static until the next network quality check. Fixed by syncing the `AnimationController` in `didChangeDependencies()`.
- **Logs Dialog Crash on Quick Dismiss**: Closing the app-logs dialog before the log fetch completed would trigger a `setState` on a disposed widget, causing a crash. Added a `mounted` guard around the `.then()` callback.
- **Import From URL List Crash on Back-Navigate**: Navigating away from the Import/Export screen while the URL-list import dialog was still open could cause `setState` to be called after the page was disposed. Added a `mounted` check before starting the import.
- **Generated Form Tag Label Crash**: Adding a tag label via the inline dialog in a generated form (e.g. the add-app form) could crash if the parent dialog was dismissed while the label dialog was still open. Added a `mounted` check before applying the new label in the `.then()` callback.
- **Import/Export setState After Dismiss**: Three import flows (file import, source search import, mass-source import) called `setState` to set `importInProgress = true` after an async picker or dialog returned, without first checking `mounted`. Navigating away while those pickers were open would cause a "setState called after dispose" crash. Added `mounted` guards before each of the three `setState` calls.
- **Update Badge / Shizuku Card / Skeleton Pulse Not Responding to Animation Toggle**: The update badge dot, Shizuku status card pulse, and app tile skeleton shimmer each started their `AnimationController.repeat()` once in `initState` and never re-evaluated when `plusEnableEnhancedAnimations` changed. Toggling animations off would leave them looping; toggling on would leave them static. Fixed by adding `didChangeDependencies()` to each widget to sync the controller whenever the setting changes.
- **Install Conflicts Explained Before They Fail**: Updates are now checked against the installed app's signing key before installing. If the new APK is signed by an unrelated key, you get a clear message instead of Android's generic "package conflicts with an existing package" error. The per-app allowed-signer list and the "verify signing certificate" setting are enforced again.
- **Same APK Variant Across Updates**: The app now remembers which release asset you use by name instead of list position, so a reordered or resized release asset list can no longer switch an app to a differently signed build.
- **Clearer Install Errors**: Conflict, invalid-APK, storage and incompatible-device failures from Shizuku, root and external installers are reported directly instead of being silently retried in the system installer. Root installs now report the real failure reason.
- **Installed Apps No Longer Cleared After a Slow Package Query**: If Android's package list timed out or failed, tracked apps could lose their installed state (and be removed when "remove on external uninstall" was on). The query result is now sanity-checked first.
- **One Corrupt App File No Longer Hides Everything**: A single app file with an unexpected field is skipped and logged instead of aborting the whole load.
- **Tags Kept When Refreshing Apps**: Checking for updates no longer resets an app's tags.
- **Home Screen Update Progress Unified**: Update-check progress is shown once in the operations banner (plus each app's own spinner) instead of in several places. When many apps update together the banner shows a single summary with an overall bar, an installed counter and a Cancel all button, with the first two apps listed in detail.
- **Pinned Apps and Recent Updates Are Tappable Again**: Tapping a pinned app or a recent update opens its page (or toggles selection in selection mode); long-press selects. The same fix restores taps on other tiles that rely on the shared touch wrapper.
- **Recent Updates Strip**: Lists only apps still waiting to update and its count opens the Updates filter.
- **Backup and Restore**: Source credentials are included in credential exports and restored to secure storage; imported settings take effect immediately; old automatic backups are removed only after the new one is written; the export folder is kept if it is briefly unreadable.
- **Downloads**: Cached APKs are reused only when their size is confirmed by the server and now include the release version; safer filename parsing from server headers; a stuck connection no longer hangs; a failed write no longer leaves a download marked as active.
- **Background Updates**: Background checks can no longer run twice at once, always report completion to the OS, and release their resources.
- **Smaller Fixes**: F-Droid repository URLs ending in index files no longer crash; GitHub's own error message is shown for 401/403 responses; day-of-month and month names from itch.io, Uptodown and SourceHut parse correctly in any app language; microG token errors are shown instead of storing an empty token; assorted import, search and dialog crash guards.

---

## [v1.6.10-r1] - Official Release (2026-09-24)

### 📱 Samsung OneUI Reachability Header
- **Collapsible Fluid Header**: Engineered for large screens; expands smoothly on pull-down to bring top interactive content down to natural thumb reach.
- **Dynamic Title Shift**: Fluid interpolation transitioning the title from top-left pinned toolbar mode to prominent centered viewing mode.
- **Live Contextual Status**: Shows real-time app counts and pending update counts (`"18 apps · 3 updates"`) that gracefully fade in with header expansion.
- **Dedicated Reachability Toggle**: Controlled via `plusEnableOneHandedMode` and `plusHeaderContextSubtitle`.

### 🎨 Material 3 Expressive Theming & Palette Presets
- **Dynamic Scheme Variants**: Native Android 16/Material 3 Expressive scheme variants including Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome.
- **Spatial Transitions & Scale Physics**: Added spring curves and spatial scale transitions across modal sheets, dialogs, and navigation destinations.
- **Curated Palette Presets**: Handcrafted color presets designed specifically for high-contrast OLED dark themes and light themes.

### 🏝️ Modern Navigation Dock & Action Capsule
- **Floating Island Navigation Dock**: Optional pill-shaped frosted dock (`plusFloatingNavBar`) with rounded corners (`BorderRadius.circular(32)`), safe-area insets, and subtle ambient drop shadow.
- **Always-Show Destination Labels**: Toggle (`plusNavBarAlwaysShowLabels`) to keep destination labels consistently visible across tabs.
- **Floating Action Capsule**: Renders the install and update action bar on the App Detail screen as a hovering frosted pill capsule (`plusFloatingActionBar`).

### ✨ Granular App Tile Customization
- **Pinned Border Accents**: Customizable 1.5px highlighted accent border (`plusPinnedBorderAccent`) on pinned cards for instant visual identification.
- **Category Accent Ribbons**: Optional color-coded vertical indicator ribbon (`plusCategoryAccentRibbon`) matching assigned categories.
- **Expressive Version Update Pills**: Tonal badge button (`plusUpdateExpressiveBadge`) displaying target versions (e.g. `↓ 2.4.0`) with stadium borders.
- **Icon Rim Borders**: Subtle outline rim (`plusIconRimBorder`) preventing white/transparent icons from dissolving into card backgrounds.
- **Stadium Pill Filter Chips**: Fully rounded pill shapes (`plusExpressiveFilterChips`) on tag and category filter bars.
- **List & Grid Parity**: All card customization options work consistently across both List and Grid views.

### ⚡ Shizuku / ShizukuPlus Turbo Engine & OEM Tuning
- **Binder IPC Optimization**: High-throughput I/O buffering and fast adaptive binder polling for silent, unattended installs.
- **Automatic Package Installer Fallback**: Graceful fallback to the system package installer if Shizuku daemon is suspended or unreachable.
- **Device Compatibility & Performance Hub**: Interactive OEM tuning shortcuts for Samsung (OneUI), Xiaomi (HyperOS/MIUI), OnePlus (OxygenOS), Vivo (OriginOS), Huawei (HarmonyOS), Nothing OS, and Transsion devices.

### 🐛 Bug Fixes & Stability
- **Settings PageStorage Crash**: Resolved `type 'bool' is not a subtype of type 'double?'` type cast crash in Settings Apps section by replacing nested shrink-wrapped GridViews with composable Row/Column layouts.
- **PopScope Null Assertion**: Fixed potential null assertion crash on back-press in `home.dart` by safely guarding `_appsPageKey.currentState?.clearSelected()`.
- **Tab Switch Hang**: Prevented latent infinite spin loop in `switchToPage(0)` when already on the Apps tab.
- **Repository Moved Warning**: Restored repository rename warnings (`hasPendingRepoRename`) to modern AppListTile and AppGridTile.
- **GitHub Badge Dark Mode Contrast**: Fixed dark-on-dark invisible badge color for GitHub source links on dark theme surfaces.
- **Icon Cache Thrashing**: Eliminated aggressive `ignoreCache: true` in App Detail screen that previously triggered repeated I/O requests on every widget rebuild.
- **Tag Editor Controller Leak**: Ensured `TextEditingController` is properly disposed on dialog dismissal.
- **FAB Overlap in Multi-Select**: Automatically hide the omnibar FAB when batch multi-selection mode is active.
- **Changelog Dialog Isolation**: Added `barrierDismissible: false` to all update and welcome dialogs to prevent accidental tap-through dismissal.

---

## [v1.6.10-p40] and Earlier
- For earlier development patch history, refer to GitHub releases and commit logs.
