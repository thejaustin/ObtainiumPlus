import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/apps/m3e_segmented_filter.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

class AppDashboard extends StatefulWidget {
  final String currentFilterMode;
  final Function(String) onFilterChanged;
  final Function(String) onSearchQuery;
  final Function(String) onUrlInput;
  final Function(String)? onDiscoverSearch;
  final VoidCallback onCheckUpdates;

  const AppDashboard({
    super.key,
    required this.currentFilterMode,
    required this.onFilterChanged,
    required this.onSearchQuery,
    required this.onUrlInput,
    this.onDiscoverSearch,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animsEnabled = context
          .read<PlusSettingsProvider>()
          .plusEnableEnhancedAnimations;
      if (animsEnabled) {
        _entranceController.forward();
      } else {
        _entranceController.value = 1.0;
      }
    });
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

  // Memoization fields to avoid recomputing updates, pinned apps, and deep-copying on filter toggles
  int? _lastAppsRevision;
  int? _lastAppsCount;
  List<AppInMemory>? _cachedApps;
  List<AppInMemory>? _cachedUpdateApps;
  List<AppInMemory>? _cachedPinnedApps;
  int _cachedInstalledCount = 0;

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final appsRevision = appsProvider.appsRevision;
    final appsCount = appsProvider.apps.length;

    if (_cachedApps == null ||
        _lastAppsRevision != appsRevision ||
        _lastAppsCount != appsCount) {
      _lastAppsRevision = appsRevision;
      _lastAppsCount = appsCount;
      _cachedApps = appsProvider.getAppValues(deepCopy: false).toList();
      final pendingUpdates = appsProvider.findAllPendingUpdates().updates;
      _cachedUpdateApps = _cachedApps!
          .where((app) => pendingUpdates.contains(app.app.id))
          .toList();
      _cachedPinnedApps = _cachedApps!.where((app) => app.app.pinned).toList();
      _cachedInstalledCount = _cachedApps!
          .where((app) => app.app.installedVersion != null)
          .length;
    }

    final apps = _cachedApps!;
    final totalApps = apps.length;
    // In-flight apps are shown by the operations banner and their tiles, so
    // the quick-access strip only lists apps that are still waiting.
    final updateApps = _cachedUpdateApps!
        .where((a) => a.downloadProgress == null)
        .toList();
    final updatesAvailable = _cachedUpdateApps!.length;
    final idleUpdates = updateApps.length;
    final showRecent =
        idleUpdates > 0 &&
        !appsProvider.gettingUpdates &&
        (totalApps >= 5 || updatesAvailable > 1);
    final pinnedApps = _cachedPinnedApps!;
    final installedCount = _cachedInstalledCount;

    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

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
          else if (plusSettings.plusShowDashboardSearch)
            // Omnibar - Unified Search/Add
            Omnibar(
              onSearchQuery: widget.onSearchQuery,
              onUrlInput: widget.onUrlInput,
              onDiscoverSearch: widget.onDiscoverSearch,
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
                  Row(
                    children: [
                      Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('pinnedApps'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: ShapeDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: CardMetrics.shape(
                            CardMetrics.pill(radius),
                            expressive:
                                plusSettings.plusEnableMaterialExpressive,
                          ),
                        ),
                        child: Text(
                          '${pinnedApps.length}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: plusSettings.scrollPhysics,
                      itemCount: pinnedApps.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _buildPinnedIcon(
                        context,
                        pinnedApps[index],
                        radius,
                        isM3E: plusSettings.plusEnableMaterialExpressive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

          // Filter mode M3 Expressive segmented filter — slides in after cards
          _animated(
            _segmentedAnim,
            M3ExpressiveSegmentedFilter(
              currentMode: widget.currentFilterMode,
              onModeChanged: widget.onFilterChanged,
              totalApps: totalApps,
              updatesCount: updatesAvailable,
              installedCount: installedCount,
              radius: radius,
              isGlass: plusSettings.plusEnableGlassmorphism,
            ),
          ),

          // Recent updates — Adaptive Hide + AnimatedSize
          AnimatedSize(
            duration: Duration(
              milliseconds: plusSettings.plusEnableEnhancedAnimations ? 320 : 0,
            ),
            curve: Easing.emphasizedDecelerate,
            child: showRecent
                ? _animated(
                    _updatesAnim,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                onTap: () => widget.onFilterChanged('updates'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.system_update_alt_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        tr('recentUpdates'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.5,
                                        vertical: 1.5,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: colorScheme.primaryContainer,
                                        shape: CardMetrics.shape(
                                          CardMetrics.pill(radius),
                                          expressive: plusSettings
                                              .plusEnableMaterialExpressive,
                                        ),
                                      ),
                                      child: Text(
                                        '$idleUpdates',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ScaleTouchWrapper(
                              hapticOnPressDown: true,
                              scaleDownFactor: 0.94,
                              onTap: () {
                                AppHaptics.mediumImpact();
                                appsProvider.downloadAndInstallLatestApps(
                                  updateApps.map((a) => a.app.id).toList(),
                                  context,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: ShapeDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: CardMetrics.shape(
                                    CardMetrics.pill(radius),
                                    expressive: plusSettings
                                        .plusEnableMaterialExpressive,
                                    side: BorderSide(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.download_rounded,
                                      size: 14,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      tr('update'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: plusSettings.scrollPhysics,
                            itemCount: idleUpdates.clamp(0, 10),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) =>
                                _buildRecentUpdateIcon(
                                  context,
                                  updateApps[index],
                                  radius,
                                  isM3E:
                                      plusSettings.plusEnableMaterialExpressive,
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

  void _openApp(BuildContext context, AppInMemory app) {
    final provider = context.read<AppsProvider>();
    AppHaptics.selectionClick();
    if (provider.selectedAppIds.isNotEmpty) {
      provider.toggleAppSelection(app.app.id);
      return;
    }
    showDraggableModalBottomSheet(
      context: context,
      builder: (context, controller) => AppPage(
        appId: app.app.id,
        isModal: true,
        scrollController: controller,
      ),
    );
  }

  void _toggleSelect(BuildContext context, AppInMemory app) {
    context.read<AppsProvider>().toggleAppSelection(app.app.id);
  }

  Widget _buildPinnedIcon(
    BuildContext context,
    AppInMemory app,
    double radius, {
    required bool isM3E,
  }) {
    final itemRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;
    final hasUpdate =
        app.app.installedVersion != null &&
        app.app.installedVersion != app.app.latestVersion;

    return Tooltip(
      message: app.name,
      child: ScaleTouchWrapper(
        onTap: () => _openApp(context, app),
        onLongPress: () => _toggleSelect(context, app),
        hapticOnPressDown: true,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: ShapeDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  shape: CardMetrics.shape(
                    itemRadius,
                    expressive: isM3E,
                    side: BorderSide(
                      color: hasUpdate
                          ? colorScheme.primary.withValues(alpha: 0.45)
                          : colorScheme.outlineVariant.withValues(alpha: 0.35),
                      width: hasUpdate ? 1.3 : 1.0,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Builder(
                          builder: (ctx) {
                            if (app.icon == null && app.installedInfo != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (ctx.mounted && app.icon == null) {
                                  ctx.read<AppsProvider>().updateAppIcon(
                                    app.app.id,
                                  );
                                }
                              });
                            }
                            return app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    cacheWidth:
                                        (44 *
                                                MediaQuery.devicePixelRatioOf(
                                                  context,
                                                ))
                                            .round(),
                                    cacheHeight:
                                        (44 *
                                                MediaQuery.devicePixelRatioOf(
                                                  context,
                                                ))
                                            .round(),
                                  )
                                : Icon(
                                    Icons.apps_rounded,
                                    size: 24,
                                    color: colorScheme.primary,
                                  );
                          },
                        ),
                      ),
                    ),
                    if (hasUpdate)
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUpdateIcon(
    BuildContext context,
    AppInMemory app,
    double radius, {
    required bool isM3E,
  }) {
    final itemRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '${app.name} (${app.app.latestVersion})',
      child: ScaleTouchWrapper(
        onTap: () => _openApp(context, app),
        onLongPress: () => _toggleSelect(context, app),
        hapticOnPressDown: true,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: colorScheme.surfaceContainerLow,
                  shape: CardMetrics.shape(
                    itemRadius,
                    expressive: isM3E,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.50),
                      width: 1.5,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Builder(
                  builder: (ctx) {
                    if (app.icon == null && app.installedInfo != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (ctx.mounted && app.icon == null) {
                          ctx.read<AppsProvider>().updateAppIcon(app.app.id);
                        }
                      });
                    }
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Center(
                            child: app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    cacheWidth:
                                        (48 *
                                                MediaQuery.devicePixelRatioOf(
                                                  context,
                                                ))
                                            .round(),
                                    cacheHeight:
                                        (48 *
                                                MediaQuery.devicePixelRatioOf(
                                                  context,
                                                ))
                                            .round(),
                                  )
                                : Icon(
                                    Icons.apps_rounded,
                                    color: colorScheme.primary.withValues(
                                      alpha: AppOpacity.half,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 3,
                          top: 3,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 9,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.15,
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
    final isM3E = context
        .watch<PlusSettingsProvider>()
        .plusEnableMaterialExpressive;
    final count = appsProvider.selectedAppIds.length;
    final itemRadius = CardMetrics.card(radius);

    return ClipRRect(
      borderRadius: BorderRadius.circular(itemRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.40),
                colorScheme.tertiaryContainer.withValues(alpha: 0.20),
              ],
            ),
            shape: CardMetrics.shape(
              itemRadius,
              expressive: isM3E,
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            shadows: AppShadows.smooth(
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
                          SharePlus.instance.share(
                            ShareParams(
                              text: urls,
                              subject: 'Obtainium - ${tr('appsString')}',
                            ),
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
