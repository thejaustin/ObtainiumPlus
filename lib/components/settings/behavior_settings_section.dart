import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/main.dart' show supportedLocales;
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// General behavior settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class BehaviorSettingsSection extends StatelessWidget {
  final Widget sortDropdown;
  final Widget orderDropdown;
  final Widget localeDropdown;

  const BehaviorSettingsSection({
    super.key,
    required this.sortDropdown,
    required this.orderDropdown,
    required this.localeDropdown,
  });

  @override
  Widget build(BuildContext context) {
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocaleDropdown(context),
        height16,
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sortDropdown),
            const SizedBox(width: 16),
            Expanded(child: orderDropdown),
          ],
        ),
        height16,
        _buildShowWebInAppViewToggle(context),
        _buildPinUpdatesToggle(context),
        _buildBuryNonInstalledToggle(context),
        _buildCheckUpdateOnDetailPageToggle(context),
        height16,
        Text(
          tr('swipeActions'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSwipeRightDropdown(context),
        const SizedBox(height: 8),
        _buildSwipeLeftDropdown(context),
      ],
    );
  }

  Widget _buildLocaleDropdown(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          prefixIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: tr('language'),
          prefixIcon: const Icon(Icons.language_outlined),
        ),
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
        value: Provider.of<SettingsProvider>(context).forcedLocale,
        items: [
          DropdownMenuItem(value: null, child: Text(tr('followSystem'))),
          ...supportedLocales.map(
            (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
          ),
        ],
        onChanged: (value) {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          settings.forcedLocale = value;
          if (value != null) {
            context.setLocale(value);
          } else {
            settings.resetLocaleSafe(context);
          }
        },
      ),
    );
  }

  Widget _buildShowWebInAppViewToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.open_in_browser_outlined),
          title: Text(tr('showWebInAppView')),
          value: settings.showAppWebpage,
          onChanged: (value) {
            settings.showAppWebpage = value;
          },
        );
      },
    );
  }

  Widget _buildPinUpdatesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.push_pin_outlined),
          title: Text(tr('pinUpdates')),
          value: settings.pinUpdates,
          onChanged: (value) {
            settings.pinUpdates = value;
          },
        );
      },
    );
  }

  Widget _buildBuryNonInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.vertical_align_bottom_outlined),
          title: Row(
            children: [
              Expanded(child: Text(tr('moveNonInstalledAppsToBottom'))),
              InfoTooltip(message: tr('moveNonInstalledAppsToBottomTooltip')),
            ],
          ),
          value: settings.buryNonInstalled,
          onChanged: (value) {
            settings.buryNonInstalled = value;
          },
        );
      },
    );
  }

  Widget _buildCheckUpdateOnDetailPageToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.sync_outlined),
          title: Text(tr('checkUpdateOnDetailPage')),
          value: settings.checkUpdateOnDetailPage,
          onChanged: (value) {
            settings.checkUpdateOnDetailPage = value;
          },
        );
      },
    );
  }

  Widget _buildSwipeRightDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DropdownButtonFormField<AppSwipeAction>(
          decoration: InputDecoration(
            labelText: tr('swipeRightAction'),
            prefixIcon: const Icon(Icons.swipe_right_outlined),
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          value: settings.swipeRightAction,
          items: AppSwipeAction.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(tr('action_${e.name}')),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) settings.swipeRightAction = value;
          },
        );
      },
    );
  }

  Widget _buildSwipeLeftDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DropdownButtonFormField<AppSwipeAction>(
          decoration: InputDecoration(
            labelText: tr('swipeLeftAction'),
            prefixIcon: const Icon(Icons.swipe_left_outlined),
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          value: settings.swipeLeftAction,
          items: AppSwipeAction.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(tr('action_${e.name}')),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) settings.swipeLeftAction = value;
          },
        );
      },
    );
  }
}
