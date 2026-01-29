import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/settings.dart';
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

    // Installation group
    List<Widget> installationChildren = [
      if (_matches(tr('useShizuku'))) _buildUseShizukuToggle(context),
      if (_matches(tr('shizukuPretendToBeGooglePlay'))) _buildShizukuPretendToBeGooglePlayToggle(context),
      if (_matches(tr('beforeNewInstallsShareToAppVerifier'))) _buildAppVerifierToggle(context),
      if (_matches(tr('removeOnExternalUninstall'))) _buildRemoveOnExternalUninstallToggle(context),
    ];

    // Warnings group
    List<Widget> warningsChildren = [
      if (_matches(tr('dontShowTrackOnlyWarnings'))) _buildHideTrackOnlyWarningToggle(context),
      if (_matches(tr('dontShowAPKOriginWarnings'))) _buildHideAPKOriginWarningToggle(context),
    ];

    // Interaction group
    List<Widget> interactionChildren = [
      if (_matches(tr('enableSwipeGestures'))) _buildEnableSwipeGesturesToggle(context),
      if (_matches(tr('enableUndoForAppRemoval'))) _buildEnableUndoForAppRemovalToggle(context),
      if (_matches(tr('enableContextualTips'))) _buildEnableContextualTipsToggle(context),
      if (Provider.of<SettingsProvider>(context).plusEnableHapticFeedback && _matches(tr('enableHapticFeedback'))) _buildEnableHapticFeedbackToggle(context),
    ];

    // Debugging group
    List<Widget> debuggingChildren = [
      if (_matches(tr('enableDeepLogging'))) _buildDeepLoggingToggle(context),
    ];

    return Column(
      children: [
        if (installationChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('installation') ?? 'Installation',
            children: installationChildren,
          ),
        if (warningsChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('warnings') ?? 'Warnings',
            children: warningsChildren,
          ),
        if (interactionChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('interaction') ?? 'Interaction',
            children: interactionChildren,
          ),
        if (debuggingChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('debugging') ?? 'Debugging',
            children: debuggingChildren,
          ),
      ],
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.auto_delete_outlined),
          title: Text(tr('removeOnExternalUninstall'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.removeOnExternalUninstall,
          onChanged: (value) => settings.removeOnExternalUninstall = value,
        );
      },
    );
  }

  Widget _buildAppVerifierToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.shield_outlined),
          title: Text(tr('beforeNewInstallsShareToAppVerifier'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.beforeNewInstallsShareToAppVerifier,
          onChanged: (value) => settings.beforeNewInstallsShareToAppVerifier = value,
        );
      },
    );
  }

  Widget _buildUseShizukuToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
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
    return Consumer<SettingsProvider>(
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
          secondary: const Icon(Icons.visibility_off_outlined),
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
          secondary: const Icon(Icons.gpp_maybe_outlined),
          title: Text(tr('dontShowAPKOriginWarnings'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.hideAPKOriginWarning,
          onChanged: (value) => settings.hideAPKOriginWarning = value,
        );
      },
    );
  }

  Widget _buildEnableSwipeGesturesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
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
    return Consumer<SettingsProvider>(
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.edgesensor_high_outlined),
          title: Text(tr('enableHapticFeedback'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.enableHapticFeedback,
          onChanged: (value) => settings.enableHapticFeedback = value,
        );
      },
    );
  }
}
