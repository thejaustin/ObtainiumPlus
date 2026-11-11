#!/usr/bin/env python3
"""Score how much of each upstream commit is in the fork.

The fork's history was rewritten (2026-10), so commit IDs don't match
upstream. For every upstream non-merge commit since SINCE whose subject is
not in the fork's log, print:
  lines  share of its added code lines (>30 chars) present in lib/android
  kept   share of the lines it removed that the fork still has
  keys   en.json keys it added that the fork has
  ids    identifiers it introduced that the fork has, plus the missing ones
Only code that still exists at REF's tip is scored, so code upstream later
renamed or removed doesn't count as missing. Fork files that ship nothing
(analyze-live.sh --dead, plus the shadowed extensions listed in CLAUDE.md)
are excluded, so code that only exists there counts as missing.
Low scores can also mean the fork reimplemented the feature differently.

Usage: python3 scripts/dev/upstream-audit.py [SINCE=2026-09-01] [REF=upstream/main]
"""
import json, re, subprocess, sys

since = sys.argv[1] if len(sys.argv) > 1 else '2026-09-01'
ref = sys.argv[2] if len(sys.argv) > 2 else 'upstream/main'
ID = r'[A-Za-z_][A-Za-z0-9_]{5,}'
PATHS = ['lib', 'android/app/src', 'pubspec.yaml']

def git(*a):
    return subprocess.run(['git', *a], capture_output=True, text=True).stdout

SHADOWED = [
    'lib/providers/apps_provider_lifecycle.dart',
    'lib/providers/apps_provider_install.dart',
    'lib/services/app_crud_service.dart',
    'lib/components/app_list_tile.dart',
]
dead_out = subprocess.run(['bash', 'scripts/dev/analyze-live.sh', '--dead'],
                          capture_output=True, text=True).stdout
dead = set(re.findall(r'^(lib/\S+\.dart)$', dead_out, re.M)) | set(SHADOWED)
excludes = [f':(exclude){f}' for f in sorted(dead)]

fork_subjects = set(git('log', '--no-merges', '--format=%s', 'HEAD').splitlines())
tree = git('grep', '-h', '-I', '-e', '.', '--', *PATHS, *excludes)
fork_lines = {l.strip() for l in tree.splitlines()}
fork_ids = set(re.findall(ID, tree))
en = json.load(open('assets/translations/en.json'))
tip = git('grep', '-h', '-I', '-e', '.', ref, '--', *PATHS)
tip_lines = {l.strip() for l in tip.splitlines()}
tip_ids = set(re.findall(ID, tip))
tip_en = json.loads(git('show', f'{ref}:assets/translations/en.json'))
print(f'excluded {len(dead)} dead/shadowed files', file=sys.stderr)

def sig(lines):
    return [x for x in lines if len(x) > 30 and not x.startswith(('//', '*', '/*', 'import '))]

for row in git('log', '--no-merges', f'--since={since}', '--format=%h%x09%ad%x09%s',
               '--date=short', ref).splitlines():
    h, d, s = row.split('\t', 2)
    if s in fork_subjects:
        continue
    diff = git('show', '--format=', '--unified=0', h, '--', *PATHS)
    add = [x[1:].strip() for x in diff.splitlines() if x.startswith('+') and not x.startswith('+++')]
    rem = [x[1:].strip() for x in diff.splitlines() if x.startswith('-') and not x.startswith('---')]
    a = [x for x in sig(add) if x in tip_lines]
    lines = f'{100 * sum(x in fork_lines for x in a) // len(a)}%' if a else '-'
    r = sig(rem)
    # For removals, high means the fork still has the code upstream deleted.
    kept = f'{100 * sum(x in fork_lines for x in r) // len(r)}%' if r else '-'
    ej = git('show', '--format=', '--unified=0', h, '--', 'assets/translations/en.json')
    removed_keys = set(re.findall(r'^-\s*"([^"]+)":', ej, re.M))
    keys = [k for k in re.findall(r'^\+\s*"([^"]+)":', ej, re.M)
            if k not in removed_keys and k in tip_en]
    prev = set(re.findall(ID, git('grep', '-h', '-I', '-e', '.', f'{h}~1', '--', *PATHS)))
    new = (set(re.findall(ID, ' '.join(add))) - set(re.findall(ID, ' '.join(rem)))
           - prev) & tip_ids
    miss = sorted(i for i in new if i not in fork_ids)
    print(f'{h} {d} lines {lines:>4} kept {kept:>4} keys {sum(k in en for k in keys)}/{len(keys)} '
          f'ids {len(new) - len(miss)}/{len(new)}  {s}')
    if miss:
        print('    missing:', ' '.join(miss[:12]))
