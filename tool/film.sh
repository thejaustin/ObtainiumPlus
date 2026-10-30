#!/usr/bin/env bash
# Films the update flow (tiles + operations banner) into a contact sheet:
# build/previews/update_flow_sheet.png, one row per step, frames left to right.
#   tool/film.sh [--dark] [--frame-ms 40] [--frames 8] [--zoom 1,4,9]
set -euo pipefail
cd "$(dirname "$0")/.."
DARK=false FRAME_MS=40 FRAMES=8 ZOOM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dark) DARK=true; shift ;;
    --frame-ms) FRAME_MS=$2; shift 2 ;;
    --frames) FRAMES=$2; shift 2 ;;
    --zoom) ZOOM=$2; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
FLUTTER_ROOT_DIR=$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")
[[ -d "$FLUTTER_ROOT_DIR/bin/cache/artifacts/material_fonts" ]] || FLUTTER_ROOT_DIR="$HOME/flutter"
flutter test --no-pub tool/preview/update_flow_film_test.dart \
  --dart-define=PREVIEW_DARK="$DARK" \
  --dart-define=FILM_FRAME_MS="$FRAME_MS" \
  --dart-define=FILM_FRAMES="$FRAMES" \
  --dart-define=FILM_ZOOM_ROWS="$ZOOM" \
  --dart-define=FLUTTER_ROOT_DIR="$FLUTTER_ROOT_DIR" 2>&1 |
  command grep -E "ROW |METRIC |PREVIEW |Error|Exception|failed" || true
