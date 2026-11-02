import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Interactive hero card displayed at the top of the Settings page.
/// Summarizes active installer backend, background updates, and quick search filters.
class SettingsHeroOverview extends StatelessWidget {
  final ValueChanged<String> onSearchKeyword;
  final ValueChanged<int> onSelectTab;

  const SettingsHeroOverview({
    super.key,
    required this.onSearchKeyword,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();

    final isM3E = plusSettings.plusEnableMaterial3Expressive;
    final isCompact = plusSettings.plusUseCompactSettings;
    final cornerRadius = plusSettings.plusGlobalCornerRadius;

    final shape = CardMetrics.shape(16, expressive: isM3E);

    final installerMode = behaviorSettings.installerMode;
    final updateInterval = updateSettings.updateInterval;

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 10 : 14),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainer,
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Pills Row
            Row(
              children: [
                // 1. Installer backend pill
                Expanded(
                  child: _buildStatusPill(
                    context: context,
                    icon: installerMode == 'shizuku'
                        ? Icons.bolt_rounded
                        : (installerMode == 'root'
                              ? Icons.shield_rounded
                              : Icons.install_mobile_rounded),
                    label: installerMode == 'shizuku'
                        ? 'Shizuku'
                        : (installerMode == 'root' ? 'Root' : 'System'),
                    subLabel: tr('installer'),
                    color: installerMode == 'shizuku'
                        ? colorScheme.primary
                        : colorScheme.secondary,
                    onTap: () {
                      AppHaptics.selectionClick();
                      onSelectTab(1); // Jump to Updates & Install tab
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 2. Background updates pill
                Expanded(
                  child: _buildStatusPill(
                    context: context,
                    icon: updateInterval > 0
                        ? Icons.schedule_rounded
                        : Icons.touch_app_rounded,
                    label: updateInterval > 0
                        ? '${updateInterval}h'
                        : tr('manual'),
                    subLabel: tr('updates'),
                    color: updateInterval > 0
                        ? colorScheme.tertiary
                        : colorScheme.outline,
                    onTap: () {
                      AppHaptics.selectionClick();
                      onSelectTab(1); // Jump to Updates & Install tab
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 3. Device & Usage optimization pill
                Expanded(
                  child: _buildStatusPill(
                    context: context,
                    icon: Icons.insights_rounded,
                    label: tr('diagnostics'),
                    subLabel: tr('device'),
                    color: colorScheme.primary,
                    onTap: () {
                      AppHaptics.selectionClick();
                      showDeviceOptimizationSheet(context: context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick topic chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.palette_outlined,
                    label: tr('appearance'),
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSelectTab(0),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.bolt_rounded,
                    label: 'Shizuku',
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSearchKeyword('shizuku'),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.swipe_rounded,
                    label: tr('swipeGestures'),
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSelectTab(3),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.insights_rounded,
                    label: tr('usageAccessSettings'),
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSelectTab(3),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.import_export_rounded,
                    label: tr('importExportSettings'),
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSearchKeyword('export'),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickSearchChip(
                    context: context,
                    icon: Icons.warning_amber_rounded,
                    label: tr('safetyAndRateLimits'),
                    cornerRadius: cornerRadius,
                    isM3E: isM3E,
                    onTap: () => onSearchKeyword('warning'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.94,
      child: Material(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSearchChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double cornerRadius,
    required bool isM3E,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.94,
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: colorScheme.primary),
        label: Text(label),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colorScheme.surfaceContainerHigh.withValues(
          alpha: 0.5,
        ),
        shape: CardMetrics.shape(
          CardMetrics.pill(cornerRadius),
          expressive: isM3E,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        onPressed: () {
          AppHaptics.selectionClick();
          onTap();
        },
      ),
    );
  }
}
