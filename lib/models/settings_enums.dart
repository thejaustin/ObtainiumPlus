enum SortColumnSettings {
  added,
  nameAuthor,
  authorName,
  releaseDate,
  lastUpdated,
  source,
  installDate,
  lastCheckDate,
  lastUsed,
}

enum SortOrderSettings { ascending, descending }

enum AppSortMethod {
  latestUpdates,
  nameAZ,
  nameZA,
  recentlyAdded,
  installStatus,
  defaultSort,
  lastUsed,
}

enum CategoryIconPosition { leading, trailing, below, disabled }

enum ViewMode { list, grid }

enum GridCategoryMode { sections, disabled, folders }

enum AppSwipeAction { none, update, togglePin, share, launch, delete }

enum AppListDensity { comfortable, compact }

enum AppBarStyle { compact, large }

enum InstallerMode { system, shizuku, external, root }

enum SettingsLayoutMode { m3eCompactGrid, classicGrouped }

enum ColourSchemeMode { standard, vibrant, expressive, materialYou }

enum AppDescriptionStyle {
  obtainiumPlus,
  githubReadme,
  playStore,
  liveWebpage,
  rawMarkdown,
}

// Visual Lab (developer options). Stored by index via safeEnum — append new
// members at the end only, or stored indexes shift.

/// Where the Settings category bar sits. [merged] shares one glass surface
/// with the main navigation bar (Settings as a home tab only; elsewhere it
/// falls back to [bottom]).
enum SettingsNavPlacement { bottom, top, merged }

enum SettingsAppBarActionsStyle { icons, labelledChips }

enum SettingsHeaderSize { large, compact }

enum NavBarBlurStrength { off, soft, strong }

enum PlusFeaturesEntry { sheet, jumpToSection }

// ── Expressive settings kit (opt-in previews). Stored by index, so only ever
// append members; the first member is the shipped look. ──

/// How settings groups are drawn: today's bordered card, or M3E segmented
/// rows (separate rows with 2 dp gaps and positional corners).
enum SettingsGroupStyle { card, segmented }

/// Which switch settings rows draw. [classic] is the SDK `Switch` (today).
enum SettingsSwitchStyle { classic, expressive, shapeThumb, iconSwitch }

/// Shape a toggle row's leading icon morphs into when switched on.
/// [squircle] maps to `MaterialShapes.square` (rounded square).
enum IconMorphShape { squircle, cookie, clover, sunny, softBurst }

/// How the leading icon animates into its "on" shape.
enum IconMorphStyle { morph, spin, pop }

/// Haptic strength. [standard] is exactly the shipped haptics.
enum HapticIntensity { standard, subtle, strong }
