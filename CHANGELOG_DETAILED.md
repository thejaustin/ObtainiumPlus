### xxxxxxx - feat: combine add app tabs into single view
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Refactored `AddAppPage` to combine URL input, Discover, and Import/Export functionalities into a single, scrollable view, replacing the tab-based interface for a more streamlined user experience.

### xxxxxxx - fix: settings page initialization
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Resolved `obtainiumThemeColor` undefined error by moving its definition to `AppConstants.dart`, ensuring proper initialization of `ModernSettingsPage`.

### xxxxxxx - fix: settings page crash and feat: add sub-menu transitions
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Fixed app freezing/crashing when toggling settings by simplifying _SubMenuPage and removing redundant TickerProviderStateMixin. Implemented SharedAxisTransition for smooth navigation to sub-menu settings pages.

### xxxxxxx - refactor: partially split SettingsProvider (Theme)
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Extracted theme-related settings into a new `ThemeSettingsProvider`. Centralized enums into `lib/models/settings_enums.dart`. Reduced `SettingsProvider` from ~1200 to ~690 lines.

### xxxxxxx - feat: implement offline mode with operation queue
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Added `OfflineService` to detect network status and queue manual update checks when offline. The queue is automatically processed when connection is restored.

### xxxxxxx - feat: add statistics dashboard
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Added a new Statistics page in Settings > Troubleshooting. Shows app tracking metrics, recent installation history, and allows exporting data as JSON.

### xxxxxxx - refactor: further modularize apps page
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Extracted `AppsFilter` model and changelog logic from `apps.dart` into specialized files to improve maintainability and reduce file size.

### xxxxxxx - perf: optimize grid tile animations
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Refactored `AppGridTile` to remove unnecessary `AnimationController` instantiation. Created `UpdateBadge` widget to isolate animation logic, ensuring tickers are only created when an update is actually available.

### xxxxxxx - perf: implement memory management for app icons
- **Date**: 2026-01-31
- **Author**: Gemini CLI
- **Details**: Added eviction handler to IconLRUCache and AppsProvider to ensure icons are cleared from memory when evicted from cache.

### 71f749e - feat: add toggle for including forks in GitHub search
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### cf022ca - feat: include forks in GitHub discover search
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### 17f1a8b - Auto-bump version to 1.2.9-p50
- **Date**: 2026-01-29
- **Author**: github-actions[bot]

### 317b5f9 - fix: add missing closing parentheses
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### d8076d4 - fix: use correct property access in StatelessWidget
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### 6e4aaf4 - fix: remove unused isar dependencies
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### af1b82f - fix: downgrade flutter_cache_manager to ^3.4.1
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### 95b9e39 - feat: Add new libraries for enhanced functionality
- **Date**: 2026-01-29
- **Author**: Qwen AI Assistant

### ffb1338 - feat: enhance UI performance, onboarding, and adaptive layouts
- **Date**: 2026-01-29
- **Author**: thejaustin

### ee5ab70 - Auto-bump version to 1.2.9-p49
- **Date**: 2026-01-29
- **Author**: github-actions[bot]

### 4233089 - fix: use CardThemeData and DialogThemeData for Flutter 3.38 compatibility
- **Date**: 2026-01-28
- **Author**: thejaustin

### 00bb3f4 - feat: M3 design enhancements with app bar style toggle
- **Date**: 2026-01-28
- **Author**: thejaustin

### 0b27d55 - Auto-bump version to 1.2.9-p48
- **Date**: 2026-01-25
- **Author**: github-actions[bot]

### 9227dc9 - fix: null safety for TabController in add_app.dart
- **Date**: 2026-01-25
- **Author**: thejaustin

### 5d5a611 - feat: implement Plus Features toggle system (#29)
- **Date**: 2026-01-25
- **Author**: thejaustin

### c3634f3 - Auto-bump version to 1.2.9-p47
- **Date**: 2026-01-25
- **Author**: github-actions[bot]

### f8d13b1 - feat: add scheduled update windows (#27)
- **Date**: 2026-01-25
- **Author**: thejaustin

### 27d802c - feat: change package name to app.obtainiumplus (#36)
- **Date**: 2026-01-25
- **Author**: thejaustin

### 2d474a8 - feat(ui): enhance empty state with Discover tab link (#34)
- **Date**: 2026-01-25
- **Author**: thejaustin

### f07cc9f - fix(ui): prevent overlapping elements on app detail page (#35)
- **Date**: 2026-01-25
- **Author**: thejaustin

### 89dae0d - Auto-bump version to 1.2.9-p46
- **Date**: 2026-01-25
- **Author**: github-actions[bot]

### f632449 - fix: improve GitHub URL error handling and prevent WebViewController memory leak
- **Date**: 2026-01-25
- **Author**: thejaustin

### 7e490b8 - Auto-bump version to 1.2.9-p45
- **Date**: 2026-01-23
- **Author**: github-actions[bot]

### 08e2477 - chore: remove unused code in apps page
- **Date**: 2026-01-23
- **Author**: thejaustin

### 71ef698 - fix: remove invalid context argument from CustomAppBar call
- **Date**: 2026-01-23
- **Author**: thejaustin

### ca32c7c - chore: remove unused imports in settings page
- **Date**: 2026-01-23
- **Author**: thejaustin

### ebb21ac - Trigger build: Update release notes formatting
- **Date**: 2026-01-23
- **Author**: thejaustin

### 8d70ad6 - Fix build configuration: Relax NDK version and Dart SDK constraints
- **Date**: 2026-01-23
- **Author**: thejaustin

### 9371fbb - Fix detached HEAD push issue in GH Actions
- **Date**: 2026-01-23
- **Author**: thejaustin

### 949e039 - Fix GH Actions build failure: Use robust delimiter for changelog output
- **Date**: 2026-01-23
- **Author**: thejaustin

### ebb9986 - Enhance release notes with proper text changelog from git history
- **Date**: 2026-01-23
- **Author**: thejaustin

### 2a618ea - Refactor Settings page to use submenus and improve M3 styling; fix dark mode text contrast
- **Date**: 2026-01-23
- **Author**: thejaustin

### cef0e78 - Auto-bump version to 1.2.9-p44
- **Date**: 2026-01-23
- **Author**: github-actions[bot]

### dcda2e2 - fix: resolve missing imports and type errors
- **Date**: 2026-01-22
- **Author**: thejaustin

### ae93b54 - Fix remaining build errors: missing methods in AppSource and SourceUtils
- **Date**: 2026-01-22
- **Author**: thejaustin

### 9d8ebee - Fix build errors: missing App type and regex validator
- **Date**: 2026-01-22
- **Author**: thejaustin

### 3d64dcd - Refactor Settings page to Material 3 Chrome style
- **Date**: 2026-01-22
- **Author**: thejaustin

### 1fbebb9 - fix: restore App class and utility functions removed during refactoring
- **Date**: 2026-01-21
- **Author**: thejaustin

### 78bf021 - refactor: modularize source_provider and extract AppSource models ui: implement EmptyStateWidget for Apps tab and fix detail page overlaps docs: sync roadmap with GitHub issues #31, #32, #33, #34, #35
- **Date**: 2026-01-21
- **Author**: thejaustin

### a29e65f - Auto-bump version to 1.2.9-p43
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### e9dee4e - fix(github): improve API URL conversion and always use official API host style(ui): enhance AMOLED theme contrast and text visibility
- **Date**: 2026-01-21
- **Author**: thejaustin

### 96f0496 - Auto-bump version to 1.2.9-p42
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### 1ce031e - fix: update all references from Obtainium to Obtainium+
- **Date**: 2026-01-20
- **Author**: thejaustin

### 10c4c7e - Auto-bump version to 1.2.9-p41
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### 6641bc2 - fix: build errors and improve Xiaomi battery optimization UX
- **Date**: 2026-01-20
- **Author**: thejaustin

### dc409fe - fix: resolve build errors from missing imports and incorrect method calls
- **Date**: 2026-01-20
- **Author**: thejaustin

### 9c47837 - fix: correct malformed Scaffold structure in apps.dart
- **Date**: 2026-01-20
- **Author**: thejaustin

### fac8e1f - feat: Add source selection UI to discover search
- **Date**: 2026-01-20
- **Author**: thejaustin

### 3df5863 - Enhance: Advanced troubleshooting and system setting shortcuts (including Xiaomi fixes)
- **Date**: 2026-01-20
- **Author**: thejaustin

### 9d26c34 - Refactor: Comprehensive UI/UX modernization and modularity enhancements
- **Date**: 2026-01-20
- **Author**: thejaustin

### e321ba0 - Auto-bump version to 1.2.9-p40
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### 3d8424b - fix: remove invalid RepaintBoundary wrapper from slivers list
- **Date**: 2026-01-20
- **Author**: thejaustin

### ee722ea - Auto-bump version to 1.2.9-p39
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### 9d47908 - fix: repair corrupt JSON in en.json translation file
- **Date**: 2026-01-20
- **Author**: thejaustin

### fedd55f - Auto-bump version to 1.2.9-p38
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### 7babd4b - fix: improve error handling in loadApps to prevent white screen crashes
- **Date**: 2026-01-20
- **Author**: thejaustin

### 33a7c22 - Auto-bump version to 1.2.9-p37
- **Date**: 2026-01-21
- **Author**: github-actions[bot]

### ac2b9bf - fix: handle non-String inputs in safeJsonDecode to prevent FormatException
- **Date**: 2026-01-20
- **Author**: thejaustin

### 02af049 - Auto-bump version to 1.2.9-p36
- **Date**: 2026-01-20
- **Author**: github-actions[bot]

### 93f6d2c - fix: add defensive JSON parsing to prevent corrupt data crashes
- **Date**: 2026-01-19
- **Author**: thejaustin

### 7d74b1b - Auto-bump version to 1.2.9-p35
- **Date**: 2026-01-20
- **Author**: github-actions[bot]

### f7392d7 - fix: add error handling for JSON parsing in settings getters
- **Date**: 2026-01-19
- **Author**: thejaustin

### 9be1d8d - Auto-bump version to 1.2.9-p34
- **Date**: 2026-01-20
- **Author**: github-actions[bot]

### b2c7f9c - fix: resolve remaining build errors
- **Date**: 2026-01-19
- **Author**: thejaustin

### 07645e3 - fix: resolve build errors in settings and toggle components
- **Date**: 2026-01-19
- **Author**: thejaustin

### 31ca2d3 - fix: move misplaced imports to top of apps_provider.dart
- **Date**: 2026-01-19
- **Author**: thejaustin

### 34d5769 - feat: add quick toggles dashboard and enhance settings UI
- **Date**: 2026-01-19
- **Author**: thejaustin

### e8ccd94 - Auto-bump version to 1.2.9-p33
- **Date**: 2026-01-19
- **Author**: github-actions[bot]

### 25caf91 - fix: add missing imports for settings sections in settings page
- **Date**: 2026-01-18
- **Author**: thejaustin

### 183cb91 - fix: resolve build errors in settings and custom_errors, add AddAppMode
- **Date**: 2026-01-18
- **Author**: thejaustin

### e23da4a - Enhance UI with M3 expressive features, tooltips, and self-repair
- **Date**: 2026-01-18
- **Author**: thejaustin

### 6df0b1e - Auto-bump version to 1.2.9-p32
- **Date**: 2026-01-18
- **Author**: github-actions[bot]

### 114862f - fix: resolve build errors from missing imports and syntax issues
- **Date**: 2026-01-18
- **Author**: thejaustin

### aac9799 - fix: move version bump after build and remove F-Droid flavor
- **Date**: 2026-01-18
- **Author**: thejaustin

### 41485f0 - Auto-bump version to 1.2.9-p31
- **Date**: 2026-01-18
- **Author**: github-actions[bot]

### 9c4aab7 - feat: implement persistent retry queue (#20) and refactor apps provider (#16)
- **Date**: 2026-01-17
- **Author**: thejaustin

### c869e52 - Auto-bump version to 1.2.9-p30
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### 192811f - feat: implement quick filters, memoized sorting, and update caching
- **Date**: 2026-01-16
- **Author**: thejaustin

### d6da3b8 - Auto-bump version to 1.2.9-p29
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### bce29d6 - feat: merge discover into add app and safe restore battery opt
- **Date**: 2026-01-16
- **Author**: thejaustin

### fbd5b3d - Auto-bump version to 1.2.9-p28
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### 018c239 - fix: prevent battery optimization screen from opening on startup
- **Date**: 2026-01-16
- **Author**: thejaustin

### 5134ee0 - Auto-bump version to 1.2.9-p27
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### f292b1d - feat: improve discover page UI with grid layout
- **Date**: 2026-01-16
- **Author**: thejaustin

### 59ef9f4 - feat: restore view mode toggle button
- **Date**: 2026-01-16
- **Author**: thejaustin

### 4ce23cb - feat: move import/export to modal and restore sort button
- **Date**: 2026-01-16
- **Author**: thejaustin

### c85c297 - Auto-bump version to 1.2.9-p26
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### d227186 - Fix null check errors and add LRU icon cache
- **Date**: 2026-01-16
- **Author**: thejaustin

### 93edc34 - Auto-bump version to 1.2.9-p25
- **Date**: 2026-01-17
- **Author**: github-actions[bot]

### 4aa14a2 - Add auto-version bump to build workflow
- **Date**: 2026-01-16
- **Author**: thejaustin

### edfc213 - Bump version to 1.2.9-p24 for new release
- **Date**: 2026-01-16
- **Author**: thejaustin

### 60b487d - Fix critical bugs: forEach continue, null safety, and async synchronization
- **Date**: 2026-01-16
- **Author**: thejaustin

### ea4b063 - Add error display for white screen debugging
- **Date**: 2026-01-16
- **Author**: thejaustin

### 13c9150 - Fix duplicate lowerCaseIfEnglish definition
- **Date**: 2026-01-15
- **Author**: thejaustin

### 1fb9715 - Fix syntax errors in source_provider.dart and update README
- **Date**: 2026-01-15
- **Author**: thejaustin

### 89ca595 - Fix multiple build errors: ID conflicts, missing imports, and syntax errors
- **Date**: 2026-01-14
- **Author**: thejaustin

### d1eba0c - Fix syntax error and missing imports in services/providers
- **Date**: 2026-01-14
- **Author**: thejaustin

### b324ac2 - Fix missing imports in extracted services
- **Date**: 2026-01-14
- **Author**: thejaustin

### f01b363 - Bump version to 1.2.9-p22
- **Date**: 2026-01-14
- **Author**: thejaustin
