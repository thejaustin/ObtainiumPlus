import 'package:flutter/material.dart';
import 'package:obtainium/services/device_compatibility_service.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';

/// Shows the Device Compatibility & Optimization Sheet.
Future<void> showDeviceOptimizationSheet({required BuildContext context}) {
  return showDraggableModalBottomSheet<void>(
    context: context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (sheetContext, scrollController) {
      return DeviceOptimizationSheetContent(scrollController: scrollController);
    },
  );
}

class DeviceOptimizationSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const DeviceOptimizationSheetContent({
    super.key,
    required this.scrollController,
  });

  @override
  State<DeviceOptimizationSheetContent> createState() =>
      _DeviceOptimizationSheetContentState();
}

class _DeviceOptimizationSheetContentState
    extends State<DeviceOptimizationSheetContent> {
  DeviceOEM? _selectedOEM;
  DeviceOEM _detectedOEM = DeviceOEM.generic;
  String _deviceSummary = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final oem = await DeviceUtils.getDeviceOEM();
    final summary = await DeviceUtils.getDeviceSummary();
    if (mounted) {
      setState(() {
        _detectedOEM = oem;
        _selectedOEM = oem;
        _deviceSummary = summary;
        _isLoading = false;
      });
    }
  }

  static const List<DeviceOEM> _supportedOEMs = [
    DeviceOEM.samsung,
    DeviceOEM.xiaomi,
    DeviceOEM.oneplus,
    DeviceOEM.nothing,
    DeviceOEM.vivo,
    DeviceOEM.huawei,
    DeviceOEM.pixel,
  ];

  String _getOEMLabel(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.samsung:
        return 'Samsung One UI';
      case DeviceOEM.xiaomi:
        return 'Xiaomi / MIUI';
      case DeviceOEM.oneplus:
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return 'OnePlus / OPPO';
      case DeviceOEM.nothing:
        return 'Nothing OS';
      case DeviceOEM.vivo:
        return 'Vivo / iQOO';
      case DeviceOEM.huawei:
        return 'Huawei / Honor';
      case DeviceOEM.pixel:
      default:
        return 'Stock Android';
    }
  }

  IconData _getOEMIcon(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.samsung:
        return Icons.phone_android_rounded;
      case DeviceOEM.xiaomi:
        return Icons.bolt_rounded;
      case DeviceOEM.oneplus:
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return Icons.speed_rounded;
      case DeviceOEM.nothing:
        return Icons.flare_rounded;
      case DeviceOEM.vivo:
        return Icons.battery_charging_full_rounded;
      case DeviceOEM.huawei:
        return Icons.shield_rounded;
      case DeviceOEM.pixel:
      default:
        return Icons.android_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeOEM = _selectedOEM ?? _detectedOEM;
    final guide = DeviceCompatibilityService.getGuideForOEM(activeOEM);

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Compatibility Hub',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _deviceSummary.isNotEmpty
                          ? 'Detected: $_deviceSummary'
                          : 'Optimizations for non-root & Shizuku users',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Horizontally scrolling OEM selection tabs
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _supportedOEMs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final oem = _supportedOEMs[index];
              final isSelected = oem == activeOEM;
              final isDetected = oem == _detectedOEM;
              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  _getOEMIcon(oem),
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getOEMLabel(oem)),
                    if (isDetected) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    AppHaptics.selectionClick();
                    setState(() => _selectedOEM = oem);
                  }
                },
              );
            },
          ),
        ),

        // Main scrollable guide content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Overview Banner
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getOEMIcon(guide.oem),
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    guide.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              guide.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Action Shortcuts Section
                    if (guide.actions.isNotEmpty) ...[
                      Text(
                        'Direct Settings Shortcuts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...guide.actions.map(
                        (action) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: Icon(
                              Icons.launch_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              action.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              action.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () async {
                                AppHaptics.lightImpact();
                                final ok = await action.action();
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Setting could not be opened automatically. Please check system settings.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Open'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Important Highlights Section
                    Text(
                      'Known OEM Behaviors & Fixes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...guide.highlights.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 10),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recommended Step-by-Step Setup
                    Text(
                      'Recommended Configuration Steps',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...guide.steps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 10, top: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Non-root / Non-ADB Pro-tip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: theme.colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Non-Root / Non-ADB Pro-Tip: On Android 14+, enable "Update Ownership" and "User Pre-approval" in ObtainiumPlus Installation settings. Once pre-approved, your apps will update silently in the background without needing root or Shizuku!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
