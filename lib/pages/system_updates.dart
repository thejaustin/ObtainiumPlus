import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/play_store_mirror_service.dart';
import 'package:provider/provider.dart';

class SystemUpdatesPage extends StatefulWidget {
  const SystemUpdatesPage({super.key});

  @override
  State<SystemUpdatesPage> createState() => _SystemUpdatesPageState();
}

class _SystemUpdatesPageState extends State<SystemUpdatesPage> {
  bool _isScanning = false;
  List<ExternalAppUpdate> _updates = [];
  int _scanCurrent = 0;
  int _scanTotal = 0;

  Future<void> _startScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _updates = [];
      _scanCurrent = 0;
      _scanTotal = 0;
    });

    try {
      final appsProvider = context.read<AppsProvider>();
      final results = await PlayStoreMirrorService.scanForUpdates(
        trackedApps: appsProvider.apps,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _scanCurrent = current;
              _scanTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _updates = results;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isScanning && _updates.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.system_update_alt_rounded,
        title: tr('scanForUpdates'),
        subtitle: tr('plusSystemUpdateScannerDescription'),
        actionLabel: tr('scanForUpdates'),
        onActionPressed: _startScan,
      );
    }

    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ExpressiveCircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(tr('scanningXApps', args: [_scanTotal.toString()])),
            const SizedBox(height: 8),
            Text('$_scanCurrent / $_scanTotal', style: Theme.of(context).textTheme.bodySmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              child: LinearProgressIndicator(
                value: _scanTotal > 0 ? _scanCurrent / _scanTotal : null,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _updates.length,
        itemBuilder: (context, index) {
          final update = _updates[index];
          return _buildUpdateCard(update);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        tooltip: tr('refresh'),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildUpdateCard(ExternalAppUpdate update) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(update.name.isNotEmpty ? update.name[0].toUpperCase() : '?'),
        ),
        title: Text(update.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${update.currentVersion} ➔ ${update.latestVersion}', style: const TextStyle(fontSize: 12)),
        children: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Source selector
                    Row(
                      children: [
                        const Icon(Icons.store_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          tr('preferredUpdateSource'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: settings.preferredUpdateSource,
                          underline: const SizedBox.shrink(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              settings.preferredUpdateSource = newValue;
                            }
                          },
                          items: [
                            DropdownMenuItem(value: 'play_store', child: Text(tr('playStore'))),
                            DropdownMenuItem(value: 'aurora', child: const Text('Aurora Store')),
                            DropdownMenuItem(value: 'github', child: const Text('GitHub')),
                            DropdownMenuItem(value: 'apkpure', child: const Text('APKPure')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.rocket_launch_outlined,
                          label: tr('updateViaAurora'),
                          onPressed: () => PlayStoreMirrorService.openInSource(
                            appId: update.appId,
                            source: 'aurora',
                          ),
                        ),
                        _buildActionButton(
                          icon: Icons.shop_outlined,
                          label: tr('updateViaPlayStore'),
                          onPressed: () => PlayStoreMirrorService.openInSource(
                            appId: update.appId,
                            source: settings.preferredUpdateSource == 'play_store' ? 'play_store' : 'play_store',
                          ),
                        ),
                        _buildActionButton(
                          icon: Icons.code_outlined,
                          label: 'GitHub',
                          onPressed: () => PlayStoreMirrorService.openInSource(
                            appId: update.appId,
                            source: 'github',
                            packageName: update.appId,
                          ),
                        ),
                        _buildActionButton(
                          icon: Icons.cloud_download_outlined,
                          label: 'APKPure',
                          onPressed: () => PlayStoreMirrorService.openInSource(
                            appId: update.appId,
                            source: 'apkpure',
                            packageName: update.appId,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(tr('addToObtainium')),
                      subtitle: Text(tr('trackFromGooglePlay')),
                      onTap: () async {
                        final appsProvider = context.read<AppsProvider>();
                        final url = 'https://play.google.com/store/apps/details?id=${update.appId}';
                        await appsProvider.addAppsByURL([url]);
                        if (mounted) {
                          setState(() => _updates.removeWhere((u) => u.appId == update.appId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('appAlreadyAdded'))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(onPressed: onPressed, icon: Icon(icon)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}
