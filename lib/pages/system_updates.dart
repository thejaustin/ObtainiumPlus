import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/play_store_mirror_service.dart';
import 'package:obtainium/utils/card_metrics.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final stateKey = _isScanning
        ? 'scanning'
        : (_updates.isEmpty ? 'empty' : 'results');

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    Widget body;
    if (!_isScanning && _updates.isEmpty) {
      body = EmptyStateWidget(
        key: const ValueKey('empty'),
        icon: Icons.system_update_alt_rounded,
        title: tr('scanForUpdates'),
        subtitle: tr('plusSystemUpdateScannerDescription'),
        actionLabel: tr('scanForUpdates'),
        onActionPressed: () {
          AppHaptics.selectionClick();
          _startScan();
        },
      );
    } else if (_isScanning) {
      body = Center(
        key: const ValueKey('scanning'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ExpressiveCircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              tr('scanningXApps', args: [_scanTotal.toString()]),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '$_scanCurrent / $_scanTotal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              child: ExpressiveProgressIndicator(
                value: _scanTotal > 0 ? _scanCurrent / _scanTotal : null,
              ),
            ),
          ],
        ),
      );
    } else {
      body = Scaffold(
        key: const ValueKey('results'),
        body: ListView.builder(
          physics: plusSettings.scrollPhysics,
          padding: EdgeInsets.fromLTRB(
            adaptiveMargin,
            8,
            adaptiveMargin,
            MediaQuery.paddingOf(context).bottom + 88,
          ),
          itemCount: _updates.length,
          itemBuilder: (context, index) {
            final update = _updates[index];
            return _buildUpdateCard(update);
          },
        ),
        floatingActionButton: ScaleTouchWrapper(
          hapticOnPressDown: true,
          scaleDownFactor: 0.95,
          child: FloatingActionButton(
            onPressed: () {
              AppHaptics.selectionClick();
              _startScan();
            },
            tooltip: tr('refresh'),
            child: const Icon(Icons.refresh),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: animsEnabled ? 300 : 0),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: KeyedSubtree(key: ValueKey(stateKey), child: body),
    );
  }

  Widget _buildUpdateCard(ExternalAppUpdate update) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: CardMetrics.shape(
        cardRadius,
        expressive: isM3E,
        side: BorderSide(
          color: cs.outlineVariant.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.35 : 0.65,
          ),
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('system_update:${update.appId}'),
        onExpansionChanged: (_) => AppHaptics.selectionClick(),
        expansionAnimationStyle: AnimationStyle(
          curve: Easing.emphasizedDecelerate,
          reverseCurve: Easing.emphasizedAccelerate,
          duration: const Duration(milliseconds: 280),
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(
            update.name.isNotEmpty ? update.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          update.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${update.currentVersion} → ${update.latestVersion}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                        DropdownMenu<String>(
                          key: ValueKey(settings.preferredUpdateSource),
                          initialSelection: settings.preferredUpdateSource,
                          inputDecorationTheme: const InputDecorationTheme(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onSelected: (String? newValue) {
                            if (newValue != null) {
                              AppHaptics.selectionClick();
                              settings.preferredUpdateSource = newValue;
                            }
                          },
                          dropdownMenuEntries: [
                            DropdownMenuEntry(
                              value: 'play_store',
                              label: tr('playStore'),
                            ),
                            const DropdownMenuEntry(
                              value: 'aurora',
                              label: 'Aurora Store',
                            ),
                            const DropdownMenuEntry(
                              value: 'github',
                              label: 'GitHub',
                            ),
                            const DropdownMenuEntry(
                              value: 'apkpure',
                              label: 'APKPure',
                            ),
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
                            source:
                                settings.preferredUpdateSource == 'play_store'
                                ? 'play_store'
                                : 'play_store',
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
                    ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: Text(tr('addToObtainium')),
                        subtitle: Text(tr('trackFromGooglePlay')),
                        onTap: () async {
                          AppHaptics.selectionClick();
                          final appsProvider = context.read<AppsProvider>();
                          final url =
                              'https://play.google.com/store/apps/details?id=${update.appId}';
                          await appsProvider.addAppsByURL([url]);
                          if (mounted && context.mounted) {
                            AppHaptics.success();
                            setState(
                              () => _updates.removeWhere(
                                (u) => u.appId == update.appId,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('appAlreadyAdded'))),
                            );
                          }
                        },
                      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          scaleDownFactor: 0.90,
          child: IconButton.filledTonal(
            onPressed: () {
              AppHaptics.selectionClick();
              onPressed();
            },
            icon: Icon(icon),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
