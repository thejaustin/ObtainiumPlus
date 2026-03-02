import 'package:flutter/material.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/pages/plugin_manager.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:flutter/services.dart';

class DeveloperSettingsPage extends StatelessWidget {
  const DeveloperSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer & Diagnostics'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Experimental Plugins & Play Store',
            [
              ListTile(
                leading: const Icon(Icons.token_outlined),
                title: Row(
                  children: [
                    const Text('Manage Token Dispensers'),
                    const InfoTooltip(message: 'Dispensers provide anonymous login tokens (AAS) to access the Google Play Store natively.'),
                  ],
                ),
                subtitle: const Text('Configure Aurora-style anonymous login dispensers'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDispenserManager(context),
              ),
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: Row(
                  children: [
                    const Text('Plugin Manager'),
                    const InfoTooltip(message: 'Plugins are JavaScript "Recipes" that allow the app to scrape or download from new sources without a full update.'),
                  ],
                ),
                subtitle: const Text('Add and manage custom source plugins (JS)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PluginManagerPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phonelink_setup_outlined),
                title: Row(
                  children: [
                    const Text('Device Spoofing (microG)'),
                    const InfoTooltip(message: 'Uses your system GSF ID or a custom profile to trick Google Play into serving app versions for specific devices or regions.'),
                  ],
                ),
                subtitle: const Text('View and spoof device identifiers for GMS'),
                onTap: () => _showSpoofingManager(context),
              ),
            ],
          ),
          _buildSection(
            context,
            'Diagnostics',
            [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Row(
                  children: [
                    const Text('View Talker Logs'),
                    const InfoTooltip(message: 'Talker is a "Flight Data Recorder" that captures all network requests, UI navigation, and errors in real-time.'),
                  ],
                ),
                subtitle: const Text('Advanced in-app logs, network, and errors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TalkerScreen(talker: talker),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: Row(
                  children: [
                    const Text('Crash Statistics'),
                    const InfoTooltip(message: 'Shows how often the app has crashed and what types of errors (e.g., Timeout, FormatException) occurred.'),
                  ],
                ),
                subtitle: const Text('Local crash frequency and types'),
                onTap: () async {
                  final stats = await CrashAnalytics.getStats();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Local Crash Stats'),
                        content: Text(
                          'Total Crashes: ${stats.totalCrashes}\n'
                          'Last Crash: ${stats.lastCrashTime ?? "Never"}\n'
                          'Types: ${stats.crashTypes.join(", ")}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Standard App Logs'),
                subtitle: const Text('Legacy obtainium logs'),
                onTap: () => context.read<LogsProvider>().get().then((logs) {
                  if (logs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No logs found')),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TalkerScreen(talker: talker),
                      ),
                    );
                  }
                }),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Row(
                  children: [
                    const Text('Upload Logs to New Issue'),
                    const InfoTooltip(message: 'Quickly creates a pre-formatted GitHub issue with your current diagnostic logs attached for easier bug reports.'),
                  ],
                ),
                subtitle: const Text('Creates a GitHub issue with current logs'),
                onTap: () async {
                  final history = talker.history.reversed.take(200).toList().reversed;
                  final logText = history.map((e) => '[${e.title}] ${e.message}').join('\n');
                  
                  final body = Uri.encodeComponent(
                    "## Diagnostic Logs Report\n\n"
                    "**Device info:** (Include manually or check Sentry)\n\n"
                    "### Logs:\n```\n$logText\n```"
                  );
                  
                  final url = 'https://github.com/thejaustin/ObtainiumPlus/issues/new?title=[Bug]+Diagnostic+Report&body=$body';
                  
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          _buildSection(
            context,
            'Testing',
            [
              ListTile(
                leading: const Icon(Icons.flash_on_outlined),
                iconColor: Colors.red,
                title: Row(
                  children: [
                    const Text('Trigger Test Crash'),
                    const InfoTooltip(message: 'Forces a simulated error to verify that Sentry (remote) and Talker (local) are capturing crashes correctly.'),
                  ],
                ),
                subtitle: const Text('Forces a crash to verify Sentry/Talker integration'),
                onTap: () {
                  talker.warning('User triggered a test crash');
                  throw Exception('Obtainium+ Test Crash');
                },
              ),
              ListTile(
                leading: const Icon(Icons.network_check_outlined),
                title: Row(
                  children: [
                    const Text('Test Network Logging'),
                    const InfoTooltip(message: 'Triggers a dummy request to verify that network calls are being intercepted and logged correctly.'),
                  ],
                ),
                subtitle: const Text('Triggers a dummy request to verify network logs'),
                onTap: () async {
                  talker.info('Triggering test network request...');
                  try {
                    // ignore: unused_local_variable
                    final response = await SentryHttpClient().get(Uri.parse('https://api.github.com/zen'));
                    talker.info('Test network request successful');
                  } catch (e, st) {
                    talker.handle(e, st, 'Test network request failed');
                  }
                },
              ),
            ],
          ),
          _buildSection(
            context,
            'External Links',
            [
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('View Sentry Project'),
                onTap: () => launchUrlString(
                  'https://sentry.io/organizations/af-developments/projects/obtainiumplus/',
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('GitHub Issue Tracker'),
                onTap: () => launchUrlString(
                  CrashTracker.issueTrackerUrl,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showDispenserManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DispenserManagerSheet(),
    );
  }

  void _showSpoofingManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SpoofingManagerSheet(),
    );
  }
}

class _SpoofingManagerSheet extends StatefulWidget {
  const _SpoofingManagerSheet();

  @override
  State<_SpoofingManagerSheet> createState() => _SpoofingManagerSheetState();
}

class _SpoofingManagerSheetState extends State<_SpoofingManagerSheet> {
  static const _platform = MethodChannel('app.obtainiumplus/native');
  String _gsfId = 'Checking...';

  @override
  void initState() {
    super.initState();
    _getGsfId();
  }

  Future<void> _getGsfId() async {
    try {
      final String result = await _platform.invokeMethod('getGsfId');
      setState(() => _gsfId = result);
    } on PlatformException catch (e) {
      setState(() => _gsfId = 'Failed to get GSF ID: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phonelink_setup_outlined, size: 48),
          const SizedBox(height: 16),
          Text('Device Identifier Spoofing', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Current GSF ID'),
            subtitle: Text(_gsfId),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getGsfId,
            ),
          ),
          const Divider(),
          const Text(
            'microG Spoofing is active when a custom GSF ID or Device Profile is selected. This allows the app to bypass regional and device restrictions on the Play Store.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DispenserManagerSheet extends StatefulWidget {
  const _DispenserManagerSheet();

  @override
  State<_DispenserManagerSheet> createState() => _DispenserManagerSheetState();
}

class _DispenserManagerSheetState extends State<_DispenserManagerSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Token Dispensers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Dispensers provide anonymous login tokens for Google Play access.',
            textAlign: TextAlign.center,
          ),
          if (authProvider.hasActiveToken)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                label: Text('Active: ${authProvider.activeBundle!.email}'),
                onDeleted: authProvider.clearBundle,
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: authProvider.dispensers.map((d) => ListTile(
                title: Text(d),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => authProvider.removeDispenser(d),
                    ),
                  ],
                ),
                onTap: _isLoading ? null : () => _testDispenser(context, authProvider, d),
              )).toList(),
            ),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add Dispenser URL',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    authProvider.addDispenser(_controller.text);
                    _controller.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _testDispenser(BuildContext context, AuthProvider authProvider, String url) async {
    setState(() => _isLoading = true);
    try {
      await authProvider.refreshBundle(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully retrieved token!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
