import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';

/// Control Grid for Boolean Settings
/// Displays boolean settings in a compact 2-column grid layout
class BooleanControlGrid extends StatelessWidget {
  final List<({
    String key,
    String label,
    String? description,
    bool Function(SettingsProvider) getValue,
    void Function(SettingsProvider, bool) setValue,
  })> settings;

  const BooleanControlGrid({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final settings = settingsProvider;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
              sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: (isDark 
                    ? Theme.of(context).colorScheme.surfaceContainerHighest 
                    : Theme.of(context).colorScheme.surface)
                  .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 1.0),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.1
                  ),
                ),
                boxShadow: AppShadows.smooth(
                  color: Theme.of(context).colorScheme.shadow,
                  opacity: 0.08,
                  blurFactor: settings.plusEnableGlassmorphism ? 1.2 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('quickToggles'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: this.settings.length,
                    itemBuilder: (context, index) {
                      final setting = this.settings[index];
                      final currentValue = setting.getValue(settingsProvider);
                      
                      return _buildBooleanControlItem(
                        context: context,
                        label: setting.label,
                        description: setting.description,
                        value: currentValue,
                        onChanged: (value) {
                          setting.setValue(settingsProvider, value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooleanControlItem({
    required BuildContext context,
    required String label,
    String? description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}