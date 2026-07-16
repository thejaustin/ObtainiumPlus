import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/startup_repair_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    final controller = TextEditingController(
      text: settings.getSettingString(settingId) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: title,
        icon: Icons.vpn_key_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('plusTokenLabel'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                launchUrlString(helpUrl, mode: LaunchMode.externalApplication);
              },
              child: Text(
                tr('plusTokenConfigHelp'),
                style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              AppHaptics.selectionClick();
              settings.setSettingString(settingId, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }
}
