import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/main.dart' show supportedLocales;
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
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

    List<Widget> children = [
      if (_matches(tr('language'))) _buildLocaleDropdown(context),
      if (_matches(tr('appSortBy')))
        ListTile(
          leading: const Icon(Icons.sort_outlined),
          title: Text(tr('appSortBy'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('appSortByDescription')),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: sortDropdown,
          ),
        ),
      if (_matches(tr('appSortOrder')))
        ListTile(
          leading: const Icon(Icons.import_export_outlined),
          title: Text(tr('appSortOrder'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('appSortOrderDescription')),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: orderDropdown,
          ),
        ),
      _buildFeatureToggle(
        context,
        icon: Icons.open_in_browser_outlined,
        title: tr('showWebInAppView'),
        subtitle: tr('showWebInAppViewDescription'),
        value: (dynamic s) => (s as ViewSettingsProvider).showAppWebpage,
        onChanged: (dynamic s, bool v) => (s as ViewSettingsProvider).showAppWebpage = v,
        visible: (dynamic s) => _matches(tr('showWebInAppView')),
        providerType: ViewSettingsProvider,
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.push_pin_outlined,
        title: tr('pinUpdates'),
        subtitle: tr('pinUpdatesDescription'),
        value: (dynamic s) => (s as ViewSettingsProvider).pinUpdates,
        onChanged: (dynamic s, bool v) => (s as ViewSettingsProvider).pinUpdates = v,
        visible: (dynamic s) => _matches(tr('pinUpdates')),
        providerType: ViewSettingsProvider,
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.vertical_align_bottom_outlined,
        title: tr('moveNonInstalledAppsToBottom'),
        subtitle: tr('moveNonInstalledAppsToBottomDescription'),
        value: (dynamic s) => (s as ViewSettingsProvider).buryNonInstalled,
        onChanged: (dynamic s, bool v) => (s as ViewSettingsProvider).buryNonInstalled = v,
        visible: (dynamic s) => _matches(tr('moveNonInstalledAppsToBottom')),
        providerType: ViewSettingsProvider,
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.sync_outlined,
        title: tr('checkUpdateOnDetailPage'),
        subtitle: tr('checkUpdateOnDetailPageDescription'),
        value: (dynamic s) => (s as UpdateSettingsProvider).checkUpdateOnDetailPage,
        onChanged: (dynamic s, bool v) => (s as UpdateSettingsProvider).checkUpdateOnDetailPage = v,
        visible: (dynamic s) => _matches(tr('checkUpdateOnDetailPage')),
        providerType: UpdateSettingsProvider,
      ),
    ];

    List<Widget> swipeChildren = [
      if (_matches(tr('swipeRightAction'))) _buildSwipeRightDropdown(context),
      if (_matches(tr('swipeLeftAction'))) _buildSwipeLeftDropdown(context),
    ];

    return Column(
      children: [
        if (children.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('general'),
            children: children,
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

  Widget _buildSwipeRightDropdown(BuildContext context) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.swipe_right_outlined),
          title: Text(tr('swipeRightAction'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('swipeRightActionDescription')),
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
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.swipe_left_outlined),
          title: Text(tr('swipeLeftAction'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('swipeLeftActionDescription')),
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

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic Function(dynamic) value,
    required void Function(dynamic, bool) onChanged,
    required bool Function(dynamic) visible,
    required Type providerType,
  }) {
    if (providerType == ViewSettingsProvider) {
      return Consumer<ViewSettingsProvider>(
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
    } else if (providerType == UpdateSettingsProvider) {
      return Consumer<UpdateSettingsProvider>(
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
    return const SizedBox.shrink();
  }
}
