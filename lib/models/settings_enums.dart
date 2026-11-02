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
