import 'package:flutter/material.dart';
import 'package:obtainium/services/contributors_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Who made Obtainium+, who made Obtainium, and whose ideas we borrowed.
Future<void> showCreditsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreditsSheet(),
    );

/// People and projects credited for design ideas, with profile links.
const _inspiredBy = <(String, String)>[
  ('MorpheApp', 'https://github.com/MorpheApp'),
  ('MarcaDian', 'https://github.com/MarcaDian'),
];

class CreditsSheet extends StatefulWidget {
  const CreditsSheet({super.key});

  @override
  State<CreditsSheet> createState() => _CreditsSheetState();
}

class _CreditsSheetState extends State<CreditsSheet> {
  late Future<(List<Contributor>, List<Contributor>)> _people;

  @override
  void initState() {
    super.initState();
    _people = ContributorsService.loadBoth();
  }

  void _open(String url) =>
      launchUrlString(url, mode: LaunchMode.externalApplication);

  Widget _person(String login, {String? tooltip, String? url}) => Tooltip(
    message: tooltip ?? login,
    child: ActionChip(
      avatar: CircleAvatar(
        radius: 12,
        child: Text(
          login.characters.first.toUpperCase(),
          style: const TextStyle(fontSize: 12, height: 1),
        ),
      ),
      label: Text(login),
      onPressed: () => _open(url ?? 'https://github.com/$login'),
    ),
  );

  Widget _group(BuildContext context, String title, List<Widget> chips) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credits', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Obtainium+ is a hobby fork, built on the work of everyone below.',
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FutureBuilder(
            future: _people,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snap.data;
              if (data == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Contributor lists need a connection to GitHub.',
                    style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                );
              }
              final (fork, upstream) = data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _group(context, 'Obtainium+', [
                    _person('thejaustin', tooltip: 'thejaustin, maintainer'),
                    for (final c in fork)
                      if (c.login != 'thejaustin')
                        _person(c.login, tooltip: '${c.contributions} commits'),
                  ]),
                  _group(context, 'Obtainium, by ImranR98 and contributors', [
                    for (final c in upstream.take(24))
                      _person(c.login, tooltip: '${c.contributions} commits'),
                    ActionChip(
                      label: Text(
                        upstream.length > 24
                            ? 'and ${upstream.length - 24} more'
                            : 'All contributors',
                      ),
                      onPressed: () => _open(
                        'https://github.com/${ContributorsService.upstreamRepo}/graphs/contributors',
                      ),
                    ),
                  ]),
                ],
              );
            },
          ),
          _group(context, 'Co-developed with', [
            ActionChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Claude by Anthropic'),
              onPressed: () => _open('https://claude.ai'),
            ),
          ]),
          _group(context, "Inspired by Morphe Manager's design", [
            for (final (name, url) in _inspiredBy) _person(name, url: url),
          ]),
          Text(
            'The timeline changelog and this credits list take design ideas '
            'from Morphe Manager (GPL-3.0), whose timeline and changelog '
            'screens MarcaDian wrote.',
            style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
