# What's New in Obtainium+

This changelog highlights the major new features, stability improvements, and visual refinements across the latest ten releases.

---

## 🚀 Version 1.4.3-p9 — App Renaming, Store Defaults & Warning Slider (May 2026)
*   **App Identity Shift**: Shifted the app name back to **Obtainium+** and updated the official package ID/codename to `dev.thejaustin.obtainiumplus` for full identity consistency.
*   **Customizable Warning Slider**: Added a dynamic settings slider allowing users to adjust the exact check threshold (from 1 to 50 apps) for automated Play Store dispenser check warnings.
*   **Default Store Routing**: Automatically scans for F-Droid, Droidify, and Aurora Store installations on your device. Easily set a default store to route the main "Install/Update" button clicks.
*   **Aesthetic Polish & Safe Layouts**: Implemented dynamic Material 3 Expressive (M3E) scaling and border-radius rules. Applied strict ellipsis text truncation constraints to guarantee zero overlapping text or layout overflows on details sheets and lists.

## 🐛 Version 1.4.3-p8 — Onboarding Fixes & Diagnostic Retries (May 2026)
*   **Google Login Fix**: Replaced native GSF dialog calls with an efficient, silent microG availability check to prevent unexpected account popup sheets on first app launch.
*   **Network & Source Retries**: Added robust HTTP, Socket, and Handshake timeout retries for unstable download hosts like APKPure.
*   **Sentry Exception Safeguards**: Wrapped underlying platform calls in solid try-catch layers to prevent null-pointer crashes during package verification.
*   **Live Logger (Talker) Integration**: Introduced a real-time diagnostic error tracker inside local testing sessions to cleanly log background network activities.

## 🏗️ Version 1.4.3-p4 — Core Architecture Modularization (May 2026)
*   **Settings Engine Deconstruction**: Decomposed the monolithic "God Class" SettingsProvider into five specialized, high-performance providers:
    *   `ThemeSettingsProvider` (Colors, Material You, visual effects)
    *   `UpdateSettingsProvider` (Schedules, intervals, checks)
    *   `BehaviorSettingsProvider` (Haptics, swipe actions, deep logs)
    *   `ViewSettingsProvider` (Lists, grids, categories, layout styles)
    *   `PlusSettingsProvider` (Plus visual filters, glassmorphic opacities)
*   **Enhanced Memory Efficiency**: Significantly minimized state rebuilds when scrolling deep app lists or reordering categories.

## 📊 Version 1.4.3 — Streamlined Add App & Statistics (January 2026)
*   **Unified Add App Page**: Replaced the separate tab views (URL, Discover, Import/Export) with a single, elegant scrollable viewport for faster inputs.
*   **Troubleshooting Dashboard**: Added a diagnostic dashboard showing live installation counts, system metrics, and comprehensive local update statistics.
*   **Offline Operation Queue**: Manual updates requested while offline are safely queued and auto-triggered once a network connection is verified.

## 🔍 Version 1.2.9-p50 — Advanced Discovery Filters (January 2026)
*   **Forks in Search Results**: Added a dedicated settings toggle to optionally include source forks during GitHub Discover keyword queries.
*   **F-Droid Repository Sync**: Stabilized background parsing for custom third-party F-Droid index signatures.

## 📱 Version 1.2.9-p49 — Performance Optimization & Layouts (January 2026)
*   **Reduced Memory Footprint**: Optimized image rendering for cached remote icons in both Dashboard lists and detailed tiles.
*   **Dynamic Fluid Spacing**: Polished general layouts and padding rules to scale beautifully on varying screen sizes (including foldable devices and tablets).

## 🎨 Version 1.2.9-p48 — Modern Material 3 (M3) Enhancements (January 2026)
*   **Compatibility Updates**: Updated core color schemes and styles for full compatibility with newer Flutter 3.38 theme engines.
*   **Granular Header Controls**: Introduced premium custom app bar styles and header toggle selectors to personalize the top dashboard.

## 💎 Version 1.2.9-p47 — Plus Feature-Gate System (January 2026)
*   **Custom Feature Switches**: Launched the initial toggle panel under Settings to configure or deactivate individual Plus additions.
*   **Scheduled Update Windows**: Set specific hours during which background automatic update checks are permitted to run (saving battery and data usage).
*   **ObtainiumPlus Package Migration**: Relocated basic platform hooks to support the initial `app.obtainiumplus` package configurations.

## 🛡️ Version 1.2.9-p46 — Stability Enhancements & Safe Sheets (January 2026)
*   **Details Page Text Fixes**: Resolved layout bugs where extremely long app descriptions or change lists would overlay text buttons.
*   **Discover Empty State**: Rebuilt empty dashboard screens with helpful direct shortcuts to open the repository Discovery page.
*   **WebViewController Leak Fixes**: Fixed background memory leaks associated with Web Scraper fallback sessions.

## 🛠️ Version 1.2.9-p44 — Submenus & Contrast Adjustments (January 2026)
*   **Modern Settings Submenus**: Transitioned the settings sheet from a long single page to modular nested sheets with SharedAxisTransitions.
*   **Dark Mode Visual Contrast**: Adjusted background tinting and text brightness to maximize readability under high-contrast dark modes.

---

— Antigravity (Gemini Agent)
