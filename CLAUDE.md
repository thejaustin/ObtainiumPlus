# ObtainiumPlus — Claude Code Guidelines

Flutter/Dart app-updater fork (github.com/thejaustin/ObtainiumPlus).
Read `AI_DEVLOG.md` at session start; update it before ending a session.

## Build commands
No local Flutter SDK — CI is the compile/test gate. Use `scripts/dev/`:

| Task | Command |
|------|---------|
| Local syntax check (fast) | `bash scripts/dev/check-syntax.sh` |
| Recent CI runs | `bash scripts/dev/ci-status.sh` (add `--log` for failed-step logs) |
| Trigger + watch APK build | `bash scripts/dev/ci-build.sh` |
| Download latest APK artifact | `bash scripts/dev/fetch-apk.sh` |

Pushing to `main` triggers `build-apk.yml` automatically: analyze → flutter test → APK → auto version bump (`1.4.3-pNN`) committed back to main.
**Always `git fetch origin && git merge origin/main --no-edit` before push** — CI bump commits land constantly.
**Prefer feature branches** (`feat/xxx`) for multi-commit work to avoid the merge-loop: each push to `main` triggers CI + version bump + a new commit you must pull before the next push.

## PostToolUse hook
`.claude/settings.json` runs `check-syntax.sh` automatically after every Edit/Write. This catches Dart parse errors and type mismatches locally before CI. If the hook output shows `SYNTAX ERRORS FOUND`, fix before committing.

## Critical crash rules — do not reintroduce

| Rule | Why |
|------|-----|
| All SharedPreferences reads MUST go through `lib/utils/safe_prefs.dart` (`safeDouble/safeInt/safeBool/safeString/safeStringList/safeEnum`) | `importObtainiumData` restores JSON-typed settings; any key can arrive type-flipped or with a stale enum index → TypeError/RangeError → blank grey page in release (#217) |
| Never call plain `tr()` on plural translation keys (`apps`, `url`, `minute`, `hour`, `day`, `apk`, `certificateHash`, `removeAppQuestion`, … any nested-object key in `assets/translations/en.json`) | easy_localization casts the resolved map `as String?` → TypeError → blank page in release. Root cause of the persistent blank settings page (fixed v1.4.3-p42). Use `plural()` or a literal |
| `TextDirection` in files importing easy_localization must be prefix-qualified (`ui.TextDirection.ltr`) | easy_localization re-exports intl's TextDirection |
| Don't hand-edit `lib/utils/version_constant.dart` | Auto-synced by the CI bump step |
| Version-ordering guard: unknown ordering MUST fall through to "offer the update" | `areVersionsDifferent` is string-based; `compareVersionStrings` (`lib/utils/version_utils.dart`) only suppresses confidently-older offers (v1.4.3-p43). Never suppress updates for unusual versioning schemes. Tests: `test/version_ordering_test.dart` |

## Testing
- `test/settings_page_test.dart` pumps every settings tab in CI — the regression gate for blank-page bugs.
- Test gotchas: translations must come from an in-memory AssetLoader (rootBundle load only completes for the first test in a file); `FlutterError.onError` capture must be installed inside the test body and restored before the post-test check.

## Dart / Flutter type pitfalls — do not reintroduce

| Pattern | Rule |
|---------|------|
| `ShapeBorderTween` with `TweenAnimationBuilder` | `ShapeBorderTween` extends `Tween<ShapeBorder?>` (nullable). Always use `TweenAnimationBuilder<ShapeBorder?>` and resolve: `final s = shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))` before passing to `Material`/`InkWell`/`BoxDecoration` |
| `BackdropFilter` / glassmorphism | Never use raw `BackdropFilter`. Always use `lib/components/common/conditional_blur.dart` → `ConditionalBlur(enabled: plusSettings.plusEnableGlassmorphism, sigma: N, child: ...)`. Remove `dart:ui` import after migration unless `ui.TextDirection` is needed |
| Animation durations | Every duration must check the setting: `Duration(milliseconds: animsEnabled ? N : 0)`. Never hardcode durations. Read `plusEnableEnhancedAnimations` from `PlusSettingsProvider` |
| `context.watch` vs `context.select` | `context.watch<P>()` rebuilds on ANY field change in P. `context.select<P,T>((p) => p.field)` rebuilds only when `field` changes. Use `select` in leaf widgets reading a single setting |
| `command grep` not `grep` | Shell `grep` is overridden to `ugrep` which crashes. Always prefix with `command grep` |

## Performance patterns

| Pattern | Where to apply |
|---------|---------------|
| Memoize filter+sort by `appsRevision` | Never filter/sort app lists inside `build()`. Memoize in `State` keyed on `appsRevision`+`appsCount` — recompute only when deps change |
| `ValueNotifier<T>` for progress | Progress values should use `ValueNotifier` + `ValueListenableBuilder`, not `notifyListeners()`, to avoid full tree rebuilds on every tick |
| Microtask coalesce (`_scheduleXNotification`) | Rapid back-to-back `notifyListeners()` (icon loads, concurrent saves) should coalesce: `if (!_flag) { _flag = true; Future.microtask(() { _flag = false; notifyListeners(); }); }` |
| `deepCopy: false` in read-only `build()` | `getAppValues()` deep-copies all app objects by default. Pass `deepCopy: false` in build methods that never mutate |

## M3E design tokens

| Token | Usage |
|-------|-------|
| `CardMetrics.pill(radius)` | Outer capsule geometry for nav bars, segmented filters |
| `CardMetrics.inner(radius)` | Inner pill for nested buttons, indicators |
| `CardMetrics.card(radius)` | App-list cards and grid tiles |
| `Cubic(0.05, 0.7, 0.1, 1.0)` | `expressiveDecelerate` — use for ALL shape morphs |
| `AppConstants.glassBlurSigma` (24.0) | Strong glass blur (dialogs, omnibar sheet) |
| `AppConstants.glassBlurSigmaSoft` (12.0) | Soft glass blur (nav bars, cards) |
| `ScaleTouchWrapper(scaleDownFactor: 0.94, hapticOnPressDown: true)` | Standard interactive element wrapper |

## Dead code traps

These files exist but are unreachable — editing them does nothing:
- `apps_provider_lifecycle.dart`, `apps_provider_install.dart` — extension methods shadowed by same-named class methods in `apps_provider.dart`
- `app_crud_service.dart` — imported by zero files
- `lib/components/app_list_tile.dart` (top-level) — shadowed by `lib/components/apps/app_list_tile.dart`

Always check the `lib/components/apps/` subdirectory, not `lib/components/` root, for app-tile files.

## Branding

- Display name `Obtainium+` (`label` in `android/app/src/main/res/values/string.xml`); applicationId `dev.thejaustin.obtainiumplus`. Dart package name stays `obtainium` in `pubspec.yaml` — don't rename it (breaks every `package:obtainium/...` import).
- Version scheme: upstream version + `-pNN` patch suffix (e.g. `1.6.17-p1`), auto-bumped by CI.
- Fork-specific settings/features are "Plus" (`PlusSettingsProvider`, `plusEnable*` keys); the `enableAllPlusFeatures` master switch hides all Plus-branded settings.
- Icon assets live in `assets/graphics/` (`icon.svg`, `icon.png`, `icon_small.png`).

### Project family (all by thejaustin)

| Product | Display name | Repo | Package / coordinates | Upstream |
|---------|-------------|------|------------------------|----------|
| Shizuku+ | `Shizuku+` | `thejaustin/ShizukuPlus` | `af.shizuku.plus.api` (Plus flavor), `moe.shizuku.privileged.api` (Drop-In flavor) | thedjchi/Shizuku ← RikkaApps/Shizuku |
| Shizuku+-API | `Shizuku+-API` | `thejaustin/ShizukuPlus-API` | Maven group `af.shizuku.plus`; JitPack `com.github.thejaustin:Shizuku+-API:<ver>-plus` | RikkaApps/Shizuku-API |
| Obtainium+ | `Obtainium+` | `thejaustin/ObtainiumPlus` | `dev.thejaustin.obtainiumplus` | ImranR98/Obtainium |
| SuperShade | `SuperShade` | `thejaustin/SuperShade` | `com.supershade` | original (no upstream) |

Naming rules:
- User-facing text uses the `+` form (`Shizuku+`, `Obtainium+`); repo names, URLs, and code identifiers spell it `Plus` (`ShizukuPlus`, `PlusSettingsProvider`). Never write "Shizuku Plus" or "ObtainiumPlus" in UI strings.
- `SuperShade` is one word, capital S twice — never "Super Shade" / "Supershade".
- Refer to upstreams by their own names (Shizuku, Obtainium) and credit them; don't rebrand upstream attributions or license notices.

## Sentry / issues
- Sentry DSN injected via `--dart-define=SENTRY_DSN` (CI secret); `sentry-sync.yml` mirrors unresolved issues to GH issues (label `sentry-crash`) every 6h.
- Sentry quota can exhaust — "no Sentry issues" ≠ "no crashes".
- Issue comments signed "— Claude" after a blank line.
