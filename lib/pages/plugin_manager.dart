import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plugin_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:easy_localization/easy_localization.dart';

class PluginManagerPage extends StatefulWidget {
  const PluginManagerPage({super.key});

  @override
  State<PluginManagerPage> createState() => _PluginManagerPageState();
}

class _PluginManagerPageState extends State<PluginManagerPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final pluginProvider = context.watch<PluginProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Manager')),
      body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInstallCard(cs, pluginProvider),
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
                (plugin) => _buildPluginTile(cs, plugin, pluginProvider),
              ),
          ],
      ),
    );
  }

  Widget _buildInstallCard(ColorScheme cs, PluginProvider pluginProvider) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
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
                color: cs.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Plugin URL',
                hintText: 'https://raw.githubusercontent.com/.../plugin.js',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: cs.surface.withOpacity(0.5),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () {
                      if (_urlController.text.isNotEmpty) {
                        pluginProvider.installFromUrl(_urlController.text);
                        _urlController.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ),
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
              color: cs.outline.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No plugins installed',
              style: TextStyle(
                color: cs.onSurfaceVariant.withOpacity(0.5),
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
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.extension_rounded, color: cs.secondary),
        ),
        title: Text(
          plugin.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          plugin.description,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        trailing: IconButton.filledTonal(
          icon: Icon(Icons.delete_outline_rounded, color: cs.error),
          onPressed: () => pluginProvider.removePlugin(plugin.id),
          style: IconButton.styleFrom(
            backgroundColor: cs.errorContainer.withOpacity(0.3),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
