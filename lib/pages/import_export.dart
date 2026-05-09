import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart' hide isEnglish, lowerCaseIfEnglish;
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/mass_app_sources/githubstars.dart';
import 'package:obtainium/mass_app_sources/githubpersonalrepos.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool importInProgress = false;
  // PERFORMANCE: Cache SourceProvider to avoid recreating 24 source objects on every build
  late final SourceProvider _sourceProvider = SourceProvider();

  @override
  Widget build(BuildContext context) {
    final sourceProvider = _sourceProvider;
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();

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
              .then(
                (errors) {
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
                },
                onError: (e) { showError(e, context); },
              )
              .whenComplete(() {
                if (mounted) setState(() { importInProgress = false; });
              });
        }
      });
    }

    runObtainiumExport({bool pickOnly = false}) async {
      AppHaptics.selectionClick();
      try {
        final result = await appsProvider.export(
          pickOnly:
              pickOnly || (await settingsProvider.getExportDir()) == null,
          sp: settingsProvider,
        );
        if (result != null) {
          showMessage(tr('exportedTo', args: [result]), context);
        }
      } catch (e) {
        if (e is! PlatformException || e.toString().contains('No activity')) {
          showError(e, context);
        }
      }
    }

    shareBackup() async {
      AppHaptics.selectionClick();
      setState(() => importInProgress = true);
      try {
        final exportData = AppExportService.generateExportJSON(
          apps: appsProvider.apps,
          settingsProvider: settingsProvider,
        );
        final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
        final tempDir = await getTemporaryDirectory();
        final fileName = 'Obtainium_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonStr);
        
        await Share.shareXFiles(
          [XFile(file.path, name: fileName, mimeType: 'application/json')],
          subject: fileName,
        );
      } catch (e) {
        if (mounted) showError(e, context);
      } finally {
        if (mounted) setState(() => importInProgress = false);
      }
    }

    runObtainiumImport() async {
      AppHaptics.selectionClick();
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty || result.files.first.path == null) {
          // User cancelled
          return;
        }

        setState(() {
          importInProgress = true;
        });

        // Read file asynchronously
        final file = File(result.files.first.path!);
        final data = await file.readAsString();

        // Decode JSON in a background isolate if it's large
        try {
          await foundation.compute(jsonDecode, data);
        } catch (e) {
          throw ObtainiumError(tr('invalidInput'));
        }

        final value = await appsProvider.import(data);
        var cats = settingsProvider.categories;
        for (var entry in value.key) {
          for (var c in entry.categories) {
            if (!cats.containsKey(c)) {
              cats[c] = generateRandomLightColor().value;
            }
          }
        }
        appsProvider.addMissingCategories(settingsProvider);
        if (mounted) {
          showMessage(
            '${tr('importedX', args: [plural('apps', value.key.length).toLowerCase()])}${value.value ? ' + ${tr('settings').toLowerCase()}' : ''}',
            context,
          );
        }
      } catch (e) {
        if (e is! PlatformException || e.toString().contains('No activity')) {
          if (mounted) showError(e, context);
        }
        // Silently ignore PlatformException for "No activity" - user cancelled
      } finally {
        if (mounted) {
          setState(() {
            importInProgress = false;
          });
        }
      }
    }

    runUrlImport() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json', 'txt', 'html'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty || result.files.first.path == null) {
          // User cancelled
          return;
        }

        setState(() {
          importInProgress = true;
        });

        final file = File(result.files.first.path!);
        final content = await file.readAsString();

        // Process URLs in background to avoid freezing UI if file is huge
        final urls = await foundation.compute((String text) {
          return RegExp('https?://[^"]+')
              .allMatches(text)
              .map((e) => e.input.substring(e.start, e.end))
              .toSet()
              .toList();
        }, content);

        // Filter valid sources - this might also be heavy
        final validUrls = urls.where((url) {
          try {
            sourceProvider.getSource(url);
            return true;
          } catch (e) {
            return false;
          }
        }).join('\n');

        if (mounted) {
          urlListImport(
            overrideInitValid: true,
            initValue: validUrls,
          );
        }
      } catch (e) {
        if (e is! PlatformException || e.toString().contains('No activity')) {
          if (mounted) showError(e, context);
        }
      } finally {
        if (mounted) {
          setState(() {
            importInProgress = false;
          });
        }
      }
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
            if (mounted) showError(e, context);
          })
          .whenComplete(() {
            if (mounted) setState(() { importInProgress = false; });
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
            if (mounted) setState(() { importInProgress = false; });
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
                  _sectionHeader(context, tr('exportAndImport')),
                  FutureBuilder(
                    future: settingsProvider.getExportDir(),
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
                                      importInProgress || snapshot.data == null
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextButton(
                                  style: outlineButtonStyle,
                                  onPressed: importInProgress
                                      ? null
                                      : shareBackup,
                                  child: Text(
                                    tr('shareBackup'),
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
                                        defaultValue: settingsProvider
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
                                        defaultValue: settingsProvider
                                            .exportSettings
                                            .toString(),
                                      ),
                                    ],
                                  ],
                                  onValueChanges: (value, valid, isBuilding) {
                                    if (valid && !isBuilding) {
                                      if (value['autoExportOnChanges'] !=
                                          null) {
                                        settingsProvider.autoExportOnChanges =
                                            value['autoExportOnChanges'] ==
                                            true;
                                      }
                                      if (value['exportSettings'] != null) {
                                        settingsProvider.exportSettings =
                                            int.parse(value['exportSettings']);
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
                  const SizedBox(height: 8),
                  _sectionHeader(context, tr('githubIntegration')),
                  Text(
                    tr('githubStarredRepos'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: importInProgress
                        ? null
                        : () {
                              runMassSourceImport(sourceProvider.massUrlSources.firstWhere((s) => s.runtimeType == GitHubStars().runtimeType));
                          },
                    child: Text(tr('importGithubStarredRepos')),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('githubPersonalRepos'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: importInProgress
                        ? null
                        : () {
                              runMassSourceImport(sourceProvider.massUrlSources.firstWhere((s) => s.runtimeType == GitHubPersonalRepos().runtimeType));
                          },
                    child: Text(tr('importX', args: [tr('githubPersonalRepos')])),
                  ),
                  const SizedBox(height: 8),
                  _sectionHeader(context, tr('importApps')),
                  if (importInProgress)
                    const Column(
                      children: [
                        SizedBox(height: 14),
                        const ExpressiveProgressIndicator(),
                        SizedBox(height: 14),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const SizedBox(height: 32),
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

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
