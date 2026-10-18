#!/usr/bin/env bash
# flutter analyze, reporting only files reachable from the app entrypoints.
# ~50 files under lib/ are never imported (and some no longer compile), so raw
# `flutter analyze` shows ~2000 errors that cannot affect the APK.
#   --dead      print the unreachable files and exit
#   --all       include warnings/infos (default: errors + warnings)
set -euo pipefail
cd "$(dirname "$0")/../.."

dead_list=$(python3 -I - <<'EOF'
import os, re
seen, stack = set(), ['lib/main.dart', 'lib/main_fdroid.dart']
imp = re.compile(r"""^\s*(?:import|export|part)\s+['"]([^'"]+)['"]""", re.M)
cond = re.compile(r"""\bif\s*\([^)]*\)\s*['"]([^'"]+)['"]""")
while stack:
    f = stack.pop()
    if f in seen or not os.path.exists(f):
        continue
    seen.add(f)
    src = open(f, encoding='utf8').read()
    for u in imp.findall(src) + cond.findall(src):
        if u.startswith('package:obtainium/'):
            stack.append('lib/' + u[len('package:obtainium/'):])
        elif not u.startswith(('package:', 'dart:')):
            stack.append(os.path.normpath(os.path.join(os.path.dirname(f), u)))
files = {os.path.join(d, x) for d, _, fs in os.walk('lib') for x in fs if x.endswith('.dart')}
print('\n'.join(sorted(files - seen)))
EOF
)

if [[ "${1:-}" == "--dead" ]]; then
  echo "$dead_list"
  exit 0
fi

levels='^\s*(error|warning) •'
[[ "${1:-}" == "--all" ]] && levels='^\s*(error|warning|info) •'

out=$(flutter analyze lib test 2>&1 || true)
live=$(echo "$out" | command grep -E "$levels" | command grep -v -F -f <(echo "$dead_list") || true)
echo "$live"
errors=$(echo "$live" | command grep -cE '^\s*error •' || true)
echo "live errors: $errors  (unreachable files skipped: $(echo "$dead_list" | wc -l))"
[[ "$errors" == "0" ]]
