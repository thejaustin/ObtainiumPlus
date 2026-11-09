import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/settings/diagnostic_page_scaffold.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/play_store_api.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Opens the Play Store app inspector. Kept under its old name so callers
/// work; it's a page now (keyboard input plus long output).
Future<void> showPlayStoreInspectorSheet(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const PlayStoreInspectorPage()),
  );
}

/// Developer sandbox that queries the Google Play FDFE details and delivery
/// endpoints for one package.
class PlayStoreInspectorPage extends StatefulWidget {
  const PlayStoreInspectorPage({super.key});

  @override
  State<PlayStoreInspectorPage> createState() => _PlayStoreInspectorPageState();
}

class _PlayStoreInspectorPageState extends State<PlayStoreInspectorPage> {
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
        throw Exception(tr('playInspectorNoToken'));
      }

      final api = PlayStoreApi(
        authProvider: authProvider,
        plusSettingsProvider: plusSettings,
      );

      final details = await api.getDetails(pkg);
      sw.stop();

      if (details == null) {
        throw Exception(tr('playInspectorNotFound', args: [pkg]));
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
      SnackBar(
        content: Text(tr('playInspectorCopied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _metaRow(String label, String value) => ListTile(
    dense: true,
    title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final result = _result;
    final notes = (result?['recentChangesHtml'] as String?)
        ?.replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    return DiagnosticPageScaffold(
      title: tr('playInspectorTitle'),
      subtitle: tr('playInspectorSubtitle'),
      storageKey: 'play_inspector_scroll',
      actions: [
        IconButton(
          tooltip: tr('playInspectorCopyJson'),
          icon: const Icon(Icons.data_object_rounded),
          onPressed: result == null ? null : _copyResultJson,
        ),
      ],
      children: [
        ExpressiveSettingsGroup(
          title: tr('playInspectorQuery'),
          icon: Icons.manage_search_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _packageController,
                enabled: !_isLoading,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _inspectPackage(),
                decoration: InputDecoration(
                  labelText: tr('appId'),
                  hintText: 'com.google.android.keep',
                  prefixIcon: const Icon(Icons.android_rounded),
                  suffixIcon: IconButton(
                    tooltip: tr('playInspectorRun'),
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _isLoading ? null : () => _inspectPackage(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final sample in _quickSamples)
                    ActionChip(
                      label: Text(sample.split('.').last),
                      onPressed: _isLoading
                          ? null
                          : () => _inspectPackage(sample),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: ExpressiveCircularProgressIndicator()),
          ),
        if (_errorMessage != null)
          ExpressiveSettingsGroup(
            title: tr('playInspectorFailed'),
            icon: Icons.error_outline_rounded,
            children: [
              ListTile(
                leading: Icon(Icons.error_outline_rounded, color: cs.error),
                title: Text(_errorMessage!),
                subtitle: _queryLatencyMs == null
                    ? null
                    : Text(tr('diagLatencyMs', args: ['$_queryLatencyMs'])),
              ),
            ],
          ),
        if (result != null)
          ExpressiveSettingsGroup(
            title: (result['title'] as String?) ?? _packageController.text,
            description: result['developerName'] as String?,
            icon: Icons.shop_rounded,
            children: [
              _metaRow(
                tr('playInspectorLatency'),
                tr('diagLatencyMs', args: ['${_queryLatencyMs ?? '-'}']),
              ),
              _metaRow(
                tr('playInspectorVersionName'),
                result['versionString']?.toString() ?? '-',
              ),
              _metaRow(
                tr('playInspectorVersionCode'),
                result['versionCode']?.toString() ?? '-',
              ),
              _metaRow(
                tr('playInspectorStatus'),
                result['status']?.toString() ?? '-',
              ),
              _metaRow(
                tr('playInspectorSplits'),
                '${_deliveryUrls.length}',
              ),
              if (notes != null && notes.isNotEmpty)
                ListTile(
                  title: Text(tr('playInspectorReleaseNotes')),
                  subtitle: Text(notes),
                ),
            ],
          ),
      ],
    );
  }
}
