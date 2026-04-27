import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/logger.dart';

class MicroGHubPage extends StatefulWidget {
  const MicroGHubPage({super.key});

  @override
  State<MicroGHubPage> createState() => _MicroGHubPageState();
}

class _MicroGHubPageState extends State<MicroGHubPage> {
  static const _platform = MethodChannel('app.obtainiumplus/native');
  String _selectedProvider = 'Official (microG Project)';
  bool _installGmsCore = true;
  bool _installGsfProxy = true;
  bool _installFakeStore = false;
  bool _isRooted = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  final Map<String, String> _providers = {
    'Official (microG Project)': 'microg/GmsCore',
    'ReVanced (GmsCore)': 'ReVanced/GmsCore',
  };

  @override
  void initState() {
    super.initState();
    _checkRootStatus();
  }

  Future<void> _checkRootStatus() async {
    try {
      final bool rooted = await _platform.invokeMethod('isRooted');
      if (mounted) {
        setState(() {
          _isRooted = rooted;
        });
      }
    } catch (e) {
      talker.error('Failed to check root status: $e');
    }
  }

  Future<void> _startDeployment() async {
    final appsProvider = context.read<AppsProvider>();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final List<String> urls = [];
      final String repoPrefix = _providers[_selectedProvider]!;
      
      if (_installGmsCore) urls.add('https://github.com/$repoPrefix');
      if (_installGsfProxy) urls.add('https://github.com/microg/GsfProxy');
      if (_installFakeStore) urls.add('https://github.com/microg/FakeStore');

      if (urls.isEmpty) {
        throw Exception(tr('noComponentsSelected'));
      }

      final errors = await appsProvider.addAppsByURL(urls);
      
      if (errors.isNotEmpty && errors.length == urls.length) {
        throw Exception('${tr('deploymentError')}: ${errors.map((e) => e[1]).join(", ")}');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      
      final List<String> addedAppIds = [];
      appsProvider.apps.forEach((id, appInMemory) {
        if (urls.contains(appInMemory.app.url)) {
          addedAppIds.add(id);
        }
      });

      if (addedAppIds.isNotEmpty) {
        await appsProvider.downloadAndInstallLatestApps(
          appIds: addedAppIds,
          context: context,
        );
      }
      
      // We don't pop immediately, but wait for progress to start or show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('deploymentStartedMessage'))),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => GlassDialog(
            title: tr('deploymentError'),
            icon: Icons.error_outline,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('close'))),
            ],
          ),
        );
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appsProvider = context.watch<AppsProvider>();
    
    // Calculate overall progress from selected components
    double overallProgress = 0;
    int trackedCount = 0;
    
    if (_isDownloading) {
      final List<String> urls = [];
      final String repoPrefix = _providers[_selectedProvider]!;
      if (_installGmsCore) urls.add('https://github.com/$repoPrefix');
      if (_installGsfProxy) urls.add('https://github.com/microg/GsfProxy');
      if (_installFakeStore) urls.add('https://github.com/microg/FakeStore');

      for (var url in urls) {
        final app = appsProvider.apps.values.firstWhere(
          (a) => a.app.url == url,
          orElse: () => AppInMemory(App(id: '', name: '', url: ''), null, null, null),
        );
        if (app.app.id.isNotEmpty) {
          overallProgress += app.downloadProgress ?? 0;
          trackedCount++;
        }
      }
      if (trackedCount > 0) {
        overallProgress /= trackedCount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('microGHub')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(cs),
          const SizedBox(height: 24),
          _buildProviderSection(cs),
          const SizedBox(height: 24),
          _buildComponentsSection(cs),
          const SizedBox(height: 24),
          _buildOptionsSection(cs),
          const SizedBox(height: 32),
          if (_isDownloading)
            Column(
              children: [
                Text('${tr('deployingComponents')} ${(overallProgress * 100).toInt()}%'),
                const SizedBox(height: 8),
                ExpressiveProgressIndicator(
                  value: overallProgress > 0 ? overallProgress : null,
                  color: cs.primary,
                ),
                if (overallProgress >= 1.0 || (trackedCount > 0 && overallProgress == 0))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () => setState(() => _isDownloading = false),
                      child: Text(tr('done')),
                    ),
                  ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: _startDeployment,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text(tr('startDeployment')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
    return Card(
      elevation: 0,
      color: cs.secondaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.secondaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                tr('microGHubInfo'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('selectProvider'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProvider,
              isExpanded: true,
              items: _providers.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedProvider = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComponentsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('componentsToInstall'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text(tr('gmsCore')),
          subtitle: Text(tr('gmsCoreDescription')),
          value: _installGmsCore,
          onChanged: (val) => setState(() => _installGmsCore = val ?? false),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(tr('gsfProxy')),
          subtitle: Text(tr('gsfProxyDescription')),
          value: _installGsfProxy,
          onChanged: (val) => setState(() => _installGsfProxy = val ?? false),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(tr('fakeStore')),
          subtitle: Text(tr('fakeStoreDescription')),
          value: _installFakeStore,
          onChanged: (val) => setState(() => _installFakeStore = val ?? false),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildOptionsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('deploymentOptions'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(tr('officialMicroGRoot')),
          subtitle: Text(_isRooted ? tr('rootAvailable') : tr('rootNotDetected')),
          value: _isRooted,
          onChanged: _isRooted ? (val) {} : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
