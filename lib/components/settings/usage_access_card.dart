import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/shizuku_status_service.dart';
import 'package:obtainium/services/usage_stats_service.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Card providing status and 1-tap Shizuku / manual settings elevation
/// for Android's Usage Access (`PACKAGE_USAGE_STATS`) permission.
class UsageAccessCard extends StatefulWidget {
  final VoidCallback? onStatusChanged;
  final EdgeInsetsGeometry margin;

  const UsageAccessCard({
    super.key,
    this.onStatusChanged,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<UsageAccessCard> createState() => _UsageAccessCardState();
}

class _UsageAccessCardState extends State<UsageAccessCard>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isGrantingShizuku = false;
  bool _isGranted = false;
  int _trackedAppCount = 0;
  bool _shizukuRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final granted = await UsageStatsService.isUsageAccessGranted();
    int count = 0;
    if (granted) {
      final stats = await UsageStatsService.getAllUsageStats();
      count = stats.length;
    }

    if (!mounted) return;
    bool shizukuAlive = false;
    try {
      final snap = await ShizukuStatusService.instance.refreshFrom(context);
      shizukuAlive = snap.isBinderAlive;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isGranted = granted;
        _trackedAppCount = count;
        _shizukuRunning = shizukuAlive;
        _isLoading = false;
      });
      widget.onStatusChanged?.call();
    }
  }

  Future<void> _grantWithShizuku() async {
    AppHaptics.heavyImpact();
    setState(() => _isGrantingShizuku = true);

    try {
      final result = await UsageStatsService.grantWithShizuku();
      if (!mounted) return;

      if (result.isGranted) {
        AppHaptics.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      'usageAccessGrantedVia',
                      args: [result.method ?? 'Shizuku'],
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        AppHaptics.toggleOff();
        String message;
        if (result.status == 'SHIZUKU_NOT_RUNNING') {
          message = tr('shizukuServiceStopped');
        } else if (result.status == 'SHIZUKU_PERMISSION_REQUIRED') {
          message = tr('shizukuPermissionDenied');
        } else {
          message = result.message ?? tr('grantUsageAccessFailed');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGrantingShizuku = false);
        await _refreshStatus();
      }
    }
  }

  Future<void> _openSettings() async {
    AppHaptics.selectionClick();
    await UsageStatsService.openUsageAccessSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterial3Expressive;
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;

    final shape = CardMetrics.shape(16, expressive: isM3E);

    final statusBg = _isGranted
        ? colorScheme.primaryContainer.withValues(alpha: 0.35)
        : colorScheme.errorContainer.withValues(alpha: 0.25);
    final statusColor = _isGranted ? colorScheme.primary : colorScheme.error;
    final statusIcon = _isGranted
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;
    final statusText = _isGranted
        ? tr('usageAccessGranted')
        : tr('usageAccessNotGranted');

    return Container(
      margin: widget.margin,
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainer,
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Title + Status Pill
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: colorScheme.onSecondaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('usageAccessPermission'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr('packageUsageStats'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Pill
                AnimatedContainer(
                  duration: Duration(milliseconds: animsEnabled ? 200 : 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: statusBg,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: statusColor,
                          ),
                        )
                      else ...[
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description text
            Text(
              tr('usageAccessDescription'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),

            if (_isGranted && _trackedAppCount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr('trackingAppsCount', args: ['$_trackedAppCount']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            if (!_isGranted) ...[
              Row(
                children: [
                  // Shizuku 1-tap grant button
                  Expanded(
                    child: ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.94,
                      child: FilledButton.icon(
                        onPressed: _isGrantingShizuku
                            ? null
                            : _grantWithShizuku,
                        icon: _isGrantingShizuku
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(
                          _shizukuRunning
                              ? tr('grantWithShizuku')
                              : tr('grantWithElevated'),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Standard Android settings button
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.94,
                    child: OutlinedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: Text(tr('settings')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _refreshStatus,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(tr('refreshStats')),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(tr('systemSettings')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
