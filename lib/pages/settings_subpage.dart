import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// A dedicated Material 3 Expressive subpage for settings sections
/// (replacing slide-up bottom sheets) with adaptive width centering,
/// one-handed mode integration, and native predictive back navigation.
class SettingsSubpage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget child;

  const SettingsSubpage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double hPadding =
        screenWidth > 840 ? ((screenWidth - 840) / 2) + 16.0 : 16.0;

    return Scaffold(
      body: CustomScrollView(
        physics: plusSettings.scrollPhysics,
        slivers: [
          CustomAppBar(
            title: title,
            subtitle: subtitle,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: child,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + 36,
            ),
          ),
        ],
      ),
    );
  }
}
