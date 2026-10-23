import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ViewSettingsProvider> provider(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final p = ViewSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    return p;
  }

  group('navigationLabelBehavior', () {
    test('defaults to selected-only', () async {
      final p = await provider({});
      expect(
        p.navigationLabelBehavior,
        NavigationDestinationLabelBehavior.onlyShowSelected,
      );
    });

    test('carries over the old always-show switch', () async {
      final p = await provider({'plusNavBarAlwaysShowLabels': true});
      expect(
        p.navigationLabelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
    });

    test('a stored choice wins over the old switch', () async {
      final p = await provider({
        'plusNavBarAlwaysShowLabels': true,
        'navigationLabelBehavior':
            NavigationDestinationLabelBehavior.alwaysHide.index,
      });
      expect(
        p.navigationLabelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
    });
  });

  test('updates row shows by default and can be turned off', () async {
    final p = await provider({});
    expect(p.showUpdatesRow, isTrue);
    expect(p.pinUpdates, isTrue);
    p.showUpdatesRow = false;
    expect(p.showUpdatesRow, isFalse);
  });

  test('flat grid only turns grouping off in the grid, not the list', () async {
    final p = await provider({
      'groupByCategory': true,
      'gridCategoryMode': GridCategoryMode.disabled.index,
      'globalViewMode': ViewMode.grid.index,
    });
    expect(p.groupsInCurrentView, isFalse);
    p.globalViewMode = ViewMode.list;
    expect(p.groupsInCurrentView, isTrue);
    p.gridCategoryMode = GridCategoryMode.sections;
    p.globalViewMode = ViewMode.grid;
    expect(p.groupsInCurrentView, isTrue);
  });
}
