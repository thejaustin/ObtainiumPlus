import 'package:flutter/material.dart';
import 'package:obtainium/utils/network_utils.dart';

class NetworkIndicator extends StatefulWidget {
  const NetworkIndicator({super.key});

  @override
  State<NetworkIndicator> createState() => _NetworkIndicatorState();
}

class _NetworkIndicatorState extends State<NetworkIndicator> {
  NetworkQuality _quality = NetworkQuality.good;

  @override
  void initState() {
    super.initState();
    _checkQuality();
  }

  Future<void> _checkQuality() async {
    final quality = await checkNetworkQuality();
    if (mounted) {
      setState(() {
        _quality = quality;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (_quality) {
      case NetworkQuality.good:
        indicatorColor = Colors.green;
        break;
      case NetworkQuality.slow:
        indicatorColor = Colors.orange;
        break;
      case NetworkQuality.offline:
        indicatorColor = Colors.red;
        break;
    }

    return Tooltip(
      message: 'Network: ${_quality.name}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
