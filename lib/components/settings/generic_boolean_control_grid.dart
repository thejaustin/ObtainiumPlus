import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

/// Generic Control Grid for Boolean Settings
/// Displays boolean settings in a compact grid layout
class GenericBooleanControlGrid<T extends ChangeNotifier> extends StatelessWidget {
  final String title;
  final List<
    ({
      IconData icon,
      String label,
      String? description,
      bool Function(T) getValue,
      void Function(T, bool) setValue,
    })
  >
  settings;

  const GenericBooleanControlGrid({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<T, PlusSettingsProvider>(
      builder: (context, provider, plusSettings, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: ConditionalBlur(
              sigma: 10,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: (isDark
                          ? Theme.of(context).colorScheme.surfaceContainerLow
                          : Theme.of(context).colorScheme.surface)
                      .withOpacity(plusSettings.plusEnableGlassmorphism ? 0.7 : 1.0),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(
                      plusSettings.plusEnableGlassmorphism ? 0.4 : 0.2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: settings.length,
                      itemBuilder: (context, index) {
                        final setting = settings[index];
                        return _buildGridItem(
                          context,
                          provider,
                          setting,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    T provider,
    ({
      IconData icon,
      String label,
      String? description,
      bool Function(T) getValue,
      void Function(T, bool) setValue,
    }) setting,
  ) {
    final value = setting.getValue(provider);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setting.setValue(provider, !value);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                setting.icon,
                size: 20,
                color: value ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                setting.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Switch(
                value: value,
                onChanged: (v) => setting.setValue(provider, v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                scale: 0.7,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension SwitchScale on Switch {
  Widget scaled(double scale) {
    return Transform.scale(scale: scale, child: this);
  }
}
