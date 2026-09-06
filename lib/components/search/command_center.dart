import 'dart:async';
import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

import 'package:flutter/material.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_search_service.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/fuzzy_search.dart';
import 'package:obtainium/components/ui_widgets.dart';

class CommandCenter extends StatefulWidget {
  final String? initialQuery;

  const CommandCenter({super.key, this.initialQuery});

  static Future<void> show(BuildContext context, {String? initialQuery}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => CommandCenter(initialQuery: initialQuery),
    );
  }

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _isAddingUrl = false;
  String _query = '';
  Map<String, MapEntry<String, List<String>>> _discoverResults = {};
  bool _discoverSearchFailed = false;
  final Set<String> _pendingAddUrls = {};
  final SourceProvider _sourceProvider = SourceProvider();
  Timer? _debounce;

  Future<void> _submitAddAppUrl(String url) async {
    if (_pendingAddUrls.contains(url)) return;
    setState(() => _pendingAddUrls.add(url));
    try {
      final errors = await context.read<AppsProvider>().addAppsByURL([url]);
      if (mounted) {
        setState(() => _pendingAddUrls.remove(url));
        if (errors.isNotEmpty) {
          showError(errors[0][1], context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('appAdded'))),
          );
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      } else {
        final globalCtx = globalNavigatorKey.currentContext;
        if (globalCtx != null && globalCtx.mounted) {
          if (errors.isNotEmpty) {
            showError(errors[0][1], globalCtx);
          } else {
            ScaffoldMessenger.of(globalCtx).showSnackBar(
              SnackBar(content: Text(tr('appAdded'))),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingAddUrls.remove(url));
        showError(e, context);
      } else {
        final globalCtx = globalNavigatorKey.currentContext;
        if (globalCtx != null && globalCtx.mounted) {
          showError(e, globalCtx);
        }
      }
    }
  }

  bool _isDirectUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('market://')) {
      return true;
    }
    try {
      final src = _sourceProvider.getSource(trimmed);
      if (src.hosts.isNotEmpty && src.runtimeType.toString() != 'HTML') {
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _query = widget.initialQuery!;
      _handleSearch(widget.initialQuery!);
    }
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AppInMemory> _localResults = [];

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
    _updateLocalResults(value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _handleDiscoverSearch(value);
    });
  }

  void _updateLocalResults(String value) {
    if (value.isEmpty) {
      setState(() {
        _localResults = [];
        _discoverResults = {};
      });
      return;
    }

    // Search local apps immediately on every keystroke
    final appsProvider = context.read<AppsProvider>();
    final results = appsProvider
        .getAppValues()
        .map((app) {
          final score = fuzzyMatchMulti(value, [
            app.name,
            app.app.id,
            app.author,
            app.app.url,
            ...?app.app.categories,
          ]);
          return MapEntry(app, score);
        })
        .where((entry) => entry.value >= 0.3)
        .toList();

    results.sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _localResults = results.map((entry) => entry.key).take(5).toList();
    });
  }

  Future<void> _handleDiscoverSearch(String value) async {
    if (value.isEmpty) return;

    // Check if it's a URL
    if (_isDirectUrl(value)) {
      // Allow GitHub User Profiles to bypass this so they can be searched
      RegExp userProfileRegEx = RegExp(
        r'^https?://(?:www\.)?github\.com/[^/]+/?$',
        caseSensitive: false,
      );
      if (!userProfileRegEx.hasMatch(value)) {
        setState(() => _discoverResults = {});
        return;
      }
    }

    // Handle as Discovery Search
    await _runDiscoverSearch(value);
  }

  Future<void> _handleSearch(String value) async {
    _updateLocalResults(value);
    await _handleDiscoverSearch(value);
  }

  Future<void> _runDiscoverSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final settings = context.read<SettingsProvider>();

      final searchResult = await AppSearchService.searchAllSources(
        query,
        sourceProvider: _sourceProvider,
        deselectedSources: settings.searchDeselected,
      );

      if (mounted && _query == query) {
        setState(() {
          _discoverResults = searchResult.results;
          _discoverSearchFailed = searchResult.allSourcesFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrl = _isDirectUrl(_query);
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: ConditionalBlur(
              sigma: 24,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.surface)
                          .withValues(
                            alpha: plusSettings.plusEnableGlassmorphism
                                ? 0.72
                                : 1.0,
                          ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: plusSettings.plusEnableGlassmorphism
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.18)
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: AppOpacity.subtle,
                            ),
                    ),
                    left: BorderSide(
                      color: plusSettings.plusEnableGlassmorphism
                          ? theme.colorScheme.onSurface.withValues(
                              alpha: AppOpacity.hint,
                            )
                          : Colors.transparent,
                    ),
                    right: BorderSide(
                      color: plusSettings.plusEnableGlassmorphism
                          ? theme.colorScheme.onSurface.withValues(
                              alpha: AppOpacity.hint,
                            )
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: theme.textTheme.titleMedium,
                        decoration: InputDecoration(
                          hintText: tr('searchOrPasteUrl'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _controller.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHigh
                              .withValues(
                                alpha: plusSettings.plusEnableGlassmorphism
                                    ? 0.5
                                    : 1.0,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),

                    // Source filter chips only matter once there's an
                    // actual discover search running — showing all 8
                    // sources before the user has typed anything just
                    // clutters the initial quick-actions/recently-added
                    // view for a feature most people never touch.
                    if (_query.isNotEmpty &&
                        (!isUrl ||
                            RegExp(
                              r'^https?://(?:www\.)?github\.com/[^/]+/?$',
                              caseSensitive: false,
                            ).hasMatch(_query))) ...[
                      const SizedBox(height: 8),
                      _buildSourceFilters(context),
                    ],
                    const SizedBox(height: 8),

                    // Content
                    Expanded(
                      child: _query.isEmpty
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildInitialState(),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: ListView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                children: [
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: _localResults.isNotEmpty
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildSectionHeader(tr('myApps')),
                                              ..._localResults.map(
                                                _buildLocalResult,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: isUrl
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildSectionHeader(
                                                tr('actions'),
                                              ),
                                              _buildUrlActionContent(),
                                              const SizedBox(height: 16),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child:
                                        (_query.isNotEmpty &&
                                            (!isUrl ||
                                                RegExp(
                                                  r'^https?://(?:www\.)?github\.com/[^/]+/?$',
                                                  caseSensitive: false,
                                                ).hasMatch(_query)))
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildSectionHeader(
                                                tr('discover'),
                                              ),
                                              _buildSearchResultsList(),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocalResult(AppInMemory app) {
    final plusSettings = context.read<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final itemRadius = CardMetrics.inner(radius);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(itemRadius),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: ScaleTouchWrapper(
          child: InkWell(
            borderRadius: BorderRadius.circular(itemRadius),
            onTap: () {
              Navigator.pop(context);
              showDraggableModalBottomSheet(
                context: context,
                builder: (context, controller) => AppPage(
                  appId: app.app.id,
                  isModal: true,
                  scrollController: controller,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(itemRadius * 0.75),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: app.icon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              itemRadius * 0.75,
                            ),
                            child: Image.memory(
                              app.icon!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : const Icon(Icons.apps_rounded),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          app.app.latestVersion,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddApp(String url) {
    Navigator.pop(context);
    final ctx = globalNavigatorKey.currentContext;
    if (ctx != null) {
      showAddAppSheet(context: ctx, initialUrl: url);
    }
  }

  Widget _buildSearchResultsList() {
    final theme = Theme.of(context);
    final plusSettings = context.watch<PlusSettingsProvider>();
    if (_isSearching && _discoverResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: ExpressiveCircularProgressIndicator()),
      );
    }

    if (!_isSearching && _discoverResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _discoverSearchFailed
                    ? Icons.wifi_off_rounded
                    : Icons.search_off_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _discoverSearchFailed
                    ? tr('searchAllSourcesFailed')
                    : tr('noResultsFound'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: const ExpressiveProgressIndicator(),
          ),
        ..._discoverResults.entries.map((entry) {
          final url = entry.key;
          final result = entry.value;
          final name = result.value.isNotEmpty ? result.value[0] : 'Unknown';
          final source = result.key;
          final radius = plusSettings.plusOverrideIndividualCornerRadius
              ? plusSettings.plusHomeCornerRadius
              : plusSettings.plusGlobalCornerRadius;
          final itemRadius = (radius * 0.66).clamp(8.0, 16.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(itemRadius),
              child: ScaleTouchWrapper(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(itemRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(itemRadius * 0.75),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          source,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: tr('advancedOptions'),
                        onPressed: () => _openAddApp(url),
                      ),
                      _pendingAddUrls.contains(url)
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: ExpressiveCircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_circle_outline_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              tooltip: tr('addApp'),
                              onPressed: () => _submitAddAppUrl(url),
                            ),
                    ],
                  ),
                  onTap: _pendingAddUrls.contains(url)
                      ? null
                      : () => _submitAddAppUrl(url),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUrlActionContent() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: AppOpacity.moderate),
      child: Column(
        children: [
          ListTile(
            leading: _isAddingUrl
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            title: Text(tr('addApp')),
            subtitle: Text(
              _query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _isAddingUrl
                ? null
                : const Icon(Icons.arrow_forward),
            onTap: _isAddingUrl
                ? null
                : () async {
                    setState(() => _isAddingUrl = true);
                    final queryToAdd = _query;
                    try {
                      final errors = await context
                          .read<AppsProvider>()
                          .addAppsByURL([queryToAdd]);
                      if (mounted) {
                        setState(() => _isAddingUrl = false);
                        if (errors.isNotEmpty) {
                          showError(errors[0][1], context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('appAdded'))),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        final globalCtx = globalNavigatorKey.currentContext;
                        if (globalCtx != null && globalCtx.mounted) {
                          if (errors.isNotEmpty) {
                            showError(errors[0][1], globalCtx);
                          } else {
                            ScaffoldMessenger.of(globalCtx).showSnackBar(
                              SnackBar(content: Text(tr('appAdded'))),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isAddingUrl = false);
                        showError(e, context);
                      } else {
                        final globalCtx = globalNavigatorKey.currentContext;
                        if (globalCtx != null && globalCtx.mounted) {
                          showError(e, globalCtx);
                        }
                      }
                    }
                  },
          ),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: Text(tr('advancedOptions')),
            trailing: const Icon(Icons.open_in_new),
            onTap: _isAddingUrl ? null : () => _openAddApp(_query),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final appsProvider = context.read<AppsProvider>();
    final recentlyAdded = appsProvider
        .getAppValues()
        .toList()
        .reversed
        .take(5)
        .toList();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentlyAdded.isNotEmpty) ...[
            _buildSectionHeader(tr('recentlyAdded')),
            ...recentlyAdded.map(_buildLocalResult),
            const SizedBox(height: 24),
          ],
          _buildQuickActions(),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: AppOpacity.low),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('commandCenterPrompt'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: AppOpacity.half),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(tr('quickActions')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(Icons.sync, tr('checkUpdates'), () {
                Navigator.pop(context);
                context
                    .read<AppsProvider>()
                    .checkUpdates(ignoreAppsCheckedAfter: DateTime.now())
                    .catchError((e) {
                      if (mounted) {
                        showError(e is Map ? e['errors'] : e, context);
                      }
                      return <App>[];
                    });
              }),
              _buildActionChip(Icons.import_export, tr('importExport'), () {
                Navigator.pop(context);
                pushRoute(context, const ImportExportPage());
              }),
              _buildActionChip(Icons.bug_report_outlined, tr('logs'), () {
                Navigator.pop(context);
                pushRoute(context, const LogsPage());
              }),
              _buildActionChip(Icons.settings_outlined, tr('settings'), () {
                Navigator.pop(context);
                pushRoute(context, const SettingsPage());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onPressed) {
    final plusSettings = context.read<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final chipRadius = CardMetrics.inner(radius);

    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(chipRadius),
      ),
    );
  }

  Widget _buildSourceFilters(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final searchableSources = _sourceProvider.sources
        .where((e) => e.canSearch)
        .toList();
    if (searchableSources.isEmpty) return const SizedBox.shrink();

    final plusSettings = context.read<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final chipRadius = CardMetrics.inner(radius);

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: searchableSources.length,
        itemBuilder: (context, index) {
          final src = searchableSources[index];
          final isSelected = !settings.searchDeselected.contains(src.name);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(src.name),
              onSelected: (bool selected) {
                AppHaptics.selectionClick();
                final newList = List<String>.from(settings.searchDeselected);
                if (selected) {
                  newList.remove(src.name);
                } else {
                  newList.add(src.name);
                }
                settings.searchDeselected = newList;
                if (_query.isNotEmpty) {
                  _handleSearch(_query);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(chipRadius),
              ),
            ),
          );
        },
      ),
    );
  }
}
