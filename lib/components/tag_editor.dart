import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:provider/provider.dart';

/// Tag editor dialog for adding/removing tags from apps
Future<List<String>?> showTagEditor({
  required BuildContext context,
  required List<String> currentTags,
  required List<String> allTags,
}) async {
  final plusSettings = context.read<PlusSettingsProvider>();
  final enableGlass = plusSettings.plusEnableGlassmorphism;

  final selectedTags = Set<String>.from(currentTags);
  final TextEditingController _controller = TextEditingController();

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setSheetState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(enableGlass ? 0.85 : 1.0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withOpacity(AppOpacity.subtle),
                width: 1,
              ),
              boxShadow: AppShadows.smooth(
                color: Colors.black,
                opacity: enableGlass ? 0.2 : 0.1,
                blurFactor: enableGlass ? 1.5 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ConditionalBlur(
                sigma: 15,
                enabled: enableGlass,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, enableGlass),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add new tag
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: tr('newTag'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      prefixIcon: const Icon(
                                        Icons.tag_outlined,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        setSheetState(() {
                                          selectedTags.add(value.trim());
                                          _controller.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    if (_controller.text.trim().isNotEmpty) {
                                      setSheetState(() {
                                        selectedTags.add(
                                          _controller.text.trim(),
                                        );
                                        _controller.clear();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Existing tags
                            if (allTags.isNotEmpty) ...[
                              Text(
                                tr('existingTags'),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allTags.map((tag) {
                                  final isSelected = selectedTags.contains(tag);
                                  return FilterChip(
                                    label: Text(tag),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setSheetState(() {
                                        if (selected) {
                                          selectedTags.add(tag);
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Selected tags
                            if (selectedTags.isNotEmpty) ...[
                              Text(
                                tr('selectedTags'),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedTags.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    onDeleted: () {
                                      setSheetState(() {
                                        selectedTags.remove(tag);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildActions(context, selectedTags.toList()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildHeader(BuildContext context, bool enableGlass) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(
            context,
          ).colorScheme.secondaryContainer.withOpacity(enableGlass ? 0.3 : 0.5),
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(
            enableGlass ? 0.15 : 0.25,
          ),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withOpacity(AppOpacity.low),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.tag_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            tr('editTags'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _buildActions(BuildContext context, List<String> selectedTags) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(AppOpacity.medium),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('cancel')),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedTags),
          child: Text(tr('save')),
        ),
      ],
    ),
  );
}

/// Get all unique tags from a list of apps
List<String> getAllTagsFromApps(List<MapEntry<String, AppInMemory>> apps) {
  final tags = <String>{};
  for (final app in apps) {
    final appTags = app.value.app.tags;
    if (appTags != null) {
      tags.addAll(appTags);
    }
  }
  return tags.toList()..sort();
}
