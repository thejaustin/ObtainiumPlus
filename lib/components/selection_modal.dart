import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/utils/source_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    Map<MapEntry<String, List<String>>, bool> filteredEntrySelections = {};
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
    getSelectAllButton() {
      if (widget.onlyOneSelectionAllowed) {
        return SizedBox.shrink();
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

    return AlertDialog(
      scrollable: true,
      title: Text(widget.title ?? tr('pick')),
      content: Column(
        children: [
          GeneratedForm(
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

            var singleSelectTile = ListTile(
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

            var multiSelectTile = Row(
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );

            return widget.onlyOneSelectionAllowed
                ? singleSelectTile
                : multiSelectTile;
          }),
        ],
      ),
      actions: [
        getSelectAllButton(),
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
    );
  }
}
