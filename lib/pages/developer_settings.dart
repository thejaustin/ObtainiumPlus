import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/components/talker_screen.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/pages/plugin_manager.dart';
import 'package:android_package_manager/android_package_manager.dart' hide LaunchMode;
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(tr('developerAndDiagnostics'))),
      body: ListView(
        controller: scrollController,
        children: [
          _buildSection(context, tr('playStoreAndPluginsExperimental'), [
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: Text(tr('authenticationMode')),
              subtitle: Text(
                context.watch<AuthProvider>().authMode == AuthMode.anonymous
                    ? tr('anonymousDispenser')
                    : (context.watch<AuthProvider>().authMode == AuthMode.hybrid
                          ? tr('hybridSafetyFirst')
                          : tr('personalMicroG')),
              ),
              onTap: () => _showAuthModePicker(context),
            ),
            ListTile(
              leading: const Icon(Icons.token_outlined),
              title: Text(tr('manageTokenDispensers')),
              subtitle: Text(
                tr('anonymousLoginTokensAAS'),
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled:
                  context.watch<AuthProvider>().authMode != AuthMode.microG,
              onTap: () => _showDispenserManager(context),
            ),
            if (context.watch<AuthProvider>().authMode != AuthMode.anonymous)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(tr('microGAccount')),
                subtitle: Text(
                  context.watch<AuthProvider>().microGEmail ?? tr('noneSelected'),
                ),
                trailing: context.watch<AuthProvider>().microGEmail != null
                    ? IconButton(
                        icon: const Icon(Icons.link_off),
                        tooltip: tr('removeLinkedAccount'),
                        onPressed: () async {
                          await context.read<AuthProvider>().setMicroGEmail(
                            null,
                          );
                        },
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _showMicroGAccountPicker(context),
              ),
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: Text(tr('pluginManager')),
              subtitle: Text(
                tr('jsRecipesPluginManager'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => pushRoute(context, const PluginManagerPage()),
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_setup_outlined),
              title: Text(tr('deviceSpoofingMicroG')),
              subtitle: Text(
                tr('spoofGsfIdDeviceProfile'),
              ),
              onTap: () => _showSpoofingManager(context),
            ),
            if (plusSettings.plusEnableMicroGHub)
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(tr('microGDeploymentHub')),
                subtitle: Text(
                  tr('directlyDownloadInstallMicroG'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushRoute(context, const MicroGHubPage()),
              ),
            if (plusSettings.plusEnableStandaloneInstaller)
              ListTile(
                leading: const Icon(Icons.install_mobile_outlined),
                title: Text(tr('standaloneApkInstaller')),
                subtitle: Text(
                  tr('installAnyApkStorage'),
                ),
                trailing: const Icon(Icons.file_open_outlined),
                onTap: () => _handleStandaloneInstall(context),
              ),
          ]),
          _buildSection(context, tr('playStoreSafetyAndFilters'), [
            _buildSafetyScoreCard(context),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.verified_user_outlined),
              title: Text(tr('verifiedAppsOnly')),
              subtitle: Text(
                tr('onlyShowAppsVerifiedByPlayProtect'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .playStoreVerifiedOnly,
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().playStoreVerifiedOnly =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.block_outlined),
              title: Text(tr('noAdsFilter')),
              subtitle: Text(
                tr('excludeAppsContainAds'),
              ),
              value: context.watch<PlusSettingsProvider>().playStoreNoAdsFilter,
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().playStoreNoAdsFilter =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(
                Icons.system_security_update_warning_outlined,
              ),
              title: Text(tr('excludeSystemApps')),
              subtitle: Text(
                tr('preventsUpdatingCriticalSystemComponents'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .playStoreExcludeSystemApps,
              onChanged: (val) =>
                  context
                          .read<PlusSettingsProvider>()
                          .playStoreExcludeSystemApps =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.vpn_lock_outlined),
              title: Text(tr('requireVpnStrictIpPrivacy')),
              subtitle: Text(
                tr('blockAllNativePlayStoreTraffic'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .requireVPNForPlayStore,
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().requireVPNForPlayStore =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.auto_delete_outlined),
              title: Text(tr('autoDiscardTokens')),
              subtitle: Text(
                tr('immediatelyClearAuthTokens'),
              ),
              value: context.watch<PlusSettingsProvider>().autoDiscardTokens,
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().autoDiscardTokens = val,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(tr('minimumDownloadsFilter')),
              subtitle: Text(
                tr('excludeAppsFewerThanDownloads', args: [context.watch<PlusSettingsProvider>().playStoreMinDownloads.toString()]),
              ),
            ),
            Slider(
              value: context
                  .watch<PlusSettingsProvider>()
                  .playStoreMinDownloads
                  .toDouble(),
              min: 0,
              max: 1000000,
              divisions: 100,
              label: context
                  .watch<PlusSettingsProvider>()
                  .playStoreMinDownloads
                  .toString(),
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().playStoreMinDownloads =
                      val.toInt(),
            ),
          ]),
          _buildSection(context, tr('diagnostics'), [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(tr('viewTalkerLogs')),
              subtitle: Text(
                tr('realtimeNetworkRequests'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => pushRoute(context, TalkerScreen(talker: talker)),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: Text(tr('crashStatistics')),
              subtitle: Text(
                tr('localCrashFrequency'),
              ),
              onTap: () async {
                final stats = await CrashAnalytics.getStats();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => GlassDialog(
                      title: tr('localCrashStats'),
                      icon: Icons.analytics_outlined,
                      content: Text(
                        tr('localCrashStatsContent', args: [
                          stats.totalCrashes.toString(),
                          stats.lastCrashTime != null ? stats.lastCrashTime.toString() : tr('never'),
                          stats.crashTypes.isEmpty ? tr('none') : stats.crashTypes.join(", "),
                        ]),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(tr('close')),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(tr('standardAppLogs')),
              subtitle: Text(tr('legacyObtainiumLogs')),
              onTap: () => context.read<LogsProvider>().get().then((logs) {
                if (!context.mounted) return;
                if (logs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('noLogsFound'))),
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
              title: Text(tr('uploadLogsNewIssue')),
              subtitle: Text(
                tr('opensPrefilledGithubIssue'),
              ),
              onTap: () async {
                final history = talker.history.reversed
                    .take(200)
                    .toList()
                    .reversed;
                final logText = history
                    .map((e) => '[${e.title}] ${e.message}')
                    .join('\n');

                final body = Uri.encodeComponent(
                  "## Diagnostic Logs Report\n\n"
                  "**Device info:** (Include manually or check Sentry)\n\n"
                  "### Logs:\n```\n$logText\n```",
                );

                final url =
                    'https://github.com/thejaustin/ObtainiumPlus/issues/new?title=[Bug]+Diagnostic+Report&body=$body';

                if (await canLaunchUrlString(url)) {
                  await launchUrlString(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
          ]),
          _buildSection(context, tr('expressiveDesignShapes'), [
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.gesture_rounded),
              title: Text(tr('squigglyProgressBars')),
              subtitle: Text(
                tr('usePlayStoreStyleSinusoidal'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusEnableExpressiveProgress,
              onChanged: (val) =>
                  context
                          .read<PlusSettingsProvider>()
                          .plusEnableExpressiveProgress =
                      val,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.rounded_corner_rounded),
              title: Text(tr('globalCornerRadius')),
              subtitle: Text(
                tr('defaultRoundednessCards', args: [context.watch<PlusSettingsProvider>().plusGlobalCornerRadius.toInt().toString()]),
              ),
            ),
            Slider(
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusGlobalCornerRadius,
              min: 0,
              max: 40,
              divisions: 40,
              onChanged: (val) =>
                  context.read<PlusSettingsProvider>().plusGlobalCornerRadius =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.tune_rounded),
              title: Text(tr('overrideIndividualRadii')),
              subtitle: Text(
                tr('fineTuneRoundedness'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusOverrideIndividualCornerRadius,
              onChanged: (val) =>
                  context
                          .read<PlusSettingsProvider>()
                          .plusOverrideIndividualCornerRadius =
                      val,
            ),
            if (context
                .watch<PlusSettingsProvider>()
                .plusOverrideIndividualCornerRadius) ...[
              ListTile(
                leading: const Icon(Icons.home_max_rounded),
                title: Text(tr('homeScreenRadius')),
                subtitle: Text(
                  tr('roundednessDashboardElements', args: [context.watch<PlusSettingsProvider>().plusHomeCornerRadius.toInt().toString()]),
                ),
              ),
              Slider(
                value: context
                    .watch<PlusSettingsProvider>()
                    .plusHomeCornerRadius,
                min: 0,
                max: 40,
                divisions: 40,
                onChanged: (val) =>
                    context.read<PlusSettingsProvider>().plusHomeCornerRadius =
                        val,
              ),
              ListTile(
                leading: const Icon(Icons.settings_suggest_rounded),
                title: Text(tr('settingsRadius')),
                subtitle: Text(
                  tr('roundednessSettingsGroups', args: [context.watch<PlusSettingsProvider>().plusSettingsCornerRadius.toInt().toString()]),
                ),
              ),
              Slider(
                value: context
                    .watch<PlusSettingsProvider>()
                    .plusSettingsCornerRadius,
                min: 0,
                max: 40,
                divisions: 40,
                onChanged: (val) =>
                    context
                            .read<PlusSettingsProvider>()
                            .plusSettingsCornerRadius =
                        val,
              ),
            ],
          ]),
          _buildSection(context, tr('experimentalFeatures'), [
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.compare_arrows_outlined),
              title: Text(tr('legacyUiComparison')),
              subtitle: Text(
                tr('injectsFabsAppList'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusShowLegacyUIComparison,
              onChanged: (val) =>
                  context
                          .read<PlusSettingsProvider>()
                          .plusShowLegacyUIComparison =
                      val,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.science_outlined),
              title: Text(tr('advancedTheming')),
              subtitle: Text(
                tr('unlocksExperimentalAdvancedTheming'),
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusEnableExperimentalCustomization,
              onChanged: (val) =>
                  context
                          .read<PlusSettingsProvider>()
                          .plusEnableExperimentalCustomization =
                      val,
            ),
          ]),
          _buildSection(context, tr('testing'), [
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              iconColor: Colors.red,
              title: Text(tr('triggerTestCrash')),
              subtitle: Text(
                tr('forcesCrashVerify'),
              ),
              onTap: () {
                talker.warning(tr('userTriggeredTestCrash'));
                throw Exception(tr('obtainiumTestCrash'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.network_check_outlined),
              title: Text(tr('testNetworkLogging')),
              subtitle: Text(
                tr('sendsDummyRequest'),
              ),
              onTap: () async {
                talker.info(tr('triggeringTestNetworkRequest'));
                try {
                  // ignore: unused_local_variable
                  final response = await SentryHttpClient().get(
                    Uri.parse('https://api.github.com/zen'),
                  );
                  talker.info(tr('testNetworkRequestSuccessful'));
                } catch (e, st) {
                  talker.handle(e, st, tr('testNetworkRequestFailed'));
                }
              },
            ),
          ]),
          _buildSection(context, tr('externalLinks'), [
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(tr('viewSentryProject')),
              onTap: () => launchUrlString(
                'https://sentry.io/organizations/af-developments/projects/obtainiumplus/',
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(tr('githubIssueTracker')),
              onTap: () => launchUrlString(
                CrashTracker.issueTrackerUrl,
                mode: LaunchMode.externalApplication,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
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
        final plusSettings = context.read<PlusSettingsProvider>();
        final enableGlass = plusSettings.plusEnableGlassmorphism;
        final sheet = Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2),
              ),
              left: BorderSide(
                color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
              ),
              right: BorderSide(
                color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(tr('anonymousDispenser')),
                  subtitle: Text(
                    tr('useThrowawayAccounts'),
                  ),
                  trailing: authProvider.authMode == AuthMode.anonymous
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    authProvider.setAuthMode(AuthMode.anonymous);
                    Navigator.pop(context);
                    await checkAndPromptBanWarnings(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(tr('personalMicroG')),
                  subtitle: Text(
                    tr('useRealAccount'),
                  ),
                  trailing: authProvider.authMode == AuthMode.microG
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    authProvider.setAuthMode(AuthMode.microG);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text(tr('hybridSafetyFirst')),
                  subtitle: Text(
                    tr('anonymousForSearch'),
                  ),
                  trailing: authProvider.authMode == AuthMode.hybrid
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    authProvider.setAuthMode(AuthMode.hybrid);
                    Navigator.pop(context);
                    await checkAndPromptBanWarnings(context);
                  },
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
      builder: (_) => GlassDialog(
        title: tr('linkingAccount'),
        icon: Icons.sync_rounded,
        content: const Center(
          child: ExpressiveCircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );

    try {
      await authProvider.setMicroGEmail(email);
      await authProvider.refreshMicroGToken();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('linkedEmailSuccessfully', args: [email]))));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('errorWithMessage', args: [e.toString().replaceFirst('ObtainiumError: ', '')])),
          ),
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (context.mounted) {
          final plusSettings = context.read<PlusSettingsProvider>();
          final behaviorSettings = context.read<BehaviorSettingsProvider>();
          final updateSettings = context.read<UpdateSettingsProvider>();
          final logs = context.read<LogsProvider>();

          // Get APK info before installing
          final PackageInfo? info = await pm.getPackageArchiveInfo(
            archiveFilePath: file.path,
          );
          if (info == null) throw Exception('Could not read APK info');

          if (context.mounted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => GlassDialog(
                title: tr('installStandaloneApk'),
                icon: Icons.install_mobile_outlined,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('packageNameLabel', args: [info.packageName ?? ''])),
                    Text(tr('versionLabel', args: [info.versionName ?? '', info.versionCode?.toString() ?? ''])),
                    const SizedBox(height: 12),
                    Text(tr('proceedWithInstallation')),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr('cancel')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(tr('install')),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              final success = await AppInstallService.installApkStandalone(
                file,
                context,
                behaviorSettings,
                plusSettings,
                updateSettings,
                logs,
              );

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('installationCompletedSuccessfully')),
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('errorWithMessage', args: [e.toString()]))));
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

    final color = score > 80
        ? Colors.green
        : (score > 50 ? Colors.orange : Colors.red);

    final String labelKey = score > 80
        ? 'safetyExcellent'
        : (score > 50 ? 'safetyModerate' : 'safetyLow');

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
                Text(
                  tr('accountSafetyScore'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpressiveProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(AppOpacity.subtle),
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              tr('currentProtection', args: [tr(labelKey)]),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              tr('selectDeviceProfile'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...AuthProvider.deviceProfiles.map(
            (p) => ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: Text(p.name),
              subtitle: Text(
                tr('deviceProfileAndroidVersion', args: [p.manufacturer, p.model, (p.sdkVersion - 21 + 5).toString()]),
              ),
              trailing: authProvider.selectedProfile.name == p.name
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                authProvider.setDeviceProfile(p);
                Navigator.pop(context);
              },
            ),
          ),
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
  static const _platform = MethodChannel('dev.thejaustin.obtainiumplus/native');
  String _gsfId = 'Checking...';

  @override
  void initState() {
    super.initState();
    _gsfId = tr('checkingEllipsis');
    _getGsfId();
  }

  Future<void> _getGsfId() async {
    try {
      final String result = await _platform.invokeMethod('getGsfId');
      if (!mounted) return;
      setState(() => _gsfId = result);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _gsfId = tr('failedToGetGsfId', args: [e.message ?? '']));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final content = Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2),
          ),
          left: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
          ),
          right: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
          ),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phonelink_setup_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            tr('deviceIdentifierSpoofing'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(tr('currentGsfId')),
            subtitle: Text(_gsfId),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getGsfId,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shuffle_rounded),
            title: Text(tr('anonymousDeviceId')),
            subtitle: Text(
              context.watch<AuthProvider>().spoofedAndroidId ??
                  tr('noneGenerated'),
            ),
            trailing: TextButton(
              onPressed: () => context.read<AuthProvider>().rotateDeviceId(),
              child: Text(tr('rotate')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_other_rounded),
            title: Text(tr('deviceProfile')),
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
          Text(
            tr('microGSpoofingActiveExplanation'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;

    final content = Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(enableGlass ? 0.78 : 1.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.18 : 0.2),
          ),
          left: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
          ),
          right: BorderSide(
            color: cs.onSurface.withOpacity(enableGlass ? 0.12 : 0.0),
          ),
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
            tr('tokenDispensers'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            tr('dispensersProvideAnonymousTokens'),
            textAlign: TextAlign.center,
          ),
          if (authProvider.hasActiveToken)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                avatar: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                label: Text(tr('activeTokenReady')),
                onDeleted: () => authProvider.clearBundle(),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: authProvider.dispensers
                  .map(
                    (d) => ListTile(
                      title: Text(d),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: ExpressiveCircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => authProvider.removeDispenser(d),
                          ),
                        ],
                      ),
                      onTap: _isLoading
                          ? null
                          : () => _testDispenser(context, authProvider, d),
                    ),
                  )
                  .toList(),
            ),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: tr('addDispenserUrl'),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  if (_controller.text.isNotEmpty) {
                    authProvider.addDispenser(_controller.text);
                    _controller.clear();
                    await checkAndPromptBanWarnings(context);
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

  Future<void> _testDispenser(
    BuildContext context,
    AuthProvider authProvider,
    String url,
  ) async {
    setState(() => _isLoading = true);
    try {
      await authProvider.refreshBundle(url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('successfullyRetrievedToken'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('errorWithMessage', args: [e.toString()]))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

Future<void> checkAndPromptBanWarnings(BuildContext context) async {
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

