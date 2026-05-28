import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:intl/intl.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/utils/app_constants.dart';

class StatisticsPage extends StatefulWidget {
  final ScrollController? scrollController;
  const StatisticsPage({super.key, this.scrollController});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final Future<List<Log>> _logsFuture;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _logsFuture = context.read<LogsProvider>().get(
      after: DateTime.now().subtract(const Duration(days: 30)),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _exportStats(
    List<Log> logs,
    int totalApps,
    int installedApps,
    int updatesAvailable,
  ) async {
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

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Obtainium_Stats_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([
        XFile(file.path, name: fileName, mimeType: 'application/json'),
      ], subject: fileName);
    } catch (e) {
      if (mounted) {
        showError(e, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final allApps = appsProvider.getAppValues().toList();

    final totalApps = allApps.length;
    final installedApps = allApps.where((a) => a.installedInfo != null).length;
    final notInstalledApps = totalApps - installedApps;
    final updatesAvailable = allApps
        .where(
          (a) =>
              a.app.installedVersion != null &&
              a.app.latestVersion != a.app.installedVersion,
        )
        .length;
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
                onPressed: () => _exportStats(
                  snapshot.data!,
                  totalApps,
                  installedApps,
                  updatesAvailable,
                ),
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
            return const Center(child: ExpressiveCircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('error'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (totalApps == 0) {
            return EmptyStateWidget(
              icon: Icons.bar_chart_outlined,
              title: tr('noApps'),
              subtitle: tr('startByAddingFirstApp'),
              actionLabel: tr('addApp'),
              onActionPressed: () {
                AppHaptics.lightImpact();
                showDraggableModalBottomSheet(
                  context: context,
                  builder: (context, controller) => AddAppPage(
                    isModal: true,
                    scrollController: controller,
                  ),
                );
              },
            );
          }

          final logs = snapshot.data ?? [];

          final installEvents = logs
              .where(
                (l) =>
                    l.message.contains('EVENT: InstallCompleted') &&
                    l.message.contains('success=true'),
              )
              .toList();

          final successfulInstalls30Days = installEvents.length;

          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          final successfulInstalls7Days = installEvents
              .where((l) => l.timestamp.isAfter(sevenDaysAgo))
              .length;

          return SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpressiveSettingsGroup(
                  title: tr('overview'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMetricsGrid(context, [
                        _MetricItem(
                          label: tr('totalApps'),
                          value: totalApps.toString(),
                          icon: Icons.apps_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _MetricItem(
                          label: tr('installed'),
                          value: installedApps.toString(),
                          icon: Icons.check_circle_outline_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        _MetricItem(
                          label: tr('updatesAvailable'),
                          value: updatesAvailable.toString(),
                          icon: Icons.system_update_rounded,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        _MetricItem(
                          label: tr('notInstalled'),
                          value: notInstalledApps.toString(),
                          icon: Icons.cloud_off_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ]),
                    ),
                  ],
                ),

                ExpressiveSettingsGroup(
                  title: tr('activity'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMetricsGrid(context, [
                        _MetricItem(
                          label: tr('installs30Days'),
                          value: successfulInstalls30Days.toString(),
                          icon: Icons.history_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _MetricItem(
                          label: tr('installs7Days'),
                          value: successfulInstalls7Days.toString(),
                          icon: Icons.calendar_today_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        _MetricItem(
                          label: tr('pinnedApps'),
                          value: pinnedApps.toString(),
                          icon: Icons.push_pin_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    _buildActivityChart(context, installEvents),
                    const SizedBox(height: 24),
                    _buildDistributionSection(context, allApps),
                    const SizedBox(height: 16),
                  ],
                ),

                ExpressiveSettingsGroup(
                  title: tr('recentInstalls'),
                  children: [_buildRecentHistoryList(context, installEvents)],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistributionSection(
    BuildContext context,
    List<AppInMemory> apps,
  ) {
    if (apps.isEmpty) return const SizedBox.shrink();

    final Map<String, int> categoryCounts = {};
    for (var app in apps) {
      if (app.app.categories.isEmpty) {
        categoryCounts[tr('uncategorized')] =
            (categoryCounts[tr('uncategorized')] ?? 0) + 1;
      } else {
        for (var cat in app.app.categories) {
          categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        }
      }
    }

    final Map<String, int> sourceCounts = {};
    for (var app in apps) {
      String source = 'Other';
      final url = app.app.url.toLowerCase();
      if (url.contains('github.com'))
        source = 'GitHub';
      else if (url.contains('gitlab.com'))
        source = 'GitLab';
      else if (url.contains('f-droid.org'))
        source = 'F-Droid';
      else if (url.contains('play.google.com'))
        source = 'Play Store';
      else if (url.contains('apkpure.com'))
        source = 'APKPure';
      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistributionBar(
            context,
            title: tr('categoryDistribution'),
            counts: categoryCounts,
            total: apps.length,
          ),
          const SizedBox(height: 24),
          _buildDistributionBar(
            context,
            title: tr('sourceDistribution'),
            counts: sourceCounts,
            total: apps.length,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(
    BuildContext context, {
    required String title,
    required Map<String, int> counts,
    required int total,
  }) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(4).toList();
    if (sortedEntries.length > 4) {
      final othersCount = sortedEntries
          .skip(4)
          .fold(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry(tr('others'), othersCount));
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.outline,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Animated distribution bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                return Row(
                  children: topEntries.asMap().entries.map((e) {
                    final fraction = e.value.value / total;
                    if (fraction <= 0) return const SizedBox.shrink();
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: fraction),
                      duration: Duration(milliseconds: 500 + e.key * 100),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Container(
                        width: (totalWidth * value).clamp(0.0, totalWidth),
                        color: colors[e.key % colors.length],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: topEntries.asMap().entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${e.value.key} (${(e.value.value / total * 100).toInt()}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, List<_MetricItem> items) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final itemRadius = (radius * 0.75).clamp(12.0, 24.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final start = (index * 0.08).clamp(0.0, 0.6);
            final end = (start + 0.55).clamp(0.0, 1.0);

            final opacity = CurvedAnimation(
              parent: _entranceController,
              curve: Interval(start, end, curve: Curves.easeOut),
            );
            final slide =
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  ),
                );

            return FadeTransition(
              opacity: opacity,
              child: SlideTransition(
                position: slide,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(itemRadius),
                  child: ConditionalBlur(
                    sigma: 12,
                    enabled: settings.plusEnableGlassmorphism,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow
                            .withOpacity(
                              settings.plusEnableGlassmorphism ? 0.5 : 1.0,
                            ),
                        borderRadius: BorderRadius.circular(itemRadius),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(
                            settings.plusEnableGlassmorphism ? 0.12 : 0.08,
                          ),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                color: item.color,
                                size: 18,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.value,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildActivityChart(BuildContext context, List<Log> events) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final Map<int, int> dailyCounts = {};
    for (int i = 0; i < 30; i++) {
      dailyCounts[i] = 0;
    }

    for (var event in events) {
      final daysAgo = now.difference(event.timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        dailyCounts[daysAgo] = (dailyCounts[daysAgo] ?? 0) + 1;
      }
    }

    final counts = List<int>.generate(30, (i) => dailyCounts[29 - i] ?? 0);
    final maxCount = counts.isEmpty
        ? 0
        : counts.reduce((a, b) => a > b ? a : b);
    final primaryColor = theme.colorScheme.primary;
    final bgColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final progress = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ).value;
        return Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.05),
            ),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _ActivityPainter(
              counts: counts,
              maxCount: maxCount,
              color: primaryColor,
              progress: progress,
            ),
          ),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final sortedEvents = List<Log>.from(events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentEvents = sortedEvents.take(10).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentEvents.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (context, index) {
        final event = recentEvents[index];
        String appId = 'Unknown';
        final match = RegExp(r'appId=([^,]+)').firstMatch(event.message);
        if (match != null) {
          appId = match.group(1)?.trim() ?? 'Unknown';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.download_done_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(appId),
          subtitle: Text(DateFormat.yMMMd().add_jm().format(event.timestamp)),
          dense: true,
        );
      },
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

class _ActivityPainter extends CustomPainter {
  final List<int> counts;
  final int maxCount;
  final Color color;
  final double progress;

  _ActivityPainter({
    required this.counts,
    required this.maxCount,
    required this.color,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty || maxCount == 0) return;

    final clipWidth = size.width * progress;
    canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, size.height));

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(AppOpacity.medium), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    final stepX = size.width / (counts.length - 1);
    final scaleY = size.height / (maxCount * 1.2);

    for (int i = 0; i < counts.length; i++) {
      final x = i * stepX;
      final y = size.height - (counts[i] * scaleY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (counts[i - 1] * scaleY);
        path.cubicTo(prevX + stepX / 2, prevY, x - stepX / 2, y, x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < counts.length; i++) {
      if (counts[i] > 0) {
        final x = i * stepX;
        final y = size.height - (counts[i] * scaleY);
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter old) =>
      old.progress != progress ||
      old.maxCount != maxCount ||
      old.color != color ||
      old.counts.length != counts.length;
}
