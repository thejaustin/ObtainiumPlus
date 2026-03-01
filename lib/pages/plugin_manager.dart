import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plugin_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Manager'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Install Plugin', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Enter a direct URL to a JavaScript plugin file (e.g. from GitHub Raw).', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Plugin URL',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            if (_urlController.text.isNotEmpty) {
                              pluginProvider.installFromUrl(_urlController.text);
                              _urlController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Installed Plugins', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (pluginProvider.plugins.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No plugins installed'),
              ),
            )
          else
            ...pluginProvider.plugins.map((plugin) => ListTile(
              leading: const Icon(Icons.extension),
              title: Text(plugin.name),
              subtitle: Text(plugin.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => pluginProvider.removePlugin(plugin.id),
              ),
            )),
        ],
      ),
    );
  }
}
