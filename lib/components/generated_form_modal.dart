import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
    this.icon,
  });

  final String title;
  final String message;
  final List<List<GeneratedFormItem>> items;
  final bool initValid;
  final List<Widget> additionalWidgets;
  final String? singleNullReturnButton;
  final Color? primaryActionColour;
  final IconData? icon;

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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enableGlass ? 0.28 : 0.1),
              blurRadius: enableGlass ? 32 : 10,
              spreadRadius: enableGlass ? -2 : -5,
            ),
            if (enableGlass)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: enableGlass ? 24 : 0,
              sigmaY: enableGlass ? 24 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, enableGlass),
                const Divider(height: 1),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.message.isNotEmpty) ...[
                          Text(widget.message),
                          const SizedBox(height: 16),
                        ],
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
                        ...widget.additionalWidgets,
                      ],
                    ),
                  ),
                ),
                // Actions
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: enableGlass ? 0.5 : 1.0),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: Text(
              widget.singleNullReturnButton == null
                  ? tr('cancel')
                  : widget.singleNullReturnButton!,
            ),
          ),
          if (widget.singleNullReturnButton == null)
            TextButton(
              style: widget.primaryActionColour == null
                  ? null
                  : TextButton.styleFrom(
                      foregroundColor: widget.primaryActionColour,
                    ),
              onPressed: !valid
                  ? null
                  : () {
                      if (valid) {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(values);
                      }
                    },
              child: Text(tr('continue')),
            ),
        ],
      ),
    );
  }
}
