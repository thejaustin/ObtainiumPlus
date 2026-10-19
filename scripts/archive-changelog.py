#!/usr/bin/env python3
import sys
import os
import re
import datetime

def get_upcoming():
    if not os.path.exists('CHANGELOG_USER.md'):
        return ''
    with open('CHANGELOG_USER.md', 'r') as f:
        content = f.read()
    top = content.split('---')[0]
    clean = re.sub(r'^## \[(Upcoming|Unreleased)\]', '', top, flags=re.I)
    clean = re.sub(r'<!--.*?-->', '', clean, flags=re.DOTALL).strip()
    return clean

def archive(version):
    if not os.path.exists('CHANGELOG_USER.md'):
        return
    with open('CHANGELOG_USER.md', 'r') as f:
        content = f.read()
    parts = content.split('---', 1)
    if len(parts) <= 1:
        return
    top_notes = re.sub(r'^## \[(Upcoming|Unreleased)\]', '', parts[0], flags=re.I)
    top_notes = re.sub(r'<!--.*?-->', '', top_notes, flags=re.DOTALL).strip()
    rest = parts[1].strip()
    today = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')
    new_header = '## [Upcoming]\n\n<!-- Add upcoming user-facing release notes here. When empty, CI automatically generates clean release notes from commit logs. -->\n\n---\n\n'
    if top_notes:
        archived_section = f'## [{version}] — {today}\n\n{top_notes}\n\n---\n\n'
    else:
        archived_section = ''
    with open('CHANGELOG_USER.md', 'w') as f:
        f.write(new_header + archived_section + rest + '\n')

def main():
    if len(sys.argv) < 2:
        print("Usage: archive-changelog.py [--get-upcoming | --archive <version>]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == '--get-upcoming':
        notes = get_upcoming()
        if notes:
            sys.stdout.write(notes)
    elif cmd == '--archive':
        if len(sys.argv) < 3:
            print("Error: version required for --archive", file=sys.stderr)
            sys.exit(1)
        version = sys.argv[2]
        archive(version)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
