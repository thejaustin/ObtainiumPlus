import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

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

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
          else if (settings.plusShowDashboardSearch)
            // Omnibar - Unified Search/Add
            Omnibar(
              onSearchQuery: widget.onSearchQuery,
              onUrlInput: widget.onUrlInput,
            ),

          if (pinnedApps.isNotEmpty || !appsProvider.isSelectionMode)
            const SizedBox(height: 14),

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
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pinnedApps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _buildPinnedIcon(context, pinnedApps[index], radius),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

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
                    color: colorScheme.outline.withValues(
                      alpha: settings.plusEnableGlassmorphism ? 0.3 : 0.15,
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
                                plural('apps', updatesAvailable),
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
    final itemRadius = CardMetrics.inner(radius);
    return Tooltip(
      message: app.name,
      child: ScaleTouchWrapper(
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: app.icon != null
                ? Image.memory(
                    app.icon!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
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
    final itemRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: app.name,
      child: ScaleTouchWrapper(
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.secondary.withValues(alpha: 0.08),
                blurRadius: 6,
                spreadRadius: -1,
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
                      filterQuality: FilterQuality.high,
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.apps_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: AppOpacity.half),
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

  Widget _buildBatchActionsHub(
    BuildContext context,
    AppsProvider appsProvider,
    double radius,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = appsProvider.selectedAppIds.length;
    final itemRadius = CardMetrics.card(radius);

    return ClipRRect(
      borderRadius: BorderRadius.circular(itemRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.25),
                colorScheme.tertiaryContainer.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(itemRadius),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
            boxShadow: AppShadows.smooth(
              color: colorScheme.primary,
              opacity: 0.08,
              blurFactor: 0.6,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.library_add_check_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    plural('apps', count),
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
                        AppHaptics.selectionClick();
                        final urls = appsProvider.selectedAppIds
                            .map((id) => appsProvider.apps[id]?.app.url)
                            .whereType<String>()
                            .join('\n');
                        if (urls.isNotEmpty) {
                          Share.share(
                            urls,
                            subject: 'Obtainium - ${tr('appsString')}',
                          );
                        }
                        appsProvider.clearSelection();
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(tr('share')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      AppHaptics.heavyImpact();
                      appsProvider.removeApps(
                        appsProvider.selectedAppIds.toList(),
                      );
                      appsProvider.clearSelection();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      backgroundColor: colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
