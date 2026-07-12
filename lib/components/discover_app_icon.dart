import 'package:flutter/material.dart';

/// Leading icon for the store-style Discover tiles (suggestions and search
/// results). Renders the app's remote icon when a URL is available and
/// degrades silently to a source-type glyph in a tinted circle when the URL
/// is missing or the image fails to load — no error surfaces.
class DiscoverAppIcon extends StatelessWidget {
  /// Remote icon URL; null or empty shows the fallback glyph immediately.
  final String? iconUrl;

  /// Source label ("GitHub", "F-Droid", ...) used to pick the fallback glyph.
  final String sourceName;

  /// Square edge length of the icon.
  final double size;

  /// Corner radius for the loaded image (callers derive it from
  /// CardMetrics so it stays concentric with the surrounding card).
  final double borderRadius;

  const DiscoverAppIcon({
    super.key,
    required this.iconUrl,
    required this.sourceName,
    required this.size,
    required this.borderRadius,
  });

  /// Glyph representing an app source type, shared with the source chip.
  static IconData sourceGlyph(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'github':
      case 'gitlab':
      case 'codeberg':
      case 'sourceforge':
        return Icons.code_rounded;
      case 'f-droid':
      case 'izzyondroid':
        return Icons.android_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        sourceGlyph(sourceName),
        size: size * 0.5,
        color: colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = iconUrl;
    if (url == null || url.isEmpty) return _fallback(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Show the fallback while loading and on any failure — the tile
        // must never show a broken-image error state.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback(context),
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      ),
    );
  }
}

/// Small source label chip ("GitHub", "F-Droid", ...) shown on Discover
/// tiles, styled like a compact store badge.
class DiscoverSourceChip extends StatelessWidget {
  final String sourceName;

  /// Corner radius, derived from CardMetrics by the caller.
  final double borderRadius;

  const DiscoverSourceChip({
    super.key,
    required this.sourceName,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DiscoverAppIcon.sourceGlyph(sourceName),
            size: 12,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              sourceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
