import 'package:flutter/material.dart';
import 'package:obtainium/providers/tag_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final tags = tagProvider.allTags.toList()..sort();

    if (tags.isEmpty) return const SizedBox.shrink();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tags.length + 1,
          itemBuilder: (context, index) {
            final tag = index == 0 ? null : tags[index - 1];
            final isSelected = activeTag == tag;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(tag ?? tr('all')),
                selected: isSelected,
                onSelected: (_) => onTagSelected(tag),
              ),
            );
          },
        ),
      ),
    );
  }
}
