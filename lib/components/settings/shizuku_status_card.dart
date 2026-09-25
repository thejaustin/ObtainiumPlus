import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/components/settings/shizuku_activity_log_sheet.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Interactive Shizuku / ShizukuPlus Service Status Card,
/// inspired by the Material 3 Expressive ServerStatus card in ShizukuPlus.
class ShizukuStatusCard extends StatefulWidget {
  final VoidCallback? onStatusChanged;
  final EdgeInsetsGeometry margin;

  const ShizukuStatusCard({
    super.key,
    this.onStatusChanged,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<ShizukuStatusCard> createState() => _ShizukuStatusCardState();
}

class _ShizukuStatusCardState extends State<ShizukuStatusCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ShizukuProviderInfo? _info;
  bool _isLoading = true;
  bool _isTesting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final info = await ShizukuInstaller.getDetailedProviderInfo();
    if (mounted) {
      setState(() {
        _info = info;
        _isLoading = false;
      });
      widget.onStatusChanged?.call();
    }
  }

  Future<void> _testLatency() async {
    if (_isTesting) return;
    AppHaptics.selectionClick();
    setState(() => _isTesting = true);
    final info = await ShizukuInstaller.getDetailedProviderInfo();
    if (mounted) {
      setState(() {
        _info = info;
        _isTesting = false;
      });
      widget.onStatusChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final info = _info;

    final isInstalled = info?.isInstalled ?? false;
    final isRunning = info?.isRunning ?? false;
    final isPlus = info?.isPlus ?? false;
    final hasActivePort = info?.hasActiveLoopback ?? false;
    final latency = info?.binderLatencyMs;

    Color containerColor;
    Color borderColor;
    Color statusDotColor;
    String statusTitle;
    String statusSubtitle;
    IconData leadingIcon;

    if (_isLoading) {
      containerColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.4);
      statusDotColor = Colors.orange;
      statusTitle = tr('checkingShizukuStatus');
      statusSubtitle = tr('probingDaemon');
      leadingIcon = Icons.hourglass_top_rounded;
    } else if (!isInstalled) {
      containerColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.4);
      statusDotColor = colorScheme.onSurfaceVariant;
      statusTitle = tr('shizukuNotInstalled');
      statusSubtitle = tr('shizukuNotInstalledDesc');
      leadingIcon = Icons.install_mobile_outlined;
    } else if (isRunning) {
      containerColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
      borderColor = colorScheme.primary.withValues(alpha: 0.35);
      statusDotColor = Colors.green;
      statusTitle = isPlus
          ? tr('shizukuPlusServiceRunning')
          : tr('shizukuServiceRunning');
      statusSubtitle = tr('shizukuServiceRunningDesc');
      leadingIcon = isPlus
          ? Icons.electric_bolt_rounded
          : Icons.terminal_rounded;
    } else {
      containerColor = colorScheme.errorContainer.withValues(alpha: 0.25);
      borderColor = colorScheme.error.withValues(alpha: 0.3);
      statusDotColor = colorScheme.error;
      statusTitle = isPlus
          ? tr('shizukuPlusServiceStopped')
          : tr('shizukuServiceStopped');
      statusSubtitle = hasActivePort
          ? tr('shizukuAdbPortDetected', args: ['${info?.activeLoopbackPort}'])
          : tr('shizukuServiceStoppedDesc');
      leadingIcon = Icons.power_off_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Leading Icon, Title, and Status Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: isRunning
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                statusTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (info != null && isInstalled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isPlus
                                      ? colorScheme.primary.withValues(alpha: 0.15)
                                      : colorScheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  info.providerLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPlus
                                        ? colorScheme.primary
                                        : colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Animated Status Indicator Dot
                  FadeTransition(
                    opacity: isRunning || _isTesting
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusDotColor,
                        shape: BoxShape.circle,
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              // Metrics row if running or loopback detected
              if (isRunning && latency != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 13,
                            color: latency < 50
                                ? Colors.green
                                : (latency < 120 ? Colors.orange : colorScheme.error),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr('binderLatency', args: ['$latency']),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: latency < 50
                                  ? Colors.green
                                  : (latency < 120 ? Colors.orange : colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr('shizukuDirectIpc'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else if (hasActivePort && !isRunning) ...[
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      AppHaptics.lightImpact();
                      ShizukuInstaller.openShizukuManager();
                    },
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('shizukuAdbPortOpenHint', args: ['${info?.activeLoopbackPort}']),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (isInstalled) ...[
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: Text(
                          isPlus ? tr('openShizukuPlus') : tr('openShizuku'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          AppHaptics.lightImpact();
                          ShizukuInstaller.openShizukuManager();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    ActionChip(
                      avatar: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 15),
                      label: Text(
                        _isTesting ? tr('testing') : tr('retest'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: _testLatency,
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.medical_services_outlined, size: 15),
                      label: Text(
                        tr('serviceDoctor'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        showDeviceOptimizationSheet(context: context);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.assignment_outlined, size: 15),
                      label: Text(
                        tr('activityLog'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        showShizukuActivityLogSheet(context: context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
