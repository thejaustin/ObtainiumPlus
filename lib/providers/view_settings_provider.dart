import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';

class ViewSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    notifyListeners();
  }

  List<String> get bottomTabs {
    return prefs?.getStringList('bottomTabs') ?? ['apps', 'add', 'updates', 'settings'];
  }

  set bottomTabs(List<String> bottomTabs) {
    prefs?.setStringList('bottomTabs', bottomTabs);
    notifyListeners();
  }

  SortColumnSettings get sortColumn {
    return SortColumnSettings.values[prefs?.getInt('sortColumn') ??
        SortColumnSettings.nameAuthor.index];
  }

  set sortColumn(SortColumnSettings s) {
    prefs?.setInt('sortColumn', s.index);
    notifyListeners();
  }

  SortOrderSettings get sortOrder {
    return SortOrderSettings.values[prefs?.getInt('sortOrder') ??
        SortOrderSettings.ascending.index];
  }

  set sortOrder(SortOrderSettings s) {
    prefs?.setInt('sortOrder', s.index);
    notifyListeners();
  }

  bool get showAppWebpage {
    return prefs?.getBool('showAppWebpage') ?? false;
  }

  set showAppWebpage(bool show) {
    prefs?.setBool('showAppWebpage', show);
    notifyListeners();
  }

  bool get pinUpdates {
    return prefs?.getBool('pinUpdates') ?? true;
  }

  set pinUpdates(bool show) {
    prefs?.setBool('pinUpdates', show);
    notifyListeners();
  }

  bool get buryNonInstalled {
    return prefs?.getBool('buryNonInstalled') ?? false;
  }

  set buryNonInstalled(bool show) {
    prefs?.setBool('buryNonInstalled', show);
    notifyListeners();
  }

  bool get groupByCategory {
    return prefs?.getBool('groupByCategory') ?? false;
  }

  set groupByCategory(bool show) {
    prefs?.setBool('groupByCategory', show);
    notifyListeners();
  }

  bool get categoriesCollapsedByDefault {
    return prefs?.getBool('categoriesCollapsedByDefault') ?? false;
  }

  set categoriesCollapsedByDefault(bool collapsed) {
    prefs?.setBool('categoriesCollapsedByDefault', collapsed);
    notifyListeners();
  }

  Map<String, int> get categories {
    try {
      return Map<String, int>.from(jsonDecode(prefs?.getString('categories') ?? '{}'));
    } catch (e) {
      return {};
    }
  }

  void setCategories(Map<String, int> cats, {AppsProvider? appsProvider}) {
    if (appsProvider != null) {
      List<App> changedApps = appsProvider
          .getAppValues(deepCopy: false)
          .map((a) {
            var n1 = a.app.categories.length;
            a.app.categories.removeWhere((c) => !cats.keys.contains(c));
            return n1 > a.app.categories.length ? a.app : null;
          })
          .where((element) => element != null)
          .map((e) => e as App)
          .toList();
      if (changedApps.isNotEmpty) {
        appsProvider.saveApps(changedApps);
      }
    }
    prefs?.setString('categories', jsonEncode(cats));
    notifyListeners();
  }

  List<String> get categoryOrder {
    return prefs?.getStringList('categoryOrder') ?? [];
  }

  set categoryOrder(List<String> order) {
    prefs?.setStringList('categoryOrder', order);
    notifyListeners();
  }

  AppSortMethod get appSortMethod {
    int defaultIndex = AppSortMethod.defaultSort.index;
    int appCount = prefs?.getInt('trackedAppCount') ?? 0;
    if (appCount > 20) {
      defaultIndex = AppSortMethod.nameAZ.index;
    } else if (appCount > 0) {
      defaultIndex = AppSortMethod.latestUpdates.index;
    }
    return AppSortMethod.values[prefs?.getInt('appSortMethod') ?? defaultIndex];
  }

  set appSortMethod(AppSortMethod method) {
    prefs?.setInt('appSortMethod', method.index);
    notifyListeners();
  }

  ViewMode get globalViewMode => ViewMode.values[prefs?.getInt('globalViewMode') ?? ViewMode.list.index];
  set globalViewMode(ViewMode mode) {
    prefs?.setInt('globalViewMode', mode.index);
    notifyListeners();
  }

  int get gridColumnCount => prefs?.getInt('gridColumnCount') ?? 0;
  set gridColumnCount(int val) {
    prefs?.setInt('gridColumnCount', val);
    notifyListeners();
  }

  bool get displayShowAppCount => prefs?.getBool('displayShowAppCount') ?? true;
  set displayShowAppCount(bool val) {
    prefs?.setBool('displayShowAppCount', val);
    notifyListeners();
  }

  bool get displayShowFilterChips => prefs?.getBool('displayShowFilterChips') ?? true;
  set displayShowFilterChips(bool val) {
    prefs?.setBool('displayShowFilterChips', val);
    notifyListeners();
  }

  bool get displayShowAuthor => prefs?.getBool('displayShowAuthor') ?? false;
  set displayShowAuthor(bool val) {
    prefs?.setBool('displayShowAuthor', val);
    notifyListeners();
  }

  bool get displayShowVersion => prefs?.getBool('displayShowVersion') ?? true;
  set displayShowVersion(bool val) {
    prefs?.setBool('displayShowVersion', val);
    notifyListeners();
  }

  bool get displayShowDate => prefs?.getBool('displayShowDate') ?? false;
  set displayShowDate(bool val) {
    prefs?.setBool('displayShowDate', val);
    notifyListeners();
  }

  CategoryIconPosition get categoryIconPosition => CategoryIconPosition.values[prefs?.getInt('categoryIconPosition') ?? CategoryIconPosition.leading.index];
  set categoryIconPosition(CategoryIconPosition val) {
    prefs?.setInt('categoryIconPosition', val.index);
    notifyListeners();
  }

  int get categoryIconCount => prefs?.getInt('categoryIconCount') ?? 0;
  set categoryIconCount(int val) {
    prefs?.setInt('categoryIconCount', val);
    notifyListeners();
  }

  AppListDensity get appListDensity => AppListDensity.values[prefs?.getInt('appListDensity') ?? AppListDensity.comfortable.index];
  set appListDensity(AppListDensity val) {
    prefs?.setInt('appListDensity', val.index);
    notifyListeners();
  }

  GridCategoryMode get gridCategoryMode => GridCategoryMode.values[prefs?.getInt('gridCategoryMode') ?? GridCategoryMode.sections.index];
  set gridCategoryMode(GridCategoryMode val) {
    prefs?.setInt('gridCategoryMode', val.index);
    notifyListeners();
  }

  NavigationDestinationLabelBehavior get navigationLabelBehavior =>
      NavigationDestinationLabelBehavior.values[prefs?.getInt('navigationLabelBehavior') ?? 0];
  set navigationLabelBehavior(NavigationDestinationLabelBehavior val) {
    prefs?.setInt('navigationLabelBehavior', val.index);
    notifyListeners();
  }
}
