import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/components/settings/diagnostic_page_scaffold.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/services/play_store_api.dart';
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

/// Opens the Google Play & network diagnostics. Kept under its old name so
/// callers work; it's a page now, like the other diagnostic reports.
Future<void> showPlayStoreDiagnosticSheet(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const PlayStoreDiagnosticPage()),
  );
}

/// Step-by-step check of microG, VPN, token dispensers and the Play API.
class PlayStoreDiagnosticPage extends StatefulWidget {
  /// False skips the automatic run on open (tests; no network).
  final bool autoRun;

  const PlayStoreDiagnosticPage({super.key, this.autoRun = true});

  @override
  State<PlayStoreDiagnosticPage> createState() =>
      _PlayStoreDiagnosticPageState();
}

class _PlayStoreDiagnosticPageState extends State<PlayStoreDiagnosticPage> {
  bool _isRunning = false;

  late final List<DiagnosticStep> _steps = [
    DiagnosticStep(
      title: tr('playDiagGmsTitle'),
      description: tr('playDiagGmsDesc'),
    ),
    DiagnosticStep(
      title: tr('playDiagVpnTitle'),
      description: tr('playDiagVpnDesc'),
    ),
    DiagnosticStep(
      title: tr('playDiagDispenserTitle'),
      description: tr('playDiagDispenserDesc'),
    ),
    DiagnosticStep(
      title: tr('playDiagApiTitle'),
      description: tr('playDiagApiDesc'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoRun) _runDiagnostics();
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
        _steps[0].detail = tr('playDiagGmsOk');
      } else {
        _steps[0].state = TestState.warning;
        _steps[0].detail = tr('playDiagGmsMissing');
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
        _steps[1].detail = tr('playDiagVpnOn');
      } else if (plusSettings.requireVPNForPlayStore) {
        _steps[1].state = TestState.warning;
        _steps[1].detail = tr('playDiagVpnRequired');
      } else {
        _steps[1].state = TestState.success;
        _steps[1].detail = tr('playDiagVpnOff');
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
      _steps[2].detail = tr('playDiagNoDispensers');
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
          _steps[2].detail = tr(
            'playDiagDispenserOk',
            args: ['${dispensers.length}'],
          );
        } else if (res.statusCode == 429) {
          _steps[2].state = TestState.warning;
          _steps[2].detail = tr('playDiagRateLimited');
        } else {
          _steps[2].state = TestState.warning;
          _steps[2].detail = 'HTTP ${res.statusCode}';
        }
      } catch (e) {
        sw3.stop();
        _steps[2].latencyMs = sw3.elapsedMilliseconds;
        _steps[2].state = TestState.warning;
        _steps[2].detail = tr('playDiagTimedOut', args: ['${e.runtimeType}']);
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
        _steps[3].detail = tr('playInspectorNoToken');
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
          _steps[3].detail = tr(
            'playDiagApiOk',
            args: ['${details['title']}'],
          );
        } else {
          _steps[3].state = TestState.success;
          _steps[3].detail = tr('playDiagApiResponded');
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

  Widget _stateIcon(TestState state, ColorScheme cs) {
    switch (state) {
      case TestState.pending:
        return Icon(Icons.radio_button_unchecked_rounded, color: cs.outline);
      case TestState.running:
        return const SizedBox(
          width: 24,
          height: 24,
          child: ExpressiveCircularProgressIndicator(strokeWidth: 2.5),
        );
      case TestState.success:
        return Icon(Icons.check_circle_rounded, color: cs.primary);
      case TestState.warning:
        return Icon(Icons.warning_amber_rounded, color: cs.tertiary);
      case TestState.failure:
        return Icon(Icons.error_rounded, color: cs.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DiagnosticPageScaffold(
      title: tr('playDiagTitle'),
      subtitle: tr('playDiagSubtitle'),
      storageKey: 'play_diagnostic_scroll',
      actions: [
        IconButton(
          tooltip: tr('diagRunAgain'),
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _isRunning ? null : _runDiagnostics,
        ),
      ],
      children: [
        ExpressiveSettingsGroup(
          title: tr('playDiagChecks'),
          icon: Icons.network_check_rounded,
          children: [
            for (final step in _steps)
              ListTile(
                leading: _stateIcon(step.state, cs),
                title: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  step.detail ?? step.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: step.state == TestState.failure
                      ? TextStyle(color: cs.error)
                      : null,
                ),
                trailing: step.latencyMs == null
                    ? null
                    : Text(
                        tr('diagLatencyMs', args: ['${step.latencyMs}']),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
