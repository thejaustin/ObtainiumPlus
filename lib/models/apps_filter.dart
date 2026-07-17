import 'package:obtainium/providers/settings_provider.dart';

class AppsFilter {
  String nameFilter = '';
  String authorFilter = '';
  String idFilter = '';
  bool includeUptodate = true;
  bool includeNonInstalled = true;
  Set<String> categoryFilter = {};
  Set<String> tagFilter = {}; // Added tag filtering
  Set<String> statusFilter = {};
  String sourceFilter = '';

  AppsFilter({this.includeUptodate = true, this.includeNonInstalled = true});

  Map<String, dynamic> toFormValuesMap() => {
    'appName': nameFilter,
    'author': authorFilter,
    'appId': idFilter,
    'upToDateApps': includeUptodate,
    'nonInstalledApps': includeNonInstalled,
    'sourceFilter': sourceFilter,
  };

  void setFormValuesFromMap(Map<String, dynamic> values) {
    nameFilter = values['appName']!;
    authorFilter = values['author']!;
    idFilter = values['appId']!;
    includeUptodate = values['upToDateApps'];
    includeNonInstalled = values['nonInstalledApps'];
    sourceFilter = values['sourceFilter'];
  }

  bool isIdenticalTo(AppsFilter other, SettingsProvider settingsProvider) =>
      authorFilter == other.authorFilter &&
      nameFilter == other.nameFilter &&
      idFilter == other.idFilter &&
      includeUptodate == other.includeUptodate &&
      includeNonInstalled == other.includeNonInstalled &&
      settingsProvider.setEqual(categoryFilter, other.categoryFilter) &&
      settingsProvider.setEqual(
        tagFilter,
        other.tagFilter,
      ) && // Check tag filter
      sourceFilter == other.sourceFilter &&
      settingsProvider.setEqual(statusFilter, other.statusFilter);
}
