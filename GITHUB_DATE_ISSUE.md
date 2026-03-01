# GitHub Release Date Issue Investigation

## Problem
Obtainium+ listing not showing proper date for latest update. Need to verify if this affects other GitHub apps.

## Root Cause Analysis

### Code Flow:
1. **GitHub API** returns `published_at` field in ISO 8601 format
2. **tryParseDateTime()** parses it in `lib/utils/app_utils.dart:100`
3. **getReleaseDateFromRelease()** extracts date in `lib/app_sources/github.dart:466`
4. **APKDetails** receives releaseDate in `lib/app_sources/github.dart:650`
5. **App model** stores releaseDate in `lib/models/app.dart:20`
6. **UI displays** via `app.releaseDate.toLocal().toString()` in `lib/pages/app.dart:1008`

### Potential Issues:

#### 1. Date Parsing (LOW LIKELIHOOD)
```dart
// lib/utils/app_utils.dart:100
DateTime? tryParseDateTime(String? dateStr) {
  if (dateStr == null) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    return null;
  }
}
```
✅ This looks correct - handles null and catches errors

#### 2. Date Extraction (LOW LIKELIHOOD)
```dart
// lib/app_sources/github.dart:443
DateTime? getPublishDateFromRelease(dynamic rel) =>
    rel?['published_at'] != null
    ? tryParseDateTime(rel['published_at'])
    : rel?['commit']?['created'] != null
    ? tryParseDateTime(rel['commit']['created'])
    : null;
```
✅ This looks correct - checks published_at, falls back to commit date

#### 3. Date Display (MEDIUM LIKELIHOOD)
```dart
// lib/pages/app.dart:1008
app!.app.releaseDate!.toLocal().toString()
```
⚠️ Uses force unwrap (!) - could crash if null
⚠️ No formatting - shows raw DateTime string

#### 4. Date Persistence (MEDIUM LIKELIHOOD)
Check if releaseDate is being saved when app is updated:
- `checkUpdate()` in `lib/services/app_update_service.dart`
- `saveApps()` in `lib/providers/apps_provider.dart`

## Testing Steps

1. **Check Obtainium+ specifically:**
   - Open app detail page for Obtainium+
   - Check if release date shows
   - Check last update check time

2. **Check other GitHub apps:**
   - Test with other GitHub-hosted apps
   - Compare date display

3. **Check API response:**
   - Verify GitHub API returns `published_at`
   - Check if field name changed

## Likely Causes

### Most Likely:
1. **Release date not being saved** during checkUpdate
2. **Null releaseDate** being passed to UI
3. **Date formatting issue** in display

### Less Likely:
1. GitHub API changed field name
2. tryParseDateTime failing silently
3. Timezone conversion issues

## Recommended Fixes

### Fix 1: Add null safety in UI
```dart
// lib/pages/app.dart
app?.app.releaseDate != null
    ? DateFormat('MMM d, yyyy').format(app!.app.releaseDate!.toLocal())
    : tr('unknown')
```

### Fix 2: Ensure releaseDate is saved
```dart
// lib/services/app_update_service.dart
// Make sure releaseDate is copied when updating app
newApp.releaseDate = apk.releaseDate;
```

### Fix 3: Add debugging
```dart
// Add logging to see what GitHub API returns
LogsProvider().add(
  'GitHub release date: ${rel['published_at']}',
  level: LogLevels.debug,
);
```

## Next Steps

1. Test with multiple GitHub apps
2. Add null checks in UI
3. Verify releaseDate persistence
4. Add better date formatting
5. Consider adding "Last Updated" vs "Release Date" distinction
