## [Upcoming]

<!-- Add upcoming user-facing release notes here. When empty, CI automatically generates clean release notes from commit logs. -->

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
