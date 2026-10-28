import 'dart:convert';
import 'dart:io';

import 'package:android_package_manager/android_package_manager.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppsProvider extends ChangeNotifier implements AppsProvider {
  final Map<String, AppInMemory> _mockApps;

  _MockAppsProvider(this._mockApps);

  @override
  Map<String, AppInMemory> get apps => _mockApps;

  @override
  Iterable<AppInMemory> getAppValues({bool deepCopy = true}) => _mockApps.values;

  @override
  final Set<String> checkingUpdateIds = const {};

  @override
  bool areDownloadsRunning() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  List<String> searchDeselected = const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPackageInfo implements PackageInfo {
  @override
  final String? packageName;
  @override
  final String? versionName;
  @override
  final int? versionCode;

  _TestPackageInfo({this.packageName, this.versionName, this.versionCode});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    final translations =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(
      const Locale('en'),
      translations: Translations(translations),
    );
  });

  AppInMemory makeApp(
    String id,
    String name, {
    String installedVersion = '1.0.0',
    String latestVersion = '1.0.0',
    List<String> tags = const [],
    List<String> categories = const [],
    bool installed = true,
  }) {
    final app = App(
      id,
      'https://github.com/example/$id',
      'Test Author',
      name,
      installed ? installedVersion : null,
      latestVersion,
      const [MapEntry('https://example.com/app.apk', 'app.apk')],
      0,
      const {},
      null,
      false,
      categories: categories,
      tags: tags,
    );
    final installedInfo = installed
        ? _TestPackageInfo(packageName: id, versionCode: 1, versionName: installedVersion)
        : null;
    return AppInMemory(app, null, installedInfo, null);
  }

  testWidgets('CommandCenter displays pending updates hub and tag discovery chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'tactileFeedbackEnabled': false,
      'plusEnableEnhancedAnimations': false,
      'plusEnableTags': true,
    });

    final plusSettings = PlusSettingsProvider();
    final settings = _MockSettingsProvider();

    final app1 = makeApp(
      'app1',
      'Alpha App',
      installedVersion: '1.0.0',
      latestVersion: '2.0.0', // Has update!
      tags: ['productivity', 'foss'],
      categories: ['Utilities'],
    );

    final app2 = makeApp(
      'app2',
      'Beta App',
      installedVersion: '1.5.0',
      latestVersion: '1.5.0', // Up to date
      tags: ['foss'],
      categories: ['Media'],
    );

    final appsProvider = _MockAppsProvider({
      'app1': app1,
      'app2': app2,
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsProvider>.value(value: appsProvider),
          ChangeNotifierProvider<PlusSettingsProvider>.value(value: plusSettings),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<SourceProvider>.value(value: SourceProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CommandCenter(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verify search field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify Pending Updates section renders with app1 and "Update All" button
    expect(find.textContaining('UPDATES (1)'), findsOneWidget);
    expect(find.text('Update All'), findsOneWidget);
    expect(find.text('Alpha App'), findsWidgets);

    // Verify Tag discovery chips render
    expect(find.text('TAGS'), findsOneWidget);
    expect(find.text('productivity'), findsOneWidget);
    expect(find.text('foss'), findsOneWidget);

    // Verify Categories chips render
    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);

    // Scroll to and tap tag chip "productivity"
    await tester.ensureVisible(find.text('productivity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('productivity'));
    await tester.pump(const Duration(milliseconds: 300));

    // Search query should now be set to productivity and show Alpha App in local results
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'productivity');
    expect(find.text('Alpha App'), findsWidgets);
  });
}
