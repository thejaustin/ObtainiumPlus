import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';

class CategoryEditorSelector extends StatefulWidget {
  final void Function(List<String> categories)? onSelected;
  final bool singleSelect;
  final Set<String> preselected;
  final WrapAlignment alignment;
  final bool showLabelWhenNotEmpty;
  const CategoryEditorSelector({
    super.key,
    this.onSelected,
    this.singleSelect = false,
    this.preselected = const {},
    this.alignment = WrapAlignment.start,
    this.showLabelWhenNotEmpty = true,
  });

  @override
  State<CategoryEditorSelector> createState() => _CategoryEditorSelectorState();
}

class _CategoryEditorSelectorState extends State<CategoryEditorSelector> {
  Map<String, MapEntry<int, bool>> storedValues = {};

  @override
  Widget build(BuildContext context) {
    var viewSettings = context.watch<ViewSettingsProvider>();
    var appsProvider = context.watch<AppsProvider>();
    storedValues = viewSettings.categories.map(
      (key, value) => MapEntry(
        key,
        MapEntry(
          value,
          storedValues[key]?.value ?? widget.preselected.contains(key),
        ),
      ),
    );
    return GeneratedForm(
      items: [
        [
          GeneratedFormTagInput(
            'categories',
            label: tr('categories'),
            emptyMessage: tr('noCategories'),
            defaultValue: storedValues,
            alignment: widget.alignment,
            deleteConfirmationMessage: MapEntry(
              tr('deleteCategoriesQuestion'),
              tr('categoryDeleteWarning'),
            ),
            singleSelect: widget.singleSelect,
            showLabelWhenNotEmpty: widget.showLabelWhenNotEmpty,
          ),
        ],
      ],
      onValueChanges: ((values, valid, isBuilding) {
        if (!isBuilding) {
          storedValues =
              values['categories'] as Map<String, MapEntry<int, bool>>;
          viewSettings.setCategories(
            storedValues.map((key, value) => MapEntry(key, value.key)),
            appsProvider: appsProvider,
          );
          if (widget.onSelected != null) {
            widget.onSelected!(
              storedValues.keys.where((k) => storedValues[k]!.value).toList(),
            );
          }
        }
      }),
    );
  }
}
