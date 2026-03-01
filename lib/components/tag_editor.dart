import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Tag editor dialog for adding/removing tags from apps
Future<List<String>?> showTagEditor({
  required BuildContext context,
  required List<String> currentTags,
  required List<String> allTags,
}) async {
  final settings = context.read<SettingsProvider>();
  final enableGlass = settings.plusEnableGlassmorphism;
  
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setSheetState) {
        final selectedTags = Set<String>.from(currentTags);
        final TextEditingController _controller = TextEditingController();
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: enableGlass ? 0.85 : 1.0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: enableGlass ? 0.2 : 0.1),
                  blurRadius: enableGlass ? 20 : 10,
                  spreadRadius: enableGlass ? 0 : -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: enableGlass ? 15 : 0,
                  sigmaY: enableGlass ? 15 : 0,
                ),
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      prefixIcon: const Icon(Icons.tag_outlined),
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
                                        selectedTags.add(_controller.text.trim());
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
                                    deleteIcon: const Icon(Icons.close, size: 18),
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
          Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: enableGlass ? 0.3 : 0.5),
          Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: enableGlass ? 0.15 : 0.25),
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
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
List<String> getAllTagsFromApps(List<MapEntry<String, dynamic>> apps) {
  final tags = <String>{};
  for (final app in apps) {
    final appTags = app.value.tags;
    if (appTags != null) {
      tags.addAll(appTags);
    }
  }
  return tags.toList()..sort();
}
