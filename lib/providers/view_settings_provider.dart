import 'package:obtainium/utils/safe_prefs.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';

class ViewSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    notifyListeners();
  }

  List<String> get bottomTabs {
    return prefs?.safeStringList('bottomTabs') ?? ['apps'];
  }

  set bottomTabs(List<String> bottomTabs) {
    prefs?.setStringList('bottomTabs', bottomTabs);
    notifyListeners();
  }

  SortColumnSettings get sortColumn {
    return prefs?.safeEnum('sortColumn', SortColumnSettings.values) ??
        SortColumnSettings.nameAuthor;
  }

  set sortColumn(SortColumnSettings s) {
    prefs?.setInt('sortColumn', s.index);
    notifyListeners();
  }

  SortOrderSettings get sortOrder {
    return prefs?.safeEnum('sortOrder', SortOrderSettings.values) ??
        SortOrderSettings.ascending;
  }

  set sortOrder(SortOrderSettings s) {
    prefs?.setInt('sortOrder', s.index);
    notifyListeners();
  }

  bool get showAppWebpage {
    return prefs?.safeBool('showAppWebpage') ?? false;
  }

  set showAppWebpage(bool show) {
    prefs?.setBool('showAppWebpage', show);
    notifyListeners();
  }

  bool get pinUpdates {
    return prefs?.safeBool('pinUpdates') ?? true;
  }

  set pinUpdates(bool show) {
    prefs?.setBool('pinUpdates', show);
    notifyListeners();
  }

  bool get buryNonInstalled {
    return prefs?.safeBool('buryNonInstalled') ?? false;
  }

  set buryNonInstalled(bool show) {
    prefs?.setBool('buryNonInstalled', show);
    notifyListeners();
  }

  bool get groupByCategory {
    return prefs?.safeBool('groupByCategory') ?? false;
  }

  set groupByCategory(bool show) {
    prefs?.setBool('groupByCategory', show);
    notifyListeners();
  }

  bool get categoriesCollapsedByDefault {
    return prefs?.safeBool('categoriesCollapsedByDefault') ?? false;
  }

  set categoriesCollapsedByDefault(bool collapsed) {
    prefs?.setBool('categoriesCollapsedByDefault', collapsed);
    notifyListeners();
  }

  Map<String, int> get categories {
    try {
      return Map<String, int>.from(
        jsonDecode(prefs?.safeString('categories') ?? '{}'),
      );
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
            // categories may be const/unmodifiable; copy before mutating
            a.app.categories = List<String>.from(a.app.categories)
              ..removeWhere((c) => !cats.keys.contains(c));
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
    return prefs?.safeStringList('categoryOrder') ?? [];
  }

  set categoryOrder(List<String> order) {
    prefs?.setStringList('categoryOrder', order);
    notifyListeners();
  }

  AppSortMethod get appSortMethod {
    int defaultIndex = AppSortMethod.defaultSort.index;
    int appCount = prefs?.safeInt('trackedAppCount') ?? 0;
    if (appCount > 20) {
      defaultIndex = AppSortMethod.nameAZ.index;
    } else if (appCount > 0) {
      defaultIndex = AppSortMethod.latestUpdates.index;
    }
    return prefs?.safeEnum('appSortMethod', AppSortMethod.values) ??
        AppSortMethod.values[defaultIndex];
  }

  set appSortMethod(AppSortMethod method) {
    prefs?.setInt('appSortMethod', method.index);
    notifyListeners();
  }

  ViewMode get globalViewMode =>
      prefs?.safeEnum('globalViewMode', ViewMode.values) ?? ViewMode.list;
  set globalViewMode(ViewMode mode) {
    prefs?.setInt('globalViewMode', mode.index);
    notifyListeners();
  }

  ViewMode get discoverViewMode =>
      prefs?.safeEnum('discoverViewMode', ViewMode.values) ?? ViewMode.grid;
  set discoverViewMode(ViewMode mode) {
    prefs?.setInt('discoverViewMode', mode.index);
    notifyListeners();
  }

  int get gridColumnCount =>
      (prefs?.safeInt('gridColumnCount') ?? 0).clamp(0, 6);
  set gridColumnCount(int val) {
    prefs?.setInt('gridColumnCount', val);
    notifyListeners();
  }

  bool get displayShowAppCount => prefs?.safeBool('displayShowAppCount') ?? true;
  set displayShowAppCount(bool val) {
    prefs?.setBool('displayShowAppCount', val);
    notifyListeners();
  }

  bool get displayShowFilterChips =>
      prefs?.safeBool('displayShowFilterChips') ?? true;
  set displayShowFilterChips(bool val) {
    prefs?.setBool('displayShowFilterChips', val);
    notifyListeners();
  }

  bool get displayShowAuthor => prefs?.safeBool('displayShowAuthor') ?? false;
  set displayShowAuthor(bool val) {
    prefs?.setBool('displayShowAuthor', val);
    notifyListeners();
  }

  bool get displayShowVersion => prefs?.safeBool('displayShowVersion') ?? true;
  set displayShowVersion(bool val) {
    prefs?.setBool('displayShowVersion', val);
    notifyListeners();
  }

  bool get displayShowDate => prefs?.safeBool('displayShowDate') ?? false;
  set displayShowDate(bool val) {
    prefs?.setBool('displayShowDate', val);
    notifyListeners();
  }

  CategoryIconPosition get categoryIconPosition =>
      prefs?.safeEnum('categoryIconPosition', CategoryIconPosition.values) ??
      CategoryIconPosition.leading;
  set categoryIconPosition(CategoryIconPosition val) {
    prefs?.setInt('categoryIconPosition', val.index);
    notifyListeners();
  }

  int get categoryIconCount =>
      (prefs?.safeInt('categoryIconCount') ?? 0).clamp(0, 20);
  set categoryIconCount(int val) {
    prefs?.setInt('categoryIconCount', val);
    notifyListeners();
  }

  AppListDensity get appListDensity =>
      prefs?.safeEnum('appListDensity', AppListDensity.values) ??
      AppListDensity.comfortable;
  set appListDensity(AppListDensity val) {
    prefs?.setInt('appListDensity', val.index);
    notifyListeners();
  }

  GridCategoryMode get gridCategoryMode =>
      prefs?.safeEnum('gridCategoryMode', GridCategoryMode.values) ??
      GridCategoryMode.sections;
  set gridCategoryMode(GridCategoryMode val) {
    prefs?.setInt('gridCategoryMode', val.index);
    notifyListeners();
  }

  NavigationDestinationLabelBehavior get navigationLabelBehavior =>
      prefs?.safeEnum(
        'navigationLabelBehavior',
        NavigationDestinationLabelBehavior.values,
      ) ??
      NavigationDestinationLabelBehavior.values[0];
  set navigationLabelBehavior(NavigationDestinationLabelBehavior val) {
    prefs?.setInt('navigationLabelBehavior', val.index);
    notifyListeners();
  }
}
