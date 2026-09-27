import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/tag_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/haptic_utils.dart';

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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final tags = tagProvider.allTags.toList()..sort();

    if (tags.isEmpty) return const SliverToBoxAdapter();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tags.length + 1,
          itemBuilder: (context, index) {
            final tag = index == 0 ? null : tags[index - 1];
            final isSelected = activeTag == tag;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: ScaleTouchWrapper(
                scaleDownFactor: 0.94,
                onTap: () {
                  AppHaptics.selectionClick();
                  onTagSelected(tag);
                },
                child: FilterChip(
                  label: Text(tag ?? tr('all')),
                  selected: isSelected,
                  onSelected: (_) {
                    AppHaptics.selectionClick();
                    onTagSelected(tag);
                  },
                  shape: const StadiumBorder(),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.secondary.withValues(alpha: 0.6)
                        : colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                  elevation: isSelected ? 1.0 : 0.0,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
