# Changelog

All notable changes to Obtainium+ are documented in this file.

## [Unreleased]

### ⚡ Update Checks
- **Faster, Lighter Checks for Large App Lists**: Checks are now spread across sources, so a long run of GitHub apps no longer holds up apps from other sites, and no single site gets more than 3 update checks at once. Results are saved in batches instead of once per app, and APKMirror data is fetched once per check.
- **Fewer Wasted GitHub Requests**: Once GitHub's API rate limit is reached, the remaining GitHub apps go straight to the releases feed until the limit resets, instead of each one failing against the API first.
- **Excluded Categories & Disabled Apps Are Skipped**: Batch update checks now skip apps in categories you excluded from checks, and apps with checking disabled. Before this fix, both were still checked.
- **Failing Apps Back Off**: An app whose check fails, or that hits a rate limit, waits one full update interval before it's checked again, instead of being retried on every background run. Connection drops don't count, so those apps are retried as usual. Repeated failures now count toward Update Health's failed-checks warning, which previously never triggered.
- **Smoother Update Progress**: The update-check bar and counter glide between steps instead of jumping, a live "N updates found" pill appears as updates turn up, and the progress strips on app tiles fade in and out. The bulk download bar also eases between steps.

### 🎨 Polish
- **App Font Everywhere**: Buttons, chips, segmented buttons, dialogs, snackbars, tooltips, badges, input labels, the slider value bubble and the navigation bar now use the app's font (or your chosen system font). Before this fix, they used Android's default font, so they didn't match the rest of the app.
- **Matching Shapes in Dialogs**: The time pickers in the update schedule and quiet hours dialogs, and the GitHub token check result, now follow your corner-radius setting and Material 3 Expressive shapes.
- **Changelog Page Width**: On tablets and unfolded foldables, the changelog page now uses the same width as Settings.
- **Translatable Plus Features Sheet**: The Shizuku, binder benchmark, OEM guide and battery optimization rows in the Plus Features sheet can now be translated.
- **No More Cut-Off Theme Labels**: The theme picker's first option now reads "System" instead of a truncated "Follow …", and the design style switch shows "Obtainium+" and "M3 Expressive" on one line (long-press for the full name).
- **Translatable GitHub Token Check**: The Verify Token button and its result messages can now be translated.

---

## [v1.7.1-p2] - 2026-10-18

### ✨ Restored Features & Expressive UI
- **Expressive App List & Swipe Actions Are Back**: The main apps list uses the expressive app rows again, with the swipe-left/right actions from Behavior settings and drag-to-reorder for pinned apps. A new "Expressive app list" toggle in Apps view settings switches back to the classic compact list.
- **Native Google Play Source (opt-in)**: With a Play token set up (Aurora dispenser or personal account), you can switch a Play app to "Google Play (Native)" to fetch it straight from Google Play. Without a token, or if Play fails, it falls back to the regular mirror.
- **System Updates Page**: Turning on the System update scanner setting now adds a System updates page to navigation, which checks your installed apps for newer versions. Previously the setting did nothing.
- **True Material You Colours**: In Material You mode every colour, including card and surface tones, now comes straight from Android's own wallpaper palette, and the app picks up a wallpaper change when you return to it.
- **Launch From the Long-Press Menu**: The app long-press menu can open installed apps directly.
- **Undo App Removal**: Removing apps shows an Undo action for a few seconds that restores them to your list.
- **Sort & Filter Sheet**: The filter button on the apps list opens the full sort and filter sheet again: sort order, list/grid view, status chips, categories, tags and name/author/ID/source filters in one place.
- **Known-Issue Notices**: If the build you're running has a known serious problem, Obtainium+ tells you on launch and points you to the fix. Checked at most every 6 hours, and never blocks startup.
- **Guided Onboarding Is Back**: Fresh installs get the step-by-step onboarding again (permissions, installer setup, optionally tracking Obtainium+ itself) instead of a one-line welcome message. It was accidentally disconnected in May.
- **Respects Android "Remove animations"**: Press animations, the nav bar indicator, looping indicators and the loading indicator now honour the system accessibility setting in addition to the in-app animations toggle. Press haptics keep working with animations off.
- **Morphing Loading Indicator**: Loading screens and dialogs now show the Material 3 Expressive shape-morphing loading indicator. Small inline spinners and determinate progress keep the wavy ring.
- **Spring Motion**: Press feedback on buttons, tiles and cards is now driven by real spring physics (Material 3 Expressive spring tokens), so releases pop back with a natural overshoot. The floating nav bar indicator rides the same spring.
- **Material 3 Expressive Theme**: Sliders across the app now use the M3 Expressive design: a thick 16dp track, a slim bar handle with gaps either side, stop indicators, and a value bubble while dragging. Cards, dialogs, bottom sheets, list tiles, snackbars and the floating action button use smoother squircle corners in expressive mode. On Android TV, buttons, switches, checkboxes and menus show a strong focus highlight so the D-pad position is always visible.
- **Notification Quiet Hours Work**: During your quiet hours, notifications now arrive silently (no sound, vibration or pop-up) instead of the setting doing nothing.

### 🛡️ Stability, Security & Bug Fixes
- **Apps No Longer Deleted When Their Source Goes Missing**: An app whose source couldn't be matched (for example one set to Google Play (Native) while that source was unavailable) was permanently removed along with its downloaded APKs on launch. Such apps are now set aside and come back automatically once their source is available again.
- **Faster Update Checks on Large Lists (#330)**: Checking for updates no longer re-sorts the whole app list several times per app, F-Droid repositories are downloaded once per check instead of once per app, and a single stalled source can no longer hang the check (90-second per-app limit).
- **More Robust Background Updates & Installs**: Root installs time out instead of hanging when the root prompt is ignored (falling back to the normal installer), one failing app no longer aborts a background check, a stuck background check can't block all future ones, and notification errors can't interrupt an install.
- **Startup Crash Screen**: If the app fails to start, you now get a crash screen with the error, a report button and repair options (after repeated crashes) instead of a blank screen.
- **Crash Reports Reach the Developer**: Unhandled background errors were only logged on your device; they are now reported too, so crashes like the export NaN crash can actually be diagnosed.
- **Export, Share & Arithmetic NaN Guards (#240, #241)**: Every remaining path writing JSON (deep links, app share links, category settings, and APK URL migrations) now routes through `safeJsonEncode`. All numeric conversions (`formatSpeed`, `formatEta`, progress bar `.round()`, `.toInt()`, `.ceil()`) are guarded against IEEE-754 `NaN` and `Infinity` throwing `UnsupportedError`.
- **Scoped FileProvider Paths**: FileProvider access in `file_paths.xml` has been tightened to app-specific external files, cache, and standard Download and Documents folders, eliminating exposure of arbitrary shared storage paths.
- **Install Commit Lock Timeout**: Stock installer session commits and prompts time out after 90 seconds instead of blocking the entire batch installation queue for up to 5 minutes.
- **Fast System App Selector**: Loading installed apps and icons now batches UI updates and uses O(1) package indexing, eliminating O(N²) list re-renders.
- **Settings Gating & Display Fixes**: Category app count badges and tag filter chips now properly honour their visibility toggles (`displayShowAppCount`, `displayShowFilterChips`), and update schedules and auto-update rules are correctly gated by their Plus master toggles.
- **Backup Encryption Actually Encrypts**: The Backup encryption setting previously did nothing. Turning it on now asks for a password and encrypts manual and automatic exports with modern authenticated encryption; encrypted backups ask for the password when imported. Older encrypted backups can still be read.
- **Credentials Stay On Your Device**: API tokens and store credentials are excluded from Android cloud backup, and the Codeberg/Forgejo token is moved into secure storage like the GitHub and GitLab tokens.
- **Safer App Links**: Importing apps from an obtainium:// link shows each app's name and URL first and ignores any settings in the link that would weaken security (insecure connections, certificate pinning, signer allow-lists).
- **Safer Plugin Installs**: Plugins can only be installed from https:// links and are size-limited.

---

## [v1.7.1-p1] - 2026-10-18

### 🎨 Material 3 Expressive & Vivid Theming
- **Vivid Primary Color System**: Navigation bar selected indicator, chip/filter selected states, update version badges, app list/grid update tile tints, segmented filter indicator, sideloading notice, "Update Available" badge on the app detail page, system updates avatars, the app icon shimmer pulse, tag editor header, onboarding token notice, MicroG hub info card, plugin icon badges, device optimization step bullets, version range subtitle text in System Updates, and the active operations banner (tinted border + background) all now use `primaryContainer` / `primary` instead of `secondaryContainer` / `secondary`. Active states and call-to-attention surfaces reflect the full seed color throughout the app. App bar titles switch to semi-bold weight (w600) for more presence.
- **Expressive Spring Press**: All touch targets now bounce past 1.0 on release with a genuine spring overshoot (Cubic(0.34, 1.56, 0.64, 1.0)) instead of a plain decelerate curve. The spring-back plays with a slightly longer ease-out duration so it feels physical rather than mechanical.
- **Richer Haptics**: Install/update success now fires two distinct pulses (light → 80ms → medium) with a proper async gap so both beats are felt. Toggle switches fire directional haptics (medium for on, light for off). Multi-beat haptics (warning, double-impact) similarly gapped at 60ms. Turning on/off a feature feels distinct.
- **Settings Expansion Curves**: Group expand/collapse now uses Material emphasized-decelerate (open) and emphasized-accelerate (close), matching the motion used across the rest of the app. The icon turn animation uses the same curves.
- **Grid Toggle Gradients**: Active grid toggle tiles use a diagonal gradient (primaryContainer → primary tint) and inactive tiles use a matching two-stop gradient so Flutter's AnimatedContainer can lerp smoothly between states instead of crossfading through a dim midpoint.
- **Glass Sheen Consistency**: App tile glass sheen and top specular highlight now branch on brightness — the sheen is subtler in dark mode (8–18% white) and stronger in light mode (12–50% white), matching the list tile implementation.
- **Dialog Header Gradient**: Glass dialog headers now use a primary-tinted diagonal gradient (primary tint top-left → surface bottom-right) instead of a plain surface fade, giving each dialog a subtle brand identity.
- **Expressive Statistics Cards**: Each metric card now carries a diagonal gradient tinted by its own icon color (primary, secondary, tertiary, error) with a color-matched border, giving each stat its own visual identity. Activity chart container also gains a primary tint gradient and stronger border.
- **Richer Activity Chart**: Chart fill gradient deepens from 30% to 42% opacity, making the 30-day activity sparkline noticeably more vivid.
- **App Detail Action Cards**: Action shortcut tiles (Share, Backup, etc.) in the app detail page now use a diagonal gradient background with a color-matched border instead of a flat tinted surface.
- **Expanded Palette Presets**: Five new expressive seed colors added — Coral, Cosmic, Sakura, Aurora, and Solar — covering the vivid end of the spectrum (electric reds, deep purples, hot pinks, bright teal, and saturated orange) that the existing presets didn't reach. All work across light, dark, and AMOLED modes.
- **Richer Empty State**: Empty state icon containers now use a three-stop diagonal gradient (primaryContainer → secondaryContainer → tertiaryContainer) with higher alpha values, and a stronger primary border ring, so empty screens feel designed rather than blank.
- **Active Toggle Tiles More Vivid**: Grid toggle tile active gradient deepens from 58% to 72% primary container alpha, making enabled settings stand out more clearly from disabled ones.
- **Dialog Actions Footer Tint**: Glass dialog action footers now use a diagonal gradient toward primaryContainer instead of a flat surface tone, tying the confirm/cancel area back to the page's theme color.
- **Floating Nav Bar**: The floating pill nav bar now has layered shadows (ambient + key + primary tint glow) outside the clip, an inner top-edge primary tint gradient, and a primary-tinted border in glass mode. In Plus mode the indicator uses a custom stretchy-pill animation: the leading edge of each tab switch travels first and the lagging edge follows after a short delay, creating a natural stretch-and-snap feel. Each tab icon bounces with a spring overshoot on selection. Tab-switch speed adapts to the enhanced-animations setting. All toggle switches app-wide now show a check icon when on and an × icon when off for instant at-a-glance state reading (M3 expressive style).
- **Instant Press Haptics**: Every interactive surface now fires a subtle haptic on first contact (pointer-down), so the press feels instantaneous rather than waiting for the tap to complete. Covers all dialogs, app list/grid tiles, dashboard icons, settings toggle tiles, discover/add-app search results, onboarding and empty-state cards, tag filter chips, segmented filter tabs, troubleshooting and notification setting tiles, system app selector tiles, the system-updates FAB, all toolbar and bottom-bar icon buttons, logs toolbar, contextual tip close, settings group help/reset buttons, deep-link error dialogs, and every form button throughout the app. Haptic is suppressed when the button is disabled.
- **Asymmetric Grid Press Animation**: Grid tile press now compresses fast (80ms ease-in) and springs back slowly (320ms expressive spring) with overshoot above 1.0, giving tiles a physical pop-back feel.
- **Double-Tap Bug Fixes**: Audited every `ScaleTouchWrapper` in the codebase. Removed ghost actions where both `ScaleTouchWrapper.onTap` and the inner button's `onPressed` were both firing the same action on every tap. Affected surfaces: toolbar and bottom-bar icon buttons, all mass-action and selection buttons, omnibar action list tiles, tag filter bar chips, segmented filter segment tabs, tag editor add button, plus_features_sheet benchmark button, installation-mode radio rows, and system-app-selector import FABs.

### 🎛️ Settings Overhaul & Controls
- **Settings Density Modes**: Compact and comfortable layout modes now produce structurally distinct results. Comfortable mode: grid toggle tiles show a description subtitle, taller touch targets, and more breathing room between card groups. Compact mode: 3-column grid, tighter padding, and dense list tiles. Section header labels switch from ALL-CAPS to sentence-case across all settings components.
- **Unified Installer Picker**: The separate Shizuku and Root toggles in Installation settings have been replaced by a single radio selector showing System, Shizuku, and Root options, each with a one-line description and a live "Available / Unavailable" chip for Shizuku. Shizuku sub-options (Pretend to be Google Play, Fallback to System, Binder test) appear inline when Shizuku is selected.
- **Setting Descriptions**: Per-app settings switches and text fields now show a permanent one-line description below the label, so you no longer have to long-press to find out what a setting does. Covered settings include: Auto-filter by architecture, Version detection, APK filter inversion, Fallback to older releases, Refresh before download, Allow insecure connections, Exempt from background updates, Skip update notifications, Stay one version behind, and Shizuku pretend to be Google Play (per-app).
- **Guided Settings Navigation**: Each settings tab now opens with a compact banner showing the tab's icon and a one-line description of what you'll find there, making it easier to orient quickly. A subtle divider connector between Updates & Installation and between Advanced & Troubleshooting groups visually links related sections. All major settings groups (Updates, Installation, Notifications, Behavior, Advanced, Troubleshooting, Swipe Gestures, Animations, Safety & Rate Limits) now show a brief description beneath their header. The Wi-Fi-only and charging-only background update toggles also gained their missing descriptions.
- **Expressive Slider Controls**: A new animated slider tile replaces the old plain Slider + separate label pattern throughout settings. The value badge morphs from pill to squircle while dragging and turns primary-colored, giving clear visual feedback. Fires subtle haptics on each notch and a light impact on release. Applied to: background update interval, corner radius (global, home, settings), animation speed (now a continuous 25%–200% slider instead of a 5-step dropdown), update-check and download concurrency, grid columns, and category icon count.
- **Animated Corner Radius Preview**: The shape preview in Appearance settings now updates live as you drag — the icon tile, card, and chip all animate their corners simultaneously with an eased spring, so you can see the radius changes in realistic context.
- **Swipe Action Chip Grid**: The swipe gesture action selectors (left/right) are now a 3×2 chip grid showing each action's icon and label. The active chip fills with the primary container color and its border highlights. Chips animate with spring-press feedback.
- **Segmented Selectors**: Grid category display (Sections/Flat) and category icon position (Disabled/Leading/Trailing/Below) now use segmented buttons instead of dropdowns, making all options immediately visible without opening a menu.
- **Ban Warning Threshold Slider**: The ban/rate-limit warning threshold in Safety & Rate Limits now uses the shared animated SettingsSliderTile: the value badge morphs and pops while dragging, and each notch fires a haptic tick. Previously it was a plain Slider row with no visual feedback.
- **Preferred Update Source Chip Grid**: The preferred update source selector in Updates settings is now a 3+2 chip grid (Direct, Play Store, Aurora, GitHub, APKPure) matching the swipe gesture chip grid style — each source shows its icon and label, the selected source fills with the primary container color.
- **Time Picker Sliders**: The start/end hour pickers in the update schedule dialog and the notification quiet hours dialog are now compact sliders (0–23 h) inside full-width styled labeled boxes, each showing the current hour as a bold value label above the track. Previously they were scroll-wheel dropdown menus.
- **M3 Button Polish**: The remaining M2-style `ElevatedButton` instances (add-app search, Xiaomi troubleshoot actions, form sub-list add button) are now `FilledButton` / `FilledButton.tonal`. Day-of-week chips in the update schedule dialog fire haptics on toggle, as do per-app setting switches and the update-schedule switch. The log-viewer filter uses the M3 `DropdownMenu`.
- **Crash Opening Settings in Non-English Languages**: Opening settings crashed with "Null check operator used on a null value" for anyone not using English, because the colour-picker text field could not find its translations (#336, #337).
- **Floating Nav Bar in Right-to-Left Languages**: The nav bar indicator now highlights the correct tab in Persian and Arabic.
- **Settings Scroll Crash (recurring)**: Re-pinned explicit `PageStorageKey` strings on the settings page `CustomScrollView` and horizontal tabs `ListView`. Without these, Flutter assigns positional PageStorage slots that collide with `ExpansionTile`'s bool entries, causing a `type 'bool' is not a subtype of 'double?'` crash on scroll restoration (issues #303 #304 #256).
- **Interval Slider NaN Guard**: The update interval slider value getter now returns the default (6) if the stored value is NaN, Infinity, or negative.
- **403 Download Errors**: Apps that returned HTTP 403 on download now fail immediately with a clear error message instead of silently retrying three times (15-second waste per app).
- **Startup Performance (Large Collections)**: Replaced unbounded parallel icon fetching with a 4-at-a-time concurrency limit, so loading a large collection no longer fires hundreds of simultaneous requests that saturate the UI thread.
- **APKPure API Headers**: APKPure API requests now include the mobile client User-Agent (`APKPure/3.19.39 (Aegon)`) matching the expected client fingerprint for `tapi.pureapk.com`.

---

## [v1.6.17-p11] - 2026-10-08

### ⚡ Batch Updates, Download Cache & Installer Safety
- **Looping Animations Follow Motion Settings**: The Shizuku status card pulse, app tile skeleton shimmer and the wavy progress indicators now start and stop whenever enhanced animations are toggled, and also hold still when Android's "Remove animations" accessibility setting is on.
- **Install Conflicts Explained Before They Fail**: Updates are now checked against the installed app's signing key before installing. If the new APK is signed by an unrelated key, you get a clear message instead of Android's generic "package conflicts with an existing package" error. The per-app allowed-signer list and the "verify signing certificate" setting are enforced again.
- **Same APK Variant Across Updates**: The app now remembers which release asset you use by name instead of list position, so a reordered or resized release asset list can no longer switch an app to a differently signed build.
- **Clearer Install Errors**: Conflict, invalid-APK, storage and incompatible-device failures from Shizuku, root and external installers are reported directly instead of being silently retried in the system installer. Root installs now report the real failure reason.
- **Installed Apps No Longer Cleared After a Slow Package Query**: If Android's package list timed out or failed, tracked apps could lose their installed state (and be removed when "remove on external uninstall" was on). The query result is now sanity-checked first.
- **One Corrupt App File No Longer Hides Everything**: A single app file with an unexpected field is skipped and logged instead of aborting the whole load.
- **Tags Kept When Refreshing Apps**: Checking for updates no longer resets an app's tags.
- **Home Screen Update Progress Unified**: Update-check progress is shown once in the operations banner (plus each app's own spinner) instead of in several places. When many apps update together the banner shows a single summary with an overall bar, an installed counter and a Cancel all button, with the first two apps listed in detail.
- **Pinned Apps and Recent Updates Are Tappable Again**: Tapping a pinned app or a recent update opens its page (or toggles selection in selection mode); long-press selects. The same fix restores taps on other tiles that rely on the shared touch wrapper.
- **Recent Updates Strip**: Lists only apps still waiting to update and its count opens the Updates filter.
- **Backup and Restore**: Source credentials are included in credential exports and restored to secure storage; imported settings take effect immediately; old automatic backups are removed only after the new one is written; the export folder is kept if it is briefly unreadable.
- **Downloads**: Cached APKs are reused only when their size is confirmed by the server and now include the release version; safer filename parsing from server headers; a stuck connection no longer hangs; a failed write no longer leaves a download marked as active.
- **Background Updates**: Background checks can no longer run twice at once, always report completion to the OS, and release their resources.
- **Smaller Fixes**: F-Droid repository URLs ending in index files no longer crash; GitHub's own error message is shown for 401/403 responses; day-of-month and month names from itch.io, Uptodown and SourceHut parse correctly in any app language; microG token errors are shown instead of storing an empty token; assorted import, search and dialog crash guards.

---

## [v1.6.17-p10] - 2026-10-07

### 🐛 Animation Lifecycle Fix
- **Animation Controller Synchronization**: Fixed an issue where repeating `AnimationController` instances failed to resync correctly in `didChangeDependencies`, preventing visual glitches during theme switches.

---

## [v1.6.17-p9] - 2026-10-06

### 🔧 State Management, Persistence & Light Mode Contrast
- **Light Mode Card & Dialog Backgrounds**: Fixed all custom dialogs and bottom sheets that were using the plain page background (`surface`) instead of the proper elevated tones. Dialogs now use `surfaceContainerHigh`; bottom sheets and floating bars use `surfaceContainerLow`.
- **Settings Changes Now Apply Immediately**: Plus settings (glassmorphism, corner radius, expressive progress, contextual tips, etc.) now update live as soon as you change them.
- **Welcome Dialog Safety**: Added `context.mounted` guard around the first-run welcome dialog to prevent a use-after-disposal crash.
- **Export / Share Crash (NaN)**: Prevented JSON encoding failure when app metadata contained `NaN` or `Infinity` values, which could crash the share/export flow.
- **Version History Crash**: Added `PageStorageKey` to the version history expansion tile to prevent a `bool`/`double` type mismatch crash when scrolling back to a previously-visited app.
- **Update Check Unresponsiveness**: Yielded to the UI thread between each update check to prevent the app from becoming unresponsive during large background scans.
- **Aurora / Play Store Auth Lost on Restart**: Ensured `AuthProvider`, `SourceConfigProvider`, and `PluginProvider` are properly initialized with `SharedPreferences` before app launch so plugin configs persist across restarts.
- **Installed Plugins Cleared on Restart**: Hardened plugin loading against corrupted entries so a single bad record no longer blocks all others.
- **MicroG Hub Stuck After Partial Add**: Deployment progress UI resets correctly when no new downloads are needed.
- **Settings Changes Now Apply Immediately (More Fixes)**: Replaced `context.read` with `context.watch` across command center, tag editor, and plugin manager.
- **App Detail Update Crash**: Added `mounted` guards in `getUpdate` on the app detail page.
- **Notification Cancel After Dispose**: Guarded `context.read<NotificationsProvider>()` in async `.then()` callbacks.
- **Discover Corner Radius Not Live**: Ensured corner-radius changes update discover result cards live.
- **Category Sections Selection Highlighted**: Added local selection state tracking to `CategorySections` so multi-select visually highlights rows.
- **Dispenser Manager Controller Leak**: Properly disposed `TextEditingController` in `_DispenserManagerSheetState`.
- **Import/Export setState After Dismiss**: Added `mounted` guards before starting imports across file import, source search import, and mass-source import.

---

## [v1.6.17-p8] - 2026-10-06

### 🐛 Bug Fixes & Visual Polish
- **Settings Card Contrast**: Improved contrast of settings groups and cards in light mode so they stand out clearly against the page surface.
- **Neutral Update Shadows**: Replaced colored glow halos on pending-update app tiles with subtle, neutral depth shadows.
- **Startup Notification De-duplication**: Fixed startup race condition causing both the What's New sheet and a secondary dialog to appear simultaneously.
- **Changelog Loading Spinner**: Constrained the changelog loading indicator to a balanced size rather than expanding across the modal.
- **Background Check Responsiveness**: Update checks yield briefly between app queries so the UI remains fluid even with large app catalogs.

## [v1.6.10-r1] - Official Release (2026-09-24)

### 📱 Samsung OneUI Reachability Header
- **Collapsible Fluid Header**: Engineered for large screens; expands smoothly on pull-down to bring top interactive content down to natural thumb reach.
- **Dynamic Title Shift**: Fluid interpolation transitioning the title from top-left pinned toolbar mode to prominent centered viewing mode.
- **Live Contextual Status**: Shows real-time app counts and pending update counts (`"18 apps · 3 updates"`) that gracefully fade in with header expansion.
- **Dedicated Reachability Toggle**: Controlled via `plusEnableOneHandedMode` and `plusHeaderContextSubtitle`.

### 🎨 Material 3 Expressive Theming & Palette Presets
- **Dynamic Scheme Variants**: Native Android 16/Material 3 Expressive scheme variants including Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome.
- **Spatial Transitions & Scale Physics**: Added spring curves and spatial scale transitions across modal sheets, dialogs, and navigation destinations.
- **Curated Palette Presets**: Handcrafted color presets designed specifically for high-contrast OLED dark themes and light themes.

### 🏝️ Modern Navigation Dock & Action Capsule
- **Floating Island Navigation Dock**: Optional pill-shaped frosted dock (`plusFloatingNavBar`) with rounded corners (`BorderRadius.circular(32)`), safe-area insets, and subtle ambient drop shadow.
- **Always-Show Destination Labels**: Toggle (`plusNavBarAlwaysShowLabels`) to keep destination labels consistently visible across tabs.
- **Floating Action Capsule**: Renders the install and update action bar on the App Detail screen as a hovering frosted pill capsule (`plusFloatingActionBar`).

### ✨ Granular App Tile Customization
- **Pinned Border Accents**: Customizable 1.5px highlighted accent border (`plusPinnedBorderAccent`) on pinned cards for instant visual identification.
- **Category Accent Ribbons**: Optional color-coded vertical indicator ribbon (`plusCategoryAccentRibbon`) matching assigned categories.
- **Expressive Version Update Pills**: Tonal badge button (`plusUpdateExpressiveBadge`) displaying target versions (e.g. `↓ 2.4.0`) with stadium borders.
- **Icon Rim Borders**: Subtle outline rim (`plusIconRimBorder`) preventing white/transparent icons from dissolving into card backgrounds.
- **Stadium Pill Filter Chips**: Fully rounded pill shapes (`plusExpressiveFilterChips`) on tag and category filter bars.
- **List & Grid Parity**: All card customization options work consistently across both List and Grid views.

### ⚡ Shizuku / ShizukuPlus Turbo Engine & OEM Tuning
- **Binder IPC Optimization**: High-throughput I/O buffering and fast adaptive binder polling for silent, unattended installs.
- **Automatic Package Installer Fallback**: Graceful fallback to the system package installer if Shizuku daemon is suspended or unreachable.
- **Device Compatibility & Performance Hub**: Interactive OEM tuning shortcuts for Samsung (OneUI), Xiaomi (HyperOS/MIUI), OnePlus (OxygenOS), Vivo (OriginOS), Huawei (HarmonyOS), Nothing OS, and Transsion devices.

### 🐛 Bug Fixes & Stability
- **Settings PageStorage Crash**: Resolved `type 'bool' is not a subtype of type 'double?'` type cast crash in Settings Apps section by replacing nested shrink-wrapped GridViews with composable Row/Column layouts.
- **PopScope Null Assertion**: Fixed potential null assertion crash on back-press in `home.dart` by safely guarding `_appsPageKey.currentState?.clearSelected()`.
- **Tab Switch Hang**: Prevented latent infinite spin loop in `switchToPage(0)` when already on the Apps tab.
- **Repository Moved Warning**: Restored repository rename warnings (`hasPendingRepoRename`) to modern AppListTile and AppGridTile.
- **GitHub Badge Dark Mode Contrast**: Fixed dark-on-dark invisible badge color for GitHub source links on dark theme surfaces.
- **Icon Cache Thrashing**: Eliminated aggressive `ignoreCache: true` in App Detail screen that previously triggered repeated I/O requests on every widget rebuild.
- **Tag Editor Controller Leak**: Ensured `TextEditingController` is properly disposed on dialog dismissal.
- **FAB Overlap in Multi-Select**: Automatically hide the omnibar FAB when batch multi-selection mode is active.
- **Changelog Dialog Isolation**: Added `barrierDismissible: false` to all update and welcome dialogs to prevent accidental tap-through dismissal.

---

## [v1.6.10-p40] and Earlier
- For earlier development patch history, refer to GitHub releases and commit logs.
