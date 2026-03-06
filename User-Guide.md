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

## ⚙️ Settings Hub Overview

The settings page uses a **hub-and-spoke** layout. Each card opens a focused settings sheet.

| Hub | What's inside |
|-----|--------------|
| **Obtainium+ Features** | Vanilla Mode master switch, grid view, icon cache, animations |
| **Updates & Automation** | Background check interval, WiFi-only, scheduled windows |
| **Theming** | Light/Dark/AMOLED, Material You, accent color, font |
| **Layout** | List/grid density, sort order, swipe gestures, category display |
| **Installation** | Shizuku, AppVerifier, parallel downloads, auto-remove |
| **Statistics** | Per-app update history and install counts |
| **Advanced Settings** | App behavior, page transitions, haptics, warnings, deep logging |
| **Dev & Logs** | Error logs, diagnostics *(visible only in Developer Mode)* |

> **Developer Mode:** Long-press the **App Info** button at the bottom of Settings to toggle it on/off.

## 📲 Silent Installs with Shizuku

Shizuku lets Obtainium+ install and update apps silently without a system dialog.

1. Download and run [Shizuku](https://github.com/RikkaApps/Shizuku)
2. Open **Settings → Installation → Use Shizuku** and enable it
3. Grant the permission prompt — if permission is denied, the toggle stays off automatically
4. Optionally enable **Pretend to be Google Play** if a source requires a Play Store identity

> **AppVerifier:** Enable *Share new apps with AppVerifier* to cryptographically check APKs before they install.

## 🎮 App Behavior & Gestures

Found in **Settings → Advanced Settings → App Behavior**:

- **Swipe gestures** — assign actions (Update, Pin, Share, Launch, Delete, None) to left/right swipes independently
- **Animation speed** — scale UI animation duration (50%–200%)
- **Page transitions** — disable or reverse screen switch animations
- **Haptic feedback** — vibrate on interactions
- **Undo app removal** — undo deletions within a few seconds via snackbar

## ⚡ Performance Tips
- **Background Updates**: Set your update interval in `Settings → Updates & Automation`. Enable **Scheduled Updates** to limit checks to specific hours (e.g., overnight).
- **Undo Removal**: Accidentally deleted an app? Enable *Undo app removal* in Advanced Settings, then tap "Undo" in the snackbar before it disappears.
- **Haptic Feedback**: Subtle tactile feedback on interactions — toggle in **Advanced Settings → App Behavior**.

---
*For technical details on how these features are implemented, see the [Technical Architecture](Technical-Architecture.md) guide.*
