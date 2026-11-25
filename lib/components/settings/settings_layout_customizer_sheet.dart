import 'package:obtainium/utils/app_shapes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/models/settings_block.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Modal bottom sheet allowing users to customize, reorder, pin, or hide
/// settings cards and sections for an immersive, adaptive layout.
class SettingsLayoutCustomizerSheet extends StatefulWidget {
  const SettingsLayoutCustomizerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false, // the sheet draws its own handle
      builder: (context) => const SettingsLayoutCustomizerSheet(),
    );
  }

  @override
  State<SettingsLayoutCustomizerSheet> createState() =>
      _SettingsLayoutCustomizerSheetState();
}

class _SettingsLayoutCustomizerSheetState
    extends State<SettingsLayoutCustomizerSheet> {
  SettingsCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final layoutConfig = plusSettings.settingsLayoutConfig;

    final categories = SettingsCategory.values;
    final activeCategory = _selectedCategory;

    final displayedBlocks = activeCategory == null
        ? SettingsBlockRegistry.allBlocks
        : SettingsBlockRegistry.forCategory(activeCategory);

    final pinnedCount = layoutConfig.pinnedBlocks.length;
    final hiddenCount = layoutConfig.hiddenBlocks.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppShapes.of(context).radiusOf(ShapeRole.sheet)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('customizeSettingsLayout'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('customizeSettingsLayoutDesc'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tr('resetSettingsLayout'),
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: (pinnedCount > 0 || hiddenCount > 0)
                      ? () => _confirmReset(context, plusSettings)
                      : null,
                ),
              ],
            ),
          ),

          // Active stats badge summary
          if (pinnedCount > 0 || hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  if (pinnedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: AppShapes.of(
                          context,
                        ).borderRadiusOf(ShapeRole.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pinnedCount ${tr('pinnedSettingsBlocks').toLowerCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hiddenCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: AppShapes.of(
                          context,
                        ).borderRadiusOf(ShapeRole.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$hiddenCount ${tr('hiddenSettingsBlocks').toLowerCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: activeCategory == null,
                      label: Text(tr('all')),
                      avatar: const Icon(Icons.apps_rounded, size: 16),
                      onSelected: (_) {
                        AppHaptics.selectionClick();
                        setState(() => _selectedCategory = null);
                      },
                    ),
                  ),
                  for (final cat in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: activeCategory == cat,
                        label: Text(tr(cat.labelKey)),
                        avatar: Icon(cat.icon, size: 16),
                        onSelected: (_) {
                          AppHaptics.selectionClick();
                          setState(
                            () => _selectedCategory = activeCategory == cat
                                ? null
                                : cat,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Block items list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: displayedBlocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final block = displayedBlocks[index];
                final isPinned = layoutConfig.isPinned(block.id);
                final isHidden = layoutConfig.isHidden(block.id);

                return Container(
                  decoration: BoxDecoration(
                    color: isHidden
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          )
                        : colorScheme.surfaceContainerLow,
                    borderRadius: AppShapes.of(
                      context,
                    ).borderRadiusOf(ShapeRole.card),
                    border: Border.all(
                      color: isPinned
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : isHidden
                          ? colorScheme.outlineVariant.withValues(alpha: 0.2)
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: isPinned ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPinned
                            ? colorScheme.primaryContainer
                            : isHidden
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        block.icon,
                        size: 20,
                        color: isPinned
                            ? colorScheme.onPrimaryContainer
                            : isHidden
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              )
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(block.titleKey),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isHidden
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isHidden
                                  ? colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (block.isProOrAdvanced)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PRO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      tr(block.descriptionKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: isHidden ? 0.5 : 0.8,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin button
                        ScaleTouchWrapper(
                          hapticOnPressDown: true,
                          scaleDownFactor: 0.9,
                          child: IconButton(
                            tooltip: isPinned ? 'Unpin' : 'Pin to top',
                            icon: Icon(
                              isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              color: isPinned ? colorScheme.primary : null,
                              size: 20,
                            ),
                            onPressed: () {
                              AppHaptics.selectionClick();
                              plusSettings.togglePinSettingsBlock(block.id);
                            },
                          ),
                        ),
                        // Hide button
                        ScaleTouchWrapper(
                          hapticOnPressDown: true,
                          scaleDownFactor: 0.9,
                          child: IconButton(
                            tooltip: isHidden ? 'Show' : 'Hide',
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_outlined,
                              color: isHidden ? colorScheme.error : null,
                              size: 20,
                            ),
                            onPressed: () {
                              AppHaptics.selectionClick();
                              plusSettings.toggleHideSettingsBlock(block.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, PlusSettingsProvider provider) {
    showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: tr('resetSettingsLayout'),
        icon: Icons.refresh_rounded,
        content: Text(tr('resetSettingsLayoutConfirm')),
        actions: [
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel')),
            ),
          ),
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: FilledButton(
              onPressed: () {
                AppHaptics.toggleOn();
                Navigator.pop(context, true);
              },
              child: Text(tr('reset')),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.resetSettingsLayout();
      }
    });
  }
}
