import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/apps_provider.dart' hide obtainiumId, obtainiumTempId;
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
  MapEntry(
    Locale('en', 'EO'),
    'Esperanto',
  ), // https://github.com/aissat/easy_localization/issues/220#issuecomment-846035493
  MapEntry(Locale('in'), 'Bahasa Indonesia'),
  MapEntry(Locale('ko'), '한국어'),
  MapEntry(Locale('ca'), 'Català'),
  MapEntry(Locale('ar'), 'العربية'),
  MapEntry(Locale('ml'), 'മലയാളം'),
];
const fallbackLocale = Locale('en');
const localeDir = 'assets/translations';
var fdroid = false;

final globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.attachStacktrace = true;
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
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        
        Sentry.configureScope((scope) {
          scope.setTag('android_sdk', androidInfo.version.sdkInt.toString());
          scope.setTag('device', androidInfo.model);
          scope.setContexts('android_device', {
            'model': androidInfo.model,
            'brand': androidInfo.brand,
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
        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => SettingsProvider()),
              ChangeNotifierProxyProvider<SettingsProvider, AppsProvider>(
                create: (ctx) => AppsProvider(settings: ctx.read<SettingsProvider>()),
                update: (ctx, settings, apps) => apps!..settingsProvider = settings,
              ),
              ChangeNotifierProvider(create: (context) => context.read<SettingsProvider>().updateSettings),
              ChangeNotifierProvider(create: (context) => context.read<SettingsProvider>().viewSettings),
              ChangeNotifierProvider(create: (context) => context.read<SettingsProvider>().behaviorSettings),
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
        );
        BackgroundFetch.registerHeadlessTask(BackgroundService.backgroundFetchHeadlessTask);
      } catch (e, stackTrace) {
        final sentryId = await Sentry.captureException(e, stackTrace: stackTrace);
        await CrashTracker.recordCrash(sentryId.toString());
        runApp(ErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
      }
    },
  );
}

Future<void> loadTranslations() async {
  // Ensure localization is initialized - called during startup
  await EasyLocalization.ensureInitialized();
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({super.key, required this.error, required this.stackTrace});

  Future<void> _reportToGitHub() async {
    await Sentry.captureMessage('User Feedback Triggered');
    final Uri url = Uri.parse(
      'https://github.com/thejaustin/ObtainiumPlus/issues/new?template=crash_report.md&logs=${Uri.encodeComponent('$error\n\n$stackTrace')}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _followIssue() async {
    final Uri url = Uri.parse(CrashTracker.issueTrackerUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Obtainium+ Startup Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report, color: Colors.white),
                      onPressed: _reportToGitHub,
                      tooltip: 'Report to GitHub',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'The app failed to start. Please report this error:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _reportToGitHub,
                      icon: const Icon(Icons.launch),
                      label: const Text('Report on GitHub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _followIssue,
                      icon: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                      label: const Text('Follow Issue', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        stackTrace,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      _buildError = details.exceptionAsString();
      _buildStackTrace = details.stack?.toString();
      Sentry.captureException(details.exception, stackTrace: details.stack).then((id) {
        CrashTracker.recordCrash(id.toString());
      });
      return _buildErrorWidget(details.exceptionAsString(), details.stack?.toString() ?? '');
    };
    initPlatformState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNonOptionalPermissions();
    });
  }

  Widget _buildErrorWidget(String error, String stackTrace) {
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Obtainium+ Build Error',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                        tooltip: 'Follow Issue on GitHub',
                        onPressed: () async {
                          final Uri url = Uri.parse(CrashTracker.issueTrackerUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.white),
                        tooltip: 'Report on GitHub',
                        onPressed: () async {
                          await Sentry.captureMessage('User Feedback Triggered (Build Error)');
                          final Uri url = Uri.parse(
                            'https://github.com/thejaustin/ObtainiumPlus/issues/new?template=crash_report.md&logs=${Uri.encodeComponent('$error\n\n$stackTrace')}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(error, style: const TextStyle(color: Colors.yellowAccent, fontSize: 11, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(
                    child: SelectableText(stackTrace, style: const TextStyle(color: Colors.white60, fontSize: 9, fontFamily: 'monospace')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
