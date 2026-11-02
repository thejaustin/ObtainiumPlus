import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/play_store_api.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Shows an interactive developer sandbox to query Google Play FDFE protobuf endpoints live.
Future<void> showPlayStoreInspectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (ctx) => const PlayStoreInspectorSheet(),
  );
}

class PlayStoreInspectorSheet extends StatefulWidget {
  const PlayStoreInspectorSheet({super.key});

  @override
  State<PlayStoreInspectorSheet> createState() =>
      _PlayStoreInspectorSheetState();
}

class _PlayStoreInspectorSheetState extends State<PlayStoreInspectorSheet> {
  final TextEditingController _packageController = TextEditingController(
    text: 'com.google.android.keep',
  );
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;
  List<String> _deliveryUrls = [];
  int? _queryLatencyMs;

  static const List<String> _quickSamples = [
    'com.google.android.keep',
    'org.videolan.vlc',
    'moe.shizuku.privileged.api',
    'com.whatsapp',
    'com.spotify.music',
  ];

  @override
  void dispose() {
    _packageController.dispose();
    super.dispose();
  }

  Future<void> _inspectPackage([String? overridePackage]) async {
    final pkg = (overridePackage ?? _packageController.text).trim();
    if (pkg.isEmpty) return;

    if (overridePackage != null) {
      _packageController.text = pkg;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
      _deliveryUrls = [];
      _queryLatencyMs = null;
    });

    final authProvider = context.read<AuthProvider>();
    final plusSettings = context.read<PlusSettingsProvider>();

    final sw = Stopwatch()..start();
    try {
      if (!authProvider.hasActiveToken) {
        if (authProvider.authMode == AuthMode.microG &&
            authProvider.microGEmail != null) {
          try {
            await authProvider.refreshMicroGToken();
          } catch (_) {}
        } else if (authProvider.dispensers.isNotEmpty) {
          try {
            await authProvider.refreshBundle(authProvider.dispensers.first);
          } catch (_) {}
        }
      }

      if (!authProvider.hasActiveToken) {
        throw Exception(
          'No active Google Play token available. Configure a dispenser or microG account first.',
        );
      }

      final api = PlayStoreApi(
        authProvider: authProvider,
        plusSettingsProvider: plusSettings,
      );

      final details = await api.getDetails(pkg);
      sw.stop();

      if (details == null) {
        throw Exception(
          'Play Store returned empty or not found for package "$pkg".',
        );
      }

      List<String> delivery = [];
      final vc = details['versionCode'];
      if (vc is int && vc > 0) {
        try {
          delivery = await api.getDeliveryUrls(pkg, vc);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _result = details;
          _deliveryUrls = delivery;
          _queryLatencyMs = sw.elapsedMilliseconds;
          _isLoading = false;
        });
        AppHaptics.success();
      }
    } catch (e) {
      sw.stop();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _queryLatencyMs = sw.elapsedMilliseconds;
          _isLoading = false;
        });
        AppHaptics.failure();
      }
    }
  }

  void _copyResultJson() {
    if (_result == null) return;
    final payload = {
      'details': _result,
      'deliveryUrls': _deliveryUrls,
      'latencyMs': _queryLatencyMs,
    };
    Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    AppHaptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Play Store response copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    final Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(alpha: 0.88)
            : cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.developer_board_rounded,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Play Store FDFE Inspector',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Live protobuf endpoint & split delivery test',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_result != null)
                      ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.88,
                        child: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          tooltip: 'Copy Payload JSON',
                          onPressed: _copyResultJson,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  shrinkWrap: true,
                  children: [
                    // Package Input Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _packageController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Package Name',
                              hintText: 'e.g. com.google.android.keep',
                              prefixIcon: const Icon(Icons.android_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _inspectPackage(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ScaleTouchWrapper(
                          hapticOnPressDown: true,
                          scaleDownFactor: 0.92,
                          child: FilledButton.tonal(
                            onPressed: _isLoading
                                ? null
                                : () => _inspectPackage(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: ExpressiveCircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quick Samples
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickSamples.map((sample) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ActionChip(
                              label: Text(
                                sample.split('.').last,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _inspectPackage(sample),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error Box
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: cs.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: cs.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Results Box
                    if (_result != null) ...[
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        shape: CardMetrics.shape(
                          cardRadius,
                          expressive: plusSettings.plusEnableMaterialExpressive,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _result!['title'] ??
                                          _packageController.text,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (_queryLatencyMs != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_queryLatencyMs}ms',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (_result!['developerName'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    _result!['developerName'],
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              _buildMetaRow(
                                'Version String',
                                _result!['versionString']?.toString() ?? 'N/A',
                                cs,
                              ),
                              _buildMetaRow(
                                'Version Code',
                                _result!['versionCode']?.toString() ?? 'N/A',
                                cs,
                              ),
                              _buildMetaRow(
                                'FDFE Status',
                                _result!['status'] ?? 'unknown',
                                cs,
                              ),
                              _buildMetaRow(
                                'Split Delivery URLs',
                                '${_deliveryUrls.length} splits detected',
                                cs,
                              ),
                              if (_result!['recentChangesHtml'] != null &&
                                  (_result!['recentChangesHtml'] as String)
                                      .isNotEmpty) ...[
                                const Divider(height: 20),
                                Text(
                                  'Release Notes',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _result!['recentChangesHtml']
                                      .toString()
                                      .replaceAll(RegExp(r'<[^>]*>'), ''),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: const Key('play_store_inspector_dismissible'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.of(context).pop(),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: 20,
        child: sheetContent,
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
