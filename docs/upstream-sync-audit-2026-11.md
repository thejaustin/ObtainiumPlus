# Upstream sync audit — 2026-11-10

Fork: `feature/review-2026-11` (version `1.7.3-p15`). Upstream: `ImranR98/Obtainium` `main`, at **1.7.4** (Nov 1).

## Method

After the 2026-10 history rewrite, commit IDs no longer match upstream, and `git log HEAD..upstream/main` reports about 2.8k commits. So each upstream non-merge commit since 2026-06 was checked three ways:

1. **Subject**: is the exact subject in the fork's log?
2. **Lines**: what share of the commit's added lines (more than 30 characters, not comments or imports) exist anywhere in the fork's `lib/`, `android/` and `pubspec.yaml`?
3. **Identifiers and keys**: are the identifiers and `en.json` keys that the commit introduced in the fork?

Only code that still exists at upstream's tip is scored, so code upstream later renamed doesn't count as missing. **Fork files that ship nothing are excluded**: `analyze-live.sh --dead` plus the shadowed `apps_provider_lifecycle.dart`, `apps_provider_install.dart`, `app_crud_service.dart` and root `app_list_tile.dart`. Code that exists only there counts as not ported.

A low score can also mean the fork rewrote the same feature in its own way. That is common for UI, because the fork has its own M3E settings and app list. Items marked "check" need a person to look.

Upstream versions by date: 1.6.18 (Sep 13), 1.7.0 (Oct 16), 1.7.1 (Oct 17), 1.7.2 (Oct 22), 1.7.3 (Oct 24), 1.7.4 (Nov 1).

## Summary

| Period | Upstream commits | Subject match | Notes |
|---|---|---|---|
| ≤ 2026-08 | all | ~100% | in sync |
| 2026-09 | 128 | 124 | 3 Uptodown/download items partial |
| 2026-10 | 172 | 23 | about 52 more are fully present under other subjects (squashed ports) |
| 2026-11 | 4 | 1 | |

Commits since June with no matching subject:
- 52: code fully present (85% or more of lines).
- 38: partly present.
- 30: mostly absent.
- 40: no code, only translations, docs, Flutter bumps or skills.

**Versioning rule:** the fork is named 1.7.3, but part of upstream ≤ 1.7.3 is not merged (see below). AGENTS.md says the base version must not match upstream until everything up to it is merged. Whether deliberate UI divergence (the "probably skip" list) may count as handled is **the user's decision**; the rule as written doesn't allow it. Don't move to 1.7.4 until the 1.7.4 items are done.

## Ported into dead code (looks done, ships nothing)

Earlier sessions ported these upstream fixes into the shadowed `AppsProvider` extensions or into a file nothing imports. The live code in `apps_provider.dart` doesn't have them:

| Upstream | Ver | Fix | Where the port sits | Live state |
|---|---|---|---|---|
| 096af9324 (+ resolveBulkOrLookup) | 1.7.1 | Keep marked-updated versions across incomplete package loads (#3215) | `apps_provider_lifecycle.dart` (`resolveBulkOrLookup`, `shouldClearInstalledVersion`) | **live bug**: `loadApps` treats an app missing from the bulk `getInstalledPackages` list as uninstalled and adds it to `removedAppIds`, with no per-app lookup |
| c10bb1bab | 1.7.0 | Bound non-stock install waits so batch updates can't hang (#3369) | `apps_provider_install.dart` (`shouldPollForInstallConfirmation`) | check the live install wait in `apps_provider.dart` / `app_install_service.dart` |
| fa71542aa, 1b0b45e9a | 1.7.0 | Background guards limit checks as well as installs (#3370) | `lib/utils/bg_update_guards.dart` (unreachable) | strings `bgGuardChecksOnly`… are in en.json, but the logic isn't wired |
| d51ab11dd, b300f7933 | 1.7.2 | Recreate the icon cache dir; survive icon load failures (#3433, #3428) | `apps_provider_lifecycle.dart` | **equivalent live**: `AppsProvider.updateAppIcon` recreates the dir and catches load and write errors. Lead for the placeholder-icon bug: a failed load adds the app to `_failedIconAppIds` for the whole session, even if `installedInfo` just wasn't loaded yet |


## Done on 2026-11-10/11

- **#3215** (096af9324 + b1c0047f6): moved into the live `loadApps` / `getCorrectedInstallStatusAppIfPossible` (f2b78a420, 85b0f57e4).
- **#3370** (fa71542aa): three-way guards in the live `background_update_service.dart`, with a Settings UI (b649c755d).
- **#3369**: no change needed; Shizuku (90 s), root (60 s) and stock already time out, and external reports natively.
- **897b112c5** Codeberg port (c7c5e3d51).
- **#3473** plus the duplicate `ApkFilterService` deleted from `source_provider.dart` (2e20cc2cd).
- **#3470/#3471/#2101** changelog links at the release tag, plus soft line breaks (b06b4f696).
- **7d89128ac APKCombo removal: deliberately not ported.** In the fork, an app whose source no longer resolves is quarantined at load with an "apps removed" notification, so removing the source would pull users' tracked APKCombo apps out of their library. The source stays; its checks just fail.


- 44f014778 Fix signing certificate checks on Android 9 and 10 (#3475)
- ef0eed86a DCL fallback (#3442): core only. The detector and the Cronet gate are ported. The **"Use Android certificate store" setting and the one-time warning dialog are not**.

## Not ported: bug fixes (cheap, do first)

| Upstream | Ver | What | State |
|---|---|---|---|
| 897b112c5 | 1.7.4 | Codeberg/Forgejo self-hosted URLs with a port (`(?::[0-9]+)?` in `pathPattern`) | absent, one line |
| 9b044613e | 1.7.4 | Prefer the ABI-specific APK when the saved choice is universal (#3473) | absent (`resolvePreferredApkIndexForArchFilter`) |
| 7d89128ac | 1.7.4 | Remove the defunct APKCombo source (#3468) | absent (`apkcombo.dart` still shipped) |
| d3c88e0a6, ad1c208e5, fa54c4349 | 1.7.4 | Changelog links resolved against the release; soft line breaks kept (#3470, #2101) | fork has its own `resolveChangeLogLink`; check that it covers release-relative links and `softLineBreak` |
| b1c0047f6 | 1.7.2 | Keep version detection on in versionCode mode (#3215) | about half: check `getCorrectedInstallStatusAppIfPossible` |
| 220d5b89b | 1.6.18 | Keep downloads alive when the app is backgrounded (#2894) | partial: `_holdRetryUntilForeground` missing, but the follow-up 76c0c089b is present. Check |
| 4b9e9549a | 1.7.0 | Release-date pseudo-versions on Forgejo/Codeberg (#3339) | Codeberg toggle present. The fork's `created_at` fallback is on asset dates (`github.dart:29`), while upstream's is on the release `e` near line 447. Check |
| 3ade5e686 | 1.7.0 | Disable apps (#3375): `toggleAppDisabled`, `setSelectedAppsDisabled` | keys present, actions missing (see features) |
| c0387eefa | 1.7.0 | `plural()` for the background error summary | present |

## Not ported: features

| Upstream | Ver | Feature | State |
|---|---|---|---|
| ccd3e026f, 9d586ade9, 02c21a637, 5a379111b, 23e9b8ea6, e67e258cf | 1.7.0 | **Update health** (#1753) | **mostly present** (79–92% after the rename). Missing: `_fetchRepoInfoQuietly` (archived-repo signal), `updateHealthConfig`/`Ignored`/`ViewDetails`, and the app-option section links (`sectionReleaseOptions`…) |
| 3ade5e686, e47cf6466 | 1.7.0 | **Disable apps without removing them** (#3375) | partial: `toggleAppDisabled`/`setSelectedAppsDisabled`/`isDisabled` missing |
| 85cc3b36e | 1.7.0 | Exclude categories from update checks (#3375) | about 65%: `skipUpdateChecks`/`_excludeFromChecks` missing. Check |
| ffdfe1fb0 | 1.7.0 | **Choose the Shizuku or Dhizuku installer backend** (#2844) | partial: `shizukuBackend*` missing. Conflicts with the fork's own Shizuku+/Dhizuku handling; decide before porting |
| 863455bd5 | 1.7.4 | **Per-app install method** | absent (`installerModeFor`) |
| 3fc108a46, 57f5de908, 013b58265 | 1.7.2 | **Custom certificate pins UI** (#3200) | absent (Cronet "phase 3": `PinStore`, `CertificatePinningPage`, `CertificateBridge`) |
| 80bc82f84 | 1.7.2 | Embedded Cronet | metadata requests ported (phase 1). Downloads still use dart:io (phase 2); certificate export keys absent |
| 310cca1ed, a652ee081, 66c75deab | 1.6.18–1.7.1 | Galaxy Store: Global/China search profiles, a "requires Shizuku" hint, custom MCC/MNC | partial or absent |
| e1f46dc6c, 1b5974d7b | 1.7.0 | **Exports to Downloads** (MediaStore) plus the TV focus pass | partial: the Downloads export path is missing |
| b975c0e23, 861bd0bab, 1d0666d91, ccbf31b04 | 1.7.0–1.7.3 | TV remote-operable dialogs and pickers, pinned add-app footer, TV icons | mostly absent |
| 40b387810, 826ca181f, 4cc4604a3, b277fbd3b | 1.7.0–1.7.3 | found-time release date, GitHub drafts, global version trim, add without checking | present (71–100%) |

## Probably skip (the fork diverged on purpose)

- Upstream's settings and Add App visual polish from Oct 16 to 23: 790fabb9c, e82e930ac, b0104f7cd, 50c3a192b, 9a919c697, d07810eef, ed869c9c2, b50577876, 75a046355, 80785f31e, b87cedc7e, 3ae94d06f, ee78f5b60, f1028f45e, fa5755b60, 6c3277056, 83b0e73df, f8b62c2a1, 510db8f0e. The fork has its own M3E design. Only take behaviour from these, such as `addAppHint` guidance or URL import page navigation, and not layout.
- c6499cbec: swipe actions off by default. The fork's own default is the fork's call.
- 5ed130a51 + e09e6794d: open-in-browser was restored and then reverted, so the net change is zero.
- June revert and R8 commits (5b0059f87, cb55e00ac, 83f22e975, 2d31106e6): upstream build housekeeping from a bad release.
- Upstream agent and skill docs (35beb8942, c95deb9d0, 713545952, 69a1b9457, c8bd01e70).

## Not checked line by line

- Translation-only commits (de, zh, bn, bs, ru, hu, fr, el, plus stale English placeholders 5994c0d57 and bb76ceb78). `el.json` exists. The fork syncs keys with its own script, so diff values per locale before taking upstream wording.
- Flutter 3.47.8 and 3.47.9 bumps plus package updates (1a3aea342, fe9319579, eb8ae8a19). Local SDK is 3.47.7; check what CI pins.

## Suggested order

1. **#3215 bulk-list fix into the live `loadApps`**: a live bug that can drop apps.
2. Wire #3370 (background guards) and check #3369 (install waits) in live code; then delete or move the dead copies so this doesn't happen again.
3. Bug-fix table: Codeberg port (897b112c5), ABI preference (9b044613e), versionCode detection (b1c0047f6), changelog links. Check how upstream handles apps already tracked with APKCombo before removing that source (7d89128ac).
4. DCL setting and dialog (finishes #3442), then cert-store export keys.
5. Disable apps, exclude-categories check, per-app install method, update-health gaps.
6. Decide on: Shizuku/Dhizuku backend choice, TV pass, Downloads export, Galaxy Store extras, certificate pins UI.
7. Only after 1–5 are in (and the user has decided on the skip list): move the base version to 1.7.4.

Re-run after each batch: `python3 scripts/dev/upstream-audit.py 2026-09-01` (needs `git fetch upstream`).
