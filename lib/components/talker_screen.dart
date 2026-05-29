import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:easy_localization/easy_localization.dart';

class TalkerScreen extends StatefulWidget {
  final Talker talker;
  const TalkerScreen({super.key, required this.talker});

  @override
  State<TalkerScreen> createState() => _TalkerScreenState();
}

class _TalkerScreenState extends State<TalkerScreen> {
  String _searchQuery = '';
  String _filterType = 'ALL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter logs
    final filteredLogs = widget.talker.history.where((entry) {
      final matchesSearch = entry.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.title.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterType == 'ALL') return matchesSearch;
      return matchesSearch && entry.title == _filterType;
    }).toList().reversed.toList();

    Color getTitleColor(String title) {
      switch (title) {
        case 'INFO':
          return Colors.green;
        case 'WARNING':
          return Colors.orange;
        case 'ERROR':
        case 'EXCEPTION':
          return Colors.red;
        case 'DEBUG':
          return Colors.blue;
        default:
          return colorScheme.primary;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('diagnosticsLogViewer')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: tr('copyAllToClipboard'),
            onPressed: () {
              final text = widget.talker.history
                  .map((e) => '[${e.timestamp.toIso8601String()}] [${e.title}] ${e.message}')
                  .join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('allLogsCopiedToClipboard'))),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: tr('clearHistory'),
            onPressed: () {
              setState(() {
                widget.talker.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('logHistoryCleared'))),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: tr('searchLogs'),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    DropdownButton<String>(
                      value: _filterType,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'ALL', child: Text(tr('all'))),
                        DropdownMenuItem(value: 'INFO', child: Text(tr('info'))),
                        DropdownMenuItem(value: 'WARNING', child: Text(tr('warning'))),
                        DropdownMenuItem(value: 'EXCEPTION', child: Text(tr('errors'))),
                        DropdownMenuItem(value: 'DEBUG', child: Text(tr('debug'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _filterType = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Logs list
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          tr('noLogsMatchesTheFilter'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final titleColor = getTitleColor(log.title);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: titleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: titleColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              log.title,
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          title: Text(
                            log.message.split('\n').first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SelectableText(
                                log.message,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
