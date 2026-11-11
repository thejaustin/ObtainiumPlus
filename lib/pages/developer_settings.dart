import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'dart:async';
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
import 'package:android_package_manager/android_package_manager.dart'
    hide LaunchMode;
import 'package:obtainium/pages/microg_hub.dart';
import 'package:obtainium/pages/visual_lab_page.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/play_store_diagnostic_sheet.dart';
import 'package:obtainium/components/settings/play_store_inspector_sheet.dart';
import 'package:obtainium/components/settings/multi_user_diagnostic_sheet.dart';

class DeveloperSettingsPage extends StatelessWidget {
  final ScrollController? scrollController;
  const DeveloperSettingsPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(0.0, double.infinity)
        : 0.0;
    return Scaffold(
      appBar: AppBar(title: Text(tr('developerAndDiagnostics'))),
      body: ListView(
        controller: scrollController,
        physics: plusSettings.scrollPhysics,
        padding: EdgeInsets.symmetric(horizontal: adaptiveMargin),
        children: [
          _buildSection(context, tr('visualLab'), [
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(tr('visualLab')),
              subtitle: Text(
                tr('visualLabDescription'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => pushRoute(context, const VisualLabPage()),
            ),
          ]),
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
              subtitle: Text(tr('anonymousLoginTokensAAS')),
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
                  context.watch<AuthProvider>().microGEmail ??
                      tr('noneSelected'),
                ),
                trailing: context.watch<AuthProvider>().microGEmail != null
                    ? ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.88,
                        child: IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: tr('removeLinkedAccount'),
                          onPressed: () async {
                            await context.read<AuthProvider>().setMicroGEmail(
                              null,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _showMicroGAccountPicker(context),
              ),
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: Text(tr('pluginManager')),
              subtitle: Text(tr('jsRecipesPluginManager')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => pushRoute(context, const PluginManagerPage()),
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_setup_outlined),
              title: Text(tr('deviceSpoofingMicroG')),
              subtitle: Text(tr('spoofGsfIdDeviceProfile')),
              onTap: () => _showSpoofingManager(context),
            ),
            if (plusSettings.plusEnableMicroGHub)
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(tr('microGDeploymentHub')),
                subtitle: Text(tr('directlyDownloadInstallMicroG')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushRoute(context, const MicroGHubPage()),
              ),
            if (plusSettings.plusEnableStandaloneInstaller)
              ListTile(
                leading: const Icon(Icons.install_mobile_outlined),
                title: Text(tr('standaloneApkInstaller')),
                subtitle: Text(tr('installAnyApkStorage')),
                trailing: const Icon(Icons.file_open_outlined),
                onTap: () => _handleStandaloneInstall(context),
              ),
            ListTile(
              leading: const Icon(Icons.network_check_rounded),
              title: Text(tr('playDiagTitle')),
              subtitle: Text(
                tr('playDiagEntryDesc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showPlayStoreDiagnosticSheet(context),
            ),
            ListTile(
              leading: const Icon(Icons.developer_board_rounded),
              title: Text(tr('playInspectorTitle')),
              subtitle: Text(
                tr('playInspectorEntryDesc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showPlayStoreInspectorSheet(context),
            ),
          ]),
          _buildSection(context, tr('playStoreSafetyAndFilters'), [
            _buildSafetyScoreCard(context),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.verified_user_outlined),
              title: Text(tr('verifiedAppsOnly')),
              subtitle: Text(tr('onlyShowAppsVerifiedByPlayProtect')),
              value: context
                  .watch<PlusSettingsProvider>()
                  .playStoreVerifiedOnly,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context.read<PlusSettingsProvider>().playStoreVerifiedOnly =
                    val;
              },
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.block_outlined),
              title: Text(tr('noAdsFilter')),
              subtitle: Text(tr('excludeAppsContainAds')),
              value: context.watch<PlusSettingsProvider>().playStoreNoAdsFilter,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context.read<PlusSettingsProvider>().playStoreNoAdsFilter = val;
              },
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(
                Icons.system_security_update_warning_outlined,
              ),
              title: Text(tr('excludeSystemApps')),
              subtitle: Text(tr('preventsUpdatingCriticalSystemComponents')),
              value: context
                  .watch<PlusSettingsProvider>()
                  .playStoreExcludeSystemApps,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context
                        .read<PlusSettingsProvider>()
                        .playStoreExcludeSystemApps =
                    val;
              },
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.vpn_lock_outlined),
              title: Text(tr('requireVpnStrictIpPrivacy')),
              subtitle: Text(tr('blockAllNativePlayStoreTraffic')),
              value: context
                  .watch<PlusSettingsProvider>()
                  .requireVPNForPlayStore,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context.read<PlusSettingsProvider>().requireVPNForPlayStore =
                    val;
              },
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.auto_delete_outlined),
              title: Text(tr('autoDiscardTokens')),
              subtitle: Text(tr('immediatelyClearAuthTokens')),
              value: context.watch<PlusSettingsProvider>().autoDiscardTokens,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context.read<PlusSettingsProvider>().autoDiscardTokens = val;
              },
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.cloud_sync_outlined),
              title: Text(tr('devPreferQuotaFreeRegistries')),
              subtitle: Text(
                tr('devPreferQuotaFreeRegistriesDesc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusPreferQuotaFreeRegistries,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context
                        .read<PlusSettingsProvider>()
                        .plusPreferQuotaFreeRegistries =
                    val;
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(tr('minimumDownloadsFilter')),
              subtitle: Text(
                tr(
                  'excludeAppsFewerThanDownloads',
                  args: [
                    context
                        .watch<PlusSettingsProvider>()
                        .playStoreMinDownloads
                        .toString(),
                  ],
                ),
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
              subtitle: Text(tr('realtimeNetworkRequests')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => pushRoute(context, TalkerScreen(talker: talker)),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: Text(tr('crashStatistics')),
              subtitle: Text(tr('localCrashFrequency')),
              onTap: () async {
                final stats = await CrashAnalytics.getStats();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => GlassDialog(
                      title: tr('localCrashStats'),
                      icon: Icons.analytics_outlined,
                      content: Text(
                        tr(
                          'localCrashStatsContent',
                          args: [
                            stats.totalCrashes.toString(),
                            stats.lastCrashTime != null
                                ? stats.lastCrashTime.toString()
                                : tr('never'),
                            stats.crashTypes.isEmpty
                                ? tr('none')
                                : stats.crashTypes.join(", "),
                          ],
                        ),
                      ),
                      actions: [
                        ScaleTouchWrapper(
                          hapticOnPressDown: true,
                          scaleDownFactor: 0.94,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(tr('close')),
                          ),
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(tr('noLogsFound'))));
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
              subtitle: Text(tr('opensPrefilledGithubIssue')),
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
            ListTile(
              leading: const Icon(Icons.supervised_user_circle_outlined),
              title: Text(tr('multiUserTitle')),
              subtitle: Text(
                tr('multiUserEntryDesc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showMultiUserDiagnosticSheet(context),
            ),
            // Usage access has its full card in Settings > Behavior; Service
            // Doctor shows its status next to battery and Shizuku+.
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(tr('serviceDoctor')),
              subtitle: Text(
                tr('serviceDoctorEntryDesc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDeviceOptimizationSheet(context: context),
            ),
          ]),
          // Corner radius and the expressive progress bar each have one
          // home in Look & motion; this links to the Shapes page.
          _buildSection(context, tr('expressiveDesignShapes'), [
            ListTile(
              leading: const Icon(Icons.rounded_corner_rounded),
              title: Text(tr('settingsAppearanceShapes')),
              subtitle: Text(tr('settingsAppearanceShapesDesc')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => pushRoute(
                context,
                SettingsSubpage(
                  title: tr('settingsAppearanceShapes'),
                  icon: Icons.rounded_corner_rounded,
                  child: const ThemeSettingsSection(
                    androidInfoFuture: null,
                    colorsNameMap: <ColorSwatch<Object>, String>{},
                    subCategory: 'shapes',
                  ),
                ),
              ),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.refresh_rounded),
              title: Text(tr('plusUseWavyLoadingSpinner')),
              subtitle: Text(tr('plusUseWavyLoadingSpinnerDesc')),
              value: context
                  .watch<PlusSettingsProvider>()
                  .plusDevUseThirdPartyLoadingIndicator,
              onChanged: (val) {
                val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                context
                        .read<PlusSettingsProvider>()
                        .plusDevUseThirdPartyLoadingIndicator =
                    val;
              },
            ),
          ]),
          _buildSection(context, tr('testing'), [
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              iconColor: Theme.of(context).colorScheme.error,
              title: Text(tr('triggerTestCrash')),
              subtitle: Text(tr('forcesCrashVerify')),
              onTap: () {
                talker.warning(tr('userTriggeredTestCrash'));
                throw Exception(tr('obtainiumTestCrash'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.network_check_outlined),
              title: Text(tr('testNetworkLogging')),
              subtitle: Text(tr('sendsDummyRequest')),
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: CardMetrics.shape(
              cardRadius,
              expressive: isM3E,
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.35 : 0.65,
                ),
                width: 1.0,
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
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
            color: enableGlass
                ? cs.surface.withValues(alpha: 0.78)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: enableGlass ? 0.18 : 0.12),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(tr('anonymousDispenser')),
                  subtitle: Text(tr('useThrowawayAccounts')),
                  trailing: authProvider.authMode == AuthMode.anonymous
                      ? Icon(Icons.check, color: cs.primary)
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
                  subtitle: Text(tr('useRealAccount')),
                  trailing: authProvider.authMode == AuthMode.microG
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () {
                    authProvider.setAuthMode(AuthMode.microG);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text(tr('hybridSafetyFirst')),
                  subtitle: Text(tr('anonymousForSearch')),
                  trailing: authProvider.authMode == AuthMode.hybrid
                      ? Icon(Icons.check, color: cs.primary)
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
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
          child: ConditionalBlur(
            enabled: enableGlass,
            sigma: AppConstants.glassBlurSigma,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('linkedEmailSuccessfully', args: [email]))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'errorWithMessage',
                args: [e.toString().replaceFirst('ObtainiumError: ', '')],
              ),
            ),
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

      if (result.isNotEmpty && result.first.path != null) {
        final file = File(result.first.path!);
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
                    Text(
                      tr('packageNameLabel', args: [info.packageName ?? '']),
                    ),
                    Text(
                      tr(
                        'versionLabel',
                        args: [
                          info.versionName ?? '',
                          info.versionCode?.toString() ?? '',
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(tr('proceedWithInstallation')),
                  ],
                ),
                actions: [
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.94,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr('cancel')),
                    ),
                  ),
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.94,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr('install')),
                    ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('errorWithMessage', args: [e.toString()]))),
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

    final cs = Theme.of(context).colorScheme;
    final color = score > 80
        ? cs.primary
        : (score > 50 ? cs.tertiary : cs.error);

    final String labelKey = score > 80
        ? 'safetyExcellent'
        : (score > 50 ? 'safetyModerate' : 'safetyLow');

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);

    return Card(
      elevation: 0,
      color: color.withValues(alpha: AppOpacity.subtle),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(innerRadius),
        side: BorderSide(color: color.withValues(alpha: AppOpacity.medium)),
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
              backgroundColor: color.withValues(alpha: AppOpacity.subtle),
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
                tr(
                  'deviceProfileAndroidVersion',
                  args: [
                    p.manufacturer,
                    p.model,
                    (p.sdkVersion - 21 + 5).toString(),
                  ],
                ),
              ),
              trailing: authProvider.selectedProfile.name == p.name
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
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
      final String result = await _platform
          .invokeMethod('getGsfId')
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _gsfId = result);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _gsfId = tr('failedToGetGsfId', args: [e.message ?? '']));
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _gsfId = tr('failedToGetGsfId', args: ['']));
    } catch (e) {
      if (!mounted) return;
      setState(() => _gsfId = tr('failedToGetGsfId', args: ['$e']));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final content = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(alpha: 0.78)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: enableGlass ? 0.18 : 0.12),
          width: 1,
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
            trailing: ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.88,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: tr('refresh'),
                onPressed: _getGsfId,
              ),
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
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigma,
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;

    final content = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(alpha: 0.78)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: enableGlass ? 0.18 : 0.12),
          width: 1,
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
                avatar: Icon(Icons.check_circle, color: cs.primary, size: 16),
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
                          ScaleTouchWrapper(
                            hapticOnPressDown: !_isLoading,
                            scaleDownFactor: 0.88,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: tr('remove'),
                              onPressed: () => authProvider.removeDispenser(d),
                            ),
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
                tooltip: tr('add'),
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
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: _sheetRadius(context)),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigma,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('errorWithMessage', args: [e.toString()]))),
        );
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
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
          ),
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('enable')),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      plusSettings.plusEnableBanWarnings = true;
    }
  }
}

/// Top corner radius for this page's bottom sheets, matching
/// `showDraggableModalBottomSheet` (user's corner radius, clamped).
Radius _sheetRadius(BuildContext context) {
  final plus = context.read<PlusSettingsProvider>();
  final base = plus.plusOverrideIndividualCornerRadius
      ? plus.plusHomeCornerRadius
      : plus.plusGlobalCornerRadius;
  return Radius.circular(base.clamp(20.0, 36.0));
}
