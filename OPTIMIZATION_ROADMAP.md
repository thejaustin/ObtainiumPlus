# Obtainium+ Optimization Roadmap

This document outlines the strategy for ongoing performance and code quality improvements.

## Completed Optimizations

### ✅ DeviceInfoPlugin Caching (v1.2.9-p16)
- **File**: `lib/pages/settings.dart`
- **Change**: Cache AndroidDeviceInfo in State to avoid 4+ redundant async calls
- **Impact**: Reduced async overhead, faster settings page rendering
- **Implementation**: Added `_cachedAndroidInfo` and `_androidInfoFuture` fields

### ✅ Centralized Constants (v1.2.9-p14)
- **File**: `lib/utils/app_constants.dart`
- **Change**: Eliminated magic numbers throughout codebase
- **Impact**: Improved maintainability, self-documenting code

### ✅ Theme Configuration Refactoring (v1.2.9-p13)
- **File**: `lib/utils/theme_builder.dart`
- **Change**: Eliminated 150+ lines of duplicated theme code
- **Impact**: Single source of truth, easier maintenance

---

## Pending High-Priority Optimizations

### 1. Widget Rebuild Optimization (HIGH)

**Problem**: `context.watch<SettingsProvider>()` in `settings.dart:94` causes full page rebuild on ANY settings change.

**Current State**:
```dart
SettingsProvider settingsProvider = context.watch<SettingsProvider>();
// Entire build() method rebuilds when ANY setting changes
```

**Recommended Solution**: Use `Consumer` widgets for specific sections

**Strategy**:
```dart
// Instead of watching entire provider
Consumer<SettingsProvider>(
  builder: (context, settings, child) {
    // Only this section rebuilds
    return ThemeDropdown(settings);
  },
)

// Or use context.select for granular rebuilds
final theme = context.select<SettingsProvider, ThemeSettings>(
  (settings) => settings.theme
);
```

**Files to Refactor**:
- `lib/pages/settings.dart` (primary target)
- Extract subsections into separate widget files:
  - `lib/components/settings/theme_settings_section.dart`
  - `lib/components/settings/update_settings_section.dart`
  - `lib/components/settings/behavior_settings_section.dart`

**Estimated Impact**: 50-70% reduction in widget rebuilds

---

### 2. SettingsProvider Split (HIGH)

**Problem**: God class anti-pattern - 737 lines, 50+ getters/setters

**Current Structure**:
```dart
class SettingsProvider {
  // Theme settings
  ThemeSettings get theme;
  Color get themeColor;
  DynamicSchemeVariant get themeVariant;
  bool get useMaterialYou;
  bool get matchSystemMaterialStyle;
  bool get useBlackTheme;
  bool get useSystemFont;

  // Update settings
  int get updateInterval;
  bool get checkOnStart;
  bool get useForegroundService;

  // View settings
  SortColumn get sortColumn;
  SortOrder get sortOrder;
  ViewMode get globalViewMode;
  GridCategoryMode get gridCategoryMode;
  int get gridColumnCount;

  // ... 40+ more settings
}
```

**Recommended Solution**: Split into domain-specific providers

**Strategy**:
```dart
// lib/providers/theme_settings_provider.dart
class ThemeSettingsProvider extends ChangeNotifier {
  ThemeSettings get theme;
  Color get themeColor;
  DynamicSchemeVariant get themeVariant;
  bool get useMaterialYou;
  bool get matchSystemMaterialStyle;
  bool get useBlackTheme;
  bool get useSystemFont;
  // ~150 lines
}

// lib/providers/update_settings_provider.dart
class UpdateSettingsProvider extends ChangeNotifier {
  int get updateInterval;
  bool get checkOnStart;
  bool get useForegroundService;
  // ~100 lines
}

// lib/providers/view_settings_provider.dart
class ViewSettingsProvider extends ChangeNotifier {
  SortColumn get sortColumn;
  SortOrder get sortOrder;
  ViewMode get globalViewMode;
  GridCategoryMode get gridCategoryMode;
  int get gridColumnCount;
  CategoryIconPosition get categoryIconPosition;
  // ~150 lines
}

// lib/providers/behavior_settings_provider.dart
class BehaviorSettingsProvider extends ChangeNotifier {
  bool get disablePageTransitions;
  bool get reversePageTransitions;
  bool get highlightTouchTargets;
  bool get hideAppScreenshots;
  bool get pinUpdatesToTop;
  // ~100 lines
}
```

**Migration Strategy**:
1. Create new provider files
2. Move getters/setters to appropriate provider
3. Update SharedPreferences keys to be domain-scoped
4. Update widgets to use specific providers
5. Add MultiProvider in main.dart
6. Deprecate old SettingsProvider gradually

**Files to Create**:
- `lib/providers/theme_settings_provider.dart`
- `lib/providers/update_settings_provider.dart`
- `lib/providers/view_settings_provider.dart`
- `lib/providers/behavior_settings_provider.dart`

**Estimated Effort**: 2-3 days

**Benefits**:
- Easier to test (smaller units)
- Better separation of concerns
- More granular widget rebuilds
- Clearer code organization

---

### 3. Large File Refactoring (MEDIUM)

**Problem**: Several files exceed recommended 500-line limit

**Files to Refactor**:

#### apps_provider.dart (2400+ lines)
**Sections to Extract**:
- App CRUD operations → `app_crud_service.dart`
- Update checking logic → `app_update_service.dart`
- Installation handling → `app_install_service.dart`
- App filtering/sorting → `app_filter_service.dart`

#### settings.dart (1418 lines)
**Already in progress** - extract subsections into widgets

#### apps.dart (2000+ lines)
**Sections to Extract**:
- Grid view → `lib/components/apps/app_grid_view.dart`
- List view → `lib/components/apps/app_list_view.dart`
- Category sections → `lib/components/apps/category_sections.dart`

**Strategy**: Extract logical sections into separate files, maintain public API

---

### 4. Animation Controller Optimization (LOW)

**Problem**: Every grid tile creates its own AnimationController

**Current State**:
```dart
// app_grid_tile.dart:26-41
class _AppGridTileState extends State<AppGridTile> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: AppConstants.mediumAnimationMs),
      vsync: this,
    )..repeat(reverse: true);
    // Each tile creates a controller
  }
}
```

**Recommended Solution**: Consider using `AnimatedContainer` for simple cases

**Alternative**: Share animation controllers across tiles (more complex)

**Estimated Impact**: 10-20% reduction in animation overhead on large lists

---

### 5. Image Memory Management (MEDIUM)

**Problem**: `Image.memory()` with `gaplessPlayback: true` may consume excessive memory on large app lists

**Current State**:
```dart
Image.memory(
  widget.appInMemory.icon!,
  fit: BoxFit.cover,
  gaplessPlayback: true,
)
```

**Recommended Solution**: Implement image caching with size limits

**Strategy**:
```dart
// Use cached_network_image pattern or custom cache
class IconCache {
  static final Map<String, Uint8List> _cache = {};
  static const int maxCacheSize = 100;

  static Uint8List? get(String appId);
  static void put(String appId, Uint8List data);
  static void evict();
}
```

**Files to Modify**:
- `lib/components/app_grid_tile.dart`
- `lib/components/app_list_tile.dart` (if exists)

---

## Performance Metrics to Track

Once optimizations are implemented, track these metrics:

1. **Settings Page**:
   - Widget rebuild count (use DevTools)
   - Time to first paint
   - Interaction latency

2. **Apps List**:
   - Frame rate (should maintain 60fps)
   - Memory usage
   - Scroll performance

3. **Startup**:
   - Time to interactive
   - Initial provider initialization time

---

## Testing Strategy

For each optimization:

1. **Before**: Measure baseline performance
2. **Implement**: Make changes
3. **After**: Measure improved performance
4. **Compare**: Document improvement percentage
5. **Test**: Ensure no regressions

**Tools**:
- Flutter DevTools (Performance tab)
- Widget Inspector (rebuild tracking)
- Memory profiler
- `flutter analyze` for code quality

---

## Priority Ordering

Based on effort vs impact:

1. **HIGH PRIORITY - LOW EFFORT**:
   - ✅ DeviceInfoPlugin caching (DONE)
   - Consumer widget wrapping in settings

2. **HIGH PRIORITY - MEDIUM EFFORT**:
   - Extract settings subsections
   - SettingsProvider split

3. **MEDIUM PRIORITY - MEDIUM EFFORT**:
   - Large file refactoring
   - Image memory management

4. **LOW PRIORITY**:
   - Animation controller optimization
   - Further micro-optimizations

---

## Next Steps

1. Implement Consumer widgets in settings.dart
2. Create theme_settings_section.dart as proof of concept
3. Measure rebuild improvement
4. Plan SettingsProvider split
5. Create unit tests for new providers
6. Document migration strategy

---

Last Updated: 2026-01-02
Version: 1.2.9-p16
