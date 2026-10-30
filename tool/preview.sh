#!/usr/bin/env bash
# Render Settings tabs to PNG via a headless widget test and show them in the
# terminal with chafa (pkg install chafa).
#
#   tool/preview.sh                 # tab 0, light
#   tool/preview.sh --tabs 0,3,5    # several tabs
#   tool/preview.sh --dark --width 840
#   tool/preview.sh --no-view       # just write build/previews/*.png
set -euo pipefail
cd "$(dirname "$0")/.."

TABS=0 DARK=false WIDTH=412 HEIGHT=2400 VIEW=true COLS=${COLUMNS:-80}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tabs) TABS=$2; shift 2 ;;
    --dark) DARK=true; shift ;;
    --width) WIDTH=$2; shift 2 ;;
    --height) HEIGHT=$2; shift 2 ;;
    --cols) COLS=$2; shift 2 ;;
    --no-view) VIEW=false; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

FLUTTER_ROOT_DIR=$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")
# ~/.local/bin/flutter is a wrapper; fall back to ~/flutter if needed.
[[ -d "$FLUTTER_ROOT_DIR/bin/cache/artifacts/material_fonts" ]] || FLUTTER_ROOT_DIR="$HOME/flutter"

flutter test tool/preview/settings_preview_test.dart \
  --dart-define=PREVIEW_TABS="$TABS" \
  --dart-define=PREVIEW_DARK="$DARK" \
  --dart-define=PREVIEW_WIDTH="$WIDTH" \
  --dart-define=PREVIEW_HEIGHT="$HEIGHT" \
  --dart-define=FLUTTER_ROOT_DIR="$FLUTTER_ROOT_DIR" 2>&1 |
  grep -E "PREVIEW |Error|Exception|failed" || true

if $VIEW && command -v chafa >/dev/null; then
  for f in build/previews/settings_tab_*.png; do
    [[ -f "$f" ]] || continue
    echo "── $f"
    chafa --size="${COLS}x" --symbols=block+border+space "$f"
  done
fi
