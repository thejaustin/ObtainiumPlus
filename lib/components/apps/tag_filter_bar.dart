import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/tag_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Material 3 Expressive horizontal tag pill bar.
///
/// Features interactive squircle pills with tag icons, live app counts,
/// and smooth scale transitions matching [CategoryFilterBar].
class TagFilterBar extends StatelessWidget {
  final String? activeTag;
  final Function(String?) onTagSelected;

  const TagFilterBar({
    super.key,
    required this.activeTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();

    context.select<AppsProvider, (int, int)>(
      (p) => (p.appsRevision, p.apps.length),
    );
    final appsProvider = context.read<AppsProvider>();
    final tags = tagProvider.allTags.toList()..sort();

    if (tags.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final allApps = appsProvider.apps.values.toList();
    final counts = <String, int>{for (final tag in tags) tag: 0};
    for (final appMem in allApps) {
      for (final tag in appMem.app.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }

    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final pillRadius = (baseRadius * 0.85).clamp(14.0, 24.0);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: tags.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final tag = isAll ? null : tags[index - 1];
              final isSelected = activeTag == tag;
              final count = isAll ? allApps.length : (counts[tag!] ?? 0);

              final shape = CardMetrics.shape(
                isSelected ? pillRadius : CardMetrics.pillRadius,
                expressive: isM3E,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.65)
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
                        ? colorScheme.primary.withValues(
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
                        onTagSelected(isSelected && !isAll ? null : tag);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAll
                                  ? Icons.label_outline_rounded
                                  : Icons.tag_rounded,
                              size: 15,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag ?? tr('all'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.65),
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
                                      color: colorScheme.onSurfaceVariant,
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
