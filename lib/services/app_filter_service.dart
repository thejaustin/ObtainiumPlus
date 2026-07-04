import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_update_service.dart';

class AppFilterService {
  AppFilterService._();

  static List<AppInMemory> getFilteredSortedApps({
    required Iterable<AppInMemory> apps,
    required AppsFilter filter,
    required AppSortMethod sortMethod,
    required SortColumnSettings sortColumn,
    required SortOrderSettings sortOrder,
    required bool pinUpdates,
    required bool groupByCategory,
    required bool buryNonInstalled,
    required List<String> existingUpdates,
    required List<String> pinnedOrder,
  }) {
    var listedApps = apps.where((app) {
      if (filter.statusFilter.isNotEmpty) {
        bool hasUpdate =
            app.app.installedVersion != null &&
            AppUpdateService.areVersionsDifferent(
              app.app,
              app.app.installedVersion,
              app.app.latestVersion,
            );
        bool notInstalled = app.app.installedVersion == null;

        bool matches = false;
        if (filter.statusFilter.contains('updates') && hasUpdate)
          matches = true;
        if (filter.statusFilter.contains('installed') && !notInstalled)
          matches = true;
        if (filter.statusFilter.contains('trackonly') &&
            app.app.additionalSettings['trackOnly'] == true)
          matches = true;
        if (filter.statusFilter.contains('uptodate') &&
            app.app.installedVersion != null &&
            !hasUpdate)
          matches = true;
        if (filter.statusFilter.contains('notinstalled') && notInstalled)
          matches = true;

        if (!matches) return false;
      }

      if (app.app.installedVersion == app.app.latestVersion &&
          !filter.includeUptodate)
        return false;
      if (app.app.installedVersion == null && !filter.includeNonInstalled)
        return false;

      if (filter.nameFilter.isNotEmpty || filter.authorFilter.isNotEmpty) {
        List<String> nameTokens = filter.nameFilter
            .split(' ')
            .where((e) => e.trim().isNotEmpty)
            .toList();
        List<String> authorTokens = filter.authorFilter
            .split(' ')
            .where((e) => e.trim().isNotEmpty)
            .toList();

        for (var t in nameTokens) {
          if (!app.name.toLowerCase().contains(t.toLowerCase())) return false;
        }
        for (var t in authorTokens) {
          if (!app.author.toLowerCase().contains(t.toLowerCase())) return false;
        }
      }
      if (filter.idFilter.isNotEmpty && !app.app.id.contains(filter.idFilter))
        return false;
      if (filter.categoryFilter.isNotEmpty &&
          filter.categoryFilter
              .intersection(app.app.categories.toSet())
              .isEmpty)
        return false;
      if (filter.tagFilter.isNotEmpty &&
          filter.tagFilter.intersection(app.app.tags.toSet()).isEmpty)
        return false; // Added tag filtering
      if (filter.sourceFilter.isNotEmpty &&
          SourceProvider()
                  .getSource(
                    app.app.url,
                    overrideSource: app.app.overrideSource,
                  )
                  .runtimeType
                  .toString() !=
              filter.sourceFilter)
        return false;

      return true;
    }).toList();

    // Sorting
    if (sortMethod == AppSortMethod.latestUpdates) {
      listedApps.sort((a, b) {
        final aDate = a.installedInfo?.lastUpdateTime != null
            ? DateTime.fromMillisecondsSinceEpoch(
                a.installedInfo!.lastUpdateTime!,
              )
            : null;
        final bDate = b.installedInfo?.lastUpdateTime != null
            ? DateTime.fromMillisecondsSinceEpoch(
                b.installedInfo!.lastUpdateTime!,
              )
            : null;
        if (aDate == null && bDate == null)
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    } else if (sortMethod == AppSortMethod.nameAZ) {
      listedApps.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (sortMethod == AppSortMethod.nameZA) {
      listedApps.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    } else if (sortMethod == AppSortMethod.recentlyAdded) {
      listedApps.sort(
        (a, b) => b.app.id.toLowerCase().compareTo(a.app.id.toLowerCase()),
      );
    } else if (sortMethod == AppSortMethod.installStatus) {
      listedApps.sort((a, b) {
        if ((a.installedInfo != null) == (b.installedInfo != null))
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return a.installedInfo != null ? -1 : 1;
      });
    } else if (sortMethod == AppSortMethod.defaultSort) {
      listedApps.sort((a, b) {
        dynamic aVal;
        dynamic bVal;
        switch (sortColumn) {
          case SortColumnSettings.added:
            aVal = a.app.id;
            bVal = b.app.id;
            break;
          case SortColumnSettings.nameAuthor:
            aVal = a.name;
            bVal = b.name;
            break;
          case SortColumnSettings.authorName:
            aVal = a.author;
            bVal = b.author;
            break;
          case SortColumnSettings.releaseDate:
            aVal = a.app.releaseDate;
            bVal = b.app.releaseDate;
            break;
          case SortColumnSettings.lastUpdated:
            aVal = a.app.lastUpdateCheck;
            bVal = b.app.lastUpdateCheck;
            break;
          case SortColumnSettings.source:
            aVal = a.app.url;
            bVal = b.app.url;
            break;
          case SortColumnSettings.installDate:
            aVal = a.installedInfo?.firstInstallTime;
            bVal = b.installedInfo?.firstInstallTime;
            break;
          case SortColumnSettings.lastCheckDate:
            aVal = a.app.lastUpdateCheck;
            bVal = b.app.lastUpdateCheck;
            break;
        }
        int res = 0;
        if (aVal == null && bVal == null)
          res = 0;
        else if (aVal == null)
          res = 1;
        else if (bVal == null)
          res = -1;
        else if (aVal is String)
          res = aVal.toLowerCase().compareTo(bVal.toString().toLowerCase());
        else if (aVal is DateTime)
          res = aVal.compareTo(bVal as DateTime);
        else if (aVal is num)
          res = aVal.compareTo(bVal as num);

        if (res == 0)
          res = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return sortOrder == SortOrderSettings.ascending ? res : -res;
      });
    }

    if (pinUpdates) {
      var temp = listedApps
          .where((sa) => existingUpdates.contains(sa.app.id))
          .toList();
      listedApps.removeWhere((sa) => existingUpdates.contains(sa.app.id));
      listedApps = [...temp, ...listedApps];
    }

    if (buryNonInstalled) {
      var temp = listedApps.where((a) => a.installedInfo == null).toList();
      listedApps.removeWhere((a) => a.installedInfo == null);
      listedApps = [...listedApps, ...temp];
    }

    var tempPinned = listedApps.where((a) => a.app.pinned).toList();
    if (pinnedOrder.isNotEmpty) {
      tempPinned.sort((a, b) {
        int indexA = pinnedOrder.indexOf(a.app.id);
        int indexB = pinnedOrder.indexOf(b.app.id);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    var tempNotPinned = listedApps.where((a) => !a.app.pinned).toList();
    listedApps = [...tempPinned, ...tempNotPinned];

    return listedApps;
  }
}
