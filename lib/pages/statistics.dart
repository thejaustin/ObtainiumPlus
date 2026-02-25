import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:intl/intl.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<Log>> _logsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch logs from the last 30 days
    _logsFuture = context.read<LogsProvider>().get(
      after: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<void> _exportStats(List<Log> logs, int totalApps, int installedApps, int updatesAvailable) async {
    final stats = {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': {
        'totalApps': totalApps,
        'installedApps': installedApps,
        'updatesAvailable': updatesAvailable,
      },
      'logs': logs.map((l) => l.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(stats);
    await Share.share(jsonStr, subject: 'Obtainium_Stats_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final allApps = appsProvider.getAppValues().toList();
    
    // Calculate current snapshot metrics
    final totalApps = allApps.length;
    final installedApps = allApps.where((a) => a.installedInfo != null).length;
    final notInstalledApps = totalApps - installedApps;
    final updatesAvailable = allApps.where((a) => 
      a.app.installedVersion != null && 
      a.app.latestVersion != a.app.installedVersion
    ).length;
    
    // Calculate pinned apps
    final pinnedApps = allApps.where((a) => a.app.pinned).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('statistics')),
        actions: [
          FutureBuilder<List<Log>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _exportStats(snapshot.data!, totalApps, installedApps, updatesAvailable),
                tooltip: tr('share'),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Log>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error loading stats: ${snapshot.error}'));
          }

          if (totalApps == 0) {
            return EmptyStateWidget(
              icon: Icons.bar_chart_outlined,
              title: tr('noApps'),
              subtitle: tr('startByAddingFirstApp'),
              actionLabel: tr('addApp'),
              onActionPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => const AddAppPage(),
                );
              },
            );
          }

          final logs = snapshot.data ?? [];

          // Parse logs for history
          // Look for 'EVENT: InstallCompleted | ... success=true'
          final installEvents = logs.where((l) => 
            l.message.contains('EVENT: InstallCompleted') && 
            l.message.contains('success=true')
          ).toList();
          
          final successfulInstalls30Days = installEvents.length;
          
          // Last 7 days
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          final successfulInstalls7Days = installEvents.where((l) => 
            l.timestamp.isAfter(sevenDaysAgo)
          ).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, tr('overview')),
                const SizedBox(height: 8),
                _buildMetricsGrid(context, [
                  _MetricItem(
                    label: tr('totalApps'),
                    value: totalApps.toString(),
                    icon: Icons.apps,
                    color: Colors.blue,
                  ),
                  _MetricItem(
                    label: tr('installed'),
                    value: installedApps.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  _MetricItem(
                    label: tr('updatesAvailable'),
                    value: updatesAvailable.toString(),
                    icon: Icons.system_update,
                    color: Colors.orange,
                  ),
                  _MetricItem(
                    label: tr('notInstalled'),
                    value: notInstalledApps.toString(),
                    icon: Icons.cloud_off,
                    color: Colors.grey,
                  ),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionTitle(context, tr('activity')),
                const SizedBox(height: 8),
                _buildMetricsGrid(context, [
                  _MetricItem(
                    label: tr('installs30Days'),
                    value: successfulInstalls30Days.toString(),
                    icon: Icons.history,
                    color: Colors.purple,
                  ),
                  _MetricItem(
                    label: tr('installs7Days'),
                    value: successfulInstalls7Days.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.teal,
                  ),
                  _MetricItem(
                    label: tr('pinnedApps'),
                    value: pinnedApps.toString(),
                    icon: Icons.push_pin,
                    color: Colors.redAccent,
                  ),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle(context, tr('recentInstalls')),
                const SizedBox(height: 8),
                _buildRecentHistoryList(context, installEvents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, List<_MetricItem> items) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
                  sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
                ),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: (isDark 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest 
                      : Theme.of(context).colorScheme.surface)
                    .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(
                        alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: item.color, size: 24),
                        const Spacer(),
                        Text(
                          item.value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentHistoryList(BuildContext context, List<Log> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            tr('noRecentActivity'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Sort by timestamp descending
    final sortedEvents = List<Log>.from(events)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentEvents = sortedEvents.take(10).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentEvents.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final event = recentEvents[index];
          // Extract appId from message "EVENT: InstallCompleted | appId=..., success=true"
          String appId = 'Unknown';
          final match = RegExp(r'appId=([^,]+)').firstMatch(event.message);
          if (match != null) {
            appId = match.group(1)?.trim() ?? 'Unknown';
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.download_done, color: Colors.green, size: 20),
            ),
            title: Text(appId),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(event.timestamp)),
            dense: true,
          );
        },
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
