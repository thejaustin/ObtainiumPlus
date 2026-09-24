# 📖 Obtainium+ User Guide

Welcome to **Obtainium+**, the performance-focused, feature-rich fork of Obtainium. This guide will walk you through the unique features of the "Plus" version and help you get the most out of your app management experience.

---

## 📦 What is Obtainium+?
Obtainium+ is an enhanced version of Obtainium that lets you install and update Android apps directly from their source (GitHub, GitLab, F-Droid, etc.). While it remains fully compatible with original Obtainium exports, it introduces significant performance optimizations, a modern Material 3 interface, and powerful new features like **Discover** and **Vanilla Mode**.

## 🔍 Discovering New Apps
Finding apps to track is easier than ever with the **Discover** tab.
1. Tap the **Add App** tab (or the **Discover** icon if enabled in your navigation bar).
2. Enter the name of an app or a keyword in the search bar.
3. Obtainium+ searches across multiple sources (GitHub, GitLab, etc.) simultaneously.
4. Tap any result to see details and add it to your tracking list with a single tap.

## 🖼️ Grid View
For a more visual experience, you can switch from the traditional list to the **Grid View**.
- **Enable**: Go to `Settings > View Options` and change the **Global View Mode** to "Grid".
- **Customization**: You can set a custom number of columns (up to 6) and choose whether to group apps by category within the grid.
- **Category Overrides**: You can even set specific categories to use Grid View while keeping others in List View.

## 🍦 Vanilla Mode
We understand that some users prefer the classic Obtainium look. **Vanilla Mode** allows you to revert the entire UI to the original upstream design while keeping the "Plus" performance improvements under the hood.
- **How to Toggle**: Go to `Settings > Obtainium+ Features`.
- **Master Switch**: Toggle **OFF** "Enable All Plus Features" to immediately revert to the classic list-based UI, original animations, and standard density.
- **Granular Control**: You can also pick and choose! Keep the performance fixes but disable the new Modern Settings or the Modern App Details page individually.

## 📁 Organization & Sorting
Obtainium+ gives you advanced control over your app list:
- **Category Reordering**: Long-press any category header to drag and drop categories into your preferred order.
- **Advanced Sorting**: Use the sort icon to organize apps by *Latest Updates*, *Recently Added*, *Install Status*, or *Alphabetical (A-Z/Z-A)*.
- **Quick Filters**: Use the chips at the top of your apps list to quickly show only apps with "Updates Available" or "Not Installed".

## ⚙️ Settings Overview

The settings page features categorized tabs along with a top **Obtainium+ Features** quick-access card.

| Section | What's inside |
|---------|--------------|
| **Obtainium+ Features** | Master toggle, OneUI header reachability, floating dock, action capsule, app tile styling, and visual toggles |
| **Appearance** | Light/Dark/AMOLED, Material You dynamic scheme variants, curated palette presets, and view options (List/Grid) |
| **Updates & Install** | Background intervals, scheduled check windows, Shizuku Turbo, silent installs, and AppVerifier |
| **Notifications** | Update alert preferences, background notifications, and channels |
| **Behavior** | Swipe gestures, animation scale, page transitions, and tactile haptic feedback |
| **Advanced & Debug** | Device optimization sheet, deep diagnostics, export/import encryption, and developer logs |

> **Developer Mode:** Long-press the **App Info** button at the bottom of Settings to toggle it on/off.

## 📱 OneUI Reachability Header

Obtainium+ features a collapsible OneUI-style header for easy one-handed reachability:
- **Title Shift & Pull-Down**: Pull down on your app list to smoothly bring top items within thumb's reach. The title shifts down into an oversized headline.
- **Contextual Subtitles**: Glanceable metadata below the header displaying total tracked apps and pending updates (`"18 apps · 3 updates"`).
- **Customizable**: Toggle in **Settings → Obtainium+ Features → OneUI Reachability Header**.

## 🚤 Floating Navigation Dock & Action Capsule

- **Floating Navigation Dock**: Replaces the traditional flat-edge navigation bar with a modern floating frosted-glass island dock.
- **Floating Action Capsule**: On the App Detail screen, quick actions (Install, Update, Web, Options) float gracefully above content inside a frosted pill capsule.
- **Toggle**: Configure independently in **Settings → Obtainium+ Features**.

## 🎨 App Tile Visual Customization

Tailor the look and feel of app tiles to your preference:
- **Pinned Border Accent**: Highlight pinned apps with an elegant primary accent border.
- **Category Accent Ribbon**: Add a subtle colored vertical indicator strip to the leading edge of tiles matching their category color.
- **Expressive Version Pill**: Display update targets in a compact rounded tonal pill (`↓ 2.4.0`) rather than standard buttons.
- **Icon Rim Border**: Frame app icons with a crisp specular rim.
- **Stadium Filter Chips**: Fully rounded pill chips for tags and category filters.

## 📲 Silent Installs with Shizuku & Shizuku Turbo

Shizuku lets Obtainium+ install and update apps silently without a system confirmation dialog.

1. Download and run [Shizuku](https://github.com/RikkaApps/Shizuku).
2. Open **Settings → Updates & Install → Installation → Use Shizuku** and enable it.
3. Grant the permission prompt — if permission is denied, the toggle stays off automatically.
4. Enable **Shizuku Turbo** for high-throughput I/O buffering and adaptive fast polling during batch updates.
5. Optionally enable **Pretend to be Google Play** if a source requires a Play Store identity.

> **Device Optimization**: Access OEM-specific battery and background guidance for Samsung, Xiaomi, OnePlus, Vivo, Huawei, Nothing OS, and Transsion under **Settings → Advanced & Debug → Device Optimization**.

## 🎮 App Behavior & Gestures

Found in **Settings → Behavior → App Behavior**:

- **Swipe gestures** — assign actions (Update, Pin, Share, Launch, Delete, None) to left/right swipes independently.
- **Animation speed** — scale UI animation duration (50%–200%).
- **Page transitions** — disable or reverse screen switch animations.
- **Haptic feedback** — tactile feedback on clicks, selections, and long presses.
- **Undo app removal** — undo accidental deletions within a few seconds via snackbar.

## ⚡ Performance Tips
- **Background Updates**: Set your update interval in `Settings → Updates & Install`. Enable **Scheduled Updates** to limit checks to specific hours (e.g., overnight).
- **Icon Caching**: In-memory LRU caching guarantees stutter-free 120Hz scrolling across large app lists.
- **Haptic Feedback**: Subtle tactile feedback on interactions — toggle in **Settings → Behavior**.

---
*For technical details on how these features are implemented, see the [Technical Architecture](Technical-Architecture.md) guide.*
