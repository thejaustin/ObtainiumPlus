// Captures frames of the update flow (check -> update found -> download ->
// install -> done) for the real app tiles and operations banner, and writes a
// contact sheet so motion problems can be reviewed without a device.
// Not part of the CI suite (lives outside test/).
//
// Usage: tool/film.sh            -> build/previews/update_flow_sheet.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/apps/active_operations_banner.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _flutterRoot = String.fromEnvironment('FLUTTER_ROOT_DIR');
const _dark = bool.fromEnvironment('PREVIEW_DARK');
const _frameMs = int.fromEnvironment('FILM_FRAME_MS', defaultValue: 40);
const _framesPerStep = int.fromEnvironment('FILM_FRAMES', defaultValue: 8);
const _zoomRows = String.fromEnvironment('FILM_ZOOM_ROWS');
const _zoomHeight = int.fromEnvironment('FILM_ZOOM_HEIGHT', defaultValue: 380);

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
    loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
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
  await _loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
}

App _fakeApp(String latest) => App(
  'com.example.film',
  'https://github.com/example/film',
  'Example',
  'Film Demo',
  '1.0.0',
  latest,
  [const MapEntry('film.apk', 'https://example.com/film.apk')],
  0,
  <String, dynamic>{},
  DateTime(2026, 10, 30),
  false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('film the update flow', (tester) async {
    tester.view.physicalSize = const Size(412 * 2, 560 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (_) async => _fakeAndroidDeviceInfo,
    );
    SharedPreferences.setMockInitialValues({});

    final translations =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    final boundaryKey = GlobalKey();
    var hasUpdate = false;
    late StateSetter setOuter;
    late AppsProvider apps;
    late Widget root;

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
      apps = AppsProvider(isBg: true, settingsProvider: settings);
      apps.apps['com.example.film'] = AppInMemory(
        _fakeApp('1.0.0'),
        null,
        null,
        null,
      );
      const locale = Locale('en');
      root = EasyLocalization(
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
            ChangeNotifierProvider<AppsProvider>.value(value: apps),
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
                home: Scaffold(
                  body: SafeArea(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        setOuter = setState;
                        final aim = context
                            .watch<AppsProvider>()
                            .apps['com.example.film']!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ActiveOperationsBanner(),
                            const SizedBox(height: 8),
                            AppListTile(appInMemory: aim, hasUpdate: hasUpdate),
                            const SizedBox(height: 8),
                            Center(
                              child: SizedBox(
                                width: 180,
                                height: 200,
                                child: AppGridTile(
                                  appInMemory: aim,
                                  isSelected: false,
                                  onTap: () {},
                                  onLongPress: () {},
                                  hasUpdate: hasUpdate,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });

    await tester.pumpWidget(root);
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    final frames = <img.Image>[];
    final legend = <String>[];
    Future<void> capture(String label) async {
      for (var f = 0; f < _framesPerStep; f++) {
        await tester.pump(const Duration(milliseconds: _frameMs));
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.0);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          frames.add(
            img.Image.fromBytes(
              width: image.width,
              height: image.height,
              bytes: bytes!.buffer,
              numChannels: 4,
            ),
          );
        });
        legend.add('${frames.length - 1}: $label +${(f + 1) * _frameMs}ms');
        final banner = tester.getSize(find.byType(ActiveOperationsBanner));
        final grid = tester.getSize(find.byType(AppGridTile));
        // ignore: avoid_print
        print(
          'METRIC $label +${(f + 1) * _frameMs}ms '
          'banner=${banner.height.toStringAsFixed(0)} '
          'gridTile=${grid.width.toStringAsFixed(0)}x${grid.height.toStringAsFixed(0)}',
        );
      }
    }

    void step(void Function() mutate) {
      mutate();
      apps.forceNotifyListeners();
      setOuter(() {});
    }

    final aim = apps.apps['com.example.film']!;
    await capture('idle');
    step(() {
      apps.gettingUpdates = true;
      apps.refreshTotal.value = 12;
      apps.refreshProgress.value = 0.0;
      apps.checkingUpdateIds.add('com.example.film');
    });
    await capture('check started');
    step(() => apps.refreshProgress.value = 0.5);
    await capture('check 50%');
    step(() {
      apps.refreshFound.value = 1;
      apps.checkingUpdateIds.remove('com.example.film');
      aim.app = _fakeApp('1.1.0');
      hasUpdate = true;
    });
    await capture('update found');
    step(() {
      apps.refreshProgress.value = null;
      apps.refreshTotal.value = 0;
      apps.gettingUpdates = false;
    });
    await capture('check done');
    step(() {
      aim.downloadTotalBytes = 20 * 1024 * 1024;
      aim.downloadReceivedBytes = 0;
      aim.downloadSpeedBytesPerSec = 4.0 * 1024 * 1024;
      aim.downloadProgress = 0;
    });
    await capture('download start');
    step(() {
      aim.downloadReceivedBytes = 12 * 1024 * 1024;
      aim.downloadProgress = 60;
    });
    await capture('download 60%');
    step(() => aim.downloadProgress = 100);
    await capture('download 100%');
    step(() => aim.downloadProgress = -1);
    await capture('installing');
    step(() {
      aim.downloadProgress = null;
      aim.app = _fakeApp('1.1.0')..installedVersion = '1.1.0';
      hasUpdate = false;
    });
    await capture('installed');

    // Contact sheet: one row per step.
    final w = frames.first.width ~/ 2;
    final h = frames.first.height ~/ 2;
    final sheet = img.Image(
      width: w * _framesPerStep,
      height: h * (frames.length ~/ _framesPerStep),
    );
    for (var i = 0; i < frames.length; i++) {
      img.compositeImage(
        sheet,
        img.copyResize(frames[i], width: w, height: h),
        dstX: (i % _framesPerStep) * w,
        dstY: (i ~/ _framesPerStep) * h,
      );
    }
    // Optional zoom sheet: chosen rows at full size, first 4 frames, cropped
    // to the top of the screen where the banner and list tile are.
    final zoomRows = _zoomRows
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
    if (zoomRows.isNotEmpty) {
      const cols = 4;
      final fw = frames.first.width;
      final zoom = img.Image(
        width: fw * cols,
        height: _zoomHeight * zoomRows.length,
      );
      for (var r = 0; r < zoomRows.length; r++) {
        for (var c = 0; c < cols; c++) {
          final i = zoomRows[r] * _framesPerStep + c;
          if (i >= frames.length) continue;
          img.compositeImage(
            zoom,
            img.copyCrop(frames[i], x: 0, y: 0, width: fw, height: _zoomHeight),
            dstX: c * fw,
            dstY: r * _zoomHeight,
          );
        }
      }
      File(
        'build/previews/update_flow_zoom.png',
      ).writeAsBytesSync(img.encodePng(zoom));
      // ignore: avoid_print
      print('PREVIEW build/previews/update_flow_zoom.png');
    }
    final out = File('build/previews/update_flow_sheet.png')
      ..parent.createSync(recursive: true);
    out.writeAsBytesSync(img.encodePng(sheet));
    for (var i = 0; i < frames.length; i += _framesPerStep) {
      // ignore: avoid_print
      print(
        'ROW ${i ~/ _framesPerStep}: ${legend[i].split(': ').last.split(' +').first}',
      );
    }
    // ignore: avoid_print
    print('PREVIEW ${out.path}');
    tester.takeException();
  }, timeout: const Timeout(Duration(minutes: 4)));
}
