import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';

class SystemAppSelector extends StatefulWidget {
  const SystemAppSelector({super.key});

  @override
  State<SystemAppSelector> createState() => _SystemAppSelectorState();
}

class _SystemAppSelectorState extends State<SystemAppSelector> {
  bool _isLoading = true;
  bool _showSystemApps = false;
  String _searchQuery = '';
  List<PackageInfo> _apps = [];
  final SourceProvider _sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final installed = await AppInstallService.getAllInstalledInfo();
      if (mounted) {
        setState(() {
          _apps = installed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    
    // Filter apps
    final filteredApps = _apps.where((pkg) {
      if (pkg.packageName == null) return false;
      
      // Filter out apps already tracked
      if (appsProvider.apps.containsKey(pkg.packageName)) return false;

      // Filter by system status if toggled
      final bool isSystem = (pkg.applicationInfo?.flags ?? 0) & 1 != 0; // FLAG_SYSTEM
      if (!_showSystemApps && isSystem) return false;

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final name = pkg.packageName!.toLowerCase();
        // Since we don't have app labels easily here without more async calls per item, 
        // we mostly search by package ID.
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      return true;
    }).toList();

    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(tr('importInstalledApps')),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.plusEnableGlassmorphism ? 15 : 0,
              sigmaY: settings.plusEnableGlassmorphism ? 15 : 0,
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(
                alpha: settings.plusEnableGlassmorphism ? 0.7 : 1.0,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSystemApps ? Icons.system_update_rounded : Icons.person_outline_rounded),
            onPressed: () => setState(() => _showSystemApps = !_showSystemApps),
            tooltip: tr('showSystemApps'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: tr('searchOrPasteUrl'),
              leading: const Icon(Icons.search),
              onChanged: (val) => setState(() => _searchQuery = val),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHigh.withValues(
                alpha: settings.plusEnableGlassmorphism ? 0.5 : 1.0,
              )),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 64),
              child: filteredApps.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.apps_rounded,
                      title: tr('noMatchingApps'),
                      subtitle: tr('tryAdjustingFilters'),
                    )
                  : ListView.builder(
                      itemCount: filteredApps.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final pkg = filteredApps[index];
                        return _buildAppTile(pkg, appsProvider);
                      },
                    ),
            ),
    );
  }

  Widget _buildAppTile(PackageInfo pkg, AppsProvider appsProvider) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
            sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: (isDark 
                ? Theme.of(context).colorScheme.surfaceContainerHighest 
                : Theme.of(context).colorScheme.surface)
              .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.1,
                ),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: FutureBuilder(
                future: pkg.applicationInfo?.getAppIcon(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(snapshot.data!, width: 44, height: 44),
                    );
                  }
                  return const AppIconShimmer(size: 44);
                },
              ),
              title: FutureBuilder(
                future: pkg.applicationInfo?.getAppLabel(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? pkg.packageName!, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              subtitle: Text(
                pkg.packageName!, 
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: FilledButton.tonal(
                onPressed: () => _handleTrackApp(pkg, appsProvider),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(tr('add')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTrackApp(PackageInfo pkg, AppsProvider appsProvider) async {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(tr('searchingForSource')),
          ],
        ),
      ),
    );

    try {
      final String appId = pkg.packageName!;
      final AppSource? source = await _sourceProvider.findSourceForPackage(appId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (source != null) {
        final String url = source.name == 'Google Play' 
            ? 'https://play.google.com/store/apps/details?id=$appId'
            : 'https://f-droid.org/en/packages/$appId';

        final label = await pkg.applicationInfo?.getAppLabel() ?? appId;
        
        final App app = App(
          appId,
          url,
          '', // Author
          label,
          pkg.versionName,
          pkg.versionName ?? '0.0.0', // Latest (will be updated on first check)
          [],
          0,
          {'versionDetection': true},
          DateTime.now(),
          false,
        );

        await appsProvider.saveApps([app], onlyIfExists: false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('sourceFound', args: [source.name]))),
          );
          // Remove from local list
          setState(() {
            _apps.removeWhere((p) => p.packageName == appId);
          });
        }
      } else {
        if (mounted) {
          _showManualSourceDialog(pkg);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showError(e, context);
      }
    }
  }

  void _showManualSourceDialog(PackageInfo pkg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('noSourceFound')),
        content: Text('Obtainium couldn\'t automatically find a source for ${pkg.packageName}. You can try adding it manually.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to Add App with package ID as search query
              Navigator.pop(context, pkg.packageName);
            },
            child: Text(tr('addApp')),
          ),
        ],
      ),
    );
  }
}
