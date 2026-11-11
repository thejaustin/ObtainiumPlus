import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/components/settings/spring_expandable.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/theme.dart';
import 'package:obtainium/theme/settings_tokens.dart';
import 'package:provider/provider.dart';

/// Children that actually render: drops childless `SizedBox`es, hidden
/// `Visibility` / `Offstage` wrappers and — with [dropEmptyGroups] — nested
/// groups whose own children are all hidden. Run BEFORE first/last positions
/// are computed so a hidden last row never leaves a square corner.
///
/// Not detectable: a `Consumer` / builder that decides at build time to
/// render `SizedBox.shrink()` (e.g. a Plus-gated `buildFeatureToggle`). The
/// segmented group clips to its outer radius so such a row can't leave a
/// square corner showing.
List<Widget> visibleSettingsChildren(
  List<Widget> children, {
  bool dropEmptyGroups = true,
}) {
  return children.where((child) {
    if (child is SizedBox && child.child == null) return false;
    if (child is Visibility && !child.visible) return false;
    if (!dropEmptyGroups) return true;
    if (child is Offstage && child.offstage) return false;
    if (child is SettingsSection &&
        visibleSettingsChildren(child.children).isEmpty) {
      return false;
    }
    if (child is ExpressiveSettingsGroup &&
        visibleSettingsChildren(child.children).isEmpty) {
      return false;
    }
    if (child is SegmentedSettingsGroup &&
        visibleSettingsChildren(child.children).isEmpty) {
      return false;
    }
    return true;
  }).toList();
}

/// A settings group in either style. [style] null follows
/// `plusSettingsGroupStyle` (default [SettingsGroupStyle.card], which is
/// today's [ExpressiveSettingsGroup] card unchanged).
class SettingsSection extends StatelessWidget {
  final String? title;
  final String? description;
  final IconData? icon;
  final List<Widget> children;
  final SettingsGroupStyle? style;
  final bool isExpandable;
  final bool initiallyExpanded;
  final VoidCallback? onReset;
  final String? persistKey;

  const SettingsSection({
    super.key,
    this.title,
    this.description,
    this.icon,
    required this.children,
    this.style,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.onReset,
    this.persistKey,
  });

  @override
  Widget build(BuildContext context) {
    final setting = context.select<PlusSettingsProvider, SettingsGroupStyle>(
      (p) => p.plusSettingsGroupStyle,
    );
    final resolved = style ?? setting;
    if (resolved == SettingsGroupStyle.card) {
      return ExpressiveSettingsGroup(
        title: title,
        description: description,
        icon: icon,
        isExpandable: isExpandable,
        initiallyExpanded: initiallyExpanded,
        onReset: onReset,
        persistKey: persistKey,
        style: SettingsGroupStyle.card,
        children: children,
      );
    }
    return SegmentedSettingsGroup(
      title: title,
      description: description,
      icon: icon,
      isExpandable: isExpandable,
      initiallyExpanded: initiallyExpanded,
      onReset: onReset,
      persistKey: persistKey,
      children: children,
    );
  }
}

/// M3E segmented group: an open primary label, then each row on its own
/// surface with 2 dp gaps; outer corners on the ends, inner corners at the
/// joints (`plusSettingsGroupOuterRadius` / `InnerRadius`, 16 / 4 by
/// default), squeezing to the outer radius while pressed.
class SegmentedSettingsGroup extends StatelessWidget {
  final String? title;
  final String? description;
  final IconData? icon;
  final List<Widget> children;
  final bool isExpandable;
  final bool initiallyExpanded;
  final VoidCallback? onReset;
  final String? persistKey;

  /// Overrides the radius settings (tests, previews).
  final double? outerRadius;
  final double? innerRadius;

  const SegmentedSettingsGroup({
    super.key,
    this.title,
    this.description,
    this.icon,
    required this.children,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.onReset,
    this.persistKey,
    this.outerRadius,
    this.innerRadius,
  });

  @override
  Widget build(BuildContext context) {
    final (isCompact, setOuter, setInner, descriptionLines) = context
        .select<PlusSettingsProvider, (bool, double, double, int)>(
          (p) => (
            p.plusUseCompactSettings,
            p.plusSettingsGroupOuterRadius,
            p.plusSettingsGroupInnerRadius,
            p.plusLabCompactDescriptionLines,
          ),
        );
    final outer = (outerRadius ?? setOuter).clamp(
      0.0,
      SettingsTokens.maxOuterRadius,
    );
    final inner = (innerRadius ?? setInner).clamp(0.0, outer);
    final cs = Theme.of(context).colorScheme;
    final color = SettingsTokens.rowColor(cs);

    final visible = visibleSettingsChildren(children);
    if (visible.isEmpty) return const SizedBox.shrink();

    Widget wrapCompact(Widget w) =>
        isCompact ? Theme(data: settingsCompactTheme(context), child: w) : w;

    if (isExpandable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SpringExpandable(
          storageKey:
              'expressive_settings_group:${persistKey ?? title ?? 'group'}',
          title: Text(title ?? tr('settings')),
          subtitle: (!isCompact && description != null)
              ? Text(
                  description!,
                  maxLines: descriptionLines,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          leading: icon != null ? Icon(icon) : null,
          trailing: onReset != null ? _ResetButton(onReset: onReset!) : null,
          initiallyExpanded: initiallyExpanded,
          outerRadius: outer,
          innerRadius: inner,
          color: color,
          children: [
            for (final c in visible)
              PageStorage(bucket: PageStorageBucket(), child: wrapCompact(c)),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: SettingsTokens.segmentGap));
      rows.add(
        PressMorphSurface(
          radius: positionalTileRadius(
            isFirst: i == 0,
            isLast: i == visible.length - 1,
            outer: outer,
            inner: inner,
          ),
          pressedRadius: BorderRadius.circular(outer),
          color: color,
          child: SettingsSegmentScope(child: wrapCompact(visible[i])),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: SettingsTokens.labelPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: SettingsTokens.labelStyle(context),
                        ),
                      ),
                      if (!isCompact && description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description!,
                            maxLines: descriptionLines,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onReset != null) _ResetButton(onReset: onReset!),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(outer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetButton({required this.onReset});

  @override
  Widget build(BuildContext context) => ScaleTouchWrapper(
    hapticOnPressDown: true,
    scaleDownFactor: 0.88,
    child: IconButton(
      icon: const Icon(Icons.restore_rounded, size: 20),
      onPressed: onReset,
      tooltip: tr('resetToDefault'),
      visualDensity: VisualDensity.compact,
    ),
  );
}
