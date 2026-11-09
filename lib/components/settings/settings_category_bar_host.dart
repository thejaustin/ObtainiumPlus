import 'package:flutter/material.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/settings_section_controller.dart';
import 'package:provider/provider.dart';

/// The Settings category bar as hosted by the home scaffold's bottom bar,
/// above the main destinations (Visual Lab `bottom` and `merged`).
///
/// Being part of the scaffold's `bottomNavigationBar` makes it count in the
/// body's bottom inset (`extendBody`), so the settings scroll view's padding
/// always clears both bars.
///
/// - [separate]: its own floating pill, [kSettingsDockGap] above the main
///   bar, sliding away while scrolling down like the page's own dock.
/// - otherwise: a bare row sharing the main bar's surface (merged).
///
/// Size + fade in/out when [show] flips (entering/leaving the Settings tab)
/// or a settings search starts, gated on enhanced animations.
class SettingsCategoryBarHost extends StatelessWidget {
  final SettingsSectionController controller;
  final bool show;
  final bool separate;

  const SettingsCategoryBarHost({
    super.key,
    required this.controller,
    required this.show,
    required this.separate,
  });

  @override
  Widget build(BuildContext context) {
    final anims = context.select<PlusSettingsProvider, bool>(
      (s) => s.plusEnableEnhancedAnimations,
    );
    final isM3E = context.select<PlusSettingsProvider, bool>(
      (s) => s.plusEnableMaterialExpressive,
    );
    final cornerRadius = context.select<PlusSettingsProvider, double>(
      (s) => s.plusGlobalCornerRadius,
    );
    final duration = Duration(milliseconds: anims ? 280 : 0);

    Widget dock({required bool surface}) => ValueListenableBuilder<int>(
      valueListenable: controller.section,
      builder: (context, selected, _) => SettingsSectionDock(
        selectedIndex: selected,
        isM3E: isM3E,
        animsEnabled: anims,
        cornerRadius: cornerRadius,
        onSelect: controller.select,
        surface: surface,
      ),
    );

    final Widget row = separate
        ? Padding(
            padding: const EdgeInsets.only(bottom: kSettingsDockGap),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ValueListenableBuilder<bool>(
                  valueListenable: controller.dockVisible,
                  builder: (context, visible, child) => IgnorePointer(
                    ignoring: !visible,
                    child: AnimatedSlide(
                      offset: visible ? Offset.zero : const Offset(0, 1.6),
                      duration: Duration(milliseconds: anims ? 260 : 0),
                      curve: visible
                          ? Easing.emphasizedDecelerate
                          : Easing.emphasizedAccelerate,
                      child: AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: Duration(milliseconds: anims ? 200 : 0),
                        child: child,
                      ),
                    ),
                  ),
                  child: dock(surface: true),
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: dock(surface: false),
          );

    return ValueListenableBuilder<bool>(
      valueListenable: controller.searching,
      builder: (context, searching, child) {
        final visible = show && !searching;
        return AnimatedSwitcher(
          duration: duration,
          switchInCurve: Easing.emphasizedDecelerate,
          switchOutCurve: Easing.emphasizedAccelerate,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: 1.0,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: visible
              ? KeyedSubtree(
                  key: const ValueKey<String>('settings_category_row'),
                  child: row,
                )
              : const SizedBox(
                  key: ValueKey<String>('settings_category_row_none'),
                  width: double.infinity,
                ),
        );
      },
    );
  }
}
