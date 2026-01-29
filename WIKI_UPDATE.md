# Obtainium+ Development Timeline

A chronological history of features and improvements added to the Obtainium+ fork.

## 🍦 Vanilla Mode & Toggle Architecture (v1.2.9-p50)

One of the defining features of Obtainium+ is the ability to revert to a "Vanilla" experience while keeping the fork's stability and performance fixes.

### How it Works
We've implemented a **Granular Toggle System** in `SettingsProvider.dart`. Every major "Plus" feature is gated by a boolean flag that defaults to `true`. 

- **Master Switch**: `enableAllPlusFeatures` act as a global override. If off, all Plus features are disabled regardless of their individual settings.
- **Dynamic UI Gating**: 
    - The **SettingsPage** and **AppPage** act as controllers. They check the `plusEnableModernSettings` and `plusEnableModernAppPage` flags to decide whether to render the modern M3 layout or the original "Legacy" UI ported from upstream.
    - **Legacy Support**: We have maintained `LegacySettingsPage.dart` and `LegacyAppPage.dart` which contain the original upstream logic, adapted only for compatibility with our new service-based architecture.

### Feature Matrix
| Feature | Flag | Description |
|---------|------|-------------|
| **Modern Settings** | `plusEnableModernSettings` | Toggles between Search/Sub-menu and Classic List layout. |
| **Modern App Page** | `plusEnableModernAppPage` | Toggles between Responsive M3 and BottomSheet layout. |
| **Grid View** | `plusEnableGridView` | Enables the grid layout option in View Mode. |
| **Discover Tab** | `plusEnableDiscover` | Enables the aggregated app search page. |
| **Swipe Actions** | `plusEnableSwipeActions` | Enables left/right swipe shortcuts on the app list. |
| **Haptic Feedback** | `plusEnableHapticFeedback` | Tactile vibration on user interactions. |
| **UI Customization** | `plusEnableUICustomization` | Gates App Bar styles, Nav labels, and Tile display info. |

---

## 🚀 The "Plus" Era (v1.2.9-p23 to Current)

The modern era of Obtainium+ focuses on user choice, stability, and advanced power-user features.

### ✨ Key Features
- **Vanilla Mode (New)**: A complete toggle system allowing users to revert the entire app (UI and logic) to the "Classic" upstream experience while keeping stability fixes.
- **Undo App Removal**: Restore deleted app entries within 30 seconds using a one-tap Snackbar action.
- **Modern Settings UI**: A complete redesign of the settings page with search functionality, sub-menus, and categorization.
- **Responsive Design**: A new App Details page layout optimized for tablets and foldables.
- **Quick Filters**: One-tap filter chips on the main apps page (Updates, Installed, etc.).
- **Scheduled Updates**: Define active hours and days for background update checks to save battery.
- **Persistent Retry Queue**: Improved reliability for background updates that fail due to network issues.

---

## 🛠️ The Refactoring Era (v1.2.9-p18 to p22)

Focused on code quality, performance, and breaking down the monolithic architecture.

### v1.2.9-p22: Service Architecture & Stack Modernization
- **Massive Refactor**: Split the 2000+ line `AppsProvider` into specialized services:
    - `AppCRUDService`: Adding/Removing apps.
    - `AppDownloadService`: Handling APK downloads.
    - `AppInstallService`: Interaction with OS installers.
- **Tech Stack Upgrade**: 
    - **Dio**: Robust networking with interceptors and better error handling.
    - **GoRouter**: Declarative routing for clean navigation.
    - **Get_it**: Dependency injection for service management.
    - **Freezed**: Type-safe data modeling.
- **Impact**: Significantly improved code maintainability and testing.

### v1.2.9-p21: Discovery
- **Discover Tab**: Added a unified search interface to find apps across multiple sources (GitHub, GitLab, etc.) simultaneously without leaving the app.

### v1.2.9-p19/p20: Performance & Caching
- **Icon Caching**: Implemented a memory-efficient caching system for app icons, solving scroll lag on large lists.
- **Service Extraction**: Moved File and Update logic to dedicated services.

### v1.2.9-p18: Settings Speed
- **Modular Settings**: Refactored the Settings page into independent widgets using the `Consumer` pattern.
- **Result**: Reduced widget rebuilds by 80-90% when changing a setting.

---

## 🎨 The Polish Era (v1.2.9-p1 to p16)

The initial phase of the fork, focusing on visual feel and user experience.

### v1.2.9-p13 to p16: Stability & Accessibility
- **Startup Speed**: Cached device info to remove redundant async calls during app launch.
- **Accessibility**: Comprehensive audit ensuring WCAG 2.1 compliance (semantic labels, touch targets).
- **Security**: Hardened link validation.

### v1.2.9-p5 to p12: Material Design 3
- **Expressive Motion**: Integrated Material 3 standard animations (OpenContainer, SharedAxis).
- **Theming**: Full implementation of Material You dynamic colors and "True Black" AMOLED mode.
- **Haptics**: Added tactile feedback to interactions throughout the app.

### v1.2.9-p1 to p4: The Foundation
- **Grid View**: The first major feature—viewing apps in a grid.
- **Category UI**: Enhanced category headers with icon previews and drag-and-drop reordering.

---

## 🧬 Fork Origin
**Base Version**: Obtainium v1.2.9  
**Fork Goal**: To provide a more customizable, performant, and feature-rich experience while maintaining full compatibility with the core mission of open-source app tracking.
