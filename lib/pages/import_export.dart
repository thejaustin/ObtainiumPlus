<<<<<<< HEAD
import 'package:obtainium/utils/haptic_utils.dart';
=======
>>>>>>> upstream/main
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
<<<<<<< HEAD
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
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart'
    hide isEnglish, lowerCaseIfEnglish;
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/mass_app_sources/githubstars.dart';
import 'package:obtainium/mass_app_sources/githubpersonalrepos.dart';
=======
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
>>>>>>> upstream/main

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool importInProgress = false;
<<<<<<< HEAD
  // PERFORMANCE: Cache SourceProvider to avoid recreating 24 source objects on every build
  late final SourceProvider _sourceProvider = SourceProvider();

  @override
  Widget build(BuildContext context) {
    final sourceProvider = _sourceProvider;
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
    var plusSettings = context.watch<PlusSettingsProvider>();
    var behaviorSettings = context.watch<BehaviorSettingsProvider>();
=======

  @override
  Widget build(BuildContext context) {
    SourceProvider sourceProvider = SourceProvider();
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
>>>>>>> upstream/main

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

<<<<<<< HEAD
    Future<String?> _promptForPassword() async {
      final TextEditingController passwordController = TextEditingController();
      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('enterBackupPassword')),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: tr('password'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: Text(tr('ok')),
            ),
          ],
        ),
      );
    }

=======
>>>>>>> upstream/main
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
<<<<<<< HEAD
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
                onError: (e) {
                  showError(e, context);
                },
              )
              .whenComplete(() {
                if (mounted)
                  setState(() {
                    importInProgress = false;
                  });
=======
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
>>>>>>> upstream/main
              });
        }
      });
    }

    runObtainiumExport({bool pickOnly = false}) async {
<<<<<<< HEAD
      AppHaptics.selectionClick();
      try {
        String? password;
        if (plusSettings.backupEncryptionEnabled && !pickOnly) {
          password = await _promptForPassword();
          if (password == null || password.isEmpty) return;
        }

        final result = await appsProvider.export(
          pickOnly: pickOnly || (await behaviorSettings.getExportDir()) == null,
          sp: settingsProvider,
          password: password,
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
        String? password;
        if (plusSettings.backupEncryptionEnabled) {
          password = await _promptForPassword();
          if (password == null || password.isEmpty) {
            setState(() => importInProgress = false);
            return;
          }
        }

        final bytes = await AppExportService.getExportBytes(
          apps: appsProvider.apps,
          settingsProvider: settingsProvider,
          password: password,
        );

        final tempDir = await getTemporaryDirectory();
        final fileName =
            'Obtainium_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([
          XFile(file.path, name: fileName, mimeType: 'application/json'),
        ], subject: fileName);
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

        if (result == null ||
            result.files.isEmpty ||
            result.files.first.path == null) {
          // User cancelled
          return;
        }
        if (!mounted) return;

        setState(() {
          importInProgress = true;
        });

        // Read file asynchronously
        final file = File(result.files.first.path!);
        String data = await file.readAsString();

        // Check if encrypted
        try {
          final decodedData = jsonDecode(data);
          if (decodedData is Map && decodedData['encrypted'] == true) {
            String? password = await _promptForPassword();
            if (password == null || password.isEmpty) {
              setState(() => importInProgress = false);
              return;
            }
            data = await AppExportService.decryptBackup(data, password);
          }
        } catch (e) {
          if (e is ObtainiumError) rethrow;
          // Not JSON or other error, fallback to standard import which handles invalid input
        }

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

        if (result == null ||
            result.files.isEmpty ||
            result.files.first.path == null) {
          // User cancelled
          return;
        }
        if (!mounted) return;

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
        final validUrls = urls
            .where((url) {
              try {
                sourceProvider.getSource(url);
                return true;
              } catch (e) {
                return false;
              }
            })
            .join('\n');

        if (mounted) {
          urlListImport(overrideInitValid: true, initValue: validUrls);
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
=======
      HapticFeedback.selectionClick();
      appsProvider
          .export(
            pickOnly:
                pickOnly || (await settingsProvider.getExportDir()) == null,
            sp: settingsProvider,
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
      HapticFeedback.selectionClick();
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
                var cats = settingsProvider.categories;
                appsProvider.apps.forEach((key, value) {
                  for (var c in value.app.categories) {
                    if (!cats.containsKey(c)) {
                      cats[c] = generateRandomLightColor().value;
                    }
                  }
                });
                appsProvider.addMissingCategories(settingsProvider);
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
>>>>>>> upstream/main
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
<<<<<<< HEAD
            if (mounted) showError(e, context);
          })
          .whenComplete(() {
            if (mounted)
              setState(() {
                importInProgress = false;
              });
=======
            showError(e, context);
          })
          .whenComplete(() {
            setState(() {
              importInProgress = false;
            });
>>>>>>> upstream/main
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
<<<<<<< HEAD
            if (values != null && mounted) {
=======
            if (values != null) {
>>>>>>> upstream/main
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
<<<<<<< HEAD
            if (mounted)
              setState(() {
                importInProgress = false;
              });
=======
            setState(() {
              importInProgress = false;
            });
>>>>>>> upstream/main
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
<<<<<<< HEAD
                  _sectionHeader(context, tr('exportAndImport')),
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
                            runMassSourceImport(
                              sourceProvider.massUrlSources.firstWhere(
                                (s) =>
                                    s.runtimeType == GitHubStars().runtimeType,
                                orElse: () => GitHubStars(),
                              ),
                            );
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
                            runMassSourceImport(
                              sourceProvider.massUrlSources.firstWhere(
                                (s) =>
                                    s.runtimeType ==
                                    GitHubPersonalRepos().runtimeType,
                                orElse: () => GitHubPersonalRepos(),
                              ),
                            );
                          },
                    child: Text(
                      tr('importX', args: [tr('githubPersonalRepos')]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _sectionHeader(context, tr('importApps')),
=======
                  if (!settingsProvider.isTV)
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
>>>>>>> upstream/main
                  if (importInProgress)
                    const Column(
                      children: [
                        SizedBox(height: 14),
<<<<<<< HEAD
                        const ExpressiveProgressIndicator(),
=======
                        LinearProgressIndicator(),
>>>>>>> upstream/main
                        SizedBox(height: 14),
                      ],
                    )
                  else
                    Column(
                      children: [
<<<<<<< HEAD
                        const SizedBox(height: 32),
=======
                        SizedBox(height: 32),
>>>>>>> upstream/main
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
<<<<<<< HEAD
                        TextButton(
                          onPressed: importInProgress ? null : runUrlImport,
                          child: Text(tr('importFromURLsInFile')),
                        ),
                      ],
                    ),
=======
                        if (!settingsProvider.isTV)
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
>>>>>>> upstream/main
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
<<<<<<< HEAD

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
=======
}

class ImportErrorDialog extends StatefulWidget {
  const ImportErrorDialog({
    super.key,
    required this.urlsLength,
    required this.errors,
  });

  final int urlsLength;
  final List<List<String>> errors;

  @override
  State<ImportErrorDialog> createState() => _ImportErrorDialogState();
}

class _ImportErrorDialogState extends State<ImportErrorDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(tr('importErrors')),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(
              'importedXOfYApps',
              args: [
                (widget.urlsLength - widget.errors.length).toString(),
                widget.urlsLength.toString(),
              ],
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            tr('followingURLsHadErrors'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          ...widget.errors.map((e) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(e[0]),
                Text(e[1], style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('ok')),
        ),
      ],
    );
  }
}

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
    final isTV = context.read<SettingsProvider>().isTV;
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
                      return regExValidator(value);
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

            var urlLink = InkWell(
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
              title: InkWell(
                onTap: widget.titlesAreLinks
                    ? null
                    : () {
                        selectThis(!(entrySelections[entry] ?? false));
                      },
                child: urlLink,
              ),
              subtitle: entry.value.length <= 1
                  ? null
                  : InkWell(
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
                  if (isTV) {
                    Navigator.of(context).pop([entry.key]);
                  } else {
                    setState(() {
                      selectOnlyOne(entry.key);
                    });
                  }
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
                      InkWell(
                        onTap: widget.titlesAreLinks
                            ? null
                            : () {
                                selectThis(!(entrySelections[entry] ?? false));
                              },
                        child: urlLink,
                      ),
                      entry.value.length <= 1
                          ? const SizedBox.shrink()
                          : InkWell(
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
          if (isTV && !widget.onlyOneSelectionAllowed) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('cancel')),
                ),
                TextButton(
                  onPressed: entrySelections.values.where((b) => b).isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                          entrySelections.entries
                              .where((entry) => entry.value)
                              .map((e) => e.key.key)
                              .toList(),
                        ),
                  child: Text(
                    tr(
                      'selectX',
                      args: [
                        entrySelections.values
                            .where((b) => b)
                            .length
                            .toString(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        getSelectAllButton(),
        TextButton(
          autofocus: isTV,
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
>>>>>>> upstream/main
    );
  }
}
