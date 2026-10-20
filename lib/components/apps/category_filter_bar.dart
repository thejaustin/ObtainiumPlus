import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Smart Launcher 6-inspired horizontal category pill bar.
///
/// Renders interactive squircle/stadium category pills with smart semantic icons,
/// category accent dots, and live app counts so users can switch categories in
/// a single tap without opening the filter modal.
class CategoryFilterBar extends StatelessWidget {
  final Set<String> selectedCategories;
  final void Function(Set<String> newCategories) onCategoriesChanged;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  static IconData iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('game')) return Icons.sports_esports_rounded;
    if (lower.contains('media') ||
        lower.contains('video') ||
        lower.contains('music') ||
        lower.contains('audio')) {
      return Icons.play_circle_outline_rounded;
    }
    if (lower.contains('social') ||
        lower.contains('chat') ||
        lower.contains('messag')) {
      return Icons.forum_outlined;
    }
    if (lower.contains('tool') ||
        lower.contains('util') ||
        lower.contains('system')) {
      return Icons.build_circle_outlined;
    }
    if (lower.contains('sec') ||
        lower.contains('priv') ||
        lower.contains('vpn') ||
        lower.contains('auth')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('web') ||
        lower.contains('browser') ||
        lower.contains('net')) {
      return Icons.public_rounded;
    }
    if (lower.contains('dev') ||
        lower.contains('code') ||
        lower.contains('git')) {
      return Icons.terminal_rounded;
    }
    if (lower.contains('prod') ||
        lower.contains('work') ||
        lower.contains('note') ||
        lower.contains('doc')) {
      return Icons.work_outline_rounded;
    }
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final viewSettings = context.watch<ViewSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final appsProvider = context.watch<AppsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (viewSettings.categories.isEmpty || viewSettings.groupByCategory) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final allApps = appsProvider.apps.values.toList();
    final counts = <String, int>{};
    for (final cat in viewSettings.categories.keys) {
      counts[cat] = 0;
    }
    for (final appMem in allApps) {
      for (final cat in appMem.app.categories) {
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }

    final categories =
        viewSettings.categories.keys
            .where(
              (c) => (counts[c] ?? 0) > 0 || selectedCategories.contains(c),
            )
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final pillRadius = (baseRadius * 0.85).clamp(14.0, 24.0);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];
              final isSelected = isAll
                  ? selectedCategories.isEmpty
                  : selectedCategories.contains(category);
              final catColorVal = category != null
                  ? viewSettings.categories[category]
                  : null;
              final accentColor = catColorVal != null
                  ? Color(catColorVal)
                  : colorScheme.primary;
              final count = isAll ? allApps.length : (counts[category!] ?? 0);

              final shape = CardMetrics.shape(
                isSelected ? pillRadius : CardMetrics.pillRadius,
                expressive: isM3E,
                side: BorderSide(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.65)
                      : colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: isSelected ? 1.3 : 0.8,
                ),
              );

              return ScaleTouchWrapper(
                scaleDownFactor: 0.94,
                hapticOnPressDown: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: ShapeDecoration(
                    color: isSelected
                        ? accentColor.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.24
                                : 0.16,
                          )
                        : colorScheme.surfaceContainerLow,
                    shape: shape,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: shape,
                      onTap: () {
                        AppHaptics.selectionClick();
                        if (isAll) {
                          onCategoriesChanged({});
                        } else {
                          final next = Set<String>.from(selectedCategories);
                          if (next.contains(category)) {
                            next.remove(category);
                          } else {
                            next
                              ..clear()
                              ..add(category!);
                          }
                          onCategoriesChanged(next);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAll)
                              Icon(
                                Icons.apps_rounded,
                                size: 15,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              )
                            else ...[
                              Icon(
                                iconForCategory(category!),
                                size: 15,
                                color: isSelected
                                    ? accentColor
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Text(
                              isAll ? tr('all') : category!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withValues(alpha: 0.22)
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(
                                  CardMetrics.pillRadius,
                                ),
                              ),
                              child: Text(
                                '$count',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
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
            },
          ),
        ),
      ),
    );
  }
}
