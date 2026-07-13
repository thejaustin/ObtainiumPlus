#!/usr/bin/env bash
# Download the APK artifact from the latest successful Build APK run
# into ~/downloads/ObtainiumPlus/.
set -euo pipefail
cd "$(dirname "$0")/../.."
dest="$HOME/downloads/ObtainiumPlus"
mkdir -p "$dest"
run_id=$(gh run list --workflow=build-apk.yml --status success --limit 1 --json databaseId --jq '.[0].databaseId')
[[ -n "$run_id" ]] || { echo "No successful build found" >&2; exit 1; }
gh run download "$run_id" --dir "$dest"
echo "Downloaded to $dest:"
find "$dest" -name '*.apk'
