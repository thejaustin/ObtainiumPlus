import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/utils/safe_prefs.dart';

const _dismissedPrefKey = 'dismissedSideloadingNotice2026';
const _learnMoreUrl =
    'https://support.google.com/googleplay/android-developer/answer/16729360';

/// One-time dismissible banner about Google's Sep 30 2026 developer
/// verification / sideloading changes — a policy change users should know
/// about, not something Obtainium Plus can fix in code.
class SideloadingNotice extends StatefulWidget {
  const SideloadingNotice({super.key});

  @override
  State<SideloadingNotice> createState() => _SideloadingNoticeState();
}

class _SideloadingNoticeState extends State<SideloadingNotice> {
  bool? _dismissed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = prefs.safeBool(_dismissedPrefKey) ?? false;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedPrefKey, true);
    if (!mounted) return;
    setState(() {
      _dismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed != false) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('sideloadingNoticeTitle'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr('sideloadingNoticeBody'),
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      launchUrlString(_learnMoreUrl, mode: LaunchMode.externalApplication),
                  child: Text(tr('sideloadingNoticeLearnMore')),
                ),
                TextButton(
                  onPressed: _dismiss,
                  child: Text(tr('sideloadingNoticeDismiss')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
