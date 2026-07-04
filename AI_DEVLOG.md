# ObtainiumPlus — AI Session Devlog

Living document. Update at the start of every AI session: mark completed items, add new ones.
Single source of truth for cross-session continuity.

Flutter app (Dart). Project at `/data/data/com.termux/files/home/ObtainiumPlus/`.

---

## Open Backlog

### Crashes / Sentry
- [ ] **Sentry audit** — check if any new issues appeared after 1.4.3-p23
- [ ] **Prefs parsing TypeErrors** — re-enabled Sentry (#217) and hardened prefs parsing; verify fix holds

### UI
- [ ] **App list clarity** — icons were blurry; fixed with `filterQuality: FilterQuality.high`; verify on device
- [ ] **Grid/list toggle** — added to apps.dart; test persistence across restarts
- [ ] **Glassmorphism blurs** — clipped to widget bounds (3aedd98c); verify no regression on list text

### Infrastructure
- [ ] **Auto-bump workflow** — version bumps auto-committed; ensure PRs don't conflict with bump commits
- [ ] **Flutter test compilation** — fixed in a7a0ef14; run `flutter test` to confirm green

---

## Session History (newest first)

### 2026-07-04 — Claude Code (Fable 5) [session 854c1d79 continued]

**Goal:** close out GitHub issues #217 and #218 with in-depth fixes; verify Sentry is clean.

**Done:**
- **#218 root cause** — `1.4.3-pNN` matched no standard version regex, so `getCorrectedInstallStatusAppIfPossible` case FOUR auto-disabled version detection and froze `installedVersion` → perpetual update prompt. Fixed with `p[0-9]+` suffix pattern + new FIFTH self-heal case in `apps_provider.dart` (corrects `installedVersion` to `latestVersion` only when the OS versionName reconciles as equal to latest).
- **#217 defense-in-depth** — `safe_prefs.dart` extension (type-tolerant `safeDouble`/`safeInt`/`safeBool`) applied across all 8 providers; release-mode `ErrorWidget.builder` replaced with a labeled error card; Sentry re-enabled in `main.dart` (was dropped in fb5a91c2) with Shizuku-noise `beforeSend` filter.
- **Changelog version constant** — `lib/utils/version_constant.dart` replaces hardcoded `1.4.3-p15` in `home.dart`; CI auto-bump step now seds it alongside pubspec.yaml.
- **Tests** — `test/version_detection_test.dart` (#218 regression) and `test/safe_prefs_test.dart` (#217 regression).
- **Gotcha hit:** `TextDirection.ltr` broke CI — easy_localization re-exports intl's `TextDirection`; must use `ui.TextDirection.ltr` in main.dart.
- **Sentry state:** all `sentry-crash` GH issues closed; sentry-sync runs green with nothing new.

### 2026-06-29 → 2026-07-04 — Claude Code (Sonnet 4.6) [Termux session, 854c1d79]

**Session note:** Ran from Termux environment. Session invisible from PRoot until 2026-07-04 sync.

**Commits:** `009ec11c` through `7f471fd9` (8 commits + 5 auto-bumps)

**Done:**

*Settings menu:*
- **Fixed compilation errors** in settings components (`PlusFeaturesSection`, related widgets)
- **Removed quick actions grid** from `app_dashboard.dart` and `plus_features_section.dart` — was causing crashes and visual clutter
- **Grid/list view toggle** added to `apps.dart` — toggle button in app bar, `getDisplayedList()` updated

*UI:*
- **Blurry icon fix** — wrapped `Image.memory` in `SizedBox` + `filterQuality: FilterQuality.high`
- **Stats hub removed** from dashboard (f6dc0319) — too visually distracting
- **Glassmorphism backdrop blurs** clipped to widget bounds (3aedd98c) — was blurring text below
- **UI polish** — icon blur, settings consistency, crash prevention (009ec11c)

*Crashes / Sentry:*
- **Re-enabled Sentry crash reporting** (7f471fd9, #217) — had been accidentally disabled
- **Hardened prefs parsing** against TypeErrors — strict type coercion → safe null fallback
- **GitHub/Sentry issues** checked; commented on open issues before resolving

**Notes:**
- Auto-bump version tags (`p19`–`p23`) interspersed with fixes; version is now `1.4.3-p23`
- Session hit monthly spend limit and session limit at the end

### 2026-06-26 → 2026-06-29 — Antigravity CLI [session a6590a93, multi-day]

**Topics covered (from history):**
- App update/install detection failures — when links not detected or apps don't install properly
- Update detection for custom GitHub-hosted apps (ShizukuPlus, ObtainiumPlus versioning)
- UI/UX improvements: animations, vibrations, settings, empty states, error states
- Material 3 Expressive design audit (wave animation, Google Play style)
- Settings refactor
- Sentry and GitHub issue review and fixes
- CI builds — multiple checks for successful GH Actions APK
- Android developer knowledge MCP tooling setup

**Notes:** This was a very long multi-day session (Jun 26 09:15 → Jun 29+ based on timestamps). Commits from this period are in the Jun 28 and Jun 29 commit ranges already logged above.

### 2026-06-01 → 2026-06-14 — Gemini CLI [multiple sessions, pre-Claude]

**Sessions:**
- `session-2026-06-01T03-30` (180MB) — capsCase codenames UI fix and extensive feature work
- `session-2026-06-04T09-33` (4.8MB) — GitHub stats graphics (thejaustin profile)
- `session-2026-06-08T02-14` (175KB) — GitHub profile improvements, layout
- `session-2026-06-15T17-54` (105KB) — Claude setup troubleshooting in PRoot context

**Key work from these sessions:**
- CapsCase/codename display issues fixed across app
- Aurora Store connection removed (per Rahul's request — disabled across all versions retroactively)
- Manual APK source addition for users (workaround for Aurora removal)
- GitHub profile stats graphics (thejaustin repo)
- Settings design consistency
- Various Gemini-era crash and UI fixes

**Note:** These sessions ran before Claude was installed (Jun 14). "Continue where Gemini and Antigravity left off" in the first Claude session (Jun 15) refers to this body of work.

### 2026-05-29 → 2026-05-31 — Antigravity CLI [sessions 118dc5d1, d4c4405e, 3605823d]

**Context:** Device was reset — all prior data deleted. Starting fresh rebuild of development environment.

**Key work:**
- Rebuilt development environment post-device-reset
- Glassmorphism onboarding toggle — works without app restart; returns to same onboarding step with new design
- Removed Aurora Store connection (`118dc5d1`) — removed from all versions retroactively
- Manual APK source flow implemented (`118dc5d1`)
- GitHub Dev Knowledge MCP integration explored (`67d4c6db`)
- ShizukuPlus GitHub issue #84 reviewed and addressed (`cae50a77`)
- Naming/structure improvements, visual over textual (`3605823d`)
- Changelogs generated and pushed to repo + GH Actions

### 2026-06-28 — Claude Code (Sonnet 4.6) [Termux session, d66b3105 start + 6cce897a]

**Commits:** `4a243f8e` through `48c2c5c1` (18 commits)

**Done:**

*Features:*
- **Home screen widget** (`2abcc3b0`, #26) — pending updates widget for Android home screen
- **Google Play API protobuf decoding** (`b4fc688c`, #89) — proper protobuf decode for Play API integration
- **Horizontal pill navigation** (`11998a9f`) — settings tabs use pill-style nav
- **GlobalThemeBuilder** (`1ace1916`) — expressive ThemeBuilder hooked up globally; fixes button/component inconsistencies
- **Premium gradients, shadows, haptics** (`644c34dc`) — Android dev tools added
- **Compact layout density** (`68a708d6`) — applied to toggles and checkboxes

*Fixes:*
- **Home_widget version** (`ae30296c`) — bumped to resolve `pub get` failure; updated manifest for 0.9.x API
- **Flutter test compilation** (`a7a0ef14`) — resolved test compile errors
- **Dynamic corner radius** (`75405c37`) — `ChoiceChips` and beta tags use global radius instead of hardcoded values
- **Adding apps from Discovery tab** (`b148da29`, #216) — fixed
- **Sentry background crashes** (`8ff56cc3`, `fc196dbe`, #132, #179, #214)
- **AppFileService import** (`fa9161a1`) — missing import added
- **Wave animation + import** (`38b7ff3a`)
- **ConditionalBlur arguments** (`4a243f8e`) — fixed parenthesis/args in `modal_utils.dart`
- **Glassmorphic dialogs + wave progress** (`133105fb`)
