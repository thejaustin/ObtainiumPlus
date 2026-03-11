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

  bool _addObtainiumPlus = true;

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final appsProvider = context.read<AppsProvider>();
      List<App> appsToAdd = [];

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
                true, // always pin Obtainium+ to the top
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
        Navigator.pop(context);
        widget.onDone();
      }
    }
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          dense: true,
        ),
      ),
    );
  }

  Widget _buildPermissionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }

  Widget _buildFabToggle(
    BuildContext context,
    SettingsProvider settings, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 16.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.transparent,
      imagePadding: EdgeInsets.zero,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: colorScheme.surface,
      allowImplicitScrolling: true,
      autoScrollDuration: null,

      pages: [
        // ── 1. Welcome ──────────────────────────────────────────────────────
        PageViewModel(
          title: 'Obtainium+',
          body: 'Install and update Android apps directly from their source — GitHub, GitLab, F-Droid, and more — without an app store.',
          image: Icon(Icons.download_for_offline, size: 100, color: colorScheme.primary),
          decoration: pageDecoration,
        ),

        // ── 2. Add Apps ──────────────────────────────────────────────────────
        PageViewModel(
          title: 'Add Apps',
          body: 'Multiple ways to build your app list fast.',
          image: Icon(Icons.add_circle_outline, size: 100, color: colorScheme.secondary),
          decoration: pageDecoration,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.link_outlined,
                title: 'Paste a URL',
                subtitle: 'Paste any GitHub, GitLab, or other release page URL to start tracking.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.star_border_rounded,
                title: 'GitHub Starred Repos',
                subtitle: 'Import apps from your GitHub starred repositories in bulk.',
                iconColor: colorScheme.tertiary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.person_outline_rounded,
                title: 'GitHub Personal Repos',
                subtitle: 'Import from your own repos — private repos included when a token is set.',
                iconColor: colorScheme.tertiary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.install_mobile_outlined,
                title: 'Import Installed Apps',
                subtitle: 'Scan your device and start tracking apps already installed.',
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Card(
                  color: colorScheme.secondaryContainer,
                  elevation: 0,
                  child: ListTile(
                    leading: Icon(Icons.key_outlined, color: colorScheme.onSecondaryContainer),
                    title: Text(
                      'GitHub Token (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      'Add a token in Settings → GitHub to unlock private repos and avoid rate limits.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer),
                    ),
                    dense: true,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 3. Permissions ────────────────────────────────────────────────────
        PageViewModel(
          title: 'Permissions',
          body: 'Grant these so Obtainium+ can install apps and check for updates in the background.',
          image: Icon(Icons.security_outlined, size: 100, color: colorScheme.tertiary),
          decoration: pageDecoration,
          footer: Builder(
            builder: (ctx) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.install_mobile_rounded,
                  label: 'Allow Installing Apps',
                  onPressed: _requestInstallPermission,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.notifications_outlined,
                  label: 'Allow Notifications',
                  onPressed: _requestNotificationPermission,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.battery_saver_outlined,
                  label: 'Disable Battery Optimisation',
                  onPressed: _openBatteryOptimization,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.track_changes_outlined,
                  label: 'Allow Usage Access',
                  onPressed: _openUsageAccess,
                ),
                if (_isSamsung || _isXiaomi)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Card(
                      color: colorScheme.tertiaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
                        title: Text(
                          _isSamsung ? 'Samsung tip' : 'Xiaomi tip',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          _isSamsung
                              ? 'On Samsung, also enable "Auto-launch" for Obtainium+ in Device Care → Battery.'
                              : 'On Xiaomi, enable "Auto-start" for Obtainium+ in Security → Manage apps.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── 4. Stay Updated ──────────────────────────────────────────────────
        PageViewModel(
          title: 'Stay Updated',
          body: 'Enable background checks so your apps are always up to date.',
          image: Icon(Icons.sync_lock, size: 100, color: colorScheme.primary),
          decoration: pageDecoration,
          footer: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile.adaptive(
                    title: const Text(
                      'Automatic Background Checks',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Check for updates while the app is closed'),
                    value: settings.updateInterval > 0,
                    onChanged: (val) => settings.updateInterval = val ? 360 : 0,
                  ),
                  if (settings.updateInterval > 0) ...[
                    const SizedBox(height: 8),
                    Slider(
                      value: settings.updateInterval.toDouble().clamp(60, 1440),
                      min: 60,
                      max: 1440,
                      divisions: 23,
                      label: '${(settings.updateInterval / 60).round()}h',
                      onChanged: (val) => settings.updateInterval = val.round(),
                    ),
                    Center(
                      child: Text(
                        'Check every ${(settings.updateInterval / 60).round()}h',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // ── 5. Quick-Add Menu ────────────────────────────────────────────────
        PageViewModel(
          title: 'Quick-Add Menu',
          body: 'Choose which shortcuts appear when you tap +. Adjust anytime in Settings → Obtainium+ Features.',
          image: Icon(Icons.add_box_outlined, size: 100, color: colorScheme.secondary),
          decoration: pageDecoration,
          footer: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildFabToggle(
                        context,
                        settings,
                        icon: Icons.search_rounded,
                        title: 'Search',
                        subtitle: 'Quick-launch the app search',
                        value: settings.plusFabShowSearch,
                        onChanged: (val) => settings.plusFabShowSearch = val,
                      ),
                      _buildFabToggle(
                        context,
                        settings,
                        icon: Icons.link_outlined,
                        title: 'Add by URL',
                        subtitle: 'Paste a release page URL',
                        value: settings.plusFabShowAddByUrl,
                        onChanged: (val) => settings.plusFabShowAddByUrl = val,
                      ),
                      _buildFabToggle(
                        context,
                        settings,
                        icon: Icons.star_border_rounded,
                        title: 'GitHub Starred Repos',
                        subtitle: 'Import your starred repositories',
                        value: settings.plusFabShowGithubStarred,
                        onChanged: (val) => settings.plusFabShowGithubStarred = val,
                      ),
                      _buildFabToggle(
                        context,
                        settings,
                        icon: Icons.person_outline_rounded,
                        title: 'GitHub Personal Repos',
                        subtitle: 'Import your own repositories',
                        value: settings.plusFabShowGithubPersonalRepos,
                        onChanged: (val) => settings.plusFabShowGithubPersonalRepos = val,
                      ),
                      _buildFabToggle(
                        context,
                        settings,
                        icon: Icons.install_mobile_outlined,
                        title: 'Import Installed Apps',
                        subtitle: 'Scan device for installed apps',
                        value: settings.plusFabShowImportInstalled,
                        onChanged: (val) => settings.plusFabShowImportInstalled = val,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── 6. Personalize ───────────────────────────────────────────────────
        PageViewModel(
          title: 'Personalize',
          body: 'Obtainium+ adds visual polish and one-handed shortcuts. All toggleable in Settings → Obtainium+ Features.',
          image: Icon(Icons.auto_awesome_outlined, size: 100, color: colorScheme.tertiary),
          decoration: pageDecoration,
          footer: Column(
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.blur_on_outlined,
                title: 'Glassmorphism',
                subtitle: 'Frosted-glass nav bars, sheets, and menus.',
                iconColor: colorScheme.secondary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.back_hand_outlined,
                title: 'Quick Filters',
                subtitle: 'One-handed filter strip pinned at the bottom of your app list.',
                iconColor: colorScheme.secondary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.grid_view_outlined,
                title: 'Grid View',
                subtitle: 'Switch between list and grid layouts.',
                iconColor: colorScheme.secondary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.swipe_outlined,
                title: 'Swipe Actions',
                subtitle: 'Swipe app tiles to quickly update or open them.',
                iconColor: colorScheme.secondary,
              ),
            ],
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
        color: colorScheme.onSurfaceVariant,
        activeSize: const Size(22.0, 10.0),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: colorScheme.primary,
      ),
    );
  }
}
