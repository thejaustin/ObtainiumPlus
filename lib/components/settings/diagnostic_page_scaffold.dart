import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/theme.dart';

/// Full-page shell shared by the diagnostic pages (Service Doctor, Play
/// diagnostics, inspector, multi-user report): the collapsing app bar and
/// width-capped content column used by the Update health page.
class DiagnosticPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  /// Distinct per page so scroll offsets never share a PageStorage slot.
  final String storageKey;

  /// Content sections, laid out top to bottom with section gaps.
  final List<Widget> children;

  /// Optional slivers placed before [children] (e.g. a pinned search row).
  final List<Widget> leadingSlivers;

  const DiagnosticPageScaffold({
    super.key,
    required this.title,
    required this.storageKey,
    required this.children,
    this.subtitle,
    this.actions,
    this.leadingSlivers = const [],
  });

  static EdgeInsets contentPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = width > 1040
        ? ((width - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;
    return EdgeInsets.symmetric(horizontal: margin);
  }

  @override
  Widget build(BuildContext context) {
    final padding = contentPadding(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        key: PageStorageKey<String>(storageKey),
        slivers: [
          CustomAppBar(title: title, subtitle: subtitle, actions: actions),
          ...leadingSlivers,
          SliverPadding(
            padding: padding.copyWith(top: AppSpacings.elementGap),
            sliver: SliverList.separated(
              itemCount: children.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacings.elementGap),
              itemBuilder: (_, i) => children[i],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ),
        ],
      ),
    );
  }
}
