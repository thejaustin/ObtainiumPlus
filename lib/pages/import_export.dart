import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form_renderer.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:obtainium/components/ui_widgets.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool importInProgress = false;

  // Cache the export-dir future so unrelated rebuilds (e.g. from the
  // watched BehaviorSettingsProvider) don't re-trigger the async prefs read
  // and cause the FutureBuilders below to flicker back to their loading
  // state. Only recompute when the underlying stored value actually changes.
  Future<Uri?>? _exportDirFuture;
  String? _lastExportDirKey;

  @override
  Widget build(BuildContext context) {
    SourceProvider sourceProvider = SourceProvider();
    var appsProvider = context.watch<AppsProvider>();
    var behaviorSettings = context.watch<BehaviorSettingsProvider>();

    final exportDirKey = behaviorSettings.prefs?.getString('exportDir');
    if (_exportDirFuture == null || exportDirKey != _lastExportDirKey) {
      _lastExportDirKey = exportDirKey;
      _exportDirFuture = behaviorSettings.getExportDir();
    }

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
                  value: initValue ?? '',
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
                if (!context.mounted) return;
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
                if (context.mounted) showError(e, context);
              })
              .whenComplete(() {
                if (!mounted) return;
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
            if (result != null && context.mounted) {
              showMessage(tr('exportedTo', args: [result]), context);
            }
          })
          .catchError((e) {
            if (context.mounted) showError(e, context);
          });
    }

    runObtainiumImport() {
      AppHaptics.selectionClick();
      FilePicker.pickFiles()
          .then((result) async {
            if (result == null) {
              if (!context.mounted) return;
              showMessage(tr('cancelled'), context);
              return;
            }
            if (result.files.isEmpty) {
              return;
            }
            setState(() {
              importInProgress = true;
            });
            var path = result.files.single.path;
            if (path == null) {
              throw ObtainiumError(tr('noFilePickerAvailable'));
            }
            String data = await File(path).readAsString();
            try {
              jsonDecode(data);
            } catch (e) {
              throw ObtainiumError(tr('invalidInput'));
            }
            appsProvider.import(data).then((value) {
              if (!context.mounted) return;
              appsProvider.addMissingCategories(context.read());
              showMessage(
                '${tr('importedX', args: [plural('apps', value.key.length).toLowerCase()])}${value.value ? ' + ${tr('settings').toLowerCase()}' : ''}',
                context,
              );
            });
          })
          .catchError((e) {
            if (context.mounted) {
              if (e is PlatformException || e is MissingPluginException) {
                showError(ObtainiumError(tr('noFilePickerAvailable')), context);
              } else {
                showError(e, context);
              }
            }
          })
          .whenComplete(() {
            if (!mounted) return;
            setState(() {
              importInProgress = false;
            });
          });
    }

    runUrlImport() {
      FilePicker.pickFiles()
          .then((result) async {
            if (result != null) {
              var path = result.files.single.path;
              if (path == null) return;
              var data = await File(path).readAsString();
              urlListImport(
                overrideInitValid: true,
                initValue: RegExp(r'https?://[^\s"]+')
                    .allMatches(data)
                    .map((e) => e.input.substring(e.start, e.end))
                    .toSet()
                    .toList()
                    .where((url) {
                      try {
                        sourceProvider.getSource(url);
                        return true;
                      } catch (e) {
                        unawaited(
                          LogsProvider().add(
                            'URL parse error in filter: $e',
                            level: LogLevel.error,
                          ),
                        );
                        return false;
                      }
                    })
                    .join('\n'),
              );
            }
          })
          .catchError((e) {
            if (e is PlatformException || e is MissingPluginException) {
              showError(ObtainiumError(tr('noFilePickerAvailable')), context);
            } else {
              showError(e, context);
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
                            : tr('urlLabel'),
                        value: source.hosts.isNotEmpty ? source.hosts[0] : '',
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
                if (!context.mounted) return;
                var selectedUrls = await showDialog<List<String>?>(
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
                  if (!context.mounted) return;
                  if (errors.isEmpty) {
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
            if (context.mounted) showError(e, context);
          })
          .whenComplete(() {
            if (!mounted) return;
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
              if (!context.mounted) return;
              var selectedUrls = await showDialog<List<String>?>(
                context: context,
                builder: (BuildContext ctx) {
                  return SelectionModal(entries: urlsWithDescriptions);
                },
              );
              if (selectedUrls != null) {
                var errors = await appsProvider.addAppsByURL(selectedUrls);
                if (!context.mounted) return;
                if (errors.isEmpty) {
                  showMessage(
                    tr(
                      'importedX',
                      args: [plural('apps', selectedUrls.length).toLowerCase()],
                    ),
                    context,
                  );
                } else {
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
            if (context.mounted) showError(e, context);
          })
          .whenComplete(() {
            if (!mounted) return;
            setState(() {
              importInProgress = false;
            });
          });
    }

    var sourceStrings = <String, List<String>>{};
    sourceProvider.sources.where((e) => e.canSearch).forEach((s) {
      sourceStrings[s.name] = [s.name];
    });

    final colorScheme = Theme.of(context).colorScheme;

    Widget _sectionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> actions,
      Color? iconColor,
    }) {
      return Card.filled(
        color: colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (iconColor ?? colorScheme.primary).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: <Widget>[
          CustomAppBar(title: tr('importExport')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── EXPORT section ─────────────────────────────────────
                FutureBuilder<Uri?>(
                  future: _exportDirFuture,
                  builder: (context, snapshot) {
                    return _sectionCard(
                      icon: Icons.upload_rounded,
                      title: tr('obtainiumExport'),
                      subtitle: tr(
                        'exportedTo',
                        args: [
                          snapshot.data?.toString() ?? tr('pickExportDir'),
                        ],
                      ),
                      iconColor: colorScheme.tertiary,
                      actions: [
                        FilledButton.icon(
                          onPressed: importInProgress
                              ? null
                              : () => runObtainiumExport(pickOnly: true),
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: Text(tr('pickExportDir')),
                        ),
                        OutlinedButton.icon(
                          onPressed: importInProgress || snapshot.data == null
                              ? null
                              : runObtainiumExport,
                          icon: const Icon(Icons.save_alt_rounded, size: 18),
                          label: Text(tr('obtainiumExport')),
                        ),
                      ],
                    );
                  },
                ),

                // Auto-export settings (shown only when export dir is set)
                FutureBuilder(
                  future: _exportDirFuture,
                  builder: (context, snapshot) {
                    if (snapshot.data == null) return const SizedBox.shrink();
                    return Card.outlined(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: GeneratedForm(
                          items: [
                            [
                              GeneratedFormSwitch(
                                'autoExportOnChanges',
                                label: tr('autoExportOnChanges'),
                                value: behaviorSettings.autoExportOnChanges,
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
                                value: behaviorSettings.exportSettings
                                    .toString(),
                              ),
                            ],
                          ],
                          onValueChanges: (value, valid, isBuilding) {
                            if (valid && !isBuilding) {
                              if (value['autoExportOnChanges'] != null) {
                                behaviorSettings.autoExportOnChanges =
                                    value['autoExportOnChanges'] == true;
                              }
                              if (value['exportSettings'] != null) {
                                behaviorSettings.exportSettings = int.parse(
                                  value['exportSettings'],
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),

                // ── IMPORT section ──────────────────────────────────────
                _sectionCard(
                  icon: Icons.download_rounded,
                  title: tr('obtainiumImport'),
                  subtitle: tr('importedAppsIdDisclaimer'),
                  iconColor: colorScheme.primary,
                  actions: [
                    FilledButton.icon(
                      onPressed: importInProgress ? null : runObtainiumImport,
                      icon: const Icon(Icons.file_open_rounded, size: 18),
                      label: Text(tr('obtainiumImport')),
                    ),
                  ],
                ),

                // ── Progress indicator ──────────────────────────────────
                if (importInProgress)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ExpressiveProgressIndicator(),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),

                // ── SOURCE IMPORT section ───────────────────────────────
                if (!importInProgress)
                  _sectionCard(
                    icon: Icons.manage_search_rounded,
                    title: tr(
                      'searchX',
                      args: [lowerCaseIfEnglish(tr('source'))],
                    ),
                    subtitle: tr('importFromURLList'),
                    iconColor: colorScheme.secondary,
                    actions: [
                      OutlinedButton.icon(
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
                                            args: [tr('source').toLowerCase()],
                                          ),
                                          entries: sourceStrings,
                                          selectedByDefault: false,
                                          onlyOneSelectionAllowed: true,
                                          titlesAreLinks: false,
                                        );
                                      },
                                    ) ??
                                    [];
                                var searchSource = sourceProvider.sources
                                    .where(
                                      (e) => searchSourceName.contains(e.name),
                                    )
                                    .toList();
                                if (searchSource.isNotEmpty) {
                                  runSourceSearch(searchSource[0]);
                                }
                              },
                        icon: const Icon(Icons.source_rounded, size: 18),
                        label: Text(
                          tr(
                            'searchX',
                            args: [lowerCaseIfEnglish(tr('source'))],
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: importInProgress ? null : urlListImport,
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: Text(tr('importFromURLList')),
                      ),
                      OutlinedButton.icon(
                        onPressed: importInProgress ? null : runUrlImport,
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(tr('importFromURLsInFile')),
                      ),
                    ],
                  ),

                // ── MASS SOURCE IMPORTS ─────────────────────────────────
                if (!importInProgress &&
                    sourceProvider.massUrlSources.isNotEmpty)
                  _sectionCard(
                    icon: Icons.cloud_download_rounded,
                    title: tr('importX', args: ['…']),
                    subtitle: '',
                    iconColor: colorScheme.error,
                    actions: [
                      ...sourceProvider.massUrlSources.map(
                        (source) => OutlinedButton.icon(
                          onPressed: importInProgress
                              ? null
                              : () => runMassSourceImport(source),
                          icon: const Icon(
                            Icons.download_for_offline_rounded,
                            size: 18,
                          ),
                          label: Text(tr('importX', args: [source.name])),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
