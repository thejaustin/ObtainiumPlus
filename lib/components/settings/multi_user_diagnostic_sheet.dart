import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/settings/diagnostic_page_scaffold.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Opens the multi-user report. Kept under its old name so callers work.
Future<void> showMultiUserDiagnosticSheet(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const MultiUserDiagnosticPage()),
  );
}

/// One launchable app seen in one profile.
class ProfileApp {
  final String packageName;
  final String label;
  final String? versionName;
  const ProfileApp(this.packageName, this.label, this.versionName);
}

/// Parses `pm list users` lines like
/// `UserInfo{150:Secure Folder:10001030} running` into id → name.
Map<int, String> parsePmListUsers(String output) {
  final out = <int, String>{};
  for (final m in RegExp(r'UserInfo\{(\d+):([^:}]*)').allMatches(output)) {
    final id = int.tryParse(m.group(1)!);
    if (id != null) out[id] = m.group(2)!.trim();
  }
  return out;
}

/// Lists the user profiles this app can see and the launchable apps in each.
///
/// Android only exposes the caller's own profile group (main user plus work
/// or clone profiles) through `LauncherApps`. Separate users such as Samsung
/// Secure Folder (user 150 on One UI) are not in that group; even the ADB
/// shell gets a SecurityException listing their packages. So the page says
/// those may exist instead of claiming there are none.
class MultiUserDiagnosticPage extends StatefulWidget {
  const MultiUserDiagnosticPage({super.key});

  @override
  State<MultiUserDiagnosticPage> createState() =>
      _MultiUserDiagnosticPageState();
}

class _MultiUserDiagnosticPageState extends State<MultiUserDiagnosticPage> {
  static const _channel = MethodChannel('dev.thejaustin.obtainiumplus/native');

  bool _isLoading = true;
  bool _failed = false;
  Map<int, List<ProfileApp>> _byUser = {};

  /// User id → name from `pm list users` via Shizuku; empty without it.
  Map<int, String> _shellUsers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    final grouped = <int, List<ProfileApp>>{};
    var failed = false;
    try {
      // null package: every launchable app in every visible profile. (The
      // old sheet passed '' through the variant matcher, which matched no
      // package, so it always reported "no profiles".)
      final list = await _channel.invokeListMethod<dynamic>(
        'getInstalledProfilesAndApps',
        {'packageName': null},
      );
      for (final item in list ?? const []) {
        if (item is! Map) continue;
        final pkg = item['packageName'] as String?;
        if (pkg == null) continue;
        final userId = item['userId'] as int? ?? 0;
        final apps = grouped.putIfAbsent(userId, () => []);
        if (apps.any((a) => a.packageName == pkg)) continue;
        apps.add(
          ProfileApp(
            pkg,
            item['label'] as String? ?? pkg,
            item['versionName'] as String?,
          ),
        );
      }
      for (final apps in grouped.values) {
        apps.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
      }
    } catch (_) {
      failed = true;
    }
    var shellUsers = <int, String>{};
    try {
      final out = await _channel
          .invokeMethod<String>('listUsersPrivileged')
          .timeout(const Duration(seconds: 8));
      if (out != null) shellUsers = parsePmListUsers(out);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _shellUsers = shellUsers;
      _byUser = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      _failed = failed;
      _isLoading = false;
    });
  }

  /// Users Shizuku reports that aren't in the visible profile group.
  Map<int, String> get _hiddenUsers => {
    for (final e in _shellUsers.entries)
      if (!_byUser.containsKey(e.key)) e.key: e.value,
  };

  String _labelFor(int userId) {
    final known = profileLabel(userId);
    final shellName = _shellUsers[userId];
    // Prefer the device's own name for profiles we can only number.
    if (shellName != null &&
        shellName.isNotEmpty &&
        known == tr('multiUserOtherProfile', args: ['$userId'])) {
      return shellName;
    }
    return known;
  }

  static String profileLabel(int userId) {
    if (userId == 0) return tr('multiUserMainProfile');
    if (userId == 95) return tr('multiUserDualMessenger');
    if (userId >= 150 && userId <= 160) return tr('multiUserSecureFolder');
    return tr('multiUserOtherProfile', args: ['$userId']);
  }

  void _copyReport() {
    final buffer = StringBuffer()
      ..writeln('### ${tr('multiUserTitle')}')
      ..writeln('${tr('multiUserVisibleProfiles')}: ${_byUser.length}')
      ..writeln();
    for (final entry in _byUser.entries) {
      buffer.writeln(
        '#### ${_labelFor(entry.key)} (user ${entry.key}) - '
        '${entry.value.length}',
      );
      for (final app in entry.value.take(30)) {
        buffer.writeln(
          '- `${app.packageName}` (${app.label}, '
          'v${app.versionName ?? '?'})',
        );
      }
      if (entry.value.length > 30) {
        buffer.writeln('- ... +${entry.value.length - 30}');
      }
      buffer.writeln();
    }
    for (final e in _hiddenUsers.entries) {
      buffer.writeln(
        '#### ${e.value.isEmpty ? profileLabel(e.key) : e.value} '
        '- ${tr('multiUserHiddenProfileDesc', args: ['${e.key}'])}',
      );
    }
    if (_hiddenUsers.isNotEmpty) buffer.writeln();
    buffer.writeln(tr('multiUserHiddenProfilesNote'));
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppHaptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('multiUserReportCopied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (_isLoading) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: ExpressiveCircularProgressIndicator()),
        ),
      );
    } else {
      children.add(
        ExpressiveSettingsGroup(
          title: tr('multiUserVisibleProfiles'),
          icon: Icons.supervised_user_circle_outlined,
          children: [
            if (_failed)
              ListTile(
                leading: Icon(Icons.error_outline_rounded, color: cs.error),
                title: Text(tr('multiUserLoadFailed')),
              )
            else if (_byUser.isEmpty)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(tr('multiUserNoneVisible')),
              ),
            for (final entry in _byUser.entries)
              ExpansionTile(
                key: PageStorageKey<String>('multi_user_profile_${entry.key}'),
                leading: Icon(
                  entry.key == 0
                      ? Icons.person_outline_rounded
                      : Icons.work_outline_rounded,
                ),
                title: Text(
                  _labelFor(entry.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  tr(
                    'multiUserProfileSummary',
                    args: ['${entry.key}', '${entry.value.length}'],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                shape: const Border(),
                collapsedShape: const Border(),
                children: [
                  for (final app in entry.value.take(200))
                    ListTile(
                      dense: true,
                      title: Text(
                        app.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        app.versionName == null
                            ? app.packageName
                            : '${app.packageName} · ${app.versionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
      children.add(
        ExpressiveSettingsGroup(
          title: tr('multiUserAboutTitle'),
          icon: Icons.info_outline_rounded,
          children: [
            for (final e in _hiddenUsers.entries)
              ListTile(
                leading: const Icon(Icons.lock_person_outlined),
                title: Text(
                  e.value.isEmpty ? profileLabel(e.key) : e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  tr('multiUserHiddenProfileDesc', args: ['${e.key}']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(tr('multiUserHiddenProfilesTitle')),
              subtitle: Text(tr('multiUserHiddenProfilesNote')),
            ),
          ],
        ),
      );
    }

    return DiagnosticPageScaffold(
      title: tr('multiUserTitle'),
      storageKey: 'multi_user_diagnostic_scroll',
      actions: [
        IconButton(
          tooltip: tr('refresh'),
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _isLoading ? null : _load,
        ),
        IconButton(
          tooltip: tr('multiUserCopyReport'),
          icon: const Icon(Icons.copy_all_rounded),
          onPressed: _isLoading || _byUser.isEmpty ? null : _copyReport,
        ),
      ],
      children: children,
    );
  }
}
