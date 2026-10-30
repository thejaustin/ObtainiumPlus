import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plugin_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';

class PluginManagerPage extends StatefulWidget {
  const PluginManagerPage({super.key});

  @override
  State<PluginManagerPage> createState() => _PluginManagerPageState();
}

class _PluginManagerPageState extends State<PluginManagerPage> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pluginProvider = context.watch<PluginProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Manager')),
      body: ListView(
        physics: plusSettings.scrollPhysics,
        padding: EdgeInsets.symmetric(horizontal: adaptiveMargin, vertical: 16),
        children: [
          _buildInstallCard(cs, pluginProvider, plusSettings, cardRadius),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16),
            child: Text(
              'Installed Plugins',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (pluginProvider.plugins.isEmpty)
            _buildEmptyState(cs)
          else
            ...pluginProvider.plugins.map(
              (plugin) => _buildPluginTile(
                cs,
                plugin,
                pluginProvider,
                plusSettings,
                cardRadius,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallCard(
    ColorScheme cs,
    PluginProvider pluginProvider,
    PlusSettingsProvider plusSettings,
    double cardRadius,
  ) {
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: CardMetrics.shape(
        cardRadius,
        expressive: isM3E,
        side: BorderSide(
          color: cs.outlineVariant.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.35
                : 0.65,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_link_rounded, color: cs.primary),
                const SizedBox(width: 12),
                const Text(
                  'Install New Plugin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a direct URL to a JavaScript plugin file (e.g. from GitHub Raw). Plugins can extend Obtainium\'s source support.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _urlController,
              builder: (context, val, _) {
                final isFocused = _urlFocusNode.hasFocus;
                final hasText = val.text.isNotEmpty;
                final isActive = isFocused || hasText;

                return AnimatedContainer(
                  duration: Duration(
                    milliseconds: plusSettings.plusEnableEnhancedAnimations
                        ? 280
                        : 0,
                  ),
                  curve: Easing.emphasizedDecelerate,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isActive ? 16.0 : 26.0),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.14),
                              blurRadius: 12,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Plugin URL',
                      hintText:
                          'https://raw.githubusercontent.com/.../plugin.js',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          isActive ? 16.0 : 26.0,
                        ),
                        borderSide: BorderSide(
                          color: isActive
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.4),
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: cs.primary, width: 1.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          isActive ? 16.0 : 26.0,
                        ),
                        borderSide: BorderSide(
                          color: isActive
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.4),
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasText)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _urlController.clear();
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ScaleTouchWrapper(
                              hapticOnPressDown: true,
                              scaleDownFactor: 0.90,
                              child: IconButton.filledTonal(
                                icon: const Icon(Icons.download_rounded),
                                onPressed: () {
                                  if (_urlController.text.isNotEmpty) {
                                    AppHaptics.selectionClick();
                                    pluginProvider.installFromUrl(
                                      _urlController.text,
                                    );
                                    _urlController.clear();
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 64,
              color: cs.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No plugins installed',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginTile(
    ColorScheme cs,
    dynamic plugin,
    PluginProvider pluginProvider,
    PlusSettingsProvider plusSettings,
    double cardRadius,
  ) {
    final innerRadius = CardMetrics.inner(cardRadius);
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final tileShape = CardMetrics.shape(
      cardRadius,
      expressive: isM3E,
      side: BorderSide(
        color: cs.outlineVariant.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.65,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerLow,
        shape: tileShape,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.55),
              shape: CardMetrics.shape(innerRadius, expressive: isM3E),
            ),
            child: Icon(Icons.extension_rounded, color: cs.primary),
          ),
          title: Text(
            plugin.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            plugin.description,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          trailing: ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.88,
            child: IconButton.filledTonal(
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: () {
                AppHaptics.heavyImpact();
                pluginProvider.removePlugin(plugin.id);
              },
              style: IconButton.styleFrom(
                backgroundColor: cs.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ),
          shape: tileShape,
        ),
      ),
    );
  }
}
