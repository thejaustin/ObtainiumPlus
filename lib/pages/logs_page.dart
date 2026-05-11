import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String? logString;
  final Future<AndroidDeviceInfo> _androidInfoFuture =
      DeviceInfoPlugin().androidInfo;
  // Use a variable to store cached device info if needed, similar to settings page
  AndroidDeviceInfo? _cachedDeviceInfo;
  late Future<List<Log>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _androidInfoFuture.then((info) => _cachedDeviceInfo = info);
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
    var deviceInfo = _cachedDeviceInfo ?? await _androidInfoFuture;
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

  void showMessage(String message, BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(tr('appLogs')),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: tr('copyToClipboard'),
                onPressed: () {
                  if (logString != null) {
                    Clipboard.setData(ClipboardData(text: logString!));
                    showMessage(tr('copiedToClipboard'), context);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: tr('clearCache'),
                onPressed: () {
                  context.read<LogsProvider>().clear();
                  setState(() {
                    logString = null;
                    _logsFuture = context.read<LogsProvider>().get(
                      after: DateTime.now().subtract(const Duration(days: 7)),
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: tr('reportIssue'),
                onPressed: _reportIssue,
              ),
            ],
            floating: true,
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Log>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final logs = snapshot.data!;
                    if (logs.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: tr('noLogs'),
                        subtitle: tr('noRecentActivity'),
                      );
                    }
                    logString = logs
                        .map(
                          (log) =>
                              '[${log.level.name}] ${log.timestamp}: ${log.message}',
                        )
                        .join('\n');
                    return SelectableText(logString ?? '');
                  } else {
                    return const Center(
                      child: ExpressiveCircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
