enum SortColumnSettings {
  added,
  nameAuthor,
  authorName,
  releaseDate,
  lastUpdated,
  source,
  installDate,
  lastCheckDate,
}

enum SortOrderSettings { ascending, descending }

enum AppSortMethod {
  latestUpdates,
  nameAZ,
  nameZA,
  recentlyAdded,
  installStatus,
  defaultSort,
}

enum CategoryIconPosition { leading, trailing, below, disabled }

enum ViewMode { list, grid }

enum GridCategoryMode { sections, disabled, folders }

enum AppSwipeAction { none, update, togglePin, share, launch, delete }

enum AppListDensity { comfortable, compact }

enum AppBarStyle { compact, large }

enum InstallerMode { system, shizuku, external, root }
