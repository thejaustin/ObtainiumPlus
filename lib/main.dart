import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/apps_provider.dart' hide obtainiumId, obtainiumTempId;
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_config_provider.dart';
import 'package:obtainium/providers/plugin_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/easy_localization_controller.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/background_service.dart';
import 'package:obtainium/services/background_update_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/crash_file_handler.dart';
import 'package:obtainium/utils/locale_constants.dart';
import 'package:obtainium/components/error_app.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

var fdroid = false;

final globalNavigatorKey = GlobalKey<NavigatorState>();

/// Filters out expected Shizuku-related exceptions so they don't pollute
/// the Sentry dashboard (mirrors hexodus's filterShizukuNoise logic).
SentryEvent? _filterShizukuNoise(SentryEvent event, Hint hint) {
  final exceptions = event.exceptions;
  if (exceptions == null || exceptions.isEmpty) return event;

  for (final ex in exceptions) {
    final type = ex.type ?? '';
    final value = (ex.value ?? '').toLowerCase();

    // Shizuku binder died — happens whenever Shizuku stops/restarts
    if (type.contains('DeadObjectException')) return null;

    // Permission denied before Shizuku grants access
    if (type.contains('SecurityException') && value.contains('shizuku')) {
      return null;
    }

    // Shizuku IPC failures — check for shizuku frames in the stack
    if (type.contains('RemoteException')) {
      final frames = ex.stackTrace?.frames ?? [];
      final hasShizukuFrame = frames.any(
        (f) =>
            (f.package ?? '').toLowerCase().contains('shizuku') ||
            (f.absPath ?? '').toLowerCase().contains('shizuku') ||
            (f.className ?? '').toLowerCase().contains('shizuku'),
      );
      if (hasShizukuFrame) return null;
    }
  }

  return event;
}

void main() async {
  initLogger();
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');

      // Performance — keep sample rates low to avoid overwhelming Sentry
      options.tracesSampleRate = 0.2;
      options.profilesSampleRate = 0.1;

      // Session health tracking (mirrors hexodus isEnableAutoSessionTracking)
      options.enableAutoSessionTracking = true;

      // Always include stack traces
      options.attachStacktrace = true;

      // Privacy — never send PII or screenshots (hexodus parity)
      options.sendDefaultPii = false;
      options.attachScreenshot = false;

      // Flutter-specific breadcrumbs (mirrors hexodus lifecycle/system breadcrumbs)
      options.enableWindowMetricBreadcrumbs = true;
      options.enableBrightnessChangeBreadcrumbs = true;
      options.enableTextScaleChangeBreadcrumbs = true;

      // Filter out expected Shizuku exceptions (hexodus parity)
      options.beforeSend = _filterShizukuNoise;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      try {
        await EasyLocalization.ensureInitialized();
        final sp = await SharedPreferences.getInstance();
        final settingsProvider = context.read<SettingsProvider>();
        await settingsProvider.initializeSettings(sp);
        await context.read<PluginProvider>().initialize(sp);
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final isSamsung = manufacturer == 'samsung';
        final isFoldable =
            androidInfo.model.toLowerCase().contains('fold') ||
            androidInfo.model.toLowerCase().contains('flip');

        Sentry.configureScope((scope) {
          scope.setTag('android_sdk', androidInfo.version.sdkInt.toString());
          scope.setTag('device', androidInfo.model);
          // Extended device tags (hexodus parity)
          scope.setTag('manufacturer', manufacturer);
          scope.setTag('device_model', androidInfo.model);
          scope.setTag('android_api', androidInfo.version.sdkInt.toString());
          scope.setTag('is_samsung', isSamsung.toString());
          scope.setTag('is_foldable', isFoldable.toString());
          scope.setContexts('android_device', {
            'model': androidInfo.model,
            'brand': androidInfo.brand,
            'manufacturer': androidInfo.manufacturer,
            'version': androidInfo.version.release,
            'sdk': androidInfo.version.sdkInt,
          });
        });

        if (androidInfo.version.sdkInt >= 29) {
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
          );
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
        final np = NotificationsProvider();
        await np.initialize();
        FlutterForegroundTask.initCommunicationPort();

        // Zone guard catches unhandled async errors that escape the widget tree
        // (mirrors hexodus's zone-level error boundary pattern)
        runZonedGuarded(
          () => runApp(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (context) => SettingsProvider()),
                ChangeNotifierProxyProvider<SettingsProvider, AppsProvider>(
                  create: (ctx) => AppsProvider(settings: ctx.read<SettingsProvider>()),
                  update: (ctx, settings, apps) => apps!..settingsProvider = settings,
                ),
                ChangeNotifierProvider<UpdateSettingsProvider>(create: (context) => context.read<SettingsProvider>().updateSettings),
                ChangeNotifierProvider<ViewSettingsProvider>(create: (context) => context.read<SettingsProvider>().viewSettings),
                ChangeNotifierProvider<BehaviorSettingsProvider>(create: (context) => context.read<SettingsProvider>().behaviorSettings),
                ChangeNotifierProvider<PlusSettingsProvider>(create: (context) => context.read<SettingsProvider>().plusSettings),
                ChangeNotifierProvider<SourceConfigProvider>(create: (context) => context.read<SettingsProvider>().sourceConfig),
                ChangeNotifierProvider<PluginProvider>(create: (context) => PluginProvider()),
                Provider(create: (context) => np),
                Provider(create: (context) => LogsProvider()),
              ],
              child: EasyLocalization(
                supportedLocales: supportedLocales.map((e) => e.key).toList(),
                path: localeDir,
                fallbackLocale: fallbackLocale,
                useOnlyLangCode: false,
                child: const Obtainium(),
              ),
            ),
          ),
          (error, stack) {
            talker.handle(error, stack, 'Unhandled Zone Error');
            Sentry.captureException(error, stackTrace: stack).then((id) {
              CrashTracker.recordCrash(id.toString());
              CrashAnalytics.recordCrash(
                errorType: error.runtimeType.toString(),
                errorMessage: error.toString(),
                eventId: id.toString(),
              );
              CrashFileHandler.writeCrashLog(
                errorType: error.runtimeType.toString(),
                message: error.toString(),
                stackTrace: stack.toString(),
                sentryEventId: id.toString(),
              );
            });
          },
        );
        BackgroundFetch.registerHeadlessTask(BackgroundService.backgroundFetchHeadlessTask);
      } catch (e, stackTrace) {
        talker.handle(e, stackTrace, 'Main Catch Error');
        final sentryId = await Sentry.captureException(e, stackTrace: stackTrace);
        await CrashTracker.recordCrash(sentryId.toString());
        await CrashAnalytics.recordCrash(
          errorType: e.runtimeType.toString(),
          errorMessage: e.toString(),
          eventId: sentryId.toString(),
        );
        await CrashFileHandler.writeCrashLog(
          errorType: e.runtimeType.toString(),
          message: e.toString(),
          stackTrace: stackTrace.toString(),
          sentryEventId: sentryId.toString(),
        );
        runApp(ErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
      }
    },
  );
}

Future<void> loadTranslations() async {
  // Ensure localization is initialized - called during startup
  await EasyLocalization.ensureInitialized();
}

class Obtainium extends StatefulWidget {
  const Obtainium({super.key});

  @override
  State<Obtainium> createState() => _ObtainiumState();
}

class _ObtainiumState extends State<Obtainium> {
  var existingUpdateInterval = -1;
  String? _buildError;
  String? _buildStackTrace;

  @override
  void initState() {
    super.initState();
    // Set custom error widget builder to catch build errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      talker.handle(details.exception, details.stack, 'Build Error');
      _buildError = details.exceptionAsString();
      _buildStackTrace = details.stack?.toString();
      Sentry.captureException(details.exception, stackTrace: details.stack).then((id) {
        CrashTracker.recordCrash(id.toString());
        CrashAnalytics.recordCrash(
          errorType: details.exception.runtimeType.toString(),
          errorMessage: details.exceptionAsString(),
          eventId: id.toString(),
        );
        CrashFileHandler.writeCrashLog(
          errorType: details.exception.runtimeType.toString(),
          message: details.exceptionAsString(),
          stackTrace: details.stack?.toString() ?? '',
          sentryEventId: id.toString(),
        );
      });
      return BuildErrorWidget(error: details.exceptionAsString(), stackTrace: details.stack?.toString() ?? '');
    };
    initPlatformState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNonOptionalPermissions();
    });
  }

  Future<void> requestNonOptionalPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Check if this is a Xiaomi device (uses shared DeviceUtils)
    final isXiaomi = await DeviceUtils.isXiaomiDevice();

    if (isXiaomi) {
      // Skip standard battery optimization on Xiaomi - it causes issues
      // The Xiaomi setup dialog will handle this instead
      return;
    }

    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (e) {
      // Ignore errors on devices that don't handle this intent correctly
      print('Failed to request battery optimization: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initPlatformState() async {
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        await BackgroundUpdateService.bgUpdateCheck(taskId, null);
        BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        context.read<LogsProvider>().add('BG update task timed out.');
        BackgroundFetch.finish(taskId);
      },
    );
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    AppsProvider appsProvider = context.read<AppsProvider>();
    LogsProvider logs = context.read<LogsProvider>();
    NotificationsProvider notifs = context.read<NotificationsProvider>();
    if (settingsProvider.updateInterval == 0) {
      BackgroundService.stopForegroundService();
      BackgroundFetch.stop();
    } else {
      if (settingsProvider.useFGService) {
        BackgroundFetch.stop();
        BackgroundService.startForegroundService(false);
      } else {
        BackgroundService.stopForegroundService();
        BackgroundFetch.start();
      }
    }
    if (settingsProvider.prefs == null) {
      settingsProvider.initializeSettings();
    } else {
      bool isFirstRun = settingsProvider.checkAndFlipFirstRun();
      if (isFirstRun) {
        logs.add('This is the first ever run of Obtainium.');
        // If this is the first run, add Obtainium to the Apps list
        if (!fdroid) {
          AppInstallService.getInstalledInfo(obtainiumId)
              .then((value) {
                if (value?.versionName != null) {
                  appsProvider.saveApps([
                    App(
                      obtainiumId,
                      obtainiumUrl,
                      'thejaustin',
                      'Obtainium+',
                      value!.versionName,
                      value.versionName!,
                      [],
                      0,
                      {
                        'versionDetection': true,
                        'apkFilterRegEx': 'fdroid',
                        'invertAPKFilter': true,
                      },
                      null,
                      false,
                    ),
                  ], onlyIfExists: false);
                }
              })
              .catchError((err) {
                print(err);
              });
        }
      }
      if (!supportedLocales.map((e) => e.key).contains(context.locale) ||
          (settingsProvider.forcedLocale == null &&
              context.deviceLocale != context.locale)) {
        settingsProvider.resetLocaleSafe(context);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifs.checkLaunchByNotif();
    });

    return WithForegroundTask(
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // Decide on a colour/brightness scheme based on OS and user settings
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;
          if (lightDynamic != null &&
              darkDynamic != null &&
              settingsProvider.useMaterialYou) {
            if (settingsProvider.matchSystemMaterialStyle) {
              // Match system's complete Material You theme (colors + style)
              lightColorScheme = lightDynamic.harmonized();
              darkColorScheme = darkDynamic.harmonized();
            } else {
              // Use system color as seed but apply custom selected variant
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: lightDynamic.primary,
                dynamicSchemeVariant: settingsProvider.themeVariant,
              ).harmonized();
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: darkDynamic.primary,
                brightness: Brightness.dark,
                dynamicSchemeVariant: settingsProvider.themeVariant,
              ).harmonized();
            }
          } else {
            // Use custom color with selected variant
            lightColorScheme = ColorScheme.fromSeed(
              seedColor: settingsProvider.themeColor,
              dynamicSchemeVariant: settingsProvider.themeVariant,
            );
            darkColorScheme = ColorScheme.fromSeed(
              seedColor: settingsProvider.themeColor,
              brightness: Brightness.dark,
              dynamicSchemeVariant: settingsProvider.themeVariant,
            );
          }

          // set the background and surface colors to pure black in the amoled theme
          if (settingsProvider.useBlackTheme) {
            darkColorScheme = darkColorScheme
                .copyWith(
                  surface: Colors.black,
                  onSurface: Colors.white, // Ensure text remains visible on pure black background
                  surfaceVariant: Colors.grey[900]!, // Darker variant for contrast
                  onSurfaceVariant: Colors.white70, // Lighter text for secondary content
                )
                .harmonized();
          }

          if (settingsProvider.useSystemFont) NativeFeatures.loadSystemFont();

          return MaterialApp(
            title: 'Obtainium',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            navigatorKey: globalNavigatorKey,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              SentryNavigatorObserver(),
              TalkerRouteObserver(talker),
            ],
            theme: ThemeBuilder.buildTheme(
              colorScheme: settingsProvider.theme == ThemeSettings.dark
                  ? darkColorScheme
                  : lightColorScheme,
              useSystemFont: settingsProvider.useSystemFont,
            ),
            darkTheme: ThemeBuilder.buildTheme(
              colorScheme: settingsProvider.theme == ThemeSettings.light
                  ? lightColorScheme
                  : darkColorScheme,
              useSystemFont: settingsProvider.useSystemFont,
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
