import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';

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
      // Xiaomi specific intent often fails or goes to generic settings, 
      // but let's try standard first or open specific if we can.
      // Current service uses generic intent.
      await AppInstallService.openBatteryOptimizationSettings();
    } else {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
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
      autoScrollDuration: 3000,
      
      pages: [
        // 1. Welcome
        PageViewModel(
          title: tr('welcome'),
          body: "Obtainium allows you to install and update apps directly from their releases pages.",
          image: Icon(Icons.download_for_offline, size: 100, color: Theme.of(context).colorScheme.primary),
          decoration: pageDecoration,
        ),

        // 2. Experience Selection
        PageViewModel(
          title: "Choose Your Experience",
          body: "Obtainium+ includes enhanced features like Grid View, Animations, and more. You can toggle these anytime in Settings.",
          image: Icon(Icons.auto_awesome, size: 100, color: Theme.of(context).colorScheme.tertiary),
          decoration: pageDecoration,
          footer: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text("Enable Obtainium+ Enhancements", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Recommended for most users"),
                    value: settings.enableAllPlusFeatures,
                    onChanged: (val) => settings.enableAllPlusFeatures = val,
                    secondary: const Icon(Icons.stars),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.enableAllPlusFeatures 
                      ? "Enhanced Experience Enabled" 
                      : "Standard Obtainium Experience",
                    style: TextStyle(
                      color: settings.enableAllPlusFeatures ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              );
            }
          ),
        ),

        // 3. Permissions (Notifications & Install)
        PageViewModel(
          title: "Permissions",
          body: "Obtainium needs permissions to notify you about updates and to install apps.",
          image: Icon(Icons.security, size: 100, color: Theme.of(context).colorScheme.secondary),
          decoration: pageDecoration,
          footer: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _requestNotificationPermission,
                icon: const Icon(Icons.notifications),
                label: const Text("Allow Notifications"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestInstallPermission,
                icon: const Icon(Icons.install_mobile),
                label: Text(tr('installUnknownApps')),
              ),
            ],
          ),
        ),

        // 3. Device Specific (Samsung/Xiaomi) - Conditionally shown or combined
        if (_isSamsung || _isXiaomi)
          PageViewModel(
            title: tr('troubleshootingAndSystem'),
            body: _isSamsung 
                ? tr('samsungUsageAccessMessage') 
                : tr('xiaomiTroubleshootingDescription'),
            image: Icon(Icons.build, size: 100, color: Theme.of(context).colorScheme.tertiary),
            decoration: pageDecoration,
            footer: Column(
              children: [
                if (_isSamsung)
                  ElevatedButton.icon(
                    onPressed: _openUsageAccess,
                    icon: const Icon(Icons.insights),
                    label: Text(tr('usageAccessSettings')),
                  ),
                if (_isXiaomi)
                  ElevatedButton.icon(
                    onPressed: _openBatteryOptimization,
                    icon: const Icon(Icons.battery_saver),
                    label: Text(tr('batteryOptimizationSettings')),
                  ),
              ],
            ),
          ),

        // 4. Ready
        PageViewModel(
          title: "You're All Set!",
          body: "You can change these settings later in the 'Troubleshooting' section.",
          image: Icon(Icons.check_circle, size: 100, color: Colors.green),
          decoration: pageDecoration,
        ),
      ],
      onDone: widget.onDone,
      onSkip: widget.onDone, // You can skip onboarding
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
