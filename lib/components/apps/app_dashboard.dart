import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/statistics.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:obtainium/utils/app_constants.dart';

class AppDashboard extends StatefulWidget {
  final String currentFilterMode;
  final Function(String) onFilterChanged;
  final Function(String) onSearchQuery;
  final Function(String) onUrlInput;
  final VoidCallback onCheckUpdates;

  const AppDashboard({
    super.key,
    required this.currentFilterMode,
    required this.onFilterChanged,
    required this.onSearchQuery,
    required this.onUrlInput,
    required this.onCheckUpdates,
  });

  @override
  State<AppDashboard> createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _card0Anim;
  late Animation<double> _card1Anim;
  late Animation<double> _card2Anim;
  late Animation<double> _segmentedAnim;
  late Animation<double> _updatesAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // M3 Expressive: emphasizedDecelerate for enter animations (fast start, soft settle)
    const curve = Easing.emphasizedDecelerate;
    _card0Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: curve),
    );
    _card1Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.63, curve: curve),
    );
    _card2Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.16, 0.71, curve: curve),
    );
    _segmentedAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.83, curve: curve),
    );
    _updatesAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 1.0, curve: curve),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Wraps a child with a fade + vertical slide entrance animation.
  Widget _animated(Animation<double> anim, Widget child) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final apps = appsProvider.getAppValues();
    final totalApps = apps.length;

    final updateApps = apps
        .where(
          (app) =>
              app.app.installedVersion != null &&
              AppUpdateService.areVersionsDifferent(
                app.app,
                app.app.installedVersion,
                app.app.latestVersion,
              ),
        )
        .toList();
    final updatesAvailable = updateApps.length;

    final pinnedApps = apps.where((app) => app.app.pinned).toList();

    DateTime? lastCheck;
    for (var app in apps) {
      if (app.app.lastUpdateCheck != null) {
        if (lastCheck == null || app.app.lastUpdateCheck!.isAfter(lastCheck)) {
          lastCheck = app.app.lastUpdateCheck;
        }
      }
    }

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Operations Hub (visible during selection)
          if (appsProvider.isSelectionMode)
            _animated(
              _card0Anim,
              _buildBatchActionsHub(context, appsProvider, radius),
            )
          else ...[
            // Omnibar - Unified Search/Add
            if (settings.plusShowDashboardSearch) ...[
              Omnibar(
                onSearchQuery: widget.onSearchQuery,
                onUrlInput: widget.onUrlInput,
              ),
              const SizedBox(height: 20),
            ],

            // Summary cards — staggered M3 entrance
            if (appsProvider.plusSettings.plusShowStatusHub)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  _animated(
                    _card0Anim,
                    _buildSummaryCard(
                      context,
                      icon: Icons.apps_rounded,
                      label: tr('appsString'),
                      value: totalApps.toString(),
                      color: colorScheme.primary,
                      onTap: () => widget.onFilterChanged('all'),
                      onLongPress: () {
                        AppHaptics.heavyImpact();
                        appsProvider.selectAll();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _animated(
                    _card1Anim,
                    _buildSummaryCard(
                      context,
                      icon: Icons.update_rounded,
                      label: tr('updates'),
                      value: updatesAvailable.toString(),
                      color: updatesAvailable > 0
                          ? colorScheme.error
                          : colorScheme.secondary,
                      onTap: () {
                        if (updatesAvailable > 0) {
                          widget.onFilterChanged('updates');
                        } else {
                          widget.onCheckUpdates();
                        }
                      },
                      onLongPress: updatesAvailable > 0
                          ? () {
                              AppHaptics.heavyImpact();
                              appsProvider.downloadAndInstallLatestApps(
                                updateApps.map((e) => e.app.id).toList(),
                                context,
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _animated(
                    _card2Anim,
                    _buildSummaryCard(
                      context,
                      icon: Icons.history_rounded,
                      label: tr('lastCheck'),
                      value: lastCheck != null
                          ? DateFormat.Md().add_jm().format(lastCheck.toLocal())
                          : tr('never'),
                      color: colorScheme.tertiary,
                      onTap: widget.onCheckUpdates,
                    ),
                  ),

                  // Storage Hub Card
                  const SizedBox(width: 12),
                  _animated(
                    _updatesAnim,
                    _buildSummaryCard(
                      context,
                      icon: Icons.storage_rounded,
                      label: tr('storage'),
                      value: tr('clean'),
                      color: colorScheme.secondary,
                      onTap: () async {
                        AppHaptics.selectionClick();
                        final count = await AppFileService.clearAllDownloadedApks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('clearedXApks', args: [count.toString()])),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Pinned Apps Quick Access (Horizontal Scroll)
          if (pinnedApps.isNotEmpty)
            _animated(
              _updatesAnim,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('pinnedApps'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pinnedApps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildPinnedIcon(context, pinnedApps[index], radius),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

          // Quick Actions Grid
          if (appsProvider.plusSettings.plusShowQuickActions) ...[
            _animated(
              _updatesAnim,
              _buildQuickActionsGrid(context, radius, colorScheme),
            ),
            const SizedBox(height: 24),
          ],

          // Filter mode segmented button — slides in after cards
          _animated(
            _segmentedAnim,
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'all',
                    label: Text(tr('all')),
                    icon: const Icon(Icons.apps_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 'updates',
                    label: Text(tr('updates')),
                    icon: const Icon(Icons.update_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 'installed',
                    label: Text(tr('installed')),
                    icon: const Icon(Icons.install_mobile_rounded, size: 18),
                  ),
                ],
                selected: {widget.currentFilterMode},
                onSelectionChanged: (Set<String> selection) {
                  AppHaptics.selectionClick();
                  widget.onFilterChanged(selection.first);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedForegroundColor: colorScheme.onSecondaryContainer,
                  selectedBackgroundColor: colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius * 0.66),
                  ),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(
                      settings.plusEnableGlassmorphism ? 0.3 : 0.15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recent updates — Adaptive Hide + AnimatedSize
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Easing.emphasizedDecelerate,
            child:
                (updatesAvailable > 0 &&
                    (totalApps >= 5 || updatesAvailable > 1))
                ? _animated(
                    _updatesAnim,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              tr('recentUpdates'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const Spacer(),
                            if (updatesAvailable > 5)
                              Text(
                                tr(
                                  'plural_apps',
                                  args: [updatesAvailable.toString()],
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: updatesAvailable.clamp(0, 10),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) =>
                                _buildRecentUpdateIcon(
                                  context,
                                  updateApps[index],
                                  radius,
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedIcon(
    BuildContext context,
    AppInMemory app,
    double radius,
  ) {
    final itemRadius = (radius * 0.5).clamp(8.0, 20.0);
    return Tooltip(
      message: app.name,
      child: InkWell(
        onTap: () {
          AppHaptics.selectionClick();
          showDraggableModalBottomSheet(
            context: context,
            builder: (context, controller) => AppPage(
              appId: app.app.id,
              isModal: true,
              scrollController: controller,
            ),
          );
        },
        borderRadius: BorderRadius.circular(itemRadius),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: app.icon != null
                ? Image.memory(app.icon!, fit: BoxFit.contain)
                : const Icon(Icons.apps_rounded, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUpdateIcon(
    BuildContext context,
    AppInMemory app,
    double radius,
  ) {
    final itemRadius = (radius * 0.5).clamp(10.0, 24.0);
    return Tooltip(
      message: app.name,
      child: GestureDetector(
        onTap: () {
          AppHaptics.selectionClick();
          showDraggableModalBottomSheet(
            context: context,
            builder: (context, controller) => AppPage(
              appId: app.app.id,
              isModal: true,
              scrollController: controller,
            ),
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.error.withOpacity(AppOpacity.medium),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (app.icon != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(itemRadius - 2),
                  child: Image.memory(
                    app.icon!,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                  ),
                )
              else
                Center(
                  child: Icon(
                    Icons.apps_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(AppOpacity.half),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
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

  Widget _buildQuickActionsGrid(
    BuildContext context,
    double radius,
    ColorScheme colorScheme,
  ) {
    final itemRadius = (radius * 0.5).clamp(12.0, 20.0);
    final actions = [
      (
        icon: Icons.add_rounded,
        label: tr('addApp'),
        onTap: () {
          AppHaptics.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAppPage()),
          );
        }
      ),
      (
        icon: Icons.explore_rounded,
        label: tr('discover'),
        onTap: () {
          AppHaptics.selectionClick();
          final homeState = context.findAncestorStateOfType<HomePageState>();
          homeState?.switchToPage(2);
        }
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: tr('statistics'),
        onTap: () {
          AppHaptics.selectionClick();
          pushRoute(context, const StatisticsPage());
        }
      ),
      (
        icon: Icons.import_export_rounded,
        label: tr('importExport'),
        onTap: () {
          AppHaptics.selectionClick();
          pushRoute(context, const ImportExportPage());
        }
      ),
      (
        icon: Icons.bug_report_outlined,
        label: tr('logs'),
        onTap: () {
          AppHaptics.selectionClick();
          pushRoute(context, const LogsPage());
        }
      ),
      (
        icon: Icons.history_edu_rounded,
        label: tr('viewChangelog'),
        onTap: () {
          AppHaptics.selectionClick();
          pushRoute(context, const ChangelogPage());
        }
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(itemRadius),
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(itemRadius),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: colorScheme.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatchActionsHub(
    BuildContext context,
    AppsProvider appsProvider,
    double radius,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = appsProvider.selectedAppIds.length;
    final itemRadius = (radius * 0.7).clamp(12.0, 24.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(itemRadius),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.library_add_check_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                tr('plural_apps', args: [count.toString()]),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => appsProvider.clearSelection(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(tr('cancel')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    AppHaptics.heavyImpact();
                    appsProvider.downloadAndInstallLatestApps(
                      appsProvider.selectedAppIds.toList(),
                      context,
                    );
                    appsProvider.clearSelection();
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(tr('update')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    // Navigate to export page with selected IDs
                    // (Assuming ImportExportPage supports this or handled elsewhere)
                    AppHaptics.selectionClick();
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(tr('share')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {
                  AppHaptics.heavyImpact();
                  appsProvider.removeApps(appsProvider.selectedAppIds.toList());
                  appsProvider.clearSelection();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final settings = context.watch<SettingsProvider>();
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final itemRadius = (radius * 0.7).clamp(12.0, 24.0);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(itemRadius),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(itemRadius),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
