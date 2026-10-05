<!-- UPCOMING RELEASE NOTES (top section, above the first --- divider)
     CI picks up this section verbatim as the GitHub release body for every
     patch build, so users see readable notes in the in-app "What's New" sheet.
     Keep it user-facing: no commit hashes, no technical jargon.
     After a patch cycle completes, archive entries below the divider using the
     versioned format: ## [X.Y.Z-pN] — YYYY-MM-DD
     Major releases use: ## [X.Y.Z-rN — Major Release] — YYYY-MM-DD -->

### 🐛 Bug Fixes

#### 🎨 Settings
- **White background in light mode** — Settings sections now stand out from the page background instead of blending into a flat white sheet.

#### 📋 App List
- **Odd glow on update cards** — Cards with pending updates no longer show a colored halo; the shadow is now neutral and subtle.

#### 🪟 Startup
- **Two popups on launch after update** — The app no longer shows the What's New sheet *and* a second dialog on the same startup. One notification per update.

#### 🔔 What's New sheet
- **Awkward loading spinner** — The loading circle while release notes fetch now appears at a fixed, sensible size instead of filling the whole sheet.


---

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
