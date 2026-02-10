import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

class CommandCenter extends StatefulWidget {
  const CommandCenter({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommandCenter(),
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
  SourceProvider _sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AppInMemory> _localResults = [];

  Future<void> _handleSearch(String value) async {
    setState(() {
      _query = value;
      _discoverResults = {};
    });

    if (value.isEmpty) {
      setState(() => _localResults = []);
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
    if (URLValidator.isValidSourceURL(value)) return;

    // Handle as Discovery Search
    await _runDiscoverSearch(value);
  }

  Future<void> _runDiscoverSearch(String query) async {
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        _handleSearch('');
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
              onChanged: _handleSearch,
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
          ? Image.memory(app.icon!) 
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
    if (_isSearching && _discoverResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isSearching && _discoverResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text(tr('noResultsFound'))),
      );
    }

    return Column(
      children: _discoverResults.entries.map((entry) {
        final url = entry.key;
        final result = entry.value;
        final name = result.value.isNotEmpty ? result.value[0] : 'Unknown';
        final source = result.key;

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
          ),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(source),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () => _openAddApp(url),
        );
      }).toList(),
    );
  }

  Widget _buildUrlActionContent() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.rocket_launch_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(tr('commandCenterPrompt'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(tr('commandCenterSubtitle'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 48),
          _buildQuickActions(),
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
            children: [
              ActionChip(
                avatar: const Icon(Icons.sync, size: 16),
                label: Text(tr('checkUpdates')),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AppsProvider>().checkUpdates(ignoreCache: true);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.import_export, size: 16),
                label: Text(tr('importExport')),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportExportPage()));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.bug_report_outlined, size: 16),
                label: Text(tr('logs')),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsPage()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
