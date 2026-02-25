import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Advanced settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AdvancedSettingsSection extends StatelessWidget {
  final String? searchQuery;

  const AdvancedSettingsSection({
      super.key,
      this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> children = [
      _buildFeatureToggle(
        context,
        icon: Icons.delete_sweep_outlined,
        title: tr('removeOnExternalUninstall'),
        subtitle: tr('removeOnExternalUninstallDescription'),
        value: (SettingsProvider s) => s.removeOnExternalUninstall,
        onChanged: (SettingsProvider s, bool v) => s.removeOnExternalUninstall = v,
        visible: (SettingsProvider s) => _matches(tr('removeOnExternalUninstall')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.verified_user_outlined,
        title: tr('beforeNewInstallsShareToAppVerifier'),
        subtitle: tr('beforeNewInstallsShareToAppVerifierDescription'),
        value: (SettingsProvider s) => s.beforeNewInstallsShareToAppVerifier,
        onChanged: (SettingsProvider s, bool v) => s.beforeNewInstallsShareToAppVerifier = v,
        visible: (SettingsProvider s) => _matches(tr('beforeNewInstallsShareToAppVerifier')),
      ),
      if (_matches(tr('useShizuku'))) _buildUseShizukuToggle(context),
      if (_matches(tr('shizukuPretendToBeGooglePlay'))) _buildShizukuPretendToBeGooglePlayToggle(context),
      _buildFeatureToggle(
        context,
        icon: Icons.report_off_outlined,
        title: tr('dontShowTrackOnlyWarnings'),
        subtitle: tr('dontShowTrackOnlyWarningsDescription'),
        value: (SettingsProvider s) => s.hideTrackOnlyWarning,
        onChanged: (SettingsProvider s, bool v) => s.hideTrackOnlyWarning = v,
        visible: (SettingsProvider s) => _matches(tr('dontShowTrackOnlyWarnings')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.security_outlined,
        title: tr('dontShowAPKOriginWarnings'),
        subtitle: tr('dontShowAPKOriginWarningsDescription'),
        value: (SettingsProvider s) => s.hideAPKOriginWarning,
        onChanged: (SettingsProvider s, bool v) => s.hideAPKOriginWarning = v,
        visible: (SettingsProvider s) => _matches(tr('dontShowAPKOriginWarnings')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.bug_report_outlined,
        title: tr('enableDeepLogging'),
        subtitle: tr('enableDeepLoggingDescription'),
        value: (SettingsProvider s) => s.enableDeepLogging,
        onChanged: (SettingsProvider s, bool v) => s.enableDeepLogging = v,
        visible: (SettingsProvider s) => _matches(tr('enableDeepLogging')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.gesture_outlined,
        title: tr('enableSwipeGestures'),
        subtitle: tr('enableSwipeGesturesDescription'),
        value: (SettingsProvider s) => s.enableSwipeGestures,
        onChanged: (SettingsProvider s, bool v) => s.enableSwipeGestures = v,
        visible: (SettingsProvider s) => _matches(tr('enableSwipeGestures')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.undo_outlined,
        title: tr('enableUndoForAppRemoval'),
        subtitle: tr('enableUndoForAppRemovalDescription'),
        value: (SettingsProvider s) => s.enableUndoForAppRemoval,
        onChanged: (SettingsProvider s, bool v) => s.enableUndoForAppRemoval = v,
        visible: (SettingsProvider s) => _matches(tr('enableUndoForAppRemoval')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.lightbulb_outline,
        title: tr('enableContextualTips'),
        subtitle: tr('enableContextualTipsDescription'),
        value: (SettingsProvider s) => s.enableContextualTips,
        onChanged: (SettingsProvider s, bool v) => s.enableContextualTips = v,
        visible: (SettingsProvider s) => _matches(tr('enableContextualTips')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.vibration_outlined,
        title: tr('enableHapticFeedback'),
        subtitle: tr('enableHapticFeedbackDescription'),
        value: (SettingsProvider s) => s.enableHapticFeedback,
        onChanged: (SettingsProvider s, bool v) => s.enableHapticFeedback = v,
        visible: (SettingsProvider s) => _matches(tr('enableHapticFeedback')),
      ),
    ];

    if (children.every((w) => w is SizedBox && w.child == null)) return const SizedBox.shrink();

    return SettingsGroup(
      title: isSearching ? null : tr('advanced'),
      children: children,
    );
  }

  Widget _buildDeepLoggingToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.bug_report_outlined),
          title: Text(tr('enableDeepLogging'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('deepLoggingExplanation')),
          value: settings.enableDeepLogging,
          onChanged: (value) => settings.enableDeepLogging = value,
        );
      },
    );
  }

  Widget _buildRemoveOnExternalUninstallToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.delete_sweep_outlined),
          title: Text(tr('removeOnExternalUninstall'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.removeOnExternalUninstall,
          onChanged: (value) => settings.removeOnExternalUninstall = value,
        );
      },
    );
  }

  Widget _buildAppVerifierToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.verified_user_outlined),
          title: Text(tr('beforeNewInstallsShareToAppVerifier'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.beforeNewInstallsShareToAppVerifier,
          onChanged: (value) => settings.beforeNewInstallsShareToAppVerifier = value,
        );
      },
    );
  }

  Widget _buildUseShizukuToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.terminal_outlined),
          title: Text(tr('useShizuku'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.useShizuku,
          onChanged: (useShizuku) {
            if (useShizuku) {
              ShizukuApkInstaller.checkPermission().then((resCode) {
                settings.useShizuku = resCode!.startsWith('granted');
              });
            } else {
              settings.useShizuku = false;
            }
          },
        );
      },
    );
  }

  Widget _buildShizukuPretendToBeGooglePlayToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.useShizuku) return const SizedBox.shrink();
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.shop_outlined),
          title: Text(tr('shizukuPretendToBeGooglePlay'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.shizukuPretendToBeGooglePlay,
          onChanged: (value) => settings.shizukuPretendToBeGooglePlay = value,
        );
      },
    );
  }

  Widget _buildHideTrackOnlyWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.report_off_outlined),
          title: Text(tr('dontShowTrackOnlyWarnings'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.hideTrackOnlyWarning,
          onChanged: (value) => settings.hideTrackOnlyWarning = value,
        );
      },
    );
  }

  Widget _buildHideAPKOriginWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.security_outlined),
          title: Text(tr('dontShowAPKOriginWarnings'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.hideAPKOriginWarning,
          onChanged: (value) => settings.hideAPKOriginWarning = value,
        );
      },
    );
  }

  Widget _buildEnableSwipeGesturesToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.gesture_outlined),
          title: Text(tr('enableSwipeGestures'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.enableSwipeGestures,
          onChanged: (value) => settings.enableSwipeGestures = value,
        );
      },
    );
  }

  Widget _buildEnableUndoForAppRemovalToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.undo_outlined),
          title: Text(tr('enableUndoForAppRemoval'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.enableUndoForAppRemoval,
          onChanged: (value) => settings.enableUndoForAppRemoval = value,
        );
      },
    );
  }

  Widget _buildEnableContextualTipsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.lightbulb_outline),
          title: Text(tr('enableContextualTips'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.enableContextualTips,
          onChanged: (value) => settings.enableContextualTips = value,
        );
      },
    );
  }

  Widget _buildEnableHapticFeedbackToggle(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.vibration_outlined),
          title: Text(tr('enableHapticFeedback'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.enableHapticFeedback,
          onChanged: (value) => settings.enableHapticFeedback = value,
        );
      },
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Function value,
    required Function onChanged,
    required Function visible,
  }) {
    // Determine which provider to use based on the title
    // This is a bit of a hack since we're using different providers
    bool isBehavior = title == tr('removeOnExternalUninstall') || 
                     title == tr('beforeNewInstallsShareToAppVerifier') ||
                     title == tr('enableSwipeGestures') ||
                     title == tr('enableUndoForAppRemoval') ||
                     title == tr('enableHapticFeedback');

    if (isBehavior) {
      return Consumer<BehaviorSettingsProvider>(
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
}
