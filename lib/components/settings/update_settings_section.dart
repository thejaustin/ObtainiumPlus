import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Update settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class UpdateSettingsSection extends StatelessWidget {
  final bool showIntervalLabel;
  final Function(bool) onIntervalLabelChange;
  final Future<AndroidDeviceInfo>? androidInfoFuture;

  const UpdateSettingsSection({
    super.key,
    required this.showIntervalLabel,
    required this.onIntervalLabelChange,
    required this.androidInfoFuture,
  });

  @override
  Widget build(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntervalLabel(context),
        _buildIntervalSlider(context),
        _buildForegroundServiceSection(context),
        height16,
        _buildCheckOnStartToggle(context),
        height16,
        _buildOnlyCheckInstalledToggle(context),
        height16,
        _buildParallelDownloadsToggle(context),
      ],
    );
  }

  Widget _buildIntervalLabel(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (showIntervalLabel) {
          return SizedBox(
            child: Text(
              "${tr('bgUpdateCheckInterval')}: ${settings.updateIntervalLabel}",
            ),
          );
        } else {
          return const SizedBox(height: 16);
        }
      },
    );
  }

  Widget _buildIntervalSlider(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Slider(
          value: settings.updateIntervalSliderVal,
          max: settings.updateIntervalNodes.length.toDouble(),
          divisions: settings.updateIntervalNodes.length * 20,
          label: settings.updateIntervalLabel,
          onChanged: (double value) {
            settings.updateIntervalSliderVal = value;
            settings.processIntervalSliderValue(value);
            // Trigger callback for parent state change
            onIntervalLabelChange(false);
          },
          onChangeStart: (double value) {
            onIntervalLabelChange(false);
          },
          onChangeEnd: (double value) {
            onIntervalLabelChange(true);
          },
        );
      },
    );
  }

  Widget _buildForegroundServiceSection(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);

    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (settings.updateInterval <= 0) {
              return const SizedBox.shrink();
            }

            bool canShowForeground = ((snapshot.data?.version.sdkInt ?? 0) >= 30) ||
                settings.useShizuku;

            if (!canShowForeground) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        tr('foregroundServiceExplanation'),
                      ),
                    ),
                    Switch(
                      value: settings.useFGService,
                      onChanged: (value) {
                        settings.useFGService = value;
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        tr('enableBackgroundUpdates'),
                      ),
                    ),
                    Switch(
                      value: settings.enableBackgroundUpdates,
                      onChanged: (value) {
                        settings.enableBackgroundUpdates = value;
                      },
                    ),
                  ],
                ),
                height8,
                Text(
                  tr('backgroundUpdateReqsExplanation'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  tr('backgroundUpdateLimitsExplanation'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                height8,
                if (settings.enableBackgroundUpdates)
                  Column(
                    children: [
                      height16,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              tr('bgUpdatesOnWiFiOnly'),
                            ),
                          ),
                          Switch(
                            value: settings.bgUpdatesOnWiFiOnly,
                            onChanged: (value) {
                              settings.bgUpdatesOnWiFiOnly = value;
                            },
                          ),
                        ],
                      ),
                      height16,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              tr('bgUpdatesWhileChargingOnly'),
                            ),
                          ),
                          Switch(
                            value: settings.bgUpdatesWhileChargingOnly,
                            onChanged: (value) {
                              settings.bgUpdatesWhileChargingOnly = value;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckOnStartToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('checkOnStart'))),
            Switch(
              value: settings.checkOnStart,
              onChanged: (value) {
                settings.checkOnStart = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlyCheckInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('onlyCheckInstalledOrTrackOnlyApps')),
            ),
            Switch(
              value: settings.onlyCheckInstalledOrTrackOnlyApps,
              onChanged: (value) {
                settings.onlyCheckInstalledOrTrackOnlyApps = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildParallelDownloadsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('parallelDownloads'))),
            Switch(
              value: settings.parallelDownloads,
              onChanged: (value) {
                settings.parallelDownloads = value;
              },
            ),
          ],
        );
      },
    );
  }
}
