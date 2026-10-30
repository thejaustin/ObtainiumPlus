import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/core/logging/app_log_db.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/providers/logs_provider.dart' hide AppLogger;
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/theme.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  static const List<int> _dayOptions = [7, 5, 4, 3, 2, 1];

  final ScrollController _scrollController = ScrollController();
  List<LogEntry> _logs = [];
  int _days = _dayOptions.first;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs(_days);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs(int days) async {
    setState(() => _loading = true);
    List<LogEntry> value;
    try {
      final after = DateTime.now().subtract(Duration(days: days));
      // Install, download and background-update messages go to the older
      // LogsProvider store (the background isolate has no AppLogger), so
      // show both, in time order.
      final results = await Future.wait([
        AppLogger.getLogs(after: after),
        LogsProvider(
          runDefaultClear: false,
        ).get(after: after).then((l) => l, onError: (Object _) => <Log>[]),
      ]);
      value = mergeLogStores(
        results[0] as List<LogEntry>,
        results[1] as List<Log>,
      );
    } catch (e, s) {
      AppLogger.error(e, stackTrace: s, message: 'Failed to load logs');
      value = [];
    }
    if (!mounted) return;
    setState(() {
      _days = days;
      _logs = value;
      _loading = false;
    });
  }

  String _joinLogs() => _logs.map((e) => e.toString()).join('\n\n');

  void _scrollTo(double offset) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      offset,
      duration: ExpressiveMotion.medium,
      curve: ExpressiveMotion.emphasized,
    );
  }

  void _scrollToTop() => _scrollTo(0);

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _clearLogs() async {
    final cont = await showContinueCancelDialog(
      context,
      title: tr('clearLogs'),
      message: tr('clearLogsWarning'),
    );
    if (!cont) return;
    await AppLogger.clearLogs();
    try {
      await LogsProvider(runDefaultClear: false).clear();
    } catch (_) {}
    if (!mounted) return;
    showMessage(tr('logsCleared'), context);
    await _loadLogs(_days);
  }

  void _copyLogs() {
    unawaited(copyToClipboard(context, _joinLogs()));
  }

  void _shareLogs() {
    unawaited(() async {
      try {
        await SharePlus.instance.share(
          ShareParams(text: _joinLogs(), subject: tr('appLogs')),
        );
      } catch (e, s) {
        AppLogger.error(e, stackTrace: s, message: 'Failed to share logs');
        if (mounted) {
          await copyToClipboard(context, _joinLogs());
        }
      }
    }());
  }

  Color _levelColor(BuildContext context, AppLogLevel level) {
    final cs = Theme.of(context).colorScheme;
    return switch (level) {
      AppLogLevel.error => cs.error,
      AppLogLevel.warning => cs.tertiary,
      AppLogLevel.debug => cs.onSurfaceVariant,
      AppLogLevel.info => cs.onSurface,
    };
  }

  String _levelLabel(AppLogLevel level) => switch (level) {
    AppLogLevel.error => tr('error'),
    AppLogLevel.warning => tr('warning'),
    AppLogLevel.debug => tr('debug'),
    AppLogLevel.info => tr('info'),
  };

  Widget _logTile(LogEntry log) {
    final color = _levelColor(context, log.level);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: adaptiveMargin, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat.yMd().add_Hms().format(log.timestamp.toLocal())} · '
            '${_levelLabel(log.level)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            log.message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _toolbarDivider(ColorScheme cs) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: cs.outlineVariant,
  );

  /// A single M3 Expressive floating toolbar that consolidates navigation
  /// (jump to top/bottom) and actions (filter, share/copy, clear) into one
  /// pill, rather than scattering them across the app bar and multiple FABs.
  /// Android TV has no share sheet, so the share action is replaced with a
  /// copy-to-clipboard action there.
  Widget _buildFloatingToolbar(BuildContext context, {required bool isTV}) {
    final cs = Theme.of(context).colorScheme;
    final hasLogs = _logs.isNotEmpty;
    return Material(
      elevation: 3,
      color: cs.surfaceContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTouchWrapper(
              hapticOnPressDown: hasLogs,
              scaleDownFactor: 0.88,
              child: IconButton(
                onPressed: hasLogs
                    ? () {
                        AppHaptics.selectionClick();
                        _scrollToTop();
                      }
                    : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
            ),
            ScaleTouchWrapper(
              hapticOnPressDown: hasLogs,
              scaleDownFactor: 0.88,
              child: IconButton(
                onPressed: hasLogs
                    ? () {
                        AppHaptics.selectionClick();
                        _scrollToBottom();
                      }
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
            _toolbarDivider(cs),
            ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.88,
              child: PopupMenuButton<int>(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: tr('filter'),
                initialValue: _days,
                onSelected: (days) {
                  AppHaptics.selectionClick();
                  _loadLogs(days);
                },
                itemBuilder: (context) => _dayOptions
                    .map(
                      (e) => CheckedPopupMenuItem<int>(
                        value: e,
                        checked: e == _days,
                        child: Text(plural('day', e)),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (isTV)
              ScaleTouchWrapper(
                hapticOnPressDown: hasLogs,
                scaleDownFactor: 0.88,
                child: IconButton(
                  onPressed: hasLogs
                      ? () {
                          AppHaptics.selectionClick();
                          _copyLogs();
                        }
                      : null,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: tr('copyToClipboard'),
                ),
              )
            else
              ScaleTouchWrapper(
                hapticOnPressDown: hasLogs,
                scaleDownFactor: 0.88,
                child: IconButton(
                  onPressed: hasLogs
                      ? () {
                          AppHaptics.selectionClick();
                          _shareLogs();
                        }
                      : null,
                  icon: const Icon(Icons.share_rounded),
                  tooltip: tr('share'),
                ),
              ),
            ScaleTouchWrapper(
              hapticOnPressDown: hasLogs,
              scaleDownFactor: 0.88,
              child: IconButton(
                onPressed: hasLogs
                    ? () {
                        AppHaptics.selectionClick();
                        _clearLogs();
                      }
                    : null,
                color: cs.error,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: tr('remove'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTV = context.select<SettingsProvider, bool>((p) => p.isTV);
    final logList = CustomScrollView(
      key: const PageStorageKey<String>('logs_scroll'),
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: true,
          title: Text(tr('appLogs')),
        ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: ExpressiveCircularProgressIndicator()),
          )
        else if (_logs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.bug_report_outlined,
              message: tr('noLogs'),
            ),
          )
        else
          SliverList.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) => _logTile(_logs[index]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // SelectionArea is pointless on a remote-controlled TV and its
          // focusable region swallows D-pad input before it can reach the
          // floating toolbar.
          if (isTV) logList else SelectionArea(child: logList),
          // Docked in a Stack rather than the Scaffold's floatingActionButton
          // slot so it doesn't play the FAB scale/rotate entrance animation.
          if (!_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildFloatingToolbar(context, isTV: isTV),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Both log stores as one list, oldest first.
@visibleForTesting
List<LogEntry> mergeLogStores(List<LogEntry> appLogs, List<Log> legacyLogs) {
  final merged = [
    ...appLogs,
    for (final l in legacyLogs)
      LogEntry(
        message: l.message,
        level: switch (l.level) {
          LogLevel.debug => AppLogLevel.debug,
          LogLevel.info => AppLogLevel.info,
          LogLevel.warning => AppLogLevel.warning,
          LogLevel.error => AppLogLevel.error,
        },
        timestamp: l.timestamp,
      ),
  ];
  merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return merged;
}
