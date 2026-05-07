import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

// ignore: must_be_immutable
class SelectionModal extends StatefulWidget {
  SelectionModal({
    super.key,
    required this.entries,
    this.selectedByDefault = true,
    this.onlyOneSelectionAllowed = false,
    this.titlesAreLinks = true,
    this.title,
    this.deselectThese = const [],
  });

  String? title;
  Map<String, List<String>> entries;
  bool selectedByDefault;
  List<String> deselectThese;
  bool onlyOneSelectionAllowed;
  bool titlesAreLinks;

  @override
  State<SelectionModal> createState() => _SelectionModalState();
}

class _SelectionModalState extends State<SelectionModal> {
  Map<MapEntry<String, List<String>>, bool> entrySelections = {};
  String filterRegex = '';
  Map<MapEntry<String, List<String>>, bool> filteredEntrySelections = {};

  @override
  void initState() {
    super.initState();
    for (var entry in widget.entries.entries) {
      entrySelections.putIfAbsent(
        entry,
        () =>
            widget.selectedByDefault &&
            !widget.onlyOneSelectionAllowed &&
            !widget.deselectThese.contains(entry.key),
      );
    }
    if (widget.selectedByDefault && widget.onlyOneSelectionAllowed) {
      selectOnlyOne(widget.entries.entries.first.key);
    }
  }

  void selectOnlyOne(String url) {
    for (var e in entrySelections.keys) {
      entrySelections[e] = e.key == url;
    }
  }

  void selectAll({bool deselect = false}) {
    for (var e in entrySelections.keys) {
      entrySelections[e] = !deselect;
    }
  }

  void _updateFilteredEntries() {
    filteredEntrySelections.clear();
    entrySelections.forEach((key, value) {
      var searchableText = key.value.isEmpty ? key.key : key.value[0];
      if (filterRegex.isEmpty || RegExp(filterRegex).hasMatch(searchableText)) {
        filteredEntrySelections.putIfAbsent(key, () => value);
      }
    });
    if (filterRegex.isNotEmpty && filteredEntrySelections.isEmpty) {
      entrySelections.forEach((key, value) {
        var searchableText = key.value.isEmpty ? key.key : key.value[0];
        if (filterRegex.isEmpty ||
            RegExp(
              filterRegex,
              caseSensitive: false,
            ).hasMatch(searchableText)) {
          filteredEntrySelections.putIfAbsent(key, () => value);
        }
      });
    }
  }

  Widget _getSelectAllButton() {
    if (widget.onlyOneSelectionAllowed) {
      return const SizedBox.shrink();
    }
    var noneSelected = entrySelections.values.where((v) => v == true).isEmpty;
    return noneSelected
        ? TextButton(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onPressed: () {
              setState(() {
                selectAll();
              });
            },
            child: Text(tr('selectAll')),
          )
        : TextButton(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onPressed: () {
              setState(() {
                selectAll(deselect: true);
              });
            },
            child: Text(tr('deselectX', args: [''])),
          );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final dialogRadius = radius.clamp(24.0, 48.0);

    _updateFilteredEntries();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(dialogRadius),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withOpacity(0.18)
                : colorScheme.outline.withOpacity(AppOpacity.subtle),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(enableGlass ? 0.2 : 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dialogRadius),
          child: ConditionalBlur(
            sigma: 20,
            enabled: enableGlass,
            child: Stack(
              children: [
                // Glass sheen
                if (enableGlass)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                            Colors.black.withOpacity(0.02),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, enableGlass, dialogRadius),
                    const Divider(height: 1, thickness: 0.5),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: _buildContent(context, radius, colorScheme),
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildActions(context, dialogRadius, colorScheme),
                    ],
                    ),
                    ],
                    ),
                    ),
                    ),
                    ),
                    );
                    }

                    Widget _buildContent(BuildContext context, double radius, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(enableGlass ? 0.3 : 0.5),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(enableGlass ? 0.15 : 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(AppOpacity.low),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.list_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.title ?? tr('pick'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double radius) {
    final itemRadius = (radius * 0.5).clamp(8.0, 20.0);
    return Column(
      children: [
        // Filter field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(itemRadius),
          ),
          child: GeneratedForm(
            items: [
              [
                GeneratedFormTextField(
                  'filter',
                  label: tr('filter'),
                  required: false,
                  additionalValidators: [
                    (value) {
                      return SourceUtils.regExValidator(value);
                    },
                  ],
                ),
              ],
            ],
            onValueChanges: (value, valid, isBuilding) {
              if (valid && !isBuilding) {
                if (value['filter'] != null) {
                  setState(() {
                    filterRegex = value['filter'];
                  });
                }
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        // Entry list
        ...filteredEntrySelections.keys.map((entry) {
          selectThis(bool? value) {
            setState(() {
              value ??= false;
              if (value! && widget.onlyOneSelectionAllowed) {
                selectOnlyOne(entry.key);
              } else {
                entrySelections[entry] = value!;
              }
            });
          }

          var urlLink = GestureDetector(
            onTap: !widget.titlesAreLinks
                ? null
                : () {
                    launchUrlString(
                      entry.key,
                      mode: LaunchMode.externalApplication,
                    );
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.value.isEmpty ? entry.key : entry.value[0],
                  style: TextStyle(
                    decoration: widget.titlesAreLinks
                        ? TextDecoration.underline
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
                if (widget.titlesAreLinks)
                  Text(
                    Uri.parse(entry.key).host,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      opacity: 0.8,
                    ),
                  ),
              ],
            ),
          );

          var descriptionText = entry.value.length <= 1
              ? const SizedBox.shrink()
              : Text(
                  entry.value[1].length > 128
                      ? '${entry.value[1].substring(0, 128)}...'
                      : entry.value[1],
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    opacity: 0.7,
                  ),
                );

          var selectedEntries = entrySelections.entries
              .where((e) => e.value)
              .toList();

          Widget tile;
          if (widget.onlyOneSelectionAllowed) {
            tile = Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: entrySelections[entry] == true
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.2),
                borderRadius: BorderRadius.circular(itemRadius),
                border: Border.all(
                  color: entrySelections[entry] == true
                      ? colorScheme.primary.withOpacity(0.4)
                      : colorScheme.outline.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: RadioListTile<String>(
                value: entry.key,
                groupValue: selectedEntries.isEmpty ? null : selectedEntries.first.key.key,
                onChanged: (value) {
                  AppHaptics.selectionClick();
                  setState(() {
                    selectOnlyOne(entry.key);
                  });
                },
                title: urlLink,
                subtitle: entry.value.length <= 1 ? null : descriptionText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
                activeColor: colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          } else {
            tile = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: entrySelections[entry] == true
                    ? colorScheme.primaryContainer.withOpacity(0.4)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.2),
                borderRadius: BorderRadius.circular(itemRadius),
                border: Border.all(
                  color: entrySelections[entry] == true
                      ? colorScheme.primary.withOpacity(0.5)
                      : colorScheme.outline.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: entrySelections[entry] == true
                    ? [BoxShadow(color: colorScheme.primary.withOpacity(0.1), blurRadius: 8, spreadRadius: -2)]
                    : null,
              ),
              child: CheckboxListTile(
                value: entrySelections[entry],
                onChanged: (value) {
                  AppHaptics.selectionClick();
                  selectThis(value);
                },
                title: urlLink,
                subtitle: entry.value.length <= 1 ? null : descriptionText,
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
                activeColor: colorScheme.primary,
                checkColor: colorScheme.onPrimary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            );
          }

          return tile;
        }),
      ],
    );
  }

  Widget _buildActions(BuildContext context, double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _getSelectAllButton(),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tr('cancel')),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: entrySelections.values.where((b) => b).isEmpty
                ? null
                : () {
                    Navigator.of(context).pop(
                      entrySelections.entries
                          .where((entry) => entry.value)
                          .map((e) => e.key.key)
                          .toList(),
                    );
                  },
            child: Text(
              widget.onlyOneSelectionAllowed
                  ? tr('pick')
                  : tr(
                      'selectX',
                      args: [
                        entrySelections.values.where((b) => b).length.toString(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
