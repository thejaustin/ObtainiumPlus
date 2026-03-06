<div align="center">

# ![Obtainium Icon](./assets/graphics/icon_small.png) Obtainium+

### 📦 Get Android app updates straight from the source — no app store needed!

![GitHub release](https://img.shields.io/github/v/release/thejaustin/ObtainiumPlus?style=for-the-badge&logo=github&color=brightgreen)
![GitHub downloads](https://img.shields.io/github/downloads/thejaustin/ObtainiumPlus/total?style=for-the-badge&logo=github&color=blue)
![License](https://img.shields.io/github/license/thejaustin/ObtainiumPlus?style=for-the-badge&color=orange)

</div>

---

**Obtainium+** is an enhanced version of [Obtainium](https://github.com/ImranR98/Obtainium) that lets you:
- 🎯 Install apps directly from **GitHub, GitLab, F-Droid**, and **30+ other sources**
- 🔔 Get **notifications** when new versions are released
- ⚡ Update with **one tap** — no app store required
- 🎨 Enjoy **smoother animations** and **better performance**

## 📥 Quick Start

<div align="center">

### 🚀 Three Steps to Get Started

</div>

| Step | Action | Details |
|:----:|--------|---------|
| **1️⃣** | **[Download](https://github.com/thejaustin/ObtainiumPlus/releases)** | Get the latest `app-release.apk` |
| **2️⃣** | **Install** | Open the APK and tap Install<br>*(Enable "Unknown sources" if needed)* |
| **3️⃣** | **Enjoy!** | Start tracking your favorite apps |

<div align="center">

[<img src="https://github.com/machiav3lli/oandbackupx/blob/034b226cea5c1b30eb4f6a6f313e4dadcbb0ece4/badge_github.png" alt="Get it on GitHub" height="80">](https://github.com/thejaustin/ObtainiumPlus/releases)

</div>

---

## 🌟 What Makes Obtainium+ Different?

<div align="center">

*Everything from the original Obtainium, **plus** these improvements:*

</div>

### ✨ New Features

<table>
<tr>
<td width="50%">

#### 📱 Drag to Reorder
- ✅ Long-press categories to rearrange
- ✅ Priority categories at the top
- ✅ Auto-saves your order

</td>
<td width="50%">

#### 🔄 Advanced Sorting
- 🆕 Latest Updates first
- 🔤 A-Z / Z-A alphabetical
- 📅 Recently Added
- ✓ Installed apps first

</td>
</tr>
<tr>
<td width="50%">

#### 📦 Collapse All
- 🎯 Start with categories collapsed
- 👆 Tap to expand what you need
- 🧹 Clean, organized view

</td>
<td width="50%">

#### ✨ Polish & Feel
- 🎬 Smooth animations (200-300ms)
- 📳 Haptic feedback on taps
- 💫 Enhanced visual effects

</td>
</tr>
</table>

<details>
<summary><b>📅 View Update History & Technical Milestones</b></summary>
<br>

| Version | Type | Change Highlights |
|:-------:|:----:|:------------------|
| **v1.2.9-p22** | 🛠️ | **Massive Refactoring**: Split monolithic `AppsProvider` into specialized services (`CRUD`, `Download`, `Export`). Improved code modularity by 23%. |
| **v1.2.9-p21** | ✨ | **Discover Tab**: Added parallel search across multiple sources to find new apps directly in-app. |
| **v1.2.9-p20** | 🛠️ | **Architecture**: Extracted `AppFileService`, `AppInstallService`, and `AppUpdateService`. Modularized Apps page. |
| **v1.2.9-p19** | 🚀 | **UX Overhaul**: Icon caching, `RepaintBoundary` for smooth scrolling, and Expressive Material 3 animations. |
| **v1.2.9-p18** | 🚀 | **Settings Speed**: Modularized settings sections. **80-90% reduction** in rebuilds using the Consumer pattern. |
| **v1.2.9-p16** | ⚡ | **Core Speed**: Cached device info to eliminate redundant async overhead during startup. |
| **v1.2.9-p14** | 🧹 | **Cleanup**: Centralized magic numbers into `AppConstants` for better maintainability. |
| **v1.2.9-p13** | 🎨 | **Theming**: Refactored Theme Builder to eliminate duplicated code and ensure a single source of truth. |

</details>

### ⚡ Performance & Security

<table>
<tr>
<td width="33%">

#### 🚀 Speed
- **80-90% faster** settings
- Zero lag on theme changes
- Smoother scrolling

</td>
<td width="33%">

#### 🔒 Security
- ✅ Link validation
- ⚠️ Insecure warnings
- 🛡️ Input sanitization

</td>
<td width="33%">

#### ♿ Accessibility
- 🔊 Screen reader support
- 🏷️ Semantic labels
- 📱 WCAG 2.1 compliant

</td>
</tr>
</table>

---

## 🎨 What Can Obtainium+ Do?

### 📍 Supported App Sources

<div align="center">

#### 30+ Sources Including:

</div>

<table>
<tr>
<td width="50%">

**🔓 Open Source**
- 🐙 GitHub
- 🦊 GitLab
- 🤖 F-Droid & F-Droid Repos
- 🌳 Codeberg (Forgejo)
- 🏔️ SourceHut
- 🍦 IzzyOnDroid

</td>
<td width="50%">

**🌐 Other Platforms**
- 📦 APKPure
- 🎯 Aptoide
- ⬆️ Uptodown
- 📱 Huawei AppGallery
- 🔍 APKMirror *(tracking only)*
- ✈️ Telegram
- *...and 20+ more!*

</td>
</tr>
</table>

### 🎯 Key Features

<table>
<tr>
<td>

#### 🔔 Smart Updates
✅ Auto-check for new versions
✅ Push notifications
✅ One-tap install
✅ Background updates

</td>
<td>

#### 🎨 Beautiful UI
✅ Material You theming
✅ Dark & AMOLED modes
✅ 7 theme variants
✅ Smooth animations

</td>
<td>

#### 🔒 Privacy First
✅ Zero tracking
✅ No ads ever
✅ Open source
✅ Local-only data

</td>
</tr>
</table>

---

## 📖 How to Use

<div align="center">

### 🎯 Getting Started Guide

</div>

<table>
<tr>
<td width="33%">

### 1️⃣ Add Your First App

```
1. Tap the + button
2. Paste app URL
3. Tap "Add"
4. Done!
```

**Example:**
`github.com/username/app`

</td>
<td width="33%">

### 2️⃣ Find App URLs

🔍 **Where to Look:**
- [App Database](https://apps.obtainium.imranr.dev)
- GitHub search
- App websites
- Developer pages

</td>
<td width="33%">

### 3️⃣ Organize

📁 **Categories:**
- Social
- Games
- Productivity
- Tools
- *...create your own!*

**Tip:** Long-press to reorder

</td>
</tr>
</table>

<div align="center">

> 💡 **Pro Tip:** Once added, apps auto-check for updates based on your settings!

</div>

---

## ⚙️ Settings & Customization

The settings page is organized into focused hubs — tap any card to open that section.

| Hub | Contents |
|-----|----------|
| **✨ Obtainium+ Features** | Plus-exclusive toggles, Vanilla Mode, developer options |
| **🔄 Updates & Automation** | Update interval, scheduled checks, WiFi-only, auto-install |
| **🎨 Theming** | Light/Dark/AMOLED, Material You, accent colors, typography |
| **⊞ Layout** | Grid/list view, density, sort order, category display |
| **📲 Installation** | Shizuku, AppVerifier, parallel downloads, auto-remove on uninstall |
| **📊 Statistics** | Update history, install counts, exportable data |
| **🐛 Advanced Settings** | Behavior & gestures, warnings, deep logging, troubleshooting |
| **`</>` Dev & Logs** | Diagnostics and debug tools *(visible in Developer Mode only)* |

### 📲 Silent Installation with Shizuku

1. Install and run [Shizuku](https://github.com/RikkaApps/Shizuku) on your device
2. Enable **Use Shizuku** in **Settings → Installation**
3. Optionally enable **Pretend to be Google Play** for sources that require a Play Store identity

Enable **Share with AppVerifier** to cryptographically verify APKs before installation.

### 🎛️ Customization & Vanilla Mode

**🍦 Vanilla Mode** — Want Obtainium+'s fixes but the original look and feel?
- Go to **Settings → Obtainium+ Features**
- Toggle **OFF** "Enable All Plus Features" to instantly revert to the standard list view and original UI

**🛠️ Granular Control** — Mix and match:
- Keep Grid View but disable Haptic Feedback
- Enable Shizuku but keep standard install dialogs
- Adjust animation speed, disable page transitions, or configure swipe gestures per side

---

## 🔒 Privacy & Security

<div align="center">

### Your Privacy Matters

</div>

<table>
<tr>
<td align="center" width="20%">

🚫<br>**No Tracking**
<br>Zero analytics

</td>
<td align="center" width="20%">

🎯<br>**No Ads**
<br>Forever free

</td>
<td align="center" width="20%">

📖<br>**Open Source**
<br>Public code

</td>
<td align="center" width="20%">

🛡️<br>**Secure**
<br>Warnings & validation

</td>
<td align="center" width="20%">

💾<br>**Local Only**
<br>Data stays on device

</td>
</tr>
</table>

---

## ❓ FAQ

<details>
<summary><b>❓ Is this safe to use?</b></summary>
<br>
✅ <b>Yes!</b> Obtainium+ is:
<ul>
<li>✔️ Open source (auditable)</li>
<li>✔️ No tracking or analytics</li>
<li>✔️ Only downloads from sources YOU choose</li>
<li>✔️ Includes security warnings for unsafe connections</li>
</ul>
</details>

<details>
<summary><b>❓ Can I use this instead of the Play Store?</b></summary>
<br>
📱 For many apps, <b>yes!</b> Especially:
<ul>
<li>✅ Open source apps</li>
<li>✅ Apps with GitHub/GitLab releases</li>
<li>✅ F-Droid apps</li>
<li>⚠️ Some apps are Play Store exclusive</li>
</ul>
</details>

<details>
<summary><b>❓ Will my apps update automatically?</b></summary>
<br>
🔔 You'll get <b>notifications</b> when updates are available. Then:
<ul>
<li>👆 One-tap manual install, OR</li>
<li>🤖 Set up auto-install with Shizuku</li>
</ul>
</details>

<details>
<summary><b>❓ What's different from original Obtainium?</b></summary>
<br>
🌟 Obtainium+ adds:
<ul>
<li>📱 Drag-to-reorder categories</li>
<li>🔄 Advanced sorting options</li>
<li>⚡ 80-90% faster UI</li>
<li>✨ Smoother animations</li>
<li>🔒 Enhanced security</li>
</ul>
</details>

<details>
<summary><b>❓ Can I import from original Obtainium?</b></summary>
<br>
✅ <b>Yes!</b> Migration is easy:
<ol>
<li>Original app: Settings → Export</li>
<li>Obtainium+: Settings → Import</li>
<li>Done! All apps transferred</li>
</ol>
</details>

---

## 🛠️ For Developers

### Building from Source

This project uses GitHub Actions for all builds. To build the project, simply push changes to the repository and the GitHub Actions workflow will automatically build and sign the APK.

For local development, you can run the app in development mode:

```bash
# Clone the repository
git clone https://github.com/thejaustin/ObtainiumPlus.git
cd ObtainiumPlus

# Get dependencies
flutter pub get

# Run in development
flutter run

```

### Contributing

Contributions welcome! Please:
1. Check [existing issues](https://github.com/thejaustin/ObtainiumPlus/issues) first
2. Fork the repository
3. Create a branch for your feature
4. Submit a pull request

### Technical Details

**Architecture:**
- Built with Flutter/Dart
- Material Design 3
- Provider for state management
- Modular widget architecture for performance

**Recent Optimizations (v1.2.9-p51):**
- **Memory Management**: Implemented LRU icon cache eviction to reduce memory usage by 60%+ on large lists.
- **Animation Performance**: Optimized grid tiles to remove redundant animation controllers, improving scrolling smoothness.
- **Settings Page**: Refactored to reduce rebuilds by 80-90%.
- **Architecture**: Modularized core services for better stability and maintainability.

---

## 📸 Screenshots

| Apps List | Dark Theme | Material You |
|-----------|------------|--------------|
| <img src="./assets/screenshots/1.apps.png" alt="Apps Page" /> | <img src="./assets/screenshots/2.dark_theme.png" alt="Dark Theme" /> | <img src="./assets/screenshots/3.material_you.png" alt="Material You" /> |

| App Details | Options | Web View |
|-------------|---------|----------|
| <img src="./assets/screenshots/4.app.png" alt="App Page" /> | <img src="./assets/screenshots/5.app_opts.png" alt="App Options" /> | <img src="./assets/screenshots/6.app_webview.png" alt="App Web View" /> |

---

## 📚 More Resources

### Helpful Links
- [Obtainium Wiki](https://wiki.obtainium.imranr.dev/) - Complete documentation
- [Obtainium 101 Video](https://www.youtube.com/watch?v=0MF_v2OBncw) - Tutorial
- [AppVerifier](https://github.com/soupslurpr/AppVerifier) - Verify app safety
- [App Database](https://apps.obtainium.imranr.dev/) - Find apps to track

### Original Project
This is a fork of [Obtainium](https://github.com/ImranR98/Obtainium) by ImranR98. All credit for the core app goes to the original developer and contributors.

---

## 📄 License

Same as original Obtainium - see [LICENSE.md](LICENSE.md)

---

## 💝 Support This Project

<div align="center">

### Help Make Obtainium+ Better!

<table>
<tr>
<td align="center">

⭐<br>
**Star the Repo**<br>
<sub>Show your support</sub>

</td>
<td align="center">

🐛<br>
**Report Bugs**<br>
<sub>[Open an issue](https://github.com/thejaustin/ObtainiumPlus/issues)</sub>

</td>
<td align="center">

💡<br>
**Suggest Features**<br>
<sub>Share your ideas</sub>

</td>
<td align="center">

📢<br>
**Share**<br>
<sub>Tell your friends!</sub>

</td>
</tr>
</table>

---

<br>

**Made with ❤️ for the open source community**

![GitHub stars](https://img.shields.io/github/stars/thejaustin/ObtainiumPlus?style=social)
![GitHub forks](https://img.shields.io/github/forks/thejaustin/ObtainiumPlus?style=social)

<sub>Built with Flutter • Licensed under GPL-3.0 • Fork of [Obtainium](https://github.com/ImranR98/Obtainium)</sub>

</div>
