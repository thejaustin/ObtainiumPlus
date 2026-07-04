import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool importInProgress = false;

  @override
  Widget build(BuildContext context) {
    SourceProvider sourceProvider = SourceProvider();
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
    var behaviorSettings = context.watch<BehaviorSettingsProvider>();

    var outlineButtonStyle = ButtonStyle(
      shape: WidgetStateProperty.all(
        StadiumBorder(
          side: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );

    urlListImport({String? initValue, bool overrideInitValid = false}) {
      showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (BuildContext ctx) {
          return GeneratedFormModal(
            initValid: overrideInitValid,
            title: tr('importFromURLList'),
            items: [
              [
                GeneratedFormTextField(
                  'appURLList',
                  defaultValue: initValue ?? '',
                  label: tr('appURLList'),
                  max: 7,
                  additionalValidators: [
                    (dynamic value) {
                      if (value != null && value.isNotEmpty) {
                        var lines = value.trim().split('\n');
                        for (int i = 0; i < lines.length; i++) {
                          try {
                            sourceProvider.getSource(lines[i]);
                          } catch (e) {
                            return '${tr('line')} ${i + 1}: $e';
                          }
                        }
                      }
                      return null;
                    },
                  ],
                ),
              ],
            ],
          );
        },
      ).then((values) {
        if (values != null) {
          var urls = (values['appURLList'] as String).split('\n');
          setState(() {
            importInProgress = true;
          });
          appsProvider
              .addAppsByURL(urls)
              .then((errors) {
                if (errors.isEmpty) {
                  showMessage(
                    tr(
                      'importedX',
                      args: [plural('apps', urls.length).toLowerCase()],
                    ),
                    context,
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return ImportErrorDialog(
                        urlsLength: urls.length,
                        errors: errors,
                      );
                    },
                  );
                }
              })
              .catchError((e) {
                showError(e, context);
              })
              .whenComplete(() {
                setState(() {
                  importInProgress = false;
                });
              });
        }
      });
    }

    runObtainiumExport({bool pickOnly = false}) async {
      AppHaptics.selectionClick();
      appsProvider
          .export(
            pickOnly:
                pickOnly || (await behaviorSettings.getExportDir()) == null,
            bsp: behaviorSettings,
          )
          .then((String? result) {
            if (result != null) {
              showMessage(tr('exportedTo', args: [result]), context);
            }
          })
          .catchError((e) {
            showError(e, context);
          });
    }

    runObtainiumImport() {
      AppHaptics.selectionClick();
      FilePicker.pickFiles()
          .then((result) {
            setState(() {
              importInProgress = true;
            });
            if (result != null) {
              String data = File(result.files.single.path!).readAsStringSync();
              try {
                jsonDecode(data);
              } catch (e) {
                throw ObtainiumError(tr('invalidInput'));
              }
              appsProvider.import(data).then((value) {
                appsProvider.addMissingCategories(context.read());
                showMessage(
                  '${tr('importedX', args: [plural('apps', value.key.length).toLowerCase()])}${value.value ? ' + ${tr('settings').toLowerCase()}' : ''}',
                  context,
                );
              });
            } else {
              // User canceled the picker
            }
          })
          .catchError((e) {
            showError(e, context);
          })
          .whenComplete(() {
            setState(() {
              importInProgress = false;
            });
          });
    }

    runUrlImport() {
      FilePicker.pickFiles().then((result) {
        if (result != null) {
          urlListImport(
            overrideInitValid: true,
            initValue: RegExp('https?://[^"]+')
                .allMatches(File(result.files.single.path!).readAsStringSync())
                .map((e) => e.input.substring(e.start, e.end))
                .toSet()
                .toList()
                .where((url) {
                  try {
                    sourceProvider.getSource(url);
                    return true;
                  } catch (e) {
                    return false;
                  }
                })
                .join('\n'),
          );
        }
      });
    }

    runSourceSearch(AppSource source) {
      () async {
            var values = await showDialog<Map<String, dynamic>?>(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: tr('searchX', args: [source.name]),
                  items: [
                    [
                      GeneratedFormTextField(
                        'searchQuery',
                        label: tr('searchQuery'),
                        required: source.name != FDroidRepo().name,
                      ),
                    ],
                    ...source.searchQuerySettingFormItems.map((e) => [e]),
                    [
                      GeneratedFormTextField(
                        'url',
                        label: source.hosts.isNotEmpty
                            ? tr('overrideSource')
                            : plural('url', 1).substring(2),
                        defaultValue: source.hosts.isNotEmpty
                            ? source.hosts[0]
                            : '',
                        required: true,
                      ),
                    ],
                  ],
                );
              },
            );
            if (values != null) {
              setState(() {
                importInProgress = true;
              });
              if (source.hosts.isEmpty || values['url'] != source.hosts[0]) {
                source = sourceProvider.getSource(
                  values['url'],
                  overrideSource: source.runtimeType.toString(),
                );
              }
              var urlsWithDescriptions = await source.search(
                values['searchQuery'] as String,
                querySettings: values,
              );
              if (urlsWithDescriptions.isNotEmpty) {
                var selectedUrls =
                    // ignore: use_build_context_synchronously
                    await showDialog<List<String>?>(
                      context: context,
                      builder: (BuildContext ctx) {
                        return SelectionModal(
                          entries: urlsWithDescriptions,
                          selectedByDefault: false,
                        );
                      },
                    );
                if (selectedUrls != null && selectedUrls.isNotEmpty) {
                  var errors = await appsProvider.addAppsByURL(
                    selectedUrls,
                    sourceOverride: source,
                  );
                  if (errors.isEmpty) {
                    // ignore: use_build_context_synchronously
                    showMessage(
                      tr(
                        'importedX',
                        args: [
                          plural('apps', selectedUrls.length).toLowerCase(),
                        ],
                      ),
                      context,
                    );
                  } else {
                    // ignore: use_build_context_synchronously
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return ImportErrorDialog(
                          urlsLength: selectedUrls.length,
                          errors: errors,
                        );
                      },
                    );
                  }
                }
              } else {
                throw ObtainiumError(tr('noResults'));
              }
            }
          }()
          .catchError((e) {
            showError(e, context);
          })
          .whenComplete(() {
            setState(() {
              importInProgress = false;
            });
          });
    }

    runMassSourceImport(MassAppUrlSource source) {
      () async {
            var values = await showDialog<Map<String, dynamic>?>(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: tr('importX', args: [source.name]),
                  items: source.requiredArgs
                      .map((e) => [GeneratedFormTextField(e, label: e)])
                      .toList(),
                );
              },
            );
            if (values != null) {
              setState(() {
                importInProgress = true;
              });
              var urlsWithDescriptions = await source.getUrlsWithDescriptions(
                values.values.map((e) => e.toString()).toList(),
              );
              var selectedUrls =
                  // ignore: use_build_context_synchronously
                  await showDialog<List<String>?>(
                    context: context,
                    builder: (BuildContext ctx) {
                      return SelectionModal(entries: urlsWithDescriptions);
                    },
                  );
              if (selectedUrls != null) {
                var errors = await appsProvider.addAppsByURL(selectedUrls);
                if (errors.isEmpty) {
                  // ignore: use_build_context_synchronously
                  showMessage(
                    tr(
                      'importedX',
                      args: [plural('apps', selectedUrls.length).toLowerCase()],
                    ),
                    context,
                  );
                } else {
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return ImportErrorDialog(
                        urlsLength: selectedUrls.length,
                        errors: errors,
                      );
                    },
                  );
                }
              }
            }
          }()
          .catchError((e) {
            showError(e, context);
          })
          .whenComplete(() {
            setState(() {
              importInProgress = false;
            });
          });
    }

    var sourceStrings = <String, List<String>>{};
    sourceProvider.sources.where((e) => e.canSearch).forEach((s) {
      sourceStrings[s.name] = [s.name];
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: <Widget>[
          CustomAppBar(title: tr('importExport')),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder(
                    future: behaviorSettings.getExportDir(),
                      builder: (context, snapshot) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    style: outlineButtonStyle,
                                    onPressed: importInProgress
                                        ? null
                                        : () {
                                            runObtainiumExport(pickOnly: true);
                                          },
                                    child: Text(
                                      tr('pickExportDir'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextButton(
                                    style: outlineButtonStyle,
                                    onPressed:
                                        importInProgress ||
                                            snapshot.data == null
                                        ? null
                                        : runObtainiumExport,
                                    child: Text(
                                      tr('obtainiumExport'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    style: outlineButtonStyle,
                                    onPressed: importInProgress
                                        ? null
                                        : runObtainiumImport,
                                    child: Text(
                                      tr('obtainiumImport'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (snapshot.data != null)
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  GeneratedForm(
                                    items: [
                                      [
                                        GeneratedFormSwitch(
                                          'autoExportOnChanges',
                                          label: tr('autoExportOnChanges'),
                                          defaultValue: behaviorSettings
                                              .autoExportOnChanges,
                                        ),
                                      ],
                                      [
                                        GeneratedFormDropdown(
                                          'exportSettings',
                                          [
                                            MapEntry('0', tr('none')),
                                            MapEntry('1', tr('excludeSecrets')),
                                            MapEntry('2', tr('all')),
                                          ],
                                          label: tr('includeSettings'),
                                          defaultValue: behaviorSettings
                                              .exportSettings
                                              .toString(),
                                        ),
                                      ],
                                    ],
                                    onValueChanges: (value, valid, isBuilding) {
                                      if (valid && !isBuilding) {
                                        if (value['autoExportOnChanges'] !=
                                            null) {
                                          behaviorSettings.autoExportOnChanges =
                                              value['autoExportOnChanges'] ==
                                              true;
                                        }
                                        if (value['exportSettings'] != null) {
                                          behaviorSettings.exportSettings =
                                              int.parse(
                                                value['exportSettings'],
                                              );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  if (importInProgress)
                    const Column(
                      children: [
                        SizedBox(height: 14),
                        ExpressiveProgressIndicator(),
                        SizedBox(height: 14),
                      ],
                    )
                  else
                    Column(
                      children: [
                        SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: importInProgress
                                    ? null
                                    : () async {
                                        var searchSourceName =
                                            await showDialog<List<String>?>(
                                              context: context,
                                              builder: (BuildContext ctx) {
                                                return SelectionModal(
                                                  title: tr(
                                                    'selectX',
                                                    args: [
                                                      tr(
                                                        'source',
                                                      ).toLowerCase(),
                                                    ],
                                                  ),
                                                  entries: sourceStrings,
                                                  selectedByDefault: false,
                                                  onlyOneSelectionAllowed: true,
                                                  titlesAreLinks: false,
                                                );
                                              },
                                            ) ??
                                            [];
                                        var searchSource = sourceProvider
                                            .sources
                                            .where(
                                              (e) => searchSourceName.contains(
                                                e.name,
                                              ),
                                            )
                                            .toList();
                                        if (searchSource.isNotEmpty) {
                                          runSourceSearch(searchSource[0]);
                                        }
                                      },
                                child: Text(
                                  tr(
                                    'searchX',
                                    args: [lowerCaseIfEnglish(tr('source'))],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: importInProgress ? null : urlListImport,
                          child: Text(tr('importFromURLList')),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: importInProgress ? null : runUrlImport,
                          child: Text(tr('importFromURLsInFile')),
                        ),
                      ],
                    ),
                  ...sourceProvider.massUrlSources.map(
                    (source) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: importInProgress
                              ? null
                              : () {
                                  runMassSourceImport(source);
                                },
                          child: Text(tr('importX', args: [source.name])),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 32),
                  Text(
                    tr('importedAppsIdDisclaimer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


