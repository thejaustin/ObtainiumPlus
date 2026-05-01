import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
        curve: const Interval(0.0, 0.55, curve: curve));
    _card1Anim = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.63, curve: curve));
    _card2Anim = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.16, 0.71, curve: curve));
    _segmentedAnim = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.83, curve: curve));
    _updatesAnim = CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.38, 1.0, curve: curve));

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
        .where((app) =>
            app.app.installedVersion != null &&
            app.app.installedVersion != app.app.latestVersion)
        .toList();
    final updatesAvailable = updateApps.length;

    DateTime? lastCheck;
    for (var app in apps) {
      if (app.app.lastUpdateCheck != null) {
        if (lastCheck == null ||
            app.app.lastUpdateCheck!.isAfter(lastCheck)) {
          lastCheck = app.app.lastUpdateCheck;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Omnibar - Unified Search/Add
          if (settings.plusShowDashboardSearch) ...[
            Omnibar(
              onSearchQuery: widget.onSearchQuery,
              onUrlInput: widget.onUrlInput,
            ),
            const SizedBox(height: 20),
          ],

          // Summary cards — staggered M3 entrance
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
                    onTap: updatesAvailable > 0 ? widget.onCheckUpdates : null,
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
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(settings.plusEnableGlassmorphism ? 0.3 : 0.15),
                  ),
                ),
              ),
            ),
          ),

          // Recent updates — AnimatedSize so it expands/collapses smoothly
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Easing.emphasizedDecelerate,
            child: updatesAvailable > 0
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const Spacer(),
                            if (updatesAvailable > 5)
                              Text(
                                tr('plural_apps',
                                    args: [updatesAvailable.toString()]),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
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
                                    context, updateApps[index]),
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

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;

    final cardContent = Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: color.withOpacity(settings.plusEnableGlassmorphism ? 0.3 : 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
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
    );

    // Conditional BackdropFilter — only instantiate when glass is ON
    // (zero-blur BackdropFilter still creates an expensive compositing layer)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: settings.plusEnableGlassmorphism
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }

  Widget _buildRecentUpdateIcon(BuildContext context, AppInMemory app) {
    return Tooltip(
      message: app.name,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .error
                .withOpacity(AppOpacity.medium),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            if (app.icon != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(app.icon!,
                    fit: BoxFit.cover, width: 64, height: 64),
              )
            else
              Center(
                child: Icon(
                  Icons.apps_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(AppOpacity.half),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
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
    );
  }
}
