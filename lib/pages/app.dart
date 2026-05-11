import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:ui';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:obtainium/components/apps/app_changelog.dart';
import 'package:obtainium/components/apps/app_description_slider.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/tag_editor.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/play_store_mirror_service.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:obtainium/utils/app_constants.dart';

class AppPage extends StatefulWidget {
  const AppPage({
    super.key,
    required this.appId,
    this.showOppositeOfPreferredView = false,
    this.isModal = false,
    this.scrollController,
  });

  final String appId;
  final bool showOppositeOfPreferredView;
  final bool isModal;
  final ScrollController? scrollController;

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  AppInMemory? prevApp;
  bool updating = false;

  void _showContextMenu({
    required String title,
    required List<MapEntry<String, VoidCallback>> actions,
  }) {
    final settings = context.read<SettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (ctx) {
        final sheet = Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withOpacity(
                  enableGlass ? 0.18 : 0,
                ),
              ),
              left: BorderSide(
                color: colorScheme.onSurface.withOpacity(
                  enableGlass ? 0.12 : 0,
                ),
              ),
              right: BorderSide(
                color: colorScheme.onSurface.withOpacity(
                  enableGlass ? 0.12 : 0,
                ),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DragHandle(margin: EdgeInsets.only(top: 8, bottom: 4)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...actions.map(
                  (action) => ListTile(
                    title: Text(action.key),
                    onTap: () {
                      Navigator.pop(ctx);
                      action.value();
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (!enableGlass) return sheet;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: sheet,
          ),
        );
      },
    );
  }

  void _showTagEditor(AppInMemory appInMemory) async {
    final appsProvider = context.read<AppsProvider>();
    final allTags = appsProvider
        .getAppValues()
        .expand((a) => a.app.tags)
        .toSet()
        .toList();
    allTags.sort();

    final newTags = await showTagEditor(
      context: context,
      currentTags: appInMemory.app.tags,
      allTags: allTags,
    );

    if (newTags != null) {
      final app = appInMemory.app;
      app.tags = newTags;
      await appsProvider.saveApps([app]);
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    final showAppWebpage = context.select<SettingsProvider, bool>(
      (sp) => sp.showAppWebpage,
    );
    final checkUpdateOnDetailPage = context.select<SettingsProvider, bool>(
      (sp) => sp.checkUpdateOnDetailPage,
    );
    final highlightTouchTargets = context.select<SettingsProvider, bool>(
      (sp) => sp.highlightTouchTargets,
    );
    var showAppWebpageFinal =
        (showAppWebpage && !widget.showOppositeOfPreferredView) ||
        (!showAppWebpage && widget.showOppositeOfPreferredView);
    getUpdate(String id, {bool resetVersion = false}) async {
      try {
        if (mounted) {
          setState(() {
            updating = true;
          });
        }
        await appsProvider.checkUpdate(id);
        if (resetVersion) {
          appsProvider.apps[id]?.app.additionalSettings['versionDetection'] =
              true;
          if (appsProvider.apps[id]?.app.installedVersion != null) {
            appsProvider.apps[id]?.app.installedVersion =
                appsProvider.apps[id]?.app.latestVersion;
          }
          final appToSave = appsProvider.apps[id]?.app;
          if (appToSave != null) {
            appsProvider.saveApps([appToSave]);
          }
        }
      } catch (err) {
        if (mounted) {
          showError(err, context);
        }
      } finally {
        if (mounted) {
          setState(() {
            updating = false;
          });
        }
      }
    }

    bool areDownloadsRunning = appsProvider.areDownloadsRunning();

    var sourceProvider = SourceProvider();
    AppInMemory? app = appsProvider.apps[widget.appId]?.deepCopy();
    var source = app != null
        ? sourceProvider.getSource(
            app.app.url,
            overrideSource: app.app.overrideSource,
          )
        : null;
    if (!areDownloadsRunning &&
        prevApp == null &&
        app != null &&
        checkUpdateOnDetailPage) {
      prevApp = app;
      getUpdate(app.app.id);
    }
    var trackOnly = app?.app.additionalSettings['trackOnly'] == true;

    bool isVersionDetectionStandard =
        app?.app.additionalSettings['versionDetection'] == true;

    bool installedVersionIsEstimate = app?.app != null
        ? SourceUtils.isVersionPseudo(app!.app)
        : false;

    showMarkUpdatedDialog() {
      return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return GlassDialog(
            title: tr('alreadyUpToDateQuestion'),
            icon: Icons.check_circle_outline,
            content: const SizedBox.shrink(),
            scrollable: false,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(tr('no')),
              ),
              FilledButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  var updatedApp = app?.app;
                  if (updatedApp != null) {
                    updatedApp.installedVersion = updatedApp.latestVersion;
                    appsProvider.saveApps([updatedApp]);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(tr('yesMarkUpdated')),
              ),
            ],
          );
        },
      );
    }

    showAdditionalOptionsDialog() async {
      return await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (BuildContext ctx) {
          var items = (source?.combinedAppSpecificSettingFormItems ?? []).map((
            row,
          ) {
            row = row.map((e) {
              if (app?.app.additionalSettings[e.key] != null) {
                e.defaultValue = app?.app.additionalSettings[e.key];
              }
              return e;
            }).toList();
            return row;
          }).toList();

          return GeneratedFormModal(
            title: tr('additionalOptions'),
            items: items,
          );
        },
      );
    }

    handleAdditionalOptionChanges(Map<String, dynamic>? values) {
      if (app != null && values != null) {
        Map<String, dynamic> originalSettings = app.app.additionalSettings;
        app.app.additionalSettings = values;
        if (source?.enforceTrackOnly == true) {
          app.app.additionalSettings['trackOnly'] = true;
          // ignore: use_build_context_synchronously
          showMessage(tr('appsFromSourceAreTrackOnly'), context);
        }
        var versionDetectionEnabled =
            app.app.additionalSettings['versionDetection'] == true &&
            originalSettings['versionDetection'] != true;
        var releaseDateVersionEnabled =
            app.app.additionalSettings['releaseDateAsVersion'] == true &&
            originalSettings['releaseDateAsVersion'] != true;
        var releaseDateVersionDisabled =
            app.app.additionalSettings['releaseDateAsVersion'] != true &&
            originalSettings['releaseDateAsVersion'] == true;
        if (releaseDateVersionEnabled) {
          if (app.app.releaseDate != null) {
            bool isUpdated = app.app.installedVersion == app.app.latestVersion;
            app.app.latestVersion = app.app.releaseDate!.microsecondsSinceEpoch
                .toString();
            if (isUpdated) {
              app.app.installedVersion = app.app.latestVersion;
            }
          }
        } else if (releaseDateVersionDisabled) {
          app.app.installedVersion =
              app.installedInfo?.versionName ?? app.app.installedVersion;
        }
        if (versionDetectionEnabled) {
          app.app.additionalSettings['versionDetection'] = true;
          app.app.additionalSettings['releaseDateAsVersion'] = false;
        }
        settingsProvider.sxncdSavedTs = DateTime.now().toIso8601String();
        appsProvider.saveApps([app.app]).then((value) {
          getUpdate(app.app.id, resetVersion: versionDetectionEnabled);
        });
      }
    }

    return Scaffold(
      appBar: showAppWebpageFinal ? (widget.isModal ? null : AppBar()) : null,
      backgroundColor: widget.isModal
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      floatingActionButton:
          appsProvider.settingsProvider.plusShowLegacyUIComparison
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Above bottom bar
              child: FloatingActionButton.small(
                heroTag: 'app_page_ui_comparison_toggle',
                onPressed: () {
                  AppHaptics.mediumImpact();
                  appsProvider.settingsProvider.plusEnableModernAppPage =
                      !appsProvider.settingsProvider.plusEnableModernAppPage;
                },
                child: Icon(
                  appsProvider.settingsProvider.plusEnableModernAppPage
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              if (app != null) {
                getUpdate(app.app.id);
              }
            },
            child: showAppWebpageFinal
                ? (app != null
                      ? _AppWebView(
                          url: app.app.url,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        )
                      : const SizedBox.shrink())
                : (appsProvider.settingsProvider.plusEnableModernAppPage
                      ? CustomScrollView(
                          controller: widget.scrollController,
                          slivers: [
                            _buildSliverAppBar(context, app),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Column(
                                  children: [
                                    _buildMainInfo(context, app, appsProvider),
                                    const SizedBox(height: 24),

                                    // 1. Stats Group
                                    ExpressiveSettingsGroup(
                                      title: tr('statistics'),
                                      children: [
                                        _buildStatRow(
                                          context,
                                          icon: Icons.install_mobile_rounded,
                                          label: tr('installed'),
                                          value:
                                              app?.app.installedVersion ??
                                              tr('notInstalled'),
                                          isBold: true,
                                        ),
                                        _buildStatRow(
                                          context,
                                          icon: Icons.new_releases_rounded,
                                          label: tr('latest'),
                                          value:
                                              app?.app.latestVersion ??
                                              tr('unknown'),
                                          valueColor:
                                              (app?.app.installedVersion ==
                                                  app?.app.latestVersion)
                                              ? null
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        ),
                                        _buildStatRow(
                                          context,
                                          icon: Icons.update_rounded,
                                          label: tr('lastCheck'),
                                          value:
                                              app?.app.lastUpdateCheck
                                                  ?.toLocal()
                                                  .toString()
                                                  .split('.')
                                                  .first ??
                                              tr('never'),
                                        ),
                                      ],
                                    ),

                                    // 3. Category Group
                                    ExpressiveSettingsGroup(
                                      title: tr('categories'),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: CategoryEditorSelector(
                                            alignment: WrapAlignment.start,
                                            preselected:
                                                app?.app.categories != null
                                                ? app!.app.categories.toSet()
                                                : {},
                                            onSelected: (categories) {
                                              if (app != null) {
                                                app.app.categories = categories;
                                                appsProvider.saveApps([
                                                  app.app,
                                                ]);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    // 3.5 Tags Group
                                    if (app != null)
                                      ExpressiveSettingsGroup(
                                        title: tr('tags'),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: _buildTagsSection(
                                              context,
                                              app,
                                              appsProvider,
                                            ),
                                          ),
                                        ],
                                      ),

                                    // 4. Advanced Group
                                    ExpressiveSettingsGroup(
                                      title: tr('advanced'),
                                      children: [
                                        ExpansionTile(
                                          title: Text(tr('advancedSettings')),
                                          leading: const Icon(
                                            Icons.tune_rounded,
                                          ),
                                          children: [
                                            ListTile(
                                              title: Text(
                                                tr('additionalOptions'),
                                              ),
                                              leading: const Icon(
                                                Icons
                                                    .settings_input_composite_rounded,
                                              ),
                                              onTap: () async {
                                                var values =
                                                    await showAdditionalOptionsDialog();
                                                handleAdditionalOptionChanges(
                                                  values,
                                                );
                                              },
                                            ),
                                            SwitchListTile(
                                              title: Text(tr('trackOnly')),
                                              value: trackOnly,
                                              onChanged: (val) {
                                                if (app != null) {
                                                  app.app.additionalSettings['trackOnly'] =
                                                      val;
                                                  appsProvider.saveApps([
                                                    app.app,
                                                  ]);
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                            SwitchListTile(
                                              title: Text(
                                                tr('versionDetection'),
                                              ),
                                              value: isVersionDetectionStandard,
                                              onChanged: (val) {
                                                if (app != null) {
                                                  app.app.additionalSettings['versionDetection'] =
                                                      val;
                                                  appsProvider.saveApps([
                                                    app.app,
                                                  ]);
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 150),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            _buildLegacyFullInfoColumn(
                              context,
                              app,
                              appsProvider,
                              highlightTouchTargets,
                              updating,
                            ),
                          ],
                        )),
          ),
          if (app != null &&
              !showAppWebpageFinal &&
              appsProvider.settingsProvider.plusEnableModernAppPage)
            AppDescriptionSlider(app: app),
        ],
      ),
      bottomSheet: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return _AppBottomBar(
            app: app,
            source: source,
            trackOnly: trackOnly,
            isVersionDetectionStandard: isVersionDetectionStandard,
            showAppWebpageFinal: showAppWebpageFinal,
            updating: updating,
            preferredSource: settings.preferredUpdateSource,
            allowThirdPartySources: settings.allowThirdPartySources,
            onSourceSelected: (String newSource) {
              settings.preferredUpdateSource = newSource;
            },
            onEditTags: () => _showTagEditor(app!),
            onInstallUpdate: () async {
              try {
                var successMessage = app?.app.installedVersion == null
                    ? tr('installed')
                    : tr('appsUpdated');
                AppHaptics.heavyImpact();

                // Handle different source types
                if (settings.preferredUpdateSource == 'play_store' ||
                    settings.preferredUpdateSource == 'aurora') {
                  // Open in store instead of downloading
                  await PlayStoreMirrorService.openInSource(
                    appId: app!.app.id,
                    source: settings.preferredUpdateSource,
                  );
                } else {
                  // Direct download (default, or fallback for any unknown source value)
                  var res = await appsProvider.downloadAndInstallLatestApps(
                    app?.app.id != null ? [app!.app.id] : [],
                    globalNavigatorKey.currentContext,
                  );
                  if (res.isNotEmpty && !trackOnly && mounted) {
                    showMessage(successMessage, context);
                  }
                  if (res.isNotEmpty && mounted) {
                    Navigator.of(context).pop();
                  }
                }
              } catch (e) {
                if (mounted) showError(e, context);
              }
            },
            onAdditionalOptions: () async {
              var values = await showAdditionalOptionsDialog();
              handleAdditionalOptionChanges(values);
            },
            onMarkUpdated: showMarkUpdatedDialog,
            onResetInstallStatus: () {
              app!.app.installedVersion = null;
              appsProvider.saveApps([app.app]);
            },
            onRemove: () {
              appsProvider
                  .removeAppsWithModal(context, app != null ? [app.app] : [])
                  .then((value) {
                    if (value == true && mounted) {
                      Navigator.of(context).pop();
                    }
                  });
            },
            onMore: () {
              _showAppDetailsDialog(context, app, appsProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppInMemory? app) {
    return AdaptiveSliverAppBar(
      pageId: 'app',
      automaticallyImplyLeading: !widget.isModal,
      leading: widget.isModal
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
      title: app?.name ?? tr('app'),
    );
  }

  Widget _buildMainInfo(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
  ) {
    var source = app != null
        ? SourceProvider().getSource(
            app.app.url,
            overrideSource: app.app.overrideSource,
          )
        : null;
    return Column(
      children: [
        const SizedBox(height: 20),
        if (app?.icon != null)
          GestureDetector(
            onTap: () => AppInstallService.openApp(app!.app.id),
            onLongPress: () {
              AppHaptics.heavyImpact();
              _showContextMenu(
                title: tr('appearance'),
                actions: [
                  if (app?.installedInfo != null)
                    MapEntry(
                      tr('openAppInfo'),
                      () => AppInstallService.openAppSettings(app!.app.id),
                    ),
                  MapEntry(
                    tr('appearance'),
                    () => pushRoute(context, const SettingsPage(initialTab: 0)),
                  ),
                ],
              );
            },
            child: Hero(
              tag: 'app_icon_${widget.appId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  appsProvider.settingsProvider.plusGlobalCornerRadius,
                ),
                child: Image.memory(
                  app!.icon!,
                  height: 120,
                  width: 120,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          app?.name ?? tr('app'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('author'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.author ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          child: Text(
            tr('byX', args: [app?.author ?? tr('unknown')]),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (source != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              source.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildUrlAndId(context, app),
      ],
    );
  }

  Widget _buildUrlAndId(BuildContext context, AppInMemory? app) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (app?.app.url == null) return;
            // For GitHub apps, open releases page instead of main repo
            String urlToOpen = app!.app.url;
            if (app.app.url.contains('github.com')) {
              final uri = Uri.parse(app.app.url);
              final pathSegments = uri.pathSegments;
              if (pathSegments.length >= 2) {
                final owner = pathSegments[0];
                final repo = pathSegments[1];
                urlToOpen = 'https://github.com/$owner/$repo/releases';
              }
            }
            launchUrlString(urlToOpen, mode: LaunchMode.externalApplication);
          },
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('sourceOptions'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.url ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              app?.app.url ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('appId'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.id ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          child: Text(
            app?.app.id ?? '',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    AppInMemory? app,
    bool updating,
    bool highlightTouchTargets,
    AppsProvider appsProvider,
  ) {
    bool installed = app?.app.installedVersion != null;
    bool upToDate = app?.app.installedVersion == app?.app.latestVersion;
    var changeLogFn = app != null ? getChangeLogFn(context, app.app) : null;
    final settings = appsProvider.settingsProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = plusSettings.plusGlobalCornerRadius;
    final statsContainer = Container(
      decoration: BoxDecoration(
        color:
            (isDark
                    ? Theme.of(context).colorScheme.surfaceContainerLow
                    : Theme.of(context).colorScheme.surface)
                .withOpacity(plusSettings.plusEnableGlassmorphism ? 0.6 : 1.0),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(
            plusSettings.plusEnableGlassmorphism ? 0.4 : 0.1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: Icons.install_mobile_rounded,
            label: tr('installed'),
            value: app?.app.installedVersion ?? tr('notInstalled'),
            isBold: true,
          ),
          const Divider(height: 24),
          _buildStatRow(
            context,
            icon: Icons.new_releases_rounded,
            label: tr('latest'),
            value: app?.app.latestVersion ?? tr('unknown'),
            valueColor: upToDate ? null : Theme.of(context).colorScheme.primary,
          ),
          const Divider(height: 24),
          _buildStatRow(
            context,
            icon: Icons.update_rounded,
            label: tr('lastCheck'),
            value:
                app?.app.lastUpdateCheck
                    ?.toLocal()
                    .toString()
                    .split('.')
                    .first ??
                tr('never'),
          ),
          if (changeLogFn != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: changeLogFn,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(tr('viewChangelog')),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (!plusSettings.plusEnableGlassmorphism) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: statsContainer,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: statsContainer,
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            tr('categories'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        CategoryEditorSelector(
          alignment: WrapAlignment.start,
          preselected: app?.app.categories != null
              ? app!.app.categories.toSet()
              : {},
          onSelected: (categories) {
            if (app != null) {
              app.app.categories = categories;
              appsProvider.saveApps([app.app]);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
  ) {
    if (app == null) return const SizedBox.shrink();

    final allTags = appsProvider
        .getAppValues()
        .expand((a) => a.app.tags)
        .toSet()
        .toList();
    allTags.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            tr('tags'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (app.app.tags.isEmpty)
          OutlinedButton.icon(
            onPressed: () async {
              final newTags = await showTagEditor(
                context: context,
                currentTags: app.app.tags,
                allTags: allTags,
              );
              if (newTags != null) {
                app.app.tags = newTags;
                appsProvider.saveApps([app.app]);
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(tr('addTags')),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...app.app.tags.map(
                (tag) => ActionChip(
                  label: Text(tag),
                  onPressed: () async {
                    final newTags = await showTagEditor(
                      context: context,
                      currentTags: app.app.tags,
                      allTags: allTags,
                    );
                    if (newTags != null) {
                      app.app.tags = newTags;
                      appsProvider.saveApps([app.app]);
                    }
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text(tr('add')),
                onPressed: () async {
                  final newTags = await showTagEditor(
                    context: context,
                    currentTags: app.app.tags,
                    allTags: allTags,
                  );
                  if (newTags != null) {
                    app.app.tags = newTags;
                    appsProvider.saveApps([app.app]);
                  }
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
  ) {
    final about = app?.app.additionalSettings['about'];
    if (about == null ||
        about.toString().isEmpty ||
        appsProvider.settingsProvider.plusEnablePopupSlider)
      return const SizedBox.shrink();
    final settings = appsProvider.settingsProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            tr('about'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Builder(
          builder: (ctx) {
            final aboutRadius = plusSettings.plusGlobalCornerRadius;
            final aboutContainer = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? Theme.of(ctx).colorScheme.surfaceContainerLow
                            : Theme.of(ctx).colorScheme.surface)
                        .withOpacity(
                          plusSettings.plusEnableGlassmorphism ? 0.6 : 1.0,
                        ),
                borderRadius: BorderRadius.circular(aboutRadius),
                border: Border.all(
                  color: Theme.of(ctx).colorScheme.outlineVariant.withOpacity(
                    plusSettings.plusEnableGlassmorphism ? 0.4 : 0.1,
                  ),
                ),
              ),
              child: MarkdownBody(
                data: about.toString(),
                onTapLink: (text, href, title) => href != null
                    ? launchUrlString(
                        href,
                        mode: LaunchMode.externalApplication,
                      )
                    : null,
                extensionSet: md.ExtensionSet(
                  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  [
                    md.EmojiSyntax(),
                    ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                  ],
                ),
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
              ),
            );
            if (!plusSettings.plusEnableGlassmorphism) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(aboutRadius),
                child: aboutContainer,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(aboutRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: aboutContainer,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAppDetailsDialog(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => GlassDialog(
        title: app?.name ?? '',
        content: Column(
          children: [
            if (app?.icon != null)
              Image.memory(app!.icon!, height: 80, gaplessPlayback: true),
            const SizedBox(height: 16),
            Text(
              app?.app.id ?? '',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyFullInfoColumn(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
    bool highlightTouchTargets,
    bool updating,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        FutureBuilder(
          future: appsProvider.updateAppIcon(app?.app.id),
          builder: (ctx, val) {
            return app?.icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: app == null
                            ? null
                            : () => AppInstallService.openApp(app.app.id),
                        onLongPress: () {
                          AppHaptics.heavyImpact();
                          _showContextMenu(
                            title: tr('appearance'),
                            actions: [
                              if (app?.installedInfo != null)
                                MapEntry(
                                  tr('openAppInfo'),
                                  () => AppInstallService.openAppSettings(
                                    app!.app.id,
                                  ),
                                ),
                              MapEntry(tr('appearance'), () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsPage(initialTab: 0),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                        child: Hero(
                          tag: 'app_icon_${widget.appId}',
                          child: Image.memory(
                            app!.icon!,
                            height: 150,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container();
          },
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            app?.name ?? tr('app'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        GestureDetector(
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('author'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.author ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              tr('byX', args: [app?.author ?? tr('unknown')]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            if (app?.app.url == null) return;
            // For GitHub apps, open releases page instead of main repo
            String urlToOpen = app!.app.url;
            if (app.app.url.contains('github.com')) {
              final uri = Uri.parse(app.app.url);
              final pathSegments = uri.pathSegments;
              if (pathSegments.length >= 2) {
                final owner = pathSegments[0];
                final repo = pathSegments[1];
                urlToOpen = 'https://github.com/$owner/$repo/releases';
              }
            }
            launchUrlString(urlToOpen, mode: LaunchMode.externalApplication);
          },
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('sourceOptions'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.url ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              app?.app.url ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        GestureDetector(
          onLongPress: () {
            AppHaptics.heavyImpact();
            _showContextMenu(
              title: tr('appId'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.id ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                }),
              ],
            );
          },
          child: Text(
            app?.app.id ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        _buildLegacyInfoColumn(
          context,
          app,
          appsProvider,
          highlightTouchTargets,
          updating,
        ),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildLegacyInfoColumn(
    BuildContext context,
    AppInMemory? app,
    AppsProvider appsProvider,
    bool highlightTouchTargets,
    bool updating,
  ) {
    String versionLines = '';
    bool installed = app?.app.installedVersion != null;
    bool upToDate = app?.app.installedVersion == app?.app.latestVersion;
    if (installed) {
      versionLines = '${app?.app.installedVersion} ${tr('installed')}';
      if (upToDate) {
        versionLines += '/${tr('latest')}';
      }
    } else {
      versionLines = tr('notInstalled');
    }
    if (!upToDate) {
      versionLines += '\n${app?.app.latestVersion} ${tr('latest')}';
    }
    String infoLines = tr(
      'lastUpdateCheckX',
      args: [
        app?.app.lastUpdateCheck == null
            ? tr('never')
            : '${app?.app.lastUpdateCheck?.toLocal()}',
      ],
    );
    if (app?.app.additionalSettings['trackOnly'] == true) {
      infoLines = '${tr('xIsTrackOnly', args: [tr('app')])}\n$infoLines';
    }
    if (app?.app != null && SourceUtils.isVersionPseudo(app!.app)) {
      infoLines = '${tr('pseudoVersionInUse')}\n$infoLines';
    }
    if ((app?.app.apkUrls.length ?? 0) > 0) {
      infoLines =
          '$infoLines\n${app?.app.apkUrls.length == 1 ? app?.app.apkUrls[0].key : plural('apk', app?.app.apkUrls.length ?? 0)}';
    }
    var changeLogFn = app != null ? getChangeLogFn(context, app.app) : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onLongPress: () {
                  AppHaptics.heavyImpact();
                  _showContextMenu(
                    title: tr('versionOptions'),
                    actions: [
                      MapEntry(
                        tr('update'),
                        () => appsProvider.checkUpdate(app!.app.id),
                      ),
                    ],
                  );
                },
                child: Text(
                  versionLines,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              changeLogFn != null || app?.app.releaseDate != null
                  ? GestureDetector(
                      onTap: changeLogFn,
                      child: Text(
                        app?.app.releaseDate == null
                            ? tr('changes')
                            : DateFormat(
                                'MMM d, yyyy • h:mm a',
                              ).format(app!.app.releaseDate!.toLocal()),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          decoration: changeLogFn != null
                              ? TextDecoration.underline
                              : null,
                          fontStyle: changeLogFn != null
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Text(
          infoLines,
          textAlign: TextAlign.center,
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
        ),
        if (app?.app.apkUrls.isNotEmpty == true ||
            app?.app.otherAssetUrls.isNotEmpty == true)
          GestureDetector(
            onTap: app?.app == null || updating
                ? null
                : () async {
                    try {
                      await appsProvider.downloadAppAssets([
                        app!.app.id,
                      ], context);
                    } catch (e) {
                      showError(e, context);
                    }
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: highlightTouchTargets
                        ? (Theme.of(context).brightness == Brightness.light
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).primaryColorLight)
                              .withOpacity(
                                Theme.of(context).brightness == Brightness.light
                                    ? 20 / 255
                                    : 40 / 255,
                              )
                        : null,
                  ),
                  padding: highlightTouchTargets
                      ? const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6)
                      : const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 6),
                  margin: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 0),
                  child: Text(
                    tr(
                      'downloadX',
                      args: [lowerCaseIfEnglish(tr('releaseAsset'))],
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      decoration: TextDecoration.underline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CategoryEditorSelector(
            alignment: WrapAlignment.center,
            preselected: app?.app.categories != null
                ? app!.app.categories.toSet()
                : {},
            onSelected: (categories) {
              if (app != null) {
                app.app.categories = categories;
                appsProvider.saveApps([app.app]);
              }
            },
          ),
        ),
        if (app?.app.additionalSettings['about'] is String &&
            app?.app.additionalSettings['about'].isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 48),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: app?.app.additionalSettings['about'] ?? '',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('copiedToClipboard'))),
                  );
                },
                child: MarkdownBody(
                  data: app?.app.additionalSettings['about'],
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrlString(
                        href,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AppWebView extends StatefulWidget {
  const _AppWebView({required this.url, required this.backgroundColor});

  final String url;
  final Color backgroundColor;

  @override
  State<_AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<_AppWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true && mounted) {
              showError(
                ObtainiumError(error.description, unexpected: true),
                context,
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) =>
              !(request.url.startsWith('http://') ||
                  request.url.startsWith('https://') ||
                  request.url.startsWith('ftp://') ||
                  request.url.startsWith('ftps://'))
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _controller.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(key: ObjectKey(_controller), controller: _controller);
  }
}

/// Returns true if the app has a pending update using the same reconciliation
/// logic as AppUpdateService, so the install button state is consistent.
bool _appNeedsUpdate(AppInMemory? app) {
  if (app == null) return false;
  final inst = app.app.installedVersion;
  final latest = app.app.latestVersion;
  if (inst == null) return true; // not installed yet
  if (inst == latest) return false;
  return reconcileVersionDifferences(inst, latest)?.key != true;
}

class _AppBottomBar extends StatefulWidget {
  const _AppBottomBar({
    required this.app,
    required this.source,
    required this.trackOnly,
    required this.isVersionDetectionStandard,
    required this.showAppWebpageFinal,
    required this.updating,
    required this.onInstallUpdate,
    required this.onAdditionalOptions,
    required this.onMarkUpdated,
    required this.onResetInstallStatus,
    required this.onRemove,
    required this.onMore,
    required this.onSourceSelected,
    required this.onEditTags,
    required this.preferredSource,
    required this.allowThirdPartySources,
  });

  final AppInMemory? app;
  final AppSource? source;
  final bool trackOnly;
  final bool isVersionDetectionStandard;
  final bool showAppWebpageFinal;
  final bool updating;
  final VoidCallback onInstallUpdate;
  final VoidCallback onAdditionalOptions;
  final VoidCallback onMarkUpdated;
  final VoidCallback onResetInstallStatus;
  final VoidCallback onRemove;
  final VoidCallback onMore;
  final VoidCallback onEditTags;
  final Function(String) onSourceSelected;
  final String preferredSource;
  final bool allowThirdPartySources;

  @override
  State<_AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<_AppBottomBar> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final barRadius = radius.clamp(24.0, 48.0);

    return Consumer<AppsProvider>(
      builder: (context, appsProvider, _) {
        final currentApp = widget.app != null
            ? appsProvider.apps[widget.app!.app.id]
            : null;
        final busy = currentApp?.downloadProgress != null || widget.updating;

        final barContent = Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(enableGlass ? 0.75 : 1.0),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(barRadius),
            ),
            border: Border(
              top: BorderSide(
                color: enableGlass
                    ? colorScheme.onSurface.withOpacity(0.18)
                    : colorScheme.outline.withOpacity(AppOpacity.subtle),
                width: 1.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Glass sheen
              if (enableGlass)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Source selector row
                    if (widget.allowThirdPartySources && !widget.trackOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tr('preferredUpdateSource'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: widget.preferredSource,
                                underline: const SizedBox.shrink(),
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                dropdownColor: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                onChanged: busy
                                    ? null
                                    : (String? newValue) {
                                        if (newValue != null) {
                                          widget.onSourceSelected(newValue);
                                        }
                                      },
                                items: [
                                  DropdownMenuItem(
                                    value: 'direct',
                                    child: Text(tr('direct')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'play_store',
                                    child: Text(tr('playStore')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'aurora',
                                    child: Text(tr('auroraStore')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Tags row
                    if (widget.app != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              size: 20,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: widget.app!.app.tags.isEmpty
                                      ? [
                                          Text(
                                            tr('noTags'),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  opacity: 0.6,
                                                ),
                                          ),
                                        ]
                                      : widget.app!.app.tags
                                            .map(
                                              (tag) => Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .secondaryContainer
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    tag,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: busy ? null : widget.onEditTags,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: tr('addTags'),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.source != null &&
                                    widget
                                        .source!
                                        .combinedAppSpecificSettingFormItems
                                        .isNotEmpty)
                                  _buildCircularAction(
                                    icon: Icons.edit_rounded,
                                    onPressed: busy
                                        ? null
                                        : widget.onAdditionalOptions,
                                    tooltip: tr('additionalOptions'),
                                    colorScheme: colorScheme,
                                  ),
                                if (widget.app != null &&
                                    currentApp?.installedInfo != null)
                                  _buildCircularAction(
                                    icon: Icons.settings_rounded,
                                    onPressed: () => appsProvider
                                        .openAppSettings(widget.app!.app.id),
                                    tooltip: tr('settings'),
                                    colorScheme: colorScheme,
                                  ),
                                if (widget.app != null &&
                                    widget.showAppWebpageFinal)
                                  _buildCircularAction(
                                    icon: Icons.more_horiz_rounded,
                                    onPressed: widget.onMore,
                                    tooltip: tr('more'),
                                    colorScheme: colorScheme,
                                  ),
                                if (_appNeedsUpdate(widget.app) &&
                                    !widget.isVersionDetectionStandard &&
                                    !widget.trackOnly)
                                  _buildCircularAction(
                                    icon: Icons.done_rounded,
                                    onPressed: busy
                                        ? null
                                        : widget.onMarkUpdated,
                                    tooltip: tr('markUpdated'),
                                    colorScheme: colorScheme,
                                  ),
                                if ((!widget.isVersionDetectionStandard ||
                                        widget.trackOnly) &&
                                    widget.app?.app.installedVersion != null &&
                                    widget.app?.app.installedVersion ==
                                        widget.app?.app.latestVersion)
                                  _buildCircularAction(
                                    icon: Icons.restore_rounded,
                                    onPressed: busy
                                        ? null
                                        : widget.onResetInstallStatus,
                                    tooltip: tr('resetInstallStatus'),
                                    colorScheme: colorScheme,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Expanded update/install button
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _isButtonPressed = true),
                            onTapUp: (_) =>
                                setState(() => _isButtonPressed = false),
                            onTapCancel: () =>
                                setState(() => _isButtonPressed = false),
                            child: AnimatedScale(
                              scale: _isButtonPressed ? 0.94 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOutCubic,
                              child: FilledButton(
                                onPressed: !busy && _appNeedsUpdate(widget.app)
                                    ? widget.onInstallUpdate
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: widget.updating
                                      ? SizedBox(
                                          key: const ValueKey('btn_spinner'),
                                          width: 24,
                                          height: 24,
                                          child: ExpressiveCircularProgressIndicator(
                                            value:
                                                currentApp?.downloadProgress !=
                                                        null &&
                                                    currentApp!
                                                            .downloadProgress! >=
                                                        0
                                                ? currentApp.downloadProgress! /
                                                      100
                                                : null,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : Row(
                                          key: const ValueKey('btn_content'),
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              widget.preferredSource ==
                                                          'play_store' ||
                                                      widget.preferredSource ==
                                                          'aurora'
                                                  ? Icons.open_in_new_rounded
                                                  : widget
                                                            .app
                                                            ?.app
                                                            .installedVersion ==
                                                        null
                                                  ? Icons.download_rounded
                                                  : Icons.system_update_rounded,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                widget.preferredSource ==
                                                        'play_store'
                                                    ? tr('playStore')
                                                    : widget.preferredSource ==
                                                          'aurora'
                                                    ? 'Aurora Store'
                                                    : widget
                                                              .app
                                                              ?.app
                                                              .installedVersion ==
                                                          null
                                                    ? !widget.trackOnly
                                                          ? tr('install')
                                                          : tr('markInstalled')
                                                    : !widget.trackOnly
                                                    ? tr('update')
                                                    : tr('markUpdated'),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        _buildCircularAction(
                          icon: Icons.delete_outline_rounded,
                          onPressed: busy ? null : widget.onRemove,
                          tooltip: tr('remove'),
                          colorScheme: colorScheme,
                          color: colorScheme.error,
                          containerColor: colorScheme.errorContainer
                              .withOpacity(0.3),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          axis: Axis.vertical,
                          child: child,
                        ),
                      ),
                      child:
                          currentApp?.downloadProgress != null &&
                              currentApp!.downloadProgress! >= 0
                          ? Padding(
                              key: const ValueKey('progress_bar'),
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ExpressiveProgressIndicator(
                                      value: currentApp.downloadProgress! / 100,
                                      height: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () => appsProvider
                                        .cancelDownload(widget.app!.app.id),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      tr('cancel'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : currentApp?.downloadProgress != null
                          ? Padding(
                              key: const ValueKey('installing_bar'),
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: ExpressiveProgressIndicator(
                                      value: null,
                                      height: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    tr('installing'),
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no_progress')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return ConditionalBlur(
          enabled: enableGlass,
          sigma: 24,
          child: barContent,
        );
      },
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required ColorScheme colorScheme,
    Color? color,
    Color? containerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  containerColor ??
                  colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: color ?? colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
