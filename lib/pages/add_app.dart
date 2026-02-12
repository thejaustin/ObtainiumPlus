import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/discover.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
  final int initialTab;
  const AddAppPage({super.key, this.mode = AddAppMode.add, this.appId, this.initialUrl, this.initialTab = 0});

  @override
  State<AddAppPage> createState() => AddAppPageState();
}

class AddAppPageState extends State<AddAppPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool gettingAppInfo = false;

  String userInput = '';
  String? pickedSourceOverride;
  String? previousPickedSourceOverride;
  AppSource? pickedSource;
  Map<String, dynamic> additionalSettings = {};
  bool additionalSettingsValid = true;
  bool inferAppIdIfOptional = true;
  List<String> pickedCategories = [];
  int urlInputKey = 0;
  SourceProvider sourceProvider = SourceProvider();
  final GlobalKey<DiscoverPageState> _discoverPageKey = GlobalKey<DiscoverPageState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
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
    _tabController.dispose();
    super.dispose();
  }

  void linkFn(String input) {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    try {
      if (input.isEmpty) {
        throw UnsupportedURLError();
      }
      sourceProvider.getSource(input);
      _changeUserInput(input, true, false, updateUrlInput: true);
    } catch (e) {
      showError(e, context);
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
      });
    }
  }

  Future<bool> _getTrackOnlyConfirmationIfNeeded(
    bool userPickedTrackOnly, {
    bool ignoreHideSetting = false,
  }) async {
    var useTrackOnly = userPickedTrackOnly || (pickedSource?.enforceTrackOnly ?? false);
    if (useTrackOnly &&
        (!context.read<SettingsProvider>().hideTrackOnlyWarning || ignoreHideSetting)) {
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
        context.read<SettingsProvider>().hideTrackOnlyWarning = values['hide'] == true;
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
      App? app;
      if ((await _getTrackOnlyConfirmationIfNeeded(userPickedTrackOnly)) &&
          (await _getReleaseDateAsVersionConfirmationIfNeeded(
            userPickedTrackOnly,
          ))) {
        var trackOnly = pickedSource!.enforceTrackOnly || userPickedTrackOnly;
        app = await sourceProvider.getApp(
          pickedSource!,
          userInput.trim(),
          additionalSettings,
          trackOnlyOverride: trackOnly,
          sourceIsOverriden: pickedSourceOverride != null,
          inferAppIdIfOptional: inferAppIdIfOptional,
        );
        if (SourceUtils.isTempId(app) && app.additionalSettings['trackOnly'] != true) {
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
      showError(e, context);
    } finally {
      if (mounted) {
        setState(() {
          gettingAppInfo = false;
        });
      }
    }
  }

  Widget _getUrlInputRow() {
    bool isUrl = userInput.trim().startsWith('http');
    
    return Row(
      children: [
        Expanded(
          child: GeneratedForm(
            key: Key(urlInputKey.toString()),
            items: [
              [
                GeneratedFormTextField(
                  'appSourceURL',
                  label: tr('searchOrURL'),
                  defaultValue: userInput,
                  additionalValidators: [
                    (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (!value.trim().startsWith('http')) return null; // Treat as search query
                      try {
                        sourceProvider
                            .getSource(
                              value,
                              overrideSource: pickedSourceOverride,
                            )
                            .standardizeUrl(value);
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
              _changeUserInput(values['appSourceURL']!, valid, isBuilding);
            },
          ),
        ),
        const SizedBox(width: 16),
        gettingAppInfo
            ? const CircularProgressIndicator()
            : GestureDetector(
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(initialTab: 1),
                    ),
                  );
                },
                child: ElevatedButton(
                  onPressed:
                      gettingAppInfo ||
                          (isUrl && (pickedSource == null ||
                          (pickedSource!
                                  .combinedAppSpecificSettingFormItems
                                  .isNotEmpty &&
                              !additionalSettingsValid)))
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          if (isUrl) {
                            _addApp();
                          } else {
                            _tabController.animateTo(1);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_discoverPageKey.currentState != null) {
                                _discoverPageKey.currentState!.searchQuery = userInput;
                                _discoverPageKey.currentState!.runSearch();
                              }
                            });
                          }
                        },
                  child: Text(isUrl ? tr('add') : tr('search')),
                ),
              ),
      ],
    );
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false, // For modal
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
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('appSourceURL')),
            Tab(text: tr('discover')),
          ],
        ),
      ),
      bottomNavigationBar: pickedSource == null && _tabController.index == 0 ? _getSourcesListWidget() : null, // Only show sources list on URL tab
      body: TabBarView(
        controller: _tabController,
        children: [
          CustomScrollView(
            shrinkWrap: true,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _getUrlInputRow(),
                      const SizedBox(height: 16),
                      if (pickedSource != null) _getHTMLSourceOverrideDropdown(),
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
                      if (pickedSource != null) _getAdditionalOptsCol(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DiscoverPage(key: _discoverPageKey, showAppBar: false, initialQuery: userInput),
        ],
      ),
    );
  }
}
