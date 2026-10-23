import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/components/unsupported_source_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/app_sources/githubpersonalrepos.dart';
import 'package:obtainium/app_sources/githubstars.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
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

  var loadingOpen = true;
  try {
    final urlsWithDescriptions = await source.getUrlsWithDescriptions(
      values.values.map((e) => e.toString()).toList(),
    );
    nav.pop(); // close loading
    loadingOpen = false;
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
    if (loadingOpen) {
      try {
        nav.pop();
      } catch (_) {} // dismiss loading if still showing
    }
    if (context.mounted) showError(e, context);
  }
}

/// Omnibar widget that combines search, URL input, and app discovery
/// Replaces separate search bars with unified input
class Omnibar extends StatefulWidget {
  final Function(String)? onSearchQuery;
  final Function(String)? onUrlInput;
  final Function(String)? onDiscoverSearch;
  final String? initialQuery;
  final bool showDiscoverOptions;

  const Omnibar({
    super.key,
    this.onSearchQuery,
    this.onUrlInput,
    this.onDiscoverSearch,
    this.initialQuery,
    this.showDiscoverOptions = true,
  });

  @override
  State<Omnibar> createState() => _OmnibarState();
}

class _OmnibarState extends State<Omnibar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isUrl = false;
  bool _isValidUrl = false;
  String? _urlError;
  bool _isFocused = false;
  final SourceProvider _sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _checkInputType(_controller.text);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final pillRadius = CardMetrics.pill(radius);
    final isFocusedOrHasText = _isFocused || _controller.text.isNotEmpty;
    // Material 3 Expressive Shape Shifting:
    // Resting: full capsule pill (28dp)
    // Active/Focused: expressive squircle morphing (18-20dp) with primary glow and elevation!
    final currentRadius = isFocusedOrHasText
        ? (radius * 0.75).clamp(16.0, 22.0)
        : pillRadius;

    return Semantics(
      label: _isUrl ? tr('appURLList') : tr('search'),
      textField: true,
      child: AnimatedContainer(
        duration: Duration(milliseconds: animsEnabled ? 280 : 0),
        curve: Easing.emphasizedDecelerate,
        decoration: ShapeDecoration(
          color: isFocusedOrHasText
              ? colorScheme.surfaceContainerHighest.withValues(
                  alpha: plusSettings.plusEnableGlassmorphism ? 0.7 : 0.95,
                )
              : colorScheme.surfaceContainerHigh.withValues(
                  alpha: plusSettings.plusEnableGlassmorphism ? 0.45 : 0.7,
                ),
          shape: CardMetrics.shape(
            currentRadius,
            expressive: isM3E,
            side: BorderSide(
              color: _isValidUrl
                  ? colorScheme.primary
                  : _urlError != null
                  ? colorScheme.error
                  : isFocusedOrHasText
                  ? colorScheme.primary.withValues(alpha: 0.8)
                  : colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.65,
                    ),
              width: isFocusedOrHasText || _isValidUrl || _urlError != null
                  ? 1.8
                  : 1.0,
            ),
          ),
          shadows: isFocusedOrHasText
              ? [
                  BoxShadow(
                    color:
                        (_isValidUrl
                                ? colorScheme.primary
                                : _urlError != null
                                ? colorScheme.error
                                : colorScheme.primary)
                            .withValues(alpha: 0.16),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (plusSettings.plusEnableGlassmorphism
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ]
                    : null),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(currentRadius),
          child: Stack(
            children: [
              // Backdrop blur clipped to the bar — must stay inside
              // ClipRRect or it blurs the whole screen behind it
              if (plusSettings.plusEnableGlassmorphism)
                Positioned.fill(
                  child: ConditionalBlur(
                    enabled: true,
                    sigma: 10,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              // Inner sheen
              if (plusSettings.plusEnableGlassmorphism)
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
                    borderRadius: BorderRadius.circular(currentRadius),
                    onTap: () {
                      if (!_isUrl) {
                        final query = _controller.text.trim();
                        if (widget.onDiscoverSearch != null &&
                            query.isNotEmpty) {
                          widget.onDiscoverSearch!(query);
                        } else {
                          CommandCenter.show(context, initialQuery: query);
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        8,
                        6,
                        8,
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: animsEnabled ? 200 : 0,
                        ),
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
                      focusNode: _focusNode,
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
                        // The bar is the field: the theme's filled,
                        // outlined input would draw a second box inside it,
                        // leaving the search icon stranded outside.
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(
                          4,
                          14,
                          12,
                          14,
                        ),
                      ),
                      onChanged: _handleInput,
                      onSubmitted: (value) {
                        if (_isUrl && _isValidUrl) {
                          widget.onUrlInput?.call(value);
                        } else if (!_isUrl && value.isNotEmpty) {
                          if (widget.onDiscoverSearch != null) {
                            widget.onDiscoverSearch!(value.trim());
                          } else {
                            CommandCenter.show(context, initialQuery: value);
                          }
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
                    duration: Duration(milliseconds: animsEnabled ? 300 : 0),
                    curve: Curves.easeOutCubic,
                    child: _controller.text.isNotEmpty
                        ? ScaleTouchWrapper(
                            hapticOnPressDown: true,
                            scaleDownFactor: 0.88,
                            child: Semantics(
                              label: tr('clear'),
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                tooltip: tr('clear'),
                                onPressed: () {
                                  _controller.clear();
                                  _handleInput('');
                                },
                                padding: const EdgeInsets.only(right: 8),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Action button: Add for URLs, or Search Online for text queries
                  AnimatedSize(
                    duration: Duration(milliseconds: animsEnabled ? 300 : 0),
                    curve: Curves.easeOutCubic,
                    child: _isUrl
                        ? Container(
                            margin: const EdgeInsets.only(
                              right: 6,
                              top: 6,
                              bottom: 6,
                            ),
                            child: ScaleTouchWrapper(
                              hapticOnPressDown: true,
                              scaleDownFactor: 0.93,
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
                                          final supportedSources =
                                              _sourceProvider.sources
                                                  .where(
                                                    (s) => s.hosts.isNotEmpty,
                                                  )
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
                                    shape: CardMetrics.shape(
                                      pillRadius,
                                      expressive: isM3E,
                                    ),
                                  ),
                                  child: Text(
                                    _isValidUrl ? tr('add') : tr('sources'),
                                  ),
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
                                  child: ScaleTouchWrapper(
                                    hapticOnPressDown: true,
                                    scaleDownFactor: 0.93,
                                    child: Semantics(
                                      label: tr('search'),
                                      button: true,
                                      child: FilledButton.tonalIcon(
                                        onPressed: () {
                                          AppHaptics.selectionClick();
                                          final query = _controller.text.trim();
                                          if (widget.onDiscoverSearch != null) {
                                            widget.onDiscoverSearch!(query);
                                          } else {
                                            CommandCenter.show(
                                              context,
                                              initialQuery: query,
                                            );
                                          }
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
                                          shape: CardMetrics.shape(
                                            pillRadius,
                                            expressive: isM3E,
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

/// FAB menu for quick app actions with scroll-aware extended/compact morphing
/// and an animated Scroll-to-Top companion button.
class AppActionsFAB extends StatelessWidget {
  final ValueListenable<({bool isCollapsed, bool showScrollToTop})>?
  scrollStateListenable;
  final VoidCallback? onScrollToTop;

  const AppActionsFAB({
    super.key,
    this.scrollStateListenable,
    this.onScrollToTop,
  });

  static Future<String?> _readClipboardUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty || text.contains(' ') || text.length > 512) return null;
      final uri = Uri.tryParse(text);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.contains('.')) {
        return text;
      }
    } catch (_) {}
    return null;
  }

  static void showAddAppMenu(BuildContext context) {
    final plusSettings = context.read<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final sheetRadius = radius.clamp(24.0, 48.0);
    final clipboardUrlFuture = _readClipboardUrl();

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
            color: enableGlass
                ? colorScheme.surface.withValues(
                    alpha: AppConstants.glassSurfaceAlpha,
                  )
                : colorScheme.surfaceContainerLow,
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
                  const SizedBox(height: 16),

                  // Title header with category icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('moreAddOptions'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Smart Clipboard URL quick-add pill
                          FutureBuilder<String?>(
                            future: clipboardUrlFuture,
                            builder: (ctx, snap) {
                              final clipUrl = snap.data;
                              if (clipUrl == null) {
                                return const SizedBox.shrink();
                              }
                              final itemRadius = CardMetrics.inner(
                                CardMetrics.card(radius),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.35),
                                    shape: CardMetrics.shape(
                                      itemRadius,
                                      expressive: isM3E,
                                      side: BorderSide(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    shape: CardMetrics.shape(
                                      itemRadius,
                                      expressive: isM3E,
                                    ),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: ShapeDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.16,
                                        ),
                                        shape: CardMetrics.shape(
                                          itemRadius,
                                          expressive: isM3E,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.content_paste_go_rounded,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      tr('addAppByUrl'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.primary,
                                          ),
                                    ),
                                    subtitle: Text(
                                      clipUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    trailing: Icon(
                                      Icons.add_circle_rounded,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    onTap: () {
                                      AppHaptics.selectionClick();
                                      Navigator.pop(context);
                                      showAddAppSheet(
                                        context: context,
                                        initialUrl: clipUrl,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                          // Search & Discover (CommandCenter)
                          _buildMenuItem(
                            context,
                            icon: Icons.travel_explore_rounded,
                            title: tr('search'),
                            subtitle: tr('searchSourceRepos'),
                            containerColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.65),
                            iconColor: colorScheme.secondary,
                            onTap: () {
                              Navigator.pop(context);
                              CommandCenter.show(context);
                            },
                          ),

                          // Add by URL
                          if (plusSettings.plusFabShowAddByUrl)
                            _buildMenuItem(
                              context,
                              icon: Icons.link_rounded,
                              title: tr('addAppByUrl'),
                              subtitle: tr('addAppByUrlDescription'),
                              containerColor: colorScheme.primaryContainer
                                  .withValues(alpha: 0.6),
                              iconColor: colorScheme.primary,
                              onTap: () {
                                Navigator.pop(context);
                                showAddAppSheet(context: context);
                              },
                            ),

                          if (plusSettings.plusFabShowGithubStarred)
                            _buildMenuItem(
                              context,
                              icon: Icons.star_rounded,
                              title: tr('importGithubStarredRepos'),
                              subtitle: tr(
                                'importGithubStarredReposDescription',
                              ),
                              containerColor: Colors.amber.withValues(
                                alpha: 0.16,
                              ),
                              iconColor: Colors.amber.shade700,
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

                          if (plusSettings.plusFabShowGithubPersonalRepos)
                            _buildMenuItem(
                              context,
                              icon: Icons.person_rounded,
                              title: tr('githubPersonalRepos'),
                              subtitle: tr('githubPersonalReposDescription'),
                              containerColor: Colors.indigo.withValues(
                                alpha: 0.16,
                              ),
                              iconColor: Colors.indigo.shade400,
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

                          if (plusSettings.plusFabShowImportInstalled)
                            _buildMenuItem(
                              context,
                              icon: Icons.install_mobile_rounded,
                              title: tr('importInstalledApps'),
                              subtitle: tr('importInstalledAppsDescription'),
                              containerColor: Colors.teal.withValues(
                                alpha: 0.16,
                              ),
                              iconColor: Colors.teal.shade400,
                              onTap: () {
                                Navigator.pop(context);
                                showSystemAppSelectorSheet(context: context);
                              },
                            ),

                          if (plusSettings.plusDeveloperMode)
                            _buildMenuItem(
                              context,
                              icon: Icons.qr_code_scanner_rounded,
                              title: tr('scanQRCode'),
                              subtitle: tr('scanQRCodeDescription'),
                              containerColor: Colors.deepOrange.withValues(
                                alpha: 0.16,
                              ),
                              iconColor: Colors.deepOrange.shade400,
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr('comingSoon'))),
                                );
                              },
                            ),

                          // Fallback when every item is disabled
                          if (!plusSettings.plusFabShowAddByUrl &&
                              !plusSettings.plusFabShowGithubStarred &&
                              !plusSettings.plusFabShowGithubPersonalRepos &&
                              !plusSettings.plusFabShowImportInstalled &&
                              !plusSettings.plusDeveloperMode)
                            _buildMenuItem(
                              context,
                              icon: Icons.link_rounded,
                              title: tr('addAppByUrl'),
                              subtitle: tr('addAppByUrlDescription'),
                              containerColor: colorScheme.primaryContainer
                                  .withValues(alpha: 0.6),
                              iconColor: colorScheme.primary,
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

        return ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
          child: ConditionalBlur(
            enabled: enableGlass,
            sigma: AppConstants.glassBlurSigma,
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
    final plusSettings = context.read<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final itemRadius = CardMetrics.inner(CardMetrics.card(radius));

    void handleTap() {
      AppHaptics.selectionClick();
      onTap();
    }

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: ShapeDecoration(
            color:
                containerColor ??
                colorScheme.primaryContainer.withValues(alpha: AppOpacity.half),
            shape: CardMetrics.shape(itemRadius, expressive: isM3E),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        onTap: handleTap,
        shape: CardMetrics.shape(itemRadius, expressive: isM3E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final fabRadius = CardMetrics.pill(plusSettings.plusGlobalCornerRadius);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final colorScheme = Theme.of(context).colorScheme;
    final animEnabled = plusSettings.plusEnableEnhancedAnimations;

    Widget buildFabStack({
      required bool isCollapsed,
      required bool showScrollToTop,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onScrollToTop != null)
            AnimatedScale(
              scale: showScrollToTop ? 1.0 : 0.0,
              duration: Duration(milliseconds: animEnabled ? 260 : 120),
              curve: showScrollToTop
                  ? AppConstants.expressiveSpring
                  : Curves.easeInCubic,
              child: AnimatedOpacity(
                opacity: showScrollToTop ? 1.0 : 0.0,
                duration: Duration(milliseconds: animEnabled ? 200 : 100),
                child: IgnorePointer(
                  ignoring: !showScrollToTop,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, right: 4),
                    child: ScaleTouchWrapper(
                      hapticOnPressDown: false,
                      scaleDownFactor: 0.90,
                      child: Material(
                        color: colorScheme.surfaceContainerHigh,
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: CardMetrics.shape(
                          isM3E ? 16 : 20,
                          expressive: isM3E,
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.lightImpact();
                            onScrollToTop!();
                          },
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.vertical_align_top_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Semantics(
            label: tr('addApp'),
            hint: tr('moreAddOptionsHint'),
            button: true,
            child: ScaleTouchWrapper(
              scaleDownFactor: 0.95,
              hapticOnPressDown: false,
              child: Container(
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: CardMetrics.shape(
                    isCollapsed ? (isM3E ? 20 : 28) : fabRadius,
                    expressive: isM3E,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.36),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedSize(
                    duration: Duration(milliseconds: animEnabled ? 280 : 140),
                    curve: animEnabled
                        ? AppConstants.expressiveSpring
                        : Curves.easeOutCubic,
                    child: isCollapsed
                        ? InkWell(
                            customBorder: CardMetrics.shape(
                              isM3E ? 20 : 28,
                              expressive: isM3E,
                            ),
                            onTap: () {
                              AppHaptics.selectionClick();
                              CommandCenter.show(context);
                            },
                            onLongPress: () {
                              AppHaptics.heavyImpact();
                              showAddAppMenu(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Icon(
                                Icons.add_rounded,
                                color: onPrimary,
                                size: 24,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Primary action: opens CommandCenter
                              InkWell(
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(fabRadius),
                                ),
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  CommandCenter.show(context);
                                },
                                onLongPress: () {
                                  AppHaptics.heavyImpact();
                                  showAddAppMenu(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    12,
                                    14,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        color: onPrimary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('addApp'),
                                        style: TextStyle(
                                          color: onPrimary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Subtle vertical divider between the main button and options affordance
                              Container(
                                width: 1,
                                height: 20,
                                color: onPrimary.withValues(alpha: 0.25),
                              ),
                              // Secondary action affordance: directly opens the quick options menu
                              Tooltip(
                                message: tr('moreAddOptions'),
                                child: InkWell(
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(fabRadius),
                                  ),
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    showAddAppMenu(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      14,
                                      14,
                                      14,
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: onPrimary.withValues(alpha: 0.92),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (scrollStateListenable == null) {
      return buildFabStack(isCollapsed: false, showScrollToTop: false);
    }
    return ValueListenableBuilder<({bool isCollapsed, bool showScrollToTop})>(
      valueListenable: scrollStateListenable!,
      builder: (context, state, _) => buildFabStack(
        isCollapsed: state.isCollapsed,
        showScrollToTop: state.showScrollToTop,
      ),
    );
  }
}
