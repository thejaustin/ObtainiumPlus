<!-- UPCOMING RELEASE NOTES (top section, above the first --- divider)
     CI picks up this section verbatim as the GitHub release body for every
     patch build, so users see readable notes in the in-app "What's New" sheet.
     Keep it user-facing: no commit hashes, no technical jargon.
     After a patch cycle completes, archive entries below the divider using the
     versioned format: ## [X.Y.Z-pN] — YYYY-MM-DD
     Major releases use: ## [X.Y.Z-rN — Major Release] — YYYY-MM-DD -->

### 🔔 What's happening while you wait

Ever stare at the "Checking for updates…" notification and wonder how far along it is? This update makes Obtainium+ a lot more communicative about what it's doing in the background.

#### 📊 Progress While Checking for Updates
- The background update-check notification now shows a live counter and progress bar: **"12 / 48 apps checked"** instead of a static "Checking for updates". You can see it ticking up in the status bar.
- The in-app banner (the card that appears at the top of your app list during a check) also shows the same counter so you don't have to pull down the notification shade.

#### 📥 More Info While Downloading
- Download notifications now show **download speed** and **time remaining** alongside the progress percentage — e.g. `68% · 3.1 MB/s · 14s left`. No more guessing whether a download is actually moving.
- When an app is being installed (the download finished and the installer is running), the notification now shows the **file size** of what was just downloaded, so you know what landed on your device.

#### ⏳ Slow Source? You'll Know
- Added a **"Please wait…"** hint under the spinner when adding a new app and the source is taking a while to respond. After about 8 seconds with no response it lets you know it's still working — not frozen.

#### 🐛 Bug Fixes
- Fixed an edge case where shadow effects on app cards bled slightly outside their rounded corners.
- Corrected a blur intensity mismatch that made some cards look hazier than intended.
- Install action buttons now have clearer labels distinguishing a fresh install from an update.
- Fixed a rendering glitch where the progress counter in the banner could show a stale number briefly.

#### 🔧 Reliability Improvements (under the hood)
- **Deleted apps are now properly forgotten.** If an app in the background retry queue gets deleted, its queued retry entry is also cleaned up. Previously deleted apps could leave behind stale entries that got checked every update cycle.
- **Rate-limited sources fail faster and more gracefully.** When a source like GitHub says "slow down," Obtainium+ now immediately notifies you instead of silently retrying the same request four more times before giving up.
- **Background update checks no longer drop errors silently.** Fixed an internal oversight where errors during the initial background check startup weren't being logged or surfaced.
- **Large app libraries handle version comparisons more efficiently.** The internal cache used to detect version format changes now retains recently-seen entries instead of clearing everything at once when full.

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
