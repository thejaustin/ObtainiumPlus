# Settings M3 Expressive redesign — plan

**Goal (2026-11-10):** Settings are cluttered and could be structurally far better. Reorganise them so every setting has one clear home, and bring them up to Material 3 Expressive: morphing toggles, consistent grouped rows, spring motion, a coherent haptics vocabulary, and transitions. Use ShizukuPlus's settings (which the user likes) and aShell You as the taste reference. Add new styles alongside the current ones instead of replacing them.

Produced by a multi-agent run on 2026-11-10: five research agents (current settings audit, ShizukuPlus, the M3E corpus, upstream's October settings work, Flutter feasibility); three proposals (A structure-first, B expressive-first, C ShizukuPlus parity) on different models; and an Opus judge that scored them and merged the result below. Base: A (43/50), with ideas grafted from B and C.

Note since writing: "Only when" in Updates now uses the three-way background guards (`bgGuardOnWiFi` and `bgGuardWhileCharging`: Nothing / Check only / Check and update) instead of the `bgUpdateRequires*` switches (b649c755d).

---

## Scores

I checked the code claims these scores depend on (see "Verified facts" below). On the 5-point user-fit column, I scored A 9 and C 6 because C puts back a launcher layout the user has not asked for.

| Criterion | A: structure-first | B: expressive-first | C: ShizukuPlus parity |
|---|---|---|---|
| Declutter / IA clarity | **9.** Five topics, one "More…" per section, a test that every setting appears once | 6. Still four hub cards in tab 0; Behavior is now a leftover bin | 8. Short launcher with live summaries, but about 11 subpages |
| M3E fidelity | 8 | **9.** Hero-moment discipline, `icon_switch`, low-end morph option | 8 |
| Fit with user taste | **9.** Additive styles, no new layout idea, open groups | 8 | 6. The launcher is close to the rejected "different layout" idea; the swipe merge hides a key |
| Implementation risk (mid-range phone) | **8.** Five-section coupling kept, `parallelDownloads` kept | 6. `parallelDownloads` merge changes behaviour; dual hubs | 5. A second layout path through `plusSettingsLayoutMode`; native haptics channel in phase 0 |
| Testability | **9.** `settings_tree_test`, gate test, every test pin kept | 7 | 6. Launcher mode skips `settings_page_test` tab pins |
| **Total / 50** | **43** | 36 | 33 |

**Verified facts these scores rely on:**
- **The two swipe keys are ANDed.** `app_list_view.dart:247-248` and `category_sections.dart:548-549` both need `plusEnableSwipeActions && enableSwipeGestures`.
  - A's master + child row matches this.
  - C's "hide one key" would leave users with the hidden key off unable to swipe at all.
- **`parallelDownloads` is a real mode switch.** It defaults to true (`behavior_settings_provider.dart:221`). False means sequential downloads; true uses `updateDownloadConcurrencyLimit` (`app_download_service.dart:198-205`, `apps_provider.dart:1937-1944`).
  - B and C want to merge it into a "1 = off" slider. That needs a migration and changes how `forceParallelDownloads` behaves, so **keep it as a switch**.
- **The double haptic is real, not just suspected.** In `settings_feature_toggle.dart:93-121`, `ScaleTouchWrapper(hapticOnPressDown: true)` fires `AppHaptics.tapDown()` → `selectionClick` at press. Then `onChanged` fires `toggleOn` (medium). `tapDown` only dedupes against itself (40 ms window).
- **`settings_feature_toggle.dart:18,81` use `context.watch<PlusSettingsProvider>()`**, so every row rebuilds on any Plus setting change.
- **Dead keys have no readers.** `plusSettingsLayoutMode` is read only in the provider and `settings_layout_selector.dart`. `plusShowLegacyUIComparison` and `plusEnableExperimentalCustomization` are read only in the provider and `developer_settings.dart`.
- **Duplicate radius / progress rows** exist at `developer_settings.dart:417-451`.
- **`plusEnablePopupSlider` has real readers:** `collapsible_about.dart:34` and `app_description_card.dart:1117`.
- **`positionalTileRadius` is hard-coded to 24/6** (`theme.dart:7-24`).
- **The switch theme already draws a check/close `thumbIcon`** (`theme_builder.dart:583`).
- **Expressive mode loses predictive back.** `theme_builder.dart:249-250` uses `FadeForwards` when expressive is on and `PredictiveBack` otherwise.
- **`pushRoute` only checks `disablePageTransitions`** (`app_utils.dart:19`); it never checks `AppMotion`.
- **`AppMotion.enabled`, `enabledNow` and `enabledForDependencies` exist** (`motion.dart:64-95`).
- **`material_new_shapes` is not in `pubspec.yaml`.** Only `loading_indicator_m3e` and `animations` are.
- **There are 35 locale files.**
- **Test pins:** `settings_page_test.dart:419-423` pins `byTooltip('Obtainium+')` and the absence of `'APPEARANCE'` and `'UPDATES & INSTALL'`.

## Recommended direction

**Base: Proposal A.** Keep the five-section controller and change what goes in each section, so every coupled site keeps working: `_chipKeys` (5) at `settings.dart:87`, `clamp(0,4)` at `:233`, `jumpToPlusFeatures` (index 4), the dock, the NavigationBar and `SettingsCategoryBarHost`. Every setting gets one home, and rare items go into one "More…" subpage per section.

**Grafted from B:**
- The `icon_switch` style ("icon is the switch"), which is ShizukuPlus's own experimental design.
- `plusReduceShapeMorphs`, a low-end option.
- At most two "hero moments": the theme preview and the Motion card. Everything else stays calm.
- `MotionControlsCard` with a live preview.
- A rule for choice controls: 2–4 options use a connected group, 5 or more use a sheet.

**Grafted from C:**
- Live current-value summaries on hub cards ("Every 6 h · Wi-Fi only").
- `plusIconMorphStyle` (Spin / Morph / Pop).
- Haptics that also follow the system touch-feedback setting.
- The "launcher" top level, but **only as an opt-in later phase** that reuses the dead `plusSettingsLayoutMode` key. It is not the default and not required.

**Conflicts resolved:**
- **Outer radius:** add a `plusSettingsGroupRadius` choice of 12 / 16 / 24 for the new style. For the segmented style the default is 12 (One UI 9). The classic card stays at 24/6.
- **Gap between groups:** 16 dp. The label already adds 12 dp above itself.
- **Haptic on expand:** `selectionClick` at Standard intensity, and ShizukuPlus's `toggleOn`/`toggleOff` at Strong.
- **Leading icon size:** 24 dp, plain, matching aShell. 20 dp at compact density.

## Settings tree

Group labels are open primary-coloured labels with no uppercase text. Rows marked *(adv)* only appear when `plusShowAdvancedSettings` is on. Rows marked *(+)* only appear when `enableAllPlusFeatures` is on.

**0 · Look & motion** (four hub cards; card keys stay so the `settingsAppearanceThemesAndColors` → `SettingsSubpage` / `BackButton` test still passes)
- **Theme & colour** — subpage:
  - *Theme:* `theme` (connected group, or `VisualThemeSelector` when `plusSettingsUseVisualThemePicker` is on), follow system, presets, `useBlackTheme`
  - *Colour:* `useMaterialYou`, `matchSystemMaterialStyle`, `themeVariant`, `themeColor`
  - *Design system* (+): `plusEnableMaterialExpressive`, `plusEnableGlassmorphism`. This is their **only** home; the hub segmented control and the Plus-sheet copies become links.
  - *Text & language:* `useSystemFont`, `forcedLocale`, `navigationLabelBehavior`
- **Shapes** — subpage:
  - Preview
  - `plusGlobalCornerRadius`
  - `plusOverrideIndividualCornerRadius`, with `plusHomeCornerRadius` and `plusSettingsCornerRadius` as child rows (`ConnectedSettingContainer`)
  - **new** `plusSettingsGroupRadius`
  - Reset
  - The duplicate at `developer_settings.dart:417-451` is removed and replaced by a link.
- **Motion & haptics** — subpage:
  - *Motion:* `MotionControlsCard` (hero moment): `plusEnableEnhancedAnimations` as the master, with child rows `animationSpeedMultiplier`, `reversePageTransitions` and `disablePageTransitions` (adv)
  - Below the card: `plusEnableBouncyPhysics`, `plusEnableExpressiveProgress`
  - *Haptics:* `enableHapticFeedback` (moved from Behavior), with child rows **new** `plusHapticIntensity` (Subtle / Standard / Strong) and **new** `plusHapticFollowSystem`
  - *Controls* (+):
    - **new** `plusSwitchStyle` (Classic / Expressive / Shape thumb / Icon is the switch), with a live preview row
    - **new** `plusIconMorphOnToggle`, with child rows `plusIconMorphShape` and `plusIconMorphStyle`
    - **new** `plusReduceShapeMorphs`
- **Settings page** — subpage, one home for layout options that are currently split four ways:
  - **new** `plusSettingsGroupStyle` (Card / Segmented)
  - `plusUseCompactSettings`, with `plusLabCompactDescriptionLines` as a child row (default stays 2)
  - `plusSettingsUseGridToggles`, `plusSettingsUseHeroCards`
  - `plusSettingsNavPlacement`, promoted out of Visual Lab
  - A "Visual Lab" link for the other `plusLab*` keys, which keep their shipped defaults
  - `SettingsLayoutSelector` is removed from Advanced and from `theme_settings_section.dart:335`
- **More…:** `plusEnableOneHandedMode`, `plusTopUILayout` (adv)

**1 · Home & library** (the old Notifications slot; its content now lives in Updates)
- *App list:* `globalViewMode`, `appListDensity`, description style (localised), `appBarStyle`, `gridCategoryMode`, `gridColumnCount`
- *Tiles:* preview, `displayShowAuthor`, `displayShowVersion`, `displayShowDate`, `plusGridShowSourceBadge`, `plusShowTagsInList`
- *Tile style* (+, collapsible, shows an "X / Y on" pill):
  - `plusGridSquareTiles`, `plusGridCardlessStyle`, `plusGridAmbientIconHalo`
  - `plusPinnedBorderAccent`, `plusCategoryAccentRibbon`, `plusUpdateExpressiveBadge`, `plusIconRimBorder`
  - `plusEnableModernAppListTile`
- *Categories & sorting:*
  - Category editor, `groupByCategory`, `categoriesCollapsedByDefault`, `categoryIconPosition`, `categoryIconCount`
  - `plusEnableCategoryReorder`, `plusEnableAdvancedSorting`, `plusEnableQuickFilters`, `plusEnableTags`
- *Updates in the list:* `showUpdatesRow`, `pinUpdates`, `buryNonInstalled`
- *Swipe actions:*
  - `enableSwipeGestures` (master), with `plusEnableSwipeActions` as a child row relabelled "Expressive swipe style". Both keys stay, because the code ANDs them.
  - `SwipePreviewWidget`, `swipeRightAction`, `swipeLeftAction`, `enableUndoForAppRemoval`
- *Navigation & search:*
  - `plusEnableBottomNavBar`, `plusFloatingNavBar`, `plusHideBottomBarOnScroll`, `plusShowStatusHub`
  - `plusShowAppBarSearch`, `plusShowDashboardSearch` (new group label `settingsGroupNavSearch`; drop the old `tr('searchSettings')` title)
  - `displayShowFilterChips`, `displayShowAppCount`, `plusExpressiveFilterChips`
- *Add button:* `plusEnableFAB` (master), with child rows `plusFloatingActionBar` and the four `plusFabShow*` keys; plus `plusEnableModernAddAppPage`
- *Home & details:* `plusEnableHomeDashboard`, `plusHeaderContextSubtitle`, `plusEnableResponsiveAppLayout`, `plusEnablePopupSlider` (relabelled "Collapsible About section"; key unchanged)
- *Library:* `removeOnExternalUninstall` and the rest of the storage rows, `UsageAccessCard`
- *Discover* (+): `plusEnableDiscover`, with `plusDiscoverSuggestions` as a child row

**2 · Updates & notifications**
- An Update Health status row at the top. The duplicate chips in `ConnectedSettingsBar` are removed.
- *Checking:*
  - A "Check now" split button whose menu offers "Installed only"
  - `checkOnStart`, `bgUpdateCheckInterval`, `checkUpdateOnDetailPage`
  - `plusEnableUpdateSchedule` with its sheet
- *Only when:* `bgUpdateRequiresWifi`, `bgUpdateRequiresCharging`, `onlyCheckInstalledOrTrackOnlyApps`, `useFGService`
- *What to update:* release channel, preferred source, `plusEnableAutoUpdateRules` with its sheet, `allowAddingAppsWithoutCheck`
- *Notifications:* system-settings link, `plusEnableNotificationEnhancements` (master), with digest and quiet hours as child rows (summary shows "11 PM – 7 AM")
- **More…:** check-concurrency slider, `plusEnableSystemUpdateScanner` (beta), Xiaomi troubleshooting

**3 · Install & safety**
- *Installer:* method, `ShizukuStatusCard`, `shizukuPretendToBeGooglePlay`, `shizukuFallbackToSystem` (the only copy; the Plus sheet links here)
- *Downloads:* `parallelDownloads` (master, kept), with `updateDownloadConcurrencyLimit` as its child row (dimmed when the master is off)
- *Before installing:* `askAboutOtherInstalledBuilds`, `beforeNewInstallsShareToAppVerifier`, install unknown apps, forget variant choices
- *Sources:* `allowThirdPartySources`, `usePlayStoreAppLinks`, `plusEnableMicroGHub`
- *Safety:* `plusEnableBanWarnings`, with `plusBanWarningThreshold` as a child row
- **More…:** `plusEnableStandaloneInstaller`, `plusEnableSmartRetries`, `plusEnableUpdateOwnership`, `plusEnableUserPreapproval`, import installed apps

**4 · Advanced** (`jumpToPlusFeatures` still points at index 4)
- `plusShowAdvancedSettings` is the first row. Its summary is "N hidden settings" when off.
- *Obtainium+:* `PlusFeaturesSection`. The `'Obtainium+ & Interface'` label is localised. The copy at the top of search results (`settings.dart:487`) stays as a link only.
- *Backup:* import/export, `autoExportOnChanges`, `backupEncryptionEnabled`
- *Accounts:* a GitHub & GitLab tokens subpage, replacing the OAuth ExpansionTile
- *Warnings & tips:* `hideTrackOnlyWarning`, `hideAPKOriginWarning`, contextual tips
- *Troubleshooting:*
  - App info, overlay, logs, statistics, changelog, `plusShowChangelogAfterUpdate`
  - Clear APK and icon caches, `enableDeepLogging`, `highlightTouchTargets`
- *Developer:* unlock row and the Developer & Diagnostics link. `plusDevUseThirdPartyLoadingIndicator` moves there.
- *Reset:* factory reset, in its own group with an error-coloured label

**Removed from the UI** (provider fields stay, so imports keep working):
- `plusSettingsLayoutMode`: its buttons go. The key is reserved for the optional launcher phase.
- `plusShowLegacyUIComparison`, `plusEnableExperimentalCustomization`
- The footer changelog link

## Components and tokens

New `lib/theme/settings_tokens.dart` with `SettingsTokens`, built on the existing `AppSpacings` scale.

**Page and group:**

| Token | Value |
|---|---|
| Page gutter | 16 |
| Group label | `labelLarge`, `primary`, w500, padding `fromLTRB(20,12,20,6)`, `Semantics(header:true)`, never uppercase |
| Gap between groups | 16; the ad-hoc `SizedBox(12)` gaps in Updates and Install go |
| Segmented row gap | 2 (`space25`) |
| Outer radius | `plusSettingsGroupRadius` 12 / 16 / 24 (segmented default 12) |
| Inner radius | 4, capped at the outer radius |
| Pressed row | inner corners go to the outer value |
| Row colour | `surfaceContainer` on a `surface` page; `surfaceContainerHigh` with `useBlackTheme` |
| Row height | 56 / 72 / 88 dp (one / two / three lines); top-aligned at 88; compact −8 |
| Row padding | `fromLTRB(16,10,16,10)`, 12 between slots, trailing slot 52 wide |
| Leading icon | 24 plain, `onSurfaceVariant`; `buildSettingsIconBadge` stays only in card style |
| Title | `bodyLarge` `onSurface`, w400 (no bold, as in ShizukuPlus 539e6d41) |
| Summary | `bodyMedium` `onSurfaceVariant`, showing the **current value**; the description moves to a long-press help sheet |
| Disabled child row | indented 16, opacity 0.38, stays in the layout |

**`SettingsSection`** (new, `lib/components/settings/settings_section.dart`):
- `style` is either `card` (wraps today's `ExpressiveSettingsGroup`, the default) or `segmented`.
- A shared `_visibleChildren()` drops `SizedBox`, `Visibility` and empty groups **before** first/last positions are computed, so a hidden last row never leaves a square bottom corner.
- `positionalTileRadius({isFirst, isLast, outer = 24, inner = 6})` gets optional parameters, so existing call sites are unchanged.

**`SettingsRow`** (`settings_row.dart`):
- Slots for leading, title, summary and trailing.
- The whole row is the tap target.
- `context.select` per field.
- `buildFeatureToggle` delegates to it, and the ~30 inline `SwitchListTile.adaptive` rows are migrated.
- `ToggleTile` wraps it, so the `settings_m3e_surfaces_test` expectations still hold.
- Press morph: `TweenAnimationBuilder<ShapeBorder?>`, resolving a null shape first, driven by `SpringCurve(M3Springs.spatialFast)` with scale 0.985. The duration is zero when `!AppMotion.enabled`.

**`SpringExpandable`** (`spring_expandable.dart`), used only in More pages and Plus groups:
- Height runs on `spatialDefault` with `SizeTransition` clamped to [0,1].
- The chevron sits in a `surfaceContainer` circle and rotates 180° on `spatialFast` (overshoot allowed).
- The collapsed header shows an "X / Y on" pill (`secondaryContainer`, full radius) when the count is above 0.
- Expanded state is stored under `PageStorageKey<String>('settings.<section>.<group>')`.

**`ConnectedChoiceGroup`** (`connected_choice_group.dart`), for 2–4 options:
- 40 dp tall, outer corners full, inner 8, pressed 4.
- The selected segment goes to 50% radius, and its neighbours stay still.
- Built on `SegmentedButton` theming. Five or more options open a radio sheet. Dropdown-styled `ListTile`s are removed.

**Sliders** (update `settings_slider_tile.dart` to upstream's header pattern):
- Label on the left (`bodyLarge`), value on the right (`onSurfaceVariant`), 12 dp gap, slider underneath, padding `16,8,16,8`.
- Detents are announced via `Semantics(value:)`.

**`MorphSwitch`** (`lib/components/common/morph_switch.dart`), selected by `plusSwitchStyle`:
1. **Classic** (default): the SDK `Switch` with the existing `thumbIcon` at `theme_builder.dart:583`. `find.byType(Switch)` tests stay green.
2. **Expressive:**
   - Track 52×32, 2 dp outline when off.
   - Thumb 16 off / 24 on / 28 pressed.
   - Position: `animateWith(SpringSimulation(M3Springs.spatialDefault, …, dragVelocity))`.
   - Size: `spatialFast`, giving the press-grow-and-settle effect.
   - Colours: `effectsFast`, no overshoot.
   - The check icon fades in after 60% of travel.
   - Colours follow the corpus table (selected: `primary` track, `onPrimary` thumb, `primary` icon; pressed thumb `primaryContainer`).
3. **Shape thumb:**
   - `static final Morph(MaterialShapes.circle.normalized(), MaterialShapes.cookie4Sided.normalized())`, with `CornerRounding(0.2)` for One UI.
   - Morph progress runs on `spatialFast`.
   - Painted by a `CustomPainter(repaint: Listenable.merge([pos, size, morph]))` inside its own `RepaintBoundary`, scaled using the `_processPath` approach from `loading_indicator_m3e`.
4. **Icon is the switch:**
   - The switch is hidden; a trailing "On" / "Off" label in `labelMedium` (`primary` / `onSurfaceVariant`).
   - The leading icon container fills 0→1 on `effectsFast`.
   - Row `Semantics(toggled:, enabled:, onTap:)`.

**Row options shared by all switch styles:**
- `plusIconMorphOnToggle`: circle → `plusIconMorphShape` (squircle, cookie, clover, sunny or soft burst) in `primaryContainer`.
- When off, the icon dims to alpha 0.6 and scale 0.9. Scale runs on `spatialFast` and alpha on `effectsFast`.

**Shared rules for all of them:**
- Drag uses a horizontal drag recogniser that only claims after slop.
- When `!AppMotion.enabled`, controllers are set to their end value with `value =` in one frame.
- `plusReduceShapeMorphs` keeps the position spring and skips the morph.
- Needs `material_new_shapes: 1.0.0` in `pubspec.yaml`. Do not import `m3e_design`.

## Haptics map

All haptics go through `AppHaptics`. A haptic fires only when the value actually changes, and once per gesture. Fix: `buildFeatureToggle` changes to `hapticOnPressDown: false`. New methods are `gestureStart`, `gestureEnd`, `gestureThreshold`, `success` (`successNotification`, medium below API 30) and `error` (`errorNotification`, heavy below API 30).

| Interaction | Subtle | Standard | Strong |
|---|---|---|---|
| Switch on / off | selection | `toggleOn` (medium) / `toggleOff` (light) | heavy / medium |
| Shape thumb starts morphing | — | — | `morphCue` |
| Connected group / radio change | selection | `segmentTick` | `segmentTick` |
| Slider touch / detent / min-max / release | — / — / medium / — | light / tick / medium / — | light / tick / medium / light |
| Group expand / collapse | — | `selectionClick` | `toggleOn` / `toggleOff` |
| Section chip, dock or nav change | — | `selectionClick` (none on re-tap scroll-to-top) | same |
| Subpage push | — | — | selection |
| Swipe preview passes / returns past threshold | medium / — | medium / light | heavy / light |
| Save or import success | medium | `success` | `success` |
| Error (bad token, failed import) | heavy | `error` | `error` |
| Reset, factory reset confirm | heavy | heavy | heavy |

The gate is `AppHaptics.enabled && (!plusHapticFollowSystem || systemTouchFeedback)`. The system check, and native `TOGGLE_ON`/`TOGGLE_OFF`/`SEGMENT_TICK` through `MethodChannel('obtainiumplus/haptics')`, are phase 4 only. Until then `plusHapticFollowSystem` is a no-op that defaults to on.

## Motion map

Everything goes through `AppMotion.enabled` / `enabledNow` (which covers both `plusEnableEnhancedAnimations` and the OS remove-animations setting), multiplied by `animationSpeedMultiplier`. `AppConstants.pressSpring`, `bounceSpring` and `gentleSpring`, and the ad-hoc spring at `swipe_preview_widget.dart:206`, are folded into `M3Springs`.

| Interaction | Spring / curve | About |
|---|---|---|
| Switch position and size | `spatialDefault` / `spatialFast` | 500 / 350 ms |
| Switch colour, On/Off label | `effectsFast` | 150 ms |
| Thumb or icon morph | `spatialFast` | 350 ms |
| Row press corner squeeze + 0.985 scale | in `effectsFast`, out `spatialFast` | 150 / 350 ms |
| Connected group selected corners | `spatialFast` | 350 ms |
| Group expand | `spatialDefault`, clamped; chevron `spatialFast`; content fades on `effectsDefault` | 500 ms |
| Child rows enabling / disabling | opacity 0.38 ↔ 1, `effectsDefault` | 200 ms |
| Section switch | existing fade, 0.04 slide and 0.985 scale, durations from `SpringCurve(spatialDefault)` | ~300 ms |
| Subpage / More push | `SharedAxisTransition` X, honours `reversePageTransitions` | 360 / 280 ms |
| Back gesture | settings routes rebuilt on `MaterialPageRoute` with `PredictiveBackPageTransitionsBuilder` for gesture pops and shared axis for button pops | system |
| Search bar radius 28 → 18 | `spatialFast` (replaces the fixed 280 ms) | 350 ms |
| Search jumps to a row | `ensureVisible` on `spatialSlow`, then a `secondaryContainer` highlight pulse on `effectsSlow` | 650 / 600 ms |
| Dock hide | slide `spatialDefault`, opacity `effectsFast` | |

**Gate fixes:**
- `pushRoute` (`app_utils.dart:17`) also checks `AppMotion.enabledNow`.
- Ungated durations at:
  - `settings_layout_selector.dart:152`
  - the 280 ms theme ExpansionTile
  - `advanced_settings_section.dart:651`
  - `apps_view_settings_section.dart:628`
  - `settings_subpage.dart:93`
  - `update_settings_section.dart:1215`
  - `installation_section.dart:609`
  - `troubleshooting_section.dart:156`
  - `home.dart:385,539`
  - `expressive_settings_group.dart:48-52`
- Blur stays off segmented rows unless both glass and motion are on, and then only through `ConditionalBlur`.

## Phased build plan

**Phase 1: hygiene, no visual change**
- Files:
  - The gate sites listed above, and `app_utils.dart`
  - `settings_feature_toggle.dart`: `hapticOnPressDown: false`, and `watch` → `select` at lines 18 and 81
  - `expressive_settings_group.dart`: use `AppMotion` and `select`
- Localise hardcoded strings: `appearance_hub.dart:48-67`, `advanced_settings_section.dart:243-257,612,627`, `theme_settings_section.dart:267-269`, `troubleshooting_section.dart:147`, `swipe_preview_widget.dart:27-62,271,276`, `apps_view_settings_section.dart:1170-1190`, `expressive_settings_group.dart:371`, `settings_hero_overview.dart:150`. Add the keys to all 35 locale files.
- Search: `_matches` also checks `tr(description)`, and the English-only needles become `tr()` keys.
- Tests:
  - `motion_gate_test`: with animations off, one pump leaves no pending timers.
  - `haptics_test`: mock `SystemChannels.platform`; a switch tap produces exactly one vibrate call.
  - `settings_page_test`: search in a non-English locale.
- Done when: `flutter test` is green, `analyze-live.sh` is clean, and the device looks identical.

**Phase 2: information architecture (one PR)**
- Move rows between `theme_settings_section`, `apps_view_settings_section` (drop the outer `appsString` group at `:574`), `app_behavior_section`, `notification_settings_section` (its body is embedded in Updates), `update_settings_section`, `installation_section`, `advanced_settings_section`, `troubleshooting_section`, `developer_settings` and `plus_features_sheet` (it becomes links).
- New section labels go into `_chipKeys`, the dock, the nav destinations, `SettingsCategoryBarHost` and `_connectedItemsForSection`. The count stays at 5.
- "More…" pages via `SettingsSubpage`.
- `SettingsLayoutSelector` becomes the Settings page subpage.
- Master / child rows via `ConnectedSettingContainer` (swipe, FAB, downloads, notifications, motion, haptics).
- New en.json keys in all locales.
- Tests:
  - Update `settings_page_test` (0..8 at 360 dp and 1.3× text, tooltip, hub → `BackButton`, expansion persistence), plus `connected_settings_test`, `view_settings_test` and `plus_settings_test`.
  - **New** `settings_tree_test`: every rendered provider key appears exactly once when browsing, and is findable in search.
- Done when: no duplicates, search finds every moved row, and each tab fits 360 dp.

**Phase 3: expressive kit (opt-in, defaults unchanged)**
- New files: `settings_tokens.dart`, `settings_section.dart`, `settings_row.dart`, `spring_expandable.dart`, `connected_choice_group.dart`, `morph_switch.dart`, `motion_controls_card.dart`.
- Change `positionalTileRadius` to take optional parameters.
- Add `material_new_shapes` to `pubspec.yaml`.
- New keys `plusSettingsGroupStyle`, `plusSettingsGroupRadius`, `plusSwitchStyle`, `plusIconMorphOnToggle`, `plusIconMorphShape`, `plusIconMorphStyle`, `plusReduceShapeMorphs`, `plusHapticIntensity` and `plusHapticFollowSystem`. Each gets a `safe_prefs` getter and an import type-flip test.
- Tests:
  - `morph_switch_test`: semantics toggled / enabled, tap and drag, one-frame settle with animations off, a static `Morph` (none built in `build`), every style.
  - `settings_section_test`: radii after hidden rows are filtered, empty group dropped.
  - `spring_expandable_test`: state survives scroll plus a tab switch.
  - `pumpAndSettle` never hangs.
- Done when: on the One UI 9 device every style looks right, there is no jank while scrolling Look & motion, and switching back to the defaults restores today's look.

**Phase 4: optional**
- Settings route builder with predictive back. First check on the device whether targetSdk 36 needs `enableOnBackInvokedCallback`.
- Search jump with highlight.
- Native haptics channel and system-follow.
- Launcher top level behind `plusSettingsLayoutMode = 'launcher'`.

## Open questions for the user

1. For segmented groups, should the outer corners be 12 dp (One UI tight), 16 dp (M3 spec) or 24 dp (today's look)?
2. Should segmented groups become the **default** once they're done, or stay opt-in next to the current cards?
3. Which switch style do you want to see first on your phone: Expressive (spring and grow), Shape thumb (morphs to a cookie shape), or Icon is the switch?
4. Is "Home & library" in the old Notifications tab slot fine, with notifications moving next to update checks?
5. Should the native Android haptics (true TOGGLE_ON/OFF ticks) be built, or are Flutter's light/medium/selection haptics enough?

## Alternatives

**B, expressive-first:**
- Keeps today's tabs, including the Notifications and Behavior tabs. It adds a "Motion, shape & haptics" page with a live preview card as the hero moment, and moves less around.
- The richest switch set (Classic / Expressive with a cookie morph / Icon is the switch) and a low-end "reduce morphs" option. Most of its controls work is already grafted into the plan above.
- Downsides: merges `parallelDownloads` into a slider (a behaviour change plus a migration), leaves Behavior as a leftover tab, and adds a second hub to tab 1.

**C, ShizukuPlus parity:**
- Settings opens on a short launcher of about 11 rows with live summaries ("Every 6 h · Wi-Fi only"), exactly like ShizukuPlus's `settings_main.xml`. It sits behind the dead `plusSettingsLayoutMode` key, and the tabs stay as the alternative.
- Each topic is its own subpage with open groups, so pages are short and focused. It has the most ShizukuPlus-like haptics, including following the system setting.
- Downsides: two layout paths to test, existing tab tests don't cover the launcher, more taps to reach a setting, and hiding `plusEnableSwipeActions` would break swiping for anyone with that key off.
