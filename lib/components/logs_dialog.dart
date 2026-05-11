import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

AndroidDeviceInfo? _cachedDeviceInfo;

class LogsDialog extends StatefulWidget {
  const LogsDialog({super.key});

  @override
  State<LogsDialog> createState() => _LogsDialogState();
}

class _LogsDialogState extends State<LogsDialog> {
  String? logString;
  List<int> days = [7, 5, 4, 3, 2, 1];
  final Future<AndroidDeviceInfo> _androidInfoFuture =
      DeviceInfoPlugin().androidInfo;
  late Future<List<Log>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = context.read<LogsProvider>().get(
      after: DateTime.now().subtract(const Duration(days: 7)),
    );
  }

  Future<void> _reportIssue() async {
    var logs = logString ?? '';
    if (logs.length > 2000) {
      logs = logs.substring(logs.length - 2000);
    }

    var appInfo = await AppInstallService.getInstalledInfo(obtainiumId);
    var deviceInfo = _cachedDeviceInfo;
    var androidInfo = await _androidInfoFuture;

    var body =
        '''${tr('reportIssue')}

App: $appInfo
Device: $deviceInfo
Android: $androidInfo

$logs''';

    var url = Uri.parse(
      'https://github.com/thejaustin/ObtainiumPlus/issues/new?body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: url.toString()));
      showMessage(tr('copiedToClipboard'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withOpacity(0.18)
                : colorScheme.outline.withOpacity(AppOpacity.subtle),
            width: 1,
          ),
          boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.28 : 0.1,
            blurFactor: enableGlass ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ConditionalBlur(
            sigma: 24,
            enabled: enableGlass,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, enableGlass),
                const Divider(height: 1),
                Flexible(child: _buildContent(context)),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(enableGlass ? 0.3 : 0.5),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(
              enableGlass ? 0.15 : 0.25,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(AppOpacity.low),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bug_report_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tr('appLogs'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return logString != null
        ? Container(
            padding: const EdgeInsets.all(16),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withOpacity(AppOpacity.half),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    logString!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          )
        : FutureBuilder<List<Log>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final logs = snapshot.data!;
                logString = logs
                    .map(
                      (log) =>
                          '[${log.level.name}] ${log.timestamp}: ${log.message}',
                    )
                    .join('\n');
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(AppOpacity.half),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          logString ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: ExpressiveCircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
            },
          );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(AppOpacity.medium),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('close')),
          ),
          TextButton(
            onPressed: () {
              context.read<LogsProvider>().clear();
              Navigator.of(context).pop();
            },
            child: Text(tr('clearCache')),
          ),
          TextButton.icon(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () {
              _reportIssue();
              Navigator.of(context).pop();
            },
            label: Text(tr('reportIssue')),
          ),
        ],
      ),
    );
  }
}
