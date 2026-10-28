import 'dart:convert';
import 'dart:io';

import 'package:android_package_manager/android_package_manager.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/app_actions_context_menu.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppsProvider extends ChangeNotifier implements AppsProvider {
  final Map<String, AppInMemory> _mockApps;

  _MockAppsProvider(this._mockApps);

  @override
  Map<String, AppInMemory> get apps => _mockApps;

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

  AppInMemory makeApp({
    required String id,
    required String name,
    required String? installedVersion,
    required String latestVersion,
  }) {
    final app = App(
      id,
      'https://github.com/example/$id',
      'Author',
      name,
      installedVersion,
      latestVersion,
      const [MapEntry('https://example.com/app.apk', 'app.apk')],
      0,
      const {},
      null,
      false,
    );
    final installedInfo = installedVersion != null
        ? _TestPackageInfo(
            packageName: id,
            versionCode: 1,
            versionName: installedVersion,
          )
        : null;
    return AppInMemory(app, null, installedInfo, null);
  }

  testWidgets('AppActionsContextMenu displays appropriate actions for outdated app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'tactileFeedbackEnabled': false,
      'plusEnableTags': true,
    });

    final plusSettings = PlusSettingsProvider();
    final outdatedApp = makeApp(
      id: 'test.app',
      name: 'Sample App',
      installedVersion: '1.0.0',
      latestVersion: '2.0.0',
    );
    final appsProvider = _MockAppsProvider({'test.app': outdatedApp});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsProvider>.value(value: appsProvider),
          ChangeNotifierProvider<PlusSettingsProvider>.value(value: plusSettings),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppActionsContextMenu.show(context, outdatedApp),
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open context menu
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();

    // Verify title and author
    expect(find.text('Sample App'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);

    // Verify Update option with version delta
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('1.0.0 → 2.0.0'), findsOneWidget);

    // Verify Share option
    expect(find.text('Share'), findsOneWidget);

    // Verify Copy App URL
    expect(find.text('Copy app URL'), findsOneWidget);
  });
}
