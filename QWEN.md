# ObtainiumPlus — Qwen Code Context

## Project Overview
Flutter fork of Obtainium — installs/updates Android apps directly from sources. Extended with scheduling, glass UI, preferred sources, dev channel, and Plus features.

## Language & Stack
- Dart / Flutter
- State management: Provider (`SettingsProvider`, `UpdateSettingsProvider`, `AppsProvider`)
- All UI strings via `tr('key')` from `easy_localization` — add new keys to `assets/translations/en.json`
- Crash reporting: Sentry (org: `af-developments`, project: `obtainiumplus`)

## Key Files
- `lib/components/settings/update_settings_section.dart` — update settings UI
- `lib/providers/update_settings_provider.dart` — update-related state
- `lib/providers/settings_provider.dart` — general settings state
- `lib/providers/plus_settings_provider.dart` — Plus feature flags
- `assets/translations/en.json` — ALL UI strings (camelCase keys)
- `lib/pages/settings.dart` — main settings page
- `lib/main.dart` — Sentry init, app entry

## Critical Rules
- NEVER call `notifyListeners()` from inside `build()` — causes infinite rebuild loops
- Always `mounted` check after any `await` before using `context` or `setState()`
- `super.dispose()` MUST be the last call in `dispose()` overrides
- Use explicit typed consumers: `Consumer<SettingsProvider>`, NOT generic `Consumer<T>`

## Release Tag Format
- Stable/patch: `v1.2.9-p107` (`vMAJOR.MINOR.PATCH-pPATCHNUM`)
- Dev: `dev-339` (`dev-BUILDNUM`)

## Update Channel
- Channel pref: `UpdateSettingsProvider.obtainiumReleaseChannel` (`'latest'` or `'dev'`)
- Dev warning: `AlertDialog` in `update_settings_section.dart` before committing to `'dev'`
- Stable API: `/releases/latest` | Dev API: `/releases?per_page=1`

## Git Workflow
- Pre-commit hook runs `flutter analyze` — fails on Termux (glibc). Use `--no-verify` if stuck; CI handles it.
- Non-fast-forward: `git pull --rebase origin HEAD` then push

## Build
- `flutter build apk --release`
- Do NOT commit CLAUDE.md, GEMINI.md, QWEN.md or other AI config files
