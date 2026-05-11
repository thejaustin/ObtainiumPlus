import 'package:flutter/foundation.dart';
import 'package:obtainium/providers/apps_provider.dart';

class TagProvider with ChangeNotifier {
  final AppsProvider appsProvider;

  TagProvider(this.appsProvider);

  // Get all unique tags currently in use
  Set<String> get allTags {
    final tags = <String>{};
    for (final appInMemory in appsProvider.getAppValues(deepCopy: false)) {
      tags.addAll(appInMemory.app.tags);
    }
    return tags;
  }

  void addTag(String appId, String tag) {
    final app = appsProvider.apps[appId]?.app;
    if (app != null && !app.tags.contains(tag)) {
      app.tags.add(tag);
      appsProvider.saveApps([app]);
      notifyListeners();
    }
  }

  void removeTag(String appId, String tag) {
    final app = appsProvider.apps[appId]?.app;
    if (app != null && app.tags.contains(tag)) {
      app.tags.remove(tag);
      appsProvider.saveApps([app]);
      notifyListeners();
    }
  }
}
