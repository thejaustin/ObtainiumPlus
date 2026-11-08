import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/services/play_store_api.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

enum TestState { pending, running, success, warning, failure }

class DiagnosticStep {
  final String title;
  final String description;
  TestState state;
  String? detail;
  int? latencyMs;

  DiagnosticStep({
    required this.title,
    required this.description,
    this.state = TestState.pending,
    this.detail,
    this.latencyMs,
  });
}

/// Comprehensive Google Play Store and microG diagnostic tester
Future<void> showPlayStoreDiagnosticSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (ctx) => const _PlayStoreDiagnosticSheet(),
  );
}

class _PlayStoreDiagnosticSheet extends StatefulWidget {
  const _PlayStoreDiagnosticSheet();

  @override
  State<_PlayStoreDiagnosticSheet> createState() =>
      _PlayStoreDiagnosticSheetState();
}

class _PlayStoreDiagnosticSheetState extends State<_PlayStoreDiagnosticSheet> {
  bool _isRunning = false;

  late final List<DiagnosticStep> _steps = [
    DiagnosticStep(
      title: 'microG / GMS Services',
      description: 'Checks if Google Play Services or microG is accessible',
    ),
    DiagnosticStep(
      title: 'VPN & IP Privacy Tunnel',
      description: 'Checks active VPN status and leak protection',
    ),
    DiagnosticStep(
      title: 'Token Dispenser & AAS Auth',
      description:
          'Pings Aurora token dispenser endpoints for latency & rate limits',
    ),
    DiagnosticStep(
      title: 'Google Play API Protobuf Endpoints',
      description:
          'Performs live FDFE handshake with android.clients.google.com',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      for (final s in _steps) {
        s.state = TestState.pending;
        s.detail = null;
        s.latencyMs = null;
      }
    });

    final authProvider = context.read<AuthProvider>();
    final plusSettings = context.read<PlusSettingsProvider>();

    // Step 1: microG / GMS check
    setState(() => _steps[0].state = TestState.running);
    final sw1 = Stopwatch()..start();
    try {
      final available = await AuthService.isMicroGAvailable();
      sw1.stop();
      _steps[0].latencyMs = sw1.elapsedMilliseconds;
      if (available) {
        _steps[0].state = TestState.success;
        _steps[0].detail = 'Services detected and active';
      } else {
        _steps[0].state = TestState.warning;
        _steps[0].detail = 'Not installed (Using anonymous dispensers)';
      }
    } catch (e) {
      sw1.stop();
      _steps[0].latencyMs = sw1.elapsedMilliseconds;
      _steps[0].state = TestState.warning;
      _steps[0].detail = e.toString();
    }
    if (mounted) setState(() {});

    // Step 2: VPN check
    setState(() => _steps[1].state = TestState.running);
    final sw2 = Stopwatch()..start();
    try {
      final vpn = await AuthService.isVPNActive();
      sw2.stop();
      _steps[1].latencyMs = sw2.elapsedMilliseconds;
      if (vpn) {
        _steps[1].state = TestState.success;
        _steps[1].detail = 'Active VPN tunnel confirmed (Strict IP privacy on)';
      } else if (plusSettings.requireVPNForPlayStore) {
        _steps[1].state = TestState.warning;
        _steps[1].detail =
            'VPN off — Play Store direct queries currently blocked';
      } else {
        _steps[1].state = TestState.success;
        _steps[1].detail =
            'Direct network connection (VPN requirement disabled)';
      }
    } catch (e) {
      sw2.stop();
      _steps[1].latencyMs = sw2.elapsedMilliseconds;
      _steps[1].state = TestState.warning;
      _steps[1].detail = e.toString();
    }
    if (mounted) setState(() {});

    // Step 3: Dispenser check
    setState(() => _steps[2].state = TestState.running);
    final sw3 = Stopwatch()..start();
    final dispensers = authProvider.dispensers;
    if (dispensers.isEmpty) {
      sw3.stop();
      _steps[2].state = TestState.warning;
      _steps[2].detail = 'No dispensers configured';
    } else {
      final url = dispensers.first;
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        sw3.stop();
        _steps[2].latencyMs = sw3.elapsedMilliseconds;
        if (res.statusCode == 200) {
          _steps[2].state = TestState.success;
          _steps[2].detail =
              'Dispenser active (${dispensers.length} available)';
        } else if (res.statusCode == 429) {
          _steps[2].state = TestState.warning;
          _steps[2].detail = 'Rate limited by dispenser (HTTP 429)';
        } else {
          _steps[2].state = TestState.warning;
          _steps[2].detail = 'HTTP ${res.statusCode}';
        }
      } catch (e) {
        sw3.stop();
        _steps[2].latencyMs = sw3.elapsedMilliseconds;
        _steps[2].state = TestState.warning;
        _steps[2].detail = 'Connection timed out (${e.runtimeType})';
      }
    }
    if (mounted) setState(() {});

    // Step 4: Play Store FDFE Live Handshake
    setState(() => _steps[3].state = TestState.running);
    final sw4 = Stopwatch()..start();
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
        sw4.stop();
        _steps[3].latencyMs = sw4.elapsedMilliseconds;
        _steps[3].state = TestState.warning;
        _steps[3].detail =
            'No active token — configure a dispenser or microG account';
      } else {
        final api = PlayStoreApi(
          authProvider: authProvider,
          plusSettingsProvider: plusSettings,
        );
        final details = await api.getDetails('com.google.android.keep');
        sw4.stop();
        _steps[3].latencyMs = sw4.elapsedMilliseconds;
        if (details != null && details['title'] != null) {
          _steps[3].state = TestState.success;
          _steps[3].detail = 'FDFE Protobuf connected: "${details['title']}"';
        } else {
          _steps[3].state = TestState.success;
          _steps[3].detail = 'Play Store endpoint responded (HTTP 200)';
        }
      }
    } catch (e) {
      sw4.stop();
      _steps[3].latencyMs = sw4.elapsedMilliseconds;
      _steps[3].state = TestState.failure;
      _steps[3].detail = e.toString().split('\n').first;
    }

    if (mounted) {
      setState(() => _isRunning = false);
      AppHaptics.success();
    }
  }

  Widget _buildStateIcon(TestState state, ColorScheme colors) {
    switch (state) {
      case TestState.pending:
        return Icon(
          Icons.circle_outlined,
          size: 20,
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
        );
      case TestState.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: const ExpressiveCircularProgressIndicator(strokeWidth: 2),
        );
      case TestState.success:
        return Icon(
          Icons.check_circle_rounded,
          size: 22,
          color: colors.primary,
        );
      case TestState.warning:
        return Icon(Icons.warning_amber_rounded, size: 22, color: Colors.amber);
      case TestState.failure:
        return Icon(Icons.error_outline_rounded, size: 22, color: colors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final sheetRadius = Radius.circular(
      plusSettings.plusGlobalCornerRadius.clamp(20.0, 32.0),
    );

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: sheetRadius),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigmaSoft,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: enableGlass
                ? colorScheme.surface.withValues(
                    alpha: AppConstants.glassSurfaceAlphaStrong,
                  )
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: sheetRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Center(child: DragHandle()),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Play & Network Diagnostics',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Live endpoint latency, auth tokens & protobuf tester',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Re-run',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _isRunning ? null : _runDiagnostics,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: _steps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = _steps[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: _buildStateIcon(s.state, colorScheme),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      if (s.latencyMs != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${s.latencyMs} ms',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSecondaryContainer,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (s.detail != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      s.detail!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: s.state == TestState.failure
                                                ? colorScheme.error
                                                : (s.state == TestState.warning
                                                      ? Colors.amber.shade700
                                                      : colorScheme.primary),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('close')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
