import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// A custom AppBar that provides consistent M3 styling across the app.
/// Returns a standard AppBar for use in plain Scaffold contexts.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.actions, this.bottom});

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: actions,
      bottom: bottom,
    );
  }
}

/// A sliver-based app bar for use in CustomScrollView contexts.
/// Provides the large, expanding/collapsing M3 style app bar.
class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      pinned: pinned,
      floating: floating,
      snap: snap,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      actions: actions,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

/// A compact sliver app bar (non-large) for use in CustomScrollView contexts.
class CustomSliverAppBarCompact extends StatelessWidget {
  const CustomSliverAppBarCompact({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      snap: snap,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      actions: actions,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

/// A smart sliver app bar that automatically chooses between compact and large
/// based on the user's settings for a specific page.
class AdaptiveSliverAppBar extends StatelessWidget {
  const AdaptiveSliverAppBar({
    super.key,
    required this.title,
    required this.pageId,
    this.actions,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String pageId;
  final List<Widget>? actions;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final style = context.select<SettingsProvider, AppBarStyle>(
      (sp) => sp.getAppBarStyleForPage(pageId),
    );

    if (style == AppBarStyle.large) {
      return CustomSliverAppBar(
        title: title,
        actions: actions,
        leading: leading,
        pinned: pinned,
        floating: floating,
        snap: snap,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    } else {
      return CustomSliverAppBarCompact(
        title: title,
        actions: actions,
        leading: leading,
        pinned: pinned,
        floating: floating,
        snap: snap,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }
  }
}
