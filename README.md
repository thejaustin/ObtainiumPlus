<div align="center"><a href="https://github.com/Safouene1/support-palestine-banner/blob/master/Markdown-pages/Support.md"><img src="https://raw.githubusercontent.com/Safouene1/support-palestine-banner/master/banner-support.svg" alt="Support Palestine" style="width: 100%;"></a></div>

# ![Obtainium Icon](./assets/graphics/icon_small.png) Obtainium+

Get Android app updates straight from the source.

> **Note:** This is a fork of [Obtainium](https://github.com/ImranR98/Obtainium) with additional features and improvements.

Obtainium allows you to install and update apps directly from their releases pages, and receive notifications when new releases are made available.

## About This Fork

Obtainium+ is a feature-enhanced fork of Obtainium with improvements focused on user experience and simplified deployment.

### ✨ New Features

#### Collapse Categories by Default
- **New Setting:** Toggle to collapse all category groups when opening the app
- **Location:** Settings → Below "Group by category" option
- **Use Case:** Keeps your app list clean and organized, especially useful with many categories
- **How it works:** When enabled, all category groups start collapsed; tap to expand individual categories as needed

### 🔧 Technical Improvements

#### Automated Build System
- **Signed APKs via GitHub Actions:** All releases are automatically signed and ready to install
- **No local build required:** Trigger builds directly from GitHub Actions workflow
- **Universal APK only:** Single APK works on all device architectures (ARM, x86_64)
- **Simplified workflow:** Removed F-Droid flavor builds (normal flavor only)

### 📦 Version Naming

This fork uses a unique versioning scheme:
- **Format:** `1.2.9-pX` where `X` = number of patches/commits since forking
- **Current:** `1.2.9-p3` (3 commits beyond upstream v1.2.9)
- **Purpose:** Track fork-specific changes while maintaining upstream version reference

### 🚀 Planned Features

See [GitHub Issues](https://github.com/thejaustin/ObtainiumPlus/issues) for upcoming features:
- [#1 Drag-to-Reorder Categories](https://github.com/thejaustin/ObtainiumPlus/issues/1) - Customize category display order
- [#2 Additional Sorting Methods](https://github.com/thejaustin/ObtainiumPlus/issues/2) - More app sorting options

### 📊 What's Different from Original Obtainium?

| Feature | Original Obtainium | Obtainium+ |
|---------|-------------------|------------|
| **Collapse Categories** | ❌ Always expanded | ✅ Optional setting to collapse by default |
| **APK Signing** | ⚠️ Manual signing required | ✅ Automatic via GitHub Actions |
| **Build Flavors** | Normal + F-Droid | Normal only (simplified) |
| **APK Types** | Universal + Split per ABI | Universal only |
| **Build Method** | Local SDK required | GitHub Actions (no SDK needed) |
| **Version Tracking** | Semantic versioning | Semantic + patch count (`-pX`) |
| **App Name** | Obtainium | Obtainium+ |

## Original Obtainium Resources

- [Obtainium Wiki](https://wiki.obtainium.imranr.dev/) ([repository](https://github.com/ImranR98/Obtainium-Wiki))
- [Obtainium 101](https://www.youtube.com/watch?v=0MF_v2OBncw) - Tutorial video
- [AppVerifier](https://github.com/soupslurpr/AppVerifier) - App verification tool (recommended, integrates with Obtainium)
- [apps.obtainium.imranr.dev](https://apps.obtainium.imranr.dev/) - Crowdsourced app configurations ([repository](https://github.com/ImranR98/apps.obtainium.imranr.dev))
- [Side Of Burritos - You should use this instead of F-Droid | How to use app RSS feed](https://youtu.be/FFz57zNR_M0) - Original motivation for this app
- [Original Obtainium Repository](https://github.com/ImranR98/Obtainium)

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
  - [Huawei AppGallery](https://appgallery.huawei.com/)
  - [Tencent App Store](https://sj.qq.com/)
  - [CoolApk](https://coolapk.com/)
  - [vivo App Store (CN)](https://h5.appstore.vivo.com.cn/)
  - [RuStore](https://rustore.ru/)
  - [Farsroid](https://www.farsroid.com)
  - Jenkins Jobs
  - [APKMirror](https://apkmirror.com/) (Track-Only)
- Other - App-Specific:
  - [Telegram App](https://telegram.org/)
  - [Neutron Code](https://neutroncode.com/)
- Direct APK Link
- "HTML" (Fallback): Any other URL that returns an HTML page with links to APK files

## Finding App Configurations

You can find crowdsourced app configurations at [apps.obtainium.imranr.dev](https://apps.obtainium.imranr.dev).

If you can't find the configuration for an app you want, feel free to leave a request on the [discussions page](https://github.com/ImranR98/apps.obtainium.imranr.dev/discussions/new?category=app-requests).

Or, contribute some configurations to the website by creating a PR at [this repo](https://github.com/ImranR98/apps.obtainium.imranr.dev).

## Installation

[<img src="https://github.com/machiav3lli/oandbackupx/blob/034b226cea5c1b30eb4f6a6f313e4dadcbb0ece4/badge_github.png"
    alt="Get it on GitHub"
    height="80">](https://github.com/thejaustin/ObtainiumPlus/releases)

### How to Install

1. Go to [Releases](https://github.com/thejaustin/ObtainiumPlus/releases)
2. Download `app-release.apk` (universal APK, works on all Android devices)
3. Install the APK on your device
   - You may need to enable "Install from unknown sources" in your device settings

**Note:** All APKs are automatically signed via GitHub Actions and ready to install.

### Verification Info

- Package ID: `dev.imranr.obtainium`
- Signing certificate is unique to this fork (different from original Obtainium)

## Development

For developers who want to contribute:

```bash
# Get dependencies
flutter pub get

# Run in development mode
flutter run
```

**Note:** Production APKs are built and signed automatically via GitHub Actions. Pre-built releases are available in the [Releases](https://github.com/thejaustin/ObtainiumPlus/releases) section.

## Contributing

Contributions are welcome! Please:
1. Check [existing issues](https://github.com/thejaustin/ObtainiumPlus/issues) first
2. Create a new issue to discuss major changes
3. Submit pull requests with clear descriptions

## Limitations
- For some sources, data is gathered using Web scraping and can easily break due to changes in website design. In such cases, more reliable methods may be unavailable.

## Screenshots

| <img src="./assets/screenshots/1.apps.png" alt="Apps Page" /> | <img src="./assets/screenshots/2.dark_theme.png" alt="Dark Theme" />           | <img src="./assets/screenshots/3.material_you.png" alt="Material You" />    |
| ------------------------------------------------------ | ----------------------------------------------------------------------- | -------------------------------------------------------------------- |
| <img src="./assets/screenshots/4.app.png" alt="App Page" />   | <img src="./assets/screenshots/5.app_opts.png" alt="App Options" /> | <img src="./assets/screenshots/6.app_webview.png" alt="App Web View" /> |
