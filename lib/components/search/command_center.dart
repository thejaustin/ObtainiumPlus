import 'dart:async';
import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';

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
  String _query = '';
  Map<String, MapEntry<String, List<String>>> _discoverResults = {};
  final SourceProvider _sourceProvider = SourceProvider();
  Timer? _debounce;

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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _handleSearch(value);
    });
  }

  Future<void> _handleSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        _localResults = [];
        _discoverResults = {};
      });
      return;
    }

    // Search local apps
    final appsProvider = context.read<AppsProvider>();
    setState(() {
      _localResults = appsProvider.getAppValues().where((app) {
        return app.name.toLowerCase().contains(value.toLowerCase()) ||
               app.app.id.toLowerCase().contains(value.toLowerCase());
      }).take(5).toList();
    });

    // Check if it's a URL
    if (URLValidator.isValidSourceURL(value)) {
      setState(() => _discoverResults = {});
      return;
    }

    // Handle as Discovery Search
    await _runDiscoverSearch(value);
  }

  Future<void> _runDiscoverSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final settings = context.read<SettingsProvider>();
      final searchableSources = _sourceProvider.sources.where((e) => e.canSearch).toList();
      
      final results = await Future.wait(
        searchableSources.map((source) async {
          if (settings.searchDeselected.contains(source.name)) return null;
          try {
            final res = await source.search(query);
            return MapEntry(source.name, res);
          } catch (_) {
            return null;
          }
        }),
      );

      final Map<String, MapEntry<String, List<String>>> aggregated = {};
      for (final res in results) {
        if (res == null) continue;
        res.value.forEach((url, info) {
          aggregated[url] = MapEntry(res.key, info);
        });
      }

      if (mounted && _query == query) {
        setState(() {
          _discoverResults = aggregated;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrl = URLValidator.isValidSourceURL(_query);
    final settings = context.watch<SettingsProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ConditionalBlur(sigma: 24, enabled: settings.plusEnableGlassmorphism, child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: (isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surface)
                .withValues(alpha: settings.plusEnableGlassmorphism ? 0.72 : 1.0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.18)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
              ),
              left: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              right: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
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
                fillColor: theme.colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _query.isEmpty 
              ? _buildInitialState()
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    if (_localResults.isNotEmpty) ...[
                      _buildSectionHeader(tr('myApps')),
                      ..._localResults.map(_buildLocalResult),
                      const SizedBox(height: 16),
                    ],
                    if (isUrl) ...[
                      _buildSectionHeader(tr('actions')),
                      _buildUrlActionContent(),
                      const SizedBox(height: 16),
                    ],
                    if (_query.isNotEmpty && !isUrl) ...[
                      _buildSectionHeader(tr('discover')),
                      _buildSearchResultsList(),
                    ],
                  ],
                ),
          ),
        ],
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
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: app.icon != null 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(app.icon!, fit: BoxFit.cover),
            )
          : const Icon(Icons.apps),
      ),
      title: Text(app.name),
      subtitle: Text(app.app.latestVersion, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => AppPage(
            appId: app.app.id,
            isModal: true,
          ),
        );
      },
    );
  }

  void _openAddApp(String url) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAppPage(),
      ),
    ).then((_) {
      // Small delay to ensure AddAppPage state is initialized
      Future.delayed(const Duration(milliseconds: 200), () {
        final homeState = globalNavigatorKey.currentContext?.findAncestorStateOfType<HomePageState>();
        final addAppKey = homeState?.addAppPage.key as GlobalKey<AddAppPageState>?;
        if (addAppKey?.currentState != null) {
          addAppKey!.currentState!.linkFn(url);
        }
      });
    });
  }

  Widget _buildSearchResultsList() {
    final theme = Theme.of(context);
    if (_isSearching && _discoverResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: ExpressiveCircularProgressIndicator()),
      );
    }

    if (!_isSearching && _discoverResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text(tr('noResultsFound'))),
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

          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    source,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            onTap: () => _openAddApp(url),
          );
        }),
      ],
    );
  }

  Widget _buildUrlActionContent() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: ListTile(
        leading: const Icon(Icons.link),
        title: Text(tr('addAppFromUrl')),
        subtitle: Text(_query, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _openAddApp(_query),
      ),
    );
  }

  Widget _buildInitialState() {
    final appsProvider = context.read<AppsProvider>();
    final recentlyAdded = appsProvider.getAppValues().toList().reversed.take(5).toList();

    return SingleChildScrollView(
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
                Icon(Icons.rocket_launch_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(tr('commandCenterPrompt'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
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
                context.read<AppsProvider>().checkUpdates(ignoreCache: true);
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
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
