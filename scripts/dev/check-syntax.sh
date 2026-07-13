#!/usr/bin/env bash
# Fast local syntax check. No Flutter SDK on this device, so `dart analyze`
# can't resolve flutter imports — instead `dart format` is used as a parser:
# it prints "Could not format ..." for any file with syntax errors. Formatting
# diffs are ignored (the codebase is not strict-dart-format clean).
# Full analysis + tests happen in CI (build-apk.yml).
set -uo pipefail
cd "$(dirname "$0")/../.."
errors=$(dart format --output=none lib/ test/ 2>&1 >/dev/null | grep -v 'analysis_options.yaml' || true)
if [[ -n "$errors" ]]; then
    echo "$errors"
    echo "SYNTAX ERRORS FOUND"
    exit 1
fi
echo "Syntax OK"
