# Obtainium+ Codebase Exploration

This document contains detailed information about the Obtainium codebase structure, specifically focused on categories and settings management.

---

## IMPORTANT: Building the APK

**ALWAYS build through GitHub Actions - no local Android SDK available!**

The repository has a GitHub Actions workflow at `.github/workflows/release.yml` that builds APKs:
- Trigger: Manual workflow dispatch (Actions tab in GitHub)
- Builds both normal and F-Droid flavors
- Outputs: Universal APK and split APKs (per-ABI)
- Artifacts are uploaded and saved as draft releases

To build:
1. Go to GitHub Actions tab
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. Choose whether it's a beta release
5. Download artifacts from the workflow run

---

## 1. Main Screen with Categories

**File:** `lib/pages/apps.dart`

### Category Display Functions

#### `getCategoryCollapsibleTile()` - Lines 711-735
Creates expandable category tiles for the main app list screen.

- Uses Flutter's `ExpansionTile` widget
- **Currently:** `initiallyExpanded: true` (all categories open by default)
- Shows category name with app count as trailing text
- Display controlled by `settingsProvider.groupByCategory` toggle (line 1290)

#### `getListedCategories()` - Lines 373-391
Dynamically generates list of categories from currently displayed apps.

- Extracts categories from `app.app.categories` property
- Handles apps with no categories (null category)
- Categories are sorted alphabetically

#### `getDisplayedList()` - Lines 1290-1309
Determines how apps are displayed.

- If `groupByCategory` is true: shows categories with collapsible tiles
- Otherwise: shows flat list of individual apps

### Category Filtering - Lines 247-252
```dart
if (filter.categoryFilter.isNotEmpty &&
    filter.categoryFilter
        .intersection(app.app.categories.toSet())
        .isEmpty) {
  return false;
}
```

### Visual Category Indicators - Lines 614-639
- LinearGradient with stops for each category color
- Left-aligned gradient bar (width 3% of tile)
- Colors from `settingsProvider.categories[categoryName]`

### Bulk Categorization - Lines 879-943
- `launchCategorizeDialog()` function
- Shows CategoryEditorSelector in modal when apps are selected
- Allows bulk assignment of categories to multiple apps

---

## 2. Settings & Preferences Storage

**File:** `lib/providers/settings_provider.dart`

### Category-Related Settings

#### `groupByCategory` Property - Lines 226-233
- **Type:** Boolean
- **Purpose:** Toggle for grouping apps by category on main screen
- **Storage Key:** `'groupByCategory'`
- **Default Value:** `false`
- **Stored in:** SharedPreferences

#### Category Color Mapping - Lines 272-293

**Getter: `get categories`** (Lines 272-273)
```dart
Map<String, int> get categories => Map<String, int>.from(
    jsonDecode(prefs?.getString('categories') ?? '{}'));
```
- Returns `Map<String, int>`
- Key: category name (String)
- Value: RGB color code (int)
- Storage key: `'categories'`

**Setter: `setCategories()`** (Lines 275-293)
```dart
setCategories(Map<String, int> cats, {SourceProvider? sourceProvider})
```
- Updates category colors
- Removes categories from apps that no longer exist
- Calls `notifyListeners()` for reactive updates
- Saves to SharedPreferences as JSON string

### Storage Architecture
- Uses `SharedPreferences` for all preference persistence
- Categories stored as JSON string: `prefs?.setString('categories', jsonEncode(cats))`
- All settings use `notifyListeners()` for reactive updates (Provider pattern)
- Settings loaded in constructor via `loadDefaults()`

---

## 3. Category UI Components

### CategoryEditorSelector Widget

**File:** `lib/pages/settings.dart` - Lines 1103-1173

**Class Definition:**
```dart
class CategoryEditorSelector extends StatefulWidget {
  final Function(Set<String>) onSelected;
  final bool singleSelect;
  final Set<String> preselected;
  final WrapAlignment alignment;
  final bool showLabelWhenNotEmpty;
}
```

**Purpose:**
- Allows users to select/edit categories
- Used in both settings and bulk app categorization
- Displays categories as interactive chips

### GeneratedFormTagInput Component

**File:** `lib/components/generated_form.dart`

**Category Chip Display** - Lines 523-575
```dart
ChoiceChip(
  label: Text(cat),
  backgroundColor: Color(settingsProvider.categories[cat] ?? 0xFFFFFFFF)
      .withAlpha(127),  // 50% transparency
  selected: controller.text.split(',').contains(cat),
  selectedColor: Color(settingsProvider.categories[cat] ?? 0xFFFFFFFF),
  onSelected: (value) { /* ... */ }
)
```

**Interactive Features:**

1. **Color Picker** - Lines 584-614
   - Icon button to change selected category color
   - Uses `generateRandomLightColor()` (lines 241-254)
   - Generates random light colors using HSLuv color space
   - Ensures unique colors by regenerating if same as before

2. **Add Button** - Lines 672-689
   - Plus icon to add new categories
   - Opens dialog for category name input
   - Auto-generates random color for new category

3. **Delete Button** - Lines 621-665
   - Remove icon for selected categories
   - Shows confirmation dialog before deletion
   - Removes all selected categories

4. **Single/Multi-select Mode** - Lines 544-571
   - When `singleSelect=true`, deselects other categories on selection

**Color Generation** - Lines 241-254
```dart
Color generateRandomLightColor() {
  final hue = Random().nextDouble() * 360;
  final saturation = 40 + Random().nextDouble() * 20; // 40-60%
  final lightness = 70 + Random().nextDouble() * 10;  // 70-80%
  return HSLColor.fromAHSL(1, hue, saturation / 100, lightness / 100).toColor();
}
```

---

## 4. Category Data Models

**File:** `lib/providers/source_provider.dart`

### App Class - Lines 312-459

**Key Category Properties:**
```dart
class App {
  late String id;
  late String url;
  late String author;
  late String name;
  String? installedVersion;
  late String latestVersion;
  List<String> categories;  // LINE 325: List of category names
  late DateTime? releaseDate;
  late String? changeLog;
  bool pinned = false;
  // ... other properties
}
```

**Default Value** - Line 342:
```dart
categories = const []
```

### Serialization

**fromJson** - Lines 393-438:
```dart
categories: json['categories'] != null
    ? (json['categories'] as List<dynamic>)
          .map((e) => e.toString())
          .toList()
    : json['category'] != null  // Backwards compatibility
    ? [json['category'] as String]
    : [],
```

**toJson** - Lines 440-458:
```dart
'categories': categories,  // Line 453
```

### AppInMemory Wrapper - Lines 46-58
```dart
class AppInMemory {
  late App app;
  double? downloadProgress;
  PackageInfo? installedInfo;
  Uint8List? icon;
}
```
- In-memory representation of App with runtime data
- Includes progress, icons, installed info

---

## 5. Implementation Plan for New Features

### Feature 1: Categories Collapsed by Default

**Changes Required:**

1. **Add new setting in `settings_provider.dart`:**
   - Property: `categoriesCollapsedByDefault`
   - Type: Boolean
   - Default: `false` (maintain current behavior)
   - Storage key: `'categoriesCollapsedByDefault'`

2. **Update `apps.dart`:**
   - Modify `getCategoryCollapsibleTile()` at line ~720
   - Change: `initiallyExpanded: true`
   - To: `initiallyExpanded: !settingsProvider.categoriesCollapsedByDefault`

3. **Add UI toggle in `settings.dart`:**
   - Add switch in Settings UI
   - Label: "Collapse categories by default"
   - Calls `settingsProvider.setCategoriesCollapsedByDefault(value)`

**Files to Modify:**
- `lib/providers/settings_provider.dart` (add setting)
- `lib/pages/apps.dart` (update ExpansionTile)
- `lib/pages/settings.dart` (add UI toggle)

### Feature 2: Drag-to-Reorder Categories

**Implementation Approach:**

1. **Add category ordering storage:**
   - New property in `settings_provider.dart`: `categoryOrder`
   - Type: `List<String>` (ordered list of category names)
   - Storage key: `'categoryOrder'`
   - Default: Empty list (use alphabetical ordering)

2. **Update category sorting logic:**
   - Modify `getListedCategories()` in `apps.dart` (lines 373-391)
   - Use custom order if `categoryOrder` is set
   - Fall back to alphabetical if category not in order list

3. **Implement drag-and-drop UI:**
   - Use Flutter's `ReorderableListView` or `ReorderableWrap`
   - Replace `ExpansionTile` with draggable variant
   - Add long-press gesture detector
   - Update `categoryOrder` in settings on reorder

4. **Visual feedback:**
   - Show drag handle icon when long-pressing
   - Highlight drop zones
   - Animate reordering

**Files to Modify:**
- `lib/providers/settings_provider.dart` (add ordering storage)
- `lib/pages/apps.dart` (implement drag-and-drop UI)

**Flutter Packages Needed:**
- May use `reorderables` package or built-in `ReorderableListView`
- Check `pubspec.yaml` for existing dependencies

---

## 6. Key Files Summary

| File | Purpose | Key Lines |
|------|---------|-----------|
| `lib/pages/apps.dart` | Main app list screen | 711-735 (category tiles), 373-391 (category list), 1290-1309 (display mode) |
| `lib/pages/settings.dart` | Settings UI, CategoryEditorSelector | 931-940 (category editor), 1103-1173 (CategoryEditorSelector) |
| `lib/providers/settings_provider.dart` | Settings storage & management | 226-233 (groupByCategory), 272-293 (category colors) |
| `lib/providers/source_provider.dart` | App model with categories | 312-459 (App class), 325 (categories property) |
| `lib/components/generated_form.dart` | Tag/chip UI components | 137-177 (GeneratedFormTagInput), 523-575 (chips), 241-254 (color generation) |

---

## 7. Category Workflow

```
User edits categories in Settings
    ↓
CategoryEditorSelector (UI Component)
    ↓
GeneratedFormTagInput with ChoiceChip widgets
    ↓
settingsProvider.setCategories() called
    ↓
Updates SharedPreferences with Map<String, int>
    ↓
notifyListeners() triggers UI updates
    ↓
Apps showing/hiding/grouping by category changes
```

---

## 8. Additional Notes

### Current Limitations
- Categories are always expanded by default (`initiallyExpanded: true`)
- Categories are sorted alphabetically only
- No custom ordering capability
- No drag-and-drop functionality

### Proposed Enhancements
1. **Collapse by Default Setting** - Simple boolean toggle
2. **Drag-to-Reorder** - More complex, requires new UI patterns
3. **Additional Sorting Methods** - Will need new sorting button in bottom nav

### Testing Considerations
- Test with many categories (10+)
- Test with apps having multiple categories
- Test with apps having no categories
- Test category color persistence
- Test drag-and-drop on different screen sizes
- Test state persistence across app restarts

---

**Last Updated:** 2025-12-16
**Explored By:** Claude Code Assistant
**For Project:** Obtainium+ Fork
