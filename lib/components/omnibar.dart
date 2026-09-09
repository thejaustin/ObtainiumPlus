import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/components/unsupported_source_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/app_sources/githubpersonalrepos.dart';
import 'package:obtainium/app_sources/githubstars.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/ui_widgets.dart';

/// Directly runs the GitHub mass-source import flow from any context,
/// without needing to navigate to ImportExportPage first.
Future<void> _runMassImport(
  BuildContext context,
  MassAppUrlSource source,
) async {
  final appsProvider = context.read<AppsProvider>();

  final values = await showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (ctx) => GeneratedFormModal(
      title: tr('importX', args: [source.name]),
      items: source.requiredArgs
          .map((e) => [GeneratedFormTextField(e, label: e)])
          .toList(),
    ),
  );
  if (values == null) return;
  if (!context.mounted) return;

  // Show a non-dismissible loading dialog while fetching.
  final nav = Navigator.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: ExpressiveCircularProgressIndicator()),
  );

  try {
    final urlsWithDescriptions = await source.getUrlsWithDescriptions(
      values.values.map((e) => e.toString()).toList(),
    );
    nav.pop(); // close loading
    if (!context.mounted) return;

    if (urlsWithDescriptions.isEmpty) {
      showError(ObtainiumError(tr('noResults')), context);
      return;
    }

    final selectedUrls = await showDialog<List<String>?>(
      context: context,
      builder: (ctx) => SelectionModal(entries: urlsWithDescriptions),
    );
    if (!context.mounted) return;

    if (selectedUrls != null && selectedUrls.isNotEmpty) {
      final errors = await appsProvider.addAppsByURL(selectedUrls);
      if (!context.mounted) return;
      if (errors.isEmpty) {
        showMessage(
          tr(
            'importedX',
            args: [plural('apps', selectedUrls.length).toLowerCase()],
          ),
          context,
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => ImportErrorDialog(
            urlsLength: selectedUrls.length,
            errors: errors,
          ),
        );
      }
    }
  } catch (e) {
    try {
      nav.pop();
    } catch (_) {} // dismiss loading if still showing
    if (context.mounted) showError(e, context);
  }
}

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
  final SourceProvider _sourceProvider = SourceProvider();

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
      String trimmed = input.trim();
      bool hasScheme =
          trimmed.startsWith('http://') ||
          trimmed.startsWith('https://') ||
          trimmed.startsWith('market://');

      bool isKnownRepoUrl =
          trimmed.contains('/') &&
          (trimmed.startsWith('github.com') ||
              trimmed.startsWith('gitlab.com') ||
              trimmed.startsWith('codeberg.org') ||
              trimmed.startsWith('f-droid.org') ||
              trimmed.startsWith('apkpure.com') ||
              trimmed.startsWith('aptoide.com'));

      _isUrl = hasScheme || isKnownRepoUrl;

      if (_isUrl) {
        final urlToTest = hasScheme ? trimmed : 'https://$trimmed';
        try {
          final src = _sourceProvider.getSource(urlToTest);
          if (src.runtimeType.toString() == 'HTML') {
            _isValidUrl = false;
            _urlError = tr('unsupportedUrl');
          } else {
            _isValidUrl = true;
            _urlError = null;
          }
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
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (value.trim().isEmpty) {
        widget.onSearchQuery?.call('');
        return;
      }

      if (!_isUrl) {
        // Search query
        widget.onSearchQuery?.call(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final itemRadius = (radius * 0.66).clamp(12.0, 32.0);

    return Semantics(
      label: _isUrl ? tr('appURLList') : tr('search'),
      textField: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Easing.standard,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: settings.plusEnableGlassmorphism ? 0.45 : 0.7,
          ),
          borderRadius: BorderRadius.circular(itemRadius),
          border: Border.all(
            color: _isValidUrl
                ? colorScheme.primary.withValues(alpha: AppOpacity.half)
                : _urlError != null
                ? colorScheme.error.withValues(alpha: AppOpacity.half)
                : colorScheme.outline.withValues(
                    alpha: settings.plusEnableGlassmorphism
                        ? 0.15
                        : AppOpacity.medium,
                  ),
            width: 1.5,
          ),
          boxShadow: settings.plusEnableGlassmorphism
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(itemRadius),
          child: Stack(
            children: [
              // Backdrop blur clipped to the bar — must stay inside
              // ClipRRect or it blurs the whole screen behind it
              if (settings.plusEnableGlassmorphism)
                Positioned.fill(
                  child: ConditionalBlur(
                    enabled: true,
                    sigma: 10,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              // Inner sheen
              if (settings.plusEnableGlassmorphism)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  // Icon indicating input type — AnimatedSwitcher for smooth transitions
                  InkWell(
                    borderRadius: BorderRadius.circular(itemRadius),
                    onTap: () {
                      if (!_isUrl) {
                        CommandCenter.show(
                          context,
                          initialQuery: _controller.text.trim(),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: Icon(
                          _isUrl
                              ? (_isValidUrl ? Icons.link : Icons.link_off)
                              : Icons.search,
                          key: ValueKey(
                            'icon_${_isUrl ? (_isValidUrl ? 'valid' : 'invalid') : 'search'}',
                          ),
                          color: _isValidUrl
                              ? colorScheme.primary
                              : _urlError != null
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Input field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _isUrl
                            ? (_isValidUrl
                                  ? tr('validUrlEnterToAdd')
                                  : tr('invalidUrl'))
                            : tr('searchOrEnterUrl'),
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
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
                          // Local filtering alone is a dead end if the app
                          // isn't tracked yet — escalate to the full
                          // local+discover search so there's always a path
                          // to find and add it.
                          CommandCenter.show(context, initialQuery: value);
                        }
                      },
                      keyboardType: _isUrl
                          ? TextInputType.url
                          : TextInputType.text,
                      textInputAction: TextInputAction.search,
                    ),
                  ),

                  // Clear button
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: _controller.text.isNotEmpty
                        ? Semantics(
                            label: tr('clear'),
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _controller.clear();
                                _handleInput('');
                              },
                              padding: const EdgeInsets.only(right: 8),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Action button: Add for URLs, or Search Online for text queries
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: _isUrl
                        ? Container(
                            margin: const EdgeInsets.only(
                              right: 6,
                              top: 6,
                              bottom: 6,
                            ),
                            child: Semantics(
                              label: tr('add'),
                              button: true,
                              child: FilledButton.tonal(
                                onPressed: _isValidUrl
                                    ? () {
                                        final text = _controller.text.trim();
                                        final urlToAdd =
                                            text.startsWith('http://') ||
                                                    text.startsWith('https://') ||
                                                    text.startsWith('market://')
                                                ? text
                                                : 'https://$text';
                                        widget.onUrlInput?.call(urlToAdd);
                                      }
                                    : () {
                                        // Show unsupported source dialog
                                        final supportedSources = _sourceProvider
                                            .sources
                                            .where((s) => s.hosts.isNotEmpty)
                                            .map((s) => s.name)
                                            .toList();

                                        showUnsupportedSourceDialog(
                                          context: context,
                                          suggestedSources: supportedSources
                                              .take(8)
                                              .toList(),
                                          failedUrl: _controller.text,
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _isValidUrl
                                      ? colorScheme.primary
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      itemRadius * 0.8,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _isValidUrl ? tr('add') : tr('sources'),
                                ),
                              ),
                            ),
                          )
                        : (_controller.text.trim().isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(
                                  right: 6,
                                  top: 6,
                                  bottom: 6,
                                ),
                                child: Semantics(
                                  label: tr('search'),
                                  button: true,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () {
                                      CommandCenter.show(
                                        context,
                                        initialQuery: _controller.text.trim(),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.travel_explore_rounded,
                                      size: 16,
                                    ),
                                    label: Text(tr('search')),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          itemRadius * 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAB menu for quick app actions
class AppActionsFAB extends StatelessWidget {
  const AppActionsFAB({super.key});

  static void showAddAppMenu(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final sheetRadius = radius.clamp(24.0, 48.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      // Without this, the sheet is hard-capped at 9/16 of screen height
      // by Flutter's default modal route regardless of our own
      // constraints below, and — combined with mainAxisSize.min further
      // down not actually bounding the Flexible/scroll area — content
      // could run past the visible sheet instead of scrolling within it.
      isScrollControlled: true,
      builder: (ctx) {
        final sheet = Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(
              alpha: enableGlass ? AppConstants.glassSurfaceAlpha : 1.0,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
            border: Border(
              top: BorderSide(
                color: enableGlass
                    ? colorScheme.onSurface.withValues(
                        alpha: AppConstants.glassBorderAlpha,
                      )
                    : colorScheme.outline.withValues(alpha: AppOpacity.hint),
              ),
              left: BorderSide(
                color: colorScheme.onSurface.withValues(
                  alpha: enableGlass ? 0.12 : 0,
                ),
              ),
              right: BorderSide(
                color: colorScheme.onSurface.withValues(
                  alpha: enableGlass ? 0.12 : 0,
                ),
              ),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const DragHandle(width: 40),
                  const SizedBox(height: 20),

                  // Title — a plain tap on the FAB already opens the
                  // unified search+add (CommandCenter); this long-press
                  // menu is only for the less-common actions.
                  Text(
                    tr('moreAddOptions'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add by URL
                          if (settings.plusFabShowAddByUrl)
                            _buildMenuItem(
                              context,
                              icon: Icons.link_outlined,
                              title: tr('addAppByUrl'),
                              subtitle: tr('addAppByUrlDescription'),
                              onTap: () {
                                Navigator.pop(context);
                                showAddAppSheet(context: context);
                              },
                            ),

                          if (settings.plusFabShowGithubStarred)
                            _buildMenuItem(
                              context,
                              icon: Icons.star_border_rounded,
                              title: tr('importGithubStarredRepos'),
                              subtitle: tr(
                                'importGithubStarredReposDescription',
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _runMassImport(
                                  context,
                                  SourceProvider().massUrlSources.firstWhere(
                                    (s) => s is GitHubStars,
                                    orElse: () => GitHubStars(),
                                  ),
                                );
                              },
                            ),

                          if (settings.plusFabShowGithubPersonalRepos)
                            _buildMenuItem(
                              context,
                              icon: Icons.person_outline_rounded,
                              title: tr('githubPersonalRepos'),
                              subtitle: tr('githubPersonalReposDescription'),
                              onTap: () {
                                Navigator.pop(context);
                                _runMassImport(
                                  context,
                                  SourceProvider().massUrlSources.firstWhere(
                                    (s) => s is GitHubPersonalRepos,
                                    orElse: () => GitHubPersonalRepos(),
                                  ),
                                );
                              },
                            ),

                          if (settings.plusFabShowImportInstalled)
                            _buildMenuItem(
                              context,
                              icon: Icons.install_mobile_outlined,
                              title: tr('importInstalledApps'),
                              subtitle: tr('importInstalledAppsDescription'),
                              onTap: () {
                                Navigator.pop(context);
                                showSystemAppSelectorSheet(context: context);
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr('comingSoon'))),
                                );
                              },
                            ),

                          // Fallback when every item is disabled
                          if (!settings.plusFabShowAddByUrl &&
                              !settings.plusFabShowGithubStarred &&
                              !settings.plusFabShowGithubPersonalRepos &&
                              !settings.plusFabShowImportInstalled &&
                              !settings.plusDeveloperMode)
                            _buildMenuItem(
                              context,
                              icon: Icons.link_outlined,
                              title: tr('addAppByUrl'),
                              subtitle: tr('addAppByUrlDescription'),
                              onTap: () {
                                Navigator.pop(context);
                                showAddAppSheet(context: context);
                              },
                            ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!enableGlass) return sheet;
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppConstants.glassBlurSigma,
              sigmaY: AppConstants.glassBlurSigma,
            ),
            child: sheet,
          ),
        );
      },
    );
  }

  static Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? containerColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final itemRadius = (radius * 0.5).clamp(8.0, 16.0);

    return ScaleTouchWrapper(
      onTap: onTap,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                containerColor ??
                colorScheme.primaryContainer.withValues(alpha: AppOpacity.half),
            borderRadius: BorderRadius.circular(itemRadius),
          ),
          child: Icon(icon, color: iconColor ?? colorScheme.primary),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(itemRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fabRadius = (settings.plusGlobalCornerRadius * 0.66).clamp(
      12.0,
      28.0,
    );

    // One FAB instead of two: a tap opens the unified search+add
    // (CommandCenter) directly — the action people need almost every
    // time — and a long-press reveals the less-common extras (add by
    // URL form, GitHub bulk imports, etc.) instead of always showing
    // them up front.
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Semantics(
      label: tr('addApp'),
      hint: tr('moreAddOptionsHint'),
      button: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(fabRadius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // A plain FloatingActionButton has its own internal tap
        // recognizer; wrapping it in an outer GestureDetector for
        // long-press put two recognizers in the same gesture arena,
        // which delayed/could suppress the tap. A single Material+InkWell
        // handles both gestures on one recognizer instead, so this
        // manually replicates FAB.extended's look (56dp min height,
        // icon+label row) rather than using the FAB widget itself.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(fabRadius),
            onTap: () {
              AppHaptics.selectionClick();
              CommandCenter.show(context);
            },
            onLongPress: () {
              AppHaptics.heavyImpact();
              showAddAppMenu(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: onPrimary),
                  const SizedBox(width: 8),
                  Text(tr('addApp'), style: TextStyle(color: onPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
