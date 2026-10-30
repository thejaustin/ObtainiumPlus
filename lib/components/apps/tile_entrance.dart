import 'package:flutter/widgets.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Decides whether an app tile plays its fade-in.
///
/// Tiles are rebuilt whenever they scroll back into view or move after the
/// list re-sorts (e.g. when an install finishes). Replaying the fade each
/// time made rows blink in while scrolling, so it now plays only while the
/// list first appears, and at most once per app.
class TileEntrance {
  TileEntrance._();

  static const _window = Duration(milliseconds: 1200);
  static final Set<String> _played = {};
  static DateTime? _firstAt;

  static bool shouldPlay(BuildContext context, String appId) {
    if (!context.read<PlusSettingsProvider>().plusEnableEnhancedAnimations) {
      return false;
    }
    final now = DateTime.now();
    _firstAt ??= now;
    if (now.difference(_firstAt!) > _window) return false;
    return _played.add(appId);
  }
}
