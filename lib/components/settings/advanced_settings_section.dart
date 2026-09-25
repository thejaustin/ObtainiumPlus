import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/startup_repair_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';

/// Advanced / warnings settings section
class AdvancedSettingsSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const AdvancedSettingsSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    final plusFeaturesEnabled = context.select<PlusSettingsProvider, bool>(
      (s) => s.enableAllPlusFeatures,
    );

    List<Widget> children = [
      if (_matches(tr('showAdvancedSettings')))
        Consumer<PlusSettingsProvider>(
          builder: (context, plusSettings, child) {
            return SwitchListTile.adaptive(
              secondary: const Icon(Icons.settings_suggest_outlined),
              title: Text(
                tr('showAdvancedSettings'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('showAdvancedSettingsDescription')),
              value: plusSettings.plusShowAdvancedSettings,
              onChanged: (v) {
                AppHaptics.selectionClick();
                plusSettings.plusShowAdvancedSettings = v;
              },
            );
          },
        ),
      if (_matches(tr('dontShowTrackOnlyWarnings')))
        _buildSettingsToggle(
          context,
          icon: Icons.report_off_outlined,
          title: tr('dontShowTrackOnlyWarnings'),
          subtitle: tr('dontShowTrackOnlyWarningsDescription'),
          value: (s) => s.hideTrackOnlyWarning,
          onChanged: (s, v) => s.hideTrackOnlyWarning = v,
        ),
      if (_matches(tr('dontShowAPKOriginWarnings')))
        _buildSettingsToggle(
          context,
          icon: Icons.security_outlined,
          title: tr('dontShowAPKOriginWarnings'),
          subtitle: tr('dontShowAPKOriginWarningsDescription'),
          value: (s) => s.hideAPKOriginWarning,
          onChanged: (s, v) => s.hideAPKOriginWarning = v,
        ),
      if (_matches(tr('enableDeepLogging')))
        _buildSettingsToggle(
          context,
          icon: Icons.bug_report_outlined,
          title: tr('enableDeepLogging'),
          subtitle: tr('enableDeepLoggingDescription'),
          value: (s) => s.enableDeepLogging,
          onChanged: (s, v) => s.enableDeepLogging = v,
        ),
      if (_matches(tr('enableContextualTips')))
        _buildSettingsToggle(
          context,
          icon: Icons.lightbulb_outline,
          title: tr('enableContextualTips'),
          subtitle: tr('enableContextualTipsDescription'),
          value: (s) => s.enableContextualTips,
          onChanged: (s, v) => s.enableContextualTips = v,
        ),
      if (_matches(tr('highlightTouchTargets'), isAdvanced: true))
        _buildSettingsToggle(
          context,
          icon: Icons.touch_app_outlined,
          title: tr('highlightTouchTargets'),
          subtitle: tr('highlightTouchTargetsDescription'),
          value: (s) => s.highlightTouchTargets,
          onChanged: (s, v) => s.highlightTouchTargets = v,
        ),
      if (_matches(tr('autoExportOnChanges'), isAdvanced: true))
        _buildSettingsToggle(
          context,
          icon: Icons.backup_outlined,
          title: tr('autoExportOnChanges'),
          subtitle: tr('autoExportOnChangesDescription'),
          value: (s) => s.autoExportOnChanges,
          onChanged: (s, v) => s.autoExportOnChanges = v,
        ),
      if (plusFeaturesEnabled &&
          _matches(tr('backupEncryption'), isAdvanced: true))
        Consumer<PlusSettingsProvider>(
          builder: (context, plusSettings, child) {
            return SwitchListTile.adaptive(
              secondary: const Icon(Icons.enhanced_encryption_outlined),
              title: Text(
                tr('backupEncryption'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('backupEncryptionDescription')),
              value: plusSettings.backupEncryptionEnabled,
              onChanged: (v) {
                AppHaptics.selectionClick();
                plusSettings.backupEncryptionEnabled = v;
              },
            );
          },
        ),
      _buildTokenConfigTile(
        context,
        icon: Icons.login_outlined,
        title: tr('plusGithubToken'),
        subtitle: tr('plusGithubTokenDescription'),
        settingId: 'github-creds',
        helpUrl:
            'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token',
        visible: _matches(tr('plusGithubToken')),
      ),
      _buildTokenConfigTile(
        context,
        icon: Icons.login_outlined,
        title: tr('plusGitlabToken'),
        subtitle: tr('plusGitlabTokenDescription'),
        settingId: 'gitlab-creds',
        helpUrl:
            'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html',
        visible: _matches(tr('plusGitlabToken')),
      ),
      if (_matches(tr('importExport')))
        ListTile(
          leading: const Icon(Icons.import_export_rounded),
          title: Text(
            tr('importExport'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: const Text(
            'Backup, restore, import, or export settings and apps',
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            AppHaptics.selectionClick();
            pushRoute(context, const ImportExportPage());
          },
        ),
      if (_matches(tr('factoryReset'))) ...[
        const Divider(),
        ListTile(
          leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          title: Text(
            tr('factoryReset'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.red),
          ),
          subtitle: Text(tr('factoryResetDescription')),
          onTap: () => _showResetConfirmation(context),
        ),
      ],
    ];

    if (children.isEmpty) return const SizedBox.shrink();

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('advanced'),
      persistKey: 'advanced',
      icon: Icons.settings_applications_rounded,
      isExpandable: !isSearching,
      initiallyExpanded: false,
      children: children,
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: tr('factoryReset'),
        icon: Icons.warning_amber_rounded,
        content: Text(tr('factoryResetConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              AppHaptics.heavyImpact();
              await StartupRepairService.factoryReset();
              if (context.mounted) {
                // Should ideally restart app, but clearing and showing msg for now
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('factoryResetComplete'))),
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(tr('reset'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(SettingsProvider) value,
    required void Function(SettingsProvider, bool) onChanged,
  }) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: value(settings),
          onChanged: (v) {
            AppHaptics.selectionClick();
            onChanged(settings, v);
          },
        );
      },
    );
  }

  Widget _buildTokenConfigTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String settingId,
    required String helpUrl,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final token = settings.getSettingString(settingId);
        final isConfigured = token != null && token.isNotEmpty;
        return ListTile(
          leading: Icon(
            icon,
            color: isConfigured ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(isConfigured ? tr('plusTokenConfigStatus') : subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _showTokenConfigDialog(
            context,
            title: title,
            settingId: settingId,
            helpUrl: helpUrl,
          ),
        );
      },
    );
  }

  void _showTokenConfigDialog(
    BuildContext context, {
    required String title,
    required String settingId,
    required String helpUrl,
  }) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: title,
        icon: Icons.vpn_key_outlined,
        content: _TokenConfigDialogContent(
          title: title,
          settingId: settingId,
          helpUrl: helpUrl,
          settings: settings,
        ),
      ),
    );
  }
}

class _TokenConfigDialogContent extends StatefulWidget {
  final String title;
  final String settingId;
  final String helpUrl;
  final SettingsProvider settings;

  const _TokenConfigDialogContent({
    required this.title,
    required this.settingId,
    required this.helpUrl,
    required this.settings,
  });

  @override
  State<_TokenConfigDialogContent> createState() =>
      _TokenConfigDialogContentState();
}

class _TokenConfigDialogContentState extends State<_TokenConfigDialogContent> {
  late TextEditingController _controller;
  bool _isPolling = false;
  String? _userCode;
  String? _verificationUri;
  String? _statusMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.settings.getSettingString(widget.settingId) ?? '',
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startOAuthFlow() async {
    setState(() {
      _isPolling = true;
      _statusMessage = 'Requesting device code from GitHub...';
      _userCode = null;
      _verificationUri = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://github.com/login/device/code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'client_id': 'Ov23liZc2J5VeeV8tS08'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        final deviceCode = data['device_code']?.toString() ?? '';
        final userCode = data['user_code']?.toString() ?? '';
        final verificationUri = data['verification_uri']?.toString() ?? '';
        final interval = ((data['interval'] as num?)?.toInt() ?? 5) + 1;

        setState(() {
          _userCode = userCode;
          _verificationUri = verificationUri;
          _statusMessage =
              'Open the verification link, enter the code, and approve access.';
        });

        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
          await _pollForToken(deviceCode, timer);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isPolling = false;
          _statusMessage =
              'OAuth Device Flow unavailable (${response.statusCode}). Please use the "Generate Token on GitHub" button above.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPolling = false;
        _statusMessage = 'Connection error: $e. Please use manual PAT above.';
      });
    }
  }

  void _cancelOAuthFlow() {
    _pollTimer?.cancel();
    setState(() {
      _isPolling = false;
      _userCode = null;
      _verificationUri = null;
      _statusMessage = null;
    });
  }

  Future<void> _pollForToken(String deviceCode, Timer timer) async {
    try {
      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'client_id': 'Ov23liZc2J5VeeV8tS08',
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          timer.cancel();
          final token = data['access_token']?.toString() ?? '';
          if (!mounted) return;
          setState(() {
            _controller.text = token;
            _isPolling = false;
            _userCode = null;
            _statusMessage = 'Signed in successfully! Click Save below.';
          });
          AppHaptics.selectionClick();
        } else if (data['error'] == 'authorization_pending') {
          // Keep polling
        } else {
          timer.cancel();
          if (!mounted) return;
          setState(() {
            _isPolling = false;
            _statusMessage =
                'OAuth session ended: ${data['error_description'] ?? data['error'] ?? 'Unknown'}';
          });
        }
      }
    } catch (_) {
      // Ignore poll network glitches
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGitHub = widget.settingId == 'github-creds';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isGitHub) ...[
          FilledButton.icon(
            onPressed: () {
              AppHaptics.selectionClick();
              launchUrlString(
                'https://github.com/settings/tokens/new?description=ObtainiumPlus&scopes=repo',
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_browser_rounded),
            label: Text(tr('generateGitHubToken')),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              tr('generateGitHubTokenDescription'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.login_rounded, size: 20),
              title: Text(
                tr('oauthDeviceFlowAlternative'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                if (!_isPolling && _userCode == null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: _startOAuthFlow,
                      icon: const Icon(Icons.devices_rounded),
                      label: const Text('Connect via Device Flow'),
                    ),
                  ),
                ] else ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_userCode != null)
                            Text(
                              _userCode!,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_verificationUri != null)
                    TextButton.icon(
                      onPressed: () {
                        launchUrlString(
                          _verificationUri!,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Verification Page'),
                    ),
                  if (_isPolling) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _cancelOAuthFlow,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(tr('cancel')),
                    ),
                  ],
                ],
                if (_statusMessage != null && !_isPolling && _userCode == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: tr('plusTokenLabel'),
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tr('pasteFromClipboard'),
                  icon: const Icon(Icons.content_paste_rounded),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.trim().isNotEmpty) {
                      AppHaptics.selectionClick();
                      setState(() {
                        _controller.text = data.text!.trim();
                      });
                    }
                  },
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: tr('clear'),
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      AppHaptics.selectionClick();
                      setState(() {
                        _controller.clear();
                      });
                    },
                  ),
              ],
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            launchUrlString(
              widget.helpUrl,
              mode: LaunchMode.externalApplication,
            );
          },
          child: Text(
            tr('plusTokenConfigHelp'),
            style: const TextStyle(
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                AppHaptics.selectionClick();
                widget.settings.setSettingString(
                  widget.settingId,
                  _controller.text.trim(),
                );
                Navigator.pop(context);
              },
              child: Text(tr('save')),
            ),
          ],
        ),
      ],
    );
  }
}
