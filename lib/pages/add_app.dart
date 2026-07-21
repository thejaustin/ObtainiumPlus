import 'dart:async';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/components/apps/app_tile_skeleton.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/discover.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_search_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AddAppPage extends StatefulWidget {
  final int? initialTab;

  /// When set, the URL is fed into the form (via linkFn) as soon as the
  /// page is built — used by deep links and search results that open the
  /// Add App page as a pushed route.
  final String? initialUrl;
  final String? appId;

  const AddAppPage({
    super.key,
    this.isModal = false,
    this.scrollController,
    this.initialTab,
    this.initialUrl,
    this.appId,
  });

  final bool isModal;
  final ScrollController? scrollController;

  @override
  State<AddAppPage> createState() => AddAppPageState();
}

class AddAppPageState extends State<AddAppPage> {
  bool gettingAppInfo = false;
  bool searching = false;

  String userInput = '';
  String searchQuery = '';
  String? pickedSourceOverride;
  String? previousPickedSourceOverride;
  AppSource? pickedSource;
  Map<String, dynamic> additionalSettings = {};
  bool additionalSettingsValid = true;
  bool inferAppIdIfOptional = true;
  List<String> pickedCategories = [];
  int urlInputKey = 0;
  SourceProvider sourceProvider = SourceProvider();
  Timer? _searchDebounce;
  Map<String, MapEntry<String, List<String>>> liveResults = {};
  bool liveSearching = false;

  @override
  void initState() {
    super.initState();
    final initialUrl = widget.initialUrl;
    final appId = widget.appId;

    if (appId != null && appId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final appsProvider = context.read<AppsProvider>();
          final app = appsProvider.apps[appId]?.app;
          if (app != null) {
            setState(() {
              userInput = app.url;
              urlInputKey++; // Force text field update
              pickedSourceOverride = app.overrideSource;
              previousPickedSourceOverride = app.overrideSource;
              additionalSettings = Map.from(app.additionalSettings);
              pickedCategories = List.from(app.categories);
              inferAppIdIfOptional = false;
            });
            try {
              sourceProvider.getSource(app.url);
              changeUserInput(
                app.url,
                true,
                false,
                updateUrlInput: true,
                overrideSource: app.overrideSource,
              );
            } catch (_) {}
          }
        }
      });
    } else if (initialUrl != null && initialUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          linkFn(initialUrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void linkFn(String input) {
    try {
      if (input.isEmpty) {
        throw UnsupportedURLError();
      }
      sourceProvider.getSource(input);
      changeUserInput(input, true, false, updateUrlInput: true);
    } catch (e) {
      showError(e, context);
    }
  }

  Future<void> runLiveSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        liveResults = {};
        liveSearching = false;
      });
      return;
    }

    setState(() {
      liveSearching = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();

      final aggregatedResults = await AppSearchService.searchAllSources(
        query,
        sourceProvider: sourceProvider,
        deselectedSources: settingsProvider.searchDeselected,
      );

      if (!mounted) return;
      setState(() {
        liveResults = aggregatedResults;
      });
    } catch (e) {
      // Ignore background search errors
    } finally {
      if (mounted) {
        setState(() {
          liveSearching = false;
        });
      }
    }
  }

  void changeUserInput(
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
        if (updateUrlInput) {
          urlInputKey++;
        }
        var prevHost = pickedSource?.hosts.isNotEmpty == true
            ? pickedSource?.hosts[0]
            : null;
        var source = valid
            ? sourceProvider.getSource(
                userInput,
                overrideSource: pickedSourceOverride,
              )
            : null;
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

        // Trigger live search if not a valid direct URL
        if (pickedSource == null ||
            pickedSource.runtimeType.toString() == 'DirectAPKLink' ||
            pickedSource.runtimeType.toString() == 'HTML') {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 600), () {
            if (mounted && userInput.isNotEmpty) {
              runLiveSearch(userInput);
            }
          });
        } else {
          liveResults = {};
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppsProvider appsProvider = context.read<AppsProvider>();
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    NotificationsProvider notificationsProvider = context
        .read<NotificationsProvider>();

    bool doingSomething = gettingAppInfo || searching;

    Future<bool> getTrackOnlyConfirmationIfNeeded(
      bool userPickedTrackOnly, {
      bool ignoreHideSetting = false,
    }) async {
      // Captured once, up front — pickedSource can go null via changeUserInput()
      // while this dialog's await is pending, and its builder can re-run on
      // an ancestor rebuild in the meantime (same race class as addApp()'s).
      final sourceEnforcesTrackOnly = pickedSource!.enforceTrackOnly;
      var useTrackOnly = userPickedTrackOnly || sourceEnforcesTrackOnly;
      if (useTrackOnly &&
          (!settingsProvider.hideTrackOnlyWarning || ignoreHideSetting)) {
        // ignore: use_build_context_synchronously
        var values = await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return GeneratedFormModal(
              initValid: true,
              title: tr(
                'xIsTrackOnly',
                args: [sourceEnforcesTrackOnly ? tr('source') : tr('app')],
              ),
              items: [
                [GeneratedFormSwitch('hide', label: tr('dontShowAgain'))],
              ],
              message:
                  '${sourceEnforcesTrackOnly ? tr('appsFromSourceAreTrackOnly') : tr('youPickedTrackOnly')}\n\n${tr('trackOnlyAppDescription')}',
            );
          },
        );
        if (values != null) {
          settingsProvider.hideTrackOnlyWarning = values['hide'] == true;
        }
        return useTrackOnly && values != null;
      } else {
        return true;
      }
    }

    getReleaseDateAsVersionConfirmationIfNeeded(
      bool userPickedTrackOnly,
    ) async {
      return (!(additionalSettings['releaseDateAsVersion'] == true &&
          // ignore: use_build_context_synchronously
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

    addApp({bool resetUserInputAfter = false}) async {
      setState(() {
        gettingAppInfo = true;
      });
      try {
        var userPickedTrackOnly = additionalSettings['trackOnly'] == true;
        App? app;
        if ((await getTrackOnlyConfirmationIfNeeded(userPickedTrackOnly)) &&
            (await getReleaseDateAsVersionConfirmationIfNeeded(
              userPickedTrackOnly,
            ))) {
          // Re-read pickedSource here rather than trusting the value from
          // before the awaits above: the URL field stays editable while
          // those confirmation prompts are pending, and changeUserInput()
          // sets pickedSource back to null if the edited input no longer
          // resolves to a source (#231).
          final source = pickedSource;
          if (source == null) {
            return;
          }
          var trackOnly = source.enforceTrackOnly || userPickedTrackOnly;
          app = await sourceProvider.getApp(
            source,
            userInput.trim(),
            additionalSettings,
            trackOnlyOverride: trackOnly,
            sourceIsOverriden: pickedSourceOverride != null,
            inferAppIdIfOptional: inferAppIdIfOptional,
          );
          // Only download the APK here if you need to for the package ID
          if (isTempId(app) && app.additionalSettings['trackOnly'] != true) {
            var apkUrl = await appsProvider.confirmAppFileUrl(
              app,
              mounted ? context : null,
              false,
            );
            if (apkUrl == null) {
              throw ObtainiumError(tr('cancelled'));
            }
            app.preferredApkIndex = app.apkUrls
                .map((e) => e.value)
                .toList()
                .indexOf(apkUrl.value);
            // ignore: use_build_context_synchronously
            var downloadedArtifact = await appsProvider.downloadApp(
              app,
              globalNavigatorKey.currentContext,
              notificationsProvider: notificationsProvider,
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
        if (app != null) {
          AppHaptics.selectionClick();
          final homeState = globalNavigatorKey.currentContext
              ?.findAncestorStateOfType<HomePageState>();
          homeState?.switchToPage(0);
          // Add App is a pushed route now (not a tab); close it so the
          // user lands back on the Apps tab behind the app sheet.
          if (!widget.isModal && mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          showDraggableModalBottomSheet(
            context: globalNavigatorKey.currentContext ?? context,
            builder: (context, controller) => AppPage(
              appId: app!.id,
              isModal: true,
              scrollController: controller,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) showError(e, context);
      } finally {
        setState(() {
          gettingAppInfo = false;
          if (resetUserInputAfter) {
            changeUserInput('', false, true);
          }
        });
      }
    }

    Widget getUrlInputRow() => Row(
      children: [
        Expanded(
          child: GeneratedForm(
            key: Key(urlInputKey.toString()),
            items: [
              [
                GeneratedFormTextField(
                  'appSourceURL',
                  label: tr('appSourceURL'),
                  defaultValue: userInput,
                  additionalValidators: [
                    (value) {
                      try {
                        sourceProvider
                            .getSource(
                              value ?? '',
                              overrideSource: pickedSourceOverride,
                            )
                            .standardizeUrl(value ?? '');
                      } catch (e) {
                        return e is String
                            ? e
                            : e is ObtainiumError
                            ? e.toString()
                            : tr('error');
                      }
                      return null;
                    },
                  ],
                ),
              ],
            ],
            onValueChanges: (values, valid, isBuilding) {
              changeUserInput(values['appSourceURL']!, valid, isBuilding);
            },
          ),
        ),
        const SizedBox(width: 16),
        gettingAppInfo
            ? const Center(
                child: ExpressiveCircularProgressIndicator(strokeWidth: 3),
              )
            : ScaleTouchWrapper(
                child: ElevatedButton(
                  onPressed:
                      doingSomething ||
                          pickedSource == null ||
                          (pickedSource!
                                  .combinedAppSpecificSettingFormItems
                                  .isNotEmpty &&
                              !additionalSettingsValid)
                      ? null
                      : () {
                          AppHaptics.selectionClick();
                          addApp();
                        },
                  child: Text(widget.appId != null ? tr('save') : tr('add')),
                ),
              ),
      ],
    );

    runSearch({bool filtered = true}) async {
      setState(() {
        searching = true;
      });
      var sourceStrings = <String, List<String>>{};
      sourceProvider.sources.where((e) => e.canSearch).forEach((s) {
        sourceStrings[s.name] = [s.name];
      });
      try {
        var searchSources =
            await showDialog<List<String>?>(
              context: context,
              builder: (BuildContext ctx) {
                return SelectionModal(
                  title: tr(
                    'selectX',
                    args: [plural('source', 2).toLowerCase()],
                  ),
                  entries: sourceStrings,
                  selectedByDefault: true,
                  onlyOneSelectionAllowed: false,
                  titlesAreLinks: false,
                  deselectThese: settingsProvider.searchDeselected,
                );
              },
            ) ??
            [];
        if (searchSources.isNotEmpty) {
          settingsProvider.searchDeselected = sourceStrings.keys
              .where((s) => !searchSources.contains(s))
              .toList();
          List<MapEntry<String, Map<String, List<String>>>?>
          results = (await Future.wait(
            sourceProvider.sources
                .where((e) => searchSources.contains(e.name))
                .map((e) async {
                  try {
                    Map<String, dynamic>? querySettings = {};
                    if (e.includeAdditionalOptsInMainSearch) {
                      querySettings = await showDialog<Map<String, dynamic>?>(
                        context: context,
                        builder: (BuildContext ctx) {
                          return GeneratedFormModal(
                            title: tr('searchX', args: [e.name]),
                            items: [
                              ...e.searchQuerySettingFormItems.map((e) => [e]),
                              [
                                GeneratedFormTextField(
                                  'url',
                                  label: e.hosts.isNotEmpty
                                      ? tr('overrideSource')
                                      : plural('url', 1).substring(2),
                                  autoCompleteOptions: [
                                    ...(e.hosts.isNotEmpty ? [e.hosts[0]] : []),
                                    ...appsProvider.apps.values
                                        .where(
                                          (a) =>
                                              sourceProvider
                                                  .getSource(
                                                    a.app.url,
                                                    overrideSource:
                                                        a.app.overrideSource,
                                                  )
                                                  .runtimeType ==
                                              e.runtimeType,
                                        )
                                        .map((a) {
                                          var uri = Uri.parse(a.app.url);
                                          return '${uri.origin}${uri.path}';
                                        }),
                                  ],
                                  defaultValue: e.hosts.isNotEmpty
                                      ? e.hosts[0]
                                      : '',
                                  required: true,
                                ),
                              ],
                            ],
                          );
                        },
                      );
                      if (querySettings == null) {
                        return null;
                      }
                    }
                    return MapEntry(
                      e.runtimeType.toString(),
                      await e.search(searchQuery, querySettings: querySettings),
                    );
                  } catch (err) {
                    if (err is! CredsNeededError) {
                      rethrow;
                    } else {
                      err.unexpected = true;
                      if (context.mounted) showError(err, context);
                      return null;
                    }
                  }
                }),
          )).where((a) => a != null).toList();

          // Interleave results instead of simple reduce
          Map<String, MapEntry<String, List<String>>> res = {};
          var si = 0;
          var done = false;
          while (!done) {
            done = true;
            for (var r in results) {
              var sourceName = r!.key;
              if (r.value.length > si) {
                done = false;
                var singleRes = r.value.entries.elementAt(si);
                res[singleRes.key] = MapEntry(sourceName, singleRes.value);
              }
            }
            si++;
          }
          if (res.isEmpty) {
            throw ObtainiumError(tr('noResults'));
          }
          if (!context.mounted) return;
          List<String>? selectedUrls = res.isEmpty
              ? []
              : await showDialog<List<String>?>(
                  context: context,
                  builder: (BuildContext ctx) {
                    return SelectionModal(
                      entries: res.map((k, v) => MapEntry(k, v.value)),
                      selectedByDefault: false,
                      onlyOneSelectionAllowed: true,
                    );
                  },
                );
          if (selectedUrls != null && selectedUrls.isNotEmpty) {
            var sourceName = res[selectedUrls[0]]?.key;
            changeUserInput(
              selectedUrls[0],
              true,
              false,
              updateUrlInput: true,
              overrideSource: sourceName,
            );
          }
        }
      } catch (e) {
        if (context.mounted) showError(e, context);
      } finally {
        if (mounted) {
          setState(() {
            searching = false;
          });
        }
      }
    }

    Widget getHTMLSourceOverrideDropdown() => Column(
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
                  fn() {
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
                  changeUserInput(userInput, valid, isBuilding);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );

    bool shouldShowSearchBar() =>
        sourceProvider.sources.where((e) => e.canSearch).isNotEmpty &&
        pickedSource == null &&
        userInput.isEmpty;

    Widget getSearchBarRow() => Row(
      children: [
        Expanded(
          child: GeneratedForm(
            items: [
              [
                GeneratedFormTextField(
                  'searchSomeSources',
                  label: tr('searchSomeSourcesLabel'),
                  required: false,
                ),
              ],
            ],
            onValueChanges: (values, valid, isBuilding) {
              if (values.isNotEmpty && valid && !isBuilding) {
                setState(() {
                  searchQuery = values['searchSomeSources']!.trim();
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        searching
            ? const ExpressiveCircularProgressIndicator()
            : ElevatedButton(
                onPressed: searchQuery.isEmpty || doingSomething
                    ? null
                    : () {
                        runSearch();
                      },
                child: Text(tr('search')),
              ),
      ],
    );

    Widget getAdditionalOptsCol() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        CategoryEditorSelector(
          alignment: WrapAlignment.start,
          onSelected: (categories) {
            pickedCategories = categories;
          },
        ),
        const SizedBox(height: 24),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.tune_rounded),
            title: Text(
              tr('advancedOptions'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              tr(
                'additionalOptsFor',
                args: [pickedSource?.name ?? tr('source')],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    GeneratedForm(
                      key: Key(
                        '${pickedSource.runtimeType.toString()}-${pickedSource?.hostChanged.toString()}-${pickedSource?.hostIdenticalDespiteAnyChange.toString()}',
                      ),
                      items: [
                        ...pickedSource!.combinedAppSpecificSettingFormItems,
                        ...(pickedSourceOverride != null
                            ? pickedSource!.sourceConfigSettingFormItems.map(
                                (e) => [e],
                              )
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
                    if (pickedSource != null &&
                        pickedSource!.appIdInferIsOptional)
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
                              inferAppIdIfOptional =
                                  values['inferAppIdIfOptional'];
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
                ),
              ),
            ],
          ),
        ),
      ],
    );

    Widget getSourcesListWidget() => Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        direction: Axis.horizontal,
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        children: [
          InkWell(
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
                          child: InkWell(
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
          InkWell(
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

    Widget _buildAppPreview() {
      if (pickedSource == null || userInput.isEmpty)
        return const SizedBox.shrink();
      final colorScheme = Theme.of(context).colorScheme;
      final plusSettings = context.watch<PlusSettingsProvider>();
      if (!plusSettings.plusEnableModernAddAppPage)
        return const SizedBox.shrink();

      final radius = plusSettings.plusGlobalCornerRadius;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(radius * 0.6),
                      ),
                      child: Icon(
                        Icons.get_app_rounded,
                        color: colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('appPreview'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            pickedSource?.name ?? tr('unknown'),
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userInput,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pickedSource!.enforceTrackOnly) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(radius * 0.4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('trackOnlyAppDescription'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildLiveResults() {
      if (!liveSearching && liveResults.isEmpty) return const SizedBox.shrink();

      final colorScheme = Theme.of(context).colorScheme;
      final plusSettings = context.watch<PlusSettingsProvider>();
      final resultRadius = (plusSettings.plusGlobalCornerRadius * 0.6).clamp(
        8.0,
        20.0,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Text(
                  tr('searchSuggestions'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (liveSearching) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (liveSearching && liveResults.isEmpty)
            const AppTileSkeleton(isGrid: false)
          else
            ...liveResults.entries.take(5).map((entry) {
              final url = entry.key;
              final name = entry.value.value.isNotEmpty
                  ? entry.value.value[0]
                  : '';
              final sourceName = entry.value.key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(resultRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(resultRadius),
                    onTap: () {
                      AppHaptics.selectionClick();
                      linkFn(url);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  sourceName,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: colorScheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    }

    final formScrollView = CustomScrollView(
      controller: widget.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: widget.isModal
          ? const BouncingScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      slivers: <Widget>[
        if (!widget.isModal)
          CustomAppBar(
            title: tr('addApp'),
            actions: [
              IconButton(
                icon: const Icon(Icons.import_export_rounded),
                tooltip: tr('importExport'),
                onPressed: () {
                  AppHaptics.selectionClick();
                  pushRoute(context, const ImportExportPage());
                },
              ),
            ],
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                getUrlInputRow(),
                const SizedBox(height: 16),
                if (pickedSource != null) getHTMLSourceOverrideDropdown(),
                _buildLiveResults(),
                _buildAppPreview(),
                if (shouldShowSearchBar()) getSearchBarRow(),
                if (pickedSource != null)
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
                if (pickedSource != null) getAdditionalOptsCol(),
              ],
            ),
          ),
        ),
      ],
    );

    final plusSettings = context.watch<PlusSettingsProvider>();

    // Discover is merged into the Add App experience: when the page is
    // idle (no URL typed, no source picked) the browse/discover content
    // fills the space below the add-by-URL form. Tapping a result feeds
    // its URL back into the form via linkFn.
    final showDiscover =
        !widget.isModal &&
        plusSettings.plusEnableDiscover &&
        pickedSource == null &&
        userInput.isEmpty;

    final scaffold = Scaffold(
      backgroundColor: widget.isModal
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      bottomNavigationBar: pickedSource == null ? getSourcesListWidget() : null,
      body: showDiscover
          ? Column(
              children: [
                Flexible(child: formScrollView),
                Expanded(
                  child: DiscoverPage(
                    showAppBar: false,
                    showSearchBar: false,
                    onAppSelected: (url) => linkFn(url),
                  ),
                ),
              ],
            )
          : formScrollView,
    );

    if (widget.isModal) {
      final radius = plusSettings.plusOverrideIndividualCornerRadius
          ? plusSettings.plusHomeCornerRadius
          : plusSettings.plusGlobalCornerRadius;

      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius.clamp(20.0, 48.0)),
        ),
        child: ConditionalBlur(
          enabled: plusSettings.plusEnableGlassmorphism,
          sigma: 20,
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: plusSettings.plusEnableGlassmorphism ? 0.85 : 1.0,
            ),
            child: scaffold,
          ),
        ),
      );
    }

    return scaffold;
  }
}
