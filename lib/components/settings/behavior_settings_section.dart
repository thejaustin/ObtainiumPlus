import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
        localeDropdown,
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
        height16,
        _buildPinUpdatesToggle(context),
        height16,
        _buildBuryNonInstalledToggle(context),
        height16,
        _buildCheckUpdateOnDetailPageToggle(context),
      ],
    );
  }

  Widget _buildShowWebInAppViewToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('showWebInAppView'))),
            Switch(
              value: settings.showAppWebpage,
              onChanged: (value) {
                settings.showAppWebpage = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinUpdatesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('pinUpdates'))),
            Switch(
              value: settings.pinUpdates,
              onChanged: (value) {
                settings.pinUpdates = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBuryNonInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('moveNonInstalledAppsToBottom')),
            ),
            Switch(
              value: settings.buryNonInstalled,
              onChanged: (value) {
                settings.buryNonInstalled = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckUpdateOnDetailPageToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('checkUpdateOnDetailPage')),
            ),
            Switch(
              value: settings.checkUpdateOnDetailPage,
              onChanged: (value) {
                settings.checkUpdateOnDetailPage = value;
              },
            ),
          ],
        );
      },
    );
  }
}
