import 'dart:async';
import 'dart:io';
// TextDirection must be prefix-qualified: easy_localization re-exports
// intl's TextDirection, which shadows the Flutter one.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/apps_provider.dart' hide bgUpdateCheck;
import 'package:obtainium/services/background_update_service.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/tag_provider.dart';
import 'package:obtainium/providers/source_config_provider.dart';
import 'package:obtainium/providers/plugin_provider.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:workmanager/workmanager.dart';

List<MapEntry<Locale, String>> supportedLocales = const [
  MapEntry(Locale('en'), 'English'),
  MapEntry(Locale('zh'), '简体中文'),
  MapEntry(Locale('zh', 'Hant_TW'), '臺灣話'),
  MapEntry(Locale('it'), 'Italiano'),
  MapEntry(Locale('ja'), '日本語'),
  MapEntry(Locale('hu'), 'Magyar'),
  MapEntry(Locale('de'), 'Deutsch'),
  MapEntry(Locale('fa'), 'فارسی'),
  MapEntry(Locale('fr'), 'Français'),
  MapEntry(Locale('es'), 'Español'),
  MapEntry(Locale('pl'), 'Polski'),
  MapEntry(Locale('ru'), 'Русский'),
  MapEntry(Locale('bs'), 'Bosanski'),
  MapEntry(Locale('pt'), 'Português'),
  MapEntry(Locale('pt', 'BR'), 'Brasileiro'),
  MapEntry(Locale('cs'), 'Česky'),
  MapEntry(Locale('sv'), 'Svenska'),
  MapEntry(Locale('nl'), 'Nederlands'),
  MapEntry(Locale('vi'), 'Tiếng Việt'),
  MapEntry(Locale('tr'), 'Türkçe'),
  MapEntry(Locale('uk'), 'Українська'),
  MapEntry(Locale('da'), 'Dansk'),
  MapEntry(Locale('en', 'EO'), 'Esperanto'),
  MapEntry(Locale('id'), 'Bahasa Indonesia'),
  MapEntry(Locale('ko'), '한국어'),
  MapEntry(Locale('ca'), 'Català'),
  MapEntry(Locale('ar'), 'العربية'),
  MapEntry(Locale('ml'), 'മലയാളം'),
  MapEntry(Locale('gl'), 'Galego'),
];
const fallbackLocale = Locale('en');
const localeDir = 'assets/translations';
bool isFdroidBuild = false;

/// Global navigator key, used to navigate from outside the widget tree
/// (e.g. tapping a notification).
final globalNavigatorKey = GlobalKey<NavigatorState>();

/// Unique task name used by WorkManager for periodic background update checks.
const _workManagerTaskName = 'obtainiumBgUpdateCheck';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    print('BG update task timed out.');
    try {
      BackgroundFetch.finish(taskId);
    } catch (e) {
      print('BackgroundFetch.finish failed: $e');
    }
    return;
  }
  await BackgroundUpdateService.bgUpdateCheck(taskId, null);
  try {
    BackgroundFetch.finish(taskId);
  } catch (e) {
    print('BackgroundFetch.finish failed: $e');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  static const String incrementCountCommand = 'incrementCount';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    BackgroundUpdateService.bgUpdateCheck('bg_check', null);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    BackgroundUpdateService.bgUpdateCheck('bg_check', null);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('Foreground service onDestroy(isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {}
}

/// Filters out expected Shizuku-related exceptions so they don't pollute
/// the Sentry dashboard (binder restarts and pre-grant permission errors
/// are normal operating conditions, not bugs).
SentryEvent? _filterShizukuNoise(SentryEvent event, Hint hint) {
  final exceptions = event.exceptions;
  if (exceptions == null || exceptions.isEmpty) return event;

  bool hasShizukuFrame(SentryException ex) => (ex.stackTrace?.frames ?? []).any(
    (f) =>
        (f.package ?? '').toLowerCase().contains('shizuku') ||
        (f.absPath ?? '').toLowerCase().contains('shizuku') ||
        (f.module ?? '').toLowerCase().contains('shizuku'),
  );

  for (final ex in exceptions) {
    final type = ex.type ?? '';
    final value = (ex.value ?? '').toLowerCase();
    if (type.contains('DeadObjectException')) return null;
    if (type.contains('SecurityException') && value.contains('shizuku')) {
      return null;
    }
    if (type.contains('RemoteException') && hasShizukuFrame(ex)) return null;
    if (type.contains('PlatformException') &&
        (value.contains('shizuku') || hasShizukuFrame(ex))) {
      return null;
    }
    // Filter out expected validation/user actions (ObtainiumError and subclasses)
    if (type.contains('ObtainiumError') ||
        type.contains('UnsupportedURLError') ||
        type.contains('DownloadCancelledError') ||
        type.contains('RateLimitError') ||
        type.contains('InvalidURLError') ||
        type.contains('NoReleasesError') ||
        type.contains('NoAPKError') ||
        type.contains('NoVersionError') ||
        type.contains('DowngradeError') ||
        type.contains('InstallError') ||
        type.contains('IDChangedError') ||
        type.contains('RepositoryRenamedError') ||
        type.contains('BadDownloadError') ||
        type.contains('NotImplementedError')) {
      return null;
    }
  }
  return event;
}

void main() async {
  // Crash reporting was silently dropped in a May refactor (fb5a91c2) —
  // without it, release-mode build failures like issue #217 are invisible.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isEmpty) {
    await _runObtainium();
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.tracesSampleRate = 0.2;
    options.profilesSampleRate = 0.1;
    options.enableAutoSessionTracking = true;
    options.attachStacktrace = true;
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
    options.environment = kReleaseMode ? 'production' : 'development';
    options.beforeSend = _filterShizukuNoise;
  }, appRunner: _runObtainium);
}

Future<void> _runObtainium() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Replace the release-mode ErrorWidget (a bare grey rectangle — see issue
  // #217) with a card that names the failure, so a broken widget is
  // reportable instead of an anonymous blank page.
  ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
    textDirection: ui.TextDirection.ltr,
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF442726),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFFB4AB),
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Something went wrong rendering this part of the app.\nPlease screenshot this and report it on GitHub.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              details.exception.toString(),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFFFDAD6), fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      LogsProvider().add(
        'Uncaught platform error: $error\n$stack',
        level: LogLevel.error,
      ),
    );
    return true;
  };
  try {
    ByteData data = await PlatformAssetBundle().load(
      'assets/ca/lets-encrypt-r3.pem',
    );
    SecurityContext.defaultContext.setTrustedCertificatesBytes(
      data.buffer.asUint8List(),
    );
  } catch (e) {
    // Already added, do nothing (see #375)
  }
  await initializeDateFormatting();
  await EasyLocalization.ensureInitialized();
  if ((await DeviceInfoPlugin().androidInfo).version.sdkInt >= 29) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  final np = NotificationsProvider();
  await np.initialize();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final sp = SettingsProvider();
  final plusSettings = PlusSettingsProvider();
  final themeSettings = ThemeSettingsProvider();
  final behaviorSettings = BehaviorSettingsProvider();
  final viewSettings = ViewSettingsProvider();
  final updateSettings = UpdateSettingsProvider();

  await Future.wait([
    sp.initializeSettings(),
    plusSettings.initializeSettings(prefs),
    themeSettings.initializeSettings(prefs),
    behaviorSettings.initializeSettings(prefs),
    viewSettings.initializeSettings(prefs),
    updateSettings.initializeSettings(prefs),
  ]);

  plusSettings.addListener(() {
    sp.notifyPlusSettingsChanged();
  });

  FlutterForegroundTask.initCommunicationPort();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppsProvider()),
        ChangeNotifierProvider(create: (context) => sp),
        ChangeNotifierProvider(create: (context) => plusSettings),
        ChangeNotifierProvider(create: (context) => themeSettings),
        ChangeNotifierProvider(create: (context) => behaviorSettings),
        ChangeNotifierProvider(create: (context) => viewSettings),
        ChangeNotifierProvider(create: (context) => updateSettings),
        ChangeNotifierProxyProvider<AppsProvider, TagProvider>(
          create: (context) => TagProvider(context.read<AppsProvider>()),
          update: (context, appsProvider, tagProvider) =>
              TagProvider(appsProvider),
        ),
        ChangeNotifierProvider(create: (context) => SourceConfigProvider()),
        ChangeNotifierProvider(create: (context) => PluginProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        Provider(create: (context) => np),
        Provider(create: (context) => LogsProvider()),
        Provider(create: (context) => SourceProvider()),
      ],
      child: EasyLocalization(
        supportedLocales: supportedLocales.map((e) => e.key).toList(),
        path: localeDir,
        fallbackLocale: fallbackLocale,
        useOnlyLangCode: false,
        useFallbackTranslations: true,
        child: const Obtainium(),
      ),
    ),
  );
}

class Obtainium extends StatefulWidget {
  const Obtainium({super.key});

  @override
  State<Obtainium> createState() => _ObtainiumState();
}

class _ObtainiumState extends State<Obtainium> {
  var _firstRunHandled = false;
  var _launchByNotifChecked = false;
  var _fontLoaded = false;

  void _manageServices(UpdateSettingsProvider updateSettings, LogsProvider logs) {
    var interval = updateSettings.updateInterval;
    var useFG = updateSettings.useFGService;
    if (interval == _lastUpdateInterval && useFG == _lastUseFGService) return;
    _lastUpdateInterval = interval;
    _lastUseFGService = useFG;
    try {
      if (interval == 0) {
        stopForegroundService();
        try {
          BackgroundFetch.stop().catchError((_) {});
        } catch (_) {}
      } else if (useFG) {
        try {
          BackgroundFetch.stop().catchError((_) {});
        } catch (_) {}
        startForegroundService(false);
      } else {
        stopForegroundService();
        try {
          BackgroundFetch.start().catchError((_) {});
        } catch (_) {}
      }
    } catch (e) {
      logs.add('BackgroundFetch operation failed: $e');
    }
  }

  void _handleFirstRun(
    SettingsProvider settings,
    AppsProvider apps,
    Logger logger,
    BuildContext context,
  ) {
    if (settings.prefs == null) {
      settings.initializeSettings();
      return;
    }
    if (_firstRunHandled) return;
    _firstRunHandled = true;
    final isFirstRun = settings.checkAndFlipFirstRun();
    if (isFirstRun) {
      logger.info('This is the first ever run of Obtainium.');
      if (!isFdroidBuild) {
        getInstalledInfo(obtainiumId)
            .then((value) {
              if (value?.versionName != null) {
                unawaited(apps.saveApps([
                  App(
                    id: obtainiumId,
                    url: obtainiumUrl,
                    author: 'ImranR98',
                    name: 'Obtainium',
                    installedVersion: value!.versionName,
                    latestVersion: value.versionName!,
                    apkUrls: [],
                    preferredApkIndex: 0,
                    additionalSettings: {
                      'versionDetection': true,
                      'apkFilterRegEx': 'fdroid',
                      'invertAPKFilter': true,
                    },
                    lastUpdateCheck: null,
                    pinned: false,
                  ),
                ], onlyIfExists: false));
              }
            })
            .catchError((err) {
              logger.error('Failed to add Obtainium on first run', err);
            });
      }
    }
    final currentLang = context.locale.languageCode;
    final deviceLang = context.deviceLocale.languageCode;
    if (!supportedLocales.map((e) => e.key).contains(context.locale) ||
        (settings.forcedLocale == null && deviceLang != currentLang)) {
      settings.resetLocaleSafe(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final appsProvider = context.read<AppsProvider>();
      final logger = context.read<Logger>();
      final notifs = context.read<NotificationsProvider>();

      unawaited(_scheduleWorkManager());
      _handleFirstRun(settingsProvider, appsProvider, logger, context);

      if (!_launchByNotifChecked) {
        _launchByNotifChecked = true;
        notifs.checkLaunchByNotif();
      }
    });
  }

  Future<void> requestNonOptionalPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      var settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.showBatteryOptimizationPrompt) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  void initForegroundService() {
    // ignore: invalid_use_of_visible_for_testing_member
    if (!FlutterForegroundTask.isInitialized) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'bg_update',
          channelName: tr('foregroundService'),
          channelDescription: tr('foregroundService'),
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(900000),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
  }

  Future<ServiceRequestResult?> startForegroundService(bool restart) async {
    initForegroundService();
    if (await FlutterForegroundTask.isRunningService) {
      if (restart) {
        return FlutterForegroundTask.restartService();
      }
    } else {
      return FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.specialUse],
        serviceId: 666,
        notificationTitle: tr('foregroundService'),
        notificationText: tr('fgServiceNotice'),
        notificationIcon: NotificationIcon(
          metaDataName:
              'dev.thejaustin.obtainiumplus.service.NOTIFICATION_ICON',
        ),
        callback: startCallback,
      );
    }
    return null;
  }

  stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.stopService();
    }
  }

  @override
  void dispose() {
    LogsProvider.close();
    super.dispose();
  }

  Future<void> initPlatformState([int? fetchInterval]) async {
    final updateSettings = context.read<UpdateSettingsProvider>();
    final finalInterval = fetchInterval == null || fetchInterval < 15
        ? 15
        : fetchInterval;
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: finalInterval,
          stopOnTerminate: false,
          startOnBoot: true,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: updateSettings.bgUpdateRequiresCharging,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: updateSettings.bgUpdateRequiresWifi
              ? NetworkType.UNMETERED
              : NetworkType.ANY,
        ),
        (String taskId) async {
          await BackgroundUpdateService.bgUpdateCheck(taskId, null);
          try {
            BackgroundFetch.finish(taskId);
          } catch (e) {
            print('BackgroundFetch.finish failed: $e');
          }
        },
        (String taskId) async {
          context.read<LogsProvider>().add('BG update task timed out.');
          try {
            BackgroundFetch.finish(taskId);
          } catch (e) {
            print('BackgroundFetch.finish failed: $e');
          }
        },
      );
    } catch (e) {
      print('BackgroundFetch.configure failed: $e');
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final appsProvider = context.read<AppsProvider>();
    final logs = context.read<LogsProvider>();
    final notifs = context.read<NotificationsProvider>();

    if (updateSettings.updateInterval != existingUpdateInterval) {
      existingUpdateInterval = updateSettings.updateInterval;
      if (existingUpdateInterval > 0) {
        initPlatformState(existingUpdateInterval);
      }
    }

    _manageServices(updateSettings, logs);
    _handleFirstRun(settingsProvider, appsProvider, logs, context);

    return WithForegroundTask(
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          setAppLocale(context.locale);
          // Decide on a colour/brightness scheme based on OS and user settings
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;
          // "Match system Material style" only has meaning when the system
          // dynamic colour scheme is actually in use
          final bool matchSystemStyle =
              themeSettings.useMaterialYou &&
              themeSettings.matchSystemMaterialStyle &&
              lightDynamic != null &&
              darkDynamic != null;
          if (lightDynamic != null &&
              darkDynamic != null &&
              themeSettings.useMaterialYou) {
            // When matching the system style, keep the dynamic scheme
            // untouched; otherwise harmonize it with the app's palette
            lightColorScheme = matchSystemStyle
                ? lightDynamic
                : lightDynamic.harmonized();
            darkColorScheme = matchSystemStyle
                ? darkDynamic
                : darkDynamic.harmonized();
          } else {
            lightColorScheme = ColorScheme.fromSeed(
              seedColor: themeSettings.themeColor,
              dynamicSchemeVariant: themeSettings.themeVariant,
            );
            darkColorScheme = ColorScheme.fromSeed(
              seedColor: themeSettings.themeColor,
              brightness: Brightness.dark,
              dynamicSchemeVariant: themeSettings.themeVariant,
            );
          }

          // Rebuild the whole dark surface ladder near-black in the amoled
          // theme (cards, dialogs, nav bar etc. use the container steps, not
          // just `surface`), keeping the relative ordering so the M3 tonal
          // hierarchy survives
          if (themeSettings.useBlackTheme) {
            darkColorScheme = darkColorScheme
                .copyWith(
                  surface: Colors.black,
                  surfaceDim: Colors.black,
                  surfaceContainerLowest: Colors.black,
                  surfaceContainerLow: const Color(0xFF0A0A0A),
                  surfaceContainer: const Color(0xFF121212),
                  surfaceContainerHigh: const Color(0xFF1A1A1A),
                  surfaceContainerHighest: const Color(0xFF212121),
                )
                .harmonized();
          }

          // The system font is also needed when matching the system style
          if (themeSettings.useSystemFont || matchSystemStyle) {
            NativeFeatures.loadSystemFont();
          }

          return MaterialApp(
            title: 'Obtainium',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            navigatorKey: globalNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeBuilder.buildTheme(
              colorScheme: themeSettings.theme == ThemeSettings.dark
                  ? darkColorScheme
                  : lightColorScheme,
              useSystemFont: themeSettings.useSystemFont,
              plusEnableMaterialExpressive:
                  plusSettings.plusEnableMaterialExpressive,
              cornerRadius: plusSettings.plusGlobalCornerRadius,
              matchSystemMaterialStyle: matchSystemStyle,
            ),
            darkTheme: ThemeBuilder.buildTheme(
              colorScheme: themeSettings.theme == ThemeSettings.light
                  ? lightColorScheme
                  : darkColorScheme,
              useSystemFont: themeSettings.useSystemFont,
              plusEnableMaterialExpressive:
                  plusSettings.plusEnableMaterialExpressive,
              cornerRadius: plusSettings.plusGlobalCornerRadius,
              matchSystemMaterialStyle: matchSystemStyle,
            ),
            home: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select):
                    const ActivateIntent(),
              },
              child: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}
