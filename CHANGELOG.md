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
