import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/unsupported_source_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/discover.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum AddAppMode { add, edit }

class AddAppPage extends StatefulWidget {
  final AddAppMode mode;
  final String? appId;
  final String? initialUrl;
  final int? initialTab;
  const AddAppPage({super.key, this.mode = AddAppMode.add, this.appId, this.initialUrl, this.initialTab});

  @override
  State<AddAppPage> createState() => AddAppPageState();
}

class AddAppPageState extends State<AddAppPage> {
  final TextEditingController _inputController = TextEditingController();
  bool gettingAppInfo = false;

  String userInput = '';
  String? pickedSourceOverride;
  String? previousPickedSourceOverride;
  AppSource? pickedSource;
  Map<String, dynamic> additionalSettings = {};
  bool additionalSettingsValid = true;
  bool inferAppIdIfOptional = true;
  List<String> pickedCategories = [];
  String? _urlValidationError;
  SourceProvider sourceProvider = SourceProvider();
  final GlobalKey<DiscoverPageState> _discoverPageKey = GlobalKey<DiscoverPageState>();
  Timer? _discoverSearchDebounce;

  bool get _isUrlMode => userInput.trim().startsWith('http');

  bool get _canAddUrl =>
      _isUrlMode &&
      pickedSource != null &&
      _urlValidationError == null &&
      !(pickedSource!.combinedAppSpecificSettingFormItems.isNotEmpty &&
          !additionalSettingsValid) &&
      !gettingAppInfo;

  @override
  void initState() {
    super.initState();
    if (widget.appId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var app = context.read<AppsProvider>().apps[widget.appId]?.app;
        if (app != null) {
          _changeUserInput(app.url, true, false, updateUrlInput: true);
        }
      });
    } else if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changeUserInput(widget.initialUrl!, true, false, updateUrlInput: true);
      });
    }
  }

  @override
  void dispose() {
    _discoverSearchDebounce?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void linkFn(String input) {
    try {
      if (input.isEmpty) {
        throw UnsupportedURLError();
      }
      sourceProvider.getSource(input);
      _changeUserInput(input, true, false, updateUrlInput: true);
    } catch (e) {
      // If it's an unsupported URL, show helpful dialog with suggestions
      if (e is UnsupportedURLError) {
        // Get list of supported sources for the dialog
        final supportedSources = sourceProvider.sources
            .where((s) => s.hosts.isNotEmpty)
            .map((s) => s.name)
            .toList();
        
        showUnsupportedSourceDialog(
          context: context,
          suggestedSources: supportedSources.take(8).toList(),
          failedUrl: input, // Pass the failed URL for debugging
        );
      } else {
        showError(e, context);
      }
    }
  }

  void _changeUserInput(
    String input,
    bool valid,
    bool isBuilding, {
    bool updateUrlInput = false,
    String? overrideSource,
  }) {
    userInput = input;
    if (!isBuilding) {
      setState(() {
        if (overrideSource != null) {
          pickedSourceOverride = overrideSource;
        }
        bool overrideChanged =
            pickedSourceOverride != previousPickedSourceOverride;
        previousPickedSourceOverride = pickedSourceOverride;
        if (updateUrlInput && _inputController.text != input) {
          _inputController.text = input;
          _inputController.selection =
              TextSelection.collapsed(offset: input.length);
        }
        var prevHost = pickedSource?.hosts.isNotEmpty == true
            ? pickedSource?.hosts[0]
            : null;
        AppSource? source;
        _urlValidationError = null;
        if (valid) {
          try {
            source = sourceProvider.getSource(
              userInput,
              overrideSource: pickedSourceOverride,
            );
          } catch (_) {}
          // Validate URL format for http inputs
          if (source != null && input.trim().startsWith('http')) {
            try {
              source.standardizeUrl(input);
            } catch (e) {
              _urlValidationError = e is ObtainiumError
                  ? e.toString()
                  : e is String
                      ? e
                      : tr('error');
            }
          }
        }
        if (pickedSource.runtimeType != source.runtimeType ||
            overrideChanged ||
            (prevHost != null && prevHost != source?.hosts[0])) {
          pickedSource = source;
          pickedSource?.runOnAddAppInputChange(userInput);
          additionalSettings = source != null
              ? getDefaultValuesFromFormItems(
                  source.combinedAppSpecificSettingFormItems,
                )
              : {};
          additionalSettingsValid = source != null
              ? !sourceProvider.ifRequiredAppSpecificSettingsExist(source)
              : true;
          inferAppIdIfOptional = true;
        }
      });
    }
  }

  Future<bool> _getTrackOnlyConfirmationIfNeeded(
    bool userPickedTrackOnly, {
    bool ignoreHideSetting = false,
  }) async {
    var useTrackOnly =
        userPickedTrackOnly || (pickedSource?.enforceTrackOnly ?? false);
    if (useTrackOnly &&
        (!context.read<SettingsProvider>().hideTrackOnlyWarning ||
            ignoreHideSetting)) {
      var values = await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return GeneratedFormModal(
            initValid: true,
            title: tr(
              'xIsTrackOnly',
              args: [
                pickedSource!.enforceTrackOnly ? tr('source') : tr('app'),
              ],
            ),
            items: [
              [GeneratedFormSwitch('hide', label: tr('dontShowAgain'))],
            ],
            message:
                '${pickedSource!.enforceTrackOnly ? tr('appsFromSourceAreTrackOnly') : tr('youPickedTrackOnly')}\n\n${tr('trackOnlyAppDescription')}',
          );
        },
      );
      if (values != null) {
        context.read<SettingsProvider>().hideTrackOnlyWarning =
            values['hide'] == true;
      }
      return useTrackOnly && values != null;
    } else {
      return true;
    }
  }

  Future<bool> _getReleaseDateAsVersionConfirmationIfNeeded(
    bool userPickedTrackOnly,
  ) async {
    return (!(additionalSettings['releaseDateAsVersion'] == true &&
        await showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: tr('releaseDateAsVersion'),
                  items: const [],
                  message: tr('releaseDateAsVersionExplanation'),
                );
              },
            ) ==
            null));
  }

  _addApp() async {
    setState(() {
      gettingAppInfo = true;
    });
    try {
      var appsProvider = context.read<AppsProvider>();
      var userPickedTrackOnly = additionalSettings['trackOnly'] == true;
      // Capture pickedSource locally before awaits to avoid TOCTOU race condition
      final source = pickedSource;
      if (source == null) return;
      App? app;
      if ((await _getTrackOnlyConfirmationIfNeeded(userPickedTrackOnly)) &&
          (await _getReleaseDateAsVersionConfirmationIfNeeded(
            userPickedTrackOnly,
          ))) {
        var trackOnly = source.enforceTrackOnly || userPickedTrackOnly;
        app = await sourceProvider.getApp(
          source,
          userInput.trim(),
          additionalSettings,
          trackOnlyOverride: trackOnly,
          sourceIsOverriden: pickedSourceOverride != null,
          inferAppIdIfOptional: inferAppIdIfOptional,
        );
        if (SourceUtils.isTempId(app) &&
            app.additionalSettings['trackOnly'] != true) {
          var apkUrl = await appsProvider.confirmAppFileUrl(
            app,
            context,
            false,
          );
          if (apkUrl == null) {
            throw ObtainiumError(tr('cancelled'));
          }
          app.preferredApkIndex = app.apkUrls
              .map((e) => e.value)
              .toList()
              .indexOf(apkUrl.value);
          var downloadedArtifact = await appsProvider.downloadApp(
            app,
            globalNavigatorKey.currentContext,
            notificationsProvider: context.read<NotificationsProvider>(),
          );
          DownloadedApk? downloadedFile;
          DownloadedDir? downloadedDir;
          if (downloadedArtifact is DownloadedApk) {
            downloadedFile = downloadedArtifact;
          } else {
            downloadedDir = downloadedArtifact as DownloadedDir;
          }
          app.id = downloadedFile?.appId ?? downloadedDir!.appId;
        }
        if (appsProvider.apps.containsKey(app.id)) {
          throw ObtainiumError(tr('appAlreadyAdded'));
        }
        if (app.additionalSettings['trackOnly'] == true ||
            app.additionalSettings['versionDetection'] != true) {
          app.installedVersion = app.latestVersion;
        }
        app.categories = pickedCategories;
        await appsProvider.saveApps([app], onlyIfExists: false);
      }
      if (app != null && mounted) {
        showModalBottomSheet(
          context: globalNavigatorKey.currentContext ?? context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => AppPage(
            appId: app!.id,
            isModal: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(e, context);
    } finally {
      if (mounted) {
        setState(() {
          gettingAppInfo = false;
        });
      }
    }
  }

  Widget _getHTMLSourceOverrideDropdown() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GeneratedForm(
                items: [
                  [
                    GeneratedFormDropdown(
                      'overrideSource',
                      defaultValue: pickedSourceOverride ?? '',
                      [
                        MapEntry('', tr('none')),
                        ...sourceProvider.sources
                            .where(
                              (s) =>
                                  s.allowOverride ||
                                  (pickedSource != null &&
                                      pickedSource.runtimeType ==
                                          s.runtimeType),
                            )
                            .map(
                              (s) => MapEntry(s.runtimeType.toString(), s.name),
                            ),
                      ],
                      label: tr('overrideSource'),
                    ),
                  ],
                ],
                onValueChanges: (values, valid, isBuilding) {
                  void fn() {
                    pickedSourceOverride =
                        (values['overrideSource'] == null ||
                                values['overrideSource'] == '')
                            ? null
                            : values['overrideSource'];
                  }

                  if (!isBuilding) {
                    setState(() {
                      fn();
                    });
                  } else {
                    fn();
                  }
                  _changeUserInput(userInput, valid, isBuilding);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _getAdditionalOptsCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          tr('additionalOptsFor', args: [pickedSource?.name ?? tr('source')]),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GeneratedForm(
          key: Key(
            '${pickedSource.runtimeType.toString()}-${pickedSource?.hostChanged.toString()}-${pickedSource?.hostIdenticalDespiteAnyChange.toString()}',
          ),
          items: [
            ...pickedSource!.combinedAppSpecificSettingFormItems,
            ...(pickedSourceOverride != null
                ? pickedSource!.sourceConfigSettingFormItems.map((e) => [e])
                : []),
          ],
          onValueChanges: (values, valid, isBuilding) {
            if (!isBuilding) {
              setState(() {
                additionalSettings = values;
                additionalSettingsValid = valid;
              });
            }
          },
        ),
        Column(
          children: [
            const SizedBox(height: 16),
            CategoryEditorSelector(
              alignment: WrapAlignment.start,
              onSelected: (categories) {
                pickedCategories = categories;
              },
            ),
          ],
        ),
        if (pickedSource != null && pickedSource!.appIdInferIsOptional)
          GeneratedForm(
            key: const Key('inferAppIdIfOptional'),
            items: [
              [
                GeneratedFormSwitch(
                  'inferAppIdIfOptional',
                  label: tr('tryInferAppIdFromCode'),
                  defaultValue: inferAppIdIfOptional,
                ),
              ],
            ],
            onValueChanges: (values, valid, isBuilding) {
              if (!isBuilding) {
                setState(() {
                  inferAppIdIfOptional = values['inferAppIdIfOptional'];
                });
              }
            },
          ),
        if (pickedSource != null && pickedSource!.enforceTrackOnly)
          GeneratedForm(
            key: Key(
              '${pickedSource.runtimeType.toString()}-${pickedSource?.hostChanged.toString()}-${pickedSource?.hostIdenticalDespiteAnyChange.toString()}-appId',
            ),
            items: [
              [
                GeneratedFormTextField(
                  'appId',
                  label: '${tr('appId')} - ${tr('custom')}',
                  required: false,
                  additionalValidators: [
                    (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      final isValid = RegExp(
                        r'^([A-Za-z]{1}[A-Za-z\d_]*\.)+[A-Za-z][A-Za-z\d_]*$',
                      ).hasMatch(value);
                      if (!isValid) {
                        return tr('invalidInput');
                      }
                      return null;
                    },
                  ],
                ),
              ],
            ],
            onValueChanges: (values, valid, isBuilding) {
              if (!isBuilding) {
                setState(() {
                  additionalSettings['appId'] = values['appId'];
                });
              }
            },
          ),
      ],
    );
  }

  Widget _getSourcesListWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return GeneratedFormModal(
                    singleNullReturnButton: tr('ok'),
                    title: tr('supportedSources'),
                    items: const [],
                    additionalWidgets: [
                      ...sourceProvider.sources.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: GestureDetector(
                            onTap: e.hosts.isNotEmpty
                                ? () {
                                    launchUrlString(
                                      'https://${e.hosts[0]}',
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                : null,
                            child: Text(
                              '${e.name}${e.enforceTrackOnly ? ' ${tr('trackOnlyInBrackets')}' : ''}${e.canSearch ? ' ${tr('searchableInBrackets')}' : ''}',
                              style: TextStyle(
                                decoration: e.hosts.isNotEmpty
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${tr('note')}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(tr('selfHostedNote', args: [tr('overrideSource')])),
                    ],
                  );
                },
              );
            },
            child: Text(
              tr('supportedSources'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              launchUrlString(
                'https://apps.obtainium.imranr.dev/',
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              tr('crowdsourcedConfigsShort'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isModern = settingsProvider.plusEnableModernAddAppPage;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: settingsProvider.plusShowLegacyUIComparison
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'add_app_ui_comparison_toggle',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  settingsProvider.plusEnableModernAddAppPage =
                      !settingsProvider.plusEnableModernAddAppPage;
                },
                child: Icon(
                  settingsProvider.plusEnableModernAddAppPage
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(tr('addApp')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.install_mobile_rounded),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemAppSelector(returnUrlOnSelect: true),
                ),
              );
              if (result != null) {
                _changeUserInput(result, true, false, updateUrlInput: true);
              }
            },
            tooltip: tr('importInstalledApps'),
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Unified search/URL bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _inputController,
              hintText: tr('searchOrURL'),
              leading: Icon(
                _isUrlMode ? Icons.link_outlined : Icons.search_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              shape: WidgetStateProperty.all(const StadiumBorder()),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 4),
              ),
              onChanged: (value) {
                _changeUserInput(value, true, false);
                if (!value.trim().startsWith('http')) {
                  _discoverPageKey.currentState?.searchQuery = value;
                  _discoverSearchDebounce?.cancel();
                  _discoverSearchDebounce = Timer(const Duration(milliseconds: 800), () {
                    if (mounted && value.trim().isNotEmpty) {
                      _discoverPageKey.currentState?.runSearch();
                    }
                  });
                }
              },
              onSubmitted: (_) {
                if (_isUrlMode) {
                  if (_canAddUrl) _addApp();
                } else if (userInput.trim().isNotEmpty) {
                  _discoverPageKey.currentState?.searchQuery = userInput;
                  _discoverPageKey.currentState?.runSearch();
                }
              },
              trailing: [
                if (!_isUrlMode && userInput.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () =>
                        _discoverPageKey.currentState?.showSearchOptions(),
                    tooltip: tr('searchOptions'),
                  ),
                if (userInput.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _discoverSearchDebounce?.cancel();
                      _inputController.clear();
                      _changeUserInput('', true, false);
                    },
                  ),
                if (_isUrlMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: gettingAppInfo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton.tonal(
                            onPressed: _canAddUrl
                                ? () {
                                    HapticFeedback.selectionClick();
                                    _addApp();
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(tr('add')),
                          ),
                  )
                else if (userInput.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonal(
                      onPressed: () {
                        _discoverPageKey.currentState?.searchQuery = userInput;
                        _discoverPageKey.currentState?.runSearch();
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(tr('search')),
                    ),
                  ),
              ],
            ),
          ),

          // URL validation error
          if (_isUrlMode && _urlValidationError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _urlValidationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Source filter chips (discover mode only)
          if (!_isUrlMode && userInput.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Consumer<SettingsProvider>(
                builder: (context, sp, _) {
                  final searchableSrcs =
                      sourceProvider.sources.where((e) => e.canSearch).toList();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: searchableSrcs.map((source) {
                        final isSelected =
                            !sp.searchDeselected.contains(source.name);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(source.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              final current =
                                  List<String>.from(sp.searchDeselected);
                              if (selected) {
                                current.remove(source.name);
                              } else {
                                current.add(source.name);
                              }
                              sp.searchDeselected = current;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _isUrlMode ? 0 : 1,
              children: [
                // URL / empty mode
                isModern
                    ? _buildModernUrlContent(context)
                    : _buildLegacyUrlContent(context),
                // Discover mode
                DiscoverPage(
                  key: _discoverPageKey,
                  showAppBar: false,
                  showSearchBar: false,
                  initialQuery: userInput,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          (_isUrlMode || userInput.trim().isEmpty) && pickedSource == null
              ? _getSourcesListWidget()
              : null,
    );
  }

  Widget _buildModernUrlContent(BuildContext context) {
    if (pickedSource == null) return const SizedBox.shrink();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSourceSection(context),
              const SizedBox(height: 16),
              _buildModernSourceNoteSection(context),
              const SizedBox(height: 16),
              _buildModernOptionsSection(context),
              const SizedBox(height: 16),
              _buildModernCategoriesSection(context),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyUrlContent(BuildContext context) {
    if (pickedSource == null) return const SizedBox.shrink();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _getHTMLSourceOverrideDropdown(),
                FutureBuilder(
                  builder: (ctx, val) {
                    return val.data != null && val.data!.isNotEmpty
                        ? Text(
                            val.data!,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : const SizedBox();
                  },
                  future: pickedSource?.getSourceNote(),
                ),
                _getAdditionalOptsCol(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSourceSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('basics'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            _getHTMLSourceOverrideDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSourceNoteSection(BuildContext context) {
    return FutureBuilder(
      future: pickedSource?.getSourceNote(),
      builder: (ctx, val) {
        if (val.data == null || val.data!.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  val.data!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernOptionsSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('additionalOptions'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            GeneratedForm(
              key: Key(
                'modern-${pickedSource.runtimeType.toString()}-${pickedSource?.hostChanged.toString()}-${pickedSource?.hostIdenticalDespiteAnyChange.toString()}',
              ),
              items: [
                ...pickedSource!.combinedAppSpecificSettingFormItems,
                ...(pickedSourceOverride != null
                    ? pickedSource!.sourceConfigSettingFormItems.map((e) => [e])
                    : []),
              ],
              onValueChanges: (values, valid, isBuilding) {
                if (!isBuilding) {
                  setState(() {
                    additionalSettings = values;
                    additionalSettingsValid = valid;
                  });
                }
              },
            ),
            if (pickedSource != null && pickedSource!.appIdInferIsOptional) ...[
              const Divider(),
              _buildInferAppIdToggle(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInferAppIdToggle() {
    return GeneratedForm(
      key: const Key('inferAppIdIfOptional-modern'),
      items: [
        [
          GeneratedFormSwitch(
            'inferAppIdIfOptional',
            label: tr('tryInferAppIdFromCode'),
            defaultValue: inferAppIdIfOptional,
          ),
        ],
      ],
      onValueChanges: (values, valid, isBuilding) {
        if (!isBuilding) {
          setState(() {
            inferAppIdIfOptional = values['inferAppIdIfOptional'];
          });
        }
      },
    );
  }

  Widget _buildModernCategoriesSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('categories'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            CategoryEditorSelector(
              alignment: WrapAlignment.start,
              onSelected: (categories) {
                pickedCategories = categories;
              },
            ),
          ],
        ),
      ),
    );
  }
}
