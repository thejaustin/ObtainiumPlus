import 'package:flutter/foundation.dart';

/// Shares the Settings page's selected category with the home scaffold, so a
/// category bar hosted by home (the Visual Lab "merged" placement, and the
/// separate `bottom` pill while Settings is a home tab) drives the page.
///
/// Held by `HomePageState` and passed to the home-tab `SettingsPage` only; a
/// standalone pushed Settings page gets none and draws its own bar.
class SettingsSectionController {
  SettingsSectionController({int initialSection = 0})
    : section = ValueNotifier<int>(initialSection);

  /// Selected category (0 Appearance … 4 Advanced & Debug).
  final ValueNotifier<int> section;

  /// True while the Settings page shows search results — the hosted
  /// category row hides, like the page's own bar does.
  final ValueNotifier<bool> searching = ValueNotifier<bool>(false);

  /// Hosted bar visibility for scroll-away (`bottom` placement only).
  final ValueNotifier<bool> dockVisible = ValueNotifier<bool>(true);

  /// Set by the attached Settings page: called when the user taps a
  /// category in the hosted bar (including re-taps of the current one,
  /// which scroll to top — a plain ValueNotifier wouldn't fire for those).
  ValueChanged<int>? onSelect;

  void select(int index) {
    final handler = onSelect;
    if (handler != null) {
      handler(index);
    } else {
      section.value = index;
    }
  }

  void dispose() {
    section.dispose();
    searching.dispose();
    dockVisible.dispose();
  }
}
