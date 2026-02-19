import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
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
  final Future<AndroidDeviceInfo> _androidInfoFuture = DeviceInfoPlugin().androidInfo;

  Future<void> _reportIssue() async {
    var logs = logString ?? '';
    if (logs.length > 2000) {
      logs = logs.substring(logs.length - 2000);
    }

    var appInfo = await AppInstallService.getInstalledInfo(obtainiumId);
    var deviceInfo = _cachedDeviceInfo;
    var androidInfo = await _androidInfoFuture;

    var body = '''${tr('reportIssue')}

App: $appInfo
Device: $deviceInfo
Android: $androidInfo

$logs''';

    var url = Uri.parse(
      'https://github.com/thejaustin/ObtainiumPlus/issues/new?body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      Clipboard.setData(ClipboardData(text: url.toString()));
      showMessage(tr('copiedToClipboard'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('appLogs')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
        child: logString != null
            ? Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Text(logString!),
                ),
              )
            : FutureBuilder<List<Log>>(
                future: context.read<LogsProvider>().get(after: DateTime.now().subtract(const Duration(days: 7))),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final logs = snapshot.data!;
                    logString = logs.map((log) => '[${log.level.name}] ${log.timestamp}: ${log.message}').join('\n');
                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(logString ?? ''),
                      ),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
      ),
      actions: [
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
        TextButton(
          onPressed: () {
            _reportIssue();
            Navigator.of(context).pop();
          },
          child: Text(tr('reportIssue')),
        ),
      ],
    );
  }
}
