<!-- UPCOMING RELEASE NOTES (top section, above the first --- divider)
     CI picks up this section verbatim as the GitHub release body for every
     patch build, so users see readable notes in the in-app "What's New" sheet.
     Keep it user-facing: no commit hashes, no technical jargon.
     After a milestone full release, archive this section below the divider
     and start a fresh block here for the next cycle. -->

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

### 🚀 Welcome to Obtainium+ 1.6.10-r1!

This milestone release brings major ergonomic improvements, Material 3 Expressive theming, refined navigation docks, extensive tile customization, and critical stability fixes.

#### 📱 Samsung OneUI Reachability Header
- **Fluid Pull-Down Reachability**: Pull down on your app list to smoothly shift the title into the center and bring interactive content within easy thumb reach.
- **Contextual Status Subtitle**: Live `"18 apps · 3 updates"` status text that fades gracefully with header expansion.

#### 🎨 Material 3 Expressive Theming
- **Dynamic Scheme Variants**: Android 16/M3 Expressive color schemes (Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome).
- **Curated Palette Presets & Scale Transitions**: Handcrafted themes designed for high-contrast OLED dark modes with fluid spring curves.

#### 🏝️ Floating Navigation Dock & Action Capsule
- **Floating Island Dock**: Optional frosted pill-shaped navigation dock (`plusFloatingNavBar`) with rounded corners and ambient shadow.
- **Floating Action Capsule**: Frosted install and update capsule on App Detail pages.

#### ✨ Granular Card & Tile Styling
- **Pinned App Highlight Borders**: Distinctive accented borders for pinned apps.
- **Category Accent Ribbons**: Vertical color ribbons indicating assigned categories.
- **Expressive Version Update Pills**: Tonal version pills (`↓ 2.4.0`) replacing classic download buttons.
- **Icon Rim Borders**: Outlines ensuring transparent or white icons remain crisp on all backgrounds.
- **Stadium Pill Filter Chips**: Fully rounded chips on tag and category filter bars.

#### ⚡ Shizuku / ShizukuPlus Turbo Engine
- **Fast IPC & Auto Fallback**: High-throughput binder buffering for unattended installs with graceful fallback to the package installer.
- **Device Tuning Hub**: Built-in optimization shortcuts for Samsung, Xiaomi, OnePlus, Vivo, Huawei, Nothing OS, and Transsion.

#### 🛡️ Key Bug Fixes & Stability
- Fixed PageStorage type collision crash in Settings Apps section.
- Fixed back-press null assertion crash in navigation handler.
- Fixed latent infinite loop in tab switching.
- Restored repository moved warnings in modern tiles.
- Fixed GitHub source badge visibility on dark theme cards.
- Eliminated icon cache thrashing and controller memory leaks.
