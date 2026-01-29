# 🏗️ Technical Architecture

Obtainium+ has undergone significant architectural evolution to support high performance and maintainability. This document outlines the move to a Service-Oriented Architecture and the modern stack used in the "Plus" fork.

---

## 🛠️ Service-Oriented Architecture (SOA)
Starting with version **v1.2.9-p22**, the project successfully migrated from a monolithic `AppsProvider` to a modular service layer. This separation of concerns ensures that business logic is isolated from state management.

### Key Services (`lib/services/`)
- **AppCRUDService**: Encapsulates all Create, Read, Update, and Delete operations for app metadata. It handles the low-level JSON persistence and ensures data integrity during migrations.
- **AppUpdateService**: Manages the logic for checking new versions, handling rate limits (especially for GitHub/GitLab), and caching results to prevent redundant network calls.
- **AppDownloadService**: Coordinates the APK download process, supporting parallel downloads and multi-source preparation.
- **AppInstallService**: Provides a unified API for the Android Package Installer and Shizuku, handling both standard and silent installations.
- **AppIconService**: Manages asynchronous icon retrieval and an LRU (Least Recently Used) memory cache to eliminate scroll jank in large lists.

## 💉 Modern Tech Stack
To improve developer productivity and code robustness, Obtainium+ integrates several industry-standard libraries:
- **Get_it**: Acts as the Service Locator for dependency injection. Services are registered at startup, allowing any part of the app to retrieve them without manual prop-drilling.
- **Dio**: The primary networking client. Unlike the standard `http` package, Dio allows for powerful interceptors, global error handling, and more reliable background requests.
- **Freezed**: Used for immutable data modeling. All core data classes (like `App` and `Settings`) are moving toward Freezed to provide type-safe cloning and robust JSON serialization.
- **GoRouter**: A declarative routing system (`lib/utils/router.dart`) that replaces the legacy imperative navigation. It simplifies deep linking and nested routes for settings sub-menus.

## 🎛️ Settings & Feature Gating
Obtainium+ uses a sophisticated "Master Toggle" system in `SettingsProvider.dart` to support **Vanilla Mode**.

### The Logic
Each "Plus" feature is gated by a composite boolean flag. If the master switch (`enableAllPlusFeatures`) is toggled off, all derivative flags return `false`, regardless of their individual stored values.
```dart
bool get plusEnableGridView => enableAllPlusFeatures && (prefs?.getBool('plusEnableGridView') ?? true);
```

### Dynamic UI Rendering
Major pages (Settings, App Details) act as controllers that check these flags to decide whether to render the "Modern" M3 layout or the "Legacy" UI ported from the original upstream repository.

## 🚀 Performance Optimization Strategies
- **Modular Rebuilds**: The Settings page was refactored from a 1400-line monolith into 5 specialized section widgets. By using the `Consumer` pattern, rebuilds were reduced by **80-90%**.
- **Icon Precaching**: `AppIconService` predictively loads app icons into the memory cache based on the user's scroll position, ensuring 60fps scrolling even in Grid View.
- **RepaintBoundary**: High-cost UI elements (like animated grid tiles) are wrapped in `RepaintBoundary` to isolate paint operations and reduce GPU overhead.

---
*For a detailed history of these optimizations, see the [OPTIMIZATION_ROADMAP.md](https://github.com/thejaustin/ObtainiumPlus/blob/main/OPTIMIZATION_ROADMAP.md) file.*
