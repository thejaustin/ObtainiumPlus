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
**Always `git pull --rebase origin main` before push** — CI bump commits land constantly.

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

## Sentry / issues
- Sentry DSN injected via `--dart-define=SENTRY_DSN` (CI secret); `sentry-sync.yml` mirrors unresolved issues to GH issues (label `sentry-crash`) every 6h.
- Sentry quota can exhaust — "no Sentry issues" ≠ "no crashes".
- Issue comments signed "— Claude" after a blank line.
