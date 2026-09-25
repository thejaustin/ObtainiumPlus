import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/services/shizuku_telemetry_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';

/// Displays the Shizuku IPC Activity Log modal sheet,
/// modeled after ShizukuPlus ActivityLogManager audit trail.
Future<void> showShizukuActivityLogSheet({required BuildContext context}) {
  return showDraggableModalBottomSheet<void>(
    context: context,
    initialChildSize: 0.75,
    minChildSize: 0.45,
    maxChildSize: 0.95,
    builder: (sheetContext, scrollController) {
      return ShizukuActivityLogSheetContent(scrollController: scrollController);
    },
  );
}

class ShizukuActivityLogSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const ShizukuActivityLogSheetContent({
    super.key,
    required this.scrollController,
  });

  @override
  State<ShizukuActivityLogSheetContent> createState() =>
      _ShizukuActivityLogSheetContentState();
}

class _ShizukuActivityLogSheetContentState
    extends State<ShizukuActivityLogSheetContent> {
  @override
  void initState() {
    super.initState();
    ShizukuTelemetryService.instance.addListener(_onTelemetryUpdated);
  }

  @override
  void dispose() {
    ShizukuTelemetryService.instance.removeListener(_onTelemetryUpdated);
    super.dispose();
  }

  void _onTelemetryUpdated() {
    if (mounted) setState(() {});
  }

  void _copyLogToClipboard() {
    AppHaptics.lightImpact();
    final logText = ShizukuTelemetryService.instance.exportPlainText();
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('shizukuLogCopied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearLog() {
    AppHaptics.selectionClick();
    ShizukuTelemetryService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = ShizukuTelemetryService.instance.entries;

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title and actions header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
          child: Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('shizukuActivityLog'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tr('shizukuActivityLogDesc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (entries.isNotEmpty) ...[
                IconButton(
                  tooltip: tr('copyToClipboard'),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: _copyLogToClipboard,
                ),
                IconButton(
                  tooltip: tr('clear'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: _clearLog,
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // Log entry list
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr('shizukuLogEmpty'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: entries.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    final timeStr =
                        '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}:${e.timestamp.second.toString().padLeft(2, '0')}';

                    Color statusColor;
                    IconData statusIcon;
                    if (e.isSuccess) {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle_rounded;
                    } else if (e.isBlocked) {
                      statusColor = Colors.orange;
                      statusIcon = Icons.shield_rounded;
                    } else {
                      statusColor = colorScheme.error;
                      statusIcon = Icons.error_rounded;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      e.action,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeStr,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (e.targetPackage != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    e.targetPackage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (e.details != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    e.details!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${e.durationMs}ms',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (e.latencyMs != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• latency: ${e.latencyMs}ms',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
