// Renders real Settings screens to PNG for quick visual review without a
// device build. Not part of the CI test suite (lives outside test/).
//
// Usage: tool/preview.sh [--tabs 0,3] [--dark] [--width 412] [--height 2400]
// Output: build/previews/settings_tab_<n>[_dark].png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tabsArg = String.fromEnvironment('PREVIEW_TABS', defaultValue: '0');
const _dark = bool.fromEnvironment('PREVIEW_DARK');
const _width = int.fromEnvironment('PREVIEW_WIDTH', defaultValue: 412);
const _height = int.fromEnvironment('PREVIEW_HEIGHT', defaultValue: 2400);
const _flutterRoot = String.fromEnvironment('FLUTTER_ROOT_DIR');

const _fakeAndroidDeviceInfo = <String, dynamic>{
  'version': {
    'baseOS': '',
    'codename': 'REL',
    'incremental': 'preview',
    'previewSdkInt': 0,
    'release': '16',
    'sdkInt': 36,
    'securityPatch': '2026-10-01',
  },
  'board': 'preview',
  'bootloader': 'preview',
  'brand': 'samsung',
  'device': 'preview',
  'display': 'preview',
  'fingerprint': 'samsung/preview',
  'hardware': 'qcom',
  'host': 'preview',
  'id': 'preview',
  'manufacturer': 'samsung',
  'model': 'SM-PREVIEW',
  'product': 'preview',
  'name': 'Preview',
  'supported32BitAbis': <String>[],
  'supported64BitAbis': ['arm64-v8a'],
  'supportedAbis': ['arm64-v8a'],
  'tags': 'release-keys',
  'type': 'user',
  'isPhysicalDevice': true,
  'freeDiskSize': 0,
  'totalDiskSize': 0,
  'systemFeatures': <String>[],
  'isLowRamDevice': false,
  'physicalRamSize': 12000,
  'availableRamSize': 6000,
};

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final f = File(p);
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  final mf = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  await _loadFont('Montserrat', ['assets/fonts/Montserrat-Regular.ttf']);
  await _loadFont('Roboto', [
    '$mf/Roboto-Regular.ttf',
    '$mf/Roboto-Medium.ttf',
    '$mf/Roboto-Bold.ttf',
  ]);
  await _loadFont('SystemFont', ['$mf/Roboto-Regular.ttf']);
  await _loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;
  final tabs = _tabsArg
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({'plusSettingsBottomNavBar': false});
  });

  for (final tab in tabs) {
    testWidgets('preview settings tab $tab', (tester) async {
      tester.view.physicalSize = Size(_width * 2.0, _height * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      // Settings rows query device info (OEM guides, installer options);
      // answer like a Samsung phone on Android 16 so they render as on device.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/device_info'),
        (_) async => _fakeAndroidDeviceInfo,
      );

      final boundaryKey = GlobalKey();
      late Widget app;
      await tester.runAsync(() async {
        await _loadFonts();
        await EasyLocalization.ensureInitialized();
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsProvider();
        await settings.initializeSettings();
        final plus = PlusSettingsProvider();
        await plus.initializeSettings(prefs);
        final theme = ThemeSettingsProvider();
        await theme.initializeSettings(prefs);
        final behavior = BehaviorSettingsProvider();
        await behavior.initializeSettings(prefs);
        final view = ViewSettingsProvider();
        await view.initializeSettings(prefs);
        final update = UpdateSettingsProvider();
        await update.initializeSettings(prefs);
        const locale = Locale('en');
        app = EasyLocalization(
          supportedLocales: const [locale],
          startLocale: locale,
          path: 'assets/translations',
          fallbackLocale: locale,
          assetLoader: _MemoryAssetLoader(translations),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: plus),
              ChangeNotifierProvider.value(value: theme),
              ChangeNotifierProvider.value(value: behavior),
              ChangeNotifierProvider.value(value: view),
              ChangeNotifierProvider.value(value: update),
              ChangeNotifierProvider<AppsProvider>(
                create: (_) => AppsProvider(),
                lazy: true,
              ),
            ],
            child: Builder(
              builder: (context) => RepaintBoundary(
                key: boundaryKey,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: appLocalizationsDelegates(
                    context.localizationDelegates,
                  ),
                  supportedLocales: const [locale],
                  locale: locale,
                  theme: ThemeBuilder.buildTheme(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.deepPurple,
                      brightness: _dark ? Brightness.dark : Brightness.light,
                    ),
                    useSystemFont: false,
                    cornerRadius: plus.plusGlobalCornerRadius,
                  ),
                  home: SettingsPage(initialTab: tab),
                ),
              ),
            ),
          ),
        );
      });

      await tester.pumpWidget(app);
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byType(SettingsPage))) break;
      }
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      // Icons/images decode asynchronously; give them a real tick.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = File(
          'build/previews/settings_tab_$tab${_dark ? '_dark' : ''}.png',
        );
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(bytes!.buffer.asUint8List());
        // ignore: avoid_print
        print('PREVIEW ${out.path}');
      });
      tester.takeException();
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
