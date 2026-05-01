import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/pages/plugin_manager.dart';
import 'package:obtainium/pages/microg_hub.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';

class DeveloperSettingsPage extends StatelessWidget {
  final ScrollController? scrollController;
  const DeveloperSettingsPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer & Diagnostics'),
      ),
      body: ListView(
        controller: scrollController,
        children: [
          _buildSection(
            context,
            'Play Store & Plugins (Experimental)',
            [
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Authentication Mode'),
                subtitle: Text(context.watch<AuthProvider>().authMode == AuthMode.anonymous 
                    ? 'Anonymous (Dispenser)' 
                    : (context.watch<AuthProvider>().authMode == AuthMode.hybrid ? 'Hybrid (Safety First)' : 'Personal (microG)')),
                onTap: () => _showAuthModePicker(context),
              ),
              ListTile(
                leading: const Icon(Icons.token_outlined),
                title: const Text('Manage Token Dispensers'),
                subtitle: const Text('Anonymous login tokens (AAS) for Google Play Store access'),
                trailing: const Icon(Icons.chevron_right),
                enabled: context.watch<AuthProvider>().authMode != AuthMode.microG,
                onTap: () => _showDispenserManager(context),
              ),
              if (context.watch<AuthProvider>().authMode != AuthMode.anonymous)
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('microG Account'),
                  subtitle: Text(context.watch<AuthProvider>().microGEmail ?? 'None selected'),
                  trailing: context.watch<AuthProvider>().microGEmail != null
                      ? IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: 'Remove linked account',
                          onPressed: () async {
                            await context.read<AuthProvider>().setMicroGEmail(null);
                          },
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () => _showMicroGAccountPicker(context),
                ),
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('Plugin Manager'),
                subtitle: const Text('JS "Recipes" that add new sources without a full app update'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushRoute(context, const PluginManagerPage()),
              ),
              ListTile(
                leading: const Icon(Icons.phonelink_setup_outlined),
                title: const Text('Device Spoofing (microG)'),
                subtitle: const Text('Spoof GSF ID / device profile for regional app compatibility'),
                onTap: () => _showSpoofingManager(context),
              ),
              if (settingsProvider.plusEnableMicroGHub)
                ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: const Text('microG Deployment Hub'),
                  subtitle: const Text('Directly download and install microG / GmsCore components'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MicroGHubPage()),
                  ),
                ),
              if (settingsProvider.plusEnableStandaloneInstaller)
                ListTile(
                  leading: const Icon(Icons.install_mobile_outlined),
                  title: const Text('Standalone APK Installer'),
                  subtitle: const Text('Install any APK from storage using Shizuku / System'),
                  trailing: const Icon(Icons.file_open_outlined),
                  onTap: () => _handleStandaloneInstall(context),
                ),
            ],
          ),
          _buildSection(
            context,
            'Play Store Safety & Filters',
            [
              _buildSafetyScoreCard(context),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.verified_user_outlined),
                title: const Text('Verified Apps Only'),
                subtitle: const Text('Only show apps verified by Play Protect in search results.'),
                value: context.watch<PlusSettingsProvider>().playStoreVerifiedOnly,
                onChanged: (val) => context.read<PlusSettingsProvider>().playStoreVerifiedOnly = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.block_outlined),
                title: const Text('No Ads Filter'),
                subtitle: const Text('Exclude apps that contain advertisements from search.'),
                value: context.watch<PlusSettingsProvider>().playStoreNoAdsFilter,
                onChanged: (val) => context.read<PlusSettingsProvider>().playStoreNoAdsFilter = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.system_security_update_warning_outlined),
                title: const Text('Exclude System Apps'),
                subtitle: const Text('Prevents updating critical system components via the native bridge.'),
                value: context.watch<PlusSettingsProvider>().playStoreExcludeSystemApps,
                onChanged: (val) => context.read<PlusSettingsProvider>().playStoreExcludeSystemApps = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.vpn_lock_outlined),
                title: const Text('Require VPN (Strict IP Privacy)'),
                subtitle: const Text('Block all native Play Store traffic unless connected to a VPN/Proxy.'),
                value: context.watch<PlusSettingsProvider>().requireVPNForPlayStore,
                onChanged: (val) => context.read<PlusSettingsProvider>().requireVPNForPlayStore = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.auto_delete_outlined),
                title: const Text('Auto-Discard Tokens'),
                subtitle: const Text('Immediately clear authentication tokens after each successful request.'),
                value: context.watch<PlusSettingsProvider>().autoDiscardTokens,
                onChanged: (val) => context.read<PlusSettingsProvider>().autoDiscardTokens = val,
              ),
            ],
          ),
          _buildSection(
            context,
            'Diagnostics',
            [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('View Talker Logs'),
                subtitle: const Text('Real-time network requests, UI events, and errors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushRoute(context, TalkerScreen(talker: talker)),
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Crash Statistics'),
                subtitle: const Text('Local crash frequency and error type breakdown'),
                onTap: () async {
                  final stats = await CrashAnalytics.getStats();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => GlassDialog(
                        title: 'Local Crash Stats',
                        icon: Icons.analytics_outlined,
                        content: Text(
                          'Total Crashes: ${stats.totalCrashes}\n'
                          'Last Crash: ${stats.lastCrashTime ?? "Never"}\n'
                          'Types: ${stats.crashTypes.join(", ")}',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Standard App Logs'),
                subtitle: const Text('Legacy obtainium logs'),
                onTap: () => context.read<LogsProvider>().get().then((logs) {
                  if (logs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No logs found')),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TalkerScreen(talker: talker),
                      ),
                    );
                  }
                }),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload Logs to New Issue'),
                subtitle: const Text('Opens a pre-filled GitHub issue with current diagnostic logs'),
                onTap: () async {
                  final history = talker.history.reversed.take(200).toList().reversed;
                  final logText = history.map((e) => '[${e.title}] ${e.message}').join('\n');
                  
                  final body = Uri.encodeComponent(
                    "## Diagnostic Logs Report\n\n"
                    "**Device info:** (Include manually or check Sentry)\n\n"
                    "### Logs:\n```\n$logText\n```"
                  );
                  
                  final url = 'https://github.com/thejaustin/ObtainiumPlus/issues/new?title=[Bug]+Diagnostic+Report&body=$body';
                  
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          _buildSection(
            context,
            'Expressive Design & Shapes',
            [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.gesture_rounded),
                title: const Text('Squiggly Progress Bars'),
                subtitle: const Text('Use Play Store-style sinusoidal animations for loading and downloads.'),
                value: context.watch<PlusSettingsProvider>().plusEnableExpressiveProgress,
                onChanged: (val) => context.read<PlusSettingsProvider>().plusEnableExpressiveProgress = val,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.rounded_corner_rounded),
                title: const Text('Global Corner Radius'),
                subtitle: Text('Default roundedness for cards and containers (${context.watch<PlusSettingsProvider>().plusGlobalCornerRadius.toInt()}px)'),
              ),
              Slider(
                value: context.watch<PlusSettingsProvider>().plusGlobalCornerRadius,
                min: 0,
                max: 40,
                divisions: 40,
                onChanged: (val) => context.read<PlusSettingsProvider>().plusGlobalCornerRadius = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.tune_rounded),
                title: const Text('Override Individual Radii'),
                subtitle: const Text('Fine-tune roundedness for specific areas of the app.'),
                value: context.watch<PlusSettingsProvider>().plusOverrideIndividualCornerRadius,
                onChanged: (val) => context.read<PlusSettingsProvider>().plusOverrideIndividualCornerRadius = val,
              ),
              if (context.watch<PlusSettingsProvider>().plusOverrideIndividualCornerRadius) ...[
                ListTile(
                  leading: const Icon(Icons.home_max_rounded),
                  title: const Text('Home Screen Radius'),
                  subtitle: Text('Roundedness for dashboard and app list elements (${context.watch<PlusSettingsProvider>().plusHomeCornerRadius.toInt()}px)'),
                ),
                Slider(
                  value: context.watch<PlusSettingsProvider>().plusHomeCornerRadius,
                  min: 0,
                  max: 40,
                  divisions: 40,
                  onChanged: (val) => context.read<PlusSettingsProvider>().plusHomeCornerRadius = val,
                ),
                ListTile(
                  leading: const Icon(Icons.settings_suggest_rounded),
                  title: const Text('Settings Radius'),
                  subtitle: Text('Roundedness for settings groups and cards (${context.watch<PlusSettingsProvider>().plusSettingsCornerRadius.toInt()}px)'),
                ),
                Slider(
                  value: context.watch<PlusSettingsProvider>().plusSettingsCornerRadius,
                  min: 0,
                  max: 40,
                  divisions: 40,
                  onChanged: (val) => context.read<PlusSettingsProvider>().plusSettingsCornerRadius = val,
                ),
              ],
            ],
          ),
          _buildSection(
            context,
            'Experimental Features',
            [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.compare_arrows_outlined),
                title: const Text('Legacy UI Comparison'),
                subtitle: const Text('Injects FABs on the app list, app detail, and add-app pages to preview the old UI side-by-side.'),
                value: context.watch<PlusSettingsProvider>().plusShowLegacyUIComparison,
                onChanged: (val) => context.read<PlusSettingsProvider>().plusShowLegacyUIComparison = val,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.science_outlined),
                title: const Text('Advanced Theming'),
                subtitle: const Text('Unlocks the experimental Advanced Theming section in Settings → Appearance. May have visual regressions.'),
                value: context.watch<PlusSettingsProvider>().plusEnableExperimentalCustomization,
                onChanged: (val) => context.read<PlusSettingsProvider>().plusEnableExperimentalCustomization = val,
              ),
            ],
          ),
          _buildSection(
            context,
            'Testing',
            [
              ListTile(
                leading: const Icon(Icons.flash_on_outlined),
                iconColor: Colors.red,
                title: const Text('Trigger Test Crash'),
                subtitle: const Text('Forces a crash to verify Sentry and Talker are capturing errors'),
                onTap: () {
                  talker.warning('User triggered a test crash');
                  throw Exception('Obtainium+ Test Crash');
                },
              ),
              ListTile(
                leading: const Icon(Icons.network_check_outlined),
                title: const Text('Test Network Logging'),
                subtitle: const Text('Sends a dummy request to verify network interception logging'),
                onTap: () async {
                  talker.info('Triggering test network request...');
                  try {
                    // ignore: unused_local_variable
                    final response = await SentryHttpClient().get(Uri.parse('https://api.github.com/zen'));
                    talker.info('Test network request successful');
                  } catch (e, st) {
                    talker.handle(e, st, 'Test network request failed');
                  }
                },
              ),
            ],
          ),
          _buildSection(
            context,
            'External Links',
            [
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('View Sentry Project'),
                onTap: () => launchUrlString(
                  'https://sentry.io/organizations/af-developments/projects/obtainiumplus/',
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('GitHub Issue Tracker'),
                onTap: () => launchUrlString(
                  CrashTracker.issueTrackerUrl,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showAuthModePicker(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final enableGlass = context.read<SettingsProvider>().plusEnableGlassmorphism;
        final sheet = Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2)),
              left: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
              right: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('Anonymous (Dispenser)'),
                  subtitle: const Text('Use throwaway accounts only. Safest for your personal account.'),
                  trailing: authProvider.authMode == AuthMode.anonymous ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () { authProvider.setAuthMode(AuthMode.anonymous); Navigator.pop(context); },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Personal (microG)'),
                  subtitle: const Text('Use your real account for all actions. Highest risk.'),
                  trailing: authProvider.authMode == AuthMode.microG ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () { authProvider.setAuthMode(AuthMode.microG); Navigator.pop(context); },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Hybrid (Safety First)'),
                  subtitle: const Text('Anonymous for search/browsing, Personal only for paid apps.'),
                  trailing: authProvider.authMode == AuthMode.hybrid ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () { authProvider.setAuthMode(AuthMode.hybrid); Navigator.pop(context); },
                ),
              ],
            ),
          ),
        );
        final clipped = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: sheet,
        );
        if (!enableGlass) return clipped;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: sheet,
          ),
        );
      },
    );
  }

  void _showMicroGAccountPicker(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Native account picker — backed by microG's registered Google accounts.
    final String? email = await AuthService.pickGoogleAccount();
    if (email == null || !context.mounted) return;

    // Show a non-dismissible loading dialog while we wait for the token.
    // If microG needs a consent screen it launches on top of this; the dialog
    // resumes behind it and is dismissed when the token arrives or fails.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          ExpressiveCircularProgressIndicator(),
          SizedBox(width: 16),
          Flexible(child: Text('Linking account…')),
        ]),
      ),
    );

    try {
      await authProvider.setMicroGEmail(email);
      await authProvider.refreshMicroGToken();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Linked $email successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ObtainiumError: ', ''))),
        );
      }
    }
  }

  void _showDispenserManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => const _DispenserManagerSheet(),
    );
  }

  void _handleStandaloneInstall(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (context.mounted) {
          final settings = context.read<SettingsProvider>();
          final logs = context.read<LogsProvider>();
          
          final success = await AppInstallService.installApkStandalone(
            file,
            context,
            settings,
            logs,
          );

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Installation completed successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSpoofingManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => const _SpoofingManagerSheet(),
    );
  }

  Widget _buildSafetyScoreCard(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    int score = 0;
    if (authProvider.authMode == AuthMode.hybrid) score += 30;
    if (authProvider.authMode == AuthMode.anonymous) score += 40;
    if (plusSettings.playStoreVerifiedOnly) score += 10;
    if (plusSettings.requireVPNForPlayStore) score += 30;
    if (plusSettings.autoDiscardTokens) score += 20;
    
    if (score > 100) score = 100;

    final color = score > 80 ? Colors.green : (score > 50 ? Colors.orange : Colors.red);
    final label = score > 80 ? 'Excellent' : (score > 50 ? 'Moderate' : 'Low');

    return Card(
      elevation: 0,
      color: color.withOpacity(AppOpacity.subtle),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(AppOpacity.medium)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Account Safety Score', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$score%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            ExpressiveProgressIndicator(value: score / 100, backgroundColor: color.withOpacity(AppOpacity.subtle), color: color),
            const SizedBox(height: 8),
            Text('Current Protection: $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showDeviceProfilePicker(BuildContext context) =>
      showDeviceProfilePicker(context);
}

/// Top-level so it can be called from both [DeveloperSettingsPage] and
/// [_SpoofingManagerSheetState] without the private-method access problem.
void showDeviceProfilePicker(BuildContext context) {
  final authProvider = context.read<AuthProvider>();
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select Device Profile',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...AuthProvider.deviceProfiles.map((p) => ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: Text(p.name),
                subtitle: Text(
                    '${p.manufacturer} ${p.model} (Android ${p.sdkVersion - 21 + 5})'),
                trailing: authProvider.selectedProfile.name == p.name
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  authProvider.setDeviceProfile(p);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    ),
  );
}

class _SpoofingManagerSheet extends StatefulWidget {
  const _SpoofingManagerSheet();

  @override
  State<_SpoofingManagerSheet> createState() => _SpoofingManagerSheetState();
}

class _SpoofingManagerSheetState extends State<_SpoofingManagerSheet> {
  static const _platform = MethodChannel('app.obtainiumplus/native');
  String _gsfId = 'Checking...';

  @override
  void initState() {
    super.initState();
    _getGsfId();
  }

  Future<void> _getGsfId() async {
    try {
      final String result = await _platform.invokeMethod('getGsfId');
      if (!mounted) return;
      setState(() => _gsfId = result);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _gsfId = 'Failed to get GSF ID: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enableGlass = context.select<SettingsProvider, bool>((s) => s.plusEnableGlassmorphism);
    final content = Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2)),
          left: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
          right: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phonelink_setup_outlined, size: 48),
          const SizedBox(height: 16),
          Text('Device Identifier Spoofing', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Current GSF ID'),
            subtitle: Text(_gsfId),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getGsfId,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shuffle_rounded),
            title: const Text('Anonymous Device ID'),
            subtitle: Text(context.watch<AuthProvider>().spoofedAndroidId ?? 'None generated'),
            trailing: TextButton(
              onPressed: () => context.read<AuthProvider>().rotateDeviceId(),
              child: const Text('ROTATE'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_other_rounded),
            title: const Text('Device Profile'),
            subtitle: Text(context.watch<AuthProvider>().selectedProfile.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 150), () {
                if (context.mounted) showDeviceProfilePicker(context);
              });
            },
          ),
          const Divider(),
          const Text(
            'microG Spoofing is active when a custom GSF ID or Device Profile is selected. This allows the app to bypass regional and device restrictions on the Play Store.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
    final clipped = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: content,
    );
    if (!enableGlass) return clipped;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: content,
      ),
    );
  }
}

class _DispenserManagerSheet extends StatefulWidget {
  const _DispenserManagerSheet();

  @override
  State<_DispenserManagerSheet> createState() => _DispenserManagerSheetState();
}

class _DispenserManagerSheetState extends State<_DispenserManagerSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final enableGlass = context.select<SettingsProvider, bool>((s) => s.plusEnableGlassmorphism);

    final content = Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2)),
          left: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
          right: BorderSide(color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0)),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Token Dispensers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Dispensers provide anonymous login tokens for Google Play access.',
            textAlign: TextAlign.center,
          ),
          if (authProvider.hasActiveToken)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                label: Text('Active Token Ready'),
                onDeleted: () => authProvider.clearBundle(),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: authProvider.dispensers.map((d) => ListTile(
                title: Text(d),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const SizedBox(width: 20, height: 20, child: ExpressiveCircularProgressIndicator(strokeWidth: 2)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => authProvider.removeDispenser(d),
                    ),
                  ],
                ),
                onTap: _isLoading ? null : () => _testDispenser(context, authProvider, d),
              )).toList(),
            ),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add Dispenser URL',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    authProvider.addDispenser(_controller.text);
                    _controller.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
    final clipped = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: content,
    );
    if (!enableGlass) return clipped;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: content,
      ),
    );
  }

  Future<void> _testDispenser(BuildContext context, AuthProvider authProvider, String url) async {
    setState(() => _isLoading = true);
    try {
      await authProvider.refreshBundle(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully retrieved token!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
