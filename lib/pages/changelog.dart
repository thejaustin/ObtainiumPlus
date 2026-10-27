import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/changelog/changelog_timeline.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/version_constant.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

// ─── Public entry point ─────────────────────────────────────────────────────

/// Shows the "What's New" bottom sheet. Call from home.dart after a version bump.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  String? targetVersion,
  String? sinceVersion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    elevation: 0,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return _WhatsNewSheet(
                targetVersion: targetVersion ?? currentObtainiumPlusVersion,
                sinceVersion: sinceVersion,
                scrollController: scrollController,
              );
            },
          ),
        ),
      );
    },
  );
}

// ─── Page (standalone, non-modal) ───────────────────────────────────────────

class ChangelogPage extends StatefulWidget {
  final bool isModal;
  final String? targetVersion;

  const ChangelogPage({super.key, this.isModal = false, this.targetVersion});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isModal) {
      // In modal context just render the inner sheet directly (handled by showWhatsNewSheet)
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(tr('viewChangelog')),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'GitHub Releases',
            onPressed: () => launchUrlString(
              releasesPageUrl,
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ChangelogTimeline(
            installedVersion:
                widget.targetVersion ?? currentObtainiumPlusVersion,
          ),
        ),
      ),
    );
  }
}

// ─── Bottom-sheet widget ────────────────────────────────────────────────────

class _WhatsNewSheet extends StatefulWidget {
  final String targetVersion;
  final String? sinceVersion;
  final ScrollController scrollController;

  const _WhatsNewSheet({
    required this.targetVersion,
    required this.scrollController,
    this.sinceVersion,
  });

  @override
  State<_WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends State<_WhatsNewSheet> {
  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final enableAnims = plusSettings.plusEnableEnhancedAnimations;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = plusSettings.plusGlobalCornerRadius;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 4)),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigma,
        child: AnimatedContainer(
          duration: Duration(milliseconds: enableAnims ? 260 : 0),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(
              alpha: enableGlass ? AppConstants.glassSurfaceAlpha : 1.0,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius + 4),
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(
                alpha: enableGlass
                    ? AppConstants.glassBorderAlpha
                    : AppOpacity.subtle,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(context, colorScheme),
              _buildHeader(context, colorScheme, enableGlass),
              const Divider(height: 1),
              Expanded(
                child: ChangelogTimeline(
                  scrollController: widget.scrollController,
                  installedVersion: widget.targetVersion,
                  sinceVersion: widget.sinceVersion,
                ),
              ),
              _buildFooter(context, colorScheme, enableGlass),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool enableGlass) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: AppOpacity.half),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's New in Obtainium+",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version ${widget.targetVersion}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.88,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: AppOpacity.subtle),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.94,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('GitHub Releases'),
                  onPressed: () {
                    launchUrlString(
                      releasesPageUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.94,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('ok')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
