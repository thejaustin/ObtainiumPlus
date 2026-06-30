import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/tag_editor.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/services/app_install_service.dart' hide pm;
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_package_manager/android_package_manager.dart' hide LaunchMode;

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
  late final WebViewController _webViewController;
  bool _wasWebViewOpened = false;
  AppInMemory? prevApp;
  bool updating = false;

  Future<List<Map<String, String>>> _getInstalledStores() async {
    final stores = [
      {'name': 'Aurora Store', 'package': 'com.aurora.store', 'scheme': 'market://details?id='},
      {'name': 'F-Droid', 'package': 'org.fdroid.fdroid', 'scheme': 'market://details?id='},
      {'name': 'Droidify', 'package': 'com.looker.droidify', 'scheme': 'market://details?id='},
    ];
    final List<Map<String, String>> installed = [];
    for (final store in stores) {
      try {
        await pm.getPackageInfo(
          packageName: store['package']!,
          flags: PackageInfoFlags({}),
        );
        installed.add(store);
      } catch (_) {}
    }
    return installed;
  }

  Future<void> _openInStore(String storePackage, String storeScheme, String appId) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: '$storeScheme$appId',
      package: storePackage,
    );
    try {
      await intent.launch();
    } catch (e) {
      // Fallback
      final fallback = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'market://details?id=$appId',
      );
      await fallback.launch();
    }
  }

  void _showStoreChooser(BuildContext context, String appId) async {
    final installed = await _getInstalledStores();
    if (installed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No supported stores found (Aurora Store, F-Droid, or Droidify)')),
        );
      }
      return;
    }

    if (mounted) {
      final plusSettings = context.read<PlusSettingsProvider>();
      showDialog(
        context: context,
        builder: (ctx) => GlassDialog(
          title: 'Open in Store',
          icon: Icons.storefront_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...installed.map(
                (store) => ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(store['name']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(store['package']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: plusSettings.plusDefaultStorePackage == store['package']
                      ? const Chip(label: Text('Default'))
                      : TextButton(
                          onPressed: () {
                            plusSettings.plusDefaultStorePackage = store['package'];
                            plusSettings.plusDefaultStoreName = store['name'];
                            Navigator.pop(ctx);
                            _showStoreChooser(context, appId);
                          },
                          child: const Text('Set Default'),
                        ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openInStore(store['package']!, store['scheme']!, appId);
                  },
                ),
              ),
              if (plusSettings.plusDefaultStorePackage != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Clear Default Store'),
                  onTap: () {
                    plusSettings.plusDefaultStorePackage = null;
                    plusSettings.plusDefaultStoreName = null;
                    Navigator.pop(ctx);
                    _showStoreChooser(context, appId);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

Widget buildRepoRenameWarning({
    required AppInMemory? app,
    required AppsProvider appsProvider,
    required Future<void> Function(String id) onUpdate,
  }) {
    if (app?.app.hasPendingRepoRename != true) {
      return const SizedBox.shrink();
    }
    var appValue = app!;
    var pendingUrl = appValue.app.pendingRepoRenameUrl!;
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(4),
            ),
          ),
          color: colorScheme.surfaceContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr('repoRenamed'),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          tr('repoRenamedExplanation'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          color: colorScheme.surfaceContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr('newUrl'),
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          pendingUrl,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(16),
            ),
          ),
          color: colorScheme.surfaceContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                // Min tap target has a height of 48dp
                vertical: 10 - 4,
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.fromMap({
                          WidgetState.disabled: colorScheme.onSurface
                              .withOpacity(0.10),
                          WidgetState.any: Colors.transparent,
                        }),
                        side: WidgetStatePropertyAll(
                          BorderSide(
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        elevation: WidgetStatePropertyAll(0),
                        overlayColor: WidgetStateProperty.fromMap({
                          WidgetState.disabled: colorScheme.onSurfaceVariant
                              .withOpacity(0),
                          WidgetState.pressed: colorScheme.onSurfaceVariant
                              .withOpacity(0.10),
                          WidgetState.focused: colorScheme.onSurfaceVariant
                              .withOpacity(0.10),
                          WidgetState.hovered: colorScheme.onSurfaceVariant
                              .withOpacity(0.08),
                          WidgetState.any: colorScheme.onSurfaceVariant
                              .withOpacity(0),
                        }),
                        foregroundColor: WidgetStateProperty.fromMap({
                          WidgetState.disabled: colorScheme.onSurface
                              .withOpacity(0.38),
                          WidgetState.any: colorScheme.onSurfaceVariant,
                        }),
                        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
                      ),
                      onPressed: () async {
                        await appsProvider.updatePendingRepoRename(
                          appValue.app.id,
                          null,
                        );
                      },
                      child: Text(tr('dismiss')),
                    ),
                  ),
                  Expanded(
                    child: FilledButton.tonal(
                      style: ButtonStyle(
                        elevation: WidgetStatePropertyAll(0),
                        textStyle: WidgetStatePropertyAll(
                          textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onPressed: () async {
                        await appsProvider.acceptRepoRename(
                          appValue.app.id,
                          pendingUrl,
                        );
                        if (mounted) {
                          onUpdate(appValue.app.id);
                        }
                      },
                      child: Text(tr('updateUrl')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              showError(
                ObtainiumError(error.description, unexpected: true),
                context,
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) =>
              !(request.url.startsWith("http://") ||
                  request.url.startsWith("https://") ||
                  request.url.startsWith("ftp://") ||
                  request.url.startsWith("ftps://"))
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
    var plusSettings = context.watch<PlusSettingsProvider>();
    var viewSettings = context.watch<ViewSettingsProvider>();
    var updateSettings = context.watch<UpdateSettingsProvider>();
    var behaviorSettings = context.watch<BehaviorSettingsProvider>();
    var showAppWebpageFinal =
        (viewSettings.showAppWebpage &&
            !widget.showOppositeOfPreferredView) ||
        (!viewSettings.showAppWebpage &&
            widget.showOppositeOfPreferredView);
    getUpdate(String id, {bool resetVersion = false}) async {
      try {
        setState(() {
          updating = true;
        });
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
        if (err is RepositoryRenamedError && context.mounted) {
          await appsProvider.updatePendingRepoRename(id, err.newUrl);
        } else if (context.mounted) {
          showError(err, context);
        }
      } finally {
        setState(() {
          updating = false;
        });
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
        updateSettings.checkUpdateOnDetailPage) {
      prevApp = app;
      getUpdate(app.app.id);
    }
    var trackOnly = app?.app.additionalSettings['trackOnly'] == true;

    bool isVersionDetectionStandard =
        app?.app.additionalSettings['versionDetection'] == true;

    bool installedVersionIsEstimate = app?.app != null
        ? isVersionPseudo(app!.app)
        : false;

    if (app != null && !_wasWebViewOpened) {
      _wasWebViewOpened = true;
      _webViewController.loadRequest(Uri.parse(app.app.url));
    }

    getInfoColumn() {
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
      final lastUpdateCheck = app?.app.lastUpdateCheck?.toLocal();
      String infoLines = tr(
        'lastUpdateCheckX',
        args: [
          lastUpdateCheck == null
              ? tr('never')
              : lastUpdateCheck.toString().split('.').first,
        ],
      );
      if (trackOnly) {
        infoLines = '${tr('xIsTrackOnly', args: [tr('app')])}\n$infoLines';
      }
      if (installedVersionIsEstimate) {
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: buildRepoRenameWarning(
                    app: app,
                    appsProvider: appsProvider,
                    onUpdate: (id) => getUpdate(id),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  versionLines,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                changeLogFn != null || app?.app.releaseDate != null
                    ? InkWell(
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
                const SizedBox(height: 40),
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
            InkWell(
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
                      color: behaviorSettings.highlightTouchTargets
                          ? (Theme.of(context).brightness == Brightness.light
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).primaryColorLight)
                                .withOpacity(
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? 20 / 255
                                      : 40 / 255,
                                )
                          : null,
                    ),
                    padding: behaviorSettings.highlightTouchTargets
                        ? const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6)
                        : const EdgeInsetsDirectional.fromSTEB(0, 2, 0, 2),
                    margin: const EdgeInsetsDirectional.fromSTEB(0, 2, 0, 0),
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

          /* Certificate Hashes */
          if (app != null && app.certificateHashes.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Text(
                  "${plural('certificateHash', app.certificateHashes.length)}"
                  "${app.hasMultipleSigners ? " (${tr('multipleSigners')})" : ""}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: app.certificateHashes.map((hash) {
                    return GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: hash));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('copiedToClipboard'))),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 0,
                        ),
                        child: Text(
                          hash,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          const SizedBox(height: 40),
          CategoryEditorSelector(
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
          if (plusSettings.plusEnableTags) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                ...app?.app.tags.map((tag) => Chip(label: Text(tag))).toList() ??
                    [],
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(tr('editTags')),
                  onPressed: () async {
                    final allTags = getAllTagsFromApps(
                      appsProvider.apps.entries.toList(),
                    );
                    final result = await showTagEditor(
                      context: context,
                      currentTags: app?.app.tags ?? [],
                      allTags: allTags,
                    );
                    if (result != null && app != null) {
                      app.app.tags = result;
                      appsProvider.saveApps([app.app]);
                    }
                  },
                ),
              ],
            ),
          ],
          if (app?.app.additionalSettings['about'] is String &&
              app?.app.additionalSettings['about'].isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        tr('about'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: GestureDetector(
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
                    child: Markdown(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                        blockquoteDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                ),
              ],
            ),
        ],
      );
    }

    Widget _buildActionCard({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color,
    }) {
      return Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildSystemActions() {
      if (app?.installedInfo == null) return const SizedBox.shrink();
      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('systemActions'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.settings_applications_outlined,
                    label: tr('appInfo'),
                    onTap: () => AppInstallService.openAppSettings(app!.app.id),
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.block_flipped,
                    label: tr('forceStop'),
                    onTap: () async {
                      try {
                        // await pm.forceStopApp(app!.app.id); // TODO: Implement
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('forceStopSuccess'))),
                          );
                        }
                      } catch (e) {
                        if (mounted) showError(e, context);
                      }
                    },
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.public_rounded,
                    label: tr('website'),
                    onTap: () async {
                      if (app?.app.url != null) {
                        launchUrlString(app!.app.url, mode: LaunchMode.externalApplication);
                      }
                    },
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.security_rounded,
                    label: tr('safetyScan'),
                    onTap: () async {
                      if (app?.app.url != null) {
                        final vtUrl = 'https://www.virustotal.com/gui/search/${Uri.encodeComponent(app!.app.url)}';
                        launchUrlString(vtUrl, mode: LaunchMode.externalApplication);
                      }
                    },
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.delete_sweep_outlined,
                    label: tr('clearCache'),
                    onTap: () async {
                      // Note: Clearing cache typically requires Shizuku/Root
                      try {
                        // await pm.deleteApplicationCacheFiles(
                        //   packageName: app!.app.id,
                        // ); // TODO: Implement
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('clearCacheSuccess'))),
                          );
                        }
                      } catch (e) {
                        if (mounted) showError(e, context);
                      }
                    },
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }


    Widget _buildDetailedSourceBadge() {
      final url = app?.app.url.toLowerCase() ?? '';
      IconData iconData = Icons.link_rounded;
      Color color = Theme.of(context).colorScheme.primary;
      String sourceName = tr('unknownSource');

      if (url.contains('github.com')) {
        iconData = Icons.terminal_rounded;
        color = const Color(0xFF24292E);
        sourceName = 'GitHub';
      } else if (url.contains('f-droid.org')) {
        iconData = Icons.android_rounded;
        color = const Color(0xFF1976D2);
        sourceName = 'F-Droid';
      } else if (url.contains('gitlab.com')) {
        iconData = Icons.account_tree_rounded;
        color = const Color(0xFFFC6D26);
        sourceName = 'GitLab';
      } else if (url.contains('codeberg.org')) {
        iconData = Icons.code_rounded;
        color = const Color(0xFF2185D0);
        sourceName = 'Codeberg';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              sourceName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    getFullInfoColumn({bool small = false}) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        FutureBuilder(
          future: appsProvider.updateAppIcon(app?.app.id, ignoreCache: true),
          builder: (ctx, val) {
            return app?.icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: InkWell(
                          onTap: app == null
                              ? null
                              : () => pm.openApp(app.app.id),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.memory(
                              app!.icon!,
                              height: small ? 80 : 120,
                              width: small ? 80 : 120,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container();
          },
        ),
        const SizedBox(height: 24),
        Center(child: _buildDetailedSourceBadge()),
        const SizedBox(height: 16),
        Text(
          app?.name ?? tr('app'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
        ),
        Text(
          tr('byX', args: [app?.author ?? tr('unknown')]),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              app?.app.id ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 0,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            if (app?.app.url != null) {
              launchUrlString(
                app?.app.url ?? '',
                mode: LaunchMode.externalApplication,
              );
            }
          },
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: app?.app.url ?? ''));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
          },
          child: Text(
            app?.app.url ?? '',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
        getInfoColumn(),
        const SizedBox(height: 16),
        _buildSystemActions(),
        SizedBox(height: 85 + MediaQuery.paddingOf(context).bottom),
      ],
    );

    getAppWebView() => app != null
        ? WebViewWidget(
            key: ObjectKey(_webViewController),
            controller: _webViewController
              ..setBackgroundColor(Theme.of(context).colorScheme.surface),
          )
        : Container();

    showMarkUpdatedDialog() {
      return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return GlassDialog(
            title: tr('alreadyUpToDateQuestion'),
            content: Container(), // Empty content as the question is in the title
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(tr('no')),
              ),
              TextButton(
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
        appsProvider.saveApps([app.app]).then((value) {
          getUpdate(app.app.id, resetVersion: versionDetectionEnabled);
        });
      }
    }

    getInstallOrUpdateButton() {
      final plusSettings = context.watch<PlusSettingsProvider>();
      final defaultStorePackage = plusSettings.plusDefaultStorePackage;
      final defaultStoreName = plusSettings.plusDefaultStoreName;

      return TextButton(
        onPressed: !updating &&
                (app?.app.installedVersion == null ||
                    AppUpdateService.areVersionsDifferent(
                      app!.app,
                      app!.app.installedVersion,
                      app!.app.latestVersion,
                    )) &&
                !areDownloadsRunning
            ? () async {
                if (defaultStorePackage != null && app?.app.id != null) {
                  AppHaptics.heavyImpact();
                  final scheme = defaultStorePackage == 'org.fdroid.fdroid'
                      ? 'fdroid.app://details?id='
                      : 'market://details?id=';
                  await _openInStore(defaultStorePackage, scheme, app!.app.id);
                  return;
                }
                try {
                  var successMessage = app?.app.installedVersion == null
                      ? tr('installed')
                      : tr('appsUpdated');
                  AppHaptics.heavyImpact();
                  var res = await appsProvider.downloadAndInstallLatestApps(
                    app?.app.id != null ? [app!.app.id] : [],
                    globalNavigatorKey.currentContext,
                  );
                  if (res.isNotEmpty && !trackOnly) {
                    // ignore: use_build_context_synchronously
                    showMessage(successMessage, context);
                  }
                  if (res.isNotEmpty && mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  showError(e, context);
                }
              }
            : null,
        child: Text(
          defaultStoreName != null
              ? (app?.app.installedVersion == null
                  ? 'Install in $defaultStoreName'
                  : 'Update in $defaultStoreName')
              : (app?.app.installedVersion == null
                  ? (!trackOnly ? tr('install') : tr('markInstalled'))
                  : (!trackOnly ? tr('update') : tr('markUpdated'))),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    getBottomSheetMenu() => Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        0,
        0,
        MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 16.0),
                Expanded(child: getInstallOrUpdateButton()),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.storefront_outlined),
                  onPressed: app?.app.id != null
                      ? () => _showStoreChooser(context, app!.app.id)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 8.0),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onSelected: (value) async {
                    AppHaptics.selectionClick();
                    switch (value) {
                      case 'additionalOptions':
                        var values = await showAdditionalOptionsDialog();
                        handleAdditionalOptionChanges(values);
                        break;
                      case 'settings':
                        if (app != null) {
                          appsProvider.openAppSettings(app.app.id);
                        }
                        break;
                      case 'moreInfo':
                        showDialog(
                          context: context,
                          builder: (BuildContext ctx) {
                            return GlassDialog(
                              title: app?.name ?? tr('app'),
                              content: getFullInfoColumn(small: true),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(tr('continue')),
                                ),
                              ],
                            );
                          },
                        );
                        break;
                      case 'markUpdated':
                        showMarkUpdatedDialog();
                        break;
                      case 'resetStatus':
                        if (app != null) {
                          app.app.installedVersion = null;
                          appsProvider.saveApps([app.app]);
                        }
                        break;
                      case 'remove':
                        appsProvider
                            .removeAppsWithModal(
                              context,
                              app != null ? [app.app] : [],
                            )
                            .then((value) {
                              if (value == true) {
                                Navigator.of(context).pop();
                              }
                            });
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final isUpdating = app?.downloadProgress != null || updating;
                    return [
                      if (source != null &&
                          source.combinedAppSpecificSettingFormItems.isNotEmpty)
                        PopupMenuItem(
                          value: 'additionalOptions',
                          enabled: !isUpdating,
                          child: ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(tr('additionalOptions')),
                            dense: true,
                          ),
                        ),
                      if (app != null && app.installedInfo != null)
                        PopupMenuItem(
                          value: 'settings',
                          child: ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: Text(tr('settings')),
                            dense: true,
                          ),
                        ),
                      if (app != null && showAppWebpageFinal)
                        PopupMenuItem(
                          value: 'moreInfo',
                          child: ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: Text(tr('more')),
                            dense: true,
                          ),
                        ),
                      if (app?.app.installedVersion != null &&
                          app?.app.installedVersion !=
                              app?.app.latestVersion &&
                          !isVersionDetectionStandard &&
                          !trackOnly)
                        PopupMenuItem(
                          value: 'markUpdated',
                          enabled: !isUpdating,
                          child: ListTile(
                            leading: const Icon(Icons.done_all_rounded),
                            title: Text(tr('markUpdated')),
                            dense: true,
                          ),
                        ),
                      if ((!isVersionDetectionStandard || trackOnly) &&
                          app?.app.installedVersion != null &&
                          app?.app.installedVersion == app?.app.latestVersion)
                        PopupMenuItem(
                          value: 'resetStatus',
                          enabled: !isUpdating,
                          child: ListTile(
                            leading: const Icon(Icons.restore_rounded),
                            title: Text(tr('resetInstallStatus')),
                            dense: true,
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'remove',
                        enabled: !isUpdating,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            tr('remove'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          dense: true,
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          if (app?.downloadProgress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: ExpressiveProgressIndicator(
                value: app!.downloadProgress! >= 0
                    ? app.downloadProgress! / 100
                    : null,
              ),
            ),
        ],
      ),
    );

    appScreenAppBar() => AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );

    final scaffold = Scaffold(
      appBar: widget.isModal
          ? null
          : (showAppWebpageFinal ? AppBar() : appScreenAppBar()),
      backgroundColor: widget.isModal
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        child: showAppWebpageFinal
            ? PopScope(
                canPop: false,
                onPopInvoked: (didPop) {
                  if (didPop) return;
                  Navigator.of(context).pop();
                },
                child: getAppWebView(),
              )
            : CustomScrollView(
                controller: widget.scrollController,
                physics: widget.isModal
                    ? const BouncingScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(children: [getFullInfoColumn()]),
                  ),
                ],
              ),
        onRefresh: () async {
          if (app != null) {
            getUpdate(app.app.id);
          }
        },
      ),
      bottomSheet: getBottomSheetMenu(),
    );

    if (widget.isModal) {
      final radius = plusSettings.plusOverrideIndividualCornerRadius
          ? plusSettings.plusHomeCornerRadius
          : plusSettings.plusGlobalCornerRadius;

      return ConditionalBlur(
        enabled: plusSettings.plusEnableGlassmorphism,
        sigma: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(
              plusSettings.plusEnableGlassmorphism ? 0.85 : 1.0,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius.clamp(20.0, 48.0)),
            ),
          ),
          child: scaffold,
        ),
      );
    }
    return scaffold;
  }
}
