import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/usage_stats_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Shows an overhauled app description modal bottom sheet with fluid style switching,
/// downward swipe dismiss, and optional theme glassmorphism.
Future<void> showAppDescriptionModal({
  required BuildContext context,
  required AppInMemory app,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.45),
    builder: (ctx) => _AppDescriptionModalSheet(app: app),
  );
}

class _AppDescriptionModalSheet extends StatelessWidget {
  final AppInMemory app;
  const _AppDescriptionModalSheet({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final sheetRadius = Radius.circular(
      plusSettings.plusGlobalCornerRadius.clamp(20.0, 32.0),
    );

    final Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.82 : 0.90,
              )
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: sheetRadius),
        border: Border.all(
          color: enableGlass
              ? cs.onSurface.withValues(alpha: 0.12)
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: cs.onPrimaryContainer,
                      size: 20,
                    ),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          app.app.author.isNotEmpty
                              ? app.app.author
                              : 'App Description & Overview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.88,
                    child: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: tr('copiedToClipboard'),
                      onPressed: () {
                        final text =
                            app.app.additionalSettings['about'] as String? ??
                            '';
                        Clipboard.setData(ClipboardData(text: text));
                        AppHaptics.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('copiedToClipboard'))),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: AppDescriptionCard(app: app, isModal: true),
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: const Key('app_description_modal_dismissible'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.of(context).pop(),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigmaSoft,
        child: sheetContent,
      ),
    );
  }
}

/// A comprehensive, multi-style app description card supporting Obtainium+, GitHub README,
/// Play Store, and Raw Markdown presentation modes with live style toggling and glassmorphism.
class AppDescriptionCard extends StatefulWidget {
  final AppInMemory app;
  final bool isModal;

  const AppDescriptionCard({
    super.key,
    required this.app,
    this.isModal = false,
  });

  @override
  State<AppDescriptionCard> createState() => _AppDescriptionCardState();
}

class _AppDescriptionCardState extends State<AppDescriptionCard> {
  bool _expanded = false;
  WebViewController? _webViewController;
  bool _isWebLoading = false;
  int _webProgress = 0;

  @override
  void didUpdateWidget(AppDescriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app.app.url != widget.app.app.url) {
      _webViewController = null;
      _initWebControllerIfNeeded();
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }

  void _initWebControllerIfNeeded() {
    if (_webViewController != null) return;
    final url = widget.app.app.url;
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme && !uri.isAbsolute)) return;

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isWebLoading = true);
            },
            onProgress: (p) {
              if (mounted) setState(() => _webProgress = p);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isWebLoading = false);
            },
          ),
        );
      controller.loadRequest(uri);
      _webViewController = controller;
    } catch (_) {}
  }

  String get _aboutText {
    final raw = widget.app.app.additionalSettings['about'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return '';
  }

  bool get _isLong =>
      _aboutText.length > 360 || '\n'.allMatches(_aboutText).length >= 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final anims = plusSettings.plusEnableEnhancedAnimations;
    final currentStyle = plusSettings.plusAppDescriptionStyle;

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    final String text = _aboutText;
    final bool hasText = text.isNotEmpty;

    final Widget cardBody = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.78 : 0.88,
              )
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: enableGlass
              ? cs.onSurface.withValues(alpha: AppConstants.glassBorderAlpha)
              : cs.outlineVariant.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.35 : 0.65,
                ),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Section Label + Style Switcher + Fullscreen Pop-out
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  tr('about'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (!widget.isModal)
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.90,
                    child: IconButton(
                      icon: const Icon(Icons.open_in_full_rounded, size: 18),
                      tooltip: 'Expand Description',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        AppHaptics.selectionClick();
                        showAppDescriptionModal(
                          context: context,
                          app: widget.app,
                        );
                      },
                    ),
                  ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.90,
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: tr('copiedToClipboard'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      AppHaptics.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('copiedToClipboard'))),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Style Switcher Bar
            _buildStyleSwitcher(context, currentStyle),
            const SizedBox(height: 14),

            // Animated Style Content
            AnimatedSwitcher(
              duration: Duration(milliseconds: anims ? 280 : 0),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(currentStyle),
                child: _buildStyleContent(context, currentStyle, text, hasText),
              ),
            ),
          ],
        ),
      ),
    );

    return ConditionalBlur(
      enabled: enableGlass,
      sigma: AppConstants.glassBlurSigmaSoft,
      child: cardBody,
    );
  }

  Widget _buildStyleSwitcher(
    BuildContext context,
    AppDescriptionStyle currentStyle,
  ) {
    final cs = Theme.of(context).colorScheme;

    final styles = [
      (
        style: AppDescriptionStyle.obtainiumPlus,
        label: 'Obtainium+',
        icon: Icons.rocket_launch_rounded,
      ),
      (
        style: AppDescriptionStyle.githubReadme,
        label: 'README',
        icon: Icons.code_rounded,
      ),
      (
        style: AppDescriptionStyle.playStore,
        label: 'Play Store',
        icon: Icons.shop_two_outlined,
      ),
      (
        style: AppDescriptionStyle.liveWebpage,
        label: 'Webpage',
        icon: Icons.language_rounded,
      ),
      (
        style: AppDescriptionStyle.rawMarkdown,
        label: 'Raw',
        icon: Icons.text_snippet_outlined,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: styles.map((item) {
          final isSelected = currentStyle == item.style;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.94,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: ChoiceChip(
                  avatar: Icon(
                    item.icon,
                    size: 14,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                  label: Text(item.label),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                  ),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  showCheckmark: false,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    if (val) {
                      AppHaptics.selectionClick();
                      context
                              .read<PlusSettingsProvider>()
                              .plusAppDescriptionStyle =
                          item.style;
                    }
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStyleContent(
    BuildContext context,
    AppDescriptionStyle style,
    String text,
    bool hasText,
  ) {
    switch (style) {
      case AppDescriptionStyle.obtainiumPlus:
        return _buildObtainiumPlusStyle(context, text, hasText);
      case AppDescriptionStyle.githubReadme:
        return _buildGithubReadmeStyle(context, text, hasText);
      case AppDescriptionStyle.playStore:
        return _buildPlayStoreStyle(context, text, hasText);
      case AppDescriptionStyle.liveWebpage:
        return _buildLiveWebpageStyle(context);
      case AppDescriptionStyle.rawMarkdown:
        return _buildRawMarkdownStyle(context, text, hasText);
    }
  }

  // ── Style 1: Custom Obtainium+ App Info ──────────────────────────────────
  Widget _buildObtainiumPlusStyle(
    BuildContext context,
    String text,
    bool hasText,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = widget.app;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Technical Specifications Badges Strip
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildBadge(
              icon: Icons.tag_rounded,
              label:
                  'ID: ${app.app.id.length > 20 ? '${app.app.id.substring(0, 18)}...' : app.app.id}',
              cs: cs,
            ),
            if (app.app.author.isNotEmpty)
              _buildBadge(
                icon: Icons.person_outline_rounded,
                label: app.app.author,
                cs: cs,
              ),
            if (app.app.apkUrls.isNotEmpty)
              _buildBadge(
                icon: Icons.file_download_outlined,
                label:
                    '${app.app.apkUrls.length} APK ${plural('asset', app.app.apkUrls.length)}',
                cs: cs,
              ),
            if (app.app.additionalSettings['trackOnly'] == true)
              _buildBadge(
                icon: Icons.visibility_outlined,
                label: 'Track Only',
                cs: cs,
                isHighlight: true,
              ),
            if (app.app.additionalSettings['linkedPackage'] != null)
              _buildBadge(
                icon: Icons.link_rounded,
                label: 'Linked: ${app.app.additionalSettings['linkedPackage']}',
                cs: cs,
              ),
            if (app.app.effectiveFirstInstalled != null ||
                app.installedInfo?.firstInstallTime != null)
              _buildBadge(
                icon: Icons.history_toggle_off_rounded,
                label:
                    'Installed: ${(app.app.effectiveFirstInstalled ?? DateTime.fromMillisecondsSinceEpoch(app.installedInfo!.firstInstallTime!)).toLocal().toString().split(' ').first}',
                cs: cs,
              ),
            if (app.app.effectiveLastInstalled != null ||
                app.installedInfo?.lastUpdateTime != null)
              _buildBadge(
                icon: Icons.update_rounded,
                label:
                    'Updated: ${(app.app.effectiveLastInstalled ?? DateTime.fromMillisecondsSinceEpoch(app.installedInfo!.lastUpdateTime!)).toLocal().toString().split(' ').first}',
                cs: cs,
              ),
            if (app.app.installHistory.isNotEmpty)
              _buildBadge(
                icon: Icons.restore_rounded,
                label:
                    '${app.app.installHistory.length} recorded install${app.app.installHistory.length == 1 ? '' : 's'}',
                cs: cs,
                isHighlight: true,
              ),
          ],
        ),
        FutureBuilder<AppUsageStats?>(
          future: UsageStatsService.getAppUsage(app.app.id),
          builder: (context, snapshot) {
            final stats = snapshot.data;
            if (stats == null || stats.lastTimeUsed == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    icon: Icons.insights_rounded,
                    label: 'Last used: ${stats.relativeLastUsed}',
                    cs: cs,
                    isHighlight: true,
                  ),
                  if (stats.totalForegroundDuration > Duration.zero)
                    _buildBadge(
                      icon: Icons.timer_outlined,
                      label:
                          'Screen time: ${stats.formattedForegroundDuration}',
                      cs: cs,
                    ),
                ],
              ),
            );
          },
        ),
        if (app.app.installHistory.length > 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Installation & Update Timeline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...app.app.installHistory.reversed.take(4).map((entry) {
                  final dateStr = entry.timestamp
                      .toLocal()
                      .toString()
                      .split('.')
                      .first;
                  final prev = entry.previousVersion != null
                      ? ' (from ${entry.previousVersion})'
                      : '';
                  final method = entry.installerMethod != null
                      ? ' via ${entry.installerMethod}'
                      : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• v${entry.version}$prev$method — $dateStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Description Body
        if (hasText)
          _buildCollapsibleWrapper(child: _renderMarkdown(context, text))
        else
          _buildEmptyPlaceholder(
            context,
            'No description metadata recorded for this app yet.',
          ),
      ],
    );
  }

  // ── Style 2: GitHub README Style ─────────────────────────────────────────
  Widget _buildGithubReadmeStyle(
    BuildContext context,
    String text,
    bool hasText,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = widget.app;

    final repoParts = app.app.url.contains('github.com/')
        ? app.app.url.split('github.com/').last.split('/')
        : <String>[];
    final repoOwner = repoParts.isNotEmpty ? repoParts[0] : app.app.author;
    final repoName = repoParts.length > 1 ? repoParts[1] : app.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GitHub Repo Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark_border_rounded, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$repoOwner / $repoName',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'main',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // README Markdown Content
        if (hasText)
          _buildCollapsibleWrapper(
            child: _renderMarkdown(context, text, isGithub: true),
          )
        else
          _buildEmptyPlaceholder(
            context,
            'No README documentation fetched for this repository.',
          ),
      ],
    );
  }

  // ── Style 3: Google Play Store Style ─────────────────────────────────────
  Widget _buildPlayStoreStyle(BuildContext context, String text, bool hasText) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = widget.app;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Play Store Metrics Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayMetric(
              context,
              icon: Icons.star_rounded,
              title: 'Verified',
              subtitle: 'Play Protect',
              iconColor: Colors.amber[700],
            ),
            Container(
              width: 1,
              height: 28,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildPlayMetric(
              context,
              icon: Icons.verified_outlined,
              title: app.app.installedVersion != null ? 'Installed' : 'Ready',
              subtitle: 'Package Status',
              iconColor: cs.primary,
            ),
            Container(
              width: 1,
              height: 28,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildPlayMetric(
              context,
              icon: Icons.info_outline_rounded,
              title: app.app.latestVersion.length > 8
                  ? app.app.latestVersion.substring(0, 8)
                  : app.app.latestVersion,
              subtitle: 'Latest Release',
              iconColor: cs.secondary,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // About This App Section
        Text(
          'About this app',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Features, developer information and capabilities',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),

        if (hasText)
          _buildCollapsibleWrapper(child: _renderMarkdown(context, text))
        else
          _buildEmptyPlaceholder(
            context,
            'No store description available for this package.',
          ),
      ],
    );
  }

  // ── Style 4: Raw Markdown / Text ─────────────────────────────────────────
  Widget _buildRawMarkdownStyle(
    BuildContext context,
    String text,
    bool hasText,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final wordCount = hasText ? text.trim().split(RegExp(r'\s+')).length : 0;
    final charCount = text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Raw Stats Strip
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$wordCount words · $charCount chars',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy Raw', style: TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                AppHaptics.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('copiedToClipboard'))),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (hasText)
          _buildCollapsibleWrapper(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          _buildEmptyPlaceholder(context, 'Empty description content.'),
      ],
    );
  }

  // ── Style 5: Live Webpage ───────────────────────────────────────────────
  Widget _buildLiveWebpageStyle(BuildContext context) {
    _initWebControllerIfNeeded();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final url = widget.app.app.url;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final baseRadius = CardMetrics.inner(
      CardMetrics.card(
        plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusHomeCornerRadius
            : plusSettings.plusGlobalCornerRadius,
      ),
    ).clamp(12.0, 20.0);

    if (url.isEmpty || _webViewController == null) {
      return _buildEmptyPlaceholder(
        context,
        'No valid web URL configured for this app.',
      );
    }

    final double containerHeight = widget.isModal ? 520 : 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Web Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(baseRadius),
            ),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  Uri.tryParse(url)?.host ?? url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.88,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Reload',
                  onPressed: () => _webViewController?.reload(),
                ),
              ),
              ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.88,
                child: IconButton(
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Open in Browser',
                  onPressed: () => launchUrlString(
                    url,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isWebLoading)
          ExpressiveProgressIndicator(
            value: _webProgress > 0 ? _webProgress / 100 : null,
          ),
        // Web View Container
        Container(
          height: containerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(baseRadius),
            ),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(baseRadius),
            ),
            child: WebViewWidget(
              controller: _webViewController!..setBackgroundColor(cs.surface),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────
  Widget _buildCollapsibleWrapper({required Widget child}) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final anims = plusSettings.plusEnableEnhancedAnimations;
    final cs = Theme.of(context).colorScheme;

    if (!plusSettings.plusEnablePopupSlider || !_isLong) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: Duration(milliseconds: anims ? 320 : 0),
          curve: Curves.easeInOutCubicEmphasized,
          alignment: Alignment.topCenter,
          child: _expanded
              ? child
              : ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.65, 1],
                  ).createShader(rect),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: child,
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ScaleTouchWrapper(
              scaleDownFactor: 0.94,
              onTap: () {
                AppHaptics.selectionClick();
                setState(() => _expanded = !_expanded);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(_expanded ? 'aboutShowLess' : 'aboutShowMore'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: Duration(milliseconds: anims ? 240 : 0),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _renderMarkdown(
    BuildContext context,
    String text, {
    bool isGithub = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Markdown(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        blockquoteDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        codeblockDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        tableBorder: TableBorder.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      data: text,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrlString(href, mode: LaunchMode.externalApplication);
        }
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? cs.tertiaryContainer.withValues(alpha: 0.7)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? cs.tertiary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight ? cs.onTertiaryContainer : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isHighlight ? cs.onTertiaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayMetric(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor ?? cs.primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
