import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/startup_repair_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/pages/import_export.dart';

/// Advanced / warnings settings section
class AdvancedSettingsSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const AdvancedSettingsSection({super.key, this.searchQuery, this.showAdvancedSettings});

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> children = [
      _buildSettingsToggle(
        context,
        icon: Icons.report_off_outlined,
        title: tr('dontShowTrackOnlyWarnings'),
        subtitle: tr('dontShowTrackOnlyWarningsDescription'),
        value: (s) => s.hideTrackOnlyWarning,
        onChanged: (s, v) => s.hideTrackOnlyWarning = v,
        visible: (s) => _matches(tr('dontShowTrackOnlyWarnings')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.security_outlined,
        title: tr('dontShowAPKOriginWarnings'),
        subtitle: tr('dontShowAPKOriginWarningsDescription'),
        value: (s) => s.hideAPKOriginWarning,
        onChanged: (s, v) => s.hideAPKOriginWarning = v,
        visible: (s) => _matches(tr('dontShowAPKOriginWarnings')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.bug_report_outlined,
        title: tr('enableDeepLogging'),
        subtitle: tr('enableDeepLoggingDescription'),
        value: (s) => s.enableDeepLogging,
        onChanged: (s, v) => s.enableDeepLogging = v,
        visible: (s) => _matches(tr('enableDeepLogging')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.lightbulb_outline,
        title: tr('enableContextualTips'),
        subtitle: tr('enableContextualTipsDescription'),
        value: (s) => s.enableContextualTips,
        onChanged: (s, v) => s.enableContextualTips = v,
        visible: (s) => _matches(tr('enableContextualTips')),
      ),
      _buildTokenConfigTile(
        context,
        icon: Icons.login_outlined,
        title: tr('plusGithubToken'),
        subtitle: tr('plusGithubTokenDescription'),
        settingId: 'github-creds',
        helpUrl: 'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token',
        visible: _matches(tr('plusGithubToken')),
      ),
      _buildTokenConfigTile(
        context,
        icon: Icons.login_outlined,
        title: tr('plusGitlabToken'),
        subtitle: tr('plusGitlabTokenDescription'),
        settingId: 'gitlab-creds',
        helpUrl: 'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html',
        visible: _matches(tr('plusGitlabToken')),
      ),
      if (_matches(tr('importExport')))
        ListTile(
          leading: const Icon(Icons.import_export_rounded),
          title: Text(tr('importExport'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: const Text('Backup, restore, import, or export settings and apps'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            AppHaptics.selectionClick();
            pushRoute(context, const ImportExportPage());
          },
        ),
      const Divider(),
      if (_matches(tr('factoryReset')))
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
    ];

    if (children.every((w) => w is SizedBox && w.child == null))
      return const SizedBox.shrink();

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('advanced'),
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
    required bool Function(SettingsProvider) visible,
  }) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!visible(settings)) return const SizedBox.shrink();
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: value(settings),
          onChanged: (v) => onChanged(settings, v),
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
          leading: Icon(icon, color: isConfigured ? Theme.of(context).colorScheme.primary : null),
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
  State<_TokenConfigDialogContent> createState() => _TokenConfigDialogContentState();
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
      _statusMessage = 'Starting connection...';
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
        body: jsonEncode({
          'client_id': 'Ov23liZc2J5VeeV8tS08',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deviceCode = data['device_code'] as String;
        final userCode = data['user_code'] as String;
        final verificationUri = data['verification_uri'] as String;
        final interval = (data['interval'] as int? ?? 5) + 1;

        setState(() {
          _userCode = userCode;
          _verificationUri = verificationUri;
          _statusMessage = 'Please open the verification link and enter the code below.';
        });

        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
          await _pollForToken(deviceCode, timer);
        });
      } else {
        setState(() {
          _isPolling = false;
          _statusMessage = 'Error connecting to GitHub. Please use manual PAT below.';
        });
      }
    } catch (e) {
      setState(() {
        _isPolling = false;
        _statusMessage = 'Error: $e. Please use manual PAT.';
      });
    }
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          timer.cancel();
          final token = data['access_token'] as String;
          setState(() {
            _controller.text = token;
            _isPolling = false;
            _userCode = null;
            _statusMessage = 'Signed in successfully! Click Save.';
          });
          AppHaptics.selectionClick();
        } else if (data['error'] == 'authorization_pending') {
          // Keep polling
        } else {
          timer.cancel();
          setState(() {
            _isPolling = false;
            _statusMessage = 'OAuth session expired or failed. Code: ${data['error']}';
          });
        }
      }
    } catch (_) {
      // Ignore poll errors
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
          if (!_isPolling && _userCode == null)
            ElevatedButton.icon(
              onPressed: _startOAuthFlow,
              icon: const Icon(Icons.login),
              label: const Text('Sign In via GitHub OAuth'),
            )
          else ...[
            Center(
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _userCode ?? '',
                        style: const TextStyle(
                          fontSize: 28,
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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_verificationUri != null)
              TextButton.icon(
                onPressed: () {
                  launchUrlString(_verificationUri!, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Verification Page'),
              ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR USE MANUAL PAT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
        ],
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: tr('plusTokenLabel'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _controller.clear(),
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            launchUrlString(widget.helpUrl, mode: LaunchMode.externalApplication);
          },
          child: Text(
            tr('plusTokenConfigHelp'),
            style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
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
                widget.settings.setSettingString(widget.settingId, _controller.text.trim());
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
