import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

class GeneratedFormModal extends StatefulWidget {
  const GeneratedFormModal({
    super.key,
    required this.title,
    required this.items,
    this.initValid = false,
    this.message = '',
    this.additionalWidgets = const [],
    this.singleNullReturnButton,
    this.primaryActionColour,
  });

  final String title;
  final String message;
  final List<List<GeneratedFormItem>> items;
  final bool initValid;
  final List<Widget> additionalWidgets;
  final String? singleNullReturnButton;
  final Color? primaryActionColour;

  @override
  State<GeneratedFormModal> createState() => _GeneratedFormModalState();
}

class _GeneratedFormModalState extends State<GeneratedFormModal> {
  Map<String, dynamic> values = {};
  bool valid = false;

  @override
  void initState() {
    super.initState();
    valid = widget.initValid || widget.items.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final dialogRadius = radius.clamp(24.0, 48.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(
            alpha: enableGlass ? 0.78 : 1.0,
          ),
          borderRadius: BorderRadius.circular(dialogRadius),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withValues(alpha: 0.18)
                : colorScheme.outline.withValues(alpha: AppOpacity.subtle),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enableGlass ? 0.2 : 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dialogRadius),
          child: ConditionalBlur(
            sigma: 24,
            enabled: enableGlass,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, colorScheme, dialogRadius),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.message.isNotEmpty)
                          Text(
                            widget.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (widget.message.isNotEmpty)
                          const SizedBox(height: 16),
                        GeneratedForm(
                          items: widget.items,
                          onValueChanges: (values, valid, isBuilding) {
                            if (isBuilding) {
                              this.values = values;
                              this.valid = valid;
                            } else {
                              setState(() {
                                this.values = values;
                                this.valid = valid;
                              });
                            }
                          },
                        ),
                        if (widget.additionalWidgets.isNotEmpty)
                          ...widget.additionalWidgets,
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildActions(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    double radius,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              widget.singleNullReturnButton ?? tr('cancel'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (widget.singleNullReturnButton == null) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              style: widget.primaryActionColour == null
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: widget.primaryActionColour,
                    ),
              onPressed: !valid
                  ? null
                  : () {
                      AppHaptics.selectionClick();
                      Navigator.of(context).pop(values);
                    },
              child: Text(tr('continue')),
            ),
          ],
        ],
      ),
    );
  }
}
