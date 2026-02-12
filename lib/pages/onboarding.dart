import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();
  bool _isSamsung = false;
  bool _isXiaomi = false;

  // Quick Start State
  bool _addObtainiumPlus = true;
  bool _pinObtainiumPlus = true;
  final Map<String, String> _recommendedApps = {
    'F-Droid': 'https://f-droid.org/',
    'Signal': 'https://signal.org/android/apk/',
    'Bitwarden': 'https://github.com/bitwarden/mobile',
  };
  final Set<String> _selectedRecommended = {};

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    final info = await DeviceInfoPlugin().androidInfo;
    final manufacturer = info.manufacturer.toLowerCase();
    setState(() {
      _isSamsung = manufacturer.contains('samsung');
      _isXiaomi = ['xiaomi', 'redmi', 'poco'].any((x) => manufacturer.contains(x));
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _requestInstallPermission() async {
    if (await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }
  }

  Future<void> _openUsageAccess() async {
    await AppInstallService.openUsageAccessSettings();
  }

  Future<void> _openBatteryOptimization() async {
    if (_isXiaomi) {
      await AppInstallService.openBatteryOptimizationSettings();
    } else {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  Future<void> _finishOnboarding() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final appsProvider = context.read<AppsProvider>();
      List<App> appsToAdd = [];

      // 1. Add Obtainium+ if selected
      if (_addObtainiumPlus) {
        try {
          var info = await AppInstallService.getInstalledInfo(obtainiumId);
          if (info?.versionName != null) {
            appsToAdd.add(
              App(
                obtainiumId,
                obtainiumUrl,
                'thejaustin',
                'Obtainium+',
                info!.versionName,
                info.versionName!,
                [],
                0,
                {
                  'versionDetection': true,
                  'apkFilterRegEx': 'fdroid',
                  'invertAPKFilter': true,
                },
                null,
                _pinObtainiumPlus,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error adding Obtainium+: $e');
        }
      }

      if (appsToAdd.isNotEmpty) {
        await appsProvider.saveApps(appsToAdd, onlyIfExists: false);
      }
    } catch (e) {
      debugPrint('Error during onboarding finish: $e');
    } finally {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        widget.onDone();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.transparent, // Use theme background
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Theme.of(context).colorScheme.surface,
      allowImplicitScrolling: true,
      autoScrollDuration: null, // Disable auto scroll for interaction
      
      pages: [
        // 1. What it does
        PageViewModel(
          title: "Obtainium+",
          body: "Install and update Android apps directly from their source releases (GitHub, GitLab, F-Droid, etc.) without an app store.",
          image: Icon(Icons.download_for_offline, size: 100, color: Theme.of(context).colorScheme.primary),
          decoration: pageDecoration,
        ),

        // 2. How to add
        PageViewModel(
          title: "Add Apps",
          body: "Simply paste an app's release page URL (like a GitHub repo) or use the search feature to start tracking updates.",
          image: Icon(Icons.add_circle_outline, size: 100, color: Theme.of(context).colorScheme.secondary),
          decoration: pageDecoration,
        ),

        // 3. Smart Settings
        PageViewModel(
          title: "Stay Updated",
          body: "Enable background checks and notifications to ensure your apps are always up to date.",
          image: Icon(Icons.sync_lock, size: 100, color: Theme.of(context).colorScheme.tertiary),
          decoration: pageDecoration,
          footer: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text("Automatic Background Checks"),
                    subtitle: const Text("Check for updates while the app is closed"),
                    value: settings.updateInterval > 0,
                    onChanged: (val) {
                      settings.updateInterval = val ? 360 : 0;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _requestNotificationPermission,
                    icon: const Icon(Icons.notifications),
                    label: const Text("Allow Notifications"),
                  ),
                ],
              );
            }
          ),
        ),
      ],
      onDone: _finishOnboarding,
      onSkip: _finishOnboarding,
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(Icons.arrow_back),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        activeSize: const Size(22.0, 10.0),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
