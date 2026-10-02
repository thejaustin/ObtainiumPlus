import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/network_utils.dart';
import 'package:provider/provider.dart';

class NetworkIndicator extends StatefulWidget {
  const NetworkIndicator({super.key});

  @override
  State<NetworkIndicator> createState() => _NetworkIndicatorState();
}

class _NetworkIndicatorState extends State<NetworkIndicator>
    with SingleTickerProviderStateMixin {
  NetworkQuality _quality = NetworkQuality.good;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _checkQuality();
  }

  Future<void> _checkQuality() async {
    final quality = await checkNetworkQuality();
    if (mounted) {
      setState(() {
        _quality = quality;
        final animsEnabled = context
            .read<PlusSettingsProvider>()
            .plusEnableEnhancedAnimations;
        if (quality == NetworkQuality.offline && animsEnabled) {
          _pulseController.repeat();
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _colorForQuality(ColorScheme cs) {
    switch (_quality) {
      case NetworkQuality.good:
        return cs.primary;
      case NetworkQuality.slow:
        return cs.tertiary;
      case NetworkQuality.offline:
        return cs.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _colorForQuality(colorScheme);
    final animsEnabled = context
        .watch<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;

    return Tooltip(
      message: 'Network: ${_quality.name}',
      child: SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_quality == NetworkQuality.offline && animsEnabled)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 1.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
