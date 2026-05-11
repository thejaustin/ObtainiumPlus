# Technical Architecture - Updated (May 2026)

## Settings Architecture
The project has transitioned from a monolithic `SettingsProvider` to a granular, decoupled sub-provider architecture. 

### Provider Breakdown
- **`BehaviorSettingsProvider`**: Handles application behavioral toggles (Shizuku, swipe gestures, download parallelization).
- **`PlusSettingsProvider`**: Manages all "Obtainium+" gated features (UI enhancements, advanced settings).
- **`ThemeSettingsProvider`**: Manages theming, colors, and font settings.
- **`UpdateSettingsProvider`**: Handles automated update schedules and source channel preferences.
- **`ViewSettingsProvider`**: Controls UI layout, column counts, and density settings.
- **`SourceConfigProvider`**: Manages dynamic per-source configurations.

All consumer widgets now use direct watchers (e.g., `context.watch<PlusSettingsProvider>()`) instead of proxying through the root provider.

## Backup Encryption
Implemented using AES-256 CBC via the `encrypt` and `crypto` libraries. The `AppExportService` now supports password-based decryption for secure backup imports and encrypted file exports.

## App Pinning
Pinned app ordering is now persisted as a `List<String>` in `PlusSettingsProvider.plusPinnedAppsOrder`. Sorting is handled by the `AppFilterService` using index lookup for deterministic ordering.
