import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:provider/provider.dart';

/// Shows the modern "Add App" bottom sheet with glassmorphism.
/// This replaces the old full-page approach for a smoother, faster experience.
Future<T?> showAddAppSheet<T>({
  required BuildContext context,
  String? initialUrl,
  String? editAppId,
}) {
  final settings = context.read<SettingsProvider>();
  final enableGlass = settings.plusEnableGlassmorphism;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    elevation: 0,
    barrierColor: Colors.black54,
    transitionAnimationController: AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    ),
    builder: (ctx) {
      final sheet = Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: enableGlass ? 0.78 : 1.0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: enableGlass
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                left: BorderSide(
                  color: enableGlass
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                right: BorderSide(
                  color: enableGlass
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
              boxShadow: AppShadows.smooth(
                color: Colors.black,
                opacity: enableGlass ? 0.28 : 0.15,
                blurFactor: enableGlass ? 1.5 : 1.0,
              ),
            ),
            child: _AddAppSheetContent(
              initialUrl: initialUrl,
              editAppId: editAppId,
            ),
          ),
        ),
      );
      final clipped = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: sheet,
      );
      if (!enableGlass) return clipped;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: sheet,
        ),
      );
    },
  );
}

class _AddAppSheetContent extends StatefulWidget {
  final String? initialUrl;
  final String? editAppId;

  const _AddAppSheetContent({
    this.initialUrl,
    this.editAppId,
  });

  @override
  State<_AddAppSheetContent> createState() => _AddAppSheetContentState();
}

class _AddAppSheetContentState extends State<_AddAppSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header
            _buildHeader(context),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.editAppId != null ? tr('editApp') : tr('addApp'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.editAppId != null
                      ? tr('editAppDescription')
                      : tr('addAppDescription'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: tr('close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Placeholder - actual implementation would import from add_app.dart
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            tr('addApp'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            tr('enterAppUrlOrSearch'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Quick add button with animation
class QuickAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool loading;

  const QuickAddButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.loading = false,
  });

  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: (_) => _controller.reverse(),
        onTap: widget.loading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.loading
                  ? null
                  : LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
              color: widget.loading
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.loading
                  ? null
                  : AppShadows.glow(
                      color: Theme.of(context).colorScheme.primary,
                      intensity: 0.6,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: ExpressiveCircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else ...[
                  Icon(
                    widget.icon,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
