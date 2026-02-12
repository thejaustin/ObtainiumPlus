import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/discover.dart';
import 'package:obtainium/pages/import_export.dart';
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
  // bool searching = false; // Moved to DiscoverPage

  String userInput = '';
  // String searchQuery = ''; // Moved to DiscoverPage
  String? pickedSourceOverride;
  String? previousPickedSourceOverride;
  AppSource? pickedSource;
  Map<String, dynamic> additionalSettings = {};
  bool additionalSettingsValid = true;
  bool inferAppIdIfOptional = true;
  List<String> pickedCategories = [];
  int urlInputKey = 0;
  SourceProvider sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    if (widget.appId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var app = context.read<AppsProvider>().apps[widget.appId]?.app;
        if (app != null) {
          changeUserInput(app.url, true, false, updateUrlInput: true);
        }
      });
    } else if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        changeUserInput(widget.initialUrl!, true, false, updateUrlInput: true);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void linkFn(String input) {
    // If input comes from DiscoverPage, we might need to switch to URL tab
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
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

  // ... (changeUserInput remains same)

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppsProvider appsProvider = context.read<AppsProvider>();
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    NotificationsProvider notificationsProvider = context
        .read<NotificationsProvider>();

    bool doingSomething = gettingAppInfo; // || searching;

    // ... (rest of helper functions)

    Future<bool> getTrackOnlyConfirmationIfNeeded(
      bool userPickedTrackOnly, {
      bool ignoreHideSetting = false,
    }) async {
      var useTrackOnly = userPickedTrackOnly || pickedSource!.enforceTrackOnly;
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
          var trackOnly = pickedSource!.enforceTrackOnly || userPickedTrackOnly;
          app = await sourceProvider.getApp(
            pickedSource!,
            userInput.trim(),
            additionalSettings,
            trackOnlyOverride: trackOnly,
            sourceIsOverriden: pickedSourceOverride != null,
            inferAppIdIfOptional: inferAppIdIfOptional,
          );
          // Only download the APK here if you need to for the package ID
          if (SourceUtils.isTempId(app) && app.additionalSettings['trackOnly'] != true) {
            // ignore: use_build_context_synchronously
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
        setState(() {
          gettingAppInfo = false;
          if (resetUserInputAfter) {
            changeUserInput('', false, true);
          }
        });
      }
    }

    Widget getUrlInputRow() {
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
                changeUserInput(values['appSourceURL']!, valid, isBuilding);
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
                        doingSomething ||
                            (isUrl && (pickedSource == null ||
                            (pickedSource!
                                    .combinedAppSpecificSettingFormItems
                                    .isNotEmpty &&
                                !additionalSettingsValid)))
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            if (isUrl) {
                              addApp();
                            } else {
                              // Switch to Discover tab and run search
                              _tabController.animateTo(1);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final discoverKey = context.read<GlobalKey<DiscoverPageState>>();
                                if (discoverKey.currentState != null) {
                                  discoverKey.currentState!.searchQuery = userInput;
                                  discoverKey.currentState!.runSearch();
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
      bottomNavigationBar: pickedSource == null && _tabController.index == 0 ? getSourcesListWidget() : null, // Only show sources list on URL tab
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
                      getUrlInputRow(),
                      const SizedBox(height: 16),
                      if (pickedSource != null) getHTMLSourceOverrideDropdown(),
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
          ),
          DiscoverPage(showAppBar: false, initialQuery: userInput),
        ],
      ),
    );
  }
}
