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

/// Which privileged route a system operation (uninstall, battery exemption)
/// may use. [system] is the plain Android path; [auto] tries Shizuku, then
/// root, then falls back to [system]. Dhizuku is not offered: it only
/// delegates installs, it can't run these shell operations.
enum PrivilegedBackend { system, auto, shizuku, root }

/// Operations that can run through a privileged backend.
enum PrivilegedOp { uninstall, batteryWhitelist }

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

/// How strongly app cards pick up the accent colour. Stored by index, so only
/// ever append members.
enum AppCardTint { standard, tinted, vivid }

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

/// The four core looks of the app. A style is a preset: it picks the colour
/// recipe and applies default values to the granular Plus toggles (which stay
/// individually editable afterwards).
///
/// - [obtainium]: matches upstream Obtainium (stock purple seed, tonal spot,
///   upstream shapes, no Plus extras).
/// - [obtainiumPlus]: upstream layout with sharper highlights and a gold
///   tertiary accent for a premium feel. The default for new installs.
/// - [expressive]: Material 3 Expressive shapes and motion, plain accents.
/// - [expressivePlus]: Expressive blended with the Plus accents and effects.
enum AppThemeStyle { obtainium, obtainiumPlus, expressive, expressivePlus }

extension AppThemeStyleX on AppThemeStyle {
  bool get isPlus =>
      this == AppThemeStyle.obtainiumPlus ||
      this == AppThemeStyle.expressivePlus;

  bool get isExpressive =>
      this == AppThemeStyle.expressive || this == AppThemeStyle.expressivePlus;

  /// Corner radius preset. Plus-over-upstream is deliberately sharper.
  double get presetCornerRadius => switch (this) {
    AppThemeStyle.obtainium => 24,
    AppThemeStyle.obtainiumPlus => 16,
    AppThemeStyle.expressive => 28,
    AppThemeStyle.expressivePlus => 28,
  };

  bool get presetGlassmorphism => isPlus;

  bool get presetEnhancedAnimations => this != AppThemeStyle.obtainium;
}

/// How Settings is browsed (Visual Lab, experimental). [tabs] is the shipped
/// category dock; [list] shows one plain list of categories and opens each
/// on its own.
enum SettingsBrowseStyle { tabs, list }
