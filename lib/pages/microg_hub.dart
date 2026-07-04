import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/models/app.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/utils/app_constants.dart';

class MicroGHubPage extends StatefulWidget {
  const MicroGHubPage({super.key});

  @override
  State<MicroGHubPage> createState() => _MicroGHubPageState();
}

class _MicroGHubPageState extends State<MicroGHubPage> {
  static const _platform = MethodChannel('dev.thejaustin.obtainiumplus/native');
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
        throw Exception(
          '${tr('deploymentError')}: ${errors.map((e) => e[1]).join(", ")}',
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final List<String> addedAppIds = [];
      appsProvider.apps.forEach((id, appInMemory) {
        if (urls.contains(appInMemory.app.url)) {
          addedAppIds.add(id);
        }
      });

      if (addedAppIds.isNotEmpty) {
        await appsProvider.downloadAndInstallLatestApps(addedAppIds, context);
      }

      // We don't pop immediately, but wait for progress to start or show success
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('deploymentStartedMessage'))));
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
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('close')),
              ),
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
          orElse: () => AppInMemory(
            App('', '', '', '', null, '', [], 0, {}, null, false),
            null,
            null,
            null,
          ),
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
      appBar: AppBar(title: Text(tr('microGHub'))),
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
              _buildProgressSection(cs, overallProgress, trackedCount)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton.icon(
                  onPressed: _startDeployment,
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(tr('startDeployment')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
      ),
    );
  }

  Widget _buildProgressSection(
    ColorScheme cs,
    double overallProgress,
    int trackedCount,
  ) {
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${tr('deployingComponents')} ${(overallProgress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ExpressiveProgressIndicator(
              value: overallProgress > 0 ? overallProgress : null,
              height: 8,
              color: cs.primary,
            ),
            if (overallProgress >= 1.0 ||
                (trackedCount > 0 && overallProgress == 0))
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton(
                  onPressed: () => setState(() => _isDownloading = false),
                  child: Text(tr('done')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs) {
    return Card(
      elevation: 0,
      color: cs.secondaryContainer.withOpacity(AppOpacity.medium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.secondaryContainer.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.hub_outlined, color: cs.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('microGHub'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('microGHubInfo'),
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSecondaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
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
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            tr('selectProvider'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._providers.keys.map((String value) {
          final isSelected = _selectedProvider == value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer.withOpacity(0.5)
                  : cs.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outline.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: RadioListTile<String>(
              title: Text(
                value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                value.contains('Official')
                    ? 'github.com/microg'
                    : 'github.com/ReVanced',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? cs.onPrimaryContainer.withOpacity(0.7)
                      : cs.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              value: value,
              groupValue: _selectedProvider,
              onChanged: (val) {
                if (val != null) setState(() => _selectedProvider = val);
              },
              controlAffinity: ListTileControlAffinity.trailing,
              activeColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildComponentsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            tr('componentsToInstall'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildComponentTile(
          cs,
          tr('gmsCore'),
          tr('gmsCoreDescription'),
          _installGmsCore,
          (v) => setState(() => _installGmsCore = v!),
        ),
        _buildComponentTile(
          cs,
          tr('gsfProxy'),
          tr('gsfProxyDescription'),
          _installGsfProxy,
          (v) => setState(() => _installGsfProxy = v!),
        ),
        _buildComponentTile(
          cs,
          tr('fakeStore'),
          tr('fakeStoreDescription'),
          _installFakeStore,
          (v) => setState(() => _installFakeStore = v!),
        ),
      ],
    );
  }

  Widget _buildComponentTile(
    ColorScheme cs,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildOptionsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            tr('deploymentOptions'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SwitchListTile(
            title: Text(
              tr('officialMicroGRoot'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _isRooted ? tr('rootAvailable') : tr('rootNotDetected'),
            ),
            value: _isRooted,
            onChanged: _isRooted ? (val) {} : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            secondary: Icon(
              _isRooted
                  ? Icons.verified_user
                  : Icons.no_encryption_gmailerrorred,
              color: _isRooted ? cs.primary : cs.error,
            ),
          ),
        ),
      ],
    );
  }
}
