import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/settings/settings_widgets.dart';
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
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.appId,
    this.showOppositeOfPreferredView = false,
  });

  final String appId;
  final bool showOppositeOfPreferredView;

  @override
  Widget build(BuildContext context) {
    return ModernAppPage(
      appId: appId,
      showOppositeOfPreferredView: showOppositeOfPreferredView,
    );
  }
}

class ModernAppPage extends StatefulWidget {
  const ModernAppPage({
    super.key,
    required this.appId,
    this.showOppositeOfPreferredView = false,
  });

  final String appId;
  final bool showOppositeOfPreferredView;

  @override
  State<ModernAppPage> createState() => _ModernAppPageState();
}

class _ModernAppPageState extends State<ModernAppPage> {
  late final WebViewController _webViewController;
  bool _wasWebViewOpened = false;
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
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
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
  void dispose() {
    if (_wasWebViewOpened) {
      _webViewController.loadRequest(Uri.parse('about:blank'));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
    var showAppWebpageFinal =
        (settingsProvider.showAppWebpage &&
            !widget.showOppositeOfPreferredView) ||
        (!settingsProvider.showAppWebpage &&
            widget.showOppositeOfPreferredView);

    getUpdate(String id, {bool resetVersion = false}) async {
      try {
        setState(() => updating = true);
        await appsProvider.checkUpdate(id);
        if (resetVersion) {
          appsProvider.apps[id]?.app.additionalSettings['versionDetection'] = true;
          if (appsProvider.apps[id]?.app.installedVersion != null) {
            appsProvider.apps[id]?.app.installedVersion = appsProvider.apps[id]?.app.latestVersion;
          }
          appsProvider.saveApps([appsProvider.apps[id]!.app]);
        }
      } catch (err) {
        showError(err, context);
      } finally {
        setState(() => updating = false);
      }
    }

    bool areDownloadsRunning = appsProvider.areDownloadsRunning();
    AppInMemory? app = appsProvider.apps[widget.appId]?.deepCopy();
    var source = app != null ? SourceProvider().getSource(app.app.url, overrideSource: app.app.overrideSource) : null;

    if (!areDownloadsRunning && prevApp == null && app != null && settingsProvider.checkUpdateOnDetailPage) {
      prevApp = app;
      getUpdate(app.app.id);
    }

    if (app != null && !_wasWebViewOpened) {
      _wasWebViewOpened = true;
      _webViewController.loadRequest(Uri.parse(app.app.url));
    }

    Widget _buildStatusHeader() {
      if (app == null) return const SizedBox.shrink();
      
      final installed = app.app.installedVersion != null;
      final upToDate = app.app.installedVersion == app.app.latestVersion;
      final color = installed ? (upToDate ? Colors.green : Colors.orange) : Colors.grey;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(installed ? (upToDate ? Icons.check_circle : Icons.update) : Icons.cloud_off, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installed ? (upToDate ? tr('upToDate') : tr('updateAvailable')) : tr('notInstalled'),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    installed ? '${app.app.installedVersion} → ${app.app.latestVersion}' : app.app.latestVersion,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildAppInfo() {
      if (app == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 24),
          SettingsGroup(
            title: tr('details'),
            children: [
              SettingsTile(
                title: tr('author'),
                subtitle: app.author,
                leadingIcon: Icons.person_outline,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: app.author));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
                },
              ),
              SettingsTile(
                title: tr('appId'),
                subtitle: app.app.id,
                leadingIcon: Icons.fingerprint,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: app.app.id));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
                },
              ),
              SettingsTile(
                title: tr('source'),
                subtitle: app.app.url,
                leadingIcon: Icons.link,
                onTap: () => launchUrlString(app.app.url, mode: LaunchMode.externalApplication),
              ),
              if (app.app.releaseDate != null)
                SettingsTile(
                  title: tr('releaseDate'),
                  subtitle: app.app.releaseDate!.toLocal().toString(),
                  leadingIcon: Icons.calendar_today_outlined,
                ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            title: tr('categories'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CategoryEditorSelector(
                  alignment: WrapAlignment.start,
                  preselected: app.app.categories.toSet(),
                  onSelected: (categories) {
                    app.app.categories = categories;
                    appsProvider.saveApps([app.app]);
                  },
                ),
              ),
            ],
          ),
          if (app.app.additionalSettings['about'] != null) ...[
            const SizedBox(height: 24),
            SettingsGroup(
              title: tr('about'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: app.app.additionalSettings['about'],
                    onTapLink: (text, href, title) => href != null ? launchUrlString(href, mode: LaunchMode.externalApplication) : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    Widget _buildActionFab() {
      if (app == null) return const SizedBox.shrink();
      final needsAction = app.app.installedVersion == null || app.app.installedVersion != app.app.latestVersion;
      if (!needsAction) return const SizedBox.shrink();

      return FloatingActionButton.extended(
        onPressed: updating || areDownloadsRunning ? null : () async {
          HapticFeedback.heavyImpact();
          await appsProvider.downloadAndInstallLatestApps([app.app.id], globalNavigatorKey.currentContext);
        },
        icon: updating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
        label: Text(app.app.installedVersion == null ? tr('install') : tr('update')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = settingsProvider.plusEnableResponsiveAppLayout && constraints.maxWidth > 800;
          
          if (showAppWebpageFinal) {
            return WebViewWidget(
              key: ObjectKey(_webViewController),
              controller: _webViewController..setBackgroundColor(Theme.of(context).colorScheme.surface),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(app?.name ?? tr('app')),
                actions: [
                  if (app != null && app.installedInfo != null)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => AppInstallService.openAppSettings(app.app.id),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => appsProvider.removeAppsWithModal(context, [app!.app]).then((res) => res == true ? Navigator.pop(context) : null),
                  ),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: isWide 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildAppInfo()),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                SettingsHeader(title: tr('appSource')),
                                SizedBox(
                                  height: constraints.maxHeight - 200,
                                  child: Card(
                                    elevation: 0,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                    ),
                                    child: WebViewWidget(controller: _webViewController),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _buildAppInfo(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildActionFab(),
      bottomNavigationBar: app?.downloadProgress != null ? LinearProgressIndicator(value: (app!.downloadProgress ?? 0) / 100) : null,
    );
  }
}