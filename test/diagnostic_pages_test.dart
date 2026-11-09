import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/components/settings/multi_user_diagnostic_sheet.dart';
import 'package:obtainium/components/settings/play_store_diagnostic_sheet.dart';
import 'package:obtainium/components/settings/play_store_inspector_sheet.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/shizuku_status_service.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps each diagnostic page on a 360x780 phone with 1.3x text and fails on
/// any exception or RenderFlex overflow. Native channels are mocked so the
/// pages' init calls answer instantly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  const nativeChannel = MethodChannel('dev.thejaustin.obtainiumplus/native');
  const shizukuChannel = MethodChannel('shizuku_apk_installer');
  const pmChannel = MethodChannel('android_package_manager');

  setUp(() {
    SharedPreferences.setMockInitialValues({'plusSettingsBottomNavBar': false});
    FlutterSecureStorage.setMockInitialValues({});
    ShizukuStatusService.resetForTest();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(nativeChannel, (call) async {
      switch (call.method) {
        case 'getInstalledProfilesAndApps':
          return [
            for (var i = 0; i < 12; i++)
              {
                'packageName': 'com.example.app$i',
                'label': 'Example app with a fairly long name $i',
                'versionName': '1.$i.0',
                'userId': i.isEven ? 0 : 10,
                'profileLabel': 'ignored',
              },
          ];
        case 'isIgnoringBatteryOptimizations':
          return false;
        case 'isUsageAccessGranted':
          return false;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(shizukuChannel, (call) async {
      if (call.method == 'checkPermission') return 'granted_adb';
      return null;
    });
    messenger.setMockMethodCallHandler(pmChannel, (call) async => null);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in [nativeChannel, shizukuChannel, pmChannel]) {
      messenger.setMockMethodCallHandler(c, null);
    }
  });

  Future<Widget> buildApp(Widget home) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final plusSettings = PlusSettingsProvider();
    await plusSettings.initializeSettings(prefs);
    final behaviorSettings = BehaviorSettingsProvider();
    await behaviorSettings.initializeSettings(prefs);
    const locale = Locale('en');
    return EasyLocalization(
      supportedLocales: const [locale],
      startLocale: locale,
      path: 'assets/translations',
      fallbackLocale: locale,
      assetLoader: _MemoryAssetLoader(translations),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: plusSettings),
          ChangeNotifierProvider.value(value: behaviorSettings),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
            lazy: true,
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: appLocalizationsDelegates(
              context.localizationDelegates,
            ),
            supportedLocales: const [locale],
            locale: locale,
            theme: ThemeBuilder.buildTheme(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useSystemFont: false,
              cornerRadius: plusSettings.plusGlobalCornerRadius,
              isTV: false,
              matchSystemMaterialStyle: false,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page,
    Type pageType, {
    Future<void> Function()? interact,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildApp(page);
    });

    final errors = <FlutterErrorDetails>[];
    final baseHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      baseHandler?.call(details);
    };
    try {
      await tester.pumpWidget(app);
      for (var i = 0; i < 40; i++) {
        // Real async for the asset loader and mocked channel futures.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byType(pageType))) break;
      }
      // Let the Shizuku probe's retry backoff and page loads finish.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      if (interact != null) await interact();
      // Scroll the whole page so lazily built sections lay out too.
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 8; i++) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 200));
      }
    } finally {
      FlutterError.onError = baseHandler;
    }
    final exception = tester.takeException();
    for (final d in errors) {
      // ignore: avoid_print
      print('──── captured error detail ────\n$d');
    }
    expect(exception, isNull);
    expect(errors, isEmpty);
    expect(find.byType(pageType), findsOneWidget);
  }

  test('status service retries past the plugin warm-up', () async {
    // The plugin answers services_not_found until Shizuku's binder arrives
    // asynchronously; a single probe reported a running server as stopped.
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shizukuChannel, (call) async {
          if (call.method != 'checkPermission') return null;
          calls++;
          return calls < 3 ? 'services_not_found' : 'granted_adb';
        });
    ShizukuStatusService.installedPackageOverride = () async =>
        'af.shizuku.plus.api';
    addTearDown(() => ShizukuStatusService.installedPackageOverride = null);

    final service = ShizukuStatusService.instance;
    final results = await Future.wait([service.refresh(), service.refresh()]);
    expect(calls, 3, reason: 'concurrent refreshes share one probe');
    expect(identical(results[0], results[1]), isTrue);
    expect(results[0].state, ShizukuServiceState.active);
    expect(results[0].providerLabel, 'Shizuku+');
    expect(service.status.value, same(results[0]));
  });

  testWidgets('Service Doctor page fits a 360dp phone at 1.3x text', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const DeviceOptimizationPage(),
      DeviceOptimizationPage,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('Play Store inspector page fits a 360dp phone at 1.3x text', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const PlayStoreInspectorPage(),
      PlayStoreInspectorPage,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('Play diagnostics page fits a 360dp phone at 1.3x text', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const PlayStoreDiagnosticPage(autoRun: false),
      PlayStoreDiagnosticPage,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('Multi-user page lists every visible profile', (tester) async {
    await pumpPage(
      tester,
      const MultiUserDiagnosticPage(),
      MultiUserDiagnosticPage,
      interact: () async {
        // Both mocked profiles are listed (the old sheet showed none).
        expect(find.text(translations['multiUserMainProfile']), findsOneWidget);
        expect(find.text('Profile 10'), findsOneWidget);
        await tester.tap(find.text(translations['multiUserMainProfile']));
        await tester.pump(const Duration(milliseconds: 500));
      },
    );
  }, timeout: const Timeout(Duration(minutes: 1)));
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
