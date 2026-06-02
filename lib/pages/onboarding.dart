import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/main.dart';

import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/utils/app_constants.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with WidgetsBindingObserver {
  final introKey = GlobalKey<IntroductionScreenState>();
  bool _isSamsung = false;
  bool _isXiaomi = false;
  bool _microGAvailable = false;

  bool _addObtainiumPlus = true;

  // Permission statuses
  bool _installGranted = false;
  bool _notifGranted = false;
  bool _batteryGranted = false;
  bool _usageGranted = false;

  final _dispenserController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDevice();
    _checkPermissions();
  }

  @override
  void dispose() {
    _dispenserController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final install = await Permission.requestInstallPackages.isGranted;
    final notif = await Permission.notification.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    final usage = await AppInstallService.isUsageAccessGranted();

    if (mounted) {
      setState(() {
        _installGranted = install;
        _notifGranted = notif;
        _batteryGranted = battery;
        _usageGranted = usage;
      });
    }
  }

  Future<void> _checkDevice() async {
    final info = await DeviceInfoPlugin().androidInfo;
    final manufacturer = info.manufacturer.toLowerCase();
    final microG = await AuthService.isMicroGAvailable();
    if (!mounted) return;
    setState(() {
      _isSamsung = manufacturer.contains('samsung');
      _isXiaomi = [
        'xiaomi',
        'redmi',
        'poco',
      ].any((x) => manufacturer.contains(x));
      _microGAvailable = microG;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isLimited) {
      await Permission.notification.request();
    } else if (status.isPermanentlyDenied) {
      // If permanently denied, request() won't show anything.
      // We could optionally show a snackbar or open settings,
      // but the user wants dialogs/popups where possible.
      await openAppSettings();
    }
    await _checkPermissions();
  }

  Future<void> _requestInstallPermission() async {
    // Android doesn't allow a popup for this; it MUST go to settings.
    await AppInstallService.openInstallUnknownAppsSettings(obtainiumId);
    // Re-check will happen when the user returns to the app
  }

  Future<void> _openUsageAccess() async {
    await AppInstallService.openUsageAccessSettings();
    // This will open a new activity, so re-check will happen on resume
  }

  Future<void> _openBatteryOptimization() async {
    if (_isXiaomi) {
      // Xiaomi/MIUI often blocks the standard dialog or ignores it;
      // it's safer to open their specific settings.
      await AppInstallService.openBatteryOptimizationSettings();
    } else {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        // This triggers the standard Android "Allow app to ignore battery optimizations?" popup
        await Permission.ignoreBatteryOptimizations.request();
      } else {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      await _checkPermissions();
    }
  }

  Future<void> _finishOnboarding() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: ExpressiveCircularProgressIndicator()),
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
          talker.warning('Error adding Obtainium+ during onboarding: $e');
        }
      }

      if (appsToAdd.isNotEmpty) {
        await appsProvider.saveApps(appsToAdd, onlyIfExists: false);
      }

      // Ensure the flag is set so we don't show onboarding again
      context.read<SettingsProvider>().welcomeShown = true;
    } catch (e) {
      talker.warning('Error during onboarding finish: $e');
    } finally {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        widget.onDone();
      }
    }
  }

  void _handleFeatureTap(String feature) {
    // Navigate to the relevant page after onboarding is finished
    _finishOnboarding().then((_) {
      // The onDone callback in HomePage will handle the actual navigation if needed
      // or we can just let the user know they can find it in the + menu.
    });
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget cardContent = ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? colorScheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      dense: true,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 18)
          : null,
    );

    Widget container = Container(
      decoration: BoxDecoration(
        color: (isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface)
            .withOpacity(enableGlass ? 0.45 : 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(enableGlass ? 0.3 : 0.1),
          width: 1,
        ),
        boxShadow: enableGlass
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: cardContent,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: enableGlass
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: container,
              ),
            )
          : container,
    );
  }

  Widget _buildPermissionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isGranted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(
          isGranted ? Icons.check_circle : icon,
          color: isGranted ? Colors.green : null,
        ),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: isGranted
              ? BorderSide(color: Colors.green.withOpacity(AppOpacity.half))
              : null,
        ),
      ),
    );
  }

  Widget _buildFabToggle({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
        letterSpacing: -0.5,
      ),
      bodyTextStyle: const TextStyle(fontSize: 15.0, height: 1.5),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
      pageColor: colorScheme.surface,
      imagePadding: const EdgeInsets.only(top: 48.0, bottom: 24.0),
      imageFlex: 3,
      bodyFlex: 4,
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
          title: 'Welcome to Obtainium+',
          body:
              'The premium, high-performance way to manage Android apps directly from their source.\n\n✨ Enhanced stability\n✨ Reorganized Settings\n✨ Universal Search-as-you-type\n✨ Pro Status Dashboard',
          image: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 100,
              color: colorScheme.primary,
            ),
          ),
          decoration: pageDecoration,
        ),

        // ── 2. Add Apps ──────────────────────────────────────────────────────
        PageViewModel(
          title: 'Add Apps',
          image: Icon(
            Icons.add_circle_outline,
            size: 80,
            color: colorScheme.secondary,
          ),
          decoration: pageDecoration,
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('onboardingAddAppsSubtitle'),
                textAlign: TextAlign.center,
                style: pageDecoration.bodyTextStyle,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.link_outlined,
                title: tr('addAppByUrl'),
                subtitle: tr('onboardingPasteUrlSubtitle'),
                onTap: () => _handleFeatureTap('addByUrl'),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.star_border_rounded,
                title: tr('githubStarredRepos'),
                subtitle: tr('onboardingStarredReposSubtitle'),
                iconColor: colorScheme.tertiary,
                onTap: () => _handleFeatureTap('githubStarred'),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.person_outline_rounded,
                title: tr('githubPersonalRepos'),
                subtitle: tr('onboardingPersonalReposSubtitle'),
                iconColor: colorScheme.tertiary,
                onTap: () => _handleFeatureTap('githubPersonal'),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.install_mobile_outlined,
                title: tr('importInstalledApps'),
                subtitle: tr('onboardingImportInstalledSubtitle'),
                onTap: () => _handleFeatureTap('importInstalled'),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.cloud_sync_outlined,
                title: tr('backupAndSync'),
                subtitle: tr('onboardingCloudSyncSubtitle'),
                iconColor: colorScheme.secondary,
                onTap: () => _handleFeatureTap('importExport'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Card(
                  color: colorScheme.secondaryContainer,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      Icons.key_outlined,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    title: Text(
                      tr('githubTokenOptional'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      tr('githubTokenSettingsNote'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    dense: true,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 3. Play Store & microG ─────────────────────────────────────────────
        PageViewModel(
          title: 'Play Store & microG',
          image: Icon(
            Icons.shop_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          decoration: pageDecoration,
          bodyWidget: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final plusSettings = context.watch<PlusSettingsProvider>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('onboardingPlayStoreSubtitle'),
                    textAlign: TextAlign.center,
                    style: pageDecoration.bodyTextStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context,
                    icon: _microGAvailable
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    title: tr('status'),
                    subtitle: _microGAvailable
                        ? tr('microGDetected')
                        : tr('microGNotFound'),
                    iconColor: _microGAvailable ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  _buildPermissionButton(
                    context: context,
                    icon: Icons.account_circle_outlined,
                    label: tr('signInViaMicroG'),
                    onPressed: () async {
                      try {
                        final email = await AuthService.pickGoogleAccount();
                        if (email != null) {
                          await auth.setMicroGEmail(email);
                          await auth.refreshMicroGToken();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Linked to $email')),
                            );
                          }
                        }
                      } catch (e) {
                        String message = e.toString();
                        if (message.contains('UnregisteredOnApiConsole')) {
                          message =
                              'microG error: This app is not registered in the Google API Console. '
                              'If you are using a custom build of Obtainium+, you may need to '
                              'configure your own OAuth credentials or use anonymous dispensers.';
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 10),
                              action: SnackBarAction(
                                label: 'Details',
                                onPressed: () {
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => GlassDialog(
                                        title: 'microG Error',
                                        icon: Icons.error_outline,
                                        content: Text(e.toString()),
                                        actions: [
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (globalNavigatorKey
                                          .currentContext !=
                                      null) {
                                    showDialog(
                                      context:
                                          globalNavigatorKey.currentContext!,
                                      builder: (ctx) => GlassDialog(
                                        title: 'microG Error',
                                        icon: Icons.error_outline,
                                        content: Text(e.toString()),
                                        actions: [
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    tr('tokenDispensers'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('dispensersProvideAnonymousTokens'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (auth.dispensers.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          plusSettings.plusEnableMaterialExpressive ? 24 : 16,
                        ),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          children: auth.dispensers
                              .map(
                                (d) => ListTile(
                                  dense: true,
                                  title: Text(
                                    d,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => auth.removeDispenser(d),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dispenserController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: tr('addDispenserUrl'),
                      hintText: 'https://your-dispenser.com/api/auth',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          plusSettings.plusEnableMaterialExpressive ? 28 : 12,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          if (_dispenserController.text.isNotEmpty) {
                            auth.addDispenser(_dispenserController.text);
                            _dispenserController.clear();
                            await _checkAndPromptBanWarnings();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── 4. Permissions ────────────────────────────────────────────────────
        PageViewModel(
          title: 'Permissions',
          image: Icon(
            Icons.security_outlined,
            size: 80,
            color: colorScheme.tertiary,
          ),
          decoration: pageDecoration,
          bodyWidget: Builder(
            builder: (ctx) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('onboardingPermissionsSubtitle'),
                  textAlign: TextAlign.center,
                  style: pageDecoration.bodyTextStyle,
                ),
                const SizedBox(height: 12),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.install_mobile_rounded,
                  label: tr('allowInstallingAppsSettings'),
                  onPressed: _requestInstallPermission,
                  isGranted: _installGranted,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.notifications_outlined,
                  label: tr('allowNotifications'),
                  onPressed: _requestNotificationPermission,
                  isGranted: _notifGranted,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.battery_saver_outlined,
                  label: tr('disableBatteryOptimisation'),
                  onPressed: _openBatteryOptimization,
                  isGranted: _batteryGranted,
                ),
                _buildPermissionButton(
                  context: ctx,
                  icon: Icons.track_changes_outlined,
                  label: tr('allowUsageAccessSettings'),
                  onPressed: _openUsageAccess,
                  isGranted: _usageGranted,
                ),
                if (_isXiaomi)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Card(
                      color: colorScheme.tertiaryContainer,
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        title: Text(
                          tr('xiaomiTip'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          tr('enableAutoStartInSecurity'),
                          style: const TextStyle(fontSize: 11),
                        ),
                        dense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── 5. Stay Updated ──────────────────────────────────────────────────
        PageViewModel(
          title: 'Stay Updated',
          image: Icon(Icons.sync_lock, size: 80, color: colorScheme.primary),
          decoration: pageDecoration,
          bodyWidget: Consumer<UpdateSettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('onboardingStayUpdatedSubtitle'),
                    textAlign: TextAlign.center,
                    style: pageDecoration.bodyTextStyle,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    title: Text(
                      tr('backgroundChecks'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    value: settings.updateInterval > 0,
                    onChanged: (val) => settings.updateInterval = val ? 360 : 0,
                    dense: true,
                  ),
                  if (settings.updateInterval > 0) ...[
                    const SizedBox(height: 4),
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
                        tr(
                          'checkEveryXHours',
                          args: [
                            (settings.updateInterval / 60).round().toString(),
                          ],
                        ),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // ── 6. Quick-Add Menu ────────────────────────────────────────────────
        PageViewModel(
          title: 'Quick-Add Menu',
          image: Icon(
            Icons.add_box_outlined,
            size: 80,
            color: colorScheme.secondary,
          ),
          decoration: pageDecoration,
          bodyWidget: Consumer<PlusSettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  Text(
                    tr('onboardingQuickAddSubtitle'),
                    textAlign: TextAlign.center,
                    style: pageDecoration.bodyTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: colorScheme.surfaceContainerHigh,
                    child: Column(
                      children: [
                        _buildFabToggle(
                          context: context,
                          icon: Icons.search_rounded,
                          title: tr('search'),
                          subtitle: tr('quickLaunchSearch'),
                          value: settings.plusFabShowSearch,
                          onChanged: (val) => settings.plusFabShowSearch = val,
                        ),
                        _buildFabToggle(
                          context: context,
                          icon: Icons.link_outlined,
                          title: tr('addByUrl'),
                          subtitle: tr('pasteReleaseUrl'),
                          value: settings.plusFabShowAddByUrl,
                          onChanged: (val) =>
                              settings.plusFabShowAddByUrl = val,
                        ),
                        _buildFabToggle(
                          context: context,
                          icon: Icons.star_border_rounded,
                          title: tr('githubStarred'),
                          subtitle: tr('importStarredRepos'),
                          value: settings.plusFabShowGithubStarred,
                          onChanged: (val) =>
                              settings.plusFabShowGithubStarred = val,
                        ),
                        _buildFabToggle(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          title: tr('githubPersonal'),
                          subtitle: tr('importOwnRepos'),
                          value: settings.plusFabShowGithubPersonalRepos,
                          onChanged: (val) =>
                              settings.plusFabShowGithubPersonalRepos = val,
                        ),
                        _buildFabToggle(
                          context: context,
                          icon: Icons.install_mobile_outlined,
                          title: tr('importInstalled'),
                          subtitle: tr('scanDevice'),
                          value: settings.plusFabShowImportInstalled,
                          onChanged: (val) =>
                              settings.plusFabShowImportInstalled = val,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── 7. Personalize ───────────────────────────────────────────────────
        PageViewModel(
          title: 'Personalize',
          image: Icon(
            Icons.palette_rounded,
            size: 80,
            color: colorScheme.tertiary,
          ),
          decoration: pageDecoration,
          bodyWidget: Consumer<PlusSettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  Text(
                    'Customize your high-performance experience.',
                    textAlign: TextAlign.center,
                    style: pageDecoration.bodyTextStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context,
                    icon: Icons.density_medium_rounded,
                    title: 'Compact Mode',
                    subtitle: 'Reduce padding for higher information density',
                    iconColor: colorScheme.primary,
                    onTap: () => settings.plusUseCompactSettings =
                        !settings.plusUseCompactSettings,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Status Hub',
                    subtitle: 'Show summary stats at the top of the dashboard',
                    iconColor: colorScheme.secondary,
                    onTap: () => settings.plusShowStatusHub =
                        !settings.plusShowStatusHub,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.blur_on_outlined,
                    title: tr('glassmorphismUI'),
                    subtitle: tr('glassmorphismSubtitle'),
                    iconColor: colorScheme.tertiary,
                    onTap: () => settings.plusEnableGlassmorphism =
                        !settings.plusEnableGlassmorphism,
                  ),
                ],
              );
            },
          ),
        ),

        // ── 8. Advanced Features ─────────────────────────────────────────────
        PageViewModel(
          title: tr('advancedFeatures'),
          image: Icon(
            Icons.auto_awesome_motion_outlined,
            size: 80,
            color: colorScheme.secondary,
          ),
          decoration: pageDecoration,
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('advancedFeaturesSubtitle'),
                textAlign: TextAlign.center,
                style: pageDecoration.bodyTextStyle,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.label_outline,
                title: tr('tagSystem'),
                subtitle: tr('tagSystemSubtitle'),
                iconColor: colorScheme.primary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.library_add_check_outlined,
                title: tr('bulkOperations'),
                subtitle: tr('bulkOperationsSubtitle'),
                iconColor: colorScheme.secondary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.touch_app_outlined,
                title: tr('quickActionsMenu'),
                subtitle: tr('quickActionsMenuSubtitle'),
                iconColor: colorScheme.tertiary,
              ),
              _buildFeatureCard(
                context,
                icon: Icons.rule_outlined,
                title: tr('autoUpdateRulesOnboarding'),
                subtitle: tr('autoUpdateRulesOnboardingSubtitle'),
                iconColor: colorScheme.error,
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

  Future<void> _checkAndPromptBanWarnings() async {
    final plusSettings = context.read<PlusSettingsProvider>();
    if (!plusSettings.plusEnableBanWarnings) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => GlassDialog(
          title: tr('plusEnableBanWarnings'),
          icon: Icons.warning_amber_rounded,
          content: Text(
            '${tr('plusEnableBanWarningsDescription')}\n\nWould you like to enable Dispenser Ban Warnings now for extra protection?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('enable')),
            ),
          ],
        ),
      );
      if (confirm == true) {
        plusSettings.plusEnableBanWarnings = true;
      }
    }
  }
}
