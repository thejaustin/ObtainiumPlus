import 'dart:async';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

import 'package:flutter/material.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_search_service.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/fuzzy_search.dart';
import 'package:obtainium/components/ui_widgets.dart';

class CommandCenter extends StatefulWidget {
  final String? initialQuery;

  const CommandCenter({super.key, this.initialQuery});

  static Future<void> show(BuildContext context, {String? initialQuery}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => CommandCenter(initialQuery: initialQuery),
    );
  }

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _isAddingUrl = false;
  String _query = '';
  Map<String, MapEntry<String, List<String>>> _discoverResults = {};
  bool _discoverSearchFailed = false;
  final Set<String> _pendingAddUrls = {};
  final Set<String> _successfulAddUrls = {};
  final SourceProvider _sourceProvider = SourceProvider();
  Timer? _debounce;

  Future<void> _submitAddAppUrl(String url) async {
    if (_pendingAddUrls.contains(url) || _isAddingUrl) return;
    setState(() {
      _pendingAddUrls.add(url);
      _isAddingUrl = true;
    });
    try {
      final ap = context.read<AppsProvider>();
      final errors = await ap.addAppsByURL([url]);
      if (mounted) {
        setState(() {
          _pendingAddUrls.remove(url);
          _isAddingUrl = false;
        });
        if (errors.isNotEmpty) {
          showError(errors[0][1], context);
        } else {
          setState(() {
            _successfulAddUrls.add(url);
          });
          final newApp = ap.apps.values
              .where((a) => a.app.url == url)
              .firstOrNull;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('appAdded')),
              action: newApp != null
                  ? SnackBarAction(
                      label: tr('install'),
                      onPressed: () {
                        ap.downloadAndInstallLatestApps([
                          newApp.app.id,
                        ], context);
                      },
                    )
                  : null,
            ),
          );
        }
      } else {
        final globalCtx = globalNavigatorKey.currentContext;
        if (globalCtx != null && globalCtx.mounted) {
          if (errors.isNotEmpty) {
            showError(errors[0][1], globalCtx);
          } else {
            ScaffoldMessenger.of(
              globalCtx,
            ).showSnackBar(SnackBar(content: Text(tr('appAdded'))));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingAddUrls.remove(url);
          _isAddingUrl = false;
        });
        showError(e, context);
      } else {
        final globalCtx = globalNavigatorKey.currentContext;
        if (globalCtx != null && globalCtx.mounted) {
          showError(e, globalCtx);
        }
      }
    }
  }

  bool _isDirectUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('market://')) {
      return true;
    }
    try {
      final src = _sourceProvider.getSource(trimmed);
      if (src.hosts.isNotEmpty && src.runtimeType.toString() != 'HTML') {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _query = widget.initialQuery!;
      _handleSearch(widget.initialQuery!);
    }
    _focusNode.requestFocus();
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
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<AppInMemory> _localResults = [];

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
    _updateLocalResults(value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _handleDiscoverSearch(value);
    });
  }

  void _updateLocalResults(String value) {
    if (value.isEmpty) {
      setState(() {
        _localResults = [];
        _discoverResults = {};
      });
      return;
    }

    // Search local apps immediately on every keystroke
    final appsProvider = context.read<AppsProvider>();
    final results = appsProvider
        .getAppValues()
        .map((app) {
          final score = fuzzyMatchMulti(value, [
            app.name,
            app.app.id,
            app.author,
            app.app.url,
            ...app.app.categories,
            ...app.app.tags,
          ]);
          return MapEntry(app, score);
        })
        .where((entry) => entry.value >= 0.3)
        .toList();

    results.sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _localResults = results.map((entry) => entry.key).take(25).toList();
    });
  }

  Future<void> _handleDiscoverSearch(String value) async {
    if (value.isEmpty) return;

    // Check if it's a URL
    if (_isDirectUrl(value)) {
      // Allow GitHub User Profiles to bypass this so they can be searched
      RegExp userProfileRegEx = RegExp(
        r'^https?://(?:www\.)?github\.com/[^/]+/?$',
        caseSensitive: false,
      );
      if (!userProfileRegEx.hasMatch(value)) {
        setState(() => _discoverResults = {});
        return;
      }
    }

    // Handle as Discovery Search
    await _runDiscoverSearch(value);
  }

  Future<void> _handleSearch(String value) async {
    _updateLocalResults(value);
    await _handleDiscoverSearch(value);
  }

  Future<void> _runDiscoverSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final settings = context.read<SettingsProvider>();

      final searchResult = await AppSearchService.searchAllSources(
        query,
        sourceProvider: _sourceProvider,
        deselectedSources: settings.searchDeselected,
      );

      if (mounted && _query == query) {
        setState(() {
          _discoverResults = searchResult.results;
          _discoverSearchFailed = searchResult.allSourcesFailed;
        });
      }
    } finally {
      if (mounted && _query == query) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrl = _isDirectUrl(_query);
    final plusSettings = context.watch<PlusSettingsProvider>();
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final sheetRadius = radius.clamp(24.0, 48.0);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
            child: ConditionalBlur(
              sigma: AppConstants.glassBlurSigma,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: plusSettings.plusEnableGlassmorphism
                      ? theme.colorScheme.surface.withValues(
                          alpha: AppConstants.glassSurfaceAlpha,
                        )
                      : (isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surfaceContainerLow),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(sheetRadius),
                  ),
                  border: Border.all(
                    color: plusSettings.plusEnableGlassmorphism
                        ? theme.colorScheme.onSurface.withValues(
                            alpha: AppConstants.glassBorderAlpha,
                          )
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: isDark ? 0.35 : 0.65,
                          ),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    const DragHandle(width: 40),

                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnimatedContainer(
                        duration: Duration(
                          milliseconds: animsEnabled ? 280 : 0,
                        ),
                        curve: Easing.emphasizedDecelerate,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _isFocused || _query.isNotEmpty ? 18.0 : 28.0,
                          ),
                          boxShadow: (_isFocused || _query.isNotEmpty)
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: theme.textTheme.titleMedium,
                          decoration: InputDecoration(
                            hintText: tr('searchOrPasteUrl'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    tooltip: tr('clear'),
                                    onPressed: () {
                                      AppHaptics.selectionClick();
                                      _controller.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.content_paste_rounded,
                                      size: 20,
                                    ),
                                    tooltip: tr('paste'),
                                    onPressed: () async {
                                      final data = await Clipboard.getData(
                                        Clipboard.kTextPlain,
                                      );
                                      final text = data?.text?.trim() ?? '';
                                      if (text.isNotEmpty) {
                                        AppHaptics.selectionClick();
                                        _controller.text = text;
                                        _onSearchChanged(text);
                                      }
                                    },
                                  ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHigh
                                .withValues(
                                  alpha: plusSettings.plusEnableGlassmorphism
                                      ? 0.5
                                      : 1.0,
                                ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                _isFocused || _query.isNotEmpty ? 18.0 : 28.0,
                              ),
                              borderSide: BorderSide(
                                color: (_isFocused || _query.isNotEmpty)
                                    ? theme.colorScheme.primary
                                    : (plusSettings.plusEnableGlassmorphism
                                          ? theme.colorScheme.onSurface
                                                .withValues(
                                                  alpha: AppConstants
                                                      .glassBorderAlpha,
                                                )
                                          : Colors.transparent),
                                width: (_isFocused || _query.isNotEmpty)
                                    ? 1.8
                                    : 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                _isFocused || _query.isNotEmpty ? 18.0 : 28.0,
                              ),
                              borderSide: BorderSide(
                                color: (_isFocused || _query.isNotEmpty)
                                    ? theme.colorScheme.primary
                                    : (plusSettings.plusEnableGlassmorphism
                                          ? theme.colorScheme.onSurface
                                                .withValues(
                                                  alpha: AppConstants
                                                      .glassBorderAlpha,
                                                )
                                          : theme.colorScheme.outlineVariant
                                                .withValues(alpha: 0.3)),
                                width: (_isFocused || _query.isNotEmpty)
                                    ? 1.8
                                    : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.8,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),

                    // Source filter chips only matter once there's an
                    // actual discover search running — showing all 8
                    // sources before the user has typed anything just
                    // clutters the initial quick-actions/recently-added
                    // view for a feature most people never touch.
                    if (_query.isNotEmpty &&
                        (!isUrl ||
                            RegExp(
                              r'^https?://(?:www\.)?github\.com/[^/]+/?$',
                              caseSensitive: false,
                            ).hasMatch(_query))) ...[
                      const SizedBox(height: 8),
                      _buildSourceFilters(context),
                    ],
                    const SizedBox(height: 8),

                    // Content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: animsEnabled ? 260 : 0,
                        ),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.04),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          ),
                        ),
                        child: _query.isEmpty
                            ? KeyedSubtree(
                                key: const ValueKey('initial'),
                                child: _buildInitialState(),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('results'),
                                child: ListView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  children: [
                                    _buildActiveDownloadsSection(
                                      context,
                                      context.watch<AppsProvider>(),
                                    ),
                                    AnimatedSize(
                                      duration: Duration(
                                        milliseconds: animsEnabled ? 300 : 0,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: _localResults.isNotEmpty
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _buildSectionHeader(
                                                  tr('myApps'),
                                                ),
                                                ..._localResults.map(
                                                  _buildLocalResult,
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSize(
                                      duration: Duration(
                                        milliseconds: animsEnabled ? 300 : 0,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: isUrl
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _buildSectionHeader(
                                                  tr('actions'),
                                                ),
                                                _buildUrlActionContent(),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    AnimatedSize(
                                      duration: Duration(
                                        milliseconds: animsEnabled ? 300 : 0,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child:
                                          (_query.isNotEmpty &&
                                              (!isUrl ||
                                                  RegExp(
                                                    r'^https?://(?:www\.)?github\.com/[^/]+/?$',
                                                    caseSensitive: false,
                                                  ).hasMatch(_query)))
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _buildSectionHeader(
                                                  tr('discover'),
                                                ),
                                                _buildSearchResultsList(),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveDownloadsSection(
    BuildContext context,
    AppsProvider appsProvider,
  ) {
    final downloading = appsProvider.apps.values
        .where((e) => e.downloadProgress != null)
        .toList();
    if (downloading.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final itemRadius = CardMetrics.inner(radius);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(tr('installing')),
        for (final app in downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(itemRadius),
                side: BorderSide(
                  color: cs.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              itemRadius * 0.6,
                            ),
                            color: cs.surfaceContainerHighest,
                          ),
                          child: app.icon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    itemRadius * 0.6,
                                  ),
                                  child: Image.memory(
                                    app.icon!,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                )
                              : const Icon(Icons.downloading_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              ValueListenableBuilder<double?>(
                                valueListenable: app.downloadProgressNotifier,
                                builder: (context, p, _) {
                                  final progressText = p != null && p >= 0
                                      ? '${p.round()}%'
                                      : tr('installing');
                                  return Text(
                                    progressText,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: tr('cancel'),
                          onPressed: () {
                            AppHaptics.selectionClick();
                            appsProvider.cancelDownload(app.app.id);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<double?>(
                      valueListenable: app.downloadProgressNotifier,
                      builder: (context, p, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: p != null && p >= 0
                                ? (p / 100.0).clamp(0.0, 1.0)
                                : null,
                            minHeight: 4,
                            backgroundColor: cs.primary.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLocalResult(AppInMemory app) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final appsProvider = context.watch<AppsProvider>();
    final cs = Theme.of(context).colorScheme;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final itemRadius = CardMetrics.inner(radius);

    final bool isInstalled = app.installedInfo != null;
    final bool hasUpdate =
        isInstalled &&
        app.app.latestVersion.isNotEmpty &&
        app.app.installedVersion != null &&
        app.app.latestVersion != app.app.installedVersion;
    final bool isDownloading = app.downloadProgress != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(itemRadius),
          side: BorderSide(
            color: hasUpdate
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.25),
            width: hasUpdate ? 1.4 : 1.0,
          ),
        ),
        child: ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(itemRadius),
            onTap: () {
              Navigator.pop(context);
              showAdaptiveDetailSheet(
                context: context,
                builder: (context, controller) => AppPage(
                  appId: app.app.id,
                  isModal: true,
                  scrollController: controller,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(itemRadius * 0.75),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: app.icon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              itemRadius * 0.75,
                            ),
                            child: Image.memory(
                              app.icon!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              cacheWidth:
                                  (48 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              cacheHeight:
                                  (48 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                            ),
                          )
                        : const Icon(Icons.apps_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (isDownloading)
                          ValueListenableBuilder<double?>(
                            valueListenable: app.downloadProgressNotifier,
                            builder: (context, p, _) {
                              final text = p != null && p >= 0
                                  ? '${p.round()}%'
                                  : tr('installing');
                              return Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: p != null && p >= 0
                                            ? (p / 100.0).clamp(0.0, 1.0)
                                            : null,
                                        minHeight: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              );
                            },
                          )
                        else if (hasUpdate)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${app.app.installedVersion} → ',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: app.app.latestVersion,
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            isInstalled
                                ? (app.app.latestVersion.isNotEmpty
                                      ? app.app.latestVersion
                                      : tr('installed'))
                                : tr('notInstalled'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDownloading)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: tr('cancel'),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        appsProvider.cancelDownload(app.app.id);
                      },
                    )
                  else if (hasUpdate)
                    ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.90,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.install_mobile_rounded,
                          size: 18,
                        ),
                        tooltip: tr('update'),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          appsProvider.downloadAndInstallLatestApps([
                            app.app.id,
                          ], context);
                        },
                      ),
                    )
                  else if (!isInstalled)
                    ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.90,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        tooltip: tr('install'),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          appsProvider.downloadAndInstallLatestApps([
                            app.app.id,
                          ], context);
                        },
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddApp(String url) {
    Navigator.pop(context);
    final ctx = globalNavigatorKey.currentContext;
    if (ctx != null) {
      showAddAppSheet(context: ctx, initialUrl: url);
    }
  }

  Widget _buildSearchResultsList() {
    final theme = Theme.of(context);
    final plusSettings = context.watch<PlusSettingsProvider>();
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    if (_isSearching && _discoverResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: ExpressiveCircularProgressIndicator()),
      );
    }

    if (!_isSearching && _discoverResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _discoverSearchFailed
                    ? Icons.wifi_off_rounded
                    : Icons.search_off_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _discoverSearchFailed
                    ? tr('searchAllSourcesFailed')
                    : tr('noResultsFound'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: const ExpressiveProgressIndicator(),
          ),
        ..._discoverResults.entries.indexed.map((idxEntry) {
          final index = idxEntry.$1;
          final entry = idxEntry.$2;
          final url = entry.key;
          final result = entry.value;
          final name = result.value.isNotEmpty ? result.value[0] : 'Unknown';
          final source = result.key;
          final radius = plusSettings.plusOverrideIndividualCornerRadius
              ? plusSettings.plusHomeCornerRadius
              : plusSettings.plusGlobalCornerRadius;
          final itemRadius = (radius * 0.66).clamp(8.0, 16.0);
          final staggerMs = animsEnabled
              ? (120 + (index < 8 ? index * 40 : 0))
              : 0;

          return TweenAnimationBuilder<double>(
            key: ValueKey(url),
            duration: Duration(milliseconds: staggerMs),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(itemRadius),
                child: ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(itemRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(itemRadius * 0.75),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            source,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: tr('advancedOptions'),
                          onPressed: () => _openAddApp(url),
                        ),
                        if (_successfulAddUrls.contains(url) ||
                            context.watch<AppsProvider>().apps.values.any(
                              (a) => a.app.url == url,
                            )) ...[
                          ScaleTouchWrapper(
                            hapticOnPressDown: true,
                            scaleDownFactor: 0.90,
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 16,
                              ),
                              label: Text(tr('install')),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                final ap = context.read<AppsProvider>();
                                final match = ap.apps.values
                                    .where((a) => a.app.url == url)
                                    .firstOrNull;
                                if (match != null) {
                                  ap.downloadAndInstallLatestApps([
                                    match.app.id,
                                  ], context);
                                }
                              },
                            ),
                          ),
                        ] else if (_pendingAddUrls.contains(url))
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: ExpressiveCircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: tr('addApp'),
                            onPressed: () => _submitAddAppUrl(url),
                          ),
                      ],
                    ),
                    onTap: _pendingAddUrls.contains(url)
                        ? null
                        : () => _submitAddAppUrl(url),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUrlActionContent() {
    final isAdded =
        _successfulAddUrls.contains(_query) ||
        context.watch<AppsProvider>().apps.values.any(
          (a) => a.app.url == _query,
        );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: AppOpacity.moderate),
      child: Column(
        children: [
          ListTile(
            leading: _isAddingUrl
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isAdded
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    color: isAdded
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            title: Text(isAdded ? tr('install') : tr('addApp')),
            subtitle: Text(
              _query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _isAddingUrl ? null : const Icon(Icons.arrow_forward),
            onTap: _isAddingUrl
                ? null
                : () {
                    if (isAdded) {
                      final ap = context.read<AppsProvider>();
                      final match = ap.apps.values
                          .where((a) => a.app.url == _query)
                          .firstOrNull;
                      if (match != null) {
                        ap.downloadAndInstallLatestApps([
                          match.app.id,
                        ], context);
                      }
                    } else {
                      _submitAddAppUrl(_query);
                    }
                  },
          ),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: Text(tr('advancedOptions')),
            trailing: const Icon(Icons.open_in_new),
            onTap: _isAddingUrl ? null : () => _openAddApp(_query),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final appsProvider = context.watch<AppsProvider>();
    final allApps = appsProvider.getAppValues().toList();
    final appsWithUpdates = allApps.where((a) {
      final isInstalled = a.installedInfo != null;
      return isInstalled &&
          a.app.latestVersion.isNotEmpty &&
          a.app.installedVersion != null &&
          a.app.latestVersion != a.app.installedVersion;
    }).toList();
    final recentlyAdded = allApps.reversed.take(5).toList();

    final allTags = <String>{};
    final allCategories = <String>{};
    for (final a in allApps) {
      allTags.addAll(a.app.tags);
      allCategories.addAll(a.app.categories);
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveDownloadsSection(context, appsProvider),
          if (appsWithUpdates.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${tr('updates').toUpperCase()} (${appsWithUpdates.length})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.94,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                      ),
                      icon: const Icon(
                        Icons.system_update_alt_rounded,
                        size: 14,
                      ),
                      label: Text(
                        '${tr('update')} ${tr('all')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        appsProvider.downloadAndInstallLatestApps(
                          appsWithUpdates.map((a) => a.app.id).toList(),
                          context,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ...appsWithUpdates.map(_buildLocalResult),
            const SizedBox(height: 16),
          ],
          if (recentlyAdded.isNotEmpty) ...[
            _buildSectionHeader(tr('recentlyAdded')),
            ...recentlyAdded.map(_buildLocalResult),
            const SizedBox(height: 24),
          ],
          _buildQuickActions(),
          const SizedBox(height: 16),
          if (allTags.isNotEmpty)
            _buildFilterChipGroup(tr('tags'), allTags, isTag: true),
          if (allCategories.isNotEmpty)
            _buildFilterChipGroup(tr('categories'), allCategories, isTag: false),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: AppOpacity.low),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('commandCenterPrompt'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: AppOpacity.half),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterChipGroup(
    String title,
    Set<String> items, {
    bool isTag = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final chipRadius = CardMetrics.inner(radius);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.take(12).map((item) {
              return ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.92,
                child: ActionChip(
                  avatar: Icon(
                    isTag ? Icons.label_rounded : Icons.folder_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(item),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    _controller.text = item;
                    _onSearchChanged(item);
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(chipRadius),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(tr('quickActions')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(Icons.sync, tr('checkUpdates'), () {
                final ctx = globalNavigatorKey.currentContext;
                Navigator.pop(context);
                context
                    .read<AppsProvider>()
                    .checkUpdates(ignoreAppsCheckedAfter: DateTime.now())
                    .catchError((e) {
                      if (ctx != null && ctx.mounted) {
                        showError(e is Map ? e['errors'] : e, ctx);
                      }
                      return <App>[];
                    });
              }),
              _buildActionChip(Icons.import_export, tr('importExport'), () {
                Navigator.pop(context);
                pushRoute(context, const ImportExportPage());
              }),
              _buildActionChip(Icons.bug_report_outlined, tr('logs'), () {
                Navigator.pop(context);
                pushRoute(context, const LogsPage());
              }),
              _buildActionChip(Icons.settings_outlined, tr('settings'), () {
                Navigator.pop(context);
                pushRoute(context, const SettingsPage());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onPressed) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final chipRadius = CardMetrics.inner(radius);

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.92,
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        onPressed: () {
          AppHaptics.selectionClick();
          onPressed();
        },
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
      ),
    );
  }

  Widget _buildSourceFilters(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final searchableSources = _sourceProvider.sources
        .where((e) => e.canSearch)
        .toList();
    if (searchableSources.isEmpty) return const SizedBox.shrink();

    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final chipRadius = CardMetrics.inner(radius);

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: searchableSources.length,
        itemBuilder: (context, index) {
          final src = searchableSources[index];
          final isSelected = !settings.searchDeselected.contains(src.name);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.92,
              child: FilterChip(
                selected: isSelected,
                label: Text(src.name),
                onSelected: (bool selected) {
                  AppHaptics.selectionClick();
                  final newList = List<String>.from(settings.searchDeselected);
                  if (selected) {
                    newList.remove(src.name);
                  } else {
                    newList.add(src.name);
                  }
                  settings.searchDeselected = newList;
                  if (_query.isNotEmpty) {
                    _handleSearch(_query);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(chipRadius),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
