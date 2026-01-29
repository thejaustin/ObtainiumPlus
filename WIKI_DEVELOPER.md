# Developer Guide: Obtainium+ Architecture

This document provides a technical deep dive into the Obtainium+ fork for developers and contributors.

## 🏗️ Service-Oriented Architecture (v1.2.9-p22)

We have moved away from the monolithic `AppsProvider` pattern to improve maintainability and testability.

### Specialized Services
- **AppCRUDService**: Encapsulates all Create, Read, Update, and Delete operations for app metadata. Uses `SharedPreferences` for persistence.
- **AppDownloadService**: Manages the download queue, progress tracking, and file system interactions for APK downloads.
- **AppInstallService**: Provides a unified interface for the System Package Installer and Shizuku integration.
- **AppIconService**: Handles asynchronous icon retrieval and manages the LRU memory cache.

## 💉 Dependency Injection & Stack
- **Get_it**: Services are registered and retrieved via `Get_it`, allowing for loose coupling and easy mocking in tests.
- **Dio**: The primary networking client, utilizing interceptors for robust error handling and logging.
- **GoRouter**: A declarative routing system that simplifies deep linking and nested navigation.
- **Freezed**: Used for immutable data classes, providing type-safe copy/clone methods and JSON serialization.

## 🎛️ Feature Gating System

Every "Plus" feature is strictly gated to allow for the **Vanilla Mode** toggle system.

### The Implementation
Gating is handled in `SettingsProvider.dart` using a composite getter pattern:

```dart
bool get plusEnableMyFeature => enableAllPlusFeatures && (prefs?.getBool('plusEnableMyFeature') ?? true);
```

### Dynamic UI Loading
The app uses "Controller" patterns for major pages to support legacy UI fallback:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (settings.plusEnableModernSettings) return ModernSettingsPage();
    return LegacySettingsPage();
  }
}
```

## 🛠️ Performance Optimizations
- **Widget Modularization**: Settings sections are split into individual files (`lib/components/settings/`) to isolate rebuilds.
- **Consumer Pattern**: Uses `Provider`'s `Consumer` widget at the lowest possible level to ensure only the necessary UI elements rebuild on state change.
- **Icon Precaching**: Predictively loads app icons based on scroll position using `precacheIcons`.
- **RepaintBoundary**: Expensive list and grid items are wrapped in `RepaintBoundary` to reduce paint overhead during scrolling.
