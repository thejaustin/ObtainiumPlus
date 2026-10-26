import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/backup_password_dialog.dart';
import 'package:obtainium/utils/backup_crypto.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form_renderer.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/document_tree_bridge.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/locale_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  /// Decrypts an encrypted backup: the stored password first, then asks
  /// (re-asking after a wrong one). Cancelling aborts the import.
  Future<String> _decryptBackup(String data) async {
    final stored = await BackupCrypto.storedPassword();
    if (stored != null && stored.isNotEmpty) {
      try {
        return await BackupCrypto.decrypt(data, stored);
      } on BackupPasswordError {
        // Exported with a different password; ask below.
      }
    }
    String? message;
    while (mounted) {
      final password = await showBackupPasswordDialog(
        context,
        message: message,
      );
      if (password == null) throw ObtainiumError(tr('cancelled'));
      try {
        return await BackupCrypto.decrypt(data, password);
      } on BackupPasswordError {
        message = tr('wrongBackupPassword');
      }
    }
    throw ObtainiumError(tr('cancelled'));
  }

  bool importInProgress = false;

  // Cache the export-dir future so unrelated rebuilds (e.g. from the
  // watched BehaviorSettingsProvider) don't re-trigger the async prefs read
  // and cause the FutureBuilders below to flicker back to their loading
  // state. Only recompute when the underlying stored value actually changes.
  Future<Uri?>? _exportDirFuture;
  String? _lastExportDirKey;

  Future<Uri?> _availableExportDir(
    BehaviorSettingsProvider behaviorSettings, {
    required bool hasStoredDir,
  }) async {
    var dir = await behaviorSettings.getExportDir();
    for (
      var attempt = 0;
      dir == null && hasStoredDir && attempt < 3;
      attempt++
    ) {
      await Future.delayed(const Duration(milliseconds: 400));
      dir = await behaviorSettings.getExportDir();
    }
    return dir;
  }

  @override
  Widget build(BuildContext context) {
    SourceProvider sourceProvider = SourceProvider();
    var appsProvider = context.watch<AppsProvider>();
    var behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final double adaptiveMargin = screenWidth > 840
        ? (screenWidth - 840) / 2
        : 16.0;
    final rawRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(rawRadius);
    final innerRadius = CardMetrics.inner(cardRadius);

    final exportDirKey = behaviorSettings.prefs?.safeString('exportDir');
    if (_exportDirFuture == null || exportDirKey != _lastExportDirKey) {
      _lastExportDirKey = exportDirKey;
      _exportDirFuture = _availableExportDir(
        behaviorSettings,
        hasStoredDir: exportDirKey != null,
      );
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
        if (values != null && mounted) {
          var urls = (values['appURLList'] as String)
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
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
      final bool hadDir = (await behaviorSettings.getExportDir()) != null;
      appsProvider
          .export(pickOnly: pickOnly || !hadDir, bsp: behaviorSettings)
          .then((String? result) {
            if (result != null && context.mounted) {
              showMessage(
                tr(
                  'exportedTo',
                  args: [
                    result.startsWith('content://')
                        ? readableTreeUri(Uri.parse(result))
                        : result,
                  ],
                ),
                context,
              );
            }
          })
          .catchError((e) {
            if (context.mounted) showError(e, context);
          })
          .whenComplete(() {
            if (mounted && (pickOnly || !hadDir)) {
              setState(() {
                _lastExportDirKey = null;
              });
            }
          });
    }

    Future<void> importData(String data) async {
      try {
        jsonDecode(data);
      } catch (e) {
        throw ObtainiumError(tr('invalidInput'));
      }
      final conflictCount = appsProvider
          .appIdsInImportJSON(data)
          .where((id) => appsProvider.apps.containsKey(id))
          .length;
      if (conflictCount > 0) {
        if (!context.mounted) return;
        final proceed = await showConfirmDialog(
          context,
          title: tr('importX', args: [tr('appsString').toLowerCase()]),
          content: Text(
            tr('importOverwriteWarning', args: [conflictCount.toString()]),
          ),
          confirmText: tr('continue'),
        );
        if (!proceed) return;
      }
      final value = await appsProvider.import(data);
      if (!context.mounted) return;
      appsProvider.addMissingCategories(context.read());
      showMessage(
        '${tr('importedX', args: [plural('apps', value.key.length).toLowerCase()])}${value.value ? ' + ${tr('settings').toLowerCase()}' : ''}',
        context,
      );
    }

    runObtainiumImport() {
      AppHaptics.selectionClick();
      FilePicker.pickFiles()
          .then((result) async {
            if (result.isEmpty) {
              if (!context.mounted) return;
              showMessage(tr('cancelled'), context);
              return;
            }
            if (!mounted) return;
            setState(() {
              importInProgress = true;
            });
            var path = result.first.path;
            if (path == null) {
              throw ObtainiumError(tr('noFilePickerAvailable'));
            }
            String data = await File(path).readAsString();
            if (BackupCrypto.isEncrypted(data)) {
              data = await _decryptBackup(data);
            }
            await importData(data);
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

    runDownloadsImport() async {
      AppHaptics.selectionClick();
      final List<DownloadsExport> exports;
      try {
        exports = await DocumentTreeBridge.instance.downloadsExports();
      } catch (e) {
        if (context.mounted) showError(e, context);
        return;
      }
      if (!context.mounted) return;
      if (exports.isEmpty) {
        showMessage(tr('noDownloadsExports'), context);
        return;
      }
      final chosen = await showDialog<DownloadsExport>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(tr('importFromDownloads')),
          content: SizedBox(
            width: 480,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < exports.length; i++)
                      ListTile(
                        autofocus: i == 0,
                        title: Text(exports[i].name),
                        subtitle: Text(
                          exports[i].date.toLocal().toString().split('.').first,
                        ),
                        onTap: () => Navigator.of(ctx).pop(exports[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(tr('cancel')),
            ),
          ],
        ),
      );
      if (chosen == null) return;
      if (mounted) {
        setState(() {
          importInProgress = true;
        });
      }
      try {
        final bytes = await DocumentTreeBridge.instance.readDownloadsExport(
          chosen.uri,
        );
        if (bytes == null || bytes.isEmpty) {
          throw ObtainiumError(tr('invalidInput'));
        }
        String data = utf8.decode(bytes);
        if (BackupCrypto.isEncrypted(data)) {
          data = await _decryptBackup(data);
        }
        await importData(data);
      } catch (e) {
        if (context.mounted) showError(e, context);
      } finally {
        if (mounted) {
          setState(() {
            importInProgress = false;
          });
        }
      }
    }

    runUrlImport() {
      AppHaptics.selectionClick();
      FilePicker.pickFiles()
          .then((result) async {
            if (result.isNotEmpty) {
              var path = result.first.path;
              if (path == null) return;
              var data = await File(path).readAsString();
              if (!context.mounted) return;
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
            if (!context.mounted) return;
            if (e is PlatformException || e is MissingPluginException) {
              showError(ObtainiumError(tr('noFilePickerAvailable')), context);
            } else {
              showError(e, context);
            }
          });
    }

    runSourceSearch(AppSource source) {
      AppHaptics.selectionClick();
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
              if (!mounted) return;
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
      AppHaptics.selectionClick();
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
              if (!mounted) return;
              setState(() {
                importInProgress = true;
              });
              var urlsWithDescriptions = await source.getUrlsWithDescriptions(
                source.requiredArgs
                    .map((arg) => values[arg]?.toString() ?? '')
                    .toList(),
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
    final isM3E = plusSettings.plusEnableMaterialExpressive;

    Widget _sectionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> actions,
      Color? iconColor,
    }) {
      final enableGlass = plusSettings.plusEnableGlassmorphism;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: ShapeDecoration(
          color: enableGlass
              ? colorScheme.surface.withValues(
                  alpha: AppConstants.glassSurfaceAlpha,
                )
              : colorScheme.surfaceContainerLow,
          shape: CardMetrics.shape(
            cardRadius,
            expressive: isM3E,
            side: BorderSide(
              color: enableGlass
                  ? colorScheme.onSurface.withValues(
                      alpha: AppConstants.glassBorderAlpha,
                    )
                  : colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.65,
                    ),
              width: 1.0,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConditionalBlur(
          enabled: enableGlass,
          sigma: AppConstants.glassBlurSigma,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: ShapeDecoration(
                        color: (iconColor ?? colorScheme.primary).withValues(
                          alpha: 0.14,
                        ),
                        shape: CardMetrics.shape(
                          innerRadius,
                          expressive: isM3E,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor ?? colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        key: const PageStorageKey<String>('import_export_page_scroll'),
        physics: plusSettings.scrollPhysics,
        slivers: <Widget>[
          CustomAppBar(title: tr('importExport')),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: adaptiveMargin,
              vertical: 8,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── EXPORT section ─────────────────────────────────────
                FutureBuilder<Uri?>(
                  future: _exportDirFuture,
                  builder: (context, snapshot) {
                    return _sectionCard(
                      icon: Icons.upload_rounded,
                      title: tr('obtainiumExport'),
                      subtitle: snapshot.data == null
                          ? tr('noExportDirChosen')
                          : tr(
                              'exportedTo',
                              args: [readableTreeUri(snapshot.data!)],
                            ),
                      iconColor: colorScheme.tertiary,
                      actions: [
                        ScaleTouchWrapper(
                          hapticOnPressDown: !importInProgress,
                          scaleDownFactor: 0.94,
                          child: FilledButton.icon(
                            onPressed: importInProgress
                                ? null
                                : () => runObtainiumExport(pickOnly: true),
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                            ),
                            label: Text(tr('pickExportDir')),
                          ),
                        ),
                        ScaleTouchWrapper(
                          hapticOnPressDown:
                              !importInProgress && snapshot.data != null,
                          scaleDownFactor: 0.94,
                          child: OutlinedButton.icon(
                            onPressed: importInProgress || snapshot.data == null
                                ? null
                                : runObtainiumExport,
                            icon: const Icon(Icons.save_alt_rounded, size: 18),
                            label: Text(tr('obtainiumExport')),
                          ),
                        ),
                        if (context.read<SettingsProvider>().isTV)
                          ScaleTouchWrapper(
                            hapticOnPressDown: !importInProgress,
                            scaleDownFactor: 0.94,
                            child: OutlinedButton.icon(
                              onPressed:
                                  importInProgress ||
                                      exportDirKey == kDownloadsExportDir
                                  ? null
                                  : () {
                                      AppHaptics.selectionClick();
                                      behaviorSettings.useDownloadsExportDir();
                                      setState(() {
                                        _lastExportDirKey = null;
                                      });
                                    },
                              icon: Icon(
                                exportDirKey == kDownloadsExportDir
                                    ? Icons.check_circle_rounded
                                    : Icons.download_outlined,
                                size: 18,
                              ),
                              label: Text(tr('useDownloadsFolder')),
                            ),
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
                    final enableGlass = plusSettings.plusEnableGlassmorphism;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: ShapeDecoration(
                        color: enableGlass
                            ? colorScheme.surface.withValues(
                                alpha: AppConstants.glassSurfaceAlpha,
                              )
                            : colorScheme.surfaceContainerLow,
                        shape: CardMetrics.shape(
                          cardRadius,
                          expressive: isM3E,
                          side: BorderSide(
                            color: enableGlass
                                ? colorScheme.onSurface.withValues(
                                    alpha: AppConstants.glassBorderAlpha,
                                  )
                                : colorScheme.outlineVariant.withValues(
                                    alpha:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.35
                                        : 0.65,
                                  ),
                            width: 1.0,
                          ),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ConditionalBlur(
                        enabled: enableGlass,
                        sigma: AppConstants.glassBlurSigma,
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
                    ScaleTouchWrapper(
                      hapticOnPressDown: !importInProgress,
                      scaleDownFactor: 0.94,
                      child: FilledButton.icon(
                        onPressed: importInProgress ? null : runObtainiumImport,
                        icon: const Icon(Icons.file_open_rounded, size: 18),
                        label: Text(tr('obtainiumImport')),
                      ),
                    ),
                    if (context.read<SettingsProvider>().isTV)
                      ScaleTouchWrapper(
                        hapticOnPressDown: !importInProgress,
                        scaleDownFactor: 0.94,
                        child: OutlinedButton.icon(
                          onPressed: importInProgress
                              ? null
                              : runDownloadsImport,
                          icon: const Icon(
                            Icons.folder_open_outlined,
                            size: 18,
                          ),
                          label: Text(tr('importFromDownloads')),
                        ),
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
                      ScaleTouchWrapper(
                        hapticOnPressDown: !importInProgress,
                        scaleDownFactor: 0.94,
                        child: OutlinedButton.icon(
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
                                                tr('source').toLowerCase(),
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
                                  var searchSource = sourceProvider.sources
                                      .where(
                                        (e) =>
                                            searchSourceName.contains(e.name),
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
                      ),
                      ScaleTouchWrapper(
                        hapticOnPressDown: !importInProgress,
                        scaleDownFactor: 0.94,
                        child: OutlinedButton.icon(
                          onPressed: importInProgress ? null : urlListImport,
                          icon: const Icon(Icons.list_alt_rounded, size: 18),
                          label: Text(tr('importFromURLList')),
                        ),
                      ),
                      ScaleTouchWrapper(
                        hapticOnPressDown: !importInProgress,
                        scaleDownFactor: 0.94,
                        child: OutlinedButton.icon(
                          onPressed: importInProgress ? null : runUrlImport,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(tr('importFromURLsInFile')),
                        ),
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
                        (source) => ScaleTouchWrapper(
                          hapticOnPressDown: !importInProgress,
                          scaleDownFactor: 0.94,
                          child: OutlinedButton.icon(
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
                      ),
                    ],
                  ),

                SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// "content://…/tree/primary%3ADocuments%2FObtainium" → "Documents/Obtainium".
/// Falls back to the full URI for anything it doesn't recognise.
@visibleForTesting
String readableTreeUri(Uri uri) {
  final segments = uri.pathSegments;
  // A file inside the folder ("…/tree/<folder>/document/<file>") names the
  // file itself; prefer it.
  final docIndex = segments.indexOf('document');
  final treeIndex = segments.indexOf('tree');
  final idIndex = docIndex != -1 ? docIndex : treeIndex;
  if (idIndex == -1 || idIndex + 1 >= segments.length) {
    return uri.toString();
  }
  final docId = segments[idIndex + 1];
  final colon = docId.indexOf(':');
  if (colon == -1) return docId;
  final volume = docId.substring(0, colon);
  final path = docId.substring(colon + 1);
  if (volume == 'primary') return path.isEmpty ? '/' : path;
  return path.isEmpty ? volume : '$volume/$path';
}
