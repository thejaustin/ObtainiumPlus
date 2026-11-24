# Settings UX audit (2026-11-24)

A pass over Obtainium+ settings: `lib/pages/settings.dart`, `lib/components/settings/*`,
`lib/pages/developer_settings.dart`, `lib/pages/visual_lab_page.dart` and the English labels in
`assets/translations/en.json`. Ranked by how much each one confuses people. Every claim below was
checked against the code or en.json at the time of writing; nothing here is implemented yet.

Rule for every fix: change only the **title, description, grouping or section**. Keep each
setting's storage key (`plusUseCompactSettings`, `plusEnableModernAppListTile`, ...) and its
translation key stable so saved values and settings search keep working. Search matches
`tr(title)` and `tr(desc)` through `_matches(...)`, so a rename is picked up automatically.

Effort: S = a label or one row move, M = a row move plus wiring, L = new control or migration.

## 1. "Compact" means five different things (high) - effort S

- `plusUseCompactSettings` "Compact settings layout" (`settings_page_section.dart`), also toggled
  by a density icon button in the Settings toolbar (`settings.dart` `_buildDensityToggle`).
- `appListDensity` "App list density" with a Compact option, and a separate `listDensity` /
  `gridCategoryDisplay` ("Category grid display", described as "standard and compact") in
  `apps_view_settings_section.dart`.
- `visualLabHeaderSize` Large/Compact (Settings app bar) in `visual_lab_page.dart`.
- `settingsUseGridToggles` titled "Compact Grid Toggles" (it is a 2-column card layout, not density).
- `plusEnableModernAppListTile` description says "Off uses the classic compact list".

Fix: reserve "density" for spacing only. Scope each name: "Settings density", "App list density",
"Settings header size" (not "Compact"), "Two-column toggles", "Category chip layout". Keep the
Settings-toolbar icon but give its tooltip the same "Settings density" name.

## 2. Two dead-looking duplicate compact-settings strings (medium) - effort S

en.json still has `useCompactSettings` ("Use Compact Settings") and `useCompactSettingsDescription`
which no Dart file references (`rg` finds no usage). They read as a second switch for the same
thing as #1 and confuse translators and anyone grepping labels. Delete both keys (and the other
translations' copies), or alias them to the live key.

## 3. Three overlapping "Expressive" style controls (high) - effort M

`theme_settings_section.dart` offers a Design system selector whose options are "Obtainium+ Theme",
"Material 3 Expressive" and "Material Expressive style" (`plusMaterialExpressive`, "Use the latest
Material 3 expressive motion and shapes"), next to "Match system Material style"
(`matchSystemMaterialStyle`, which per its own description overrides Expressive styling and custom
corner radius). Two options named almost identically sit in one picker, and the third control
silently overrides both. In Motion, `plusExpressiveProgress` "Expressive progress bars",
`plusUpdateExpressiveBadge` "Expressive Update Pill" and `plusEnableModernAppListTile`
"Expressive app list" use the word for per-widget toggles that have no relation to the design system.

Fix: give the picker three distinct names ("Obtainium+ classic", "Material 3 Expressive (full)",
"Material 3 Expressive (light)" or drop the duplicate if both resolve to the same style, which
needs a code check first), and put "Match system Material style" directly under it with
"Overrides the style above" in the title area. Reserve "Expressive" for the design system;
rename the per-widget ones to what they change (see quick wins).

## 4. Animation switches overlap (high) - effort S

`plusEnhancedAnimations` "Enhanced animations" (description: "smooth expressive transitions and
bouncy physics") and `plusBouncyPhysics` "Bouncy scroll physics" are separate rows in
`motion_haptics_section.dart`, but the first claims to include the second. Also
`disablePageTransitions`, `reversePageTransitions` and `animationSpeed` sit in the same group, so
"Enhanced animations" off plus "Disable page transitions" off has no obvious outcome.
`plusEnableEnhancedAnimations` gates durations in ~15 files (omnibar, badge, tile entrance, sort
panel), so it is really a master motion switch.

Fix: rename to "Expressive motion" with the description "Master switch: entrance, press and
transition animations", move "Bouncy scroll physics" beneath it as a child row
(`SettingsChildRows`, already used in `settings_page_section.dart`), and drop "and bouncy
physics" from the description.

## 5. "Plus" master switch with unclear scope (high) - effort M

`enableAllPlusFeatures` "Enable all Obtainium+ features" ("Master switch ... all 'Plus'
enhancements") is also read by `notifications_provider.dart`. Many rows use
`buildFeatureToggle` with `hideWhenPlusOff` true, so rows vanish when it is off, while others pass
`hideWhenPlusOff: false` (all the Settings-page layout toggles) because they only live in the Plus
provider. The user cannot tell which switches the master controls, and "Plus" prefixes appear in
titles inconsistently ("Obtainium+ & Interface" `advancedPlusGroupTitle`, "Enable all Obtainium+
features", "Obtainium+ button" in the Visual Lab, "Obtainium+ Theme" which is a design system).

Fix: retitle the master "Plus enhancements" with a description that lists what turns off
("Hides the Plus rows below and returns to the base Obtainium behaviour"). Rename the
"Obtainium+ Theme" design option to "Classic" so "Obtainium+" always means the feature set.

## 6. Shapes control lives in Developer options and in Appearance (medium) - effort S

`settingsAppearanceShapes` "Shapes" (Corner radius for cards, tiles and buttons) is a card in
`appearance_hub.dart` and is also rendered inside Developer & Diagnostics under the section
"Expressive Design & Shapes" (`developer_settings.dart:611-620`), next to `plusUseWavyLoadingSpinner`
("for comparison"). Same label twice on two screens, and a user-facing control under developer
options.

Fix: keep Shapes only in Appearance; leave the section in Developer options for test/comparison
rows only and retitle it "Shape and spinner experiments".

## 7. Settings-page layout options are scattered and mislabelled (medium) - effort M

The Settings page layout has controls in two places: `settings_page_section.dart`
(Compact settings layout, description lines, Compact Grid Toggles, Visual Theme Selector,
Expressive Status Cards) and the Visual Lab (header size, app bar actions, overview card, overview
chips, nav blur). "Expressive Status Cards" (`settingsUseHeroCards`) is described as the "Shizuku
status card and service banners", while the Visual Lab "Overview card" (`visualLabHero`) is
"the status card at the top of each Settings tab". These read as the same card with two switches;
they are different widgets (Shizuku card vs settings hero), which only code reading reveals.

Fix: rename `settingsUseHeroCards` "Service status banners" (Shizuku and similar), keep
"Overview card" for the Visual Lab one, and add "(Visual Lab)" pointers in each description.
Longer term, move the Settings-page layout rows into one "Settings layout" group.

## 8. Visual Lab status unclear (medium) - effort S

`visualLab` is reachable from Developer & Diagnostics and its own description says "Try out visual
alternatives. Every option starts at the shipped look". But some Lab controls
(`visualLabNavPlacement`, description lines, header size) are also shown in regular Settings
rows via `settings_page_section.dart`, so users find the same option in two places with the "Lab"
word in one only. en.json also has `visualLabPlusEntry` / `visualLabPlusEntryDesc` that
`visual_lab_page.dart` does not use.

Fix: add "Also under Settings > Appearance" to the Lab subtitle; remove the unused
`visualLabPlusEntry*` keys if no other file references them.

## 9. Navigation labels: two rows for one idea (medium) - effort S

`navigationLabels` ("Choose when to show text labels...") and `plusNavBarAlwaysShowLabels`
("Always Show Navigation Labels") are two rows in `theme_settings_section.dart` (lines 130-135),
and `view_settings_provider.dart:281` shows the boolean is only consulted as a fallback. A user
can set "Navigation labels" to "never" and flip "Always show" on with no explanation of the winner.

Fix: if the choice row already has an Always option, hide the boolean behind it (code check
needed), otherwise merge copy: "Navigation labels (when 'Always show' is on, this is ignored)".

## 10. Experimental / legacy words with nothing behind them (medium) - effort S

- `legacyUiComparison`, `settingsGranularOldUI` ("Legacy & Granular UI Elements"),
  `settingsLayoutMode`/`settingsLayoutM3E` and `unlocksExperimentalAdvancedTheming` exist in en.json
  but no Dart file references them: leftovers of removed options.
- `legacyObtainiumLogs` "Legacy obtainium logs" (lower-case brand) is still wired in Developer options.
- `gsfProxyDescription` calls the proxy "Legacy" without saying whether it should be used.
- `advancedFeaturesSubtitle` calls the section "Experimental and 'Plus' exclusive enhancements",
  mixing two unrelated concepts.

Fix: delete the unreferenced keys; retitle logs "Older log viewer"; explain the GSF proxy as
"Only needed if an app refuses microG"; retitle the section subtitle "Optional Obtainium+
features and tools".

## 11. Jargon in descriptions (low) - effort S

`plusHardwareAcceleration` ("GPU-accelerated texture composition and Impeller Vulkan backend"),
`plusGridRepaintBoundaries` ("Isolate Tile Repaint Boundaries ... invalidating GPU layers"),
`gpuPipelineVulkan`, `plusMaxIconMemoryEntries`, `plusUseWavyLoadingSpinner` ("Replaces the M3E
morphing loading indicator"). They are in Developer options so the audience is smaller, but none
say what the user would notice or when to touch them.

Fix: "Smoother scrolling on supported phones. Turn off if you see glitches." style rewrites;
spell out M3E.

## 12. Title case drift (low) - effort S

en.json mixes sentence case ("Compact settings layout", "App list density") with Title Case
("Use Compact Settings", "Always Show Navigation Labels", "Compact Grid Toggles", "Visual Theme
Selector", "Expressive Status Cards", "Pill Tag Filter Chips", "Use Wavy Loading Spinner",
"Expressive Update Pill", "Settings Layout Style"). Also "Shizuku+" vs "Obtainium+" vs "Plus".

Fix: sentence case for all setting titles in one pass; no key changes.

## Cheap wins (en.json only, no code or key changes)

1. `plusEnhancedAnimations`: "Enhanced animations" -> "Expressive motion"; description -> "Master
   switch for entrance, press and transition animations" (drops the "bouncy physics" overlap).
2. `settingsUseGridToggles`: "Compact Grid Toggles" -> "Two-column toggles"; `plusUseCompactSettings`
   -> "Settings density: compact" so only density says compact.
3. `settingsUseHeroCards`: "Expressive Status Cards" -> "Service status banners"; same for its Desc.
4. `plusEnableModernAppListTile` "Expressive app list" stays but description -> "Rows with swipe
   actions and drag-to-reorder pinned apps. Off shows the simple list."; `plusExpressiveProgress`
   -> "Animated progress bars"; `plusUpdateExpressiveBadge` -> "Version pill on update button".
5. `obtainiumPlusTheme` "Obtainium+ Theme" -> "Classic"; `plusMaterialExpressive` ->
   "Material 3 Expressive (light)"; `advancedFeaturesSubtitle` -> "Optional Obtainium+ features and tools".
