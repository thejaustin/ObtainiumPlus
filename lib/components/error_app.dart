import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:obtainium/utils/startup_repair_service.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorApp extends StatefulWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({super.key, required this.error, required this.stackTrace});

  @override
  State<ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<ErrorApp> {
  bool _showRepair = false;

  @override
  void initState() {
    super.initState();
    _checkCrashLoop();
  }

  Future<void> _checkCrashLoop() async {
    final loop = await CrashAnalytics.isInCrashLoop();
    if (mounted) setState(() => _showRepair = loop);
  }

  Future<void> _reportToGitHub() async {
    await Sentry.captureMessage('User Feedback Triggered');
    final Uri url = Uri.parse(
      'https://github.com/thejaustin/ObtainiumPlus/issues/new?template=crash_report.md&logs=${Uri.encodeComponent("${widget.error}\n\n${widget.stackTrace}")}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _followIssue() async {
    final String urlStr = await CrashTracker.getSpecificIssueUrl();
    final Uri url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      home: Material(
        color: Colors.red.shade900,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Startup Recovery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bug_report_outlined,
                          color: Colors.white,
                        ),
                        onPressed: _reportToGitHub,
                        tooltip: tr('reportOnGitHub'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Obtainium+ encountered a persistent problem during launch. You can try to repair the app below:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Repair Actions Card
                  Card(
                    color: Colors.black26,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          _buildRepairTile(
                            context,
                            icon: Icons.image_not_supported_outlined,
                            title: 'Clear Icon Cache',
                            subtitle: 'Fixes crashes related to broken images',
                            onTap: () async {
                              await StartupRepairService.clearIconCache();
                              if (context.mounted) _showRepairComplete(context);
                            },
                          ),
                          _buildRepairTile(
                            context,
                            icon: Icons.layers_clear_outlined,
                            title: 'Clear Provider State',
                            subtitle: 'Resets corrupted app list data',
                            onTap: () async {
                              await StartupRepairService.clearProviderStates();
                              if (context.mounted) _showRepairComplete(context);
                            },
                          ),
                          _buildRepairTile(
                            context,
                            icon: Icons.restart_alt_outlined,
                            title: 'Factory Reset',
                            subtitle: 'Wipe all settings (Highly effective)',
                            isDestructive: true,
                            onTap: () async {
                              await StartupRepairService.factoryReset();
                              if (context.mounted) _showRepairComplete(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Technical Details:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.error,
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _reportToGitHub,
                        icon: const Icon(Icons.launch_outlined),
                        label: Text(tr('reportOnGitHub')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _followIssue,
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white70,
                        ),
                        label: Text(
                          tr('followIssue'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          widget.stackTrace,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepairTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.orangeAccent : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.orangeAccent : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: () => _confirmRepair(context, title, onTap),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  void _confirmRepair(
    BuildContext context,
    String action,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text('Are you sure you want to proceed with: $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRepairComplete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Repair Successful'),
        content: const Text(
          'The repair action has been applied. Please restart Obtainium+ to see if the issue is resolved.',
        ),
        actions: [
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Close App'),
          ),
        ],
      ),
    );
  }
}

class BuildErrorWidget extends StatelessWidget {
  final String error;
  final String stackTrace;

  const BuildErrorWidget({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Obtainium+ Build Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white70,
                        ),
                        tooltip: tr('followIssueOnGitHub'),
                        onPressed: () async {
                          final String urlStr =
                              await CrashTracker.getSpecificIssueUrl();
                          final Uri url = Uri.parse(urlStr);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.white),
                        tooltip: tr('reportOnGitHub'),
                        onPressed: () async {
                          await Sentry.captureMessage(
                            'User Feedback Triggered (Build Error)',
                          );
                          final Uri url = Uri.parse(
                            'https://github.com/thejaustin/ObtainiumPlus/issues/new?template=crash_report.md&logs=${Uri.encodeComponent("$error\n\n$stackTrace")}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  error,
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      stackTrace,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
