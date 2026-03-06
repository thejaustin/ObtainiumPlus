import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/unsupported_source_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';

/// Omnibar widget that combines search, URL input, and app discovery
/// Replaces separate search bars with unified input
class Omnibar extends StatefulWidget {
  final Function(String)? onSearchQuery;
  final Function(String)? onUrlInput;
  final String? initialQuery;
  final bool showDiscoverOptions;

  const Omnibar({
    super.key,
    this.onSearchQuery,
    this.onUrlInput,
    this.initialQuery,
    this.showDiscoverOptions = true,
  });

  @override
  State<Omnibar> createState() => _OmnibarState();
}

class _OmnibarState extends State<Omnibar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isUrl = false;
  bool _isValidUrl = false;
  String? _urlError;
  SourceProvider _sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _checkInputType(_controller.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkInputType(String input) {
    setState(() {
      _isUrl = input.trim().startsWith('http://') || 
               input.trim().startsWith('https://') ||
               input.trim().startsWith('market://');
      
      if (_isUrl) {
        try {
          _sourceProvider.getSource(input);
          _isValidUrl = true;
          _urlError = null;
        } catch (e) {
          _isValidUrl = false;
          _urlError = e is UnsupportedURLError 
              ? tr('unsupportedUrl') 
              : e.toString();
        }
      } else {
        _isValidUrl = false;
        _urlError = null;
      }
    });
  }

  void _handleInput(String value) {
    _checkInputType(value);
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        widget.onSearchQuery?.call('');
        return;
      }

      if (_isUrl && _isValidUrl) {
        // Valid URL - trigger add app
        widget.onUrlInput?.call(value);
      } else if (!_isUrl) {
        // Search query
        widget.onSearchQuery?.call(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isValidUrl 
              ? colorScheme.primary.withValues(alpha: 0.5)
              : _urlError != null
                  ? colorScheme.error.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon indicating input type
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              _isUrl 
                  ? (_isValidUrl ? Icons.link : Icons.link_off)
                  : Icons.search,
              color: _isValidUrl
                  ? colorScheme.primary
                  : _urlError != null
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          
          // Input field
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _isUrl 
                    ? (_isValidUrl ? tr('validUrlEnterToAdd') : tr('invalidUrl'))
                    : tr('searchOrEnterUrl'),
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onChanged: _handleInput,
              onSubmitted: (value) {
                if (_isUrl && _isValidUrl) {
                  widget.onUrlInput?.call(value);
                } else if (!_isUrl && value.isNotEmpty) {
                  widget.onSearchQuery?.call(value);
                }
              },
              keyboardType: _isUrl 
                  ? TextInputType.url 
                  : TextInputType.text,
              textInputAction: TextInputAction.search,
            ),
          ),
          
          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                _handleInput('');
              },
              padding: const EdgeInsets.only(right: 8),
            ),
          
          // Add button (for URLs)
          if (_isUrl)
            Container(
              margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: FilledButton.tonal(
                onPressed: _isValidUrl 
                    ? () => widget.onUrlInput?.call(_controller.text)
                    : () {
                        // Show unsupported source dialog
                        final supportedSources = _sourceProvider.sources
                            .where((s) => s.hosts.isNotEmpty)
                            .map((s) => s.name)
                            .toList();
                        
                        showUnsupportedSourceDialog(
                          context: context,
                          suggestedSources: supportedSources.take(8).toList(),
                          failedUrl: _controller.text,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _isValidUrl 
                      ? colorScheme.primary
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(_isValidUrl ? tr('add') : tr('error')),
              ),
            ),
        ],
      ),
    );
  }
}

/// FAB menu for quick app actions
class AppActionsFAB extends StatelessWidget {
  const AppActionsFAB({super.key});

  void _showAddAppMenu(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    final settings = context.read<SettingsProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  tr('addApp'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Menu items
                _buildMenuItem(
                  context,
                  icon: Icons.link_outlined,
                  title: tr('addAppByUrl'),
                  subtitle: tr('addAppByUrlDescription'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAppPage()),
                    );
                  },
                ),
                
                _buildMenuItem(
                  context,
                  icon: Icons.search_outlined,
                  title: tr('discoverApps'),
                  subtitle: tr('discoverAppsDescription'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('comingSoon'))),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.code_outlined,
                  title: tr('importGithubStarredRepos'),
                  subtitle: tr('importGithubStarredReposDescription'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ImportExportPage()),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.install_mobile_outlined,
                  title: tr('importInstalledApps'),
                  subtitle: tr('importInstalledAppsDescription'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SystemAppSelector()),
                    );
                  },
                ),
                
                if (settings.plusDeveloperMode)
                  _buildMenuItem(
                    context,
                    icon: Icons.qr_code_scanner_outlined,
                    title: tr('scanQRCode'),
                    subtitle: tr('scanQRCodeDescription'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement QR scanner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('comingSoon'))),
                      );
                    },
                  ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddAppMenu(context),
      icon: const Icon(Icons.add),
      label: Text(tr('addApp')),
      elevation: 4,
    );
  }
}
