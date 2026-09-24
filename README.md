# ![Obtainium Icon](./assets/graphics/icon_small.png) Obtainium+

Android app updates straight from the source, with a gorgeous modern look and privacy-first features.

Obtainium+ is an independent, privacy-focused version (fork) of the original **Obtainium** app. It allows you to download, install, and update Android apps directly from their developers (like GitHub, GitLab, or custom websites) rather than relying on a commercial app store. You get the latest updates instantly, without third-party tracking, middle-men, or telemetry.

---

## 🌟 What makes Obtainium+ different?

While the original Obtainium is excellent, Obtainium+ elevates the experience with a modern interface, smart update management, and privacy-respecting tools.

Currently supported App sources:
- Open Source - General:
  - [GitHub](https://github.com/)
  - [GitLab](https://gitlab.com/)
  - [Forgejo](https://forgejo.org/) ([Codeberg](https://codeberg.org/))
  - [F-Droid](https://f-droid.org/)
  - Third Party F-Droid Repos
  - [IzzyOnDroid](https://android.izzysoft.de/)
  - [SourceHut](https://git.sr.ht/)
- Other - General:
  - [APKPure](https://apkpure.net/)
  - [Aptoide](https://aptoide.com/)
  - [Uptodown](https://uptodown.com/)
  - [APKCombo](https://apkcombo.com/)
  - [itch.io](https://itch.io/)
  - [Huawei AppGallery](https://appgallery.huawei.com/)
  - [Tencent App Store](https://sj.qq.com/)
  - [vivo App Store (CN)](https://h5.appstore.vivo.com.cn/)
  - [RuStore](https://rustore.ru/)
  - [Farsroid](https://www.farsroid.com)
  - [CoolApk](https://coolapk.com/)
  - [LiteAPKs](https://liteapks.com/)
  - [APK4Free](https://apk4free.net/)
  - [SourceForge](https://sourceforge.net/)
  - Jenkins Jobs
  - [APKMirror](https://apkmirror.com/) *(Track-Only)*
  - [RockMods](https://rockmods.net/) *(Track-Only)*
- Other - App-Specific:
  - [Telegram App](https://telegram.org/)
  - [Neutron Code](https://neutroncode.com/)
- Direct APK Link
- "HTML" (Fallback): Any other URL that returns an HTML page with links to APK files

You can find crowdsourced app configurations at [apps.obtainium.page](https://apps.obtainium.page).

If you can't find the configuration for an app you want, feel free to leave a request on the [issues page](https://github.com/ImranR98/apps.obtainium.imranr.dev/issues).

Or, contribute some configurations to the website by creating a PR at [this repo](https://github.com/ImranR98/apps.obtainium.imranr.dev).

| Feature | Original Obtainium | Obtainium+ |
| :--- | :--- | :--- |
| **Design & Theming** | Standard Material design | Glassmorphic interface, Material 3 Expressive wallpaper dynamic variants, curated palette presets, and spatial scale transitions. |
| **One-Handed Ergonomics** | Fixed top app bar | Samsung OneUI-inspired collapsible header with fluid title shifting on pull-down and live contextual app & update status. |
| **Navigation & Controls** | Fixed flat bottom bar | Optional floating frosted island dock, always-show labels, and floating action capsule on App Detail pages. |
| **Card & Tile Customization** | Static list items | Customizable pinned app highlights, category accent ribbons, expressive update pills (↓ 2.4.0), and icon rim borders across List and Grid views. |
| **Installer Engine** | Standard Shizuku/Root | Shizuku & ShizukuPlus Turbo mode with optimized binder IPC buffers, auto-fallback to package installer, and OEM device optimization hub. |
| **Play Store Mirroring** | Scrapes APK links | Secure, direct connections to Google Play mirrors using your own private servers (dispensers) or microG. |
| **Troubleshooting & Logs** | Basic terminal logs | Built-in diagnostics screen, real-time logger, and local crash tracker to solve issues privately. |
| **Instant Settings** | Requires app restarts to apply | Changes to look, feel, animations, and updates apply instantly as you tap them. |
| **Privacy First** | Uses some default third-party servers | Completely tracking-free. No pre-configured server addresses to protect public servers and guarantee your privacy. |

---

## 🚀 Key Features

### 📱 Samsung OneUI Reachability Header
Engineered for modern large-screen smartphones, Obtainium+ includes a OneUI-inspired collapsible header. When pulled down or at the top of your list, the header smoothly expands to bring interactive content within natural thumb reach, shifting the title into the center alongside real-time contextual information (`18 apps · 3 updates`).

### 🎨 Material 3 Expressive Theming & Palette Presets
Expand beyond standard dynamic color with Android 16/Material 3 Expressive color schemes (Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome), curated contrast presets, and smooth spatial scale transitions.

### 🏝️ Floating Navigation Dock & Action Capsule
Experience a refined floating frosted island dock with rounded corners, ambient drop shadows, and full keyboard arrow navigation. The App Detail screen features a floating action capsule that stays accessible above the bottom margin.

### ✨ Granular App Tile & Card Styling
Customize your app list to your exact aesthetic:
- **Pinned App Highlights**: Distinctive thicker accented borders for pinned apps.
- **Category Accent Ribbons**: Color-coded edge ribbons reflecting assigned categories.
- **Expressive Version Pills**: Tonal status pills showing target versions (`↓ 2.4.0`).
- **Icon Rim Borders**: Outlines around icon containers preventing transparent or white icons from bleeding into backgrounds.
- **Stadium Pill Filter Chips**: Fully rounded chips on the tag and category filter bar.

### ⚡ Shizuku / ShizukuPlus Turbo Engine & Device Tuning
Bypass restrictive background app throttles and OEM installation blocks with native Shizuku and ShizukuPlus integration. Includes an OEM Device Compatibility & Performance hub with direct tuning shortcuts for Samsung (OneUI), Xiaomi (HyperOS/MIUI), OnePlus (OxygenOS), Vivo (Funtouch/OriginOS), Huawei (EMUI/HarmonyOS), Nothing OS, and Transsion devices.

### 🔒 Play Store Updates (Without a Google Account)
Update apps that are normally only available on the Google Play Store. To respect public resources and guarantee your privacy, Obtainium+ includes absolutely no hidden tracking and does not ship with any pre-configured servers. You can easily hook in your own secure servers (like a self-hosted token dispenser) or microG profile.

### 🛑 Play Store Ban Protection
If you check for updates on too many Play Store apps at once, Google might temporarily block your internet address (IP). Obtainium+ includes a safety slider (from 1 to 50 apps) that warns you when an automated update check is about to exceed your limit, keeping your connection safe.

### 🔄 Default App Store Redirection
Obtainium+ automatically detects other app stores installed on your device (like F-Droid, Aurora Store, or Droidify). You can set a default store to route update buttons automatically, or tap to open any app page directly in your preferred store.

### 🌐 Private Diagnostics & Troubleshooting
If an app fails to update, you don't need to guess why. A built-in real-time logger captures network warnings, download errors, and system events. All crash statistics and error logs are stored safely on your device and are never sent to external servers.

## Troubleshooting

### App not updating even when a new version is available
- **Check the source settings** — Some sources require additional configuration (e.g., GitHub releases need the correct repository URL format)
- **Check if the source is supported** — Not all sources support version checking equally; some use HTML scraping which may be slower
- **Check the update interval** — By default, apps update every 6 hours. You can change this in app settings
- **Try force-refreshing** — Pull down on the apps list to force a refresh

### Source additions failing with 403 Forbidden
- Some sources block requests from unknown user agents or regions
- GitHub-based sources may need a Personal Access Token if you're hitting rate limits
- Some APK hosts (APKMirror, etc.) may require cookies or specific headers

### Flutter-related issues
- Obtainium+ is built with Flutter. If the app crashes on startup, try:
  - Clearing app data and reinstalling
  - Ensuring your Android version meets the minimum requirement
  - Checking if you have the latest Google Play Services

### APK verification failures
- If you see "Signature verification failed", ensure you haven't modified the APK after download
- The SHA-256 hash in the app settings should match the downloaded APK

---

## 📦 Installation

Get the latest version directly from the [Releases](https://github.com/thejaustin/ObtainiumPlus/releases) page.

### 🔑 Security Verification
To ensure you have a genuine, unmodified build of Obtainium+, you can verify these details:
*   **Package ID:** `dev.thejaustin.obtainiumplus`
*   **SHA-256 Signature Hash:**
    `B3:53:60:1F:6A:1D:5F:D6:60:3A:E2:F5:0B:E8:0C:F3:01:36:7B:86:B6:AB:8B:1F:66:24:3D:A9:6C:D5:73:62`
*   **[PGP Public Key](https://keyserver.ubuntu.com/pks/lookup?search=contact%40imranr.dev&fingerprint=on&op=index)** (used to verify official APK hashes)

---

## ❤️ Credits & Open Source Acknowledgments

Obtainium+ is built on the shoulders of giants. We are deeply grateful to the original creators and the open-source community:

*   **[Obtainium (Upstream)](https://github.com/ImranR98/Obtainium):** The incredible parent project created by **ImranR98** that serves as the foundation for this fork.
*   **[Talker](https://pub.dev/packages/talker):** Powers our real-time, user-friendly diagnostics and logging screen.
*   **[Dynamic Color](https://pub.dev/packages/dynamic_color):** Enables the app interface to blend seamlessly with your Android system theme (Material You).
*   **[Background Fetch](https://pub.dev/packages/background_fetch) & [Flutter Foreground Task](https://pub.dev/packages/flutter_foreground_task):** Power the reliable, battery-efficient background update checker.
*   **[Easy Localization](https://pub.dev/packages/easy_localization):** Manages translation assets to make the app accessible in dozens of languages.
*   **[Sentry Flutter](https://pub.dev/packages/sentry_flutter):** Powers our opt-in, telemetry-free crash analytics engine.

---

## 📷 Screenshots

| <img src="./assets/screenshots/1.apps.png" alt="Apps Page" /> | <img src="./assets/screenshots/2.dark_theme.png" alt="Dark Theme" /> | <img src="./assets/screenshots/3.material_you.png" alt="Material You" /> |
| :---: | :---: | :---: |
| **Apps List** | **Dark Theme** | **Material You Accent Colors** |

| <img src="./assets/screenshots/4.app.png" alt="App Page" /> | <img src="./assets/screenshots/5.app_opts.png" alt="App Options" /> | <img src="./assets/screenshots/6.app_webview.png" alt="App Web View" /> |
| :---: | :---: | :---: |
| **App Detail Screen** | **App Update Settings** | **Built-in Web Scraping** |
