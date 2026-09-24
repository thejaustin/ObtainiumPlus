# Technical Architecture - Updated (September 2026)

## Settings & Provider Architecture
The project employs a granular, decoupled sub-provider architecture to maximize UI responsiveness and minimize unnecessary widget tree rebuilds.

### Provider & Service Breakdown
- **`BehaviorSettingsProvider`**: Handles application behavioral toggles (Shizuku, swipe gestures, download parallelization, undo removal).
- **`PlusSettingsProvider`**: Manages all Obtainium+ features (OneUI header, floating dock, action capsule, tile styling, glassmorphism).
- **`ThemeSettingsProvider`**: Manages Material 3 Expressive theming, wallpaper dynamic color variants, and curated palette presets.
- **`UpdateSettingsProvider`**: Handles automated background update schedules, network constraints, and source channel preferences.
- **`ViewSettingsProvider`**: Controls UI layout modes (List/Grid), column counts, category grouping, and density.
- **`TagProvider`**: Manages app tagging, tag persistence, and tag filtering.
- **`DeviceCompatibilityService`**: Detects OEM skins (OneUI, MIUI/HyperOS, OxygenOS, ColorOS, EMUI, Nothing OS, Transsion) and surfaces tailored optimization advice.
- **`SourceConfigProvider`**: Manages dynamic per-source API configurations and rate limits.

Consumer widgets use direct, granular watchers (e.g., `context.watch<PlusSettingsProvider>()` or `context.select(...)`) rather than proxying through the root settings provider.

## OneUI Reachability Architecture
Implemented via `CustomAppBar` and extensible flexible space widgets:
- Integrates pull-down scroll delta tracking to expand the top header area up to 35% of the viewport height.
- Smoothly interpolates title size, opacity, and vertical translation to bring interactive list items into natural thumb reach.
- Displays contextual live counts (total tracked apps and pending updates) beneath the primary headline.

## Material 3 Expressive Theming
Built on Flutter's Material 3 design system with extended dynamic capabilities:
- **DynamicSchemeVariants**: Full support for wallpaper color extraction with multiple algorithmic schemes (Tonal Spot, Neutral, Vibrant, Expressive, Fidelity, Content, Monochrome).
- **Palette Presets**: Curated high-contrast and ambient palettes with AMOLED true black optimization.
- **Glassmorphism**: Backdrop blur filtering and specular alpha borders applied across cards, bottom sheets, and dialogs.

## Floating Navigation Dock & Action Capsule
- **Floating Navigation Dock**: Detaches the bottom navigation bar into a rounded floating island with ambient elevation and background blur, avoiding content occlusion with dynamic bottom padding.
- **Floating Action Capsule**: Decouples primary call-to-actions on the App Detail screen into a floating frosted pill with adaptive contrast and tonal styling.

## App Tile Visual Architecture
List and Grid tiles share a unified visual enhancement pipeline:
- **Pinned Border Accent**: Evaluates pin state and renders an elevated primary border highlight (1.5px) for clear spatial hierarchy.
- **Category Accent Ribbon**: Leading-edge category color indicator strip.
- **Expressive Version Pill**: Compact tonal pill with contextual icon and version string.
- **Icon Rim Border**: High-precision border overlay defining app icon boundaries against variable backgrounds.

## Shizuku Turbo & Silent Installation
- Interacts with Shizuku via direct IPC binders for elevated package management without root.
- **Shizuku Turbo**: Employs high-throughput buffered stream I/O and adaptive short-polling of package installer sessions to drastically accelerate batch updates.

## Backup Encryption & Deterministic Sorting
- **Backup Encryption**: AES-256 CBC encryption via `encrypt` and `crypto` libraries with PBKDF2 key derivation for secure exports and imports.
- **App Pinning**: Pinned app ordering persisted as `List<String>` in `PlusSettingsProvider.plusPinnedAppsOrder`, sorted by `AppFilterService` using deterministic index lookup.
