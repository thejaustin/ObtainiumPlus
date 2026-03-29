import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

class AppDescriptionSlider extends StatefulWidget {
  final AppInMemory app;
  final ScrollController? parentScrollController;

  const AppDescriptionSlider({
    super.key,
    required this.app,
    this.parentScrollController,
  });

  @override
  State<AppDescriptionSlider> createState() => _AppDescriptionSliderState();
}

class _AppDescriptionSliderState extends State<AppDescriptionSlider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        HapticFeedback.mediumImpact();
      } else {
        _controller.reverse();
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final about = widget.app.app.additionalSettings['about']?.toString();
    
    if (about == null || about.isEmpty || !settings.plusEnablePopupSlider) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _heightFactor,
      builder: (context, child) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16 + _dragOffset,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset -= details.primaryDelta!;
                if (_dragOffset < 0) _dragOffset = 0;
                if (_dragOffset > 200) _dragOffset = 200;
              });
            },
            onVerticalDragEnd: (details) {
              if (_dragOffset > 50 || details.primaryVelocity! < -300) {
                _toggleExpansion();
              }
              setState(() => _dragOffset = 0);
            },
            child: Hero(
              tag: 'app_about_${widget.app.app.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ConditionalBlur(sigma: 15, enabled: settings.plusEnableGlassmorphism, child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 80 + (_heightFactor.value * 300),
                    decoration: BoxDecoration(
                      color: (isDark 
                          ? colorScheme.surfaceContainerHighest 
                          : colorScheme.surface)
                        .withValues(alpha: settings.plusEnableGlassmorphism ? 0.7 : 1.0),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: AppShadows.smooth(
                        color: Colors.black,
                        opacity: settings.plusEnableGlassmorphism ? 0.2 : 0.1,
                        blurFactor: settings.plusEnableGlassmorphism ? 1.2 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleExpansion,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('about'),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!_isExpanded)
                                          Text(
                                            about.split('\n').first,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _isExpanded 
                                      ? Icons.keyboard_arrow_down_rounded 
                                      : Icons.keyboard_arrow_up_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              if (_heightFactor.value > 0.1) ...[
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Opacity(
                                    opacity: _heightFactor.value,
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: MarkdownBody(
                                        data: about,
                                        onTapLink: (text, href, title) => href != null 
                                          ? launchUrlString(href, mode: LaunchMode.externalApplication) 
                                          : null,
                                        extensionSet: md.ExtensionSet(
                                          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                                          [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
                                        ),
                                        styleSheet: MarkdownStyleSheet(
                                          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
