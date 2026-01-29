import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/main.dart' show supportedLocales;
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// General behavior settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class BehaviorSettingsSection extends StatelessWidget {
  final Widget sortDropdown;
  final Widget orderDropdown;
  final Widget localeDropdown;
  final String? searchQuery;

  const BehaviorSettingsSection({
    super.key,
    required this.sortDropdown,
    required this.orderDropdown,
    required this.localeDropdown,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    // Language & Region group
    List<Widget> languageChildren = [
      if (_matches(tr('language'))) _buildLocaleDropdown(context),
    ];

    // App List Behavior group
    List<Widget> appListChildren = [
      if (_matches(tr('appSortBy')))
        ListTile(
          leading: const Icon(Icons.sort_outlined),
          title: Text(tr('appSortBy'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: sortDropdown,
          ),
        ),
      if (_matches(tr('appSortOrder')))
        ListTile(
          leading: const Icon(Icons.swap_vert_outlined),
          title: Text(tr('appSortOrder'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: orderDropdown,
          ),
        ),
      if (_matches(tr('showWebInAppView'))) _buildShowWebInAppViewToggle(context),
      if (_matches(tr('pinUpdates'))) _buildPinUpdatesToggle(context),
      if (_matches(tr('moveNonInstalledAppsToBottom'))) _buildBuryNonInstalledToggle(context),
      if (_matches(tr('checkUpdateOnDetailPage'))) _buildCheckUpdateOnDetailPageToggle(context),
    ];

    // Swipe Actions group
    List<Widget> swipeChildren = [];
    final settings = Provider.of<SettingsProvider>(context);
    if (settings.plusEnableSwipeActions) {
      swipeChildren = [
        if (_matches(tr('swipeRightAction'))) _buildSwipeRightDropdown(context),
        if (_matches(tr('swipeLeftAction'))) _buildSwipeLeftDropdown(context),
      ];
    }

    return Column(
      children: [
        if (languageChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('languageAndRegion') ?? 'Language & Region',
            children: languageChildren,
          ),
        if (appListChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('appListBehavior') ?? 'App List Behavior',
            children: appListChildren,
          ),
        if (swipeChildren.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('swipeActions'),
            children: swipeChildren,
          ),
      ],
    );
  }

  Widget _buildLocaleDropdown(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(tr('language'), style: Theme.of(context).textTheme.bodyLarge),
      trailing: DropdownButton<Locale?>(
        underline: const SizedBox(),
        value: settings.forcedLocale,
        items: [
          DropdownMenuItem(value: null, child: Text(tr('followSystem'))),
          ...supportedLocales.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
        ],
        onChanged: (value) {
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
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.public_outlined),
          title: Text(tr('showWebInAppView'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.showAppWebpage,
          onChanged: (value) => settings.showAppWebpage = value,
        );
      },
    );
  }

  Widget _buildPinUpdatesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.push_pin_outlined),
          title: Text(tr('pinUpdates'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.pinUpdates,
          onChanged: (value) => settings.pinUpdates = value,
        );
      },
    );
  }

  Widget _buildBuryNonInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.vertical_align_bottom_outlined),
          title: Text(tr('moveNonInstalledAppsToBottom'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.buryNonInstalled,
          onChanged: (value) => settings.buryNonInstalled = value,
        );
      },
    );
  }

  Widget _buildCheckUpdateOnDetailPageToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.refresh_outlined),
          title: Text(tr('checkUpdateOnDetailPage'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.checkUpdateOnDetailPage,
          onChanged: (value) => settings.checkUpdateOnDetailPage = value,
        );
      },
    );
  }

  Widget _buildSwipeRightDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.swipe_right_outlined),
          title: Text(tr('swipeRightAction'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: DropdownButton<AppSwipeAction>(
            underline: const SizedBox(),
            value: settings.swipeRightAction,
            items: AppSwipeAction.values.map((e) => DropdownMenuItem(value: e, child: Text(tr('action_${e.name}')))).toList(),
            onChanged: (value) {
              if (value != null) settings.swipeRightAction = value;
            },
          ),
        );
      },
    );
  }

  Widget _buildSwipeLeftDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.swipe_left_outlined),
          title: Text(tr('swipeLeftAction'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: DropdownButton<AppSwipeAction>(
            underline: const SizedBox(),
            value: settings.swipeLeftAction,
            items: AppSwipeAction.values.map((e) => DropdownMenuItem(value: e, child: Text(tr('action_${e.name}')))).toList(),
            onChanged: (value) {
              if (value != null) settings.swipeLeftAction = value;
            },
          ),
        );
      },
    );
  }
}
