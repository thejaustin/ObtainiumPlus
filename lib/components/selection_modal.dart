import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
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

    _updateFilteredEntries();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withOpacity(0.18)
                : colorScheme.outline.withOpacity(AppOpacity.subtle),
            width: 1,
          ),
          boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.28 : 0.1,
            blurFactor: enableGlass ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ConditionalBlur(sigma: 24, enabled: enableGlass, child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, enableGlass),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(context),
                  ),
                ),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(enableGlass ? 0.3 : 0.5),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(enableGlass ? 0.15 : 0.25),
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
              color: Theme.of(context).colorScheme.secondary.withOpacity(AppOpacity.low),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.list_alt_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.title ?? tr('pick'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // Filter field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(AppOpacity.half),
            borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 16),
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
                  ),
                );

          var selectedEntries = entrySelections.entries
              .where((e) => e.value)
              .toList();

          Widget tile;
          if (widget.onlyOneSelectionAllowed) {
            tile = ListTile(
              title: GestureDetector(
                onTap: widget.titlesAreLinks
                    ? null
                    : () {
                        selectThis(!(entrySelections[entry] ?? false));
                      },
                child: urlLink,
              ),
              subtitle: entry.value.length <= 1
                  ? null
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          selectOnlyOne(entry.key);
                        });
                      },
                      child: descriptionText,
                    ),
              leading: Radio<String>(
                value: entry.key,
                groupValue: selectedEntries.isEmpty
                    ? null
                    : selectedEntries.first.key.key,
                onChanged: (value) {
                  setState(() {
                    selectOnlyOne(entry.key);
                  });
                },
              ),
            );
          } else {
            tile = Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(AppOpacity.medium),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: entrySelections[entry],
                    onChanged: (value) {
                      selectThis(value);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: widget.titlesAreLinks
                              ? null
                              : () {
                                  selectThis(!(entrySelections[entry] ?? false));
                                },
                          child: urlLink,
                        ),
                        entry.value.length <= 1
                            ? const SizedBox.shrink()
                            : GestureDetector(
                                onTap: () {
                                  selectThis(!(entrySelections[entry] ?? false));
                                },
                                child: descriptionText,
                              ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return tile;
        }),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(AppOpacity.medium),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
          TextButton(
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
