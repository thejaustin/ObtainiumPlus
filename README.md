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
  - [itch.io](https://itch.io/)
  - [Huawei AppGallery](https://appgallery.huawei.com/)
  - [Tencent App Store](https://sj.qq.com/)
  - [vivo App Store (CN)](https://h5.appstore.vivo.com.cn/)
  - [RuStore](https://rustore.ru/)
  - [Farsroid](https://www.farsroid.com)
  - [CoolApk](https://coolapk.com/)
  - [LiteAPKs](https://liteapks.com/)
  - [APK4Free](https://apk4free.net/)
  - Jenkins Jobs
  - [APKMirror](https://apkmirror.com/) (Track-Only)
  - [RockMods](https://rockmods.net/) (Track-Only)
- Other - App-Specific:
  - [Telegram App](https://telegram.org/)
  - [Neutron Code](https://neutroncode.com/)
- Direct APK Link
- "HTML" (Fallback): Any other URL that returns an HTML page with links to APK files

You can find crowdsourced app configurations at [apps.obtainium.page](https://apps.obtainium.page).

If you can't find the configuration for an app you want, feel free to leave a request on the [discussions page](https://github.com/ImranR98/apps.obtainium.page/discussions/new?category=app-requests).

Or, contribute some configurations to the website by creating a PR at [this repo](https://github.com/ImranR98/apps.obtainium.page).

| Feature | Original Obtainium | Obtainium+ |
| :--- | :--- | :--- |
| **Design & Look** | Standard Android design | A beautiful "glass-like" interface (glassmorphism) with smooth colors, subtle blurs, and modern text. |
| **Play Store Mirroring** | Scrapes APK links | Secure, direct connections to Google Play mirrors using your own private servers (dispensers) or microG. |
| **Troubleshooting & Logs** | Basic terminal logs | A built-in, easy-to-use diagnostics screen and local crash tracker to solve issues privately. |
| **Instant Settings** | Requires app restarts to apply | Changes to look, feel, and updates apply instantly as you tap them. |
| **Privacy First** | Uses some default third-party servers | Completely tracking-free. No pre-configured server addresses to protect public servers and guarantee your privacy. |

---

## 🚀 Key Features

### 🎨 Beautiful, Modern Design (Glassmorphic Interface)
Obtainium+ features a premium, clean design with smooth color transitions, soft backdrop blurs, and elegant layouts. Standard sharp boxes and high-contrast lines are replaced with a smooth visual style that is easy on the eyes.

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
