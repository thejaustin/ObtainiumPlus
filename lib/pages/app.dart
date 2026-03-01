import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/apps/app_changelog.dart';
import 'package:obtainium/components/apps/app_description_slider.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/play_store_mirror_service.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppPage extends StatefulWidget {
  const AppPage({
    super.key,
    required this.appId,
    this.showOppositeOfPreferredView = false,
    this.isModal = false,
  });

  final String appId;
  final bool showOppositeOfPreferredView;
  final bool isModal;

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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              ...actions.map((action) => ListTile(
                title: Text(action.key),
                onTap: () {
                  Navigator.pop(context);
                  action.value();
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    final showAppWebpage = context.select<SettingsProvider, bool>((sp) => sp.showAppWebpage);
    final checkUpdateOnDetailPage = context.select<SettingsProvider, bool>((sp) => sp.checkUpdateOnDetailPage);
    final highlightTouchTargets = context.select<SettingsProvider, bool>((sp) => sp.highlightTouchTargets);
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
          appsProvider.saveApps([appsProvider.apps[id]!.app]);
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
          return AlertDialog(
            title: Text(tr('alreadyUpToDateQuestion')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(tr('no')),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
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
        appsProvider.saveApps([app.app]).then((value) {
          getUpdate(app.app.id, resetVersion: versionDetectionEnabled);
        });
      }
    }

    return Scaffold(
      appBar: showAppWebpageFinal ? (widget.isModal ? null : AppBar()) : null,
      backgroundColor: widget.isModal ? Colors.transparent : Theme.of(context).colorScheme.surface,
      floatingActionButton: appsProvider.settingsProvider.plusShowLegacyUIComparison
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Above bottom bar
              child: FloatingActionButton.small(
                heroTag: 'app_page_ui_comparison_toggle',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  appsProvider.settingsProvider.plusEnableModernAppPage = !appsProvider.settingsProvider.plusEnableModernAppPage;
                },
                child: Icon(appsProvider.settingsProvider.plusEnableModernAppPage 
                    ? Icons.visibility_outlined 
                    : Icons.visibility_off_outlined),
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
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      )
                    : const SizedBox.shrink())
                : (appsProvider.settingsProvider.plusEnableModernAppPage
                    ? CustomScrollView(
                        slivers: [
                          if (widget.isModal) _buildModalHandle(context),
                          _buildSliverAppBar(context, app),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  _buildMainInfo(context, app, appsProvider),
                                  const SizedBox(height: 24),
                                  _buildStatsSection(context, app, updating, highlightTouchTargets, appsProvider),
                                  const SizedBox(height: 32),
                                  _buildCategorySection(context, app, appsProvider),
                                  const SizedBox(height: 32),
                                  _buildAboutSection(context, app, appsProvider),
                                  const SizedBox(height: 150), // Spacing for bottom bar
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildLegacyFullInfoColumn(context, app, appsProvider, highlightTouchTargets, updating),
                        ],
                      )),
          ),
          if (app != null && !showAppWebpageFinal && appsProvider.settingsProvider.plusEnableModernAppPage)
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
            onInstallUpdate: () async {
              try {
                var successMessage = app?.app.installedVersion == null
                    ? tr('installed')
                    : tr('appsUpdated');
                HapticFeedback.heavyImpact();
                
                // Handle different source types
                if (settings.preferredUpdateSource == 'play_store' ||
                    settings.preferredUpdateSource == 'aurora') {
                  // Open in store instead of downloading
                  await PlayStoreMirrorService.openInSource(
                    appId: app!.app.id,
                    source: settings.preferredUpdateSource,
                  );
                } else if (settings.preferredUpdateSource == 'github' ||
                    settings.preferredUpdateSource == 'apkpure') {
                  // Open in browser
                  final uri = Uri.parse(
                    settings.preferredUpdateSource == 'github'
                        ? 'https://github.com/search?q=${app!.app.id}'
                        : 'https://apkpure.com/any/${app!.app.id}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } else {
                  // Direct download (default)
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

  Widget _buildModalHandle(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppInMemory? app) {
    return SliverAppBar.large(
      automaticallyImplyLeading: !widget.isModal,
      leading: widget.isModal
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
      title: Text(app?.name ?? tr('app')),
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
    );
  }

  Widget _buildMainInfo(BuildContext context, AppInMemory? app, AppsProvider appsProvider) {
    var source = app != null ? SourceProvider().getSource(app.app.url, overrideSource: app.app.overrideSource) : null;
    return Column(
      children: [
        const SizedBox(height: 20),
        if (app?.icon != null)
          GestureDetector(
            onTap: () => AppInstallService.openApp(app!.app.id),
            onLongPress: () {
              HapticFeedback.heavyImpact();
              _showContextMenu(
                title: tr('appearance'),
                actions: [
                  if (app?.installedInfo != null)
                    MapEntry(tr('openAppInfo'), () => AppInstallService.openAppSettings(app!.app.id)),
                  MapEntry(tr('appearance'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage(initialTab: 0)))),
                ],
              );
            },
            child: Hero(
              tag: 'app_icon_${widget.appId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(app!.icon!, height: 120, width: 120, gaplessPlayback: true),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          app?.name ?? tr('app'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showContextMenu(
              title: tr('author'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.author ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
                }),
              ],
            );
          },
          child: Text(
            tr('byX', args: [app?.author ?? tr('unknown')]),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          onTap: () => app?.app.url != null ? launchUrlString(app!.app.url, mode: LaunchMode.externalApplication) : null,
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showContextMenu(
              title: tr('sourceOptions'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.url ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
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
            HapticFeedback.heavyImpact();
            _showContextMenu(
              title: tr('appId'),
              actions: [
                MapEntry(tr('copy'), () {
                  Clipboard.setData(ClipboardData(text: app?.app.id ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
                }),
              ],
            );
          },
          child: Text(
            app?.app.id ?? '',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, AppInMemory? app, bool updating, bool highlightTouchTargets, AppsProvider appsProvider) {
    bool installed = app?.app.installedVersion != null;
    bool upToDate = app?.app.installedVersion == app?.app.latestVersion;
    var changeLogFn = app != null ? getChangeLogFn(context, app.app) : null;
    final settings = appsProvider.settingsProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
          sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark 
                ? Theme.of(context).colorScheme.surfaceContainerLow 
                : Theme.of(context).colorScheme.surface)
              .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 1.0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.1,
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
                label: tr('lastChecked'),
                value: app?.app.lastUpdateCheck?.toLocal().toString().split('.').first ?? tr('never'),
              ),
              if (changeLogFn != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: changeLogFn,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text(tr('viewChanges')),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildCategorySection(BuildContext context, AppInMemory? app, AppsProvider appsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(tr('categories'), style: Theme.of(context).textTheme.titleSmall),
        ),
        CategoryEditorSelector(
          alignment: WrapAlignment.start,
          preselected: app?.app.categories != null ? app!.app.categories.toSet() : {},
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

  Widget _buildAboutSection(BuildContext context, AppInMemory? app, AppsProvider appsProvider) {
    final about = app?.app.additionalSettings['about'];
    if (about == null || about.toString().isEmpty || appsProvider.settingsProvider.plusEnablePopupSlider) return const SizedBox.shrink();
    final settings = appsProvider.settingsProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(tr('about'), style: Theme.of(context).textTheme.titleSmall),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
              sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark 
                    ? Theme.of(context).colorScheme.surfaceContainerLow 
                    : Theme.of(context).colorScheme.surface)
                  .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 1.0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.1,
                  ),
                ),
              ),
              child: MarkdownBody(
                data: about.toString(),
                onTapLink: (text, href, title) => href != null ? launchUrlString(href, mode: LaunchMode.externalApplication) : null,
                extensionSet: md.ExtensionSet(
                  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
                ),
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAppDetailsDialog(BuildContext context, AppInMemory? app, AppsProvider appsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          scrollable: true,
          content: Column(
            children: [
              if (app?.icon != null) Image.memory(app!.icon!, height: 80, gaplessPlayback: true),
              const SizedBox(height: 16),
              Text(app?.app.id ?? '', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          title: Text(app?.name ?? ''),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('ok'))),
          ],
        );
      },
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
                          HapticFeedback.heavyImpact();
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
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsPage(initialTab: 0),
                                    ),
                                  );
                                },
                              ),
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
            HapticFeedback.heavyImpact();
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
            if (app?.app.url != null) {
              launchUrlString(
                app?.app.url ?? '',
                mode: LaunchMode.externalApplication,
              );
            }
          },
          onLongPress: () {
            HapticFeedback.heavyImpact();
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
            HapticFeedback.heavyImpact();
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
        _buildLegacyInfoColumn(context, app, appsProvider, highlightTouchTargets, updating),
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
                  HapticFeedback.heavyImpact();
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
                            : app!.app.releaseDate!.toLocal().toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall!
                            .copyWith(
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
                              .withAlpha(
                                Theme.of(context).brightness ==
                                        Brightness.light
                                    ? 20
                                    : 40,
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

class _AppBottomBar extends StatelessWidget {
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
  final Function(String) onSourceSelected;
  final String preferredSource;
  final bool allowThirdPartySources;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppsProvider>(
      builder: (context, appsProvider, _) {
        final currentApp = app != null ? appsProvider.apps[app!.app.id] : null;
        final busy = currentApp?.downloadProgress != null || updating;
        final areDownloadsRunning = appsProvider.areDownloadsRunning();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Source selector row
              if (allowThirdPartySources && !trackOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.store_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr('preferredUpdateSource'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: preferredSource,
                        underline: const SizedBox.shrink(),
                        onChanged: busy
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  onSourceSelected(newValue);
                                }
                              },
                        items: [
                          DropdownMenuItem(value: 'direct', child: Text(tr('direct'))),
                          DropdownMenuItem(value: 'play_store', child: Text(tr('playStore'))),
                          DropdownMenuItem(value: 'aurora', child: const Text('Aurora Store')),
                          DropdownMenuItem(value: 'github', child: const Text('GitHub')),
                          DropdownMenuItem(value: 'apkpure', child: const Text('APKPure')),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (source != null &&
                                source!
                                    .combinedAppSpecificSettingFormItems
                                    .isNotEmpty)
                              IconButton(
                                onPressed: busy ? null : onAdditionalOptions,
                                tooltip: tr('additionalOptions'),
                                icon: const Icon(Icons.edit),
                              ),
                            if (app != null &&
                                currentApp?.installedInfo != null)
                              IconButton(
                                onPressed: () =>
                                    appsProvider.openAppSettings(app!.app.id),
                                icon: const Icon(Icons.settings),
                                tooltip: tr('settings'),
                              ),
                            if (app != null && showAppWebpageFinal)
                              IconButton(
                                onPressed: onMore,
                                icon: const Icon(Icons.more_horiz),
                                tooltip: tr('more'),
                              ),
                            if (app?.app.installedVersion != null &&
                                app?.app.installedVersion !=
                                    app?.app.latestVersion &&
                                !isVersionDetectionStandard &&
                                !trackOnly)
                              IconButton(
                                onPressed: busy ? null : onMarkUpdated,
                                tooltip: tr('markUpdated'),
                                icon: const Icon(Icons.done),
                              ),
                            if ((!isVersionDetectionStandard || trackOnly) &&
                                app?.app.installedVersion != null &&
                                app?.app.installedVersion ==
                                    app?.app.latestVersion)
                              IconButton(
                                onPressed: busy ? null : onResetInstallStatus,
                                icon: const Icon(Icons.restore_rounded),
                                tooltip: tr('resetInstallStatus'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      flex: 2,
                      child: FilledButton(
                        onPressed: !updating &&
                                (app?.app.installedVersion == null ||
                                    app?.app.installedVersion !=
                                        app?.app.latestVersion) &&
                                !areDownloadsRunning
                            ? onInstallUpdate
                            : null,
                        child: Text(
                          app?.app.installedVersion == null
                              ? !trackOnly
                                    ? tr('install')
                                    : tr('markInstalled')
                              : !trackOnly
                              ? tr('update')
                              : tr('markUpdated'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      onPressed: busy ? null : onRemove,
                      tooltip: tr('remove'),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
              if (currentApp?.downloadProgress != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: LinearProgressIndicator(
                    value: currentApp!.downloadProgress! >= 0
                        ? currentApp.downloadProgress! / 100
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
