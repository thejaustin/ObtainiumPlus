import 'dart:math';

<<<<<<< HEAD
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hsluv/hsluv.dart';

import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/app_constants.dart';
=======
import 'package:hsluv/hsluv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
>>>>>>> upstream/main

abstract class GeneratedFormItem {
  late String key;
  late String label;
<<<<<<< HEAD
  late String? tooltip;
=======
>>>>>>> upstream/main
  late List<Widget> belowWidgets;
  late dynamic defaultValue;
  List<dynamic> additionalValidators;
  dynamic ensureType(dynamic val);
  GeneratedFormItem clone();

  GeneratedFormItem(
    this.key, {
    this.label = 'Input',
<<<<<<< HEAD
    this.tooltip,
=======
>>>>>>> upstream/main
    this.belowWidgets = const [],
    this.defaultValue,
    this.additionalValidators = const [],
  });
}

class GeneratedFormTextField extends GeneratedFormItem {
  late bool required;
  late int max;
  late String? hint;
  late bool password;
  late TextInputType? textInputType;
  late List<String>? autoCompleteOptions;

  GeneratedFormTextField(
    super.key, {
    super.label,
<<<<<<< HEAD
    super.tooltip,
=======
>>>>>>> upstream/main
    super.belowWidgets,
    String super.defaultValue = '',
    List<String? Function(String? value)> super.additionalValidators = const [],
    this.required = true,
    this.max = 1,
    this.hint,
    this.password = false,
    this.textInputType,
    this.autoCompleteOptions,
  });

  @override
  String ensureType(val) {
    return val.toString();
  }

  @override
  GeneratedFormTextField clone() {
    return GeneratedFormTextField(
      key,
      label: label,
<<<<<<< HEAD
      tooltip: tooltip,
=======
>>>>>>> upstream/main
      belowWidgets: belowWidgets,
      defaultValue: defaultValue,
      additionalValidators: List.from(additionalValidators),
      required: required,
      max: max,
      hint: hint,
      password: password,
      textInputType: textInputType,
    );
  }
}

class GeneratedFormDropdown extends GeneratedFormItem {
  late List<MapEntry<String, String>>? opts;
  List<String>? disabledOptKeys;

  GeneratedFormDropdown(
    super.key,
    this.opts, {
    super.label,
<<<<<<< HEAD
    super.tooltip,
=======
>>>>>>> upstream/main
    super.belowWidgets,
    String super.defaultValue = '',
    this.disabledOptKeys,
    List<String? Function(String? value)> super.additionalValidators = const [],
  });

  @override
  String ensureType(val) {
    return val.toString();
  }

  @override
  GeneratedFormDropdown clone() {
    return GeneratedFormDropdown(
      key,
      opts?.map((e) => MapEntry(e.key, e.value)).toList(),
      label: label,
<<<<<<< HEAD
      tooltip: tooltip,
=======
>>>>>>> upstream/main
      belowWidgets: belowWidgets,
      defaultValue: defaultValue,
      disabledOptKeys: disabledOptKeys != null
          ? List.from(disabledOptKeys!)
          : null,
      additionalValidators: List.from(additionalValidators),
    );
  }
}

class GeneratedFormSwitch extends GeneratedFormItem {
  bool disabled = false;

  GeneratedFormSwitch(
    super.key, {
    super.label,
<<<<<<< HEAD
    super.tooltip,
=======
>>>>>>> upstream/main
    super.belowWidgets,
    bool super.defaultValue = false,
    bool disabled = false,
    List<String? Function(bool value)> super.additionalValidators = const [],
  });

  @override
  bool ensureType(val) {
    return val == true || val == 'true';
  }

  @override
  GeneratedFormSwitch clone() {
    return GeneratedFormSwitch(
      key,
      label: label,
<<<<<<< HEAD
      tooltip: tooltip,
=======
>>>>>>> upstream/main
      belowWidgets: belowWidgets,
      defaultValue: defaultValue,
      disabled: false,
      additionalValidators: List.from(additionalValidators),
    );
  }
}

class GeneratedFormTagInput extends GeneratedFormItem {
  late MapEntry<String, String>? deleteConfirmationMessage;
  late bool singleSelect;
  late WrapAlignment alignment;
  late String emptyMessage;
  late bool showLabelWhenNotEmpty;
  GeneratedFormTagInput(
    super.key, {
    super.label,
<<<<<<< HEAD
    super.tooltip,
=======
>>>>>>> upstream/main
    super.belowWidgets,
    Map<String, MapEntry<int, bool>> super.defaultValue = const {},
    List<String? Function(Map<String, MapEntry<int, bool>> value)>
        super.additionalValidators =
        const [],
    this.deleteConfirmationMessage,
    this.singleSelect = false,
    this.alignment = WrapAlignment.start,
    this.emptyMessage = 'Input',
    this.showLabelWhenNotEmpty = true,
  });

  @override
  Map<String, MapEntry<int, bool>> ensureType(val) {
    return val is Map<String, MapEntry<int, bool>> ? val : {};
  }

  @override
  GeneratedFormTagInput clone() {
    return GeneratedFormTagInput(
      key,
      label: label,
<<<<<<< HEAD
      tooltip: tooltip,
=======
>>>>>>> upstream/main
      belowWidgets: belowWidgets,
      defaultValue: defaultValue,
      additionalValidators: List.from(additionalValidators),
      deleteConfirmationMessage: deleteConfirmationMessage,
      singleSelect: singleSelect,
      alignment: alignment,
      emptyMessage: emptyMessage,
      showLabelWhenNotEmpty: showLabelWhenNotEmpty,
    );
  }
}

typedef OnValueChanges =
    void Function(Map<String, dynamic> values, bool valid, bool isBuilding);

class GeneratedForm extends StatefulWidget {
  const GeneratedForm({
    super.key,
    required this.items,
    required this.onValueChanges,
  });

  final List<List<GeneratedFormItem>> items;
  final OnValueChanges onValueChanges;

  @override
  State<GeneratedForm> createState() => _GeneratedFormState();
}

List<List<GeneratedFormItem>> cloneFormItems(
  List<List<GeneratedFormItem>> items,
) {
  List<List<GeneratedFormItem>> clonedItems = [];
  for (var row in items) {
    List<GeneratedFormItem> clonedRow = [];
    for (var it in row) {
      clonedRow.add(it.clone());
    }
    clonedItems.add(clonedRow);
  }
  return clonedItems;
}

class GeneratedFormSubForm extends GeneratedFormItem {
  final List<List<GeneratedFormItem>> items;

  GeneratedFormSubForm(
    super.key,
    this.items, {
    super.label,
<<<<<<< HEAD
    super.tooltip,
=======
>>>>>>> upstream/main
    super.belowWidgets,
    super.defaultValue = const [],
  });

  @override
  ensureType(val) {
    return val; // Not easy to validate List<Map<String, dynamic>>
  }

  @override
  GeneratedFormSubForm clone() {
    return GeneratedFormSubForm(
      key,
      cloneFormItems(items),
      label: label,
<<<<<<< HEAD
      tooltip: tooltip,
=======
>>>>>>> upstream/main
      belowWidgets: belowWidgets,
      defaultValue: defaultValue,
    );
  }
}

<<<<<<< HEAD
=======
// Generates a color in the HSLuv (Pastel) color space
// https://pub.dev/documentation/hsluv/latest/hsluv/Hsluv/hpluvToRgb.html
Color generateRandomLightColor() {
  final randomSeed = Random().nextInt(120);
  // https://en.wikipedia.org/wiki/Golden_angle
  final goldenAngle = 180 * (3 - sqrt(5));
  // Generate next golden angle hue
  final double hue = randomSeed * goldenAngle;
  // Map from HPLuv color space to RGB, use constant saturation=100, lightness=70
  final List<double> rgbValuesDbl = Hsluv.hpluvToRgb([hue, 100, 70]);
  // Map RBG values from 0-1 to 0-255:
  final List<int> rgbValues = rgbValuesDbl
      .map((rgb) => (rgb * 255).toInt())
      .toList();
  return Color.fromARGB(255, rgbValues[0], rgbValues[1], rgbValues[2]);
}

>>>>>>> upstream/main
int generateRandomNumber(
  int seed1, {
  int seed2 = 0,
  int seed3 = 0,
  max = 10000,
}) {
  int combinedSeed = seed1.hashCode ^ seed2.hashCode ^ seed3.hashCode;
  Random random = Random(combinedSeed);
  int randomNumber = random.nextInt(max);
  return randomNumber;
}

<<<<<<< HEAD
=======
bool validateTextField(TextFormField tf) =>
    (tf.key as GlobalKey<FormFieldState>).currentState?.isValid == true;

class _TVTextFieldFocus extends StatefulWidget {
  final Widget child;
  final FocusNode textFocusNode;

  const _TVTextFieldFocus({
    required this.child,
    required this.textFocusNode,
  });

  @override
  State<_TVTextFieldFocus> createState() => _TVTextFieldFocusState();
}

class _TVTextFieldFocusState extends State<_TVTextFieldFocus> {
  final FocusNode _outerFocus = FocusNode();
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    widget.textFocusNode.addListener(_onTextFocusChange);
  }

  void _onTextFocusChange() {
    if (!widget.textFocusNode.hasFocus && _activated) {
      setState(() => _activated = false);
      _outerFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    widget.textFocusNode.removeListener(_onTextFocusChange);
    _outerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _outerFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          setState(() => _activated = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.textFocusNode.requestFocus();
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListenableBuilder(
        listenable: _outerFocus,
        builder: (context, child) => Container(
          decoration: _outerFocus.hasFocus && !_activated
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: ExcludeFocus(excluding: !_activated, child: widget.child),
        ),
      ),
    );
  }
}

>>>>>>> upstream/main
class _GeneratedFormState extends State<GeneratedForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> values = {};
  late List<List<Widget>> formInputs;
  List<List<Widget>> rows = [];
  String? initKey;
<<<<<<< HEAD
  Map<String, bool> _fieldValid = {};

  void someValueChanged({bool isBuilding = false, bool forceInvalid = false}) {
    var valid = !_fieldValid.values.any((v) => !v);
    if (forceInvalid) valid = false;
    widget.onValueChanges(values, valid, isBuilding);
=======
  int forceUpdateKeyCount = 0;

  // If any value changes, call this to update the parent with value and validity
  void someValueChanged({bool isBuilding = false, bool forceInvalid = false}) {
    Map<String, dynamic> returnValues = values;
    var valid = true;
    for (int r = 0; r < formInputs.length; r++) {
      for (int i = 0; i < formInputs[r].length; i++) {
        if (formInputs[r][i] is TextFormField) {
          valid = valid && validateTextField(formInputs[r][i] as TextFormField);
        }
      }
    }
    if (forceInvalid) {
      valid = false;
    }
    widget.onValueChanges(returnValues, valid, isBuilding);
>>>>>>> upstream/main
  }

  void initForm() {
    initKey = widget.key.toString();
<<<<<<< HEAD
    values.clear();
    _fieldValid.clear();
    for (var row in widget.items) {
      for (var e in row) {
        if (e is GeneratedFormSubForm) {
          values[e.key] = [];
          for (Map<String, dynamic> v
              in ((e.defaultValue ?? []) as List<dynamic>)) {
            var fullDefaults = getDefaultValuesFromFormItems(e.items);
            for (var element in v.entries) {
              fullDefaults[element.key] = element.value;
            }
            values[e.key].add(fullDefaults);
          }
        } else {
          values[e.key] = e.defaultValue;
          if (e is GeneratedFormTextField) {
            final val = (e.defaultValue as String?) ?? '';
            var valid = !e.required || val.trim().isNotEmpty;
            if (valid) {
              for (var validator in e.additionalValidators) {
                if (validator(val) != null) {
                  valid = false;
                  break;
                }
              }
            }
            _fieldValid[e.key] = valid;
          }
        }
      }
    }
    formInputs = widget.items
        .map(
          (row) => row.map((_) => const SizedBox.shrink() as Widget).toList(),
        )
        .toList();
=======
    // Initialize form values as all empty
    values.clear();
    for (var row in widget.items) {
      for (var e in row) {
        values[e.key] = e.defaultValue;
      }
    }

    // Dynamically create form inputs
    formInputs = widget.items.asMap().entries.map((row) {
      return row.value.asMap().entries.map((e) {
        var formItem = e.value;
        if (formItem is GeneratedFormTextField) {
          final formFieldKey = GlobalKey<FormFieldState>();
          var ctrl = TextEditingController(text: values[formItem.key]);
          return TypeAheadField<String>(
            controller: ctrl,
            builder: (context, controller, focusNode) {
              final textField = TextFormField(
                controller: ctrl,
                focusNode: focusNode,
                keyboardType: formItem.textInputType,
                obscureText: formItem.password,
                autocorrect: !formItem.password,
                enableSuggestions: !formItem.password,
                key: formFieldKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  setState(() {
                    values[formItem.key] = value;
                    someValueChanged();
                  });
                },
                decoration: InputDecoration(
                  helperText: formItem.label + (formItem.required ? ' *' : ''),
                  hintText: formItem.hint,
                ),
                minLines: formItem.max <= 1 ? null : formItem.max,
                maxLines: formItem.max <= 1 ? 1 : formItem.max,
                validator: (value) {
                  if (formItem.required &&
                      (value == null || value.trim().isEmpty)) {
                    return '${formItem.label} ${tr('requiredInBrackets')}';
                  }
                  for (var validator in formItem.additionalValidators) {
                    String? result = validator(value);
                    if (result != null) {
                      return result;
                    }
                  }
                  return null;
                },
              );
              if (context.read<SettingsProvider>().isTV) {
                return _TVTextFieldFocus(
                  textFocusNode: focusNode,
                  child: textField,
                );
              }
              return textField;
            },
            itemBuilder: (context, value) {
              return ListTile(title: Text(value));
            },
            onSelected: (value) {
              ctrl.text = value;
              setState(() {
                values[formItem.key] = value;
                someValueChanged();
              });
            },
            suggestionsCallback: (search) {
              return formItem.autoCompleteOptions
                  ?.where((t) => t.toLowerCase().contains(search.toLowerCase()))
                  .toList();
            },
            hideOnEmpty: true,
          );
        } else if (formItem is GeneratedFormDropdown) {
          if (formItem.opts!.isEmpty) {
            return Text(tr('dropdownNoOptsError'));
          }
          return DropdownButtonFormField(
            decoration: InputDecoration(labelText: formItem.label),
            value: values[formItem.key],
            items: formItem.opts!.map((e2) {
              var enabled = formItem.disabledOptKeys?.contains(e2.key) != true;
              return DropdownMenuItem(
                value: e2.key,
                enabled: enabled,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: Text(e2.value),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                values[formItem.key] = value ?? formItem.opts!.first.key;
                someValueChanged();
              });
            },
          );
        } else if (formItem is GeneratedFormSubForm) {
          values[formItem.key] = [];
          for (Map<String, dynamic> v
              in ((formItem.defaultValue ?? []) as List<dynamic>)) {
            var fullDefaults = getDefaultValuesFromFormItems(formItem.items);
            for (var element in v.entries) {
              fullDefaults[element.key] = element.value;
            }
            values[formItem.key].add(fullDefaults);
          }
          return Container();
        } else {
          return Container(); // Some input types added in build
        }
      }).toList();
    }).toList();
>>>>>>> upstream/main
    someValueChanged(isBuilding: true);
  }

  @override
  void initState() {
    super.initState();
    initForm();
  }

<<<<<<< HEAD
  bool _itemsDimensionsChanged() {
    if (formInputs.length != widget.items.length) return true;
    for (var r = 0; r < formInputs.length; r++) {
      if (formInputs[r].length != widget.items[r].length) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.key.toString() != initKey || _itemsDimensionsChanged()) {
      initForm();
    }
    for (var r = 0; r < formInputs.length && r < widget.items.length; r++) {
      for (
        var e = 0;
        e < formInputs[r].length && e < widget.items[r].length;
        e++
      ) {
        final item = widget.items[r][e];
        final fieldKey = item.key;
        if (item is GeneratedFormSwitch) {
          formInputs[r][e] = _FormSwitchField(
            key: ValueKey(fieldKey),
            item: item,
            value: values[fieldKey] as bool? ?? false,
            onChanged: (v) {
              values[fieldKey] = v;
              someValueChanged();
            },
          );
        } else if (item is GeneratedFormTextField) {
          formInputs[r][e] = _FormTextField(
            key: ValueKey(fieldKey),
            item: item,
            initialValue: values[fieldKey] as String? ?? '',
            onChanged: (v, {required bool isValid}) {
              values[fieldKey] = v;
              _fieldValid[fieldKey] = isValid;
              someValueChanged();
            },
          );
        } else if (item is GeneratedFormDropdown) {
          formInputs[r][e] = _FormDropdownField(
            key: ValueKey(fieldKey),
            item: item,
            value: values[fieldKey] as String? ?? '',
            onChanged: (v) {
              values[fieldKey] = v ?? item.opts!.first.key;
              someValueChanged();
            },
          );
        } else if (item is GeneratedFormTagInput) {
          formInputs[r][e] = _FormTagInputField(
            key: ValueKey(fieldKey),
            item: item,
            value:
                (values[fieldKey] as Map<String, MapEntry<int, bool>>?) ?? {},
            onChanged: (v) {
              values[fieldKey] = v;
              someValueChanged();
            },
          );
        } else if (item is GeneratedFormSubForm) {
          formInputs[r][e] = _FormSubFormField(
            key: ValueKey(fieldKey),
            item: item,
            initialValues: ((values[fieldKey] as List?) ?? [])
                .cast<Map<String, dynamic>>(),
            onChanged: (v, {bool? forceInvalid}) {
              values[fieldKey] = v;
              someValueChanged(forceInvalid: forceInvalid == true);
            },
          );
=======
  @override
  Widget build(BuildContext context) {
    if (widget.key.toString() != initKey) {
      initForm();
    }
    for (var r = 0; r < formInputs.length; r++) {
      for (var e = 0; e < formInputs[r].length; e++) {
        String fieldKey = widget.items[r][e].key;
        if (widget.items[r][e] is GeneratedFormSwitch) {
          formInputs[r][e] = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(widget.items[r][e].label)),
              const SizedBox(width: 8),
              Switch(
                value: values[fieldKey],
                onChanged: (widget.items[r][e] as GeneratedFormSwitch).disabled
                    ? null
                    : (value) {
                        setState(() {
                          values[fieldKey] = value;
                          someValueChanged();
                        });
                      },
              ),
            ],
          );
        } else if (widget.items[r][e] is GeneratedFormTagInput) {
          onAddPressed() {
            showDialog<Map<String, dynamic>?>(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: widget.items[r][e].label,
                  items: [
                    [GeneratedFormTextField('label', label: tr('label'))],
                  ],
                );
              },
            ).then((value) {
              String? label = value?['label'];
              if (label != null) {
                setState(() {
                  var temp =
                      values[fieldKey] as Map<String, MapEntry<int, bool>>?;
                  temp ??= {};
                  if (temp[label] == null) {
                    var singleSelect =
                        (widget.items[r][e] as GeneratedFormTagInput)
                            .singleSelect;
                    var someSelected = temp.entries
                        .where((element) => element.value.value)
                        .isNotEmpty;
                    temp[label] = MapEntry(
                      generateRandomLightColor().value,
                      !(someSelected && singleSelect),
                    );
                    values[fieldKey] = temp;
                    someValueChanged();
                  }
                });
              }
            });
          }

          formInputs[r][e] = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                          ?.isNotEmpty ==
                      true &&
                  (widget.items[r][e] as GeneratedFormTagInput)
                      .showLabelWhenNotEmpty)
                Column(
                  crossAxisAlignment:
                      (widget.items[r][e] as GeneratedFormTagInput).alignment ==
                          WrapAlignment.center
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.items[r][e].label),
                    const SizedBox(height: 8),
                  ],
                ),
              Wrap(
                alignment:
                    (widget.items[r][e] as GeneratedFormTagInput).alignment,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // (values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                  //             ?.isEmpty ==
                  //         true
                  //     ? Text(
                  //         (widget.items[r][e] as GeneratedFormTagInput)
                  //             .emptyMessage,
                  //       )
                  //     : const SizedBox.shrink(),
                  ...(values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                          ?.entries
                          .map((e2) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ChoiceChip(
                                label: Text(e2.key),
                                backgroundColor: Color(
                                  e2.value.key,
                                ).withAlpha(50),
                                selectedColor: Color(e2.value.key),
                                visualDensity: VisualDensity.compact,
                                selected: e2.value.value,
                                onSelected: (value) {
                                  setState(() {
                                    (values[fieldKey]
                                        as Map<String, MapEntry<int, bool>>)[e2
                                        .key] = MapEntry(
                                      (values[fieldKey]
                                              as Map<
                                                String,
                                                MapEntry<int, bool>
                                              >)[e2.key]!
                                          .key,
                                      value,
                                    );
                                    if ((widget.items[r][e]
                                                as GeneratedFormTagInput)
                                            .singleSelect &&
                                        value == true) {
                                      for (var key
                                          in (values[fieldKey]
                                                  as Map<
                                                    String,
                                                    MapEntry<int, bool>
                                                  >)
                                              .keys) {
                                        if (key != e2.key) {
                                          (values[fieldKey]
                                              as Map<
                                                String,
                                                MapEntry<int, bool>
                                              >)[key] = MapEntry(
                                            (values[fieldKey]
                                                    as Map<
                                                      String,
                                                      MapEntry<int, bool>
                                                    >)[key]!
                                                .key,
                                            false,
                                          );
                                        }
                                      }
                                    }
                                    someValueChanged();
                                  });
                                },
                              ),
                            );
                          }) ??
                      [const SizedBox.shrink()],
                  (values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                              ?.values
                              .where((e) => e.value)
                              .length ==
                          1
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                var temp =
                                    values[fieldKey]
                                        as Map<String, MapEntry<int, bool>>;
                                // get selected category str where bool is true
                                final oldEntry = temp.entries.firstWhere(
                                  (entry) => entry.value.value,
                                );
                                // generate new color, ensure it is not the same
                                int newColor = oldEntry.value.key;
                                while (oldEntry.value.key == newColor) {
                                  newColor = generateRandomLightColor().value;
                                }
                                // Update entry with new color, remain selected
                                temp.update(
                                  oldEntry.key,
                                  (old) => MapEntry(newColor, old.value),
                                );
                                values[fieldKey] = temp;
                                someValueChanged();
                              });
                            },
                            icon: const Icon(Icons.format_color_fill_rounded),
                            visualDensity: VisualDensity.compact,
                            tooltip: tr('colour'),
                          ),
                        )
                      : const SizedBox.shrink(),
                  (values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                              ?.values
                              .where((e) => e.value)
                              .isNotEmpty ==
                          true
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            onPressed: () {
                              fn() {
                                setState(() {
                                  var temp =
                                      values[fieldKey]
                                          as Map<String, MapEntry<int, bool>>;
                                  temp.removeWhere((key, value) => value.value);
                                  values[fieldKey] = temp;
                                  someValueChanged();
                                });
                              }

                              if ((widget.items[r][e] as GeneratedFormTagInput)
                                      .deleteConfirmationMessage !=
                                  null) {
                                var message =
                                    (widget.items[r][e]
                                            as GeneratedFormTagInput)
                                        .deleteConfirmationMessage!;
                                showDialog<Map<String, dynamic>?>(
                                  context: context,
                                  builder: (BuildContext ctx) {
                                    return GeneratedFormModal(
                                      title: message.key,
                                      message: message.value,
                                      items: const [],
                                    );
                                  },
                                ).then((value) {
                                  if (value != null) {
                                    fn();
                                  }
                                });
                              } else {
                                fn();
                              }
                            },
                            icon: const Icon(Icons.remove),
                            visualDensity: VisualDensity.compact,
                            tooltip: tr('remove'),
                          ),
                        )
                      : const SizedBox.shrink(),
                  (values[fieldKey] as Map<String, MapEntry<int, bool>>?)
                              ?.isEmpty ==
                          true
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextButton.icon(
                            onPressed: onAddPressed,
                            icon: const Icon(Icons.add),
                            label: Text(
                              (widget.items[r][e] as GeneratedFormTagInput)
                                  .label,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            onPressed: onAddPressed,
                            icon: const Icon(Icons.add),
                            visualDensity: VisualDensity.compact,
                            tooltip: tr('add'),
                          ),
                        ),
                ],
              ),
            ],
          );
        } else if (widget.items[r][e] is GeneratedFormSubForm) {
          List<Widget> subformColumn = [];
          var compact =
              (widget.items[r][e] as GeneratedFormSubForm).items.length == 1 &&
              (widget.items[r][e] as GeneratedFormSubForm).items[0].length == 1;
          for (int i = 0; i < values[fieldKey].length; i++) {
            var internalFormKey = ValueKey(
              generateRandomNumber(
                values[fieldKey].length,
                seed2: i,
                seed3: forceUpdateKeyCount,
              ),
            );
            subformColumn.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(height: 16),
                  if (!compact)
                    Text(
                      '${(widget.items[r][e] as GeneratedFormSubForm).label} (${i + 1})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  GeneratedForm(
                    key: internalFormKey,
                    items:
                        cloneFormItems(
                              (widget.items[r][e] as GeneratedFormSubForm)
                                  .items,
                            )
                            .map(
                              (x) => x.map((y) {
                                y.defaultValue = values[fieldKey]?[i]?[y.key];
                                y.key = '${y.key.toString()},$internalFormKey';
                                return y;
                              }).toList(),
                            )
                            .toList(),
                    onValueChanges: (values, valid, isBuilding) {
                      values = values.map(
                        (key, value) => MapEntry(key.split(',')[0], value),
                      );
                      if (valid) {
                        this.values[fieldKey]?[i] = values;
                      }
                      someValueChanged(
                        isBuilding: isBuilding,
                        forceInvalid: !valid,
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: (values[fieldKey].length > 0)
                            ? () {
                                var temp = List.from(values[fieldKey]);
                                temp.removeAt(i);
                                values[fieldKey] = List.from(temp);
                                forceUpdateKeyCount++;
                                someValueChanged();
                              }
                            : null,
                        label: Text(
                          '${(widget.items[r][e] as GeneratedFormSubForm).label} (${i + 1})',
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          subformColumn.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 0, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        values[fieldKey].add(
                          getDefaultValuesFromFormItems(
                            (widget.items[r][e] as GeneratedFormSubForm).items,
                          ),
                        );
                        forceUpdateKeyCount++;
                        someValueChanged();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        (widget.items[r][e] as GeneratedFormSubForm).label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          formInputs[r][e] = Column(children: subformColumn);
>>>>>>> upstream/main
        }
      }
    }

    rows.clear();
    formInputs.asMap().entries.forEach((rowInputs) {
      if (rowInputs.key > 0) {
        rows.add([
          SizedBox(
<<<<<<< HEAD
            height:
                (widget.items[rowInputs.key - 1].isNotEmpty &&
                    widget.items[rowInputs.key - 1][0] is GeneratedFormSwitch)
=======
            height: widget.items[rowInputs.key - 1][0] is GeneratedFormSwitch
>>>>>>> upstream/main
                ? 8
                : 25,
          ),
        ]);
      }
      List<Widget> rowItems = [];
      rowInputs.value.asMap().entries.forEach((rowInput) {
        if (rowInput.key > 0) {
          rowItems.add(const SizedBox(width: 20));
        }
        rowItems.add(
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                rowInput.value,
                ...widget.items[rowInputs.key][rowInput.key].belowWidgets,
              ],
            ),
          ),
        );
      });
      rows.add(rowItems);
    });

<<<<<<< HEAD
    final bool hasRequiredFields = widget.items.any(
      (row) =>
          row.any((item) => item is GeneratedFormTextField && item.required),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
=======
    return Form(
      key: _formKey,
      child: Column(
>>>>>>> upstream/main
        children: [
          ...rows.map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [...row.map((e) => e)],
            ),
          ),
<<<<<<< HEAD
          if (hasRequiredFields) ...[
            const SizedBox(height: 8),
            Text(
              '* ${tr('requiredInBrackets')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
=======
>>>>>>> upstream/main
        ],
      ),
    );
  }
}
<<<<<<< HEAD

// ─── Extracted field renderer widgets ────────────────────────────────────────

class _FormSwitchField extends StatefulWidget {
  const _FormSwitchField({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  final GeneratedFormSwitch item;
  final bool value;
  final void Function(bool) onChanged;

  @override
  State<_FormSwitchField> createState() => _FormSwitchFieldState();
}

class _FormSwitchFieldState extends State<_FormSwitchField> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_FormSwitchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                      ),
                    ),
                    if (widget.item.tooltip != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Tooltip(
                          message: widget.item.tooltip!,
                          triggerMode: TooltipTriggerMode.tap,
                          child: const Icon(Icons.info_outline, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: _value,
                onChanged: widget.item.disabled
                    ? null
                    : (v) {
                        setState(() => _value = v);
                        widget.onChanged(v);
                      },
              ),
            ],
          ),
          if (widget.item.belowWidgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Opacity(
                opacity: 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.item.belowWidgets
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withOpacity(AppOpacity.muted),
                                ),
                            child: w,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef _OnTextChanged = void Function(String value, {required bool isValid});

class _FormTextField extends StatefulWidget {
  const _FormTextField({
    super.key,
    required this.item,
    required this.initialValue,
    required this.onChanged,
  });

  final GeneratedFormTextField item;
  final String initialValue;
  final _OnTextChanged onChanged;

  @override
  State<_FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<_FormTextField> {
  late final TextEditingController _controller;
  final _formFieldKey = GlobalKey<FormFieldState>();

  bool _checkValid(String? value) {
    if (widget.item.required && (value == null || value.trim().isEmpty)) {
      return false;
    }
    for (var validator in widget.item.additionalValidators) {
      if (validator(value) != null) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_FormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      controller: _controller,
      builder: (context, controller, focusNode) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.label + (widget.item.required ? ' *' : ''),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: widget.item.textInputType,
                obscureText: widget.item.password,
                autocorrect: !widget.item.password,
                enableSuggestions: !widget.item.password,
                key: _formFieldKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  widget.onChanged(value, isValid: _checkValid(value));
                },
                decoration: InputDecoration(
                  hintText: widget.item.hint,
                  suffixIcon: widget.item.tooltip != null
                      ? Tooltip(
                          message: widget.item.tooltip!,
                          triggerMode: TooltipTriggerMode.tap,
                          child: const Icon(Icons.info_outline, size: 20),
                        )
                      : null,
                ),
                minLines: widget.item.max <= 1 ? null : widget.item.max,
                maxLines: widget.item.max <= 1 ? 1 : widget.item.max,
                validator: (value) {
                  if (widget.item.required &&
                      (value == null || value.trim().isEmpty)) {
                    return '${widget.item.label} ${tr('requiredInBrackets')}';
                  }
                  for (var validator in widget.item.additionalValidators) {
                    final result = validator(value);
                    if (result != null) return result;
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      },
      itemBuilder: (context, value) => ListTile(title: Text(value)),
      onSelected: (value) {
        _controller.text = value;
        widget.onChanged(value, isValid: _checkValid(value));
      },
      suggestionsCallback: (search) => widget.item.autoCompleteOptions
          ?.where((t) => t.toLowerCase().contains(search.toLowerCase()))
          .toList(),
      hideOnEmpty: true,
    );
  }
}

class _FormDropdownField extends StatefulWidget {
  const _FormDropdownField({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  final GeneratedFormDropdown item;
  final String value;
  final void Function(String?) onChanged;

  @override
  State<_FormDropdownField> createState() => _FormDropdownFieldState();
}

class _FormDropdownFieldState extends State<_FormDropdownField> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_FormDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.opts == null || widget.item.opts!.isEmpty) {
      return Text(tr('dropdownNoOptsError'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              suffixIcon: widget.item.tooltip != null
                  ? Tooltip(
                      message: widget.item.tooltip!,
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(Icons.info_outline, size: 20),
                    )
                  : null,
            ),
            dropdownColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
            value: _value,
            items: widget.item.opts!.map((e) {
              final enabled =
                  widget.item.disabledOptKeys?.contains(e.key) != true;
              return DropdownMenuItem(
                value: e.key,
                enabled: enabled,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: Text(e.value),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _value = value ?? widget.item.opts!.first.key);
              widget.onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _FormTagInputField extends StatefulWidget {
  const _FormTagInputField({
    super.key,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  final GeneratedFormTagInput item;
  final Map<String, MapEntry<int, bool>> value;
  final void Function(Map<String, MapEntry<int, bool>>) onChanged;

  @override
  State<_FormTagInputField> createState() => _FormTagInputFieldState();
}

class _FormTagInputFieldState extends State<_FormTagInputField> {
  late Map<String, MapEntry<int, bool>> _tags;

  @override
  void initState() {
    super.initState();
    _tags = Map.from(widget.value);
  }

  @override
  void didUpdateWidget(_FormTagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _tags = Map.from(widget.value);
  }

  void _addTag(String label) {
    if (_tags[label] != null) return;
    setState(() {
      final someSelected = _tags.values.any((e) => e.value);
      _tags[label] = MapEntry(
        generateRandomLightColor().value,
        !(someSelected && widget.item.singleSelect),
      );
    });
    widget.onChanged(Map.from(_tags));
  }

  void _showAddDialog() {
    showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext ctx) {
        return GeneratedFormModal(
          title: widget.item.label,
          items: [
            [GeneratedFormTextField('label', label: tr('label'))],
          ],
        );
      },
    ).then((value) {
      final label = value?['label'] as String?;
      if (label != null) _addTag(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tags.isNotEmpty && widget.item.showLabelWhenNotEmpty)
          Column(
            crossAxisAlignment: widget.item.alignment == WrapAlignment.center
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(widget.item.label)),
                  if (widget.item.tooltip != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Tooltip(
                        message: widget.item.tooltip!,
                        triggerMode: TooltipTriggerMode.tap,
                        child: const Icon(Icons.info_outline, size: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: widget.item.alignment,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._tags.entries.map((e2) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: ChoiceChip(
                        label: Text(
                          e2.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Color(
                          e2.value.key,
                        ).withOpacity(50 / 255),
                        selectedColor: Color(e2.value.key),
                        visualDensity: VisualDensity.compact,
                        selected: e2.value.value,
                        onSelected: (selected) {
                          setState(() {
                            _tags[e2.key] = MapEntry(
                              _tags[e2.key]!.key,
                              selected,
                            );
                            if (widget.item.singleSelect && selected) {
                              for (final key in _tags.keys) {
                                if (key != e2.key) {
                                  _tags[key] = MapEntry(_tags[key]!.key, false);
                                }
                              }
                            }
                          });
                          widget.onChanged(Map.from(_tags));
                        },
                      ),
                    );
                  }),
                  if (_tags.values.where((e) => e.value).length == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        onPressed: () {
                          final oldEntry = _tags.entries.firstWhere(
                            (e) => e.value.value,
                          );
                          int newColor = oldEntry.value.key;
                          while (newColor == oldEntry.value.key) {
                            newColor = generateRandomLightColor().value;
                          }
                          setState(() {
                            _tags[oldEntry.key] = MapEntry(
                              newColor,
                              oldEntry.value.value,
                            );
                          });
                          widget.onChanged(Map.from(_tags));
                        },
                        icon: const Icon(
                          Icons.format_color_fill_rounded,
                          size: 16,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: tr('colour'),
                      ),
                    ),
                  if (_tags.values.any((e) => e.value))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        onPressed: () {
                          fn() {
                            setState(
                              () => _tags.removeWhere((k, v) => v.value),
                            );
                            widget.onChanged(Map.from(_tags));
                          }

                          final msg = widget.item.deleteConfirmationMessage;
                          if (msg != null) {
                            showDialog<Map<String, dynamic>?>(
                              context: context,
                              builder: (ctx) => GeneratedFormModal(
                                title: msg.key,
                                message: msg.value,
                                items: const [],
                              ),
                            ).then((v) {
                              if (v != null) fn();
                            });
                          } else {
                            fn();
                          }
                        },
                        icon: const Icon(Icons.remove, size: 16),
                        visualDensity: VisualDensity.compact,
                        tooltip: tr('remove'),
                      ),
                    ),
                  if (_tags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TextButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          widget.item.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, size: 16),
                        visualDensity: VisualDensity.compact,
                        tooltip: tr('add'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _OnSubFormChanged =
    void Function(List<Map<String, dynamic>> values, {bool? forceInvalid});

class _FormSubFormField extends StatefulWidget {
  const _FormSubFormField({
    super.key,
    required this.item,
    required this.initialValues,
    required this.onChanged,
  });

  final GeneratedFormSubForm item;
  final List<Map<String, dynamic>> initialValues;
  final _OnSubFormChanged onChanged;

  @override
  State<_FormSubFormField> createState() => _FormSubFormFieldState();
}

class _FormSubFormFieldState extends State<_FormSubFormField> {
  late List<Map<String, dynamic>> _values;
  int _forceUpdateKeyCount = 0;

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.initialValues);
  }

  @override
  void didUpdateWidget(_FormSubFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValues != oldWidget.initialValues) {
      _values = List.from(widget.initialValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        widget.item.items.length == 1 && widget.item.items[0].length == 1;
    final subformColumn = <Widget>[];

    for (int i = 0; i < _values.length; i++) {
      final internalFormKey = ValueKey(
        generateRandomNumber(
          _values.length,
          seed2: i,
          seed3: _forceUpdateKeyCount,
        ),
      );
      subformColumn.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) const SizedBox(height: 16),
            if (!compact)
              Text(
                '${widget.item.label} (${i + 1})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            GeneratedForm(
              key: internalFormKey,
              items: cloneFormItems(widget.item.items)
                  .map(
                    (x) => x.map((y) {
                      y.defaultValue = _values[i][y.key];
                      y.key = '${y.key},$internalFormKey';
                      return y;
                    }).toList(),
                  )
                  .toList(),
              onValueChanges: (subValues, valid, isBuilding) {
                final mapped = subValues.map(
                  (key, value) => MapEntry(key.split(',')[0], value),
                );
                if (valid) _values[i] = mapped;
                widget.onChanged(List.from(_values), forceInvalid: !valid);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _values.isNotEmpty
                      ? () {
                          setState(() {
                            _values.removeAt(i);
                            _forceUpdateKeyCount++;
                          });
                          widget.onChanged(List.from(_values));
                        }
                      : null,
                  label: Text('${widget.item.label} (${i + 1})'),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      );
    }

    subformColumn.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 0, top: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _values.add(
                      getDefaultValuesFromFormItems(widget.item.items),
                    );
                    _forceUpdateKeyCount++;
                  });
                  widget.onChanged(List.from(_values));
                },
                icon: const Icon(Icons.add),
                label: Text(widget.item.label),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(children: subformColumn);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> getDefaultValuesFromFormItems(
  List<List<GeneratedFormItem>> items,
) {
  Map<String, dynamic> values = {};
  for (var row in items) {
    for (var e in row) {
      values[e.key] = e.defaultValue;
    }
  }
  return values;
}
=======
>>>>>>> upstream/main
