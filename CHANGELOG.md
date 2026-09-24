# Changelog

All notable changes to Obtainium+ are documented in this file.

## [v1.7.0] - Official Release (2026-09-24)

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
